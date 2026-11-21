#!/usr/bin/env bash
set -uo pipefail
AUTH_JSON="${OPENCODE_AUTH_JSON:-$HOME/.local/share/opencode/auth.json}"

# Locate the opencode CLI (the plugin process may not inherit the full PATH)
OPENCODE_BIN=$(command -v opencode 2>/dev/null || true)
if [[ -z "$OPENCODE_BIN" ]]; then
  for c in /home/jamerrq/.local/share/mise/installs/opencode/*/node_modules/.bin/opencode; do
    [[ -x "$c" ]] && { OPENCODE_BIN="$c"; break; }
  done
fi

# OpenCode Go subscription usage (paid tier only)
URL=https://opencode.ai/zen/go/v1/usage
key=$(jq -r '.["opencode-go"].key // .opencode.key // empty' "$AUTH_JSON" 2>/dev/null || true)

collect_go() {
  local k=$1 out code
  [[ -n $k ]] || return 1
  out=$(curl -sS -m 10 -w $'\n%{http_code}' -H "Authorization: Bearer $k" "$URL" 2>/dev/null) || return 1
  code=${out##*$'\n'}; out=${out%$'\n'*}
  [[ $code == 200 ]] || return 1
  jq -e '.usage.rolling and .usage.weekly and .usage.monthly' >/dev/null 2>&1 <<<"$out" || return 1
  jq -c '{status:"ok",rolling:.usage.rolling,weekly:.usage.weekly,monthly:.usage.monthly}' <<<"$out"
}

windows=''; status=''
if windows=$(collect_go "$key"); then status="ok"; else status="free-tier"; fi

stats_json='{}'
if [[ -n "$OPENCODE_BIN" ]]; then
  stats_json=$("$OPENCODE_BIN" stats --json --all --models 2>/dev/null || echo '{}')
fi

token_sum() {
  jq -r '[.tokens.input // 0, .tokens.output // 0, .tokens.reasoning // 0,
          .tokens.cache.read // 0, .tokens.cache.write // 0] | add // 0' 2>/dev/null || echo 0
}

# `stats` exposes per-day *steps* only. Derive real per-day tokens from the
# cumulative `--days N` totals by differencing consecutive windows.
declare -A cum
cum[0]=0
for n in 1 2 3 4 5 6 7; do
  if [[ -n "$OPENCODE_BIN" ]]; then
    s=$("$OPENCODE_BIN" stats --json --days "$n" 2>/dev/null || echo '{}')
  else
    s='{}'
  fi
  cum[$n]=$(token_sum <<<"$s")
done

# Map each of the last 7 calendar dates to its cumulative index (DST-safe).
# `stats --days 1` covers only today, so today -> 1, yesterday -> 2, ...
declare -A day_index
i=1
for offset in 0 1 2 3 4 5 6; do
  d=$(date -d "$offset days ago" +%Y-%m-%d 2>/dev/null || date -v-${offset}d +%Y-%m-%d 2>/dev/null || true)
  [[ -n "$d" ]] && day_index[$d]=$i
  i=$((i + 1))
done

cutoff_date=$(date -d '6 days ago' +%Y-%m-%d 2>/dev/null || date -v-6d +%Y-%m-%d 2>/dev/null || true)

recent='[]'
while IFS='|' read -r d steps; do
  [[ -n "$d" ]] || continue
  n=${day_index[$d]:-0}
  (( n > 0 )) || continue
  tokens=$((${cum[$n]:-0} - ${cum[$((n - 1))]:-0}))
  (( tokens > 0 )) || continue
  recent=$(jq -c --arg d "$d" --argjson t "$tokens" --argjson s "${steps:-0}" \
    '. + [{date:$d, tokens:$t, steps:$s, cost:0}]' <<<"$recent")
done < <(jq -r --arg cutoff "$cutoff_date" \
  '.activity[]? | select(.date >= $cutoff) | "\(.date)|\(.steps // 0)"' \
  <<<"$stats_json" 2>/dev/null || true)

# Per-model breakdown: combine variants, drop models with no tokens used.
models=$(jq -c '
  [(.models // [])[]
   | ((.tokens.input // 0) + (.tokens.output // 0) + (.tokens.reasoning // 0) +
      (.tokens.cache.read // 0) + (.tokens.cache.write // 0)) as $t
   | select($t > 0)
   | {key: ((.model.providerID // "") + "/" + (.model.id // "unknown")),
      model: (.model.id // "unknown"),
      providerID: (.model.providerID // ""),
      steps: (.steps // 0), tokens: $t}]
  | group_by(.key)
  | map({model: .[0].model, providerID: .[0].providerID,
         steps: (map(.steps) | add), tokens: (map(.tokens) | add)})
  | sort_by(-.tokens)
' <<<"$stats_json" 2>/dev/null || echo '[]')

total_tokens=$(token_sum <<<"$stats_json")
total_steps=$(jq -r '.steps // 0' <<<"$stats_json" 2>/dev/null || echo 0)
sessions=$(jq -r '.sessions // 0' <<<"$stats_json" 2>/dev/null || echo 0)

# Next free-message reset (local time, configurable via OPENCODE_FREE_RESET_TIME)
reset_clock="${OPENCODE_FREE_RESET_TIME:-19:20}"
free_reset_at=''
reset_epoch=$(date -d "today $reset_clock" +%s 2>/dev/null || true)
if [[ -n "$reset_epoch" ]]; then
  (( reset_epoch <= $(date +%s) )) && reset_epoch=$(date -d "tomorrow $reset_clock" +%s)
  free_reset_at=$(date -u -d "@$reset_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)
fi

common=(--arg label "OpenCode" --arg status "$status" --argjson recent "$recent"
        --argjson models "$models" --arg totalTokens "$total_tokens"
        --arg totalSteps "$total_steps" --arg sessions "$sessions"
        --arg freeResetAt "$free_reset_at")

if [[ "$status" == "ok" ]]; then
  jq -cn "${common[@]}" --argjson w "$windows" \
    '{label:$label,status:$status,rolling:$w.rolling,weekly:$w.weekly,monthly:$w.monthly,
      recentDays:$recent,models:$models,totalTokens:($totalTokens|tonumber),
      totalSteps:($totalSteps|tonumber),sessions:($sessions|tonumber),
      freeResetAt:$freeResetAt,updatedAt:(now|todateiso8601),error:""}'
else
  jq -cn "${common[@]}" \
    '{label:$label,status:"free-tier",rolling:null,weekly:null,monthly:null,
      recentDays:$recent,models:$models,totalTokens:($totalTokens|tonumber),
      totalSteps:($totalSteps|tonumber),sessions:($sessions|tonumber),
      freeResetAt:$freeResetAt,updatedAt:(now|todateiso8601),error:""}'
fi

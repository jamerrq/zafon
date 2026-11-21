#!/usr/bin/env bash
set -uo pipefail
AUTH_JSON="${OPENCODE_AUTH_JSON:-$HOME/.local/share/opencode/auth.json}"

# Locate the opencode CLI (may not be on PATH in the plugin's process env)
OPENCODE_BIN=$(command -v opencode 2>/dev/null || true)
if [[ -z "$OPENCODE_BIN" ]]; then
  for c in /home/jamerrq/.local/share/mise/installs/opencode/*/node_modules/.bin/opencode; do
    [[ -x "$c" ]] && { OPENCODE_BIN="$c"; break; }
  done
fi

# Try OpenCode Go subscription usage (paid tier)
URL=https://opencode.ai/zen/go/v1/usage
DB="$HOME/.local/share/opencode/opencode.db"

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

windows=''; status=''; error=''
if windows=$(collect_go "$key"); then
  status="ok"
else
  status="free-tier"
fi

# Free-tier / local usage from opencode stats (authoritative, always current)
stats_json='{}'
if [[ -n "$OPENCODE_BIN" ]]; then
  stats_json=$("$OPENCODE_BIN" stats --json --all --models 2>/dev/null || echo '{}')
fi

# Build recentDays (last 7 days of activity, steps as the per-day value)
cutoff_date=$(date -d '6 days ago' +%Y-%m-%d 2>/dev/null || date -v-6d +%Y-%m-%d 2>/dev/null)
recent=$(jq -c --arg cutoff "$cutoff_date" '
  [(.activity // [])[] | select(.date >= $cutoff) | {date, tokens: (.steps // 0), cost: 0}]
' <<<"$stats_json" 2>/dev/null || echo '[]')

# Build models breakdown
models=$(jq -c '
  [(.models // [])[] | {
    model: (.model.id // "unknown"),
    providerID: (.model.providerID // ""),
    steps: (.steps // 0),
    tokens: ((.tokens.input // 0) + (.tokens.output // 0) + (.tokens.reasoning // 0) + (.tokens.cache.read // 0) + (.tokens.cache.write // 0))
  }]
' <<<"$stats_json" 2>/dev/null || echo '[]')

total_tokens=$(jq -r '(.tokens.input // 0) + (.tokens.output // 0) + (.tokens.reasoning // 0) + (.tokens.cache.read // 0) + (.tokens.cache.write // 0)' <<<"$stats_json" 2>/dev/null || echo 0)
total_steps=$(jq -r '.steps // 0' <<<"$stats_json" 2>/dev/null || echo 0)
sessions=$(jq -r '.sessions // 0' <<<"$stats_json" 2>/dev/null || echo 0)

if [[ "$status" == "ok" ]]; then
  jq -cn \
    --arg label "OpenCode" \
    --argjson w "$windows" \
    --argjson recent "$recent" \
    --argjson models "$models" \
    --arg status "$status" \
    --arg totalTokens "$total_tokens" \
    --arg totalSteps "$total_steps" \
    --arg sessions "$sessions" \
    '{label:$label,status:$status,rolling:$w.rolling,weekly:$w.weekly,monthly:$w.monthly,recentDays:$recent,models:$models,totalTokens:($totalTokens|tonumber),totalSteps:($totalSteps|tonumber),sessions:($sessions|tonumber),updatedAt:(now|todateiso8601),error:""}'
else
  jq -cn \
    --arg label "OpenCode" \
    --argjson recent "$recent" \
    --argjson models "$models" \
    --arg status "free-tier" \
    --arg totalTokens "$total_tokens" \
    --arg totalSteps "$total_steps" \
    --arg sessions "$sessions" \
    '{label:$label,status:$status,rolling:null,weekly:null,monthly:null,recentDays:$recent,models:$models,totalTokens:($totalTokens|tonumber),totalSteps:($totalSteps|tonumber),sessions:($sessions|tonumber),updatedAt:(now|todateiso8601),error:""}'
fi
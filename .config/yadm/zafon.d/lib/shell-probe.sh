#!/bin/bash
# Shared helper: run a real interactive shell and report what it actually loaded.
#
# Not matched by zafon's module glob ($MODULE_DIR/*.sh is not recursive), so
# this lives here without being discovered as a module.
#
# Why a PTY. `zsh -i -c ...` with no terminal is not a useful test: zle and job
# control cannot be enabled, so p10k's gitstatus fails to start and the run
# prints errors that say nothing about the config. Under script(1) the same
# shell starts silently. A check that skips this reports noise as breakage.
#
# Why run it rather than grep it. A config file can contain exactly the right
# lines and still not take effect -- sourced in the wrong order, guarded by a
# false condition, or overwritten later. These helpers assert on the shell's
# own state after startup, which is the only thing that answers "did it load".

# shell_probe <shell> <snippet> -- run <snippet> in an interactive <shell> under
# a PTY; print stdout with CRs stripped.
shell_probe() {
  local sh=$1 snippet=$2
  command -v script >/dev/null 2>&1 || { echo "script(1) not available" >&2; return 3; }
  script -qec "$sh -i -c '$snippet'" /dev/null 2>/dev/null | tr -d '\r'
}

# shell_probe_stderr <shell> -- start an interactive shell that does nothing and
# return whatever it complained about. Empty output means a clean startup.
shell_probe_stderr() {
  local sh=$1
  script -qec "$sh -i -c 'true'" /dev/null 2>&1 |
    tr -d '\r' |
    grep -vE '^[[:space:]]*$' |
    grep -viE '^script (started|done)'
}

# probe_kv <output> <key> -- read a `key=value` line out of a probe's output.
# Assertions are written as key=value so one shell start can answer several
# questions at once, which is what keeps this cheap enough to run every check.
probe_kv() {
  sed -n "s/^$2=//p" <<<"$1" | head -n1
}

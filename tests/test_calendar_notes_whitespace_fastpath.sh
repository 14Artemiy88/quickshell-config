#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$TMP_ROOT"' EXIT
export HOME="$TMP_ROOT/home"
export XDG_CONFIG_HOME="$HOME/config"
export XDG_DATA_HOME="$HOME/share"
export XDG_STATE_HOME="$HOME/state"
export XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$TMP_ROOT/runtime"
export QS_PROJECT_DIR="$ROOT"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
SCRIPT="$ROOT/scripts/calendar_notes"
FILE="$XDG_DATA_HOME/quickshell-widgets/calendar-notes.json"
fail() { printf 'Calendar notes whitespace fast-path test failed: %s\n' "$1" >&2; exit 1; }

"$SCRIPT" set 2026-10-23 'keep this note' >/dev/null
[[ "$(jq -r '.["2026-10-23"]' "$FILE")" == 'keep this note' ]] || fail 'non-whitespace note was not saved'
"$SCRIPT" set 2026-10-23 $' \t\n\r' >/dev/null
jq -e 'has("2026-10-23") | not' "$FILE" >/dev/null || fail 'whitespace-only note was not removed'
"$SCRIPT" set 2026-10-24 $'  preserved\ntext  ' >/dev/null
[[ "$(jq -r '.["2026-10-24"]' "$FILE")" == $'  preserved\ntext  ' ]] || fail 'meaningful text whitespace was not preserved'
if grep -Fq "tr -d '[:space:]'" "$SCRIPT"; then
  fail 'external tr whitespace pipeline remains in the hot path'
fi
grep -Fq '[[ ! "$value" =~ [^[:space:]] ]]' "$SCRIPT" || fail 'Bash built-in whitespace predicate missing'
echo 'Calendar notes whitespace fast path: OK'

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
export HOME="$TMP_ROOT/home"
export XDG_CONFIG_HOME="$HOME/config"
export XDG_DATA_HOME="$HOME/share"
export XDG_STATE_HOME="$HOME/state"
export XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$TMP_ROOT/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
SETTINGS="$ROOT/scripts/settings"
CFG="$XDG_CONFIG_HOME/quickshell-widgets/settings.json"
fail() { printf 'settings UI/external token stress test failed: %s\n' "$1" >&2; exit 1; }
"$SETTINGS" set-json '{"weatherToken":"baseline-token","stable":{"value":42}}'
baseline='baseline-token'
workers=()
for i in $(seq 1 24); do
    "$SETTINGS" token "external-token-$i" >/dev/null &
    workers+=("$!")
    payload=$(jq -cn --argjson n "$i" '{weatherToken:"baseline-token",uiRevision:$n,stable:{value:42}}')
    "$SETTINGS" set-json-ui "$payload" "$baseline" >/dev/null &
    workers+=("$!")
done
for pid in "${workers[@]}"; do wait "$pid" || fail 'a concurrent token/UI-snapshot update failed'; done
jq -e 'type == "object" and (has("weatherToken") | not) and (.uiRevision | type == "number") and .stable.value == 42' "$CFG" >/dev/null || fail 'concurrent UI snapshots corrupted settings'; jq -e '.weatherToken | startswith("external-token-")' "$XDG_CONFIG_HOME/quickshell-widgets/secrets.json" >/dev/null || fail 'stale UI snapshot erased the final external token'
cmp -s "$CFG" "$XDG_CONFIG_HOME/quickshell-widgets/.settings.json.bak" || fail 'backup diverged after concurrent UI/token writes'
if jq -e 'type == "object"' "$CFG" >/dev/null 2>&1; then :; else fail 'concurrent writes left invalid JSON'; fi
echo 'Settings UI snapshots preserve concurrent external token updates: OK'

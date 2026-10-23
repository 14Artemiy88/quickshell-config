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
fail() { printf 'settings atomic-write test failed: %s\n' "$1" >&2; exit 1; }

initial=$("$SETTINGS" get)
jq -e 'type == "object" and .weatherToken == "" and (.modules.time == true)' <<<"$initial" >/dev/null || fail 'default settings were not initialized as an object'
CFG="$XDG_CONFIG_HOME/quickshell-widgets/settings.json"
[[ "$(stat -c '%a' "$CFG")" == 600 ]] || fail 'settings file is not private (mode 600)'

valid='{"weatherToken":"old","custom":{"value":7},"modules":{"time":true},"geometry":{}}'
"$SETTINGS" set-json "$valid"
jq -e '.weatherToken == "old" and .custom.value == 7' "$CFG" >/dev/null || fail 'valid set-json payload was not written'
cp "$CFG" "$TMP_ROOT/before.json"
if "$SETTINGS" set-json '{invalid' >/dev/null 2>&1; then fail 'malformed JSON was accepted'; fi
if "$SETTINGS" set-json '[]' >/dev/null 2>&1; then fail 'non-object JSON was accepted'; fi
cmp -s "$CFG" "$TMP_ROOT/before.json" || fail 'invalid payload altered existing settings'

# token updates are read-modify-write transactions: concurrent invocations must
# preserve the unrelated settings fields and always leave parseable JSON.
workers=()
for i in $(seq 1 24); do
    "$SETTINGS" token "token-$i-\"quoted\"-\\path" >/dev/null &
    workers+=("$!")
done
for pid in "${workers[@]}"; do wait "$pid" || fail 'concurrent token update failed'; done
jq -e 'type == "object" and (.weatherToken | startswith("token-")) and .custom.value == 7 and .modules.time == true' "$CFG" >/dev/null || fail 'concurrent token updates corrupted or lost unrelated settings'
cmp -s "$CFG" "$XDG_CONFIG_HOME/quickshell-widgets/.settings.json.bak" || fail 'backup did not track the newest concurrent token update'

# Concurrent whole-snapshot writes must publish one complete payload, never a
# truncated/mixed JSON file. Which writer wins is deliberately unspecified.
workers=()
for i in $(seq 1 16); do
    payload=$(jq -cn --argjson n "$i" '{writer:$n, weatherToken:"", modules:{time:true}, geometry:{}}')
    "$SETTINGS" set-json "$payload" >/dev/null &
    workers+=("$!")
done
for pid in "${workers[@]}"; do wait "$pid" || fail 'concurrent set-json write failed'; done
jq -e 'type == "object" and (.writer | type == "number") and .modules.time == true' "$CFG" >/dev/null || fail 'concurrent set-json left invalid or partial JSON'
cmp -s "$CFG" "$XDG_CONFIG_HOME/quickshell-widgets/.settings.json.bak" || fail 'backup did not track the newest concurrent whole-snapshot write'

if find "$XDG_CONFIG_HOME/quickshell-widgets" -maxdepth 1 -type f -name '.settings.json.*' ! -name '.settings.json.bak' | grep -q .; then
    fail 'temporary settings files leaked'
fi
[[ -f "$XDG_CONFIG_HOME/quickshell-widgets/.settings.lock" ]] || fail 'settings lock file missing'

echo 'Settings atomic writes: OK'

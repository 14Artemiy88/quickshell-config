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
DIR="$XDG_CONFIG_HOME/quickshell-widgets"
CFG="$DIR/settings.json"
BACKUP="$DIR/.settings.json.bak"
fail() { printf 'settings latest-backup test failed: %s\n' "$1" >&2; exit 1; }

first='{"weatherToken":"first","prefs":{"revision":1},"modules":{"time":true}}'
second='{"weatherToken":"second","prefs":{"revision":2},"modules":{"time":false}}'
"$SETTINGS" set-json "$first"
cmp -s "$CFG" "$BACKUP" || fail 'backup was not synchronized after first committed write'
"$SETTINGS" set-json "$second"
cmp -s "$CFG" "$BACKUP" || fail 'backup lagged behind the second committed write'
jq -e '(has("weatherToken") | not) and .prefs.revision == 2 and .modules.time == false' "$BACKUP" >/dev/null || fail 'backup does not contain the latest snapshot'

# A valid current file paired with an older valid backup must refresh the backup
# on read, covering a process stop between primary publish and backup refresh.
printf '%s\n' "$first" > "$BACKUP"
readback=$("$SETTINGS" get)
jq -e '.weatherToken == "second" and .prefs.revision == 2 and .modules.time == false' <<<"$readback" >/dev/null || fail 'read changed the current settings while synchronizing backup'
cmp -s "$CFG" "$BACKUP" || fail 'get did not refresh a stale but valid backup'

# Token updates also need to leave both copies at the newly committed state.
"$SETTINGS" token 'third' 
jq -e '(has("weatherToken") | not) and .prefs.revision == 2' "$CFG" && jq -e '.weatherToken == "third"' "$DIR/secrets.json" >/dev/null || fail 'token update was not applied'
cmp -s "$CFG" "$BACKUP" || fail 'backup lagged behind token update'

# Damage after the successful write must restore the latest state, not the one
# that happened to exist before the most recent write.
printf '{"broken":' > "$CFG"
restored=$("$SETTINGS" get 2>"$TMP_ROOT/recovery.log")
jq -e '.weatherToken == "third" and .prefs.revision == 2' <<<"$restored" >/dev/null || fail 'recovery did not use the most recently committed state'
cmp -s "$CFG" "$BACKUP" || fail 'recovered primary and backup do not match'

echo 'Settings backup tracks latest commit: OK'

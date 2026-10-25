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
fail() { printf 'mixed settings writer/recovery stress test failed: %s\n' "$1" >&2; exit 1; }

initial='{"weatherToken":"baseline-token","uiRevision":0,"stable":{"value":"preserved"},"modules":{"time":true},"geometry":{}}'
"$SETTINGS" set-json "$initial"

# Interleave many full UI snapshots with token read-modify-write updates and
# readers. flock must serialize them; each observed and final state must remain
# valid JSON, the UI-only fields must survive, and the current disk token wins.
workers=()
for i in $(seq 1 24); do
    "$SETTINGS" token "external-token-$i" >/dev/null & workers+=("$!")
    payload=$(jq -cn --argjson revision "$i" '{weatherToken:"baseline-token",uiRevision:$revision,stable:{value:"preserved"},modules:{time:true},geometry:{}}')
    "$SETTINGS" set-json-ui "$payload" baseline-token >/dev/null & workers+=("$!")
    (
      observed=$("$SETTINGS" get)
      jq -e 'type == "object" and (.weatherToken | type == "string") and (.stable.value == "preserved")' <<<"$observed" >/dev/null || exit 1
    ) & workers+=("$!")
done
for pid in "${workers[@]}"; do wait "$pid" || fail 'concurrent token/UI/read transaction failed'; done
jq -e 'type == "object" and (has("weatherToken") | not) and (.uiRevision | type == "number") and .stable.value == "preserved" and .modules.time == true' "$CFG" >/dev/null || fail 'mixed writes lost UI snapshot fields'; jq -e '.weatherToken | startswith("external-token-")' "$XDG_CONFIG_HOME/quickshell-widgets/secrets.json" >/dev/null || fail 'mixed writes lost token'
cmp -s "$CFG" "$BACKUP" || fail 'backup diverged after concurrent mixed writes'
[[ "$(stat -c '%a' "$CFG")" == 600 && "$(stat -c '%a' "$BACKUP")" == 600 ]] || fail 'settings or backup permissions are not 600'

# Recovery runs under the same transaction lock. A read that discovers a
# damaged primary, a token update, and a stale UI snapshot must converge to the
# last committed token without returning to malformed JSON or losing fields.
baseline=$(jq -r '.weatherToken' "$XDG_CONFIG_HOME/quickshell-widgets/secrets.json")
printf '{truncated json\n' > "$CFG"
payload=$(jq -cn --arg token "$baseline" '{weatherToken:$token,uiRevision:777,stable:{value:"preserved"},modules:{time:true},geometry:{}}')
workers=()
"$SETTINGS" get > "$TMP_ROOT/recovered-read.json" & workers+=("$!")
"$SETTINGS" token recovery-token >/dev/null & workers+=("$!")
"$SETTINGS" set-json-ui "$payload" "$baseline" >/dev/null & workers+=("$!")
for pid in "${workers[@]}"; do wait "$pid" || fail 'concurrent recovery/read/token/UI transaction failed'; done
jq -e 'type == "object" and (has("weatherToken") | not) and .uiRevision == 777 and .stable.value == "preserved" and .modules.time == true' "$CFG" >/dev/null || fail 'recovery race lost the latest UI state'; jq -e '.weatherToken == "recovery-token"' "$XDG_CONFIG_HOME/quickshell-widgets/secrets.json" >/dev/null || fail 'recovery race lost final token'
cmp -s "$CFG" "$BACKUP" || fail 'backup diverged after recovery race'
jq -e 'type == "object"' "$TMP_ROOT/recovered-read.json" >/dev/null || fail 'concurrent reader observed malformed JSON'
compgen -G "$DIR/.settings.json.corrupt.*" >/dev/null || fail 'damaged settings file was not preserved'
if find "$DIR" -maxdepth 1 -type f -name '.settings.json.*' ! -name '.settings.json.bak' ! -name '.settings.json.lock' | grep -q .; then
    # Corrupt quarantine files are intentional; only unnamed transient files are forbidden.
    if find "$DIR" -maxdepth 1 -type f -name '.settings.json.*' ! -name '.settings.json.bak' ! -name '.settings.json.lock' ! -name '.settings.json.corrupt.*' | grep -q .; then
        fail 'temporary settings files leaked after mixed recovery race'
    fi
fi

echo 'Mixed settings writers, readers, and recovery stress: OK'

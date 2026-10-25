#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
export HOME="$TMP_ROOT/home" XDG_CONFIG_HOME="$TMP_ROOT/config" XDG_DATA_HOME="$TMP_ROOT/share" XDG_STATE_HOME="$TMP_ROOT/state" XDG_CACHE_HOME="$TMP_ROOT/cache" XDG_RUNTIME_DIR="$TMP_ROOT/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR" "$XDG_CONFIG_HOME/quickshell-widgets"
SETTINGS="$ROOT/scripts/settings"
DIR="$XDG_CONFIG_HOME/quickshell-widgets"
CFG="$DIR/settings.json"
SECRETS="$DIR/secrets.json"
fail() { printf 'weather secret storage test failed: %s\n' "$1" >&2; exit 1; }

# Upgrade an existing installation that stored its token in settings.json.
printf '%s\n' '{"weatherToken":"legacy-weather-token","custom":{"keep":true}}' > "$CFG"
chmod 600 "$CFG"
view=$("$SETTINGS" get)
jq -e '.weatherToken == "legacy-weather-token" and .custom.keep == true' <<<"$view" >/dev/null || fail 'legacy token was not exposed to existing UI callers'
jq -e 'has("weatherToken") | not' "$CFG" >/dev/null || fail 'token remained in settings.json after migration'
jq -e '.weatherToken == "legacy-weather-token"' "$SECRETS" >/dev/null || fail 'legacy token was not moved into secrets.json'
[[ "$(stat -c '%a' "$SECRETS")" == 600 ]] || fail 'secrets file is not mode 600'
[[ ! -e "$DIR/.settings.json.bak" ]] || jq -e 'has("weatherToken") | not' "$DIR/.settings.json.bak" >/dev/null || fail 'legacy token remained in settings backup'

# Token edits through either supported writer update only the local secret.
"$SETTINGS" token 'new-local-token'
view=$("$SETTINGS" get)
jq -e '.weatherToken == "new-local-token"' <<<"$view" >/dev/null || fail 'token command update was not visible in merged settings'
jq -e 'has("weatherToken") | not' "$CFG" >/dev/null || fail 'token command wrote the secret into settings.json'
"$SETTINGS" set-json-ui '{"weatherToken":"ui-token","custom":{"changed":true}}' 'new-local-token' >/dev/null
jq -e '.weatherToken == "ui-token"' "$SECRETS" >/dev/null || fail 'UI token edit did not update secrets.json'
jq -e '(has("weatherToken") | not) and .custom.changed == true' "$CFG" >/dev/null || fail 'UI write persisted token or lost ordinary settings'

# Weather service reads from the local secret file, not the transferable file.
source "$ROOT/scripts/weather.d/common.sh"
[[ "$(weather_read_token)" == 'ui-token' ]] || fail 'weather service did not read secrets.json'

# The repository ignores the secret file.
grep -Fxq 'secrets.json' "$ROOT/.gitignore" || fail '.gitignore does not exclude secrets.json'
! grep -Fxq '/settings.json' "$ROOT/.gitignore" || fail '.gitignore still blocks portable settings.json'
echo 'Weather token isolation and legacy migration: OK'

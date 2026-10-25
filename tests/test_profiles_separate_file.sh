#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
export HOME="$TMP_ROOT/home" XDG_CONFIG_HOME="$TMP_ROOT/config" XDG_DATA_HOME="$TMP_ROOT/data" XDG_STATE_HOME="$TMP_ROOT/state" XDG_CACHE_HOME="$TMP_ROOT/cache" XDG_RUNTIME_DIR="$TMP_ROOT/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
SETTINGS="$ROOT/scripts/settings"
CFG="$XDG_CONFIG_HOME/quickshell-widgets/settings.json"
PROFILES="$(dirname "$CFG")/profiles.json"
mkdir -p "$(dirname "$CFG")"
# A legacy embedded catalog is migrated without losing active profile or overrides.
printf '%s\n' '{"profiles":{"Work":{"fontSize":15}},"activeProfile":"Work","profileOverrides":{"fontSize":17},"weatherToken":"global"}' > "$CFG"
merged=$("$SETTINGS" get)
jq -e '.profiles.Work.fontSize == 15 and .activeProfile == "Work" and .profileOverrides.fontSize == 17 and .weatherToken == "global"' <<<"$merged" >/dev/null
jq -e 'has("profiles") | not' "$CFG" >/dev/null || { echo 'profiles catalog remains embedded in settings.json' >&2; exit 1; }
jq -e '.Work.fontSize == 15' "$PROFILES" >/dev/null
[[ "$(stat -c '%a' "$PROFILES")" == 600 ]]
# UI snapshots continue to use the merged schema, but writes split the catalog back out.
payload='{"settingsPersistenceFormat":"profile-overrides-v1","profiles":{"Work":{"fontSize":16},"Games":{"fontSize":20}},"activeProfile":"Games","profileOverrides":{"fontSize":21},"weatherToken":"global"}'
"$SETTINGS" set-json-ui "$payload" global >/dev/null
jq -e '((has("profiles") | not) and .activeProfile == "Games" and .profileOverrides.fontSize == 21 and (has("weatherToken") | not))' "$CFG" && jq -e '.weatherToken == "global"' "$(dirname "$CFG")/secrets.json" >/dev/null
jq -e '.Work.fontSize == 16 and .Games.fontSize == 20' "$PROFILES" >/dev/null
merged=$("$SETTINGS" get)
jq -e '.profiles.Work.fontSize == 16 and .profiles.Games.fontSize == 20 and .activeProfile == "Games"' <<<"$merged" >/dev/null
# Invalid catalog data is preserved before a safe empty catalog is created.
printf '{bad json' > "$PROFILES"
merged=$("$SETTINGS" get 2>"$TMP_ROOT/recovery.log")
jq -e '(.profiles.Work.fontSize == 15) and ((.profiles | has("Games")) | not) and .activeProfile == "Games"' <<<"$merged" >/dev/null
find "$(dirname "$PROFILES")" -maxdepth 1 -type f -name '.profiles.json.corrupt.*' | grep -q .
grep -q 'invalid profiles file preserved' "$TMP_ROOT/recovery.log" || grep -q 'invalid profiles file preserved' "$TMP_ROOT/recovery.log"
# Storage overview points to the independent editable catalog.
paths=$("$ROOT/scripts/storage_paths" list)
jq -e --arg path "$PROFILES" '.entries[] | select(.id == "profiles") | .path == $path and (.description | contains("редактировать вручную"))' <<<"$paths" >/dev/null
echo 'Separate profiles.json migration, persistence, recovery and storage listing: OK'

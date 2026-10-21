#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fixture="$TMP_ROOT/project"
home_dir="$TMP_ROOT/home"
mkdir -p "$fixture/scripts" "$home_dir"
cp "$ROOT/scripts/env" "$ROOT/scripts/settings" "$ROOT/scripts/calendar_notes" "$fixture/scripts/"

# Simulate a previous release that kept both JSON files beside the project.
cat > "$fixture/settings.json" <<'JSON'
{"weatherToken":"migration-test-token","modules":{"time":true,"timer":true},"geometry":{"player":{"x":17,"y":23}}}
JSON
cat > "$fixture/calendar-notes.json" <<'JSON'
{"2026-10-09":"legacy calendar note"}
JSON

export HOME="$home_dir"
export XDG_CONFIG_HOME="$home_dir/xdg-config"
export XDG_DATA_HOME="$home_dir/xdg-data"
export XDG_STATE_HOME="$home_dir/xdg-state"
export XDG_CACHE_HOME="$home_dir/xdg-cache"
unset QS_CONFIG_DIR QS_DATA_DIR QS_STATE_DIR QS_CACHE_DIR QS_PROJECT_DIR || true

settings_output="$("$fixture/scripts/settings" get)"
notes_output="$("$fixture/scripts/calendar_notes" get)"
[[ "$(jq -r '.weatherToken' <<< "$settings_output")" == "migration-test-token" ]]
[[ "$(jq -r '."2026-10-09"' <<< "$notes_output")" == "legacy calendar note" ]]
[[ -f "$XDG_CONFIG_HOME/quickshell-widgets/settings.json" ]]
[[ -f "$XDG_DATA_HOME/quickshell-widgets/calendar-notes.json" ]]
[[ -f "$fixture/settings.json" && -f "$fixture/calendar-notes.json" ]]

# Existing canonical data must never be overwritten by the retained legacy copy.
printf '%s\n' '{"weatherToken":"canonical-value"}' > "$XDG_CONFIG_HOME/quickshell-widgets/settings.json"
settings_output="$("$fixture/scripts/settings" get)"
[[ "$(jq -r '.weatherToken' <<< "$settings_output")" == "canonical-value" ]]
# A reset/removal after migration must not resurrect the retained legacy file.
rm -f "$XDG_CONFIG_HOME/quickshell-widgets/settings.json"
settings_output="$("$fixture/scripts/settings" get)"
[[ "$(jq -r '.weatherToken' <<< "$settings_output")" == "" ]]
rm -f "$XDG_DATA_HOME/quickshell-widgets/calendar-notes.json"
notes_output="$("$fixture/scripts/calendar_notes" get)"
[[ "$(jq -r 'length' <<< "$notes_output")" == "0" ]]

# All XDG directories should be discoverable from scripts/env, including caches/state.
env_info="$(bash -c 'source "$1"; printf "%s\n%s\n%s\n%s" "$QS_CONFIG_DIR" "$QS_DATA_DIR" "$QS_STATE_DIR" "$QS_CACHE_DIR"' _ "$fixture/scripts/env")"
[[ "$(sed -n '1p' <<< "$env_info")" == "$XDG_CONFIG_HOME/quickshell-widgets" ]]
[[ "$(sed -n '2p' <<< "$env_info")" == "$XDG_DATA_HOME/quickshell-widgets" ]]
[[ "$(sed -n '3p' <<< "$env_info")" == "$XDG_STATE_HOME/quickshell-widgets" ]]
[[ "$(sed -n '4p' <<< "$env_info")" == "$XDG_CACHE_HOME/quickshell-widgets" ]]

# Also import from a previous default install when this project is running
# from a different source directory and contains no legacy data itself.
legacy_home="$TMP_ROOT/legacy-home"
new_project="$TMP_ROOT/second-project"
mkdir -p "$legacy_home/config/quickshell/desktop-shell" "$new_project/scripts"
cp "$ROOT/scripts/env" "$ROOT/scripts/settings" "$ROOT/scripts/calendar_notes" "$new_project/scripts/"
printf '%s\n' '{"modules":{"time":true,"timer":true},"geometry":{}}' > "$legacy_home/config/quickshell/desktop-shell/settings.json"
printf '%s\n' '{"2025-01-02":"old install note"}' > "$legacy_home/config/quickshell/desktop-shell/calendar-notes.json"
HOME="$legacy_home" XDG_CONFIG_HOME="$legacy_home/config" XDG_DATA_HOME="$legacy_home/share" XDG_STATE_HOME="$legacy_home/state" XDG_CACHE_HOME="$legacy_home/cache" \
    "$new_project/scripts/settings" get > "$TMP_ROOT/sibling-settings.json"
HOME="$legacy_home" XDG_CONFIG_HOME="$legacy_home/config" XDG_DATA_HOME="$legacy_home/share" XDG_STATE_HOME="$legacy_home/state" XDG_CACHE_HOME="$legacy_home/cache" \
    "$new_project/scripts/calendar_notes" get > "$TMP_ROOT/sibling-notes.json"
[[ "$(jq -r '.modules.timer' "$TMP_ROOT/sibling-settings.json")" == "true" ]]
[[ "$(jq -r '."2025-01-02"' "$TMP_ROOT/sibling-notes.json")" == "old install note" ]]
[[ -f "$legacy_home/config/quickshell/desktop-shell/settings.json" && -f "$legacy_home/config/quickshell/desktop-shell/calendar-notes.json" ]]


# The installer also migrates data already present in the traditional
# ~/.config/quickshell/desktop-shell location before copying the new code.
install_home="$TMP_ROOT/install-home"
install_config="$install_home/config"
install_data="$install_home/share"
mkdir -p "$install_config/quickshell/desktop-shell"
printf '%s\n' '{"weatherToken":"installer-token","modules":{"time":true,"timer":true},"geometry":{}}' > "$install_config/quickshell/desktop-shell/settings.json"
printf '%s\n' '{"2025-04-01":"installer note"}' > "$install_config/quickshell/desktop-shell/calendar-notes.json"
HOME="$install_home" XDG_CONFIG_HOME="$install_config" XDG_DATA_HOME="$install_data" \
    XDG_STATE_HOME="$install_home/state" XDG_CACHE_HOME="$install_home/cache" \
    "$ROOT/install.sh" > "$TMP_ROOT/install.log"
[[ "$(jq -r '.weatherToken' "$install_config/quickshell-widgets/settings.json")" == "installer-token" ]]
[[ "$(jq -r '."2025-04-01"' "$install_data/quickshell-widgets/calendar-notes.json")" == "installer note" ]]
[[ -f "$install_config/quickshell/desktop-shell/settings.json" && -f "$install_config/quickshell/desktop-shell/calendar-notes.json" ]]

echo "XDG migration: OK"

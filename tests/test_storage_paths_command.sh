#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$TMP/config-home/"
export XDG_DATA_HOME="$TMP/data-home/"
export XDG_STATE_HOME="$TMP/state-home/"
export XDG_CACHE_HOME="$TMP/cache-home/"
export XDG_RUNTIME_DIR="$TMP/runtime-dir/"
export WEATHER_CACHE_DIR="$TMP/custom-weather-cache/"
mkdir -p "$HOME"

output="$("$ROOT/scripts/storage_paths")"
printf '%s\n' "$output" | jq -e '.entries | length >= 10' >/dev/null
expected_config="$TMP/config-home/quickshell-widgets"
expected_data="$TMP/data-home/quickshell-widgets"
expected_state="$TMP/state-home/quickshell-widgets"
expected_cache="$TMP/cache-home/quickshell-widgets"
[[ "$(jq -r '.entries[] | select(.id == "settings") | .path' <<<"$output")" == "$expected_config/settings.json" ]]
[[ "$(jq -r '.entries[] | select(.id == "profiles") | .path' <<<"$output")" == "$expected_config/profiles.json" ]]
[[ "$(jq -r '.entries[] | select(.id == "settingsBackup") | .path' <<<"$output")" == "$expected_config/.settings.json.bak" ]]
[[ "$(jq -r '.entries[] | select(.id == "calendarNotes") | .path' <<<"$output")" == "$expected_data/calendar-notes.json" ]]
[[ "$(jq -r '.entries[] | select(.id == "calendarMarks") | .path' <<<"$output")" == "$expected_data/calendar-marks.json" ]]
[[ "$(jq -r '.entries[] | select(.id == "stateDir") | .path' <<<"$output")" == "$expected_state" ]]
[[ "$(jq -r '.entries[] | select(.id == "weatherCache") | .path' <<<"$output")" == "$TMP/custom-weather-cache" ]]
[[ "$(jq -r '.entries[] | select(.id == "mopidyCovers") | .path' <<<"$output")" == "$expected_cache/mopidy-covers" ]]
[[ "$(jq -r '.entries[] | select(.id == "launcherHistory") | .path' <<<"$output")" == "$HOME/.cache/quickshell-launcher-run-history" ]]
[[ "$(jq -r '.entries[] | select(.id == "timerRuntimeDir") | .path' <<<"$output")" == "$TMP/runtime-dir/timer" ]]
jq -e '.entries[] | select(.id == "profiles") | .description | contains("профилей")' <<<"$output" >/dev/null
jq -e '[.entries[] | select(.editable == true) | .id] | sort == ["calendarMarks","calendarNotes","profiles","settings"]' <<<"$output" >/dev/null
printf 'storage paths command: OK\n'

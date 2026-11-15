#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIELD="$ROOT/components/settings/primitives/SettingsFontField.qml"
assert_direct() {
    local file="$1" key="$2"
    grep -Fq 'SettingsFontField {' "$file"
    grep -Fq "targetProperty: \"$key\"" "$file"
}

# Every editable font-family setting uses the shared primitive, including the
# settings UI font itself. Font-size settings are intentionally not included.
assert_direct "$ROOT/components/settings/sections/SettingsGeneralSection.qml" font
assert_direct "$ROOT/components/settings/sections/SettingsGeneralSection.qml" ledFont
assert_direct "$ROOT/components/settings/sections/SettingsWindowSection.qml" settingsFont
assert_direct "$ROOT/components/settings/sections/SettingsPlayerSection.qml" playerFont
assert_direct "$ROOT/components/settings/sections/SettingsPlayerSection.qml" playerTimeFont
assert_direct "$ROOT/components/settings/sections/SettingsPlayerSection.qml" playerMetaFont
assert_direct "$ROOT/components/settings/sections/SettingsTimersSection.qml" timerFinishedTitleFont
assert_direct "$ROOT/components/settings/sections/SettingsLauncherSection.qml" launcherTitleFont
assert_direct "$ROOT/components/settings/sections/SettingsLauncherSection.qml" launcherSearchFont
assert_direct "$ROOT/components/settings/sections/SettingsCpuRamSection.qml" topAppsFont
assert_direct "$ROOT/components/settings/sections/mopidy/SettingsMopidyStatusSection.qml" mopidyStatusFont
for key in mopidyQueueDurationFont mopidyAlbumFont mopidyTrackFont mopidyArtistFont mopidyDurationFont; do
    assert_direct "$ROOT/components/settings/sections/mopidy/SettingsMopidyTimeSection.qml" "$key"
done
for key in calendarTitleFont calendarWeekdayFont calendarDayFont; do
    assert_direct "$ROOT/components/settings/sections/SettingsCalendarSection.qml" "$key"
done
assert_direct "$ROOT/components/settings/sections/SettingsNetworkSection.qml" networkFont

# Weather direction family fields are routed through the same primitive and
# retain all nine per-direction Config bindings via the row's value API.
WEATHER_ROW="$ROOT/components/settings/sections/WeatherWindDirectionSettingsRow.qml"
grep -Fq 'SettingsFontField {' "$WEATHER_ROW"
grep -Fq 'value: root.fontValue' "$WEATHER_ROW"
grep -Fq 'root.fontEdited(value)' "$WEATHER_ROW"
WEATHER_SECTION="$ROOT/components/settings/sections/SettingsWeatherSection.qml"
for key in weatherWindCalmFont weatherWindNFont weatherWindNEFont weatherWindEFont weatherWindSEFont weatherWindSFont weatherWindSWFont weatherWindWFont weatherWindNWFont; do
    grep -Fq "fontValue: Config.$key" "$WEATHER_SECTION"
    grep -Fq "Config.$key = value" "$WEATHER_SECTION"
done

# Primitive always exposes a text field and a dedicated action that resets to
# the system font (empty family), committing through the same settings path.
grep -Fq 'SettingsInputField {' "$FIELD"
grep -Fq 'SettingsResetButton {' "$FIELD"
grep -Fq 'onClicked: root.commit("")' "$FIELD"
grep -Fq 'targetObject[root.targetProperty] = family' "$FIELD"

echo 'All editable font-family settings use SettingsFontField: OK'

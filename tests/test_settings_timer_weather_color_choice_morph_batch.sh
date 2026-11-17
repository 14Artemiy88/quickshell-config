#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMERS="$ROOT/components/settings/sections/SettingsTimersSection.qml"
WEATHER="$ROOT/components/settings/sections/SettingsWeatherSection.qml"
fail() { echo "Timer/Weather conditional color MorphGeometry batch: FAIL: $*" >&2; exit 1; }

for file in "$TIMERS" "$WEATHER"; do
    grep -Fq 'import "../../primitives"' "$file" || fail "shared MorphGeometry import missing in $(basename "$file")"
done

python3 - "$TIMERS" "$WEATHER" <<'PYTEST'
from pathlib import Path
import sys

def block_by_id(source: str, object_name: str, object_id: str) -> str:
    needle = f"{object_name} {{\n                id: {object_id}"
    start = source.find(needle)
    if start < 0:
        # Weather's nested block uses a slightly different indentation.
        needle = f"{object_name} {{\n            id: {object_id}"
        start = source.find(needle)
    assert start >= 0, f"{object_id} block missing"
    brace = source.find("{", start)
    depth = 0
    quote = None
    escaped = False
    for i in range(brace, len(source)):
        c = source[i]
        if quote:
            if escaped:
                escaped = False
            elif c == "\\":
                escaped = True
            elif c == quote:
                quote = None
            continue
        if c in ('"', "'"):
            quote = c
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return source[start:i + 1]
    raise AssertionError(f"{object_id} braces are unbalanced")

timers = Path(sys.argv[1]).read_text(encoding="utf-8")
weather = Path(sys.argv[2]).read_text(encoding="utf-8")

# Custom timer finished-title color.
title = block_by_id(timers, "MorphGeometry", "timerFinishedTitleColorMorph")
for token in (
    'visible: !Config.timerFinishedTitleUsesTimerColor || normalizedProgress > 0.001',
    'progress: !Config.timerFinishedTitleUsesTimerColor ? 1 : 0',
    'animationDuration: Config.animationDuration(180, "appearance")',
    'animationEasing: Config.animationEasingType("standard", !Config.timerFinishedTitleUsesTimerColor ? "enter" : "exit")',
    'text: "Свой цвет заголовка"',
    'targetProperty: "timerFinishedTitleColor"',
    'saveOnEdit: true',
):
    assert token in title, f"title-color morph missing or altered: {token}"
assert title.count('visible:') == 1, "title color row must remain alive during collapse"

# Custom timer finished-background color.
background = block_by_id(timers, "MorphGeometry", "timerFinishedBackgroundColorMorph")
for token in (
    'visible: !Config.timerFinishedBackgroundUsesTimerColor || normalizedProgress > 0.001',
    'progress: !Config.timerFinishedBackgroundUsesTimerColor ? 1 : 0',
    'animationDuration: Config.animationDuration(180, "appearance")',
    'animationEasing: Config.animationEasingType("standard", !Config.timerFinishedBackgroundUsesTimerColor ? "enter" : "exit")',
    'text: "Свой цвет фона"',
    'targetProperty: "timerFinishedBackgroundColor"',
    'saveOnEdit: true',
):
    assert token in background, f"background-color morph missing or altered: {token}"
assert background.count('visible:') == 1, "background color row must remain alive during collapse"

# Weather comfort options are one measured group controlled by the existing show checkbox.
comfort = block_by_id(weather, "MorphGeometry", "weatherComfortOptionsMorph")
for token in (
    'visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 1',
    '&& (Config.weatherShowComfort || normalizedProgress > 0.001)',
    'toGeometry: Qt.rect(0, 0, parent.width, weatherComfortOptionsContent.implicitHeight)',
    'progress: Config.weatherShowComfort ? 1 : 0',
    'animationDuration: Config.animationDuration(180, "appearance")',
    'animationEasing: Config.animationEasingType("standard", Config.weatherShowComfort ? "enter" : "exit")',
    'id: weatherComfortOptionsContent',
    'label: "Цвет обводки"',
    'targetProperty: "weatherComfortOutlineColor"',
    'targetProperty: "weatherComfortOutlineWidth"',
    'id: weatherComfortYField',
    'id: weatherComfortOffsetXField',
):
    assert token in comfort, f"weather comfort morph missing or altered: {token}"
assert 'visible: Config.weatherShowComfort' not in comfort, "weather controls must stay alive during collapse"
checkbox_start = weather.rfind('id: weatherShowComfortCheckBox', 0, weather.find('id: weatherComfortOptionsMorph'))
assert checkbox_start >= 0, "weather show checkbox moved or removed"
checkbox = weather[checkbox_start:weather.find('MorphGeometry {', checkbox_start)]
assert 'checked: Config.weatherShowComfort' in checkbox, "weather show checkbox binding changed"
assert 'Config.weatherShowComfort = checked; settings.save()' in checkbox, "weather show checkbox save path changed"

print("Timer title/background colors + Weather comfort options MorphGeometry: OK")
PYTEST

grep -Fq 'test_settings_timer_weather_color_choice_morph_batch.sh' "$ROOT/CHECK.sh" || fail "test not registered in CHECK.sh"
printf 'Timer/Weather conditional color MorphGeometry batch: OK\n'

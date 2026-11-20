#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
checks = {
    "components/WeatherNow.qml": [
        ('animationProfile: Config.animationWeatherMorphProfile', 3),
        ('animationPhase: weatherComfortLabel.shouldShow ? "enter" : "exit"', 1),
        ('animationPhase: root.hasData && Config.weatherIconPlacement !== "off" ? "enter" : "exit"', 1),
        ('animationPhase: root.hasData ? "enter" : "exit"', 1),
    ],
    "components/TimerWidget.qml": [
        ('animationProfile: Config.animationTimerMorphProfile', 5),
        ('animationPhase: Config.timerIconEnabled && root.controlsMode === 0 ? "enter" : "exit"', 1),
        ('animationPhase: Config.timerAlarmIconEnabled && root.controlsMode === 0 ? "enter" : "exit"', 1),
    ],
    "components/CalendarWidget.qml": [
        ('animationProfile: Config.animationCalendarMorphProfile', 1),
        ('animationPhase: root.noteOverlayMode !== "" ? "enter" : "exit"', 1),
    ],
}
for name, entries in checks.items():
    data = (root / name).read_text(encoding="utf-8")
    for token, count in entries:
        actual = data.count(token)
        assert actual == count, f"{name}: {token!r}: expected {count}, got {actual}"
# Existing pilot migrations remain intact and unrelated MorphGeometry instances are untouched.
network = (root / "components/NetworkStat.qml").read_text(encoding="utf-8")
assert network.count('animationProfile: "expressive"') == 2
for name, token, count in (
    ("components/WeatherPlaceholder.qml", "animationProfile: Config.animationWeatherMorphProfile", 1),
    ("components/WeatherForecastItem.qml", "animationProfile: Config.animationWeatherMorphProfile", 2),
    ("components/Player.qml", "animationProfile: Config.animationPlayerMorphProfile", 3),
    ("components/mopidy/MopidyPlaylistDialog.qml", "animationProfile: Config.animationMopidyMorphProfile", 1),
):
    data = (root / name).read_text(encoding="utf-8")
    assert data.count(token) == count, name
print("Expressive morph expansion 2 (WeatherNow, Timer, Calendar): OK")
PY

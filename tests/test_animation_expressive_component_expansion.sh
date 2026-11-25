#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys
root = Path(sys.argv[1])
checks = {
    "components/WeatherForecastItem.qml": {
        'animationProfile: Config.animationWeatherMorphProfile': 2,
        'animationPhase: root.hasHighTemperature ? "enter" : "exit"': 1,
        'animationPhase: root.hasLowTemperature ? "enter" : "exit"': 1,
        'Config.animationEasingType(Config.animationWeatherMorphProfile, root.hasHighTemperature ? "enter" : "exit")': 1,
        'Config.animationEasingType(Config.animationWeatherMorphProfile, root.hasLowTemperature ? "enter" : "exit")': 1,
        'readonly property int forecastMorphDuration: Config.animationDurationForProfile(Config.animationWeatherMorphEnabled, Config.animationWeatherMorphProfile, Config.animationWeatherMorphDuration, "appearance")': 1,
    },
    "components/Player.qml": {
        'animationProfile: Config.animationPlayerMorphProfile': 3,
        'animationPhase: root.playerMetadataExpanding ? "enter" : "exit"': 1,
        'animationPhase: root.playerNextSupported ? "enter" : "exit"': 1,
        'animationPhase: Config.playerShowProgress ? "enter" : "exit"': 1,
        'Config.animationEasingType(Config.animationPlayerMorphProfile, root.playerMetadataExpanding ? "enter" : "exit")': 1,
        'Config.animationEasingType(Config.animationPlayerMorphProfile, root.playerNextSupported ? "enter" : "exit")': 1,
        'Config.animationEasingType(Config.animationPlayerMorphProfile, Config.playerShowProgress ? "enter" : "exit")': 1,
        'animationDuration: Config.animationDurationForProfile(Config.animationPlayerMorphEnabled, Config.animationPlayerMorphProfile, Config.animationPlayerMorphDuration, "appearance")': 3,
    },
    "components/mopidy/MopidyPlaylistDialog.qml": {
        'animationProfile: Config.animationMopidyMorphProfile': 1,
        'animationPhase: controller.playlistDialogVisible ? "enter" : "exit"': 1,
        'animationDuration: Config.animationDurationForProfile(Config.animationMopidyMorphEnabled, Config.animationMopidyMorphProfile, Config.animationMopidyMorphDuration, "appearance")': 1,
    },
}
for name, expected in checks.items():
    content = (root / name).read_text(encoding="utf-8")
    for token, count in expected.items():
        actual = content.count(token)
        assert actual == count, f"{name}: expected {count} occurrences of {token!r}, got {actual}"
# Forecast weather icons must remain on the direct Image path; this was a known live-QML constraint.
forecast = (root / "components/WeatherForecastItem.qml").read_text(encoding="utf-8")
assert 'Keep forecast icons on the original direct Image path' in forecast
assert re.search(r'Image\s*\{\s*id:\s*forecastIconImage\s*\n\s*x:', forecast), "Forecast icon must remain a direct Image with its stable id and explicit x geometry"
# Existing pilot components remain opt-in; no blanket conversion or global default change.
network = (root / "components/NetworkStat.qml").read_text(encoding="utf-8")
assert network.count('animationProfile: "expressive"') == 2
placeholder = (root / "components/WeatherPlaceholder.qml").read_text(encoding="utf-8")
assert placeholder.count('animationProfile: Config.animationWeatherMorphProfile') == 1
print("Expressive component expansion (Weather forecast, Player, Mopidy dialog): OK")
PY

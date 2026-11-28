#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
config = (root / "Config.qml").read_text()
defaults = (root / "js/settings/SettingsDefaults.js").read_text()
persistence = (root / "js/settings/SettingsPersistence.js").read_text()
apply_core = (root / "js/settings/SettingsApplyCore.js").read_text()
apply_player = (root / "js/settings/SettingsApplyTimerPlayer.js").read_text()
resets = (root / "js/settings/SettingsResets.js").read_text()
nav = (root / "components/settings/SettingsNavigationController.qml").read_text()
ui = (root / "components/settings/sections/SettingsPlayerSection.qml").read_text()
player = (root / "components/Player.qml").read_text()

assert 'property string playerSilenceOutlineColor: "#000000"' in config
assert 'property int playerSilenceOutlineWidth: 1' in config
assert 'playerSilenceOutlineColor: "#000000"' in defaults
assert 'playerSilenceOutlineWidth: 1' in defaults
assert 'playerSilenceOutlineColor: String(config.playerSilenceOutlineColor)' in persistence
assert 'playerSilenceOutlineWidth: config.playerSilenceOutlineWidth' in persistence
assert 'if (o.playerSilenceOutlineColor !== undefined) Config.playerSilenceOutlineColor = String(o.playerSilenceOutlineColor)' in apply_core
assert '["playerSilenceOutlineWidth", 0, 4]' in apply_player
assert '"playerSilenceOutlineColor", "playerSilenceOutlineWidth"' in resets
assert '"playerSilenceOutlineColor", "playerSilenceOutlineWidth"' in ui
assert 'targetProperty: "playerSilenceOutlineColor"' in ui
assert 'targetProperty: "playerSilenceOutlineWidth"' in ui
assert 'minimum: 0' in ui and 'maximum: 4' in ui
assert '{ prefixes: ["playerSilence"] }' in nav
assert 'readonly property var silenceOutlineOffsets' in player
assert 'model: root.silenceOutlineOffsets' in player
assert 'color: Config.playerSilenceOutlineColor' in player
assert 'style: Text.Normal' in player
# The fallback text now has its own configurable outline instead of sharing the
# metadata outline toggle/color. Metadata continues to use playerTextOutline*.
assert 'style: Config.playerTextOutlineEnabled ? Text.Outline : Text.Normal' not in player[player.index('id: silenceText'):player.index('// Metadata grows upward')]
assert 'style: Config.playerTextOutlineEnabled ? Text.Outline : Text.Normal' in player[player.index('// Metadata grows upward'):]
print("Player Silence outline rendering/settings/profile/reset wiring: OK")
PY

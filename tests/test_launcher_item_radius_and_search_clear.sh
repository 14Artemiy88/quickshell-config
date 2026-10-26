#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
SECTION="$ROOT/components/settings/sections/SettingsLauncherSection.qml"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"

# The rounding option has defaults, persistence, validation, and profile-reset wiring.
grep -Fq 'property int launcherItemRadius: 11' "$CONFIG"
grep -Fq 'launcherItemRadius: 11' "$DEFAULTS"
grep -Fq 'launcherItemRadius: config.launcherItemRadius' "$PERSIST"
grep -Fq '["launcherItemRadius", 0, 30]' "$APPLY"
grep -Fq '"launcherItemHeight", "launcherItemRadius", "launcherRadius"' "$RESETS"
grep -Fq 'targetProperty: "launcherItemRadius"' "$SECTION"
grep -Fq 'text: "Скругление элементов"' "$SECTION"

# The list-item height and rounding are in their own frame; background color is grouped into Elements.
grep -Fq 'heading: "Элемент списка"' "$SECTION"
grep -Fq 'heading: "Окно лаунчера"' "$SECTION"
grep -Fq 'label: "Фон окна лаунчера"' "$SECTION"
# Window controls must appear before list-item height/radius controls.
python3 - "$SECTION" <<'PY2'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
assert s.index('heading: "Окно лаунчера"') < s.index('heading: "Элемент списка"')
window_start = s.index('heading: "Окно лаунчера"')
item_start = s.index('heading: "Элемент списка"')
assert 'targetProperty: "launcherRadius"' in s[window_start:item_start]
assert 'targetProperty: "launcherBackground"' in s[window_start:item_start]
assert 'targetProperty: "launcherItemHeight"' in s[item_start:]
assert 'targetProperty: "launcherItemRadius"' in s[item_start:]
PY2
if grep -Eq 'text: "Элементы и фон"|text: "Внешний вид"' "$SECTION"; then
    echo 'Old duplicated launcher appearance frame still exists' >&2
    exit 1
fi
[[ "$(grep -Fc 'targetProperty: "launcherItemHeight"' "$SECTION")" -eq 1 ]]

# Every top-level launcher list delegate uses the new common radius setting.
[[ "$(grep -Fc 'radius: Config.launcherItemRadius' "$LAUNCHER")" -eq 10 ]]

# Closing clears the query; tab switching itself must continue to preserve it.
python3 - "$LAUNCHER" <<'PY'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
hide_start = s.index('    function hideLauncher() {')
hide_end = s.index('\n    }', hide_start)
hide = s[hide_start:hide_end]
assert 'searchField.text = ""' in hide
assert hide.index('searchField.text = ""') < hide.index('root.visible = false')
mode_start = s.index('    function setMode(newMode) {')
mode_end = s.index('\n    function activeListForMode', mode_start)
set_mode = s[mode_start:mode_end]
assert 'Keep a single query while switching tabs' in set_mode
assert 'searchField.text = ""' not in set_mode
PY

echo 'Launcher item-radius setting and clear-search-on-close: OK'

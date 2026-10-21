#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TIME="$ROOT/components/settings/sections/mopidy/SettingsMopidyTimeSection.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"

python3 - "$TIME" "$WIDGET" <<'PYCODE'
from pathlib import Path
import sys
section = Path(sys.argv[1]).read_text()
widget = Path(sys.argv[2]).read_text()

# X and Y remain independently adjustable, but the row title does not repeat
# the axis labels that immediately follow it.
assert section.count('targetProperty: "mopidyQueueDurationX"') == 1, "Queue duration X control is duplicated"
assert section.count('targetProperty: "mopidyQueueDurationY"') == 1, "Queue duration Y control is duplicated"
assert section.count('text: "Положение"') == 1, "Expected one concise position-row label"
assert 'text: "Положение X / Y"' not in section, "Position label redundantly repeats X/Y"
assert widget.count('MopidySettings.SettingsMopidyTimeSection {') == 1, "Mopidy time settings section is instantiated more than once"
assert 'visible: host && host.currentOtherTab === 10 && host.currentOtherSubTab === 1' in section, "Mopidy time settings are not scoped to the Time subtab"
assert 'пример:  ·  /  —  /  |' not in section, "Separator example helper text must be removed"
PYCODE

echo 'Mopidy time settings duplicate rows and separator helper: OK'

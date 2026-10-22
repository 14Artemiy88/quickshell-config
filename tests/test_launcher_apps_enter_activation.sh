#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"

# Enter and keypad Enter in Apps activate the selected entry from the search field.
python3 - "$LAUNCHER" <<'PY'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
start = s.index('// Apps: Enter/Return launches the currently selected')
end = s.index('// Packages: Enter keeps the primary fast workflow', start)
block = s[start:end]
assert 'root.mode === root.modeApps' in block
assert 'event.key === Qt.Key_Return' in block
assert 'event.key === Qt.Key_Enter' in block
assert 'root.launchCurrent()' in block
assert 'event.accepted = true' in block
assert block.index('root.launchCurrent()') < block.index('event.accepted = true')
# launchCurrent routes the selected unified Apps result through the same activation helper as mouse clicks.
launch_start = s.index('function launchCurrent()')
launch_end = s.index('\n    function focusWindow', launch_start)
launch = s[launch_start:launch_end]
assert 'root.appsUnifiedResults[index]' in launch
assert 'root.activateAppsSearchResult' in launch
entry_start = s.index('function launchEntry(entry)')
entry_end = s.index('\n    function launchCurrent()', entry_start)
entry = s[entry_start:entry_end]
assert 'entry.execute()' in entry
assert 'root.hideLauncher()' in entry
print('Launcher Apps Enter/Return activation: OK')
PY

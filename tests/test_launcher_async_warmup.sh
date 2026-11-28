#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
shell = (root / "shell.qml").read_text()
launcher = (root / "components/launcher/Launcher.qml").read_text()

def block(source, start, end):
    a = source.index(start)
    b = source.index(end, a)
    return source[a:b]

# The launcher remains outside critical startup, then its component is warmed
# asynchronously after settings load and only when the feature is enabled.
loader = block(shell, 'id: launcherLoader', 'onLoaded:')
assert 'active: false' in loader
assert 'asynchronous: true' in loader
assert 'source: "components/launcher/Launcher.qml"' in loader
warmup = block(shell, 'id: launcherWarmupTimer', 'Loader {\n        id: launcherLoader')
assert 'interval: 1800' in warmup and 'repeat: false' in warmup
assert 'Settings.loaded && Config.launcherEnabled && launcherLoader.status === Loader.Null' in warmup
assert 'launcherLoader.active = true' in warmup
assert warmup.index('Settings.loaded && Config.launcherEnabled') < warmup.index('launcherLoader.active = true')

# Warm-up must not perform user-data I/O or launch restore processes. Initialization
# is idempotent and is entered only from actual user-facing launch/edit actions.
assert 'property bool launcherInitialized: false' in launcher
initialize = block(launcher, 'function initializeLauncher()', 'function beginLayoutEdit()')
for action in ('loadRunHistoryFromDisk()', 'loadCalculatorHistoryFromDisk()',
               'loadEmojiPickerDataFromDisk()', 'loadWallpaperPickerDataFromDisk()',
               'appModel.refreshUsageHistory()', 'root.resetSelection()'):
    assert action in initialize, f'missing deferred initialization action: {action}'
assert 'if (root.launcherInitialized) return false' in initialize
assert 'root.launcherInitialized = true' in initialize
for name, end in (
    ('function beginLayoutEdit()', 'function cancelLayoutDrag()'),
    ('function showLauncher()', 'function hideLauncher()'),
    ('function openMode(modeName)', 'function setMode(newMode)'),
):
    entry = block(launcher, name, end)
    assert 'root.initializeLauncher()' in entry, f'{name} must initialize on real use'
# Component construction during warm-up must have no user-data/restore side effects.
assert 'Component.onCompleted: {\n        loadRunHistoryFromDisk()' not in launcher
print('Launcher asynchronous idle warm-up and deferred side-effect initialization: OK')
PY
echo 'launcher async warm-up: OK'

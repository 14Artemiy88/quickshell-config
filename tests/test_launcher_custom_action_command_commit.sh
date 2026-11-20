#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECTION="$ROOT/components/settings/sections/SettingsLauncherSection.qml"
SETTINGS="$ROOT/Settings.qml"
python3 - "$SECTION" "$SETTINGS" <<'PYCODE'
from pathlib import Path
import sys
section = Path(sys.argv[1]).read_text()
settings = Path(sys.argv[2]).read_text()
start = section.index('id: customActionCommandField')
end = section.index('\n                }\n            }\n        }\n\n        SettingsButton {\n            width: 175', start)
editor = section[start:end]
assert 'onAccepted: customActionCard.saveAction()' in editor
assert 'text: "Сохранить действие"' in editor
assert 'onClicked: customActionCard.saveAction()' in editor
assert 'onEditingFinished: customActionCard.saveAction()' in editor, 'command focus loss must pass through validation'
assert 'function updateLauncherCustomActionFields(index, values)' in settings
start_save = settings.index('function updateLauncherCustomActionFields(index, values)')
end_save = settings.index('function addLauncherCustomAction()', start_save)
assert 'root.save()' in settings[start_save:end_save]
PYCODE
printf 'launcher custom action is submitted through explicit validation and atomic save paths: OK\n'

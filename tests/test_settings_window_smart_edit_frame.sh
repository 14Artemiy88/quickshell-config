#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/settings/sections/SettingsWindowSection.qml" <<'PY'
from pathlib import Path
import sys
qml = Path(sys.argv[1]).read_text(encoding="utf-8")
heading = qml.index('heading: "Положение и размер окна"')
start = qml.rfind("SettingsGroup {", 0, heading)
end = qml.index("\n    }\n\n    SettingsGroup {", heading)
group = qml[start:end]
assert "showFrame: true" in group, "the settings-window position group must have a visible frame"
for expected in (
    'model: ["X", "Y", "Width", "Height"]',
    'value: Number(settings.settingsGeometry[fieldIndex])',
    'text: "УМНОЕ ПЕРЕМЕЩЕНИЕ"',
    'onClicked: host.settingsMoveRequested()',
    'Esc — завершить перемещение и вернуться сюда.',
):
    assert expected in group, f"Smart Moving and coordinate controls must share the same frame: {expected}"
assert 'heading: "Положение и размер окна"' in group
print("Settings Window Smart Moving controls share the coordinates frame: OK")
PY

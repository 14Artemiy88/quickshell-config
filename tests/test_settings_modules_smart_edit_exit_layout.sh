#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/settings/sections/SettingsModulesSection.qml" <<'PYCODE'
from pathlib import Path
import sys
qml = Path(sys.argv[1]).read_text(encoding="utf-8")
start = qml.index('id: layoutEditButton')
end = qml.index('onClicked: host.layoutEditRequested()', start)
button = qml[start:end]
assert 'visible: true' in button, "Smart Editing button must remain in the row while the parent content is disabled for exit animation"
assert 'disabledTextColor: Config.accent' in button, "Smart Editing button must retain its accent appearance during the exit animation"
assert 'disabledBorderColor: Config.baseColor' in button, "Smart Editing button must retain its normal border during the exit animation"
assert 'Скрывает окно настроек и позволяет перетаскивать видимые модули, включая Dashboard, мышью.' in qml and 'Esc — завершить редактирование и вернуться сюда.' in qml, "Smart Editing description must remain adjacent to its fixed-width button"
print("Settings Modules Smart Editing row remains layout-stable during exit animation: OK")
PYCODE

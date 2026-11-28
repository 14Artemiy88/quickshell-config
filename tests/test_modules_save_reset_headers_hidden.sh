#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PYTEST'
from pathlib import Path
import sys
source = (Path(sys.argv[1]) / "components/settings/sections/SettingsModulesSection.qml").read_text()
assert 'text: "Сохр."' not in source and 'text: "Сброс"' not in source
assert 'SettingsSaveButton {' in source and 'SettingsResetButton {' in source
assert 'actionAvailable: host && host.profileController.canSaveScope' in source
assert 'actionAvailable: host.profileController.canResetScope' in source
assert 'tooltip: "Сбросить настройки модуля"' in source
print("Modules Save/Reset captions removed; conditional icon actions remain: OK")
PYTEST

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECTION="$ROOT/components/settings/sections/SettingsDashboardSection.qml"
python3 - "$SECTION" <<'PY'
from pathlib import Path
import re
import sys
source = Path(sys.argv[1]).read_text()
repeater = source.split('id: dashboardSettingsCardsRepeater', 1)[1]
delegate = repeater.split('delegate: Column {', 1)[1].split('\n            }\n        }', 1)[0]
assert 'required property var modelData' in delegate, 'Dashboard card delegate must explicitly receive modelData'
assert re.search(r'required\s+property\s+int\s+index\b', delegate), (
    'Dashboard card delegate must explicitly declare the Repeater index role when using required model properties'
)
assert 'itemIndex: cardSettings.index' in delegate, (
    'Dashboard DragReorderHandle must read the index from its owning delegate'
)
assert not re.search(r'itemIndex:\s*index\b', delegate), (
    'Dashboard DragReorderHandle must not reference an implicit index from a nested child scope'
)
print('Dashboard drag-reorder index binding: OK')
PY

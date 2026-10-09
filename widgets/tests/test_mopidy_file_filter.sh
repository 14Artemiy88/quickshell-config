#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/Mopidy.qml"
python3 - "$FILE" <<'PY'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text(encoding='utf-8')
required = [
    'property bool fileFilterOpen: false',
    'property string fileFilterQuery: ""',
    'readonly property var filteredBrowseDisplayEntries:',
    'event.text === "/"',
    'root.fileFilterOpen = true',
    'fileFilterField.forceActiveFocus()',
    'model: root.filteredBrowseDisplayEntries',
    'root.closeFileFilter(true)',
    'root.closeFileFilter(false)',
    'Совпадений нет',
]
missing = [x for x in required if x not in s]
if missing:
    raise SystemExit('Mopidy file-filter check failed; missing: ' + ', '.join(missing))
print('Mopidy file filter: OK')
PY

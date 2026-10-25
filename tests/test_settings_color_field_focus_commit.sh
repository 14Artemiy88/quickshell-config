#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIELD="$ROOT/components/settings/primitives/SettingsColorField.qml"
python3 - "$FIELD" <<'PY_EOF'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
assert 'property bool userEdited: false' in s, 'color field has no explicit user-edit state'
assert 'onTextEdited: userEdited = true' in s, 'real text edits are not tracked'
block = s.split('onEditingFinished: {', 1)[1].split('\n            }', 1)[0]
assert 'if (!userEdited)' in block, 'editingFinished can commit without a user edit'
assert 'field.text = String(root.value)' in block, 'no-edit focus exit does not restore current model value'
assert 'return' in block, 'no-edit path does not exit before commit'
assert 'userEdited = false' in block and 'root.commit(text)' in block, 'edited values are not committed and reset cleanly'
print('Color field focus/reset regression guard: OK')
PY_EOF

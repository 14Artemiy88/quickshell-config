#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsNavigation.qml"
CONTROLLER="$ROOT/components/settings/SettingsSearchController.qml"
fail() { echo "Settings search empty-state: FAIL: $*" >&2; exit 1; }

python3 - "$WIDGET" <<'PY'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
assert 'id: settingsSearchStatus' in s, 'inline search status item is missing'
block_start = s.index('id: settingsSearchStatus')
block_end = s.index('id: mainSettingsTabs', block_start)
status = s[block_start:block_end]
assert 'Config.settingsSearchVisible && root.searchQuery.trim().length > 0 ? 17 : 0' in status, 'status only appears for a visible, non-empty query'
assert '"Совпадений не найдено"' in status, 'empty result state is not explained'
assert '"Найдено совпадений: "' in status, 'non-empty result count is not reported'
assert 'Behavior on height' in status and 'Behavior on opacity' in status, 'status does not animate in and out'
assert 'settingsSearchStatus.height' in s, 'sidebar navigation does not reclaim status space when it hides'
assert 'settingsSearchPopup' not in s, 'a separate results popup must not be introduced'
PY

grep -Fq 'root.settingsSearchQuery = ""' "$CONTROLLER" || fail 'Escape does not clear the query'
grep -Fq 'root.settingsSearchResults = []' "$CONTROLLER" || fail 'Escape does not clear stale results'
grep -Fq 'root.searchInput.text = ""' "$CONTROLLER" || fail 'Escape does not clear the visible field'
grep -Fq 'root.applySettingsSearchHighlights()' "$CONTROLLER" || fail 'Escape does not remove stale highlight outlines'

echo 'settings search inline result status and Escape clear: OK'

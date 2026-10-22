#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT/components/settings/sections/SettingsColorsSection.qml" <<'PY'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text()
assert 'text: "Развернуть"' in s and 'checked: root.themesExpanded' in s
assert 'visible: root.themesExpanded' in s and 'model: settings.themeNames' in s
assert 'settings.themePreview(themeCard.themeName)' in s and 'settings.applyTheme(themeCard.themeName)' in s
assert 'settings.currentThemeModified' in s and 'Changed' in s
assert 'id: activeThemePreviewRow' in s and 'visible: !root.themesExpanded' in s, 'compact active-theme swatches should be hidden while the full theme list is expanded'
assert s.index('text: "Развернуть"') < s.index('id: themeCombo'), 'expand toggle must appear before the compact theme selector'
print('Expanded theme palette list and compact selector compatibility: OK')
PY

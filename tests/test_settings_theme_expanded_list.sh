#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT/components/settings/sections/SettingsColorsSection.qml" <<'PY'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text()
assert 'text: "Развернуть"' in s and 'checked: root.themesExpanded' in s
assert 'progress: root.themesExpanded ? 1 : 0' in s and 'model: settings.themeNames' in s
assert 'settings.themePreview(themeCard.themeName)' in s and 'settings.applyTheme(themeCard.themeName)' in s
assert 'settings.currentThemeModified' in s and 'Changed' in s
assert 'id: activeThemePreviewRow' in s and 'visible: !root.themesExpanded && expandedThemeList.normalizedProgress <= 0.001' in s, 'compact active-theme swatches should return only after the theme list finishes collapsing'
assert 'readonly property bool showThemeCombo: !root.themesExpanded' in s and 'expandedThemeList.normalizedProgress <= 0.001' in s and '(!settings.currentThemeModified || !root.editingColors)' in s, 'compact theme selector should return only after the theme list finishes collapsing'
assert s.index('text: "Развернуть"') < s.index('id: expandedThemeList') < s.index('id: themeSelectorSlot') < s.index('id: themeCombo'), 'expand toggle, theme list, and fixed selector slot must keep their intended order'
print('Expanded theme palette list and compact selector compatibility: OK')
PY

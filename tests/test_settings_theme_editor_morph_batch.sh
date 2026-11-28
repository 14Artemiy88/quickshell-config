#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COLORS="$ROOT/components/settings/sections/SettingsColorsSection.qml"
fail() { echo "Theme editor MorphGeometry batch: FAIL: $*" >&2; exit 1; }

grep -Fq 'import "../../primitives"' "$COLORS" || fail "shared MorphGeometry import missing"

python3 - "$COLORS" <<'PYTEST'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")

def block_by_id(object_name: str, object_id: str) -> str:
    needle = f"{object_name} {{\n                        id: {object_id}"
    start = source.find(needle)
    if start < 0:
        needle = f"{object_name} {{\n                    id: {object_id}"
        start = source.find(needle)
    assert start >= 0, f"{object_id} block missing"
    brace = source.find("{", start)
    depth = 0
    quote = None
    escaped = False
    for i in range(brace, len(source)):
        c = source[i]
        if quote:
            if escaped:
                escaped = False
            elif c == "\\":
                escaped = True
            elif c == quote:
                quote = None
            continue
        if c in ('"', "'"):
            quote = c
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return source[start:i + 1]
    raise AssertionError(f"{object_id} braces are unbalanced")

def verify_morph(block: str, state: str, height: str, name: str) -> None:
    visible_state = f"({state})" if "&&" in state else state
    checks = (
        f"visible: {visible_state} || normalizedProgress > 0.001",
        "fromGeometry: Qt.rect(0, 0, parent.width, 0)",
        f"toGeometry: Qt.rect(0, 0, parent.width, {height})",
        f"progress: {state} ? 1 : 0",
        'animationDuration: Config.animationDuration(180, "appearance")',
        f'animationEasing: Config.animationEasingType("ease-out", {state} ? "enter" : "exit")',
    )
    for token in checks:
        assert token in block, f"{name} morph missing or altered: {token}"

# The compact theme selector and modified-theme input intentionally share a fixed slot.
# Their replacement is immediate; only the color palette itself morphs.
selector = block_by_id("Item", "themeSelectorSlot")
assert 'readonly property bool showThemeCombo: !root.themesExpanded' in selector
assert 'expandedThemeList.normalizedProgress <= 0.001' in selector
assert '(!settings.currentThemeModified || !root.editingColors)' in selector
assert 'readonly property bool showModifiedThemeName: root.editingColors && settings.currentThemeModified' in selector
assert 'height: showThemeCombo || showModifiedThemeName ? 30 : 0' in selector
assert 'SettingsComboBox {' in selector and 'id: themeCombo' in selector
assert 'SettingsTextField {' in selector and 'id: themeNameField' in selector
assert 'visible: themeSelectorSlot.showThemeCombo' in selector
assert 'visible: themeSelectorSlot.showModifiedThemeName' in selector
assert 'id: modifiedThemeNameMorph' not in source, "selector replacement must not use MorphGeometry"
assert 'height: 30' in selector, "selector and input must share the same fixed height"
assert selector.index('id: themeCombo') < selector.index('id: themeNameField')
assert 'text: settings.activeTheme + " (Changed)"' in selector
assert 'function saveThemeFromField()' in selector
assert 'settings.saveCurrentTheme(name)' in selector
assert 'Keys.onReturnPressed: saveThemeFromField()' in selector

rename_state = "root.editingColors && settings.isCustomTheme(settings.activeTheme) && !settings.currentThemeModified"
rename = block_by_id("MorphGeometry", "customThemeRenameMorph")
verify_morph(rename, rename_state, "customThemeRenameContent.implicitHeight", "custom theme rename")
assert 'id: themeRenameField' in rename
assert 'function renameCurrentTheme()' in rename
assert 'settings.renameCustomTheme(settings.activeTheme, name)' in rename
assert 'id: themeDeleteButton' in rename
assert 'root.pendingDeleteThemeName = settings.activeTheme' in rename
assert 'settings.deleteCustomTheme(deletingName)' in rename
assert 'Удалить пользовательскую тему «' in rename
assert 'text: "Удалить"' in rename and 'text: "Отмена"' in rename
assert 'Подтвердить удаление темы' in rename
assert 'visible: root.editingColors' not in rename, "rename row must remain alive through collapse"
assert 'function showThemeFeedback(message, isError)' in source
assert 'settings.beginThemeEdit(settings.activeTheme)' in source
assert 'onValueEdited: function(value) { settings.setThemeDraftColor(colorName, value) }' in source
assert 'не более 32 символов' in source
assert 'themeActionMessageIsError ? Config.tempHot : Config.textMuted' in source

palette = block_by_id("MorphGeometry", "customThemeColorsMorph")
palette_state = "root.editingColors"
verify_morph(palette, palette_state, "customThemeColorsContent.implicitHeight", "theme color palette")
assert 'id: customThemeColorsContent' in palette
assert 'property var groups: [' in palette
assert 'model: parent.groups' in palette
assert 'model: modelData.colors' in palette
assert 'targetProperty: colorName' in palette
assert 'saveOnEdit: true' in palette
delegate_start = palette.find("delegate: SettingsGroup {")
assert delegate_start >= 0, "palette SettingsGroup delegate missing"
delegate_brace = palette.find("{", delegate_start)
delegate_depth = 0
delegate_end = None
for i in range(delegate_brace, len(palette)):
    if palette[i] == "{": delegate_depth += 1
    elif palette[i] == "}":
        delegate_depth -= 1
        if delegate_depth == 0:
            delegate_end = i + 1
            break
assert delegate_end is not None, "palette SettingsGroup delegate braces are unbalanced"
delegate_block = palette[delegate_start:delegate_end]
assert 'width: parent.width' in delegate_block and 'contentSpacing: 5' in delegate_block, "palette delegate layout changed"
assert 'visible: root.editingColors' not in delegate_block, "palette delegates must stay alive while wrapper collapses"
assert delegate_block.count('height: visible ? implicitHeight : 0') <= 1, "only the optional palette helper text may collapse; the framed color groups must remain in the morph"

# Existing theme-list expansion and its compact-selector handoff must remain intact.
assert 'progress: root.themesExpanded ? 1 : 0' in source
assert 'id: activeThemePreviewRow' in source
assert 'visible: !root.themesExpanded && expandedThemeList.normalizedProgress <= 0.001' in source
assert 'readonly property bool showThemeCombo: !root.themesExpanded' in source
assert 'readonly property bool showModifiedThemeName: root.editingColors && settings.currentThemeModified' in source
# The edit toggle and the theme lifecycle connections must remain unchanged.
assert 'id: editColorsCheck' in source and 'checked: root.editingColors' in source
assert 'root.editingColors = checked' in source and 'root.pendingDeleteThemeName = ""' in source
assert 'function onActiveThemeChanged()' in source
assert 'themeNameField.text = settings.activeTheme + (settings.currentThemeModified ? " (Changed)" : "")' in source
assert 'themeRenameField.text = settings.activeTheme' in source

print("Theme editor custom-name fields + palette MorphGeometry batch: OK")
PYTEST

grep -Fq 'test_settings_theme_editor_morph_batch.sh' "$ROOT/CHECK.sh" || fail "test not registered in CHECK.sh"
printf 'Theme editor MorphGeometry batch: OK\n'

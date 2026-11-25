#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
FOLDER="$ROOT/components/settings/primitives/SettingsNavigationFolder.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
SEARCH="$ROOT/components/settings/SettingsSearchController.qml"
TAB="$ROOT/components/settings/primitives/SettingsTabBase.qml"
BUTTON="$ROOT/components/settings/primitives/SettingsButton.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"

# The navigation sidebar must be keyboard-operable without relying on the mouse.
grep -Fq 'property bool settingsNavigationFocusTarget: true' "$FOLDER"
grep -Fq 'activeFocusOnTab: true' "$FOLDER"
grep -Fq 'settingsNavigationFocusTarget: true' "$NAV"
grep -Fq 'settingsNavigationPageId: visible ? String(modelData.items[0].id) : ""' "$NAV"
grep -Fq 'settingsNavigationHost: root.host' "$NAV"
grep -Fq 'Accessible.role: Accessible.Button' "$FOLDER"
grep -Fq 'Accessible.name: "Поиск настроек"' "$NAV"
grep -Fq 'Accessible.onPressAction: root.toggleRequested()' "$FOLDER"
grep -Fq 'Qt.Key_Return' "$FOLDER"
grep -Fq 'Qt.Key_Enter' "$FOLDER"
grep -Fq 'Qt.Key_Space' "$FOLDER"
grep -Fq 'Qt.Key_Left' "$FOLDER"
grep -Fq 'Qt.Key_Right' "$FOLDER"
grep -Fq 'Qt.Key_Up' "$FOLDER"
grep -Fq 'Qt.Key_Down' "$FOLDER"
grep -Fq 'selected: visible && root.host.isSettingsTabSelected(modelData.items[0].id)' "$NAV"
! grep -Fq 'folderHeader.forceActiveFocus(Qt.MouseFocusReason)' "$FOLDER"
grep -Fq 'folderHeader.focus = false' "$FOLDER"
grep -Fq 'SettingsSubTab {' "$NAV"
grep -Fq 'folderHeader.focus = false' "$FOLDER"
grep -Fq 'selected: visible && root.host.isSettingsTabSelected(modelData.items[0].id)' "$NAV"
grep -Fq 'settingsNavigationFocusTarget: true' "$NAV"
grep -Fq 'settingsNavigationHost: root.host' "$NAV"
grep -Fq 'settingsNavigationPageId: String(parent.modelData.id)' "$NAV"

# Page tabs and icon-only action buttons expose focus, semantics and keyboard activation.
grep -Fq 'activeFocusOnTab: true' "$TAB"
grep -Fq 'Accessible.role: Accessible.Button' "$TAB"
grep -Fq 'Accessible.name: root.text' "$TAB"
grep -Fq 'Accessible.onPressAction: root.clicked()' "$TAB"
grep -Fq 'root.settingsNavigationHost.focusAdjacentSettingsNavigationItem' "$TAB"
grep -Fq 'border.width: root.activeFocus ? 2' "$TAB"
grep -Fq 'activeFocusOnTab: root.enabled' "$BUTTON"
grep -Fq 'Accessible.role: Accessible.Button' "$BUTTON"
grep -Fq 'Accessible.name: root.text.length > 0 ? root.text' "$BUTTON"
grep -Fq 'Accessible.onPressAction: root.clicked()' "$BUTTON"
grep -Fq 'border.width: root.activeFocus ? Math.max(2, root.borderWidth)' "$BUTTON"

# Both frame and page ordering use the shared accessible drag handle.
grep -Fq 'DragReorderHandle {' "$WINDOW"
grep -Fq 'accessibleLabel: settingsGroupOrderRow.modelData.items.length === 1' "$WINDOW"
grep -Fq 'accessibleLabel: settingsNavigationPageOrderRow.modelData.label' "$WINDOW"
grep -Fq 'host.moveSettingsNavigationGroupTo(' "$WINDOW"
grep -Fq 'host.moveSettingsTabWithinGroupTo(' "$WINDOW"
REORDER="$ROOT/components/primitives/DragReorderHandle.qml"
grep -Fq 'ToolTip.text: "Перетащить · Alt + ↑/↓"' "$REORDER"
grep -Fq 'Accessible.role: Accessible.Button' "$REORDER"
grep -Fq 'Accessible.description: "Перетащите маркер, чтобы изменить порядок. Также доступны Alt и стрелки вверх или вниз."' "$REORDER"

# Search activation should focus the destination page after the page/subtab has been selected.
grep -Fq 'root.host.focusSettingsNavigationPage(pageId)' "$SEARCH"
grep -Fq 'function focusSettingsNavigationPage(pageId)' "$WIDGET"

node - "$WIDGET" <<'NODE'
const fs = require('fs');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8');
function methodBody(name) {
  const start = source.indexOf(`function ${name}(`);
  assert(start >= 0, `missing ${name}`);
  const open = source.indexOf('{', start);
  let depth = 0;
  for (let i = open; i < source.length; i++) {
    if (source[i] === '{') depth++;
    else if (source[i] === '}' && --depth === 0) return source.slice(open + 1, i);
  }
  throw new Error(`unterminated ${name}`);
}
function makeFocusChain(items) {
  for (let i = 0; i < items.length; i++) {
    items[i].nextItemInFocusChain = forward => {
      const delta = forward ? 1 : -1;
      return items[(i + delta + items.length) % items.length];
    };
  }
}
const focusAdjacent = new Function('currentItem', 'forward', 'root', 'Qt', methodBody('focusAdjacentSettingsNavigationItem'));
const start = { settingsNavigationFocusTarget: true, visible: true, enabled: true, focused: false, forceActiveFocus() { this.focused = true; } };
const unrelated = { visible: true, enabled: true };
const unrelated2 = { visible: true, enabled: true };
const unrelated3 = { visible: true, enabled: true };
const hidden = { settingsNavigationFocusTarget: true, visible: false, enabled: true, focused: false, forceActiveFocus() { this.focused = true; } };
const disabled = { settingsNavigationFocusTarget: true, visible: true, enabled: false, focused: false, forceActiveFocus() { this.focused = true; } };
const nextPage = { settingsNavigationFocusTarget: true, visible: true, enabled: true, focused: false, forceActiveFocus(reason) { this.focused = true; this.reason = reason; } };
const previousGroup = { settingsNavigationFocusTarget: true, visible: true, enabled: true, focused: false, forceActiveFocus(reason) { this.focused = true; this.reason = reason; } };
const chain = [start, unrelated, hidden, disabled, nextPage, unrelated2, previousGroup];
makeFocusChain(chain);
assert.strictEqual(focusAdjacent(start, true, {}, { TabFocusReason: 1 }), true, 'forward navigation finds the next visible enabled navigation item');
assert.strictEqual(nextPage.focused, true, 'forward navigation focuses the next page after skipping unrelated, hidden and disabled objects');
assert.strictEqual(nextPage.reason, 1, 'navigation focus uses the tab focus reason');
assert.strictEqual(focusAdjacent(start, false, {}, { TabFocusReason: 1 }), true, 'backward navigation finds the previous visible navigation item');
assert.strictEqual(previousGroup.focused, true, 'backward navigation focuses the previous group');

const emptyStart = { settingsNavigationFocusTarget: true, visible: true, enabled: true, forceActiveFocus() {} };
const emptyHidden = { settingsNavigationFocusTarget: true, visible: false, enabled: true, forceActiveFocus() {} };
makeFocusChain([emptyStart, unrelated3, emptyHidden]);
assert.strictEqual(focusAdjacent(emptyStart, true, {}, { TabFocusReason: 1 }), false, 'navigation returns false when no visible target exists');

const focusPage = new Function('pageId', 'root', 'Qt', methodBody('focusSettingsNavigationPage'));
const searchInput = {};
const pageGeneral = { settingsNavigationFocusTarget: true, settingsNavigationPageId: 'general', visible: true, enabled: true, focused: false, forceActiveFocus(reason) { this.focused = true; this.reason = reason; } };
const pageWeather = { settingsNavigationFocusTarget: true, settingsNavigationPageId: 'weather', visible: true, enabled: true, focused: false, forceActiveFocus(reason) { this.focused = true; this.reason = reason; } };
const searchChain = [searchInput, unrelated3, pageGeneral, pageWeather];
makeFocusChain(searchChain);
const host = { settingsNavigation: { searchInput } };
assert.strictEqual(focusPage('weather', host, { OtherFocusReason: 2 }), true, 'search navigation locates the requested sidebar page');
assert.strictEqual(pageWeather.focused, true, 'search navigation transfers focus to the matching page');
assert.strictEqual(pageWeather.reason, 2, 'search navigation uses an explicit navigation focus reason');
assert.strictEqual(focusPage('missing', host, { OtherFocusReason: 2 }), false, 'search navigation safely ignores unknown page IDs');
pageWeather.visible = false;
assert.strictEqual(focusPage('weather', host, { OtherFocusReason: 2 }), false, 'search focus refuses to target a page hidden inside a collapsed group');

const navSource = fs.readFileSync(require('path').join(require('path').dirname(process.argv[2]), 'SettingsNavigation.qml'), 'utf8');
function navMethodBody(name) {
  const start = navSource.indexOf(`function ${name}(`);
  assert(start >= 0, `missing SettingsNavigation.${name}`);
  const open = navSource.indexOf('{', start);
  let depth = 0;
  for (let i = open; i < navSource.length; i++) {
    if (navSource[i] === '{') depth++;
    else if (navSource[i] === '}' && --depth === 0) return navSource.slice(open + 1, i);
  }
  throw new Error(`unterminated SettingsNavigation.${name}`);
}
const ensureVisible = new Function('item', 'root', 'mainSettingsTabs', 'mainSettingsGroupsColumn', navMethodBody('ensureNavigationItemVisible'));
const tabs = { contentY: 0, height: 200, contentHeight: 600 };
const groupsColumn = {};
const below = { visible: true, height: 34, mapToItem() { return { y: 250 }; } };
assert.strictEqual(ensureVisible(below, {}, tabs, groupsColumn), true, 'off-screen navigation item is handled');
assert.strictEqual(tabs.contentY, 84, 'downward focus movement scrolls the item into the bottom of the viewport');
const above = { visible: true, height: 30, mapToItem() { return { y: 20 }; } };
tabs.contentY = 100;
assert.strictEqual(ensureVisible(above, {}, tabs, groupsColumn), true, 'navigation item above the viewport is handled');
assert.strictEqual(tabs.contentY, 20, 'backward focus movement scrolls the item into the top of the viewport');
console.log('Settings keyboard focus helpers: forward/backward traversal, hidden/disabled filtering, search focus and viewport scrolling: OK');
NODE

echo 'settings navigation keyboard accessibility: OK'

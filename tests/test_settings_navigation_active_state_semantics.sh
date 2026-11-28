#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HELPER="$ROOT/js/settings/SettingsNavigationVisualState.js"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
SUBTAB="$ROOT/components/settings/primitives/SettingsSubTab.qml"
BASE="$ROOT/components/settings/primitives/SettingsTabBase.qml"
FOLDER="$ROOT/components/settings/primitives/SettingsNavigationFolder.qml"
node - "$HELPER" "$NAV" "$SUBTAB" "$BASE" "$FOLDER" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const [helperPath, navPath, subtabPath, basePath, folderPath] = process.argv.slice(2);
const helper = {};
vm.runInNewContext(fs.readFileSync(helperPath, 'utf8').replace(/^\.pragma library\s*/, ''), helper, { filename: helperPath });
const nav = fs.readFileSync(navPath, 'utf8');
const subtab = fs.readFileSync(subtabPath, 'utf8');
const base = fs.readFileSync(basePath, 'utf8');
const folder = fs.readFileSync(folderPath, 'utf8');

const modules = { id: 'modules', items: [{ id: 'time' }, { id: 'weather' }, { id: 'notifications' }] };
const launcher = { id: 'launcher', items: [{ id: 'launcher' }, { id: 'launcherSearch' }] };
const dashboard = { id: 'dashboard', items: [{ id: 'dashboard' }] };
const general = { id: 'general', items: [{ id: 'general' }] };

assert.strictEqual(helper.groupContainsCurrentPage(modules, 'weather'), true);
assert.strictEqual(helper.isStandalonePageSelected(modules, 'weather'), false);
assert.strictEqual(helper.isStandalonePageSelected(dashboard, 'dashboard'), true);
assert.strictEqual(helper.isStandalonePageSelected(general, 'dashboard'), false);
assert.strictEqual(helper.shouldShowCollapsedPageHint(modules, true, 'weather'), true);
assert.strictEqual(helper.shouldShowCollapsedPageHint(modules, false, 'weather'), false);
assert.strictEqual(helper.shouldShowCollapsedPageHint(launcher, true, 'dashboard'), false);

const activePage = 'dashboard';
const collapsedGroups = { launcher: true, modules: false, dashboard: false };
assert.strictEqual(helper.isStandalonePageSelected(dashboard, activePage), true);
assert.strictEqual(helper.isStandalonePageSelected(launcher, activePage), false);
assert.strictEqual(helper.isStandalonePageSelected(modules, activePage), false);
assert.strictEqual(helper.shouldShowCollapsedPageHint(launcher, collapsedGroups.launcher, activePage), false);

// Singleton pages must use exactly the same tab component as pages inside folders.
assert(nav.includes('SettingsSubTab {\n                        id: navigationGroupStandaloneTab'), 'standalone pages must be rendered by shared SettingsSubTab');
assert(nav.includes('visible: modelData.items.length === 1'), 'shared standalone tab is only visible for singleton groups');
assert(nav.includes('selected: visible && root.host.isSettingsTabSelected(modelData.items[0].id)'), 'standalone tab uses the canonical selected state');
assert(nav.includes('onClicked: {') && nav.includes('root.host.selectSettingsTab(modelData.items[0].id)'), 'standalone tab routes through the same page selection path');
assert(subtab.includes('SettingsTabBase {'), 'SettingsSubTab must inherit the shared tab visual primitive');
assert(base.includes('property color persistentSelectedBackground: \"transparent\"'), 'selected tabs have no resting fill');
assert(base.includes('root.selected ? root.effectiveSelectedTextColor : root.normalTextColor'), 'persistent selected text treatment remains visible after focus moves');
assert(base.includes('readonly property real visualBorderWidth: root.activeFocus ? 1'), 'keyboard focus thickness stays at the same one-pixel outline as hover');
assert(base.includes('property color selectedBackground: \"transparent\"'), 'selected tabs remain transparent');
assert(base.includes('readonly property bool persistentSelectionActive: root.persistentSelectionHighlight && root.selected'), 'persistent selection does not depend on activeFocus');
assert(base.includes('border.width: root.visualBorderWidth'), 'keyboard focus treatment uses the shared tab border width');

// Horizontal subtabs opt into the persistent selected treatment; sidebar rows do not.
const pageHost = fs.readFileSync(require('path').join(require('path').dirname(navPath), 'SettingsPageHost.qml'), 'utf8');
assert(pageHost.includes('persistentSelectionHighlight: true'), 'horizontal subtabs keep their selected appearance after sidebar clicks');
assert(pageHost.includes('selected: root.host && root.host.currentPageSubTabIndex === index'), 'horizontal selection still follows the canonical subtab index');
assert((nav.match(/persistentSelectionHighlight: true/g) || []).length === 2, 'standalone and nested sidebar page tabs preserve their selected state independently of focus');

// Folder header is an expansion control only; actual child page owns selection.
assert(nav.includes('SettingsNavigationFolder {') && nav.includes('visible: navigationGroupDelegate.modelData.items.length !== 1'), 'multi-page and empty groups must use the reusable folder primitive');
assert(nav.includes('selected: root.host.isSettingsTabSelected(parent.modelData.id)'), 'actual page row owns selected state');
assert(folder.includes('folderHeader.focus = false'), 'mouse expansion clears stale folder focus');
assert(!folder.includes('folderHeader.forceActiveFocus(Qt.MouseFocusReason)'), 'mouse expansion must not give the folder a focus ring');
assert(!nav.includes('standalonePageSelected'), 'standalone tabs must not have a parallel custom visual state');
assert(folder.includes('text: "Страница: " + root.currentPageLabel'), 'collapsed folder hint remains neutral');
assert(folder.includes('color: Config.textMuted'), 'collapsed folder hint remains neutral');
assert(folder.includes('border.width: root.searchMatchCount > 0\n                ? Config.settingsSearchHighlightBorderWidth\n                : (folderHeader.activeFocus || (Config.cardBordersEnabled && folderHover.hovered) ? 1 : 0)'), 'folder hover outline respects card-border settings');
console.log('settings active state semantics: standalone pages share standard tab visuals; folders remain independent expansion controls: OK');
NODE
echo 'settings navigation active state semantics: OK'

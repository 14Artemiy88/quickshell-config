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
assert(base.includes('color: root.selected ? root.selectedBackground : root.normalBackground'), 'selected fill is shared with every other tab');
assert(base.includes('color: root.selected ? root.selectedTextColor : root.normalTextColor'), 'selected text color is shared with every other tab');
assert(base.includes('border.width: root.activeFocus ? 2'), 'keyboard focus treatment is inherited from the standard tab primitive');

// Folder header is an expansion control only; actual child page owns selection.
assert(nav.includes('SettingsNavigationFolder {') && nav.includes('visible: navigationGroupDelegate.modelData.items.length > 1'), 'multi-page groups must use the reusable folder primitive');
assert(nav.includes('selected: root.host.isSettingsTabSelected(parent.modelData.id)'), 'actual page row owns selected state');
assert(folder.includes('folderHeader.focus = false'), 'mouse expansion clears stale folder focus');
assert(!folder.includes('folderHeader.forceActiveFocus(Qt.MouseFocusReason)'), 'mouse expansion must not give the folder a focus ring');
assert(!nav.includes('standalonePageSelected'), 'standalone tabs must not have a parallel custom visual state');
assert(folder.includes('text: "Страница: " + root.currentPageLabel'), 'collapsed folder hint remains neutral');
assert(folder.includes('color: Config.textMuted'), 'collapsed folder hint remains neutral');
assert(folder.includes('border.width: root.searchMatchCount > 0\n                ? Config.settingsSearchHighlightBorderWidth\n                : ((folderHeader.activeFocus || folderHover.hovered) ? 1 : 0)'), 'collapsed header outline stays thin and expanded header relies on the outer card frame');
console.log('settings active state semantics: standalone pages share standard tab visuals; folders remain independent expansion controls: OK');
NODE
echo 'settings navigation active state semantics: OK'

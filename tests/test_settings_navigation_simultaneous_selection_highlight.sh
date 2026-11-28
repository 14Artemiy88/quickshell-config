#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
PAGE_HOST="$ROOT/components/settings/SettingsPageHost.qml"
BASE="$ROOT/components/settings/primitives/SettingsTabBase.qml"
CONTROLLER="$ROOT/components/settings/SettingsNavigationController.qml"
node - "$NAV" "$PAGE_HOST" "$BASE" "$CONTROLLER" <<'NODE'
const fs = require('fs');
const assert = require('assert');
const [navPath, pageHostPath, basePath, controllerPath] = process.argv.slice(2);
const nav = fs.readFileSync(navPath, 'utf8');
const pageHost = fs.readFileSync(pageHostPath, 'utf8');
const base = fs.readFileSync(basePath, 'utf8');
const controller = fs.readFileSync(controllerPath, 'utf8');

// Both controls derive selection from persistent page/subtab state, not focus.
assert((nav.match(/persistentSelectionHighlight: true/g) || []).length === 2,
    'both standalone and nested sidebar page rows preserve their selected state');
assert(nav.includes('selected: visible && root.host.isSettingsTabSelected(modelData.items[0].id)'),
    'standalone sidebar selection follows the current page');
assert(nav.includes('selected: root.host.isSettingsTabSelected(parent.modelData.id)'),
    'nested sidebar selection follows the current page');
assert(pageHost.includes('persistentSelectionHighlight: true'),
    'horizontal subtab also preserves its selected state');
assert(pageHost.includes('selected: root.host && root.host.currentPageSubTabIndex === index'),
    'horizontal selected state follows the chosen content index');
assert(base.includes('readonly property bool persistentSelectionActive: root.persistentSelectionHighlight && root.selected'),
    'persistent selection is independent of keyboard focus');
assert(base.includes('property color persistentSelectedBackground: \"transparent\"'),
    'selected state remains fill-free');
assert(base.includes('root.persistentSelectionActive\n                        ? root.persistentSelectedBorderColor'),
    'selected state retains an accent border where borders are enabled');
assert(base.includes('root.selected ? root.effectiveSelectedTextColor : root.normalTextColor'),
    'selected label retains its selected text color');
assert(controller.includes('function isSettingsTabSelected(id)') && controller.includes('root.currentPageId === String(id)'),
    'sidebar page state remains independent from subtab index and focus');
console.log('Sidebar page and horizontal subtab can remain highlighted simultaneously: OK');
NODE
echo 'settings navigation simultaneous selection highlight: OK'

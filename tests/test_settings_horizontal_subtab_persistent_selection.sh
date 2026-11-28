#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAB="$ROOT/components/settings/primitives/SettingsTabBase.qml"
PAGE_HOST="$ROOT/components/settings/SettingsPageHost.qml"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
CONTROLLER="$ROOT/components/settings/SettingsNavigationController.qml"
node - "$TAB" "$PAGE_HOST" "$NAV" "$CONTROLLER" <<'NODE'
const fs = require('fs');
const assert = require('assert');
const [tabPath, pageHostPath, navPath, controllerPath] = process.argv.slice(2);
const tab = fs.readFileSync(tabPath, 'utf8');
const pageHost = fs.readFileSync(pageHostPath, 'utf8');
const nav = fs.readFileSync(navPath, 'utf8');
const controller = fs.readFileSync(controllerPath, 'utf8');

assert(tab.includes('property bool persistentSelectionHighlight: false'), 'persistent selection is opt-in');
assert(tab.includes('readonly property bool persistentSelectionActive: root.persistentSelectionHighlight && root.selected'), 'persistent selection depends on selected state, not focus');
assert(tab.includes('root.persistentSelectionActive ? root.persistentSelectedBackground'), 'persistent selected treatment uses selected state');
assert(tab.includes('root.persistentSelectionActive\n                        ? root.persistentSelectedBorderColor'), 'persistent border uses selected state');
assert(tab.includes('root.selected ? root.effectiveSelectedTextColor : root.normalTextColor'), 'selected label stays highlighted after focus moves');
assert(pageHost.includes('persistentSelectionHighlight: true'), 'horizontal subtabs opt into persistent selected state');
assert(pageHost.includes('selected: root.host && root.host.currentPageSubTabIndex === index'), 'active subtab remains keyed to the selected content');
assert(nav.includes('persistentSelectionHighlight: true'), 'selected sidebar page remains highlighted while a horizontal subtab has focus');
assert((nav.match(/persistentSelectionHighlight: true/g) || []).length === 2, 'standalone and nested sidebar pages both preserve selected state');
assert(controller.includes('root.currentPageSubTabIndex = 0'), 'changing page still resets the subtab index for the new page');
console.log('Horizontal subtab selected appearance persists independently from sidebar focus: OK');
NODE
echo 'settings horizontal subtab persistent selection: OK'

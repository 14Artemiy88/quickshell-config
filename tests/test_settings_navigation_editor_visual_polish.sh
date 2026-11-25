#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"
BUTTON="$ROOT/components/settings/primitives/SettingsButton.qml"
GROUP="$ROOT/components/settings/primitives/SettingsGroup.qml"

node - "$ROOT" <<'JS'
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const root = process.argv[2];
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const windowQml = read('components/settings/sections/SettingsWindowSection.qml');
const buttonQml = read('components/settings/primitives/SettingsButton.qml');
const groupQml = read('components/settings/primitives/SettingsGroup.qml');

const frameHeading = windowQml.indexOf('heading: "Порядок рамок"');
const pageHeading = windowQml.indexOf('text: "Вкладки панели настроек"');
const nextSection = windowQml.indexOf('visible: host && host.currentPageId === "general" && host.currentPageSubTabIndex === 1', pageHeading);
assert(frameHeading >= 0 && pageHeading > frameHeading && nextSection > pageHeading,
  'frame order and per-group page editor sections are present in the expected order');
const frameOrder = windowQml.slice(frameHeading, pageHeading);
const pageEditor = windowQml.slice(pageHeading, nextSection);

for (const [name, section] of [['frame order', frameOrder], ['page editor', pageEditor]]) {
  assert(section.includes('DragReorderHandle {'), `${name} uses the shared drag-reorder handle`);
  assert(section.includes('dropIndicatorHost:'), `${name} hosts the shared insertion indicator in its frame`);
  assert(section.includes('listRepeater:'), `${name} binds the handle to the correct list`);
  assert(section.includes('property Item reorderTargetItem:'), `${name} exposes the complete row as the drop target`);
  assert(!/iconText: "[↑↓]"/.test(section), `${name} no longer uses direction arrows for ordering`);
  assert(section.includes('handleWidth: width < 220 ? 24 : 26'), `${name} uses a compact responsive drag handle slot`);
  assert(section.includes('Behavior on y'), `${name} animates row reflow`);
}

assert(buttonQml.includes('property color outlineColor: Config.baseColor'),
  'SettingsButton defaults to the shared standard frame color');
assert(buttonQml.includes('root.activeFocus || root.emphasized || (root.borderOnHover && mouse.containsMouse)'),
  'keyboard focus and hover still emphasize the standard outline');
assert(buttonQml.includes('border.width: root.activeFocus ? Math.max(2, root.borderWidth) : root.borderWidth'),
  'keyboard focus keeps a stronger visible border');
assert(buttonQml.includes('root.forceActiveFocus(Qt.MouseFocusReason)'),
  'mouse activation also gives the action focus');
assert(groupQml.includes('property color backgroundColor: Config.transparent'),
  'navigation frames remain transparent rather than nested filled cards');
assert(groupQml.includes('border.color: root.borderColor'), 'framed group outlines remain intact');
assert(frameOrder.includes('heading: "Порядок рамок"'), 'group order remains its own frame');
assert(pageEditor.includes('delegate: SettingsGroup {') && pageEditor.includes('heading: groupData.label'),
  'each page group remains visually separated by its own frame');
assert(frameOrder.includes('listRepeater: settingsNavigationGroupsOrderRepeater')
    && frameOrder.includes('dropIndicatorHost: settingsNavigationGroupOrderFrame'),
  'frame order drag is hosted inside its framed group');
assert(pageEditor.includes('listRepeater: settingsNavigationPagesOrderRepeater')
    && pageEditor.includes('dropIndicatorHost: settingsNavigationPageGroup'),
  'page order drag is scoped to the matching page frame');
console.log('Settings navigation editor visual polish: shared drag handles, framed insertion indicators and animated row reflow: OK');
JS

echo 'settings navigation editor visual polish: OK'

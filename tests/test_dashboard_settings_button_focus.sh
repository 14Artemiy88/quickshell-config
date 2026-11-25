#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const qml = fs.readFileSync(path.join(process.argv[2], 'components/Dashboard.qml'), 'utf8');
const buttonStart = qml.indexOf('id: settingsButton');
const buttonEnd = qml.indexOf('id: closeButton', buttonStart);
assert(buttonStart >= 0 && buttonEnd > buttonStart, 'find the corner Settings button');
const button = qml.slice(buttonStart, buttonEnd);
assert(button.includes('root.keyboardNavigationActive = false'), 'pointer activation clears keyboard-navigation styling');
assert(!button.includes('forceActiveFocus()'), 'pointer clicks do not pin the Settings icon as a persistent focus selection');
assert(button.includes('onActiveFocusChanged:'), 'keyboard focus is still tracked for the icon');
assert(button.includes('settingsMouse.containsMouse'), 'hover remains a soft preview, separate from keyboard focus');
const cardStart = qml.indexOf('component InfoCard: Rectangle {');
const cardEnd = qml.indexOf('\n    }\n}', cardStart);
const card = qml.slice(cardStart, cardEnd);
assert(card.includes('HoverHandler {') && card.includes('id: cardHover'), 'passive cards keep a non-clickable hover handler');
assert(!card.includes('forceActiveFocus()') && !card.includes('cardMouse'), 'pointer interaction does not force focus on a card');
assert(!card.includes('MouseArea {'), 'the whole card surface has no click-catching MouseArea');
console.log('Dashboard Settings icon and passive card pointer/focus behavior: PASS');
NODE

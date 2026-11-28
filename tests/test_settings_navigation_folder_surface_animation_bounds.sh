#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FOLDER="$ROOT/components/settings/primitives/SettingsNavigationFolder.qml"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
BASE="$ROOT/components/settings/primitives/SettingsTabBase.qml"
fail() { echo "Settings navigation folder surface/animation/bounds: FAIL: $*" >&2; exit 1; }

node - "$FOLDER" "$NAV" "$BASE" <<'NODE'
const fs = require('fs');
const assert = require('assert');
const [folderPath, navPath, basePath] = process.argv.slice(2);
const folder = fs.readFileSync(folderPath, 'utf8');
const nav = fs.readFileSync(navPath, 'utf8');
const base = fs.readFileSync(basePath, 'utf8');

// Sidebar folder, header and page tabs are visually unfilled; selection uses text and outline.
assert((folder.match(/color: Config\.transparent/g) || []).length >= 2,
  'folder card and folder header must be transparent');
assert(!folder.includes('Qt.darker(Config.settingsBackground'),
  'folder must not paint another dark surface');
assert(nav.includes('normalBackground: Config.transparent'),
  'ordinary sidebar tabs must not paint a normal background');
assert(nav.includes('normalBorderColor: Config.transparent'),
  'ordinary sidebar tabs must not paint a normal border');
assert(base.includes(': (root.selected ? root.selectedBackground : root.normalBackground)'),
  'selected tab must use the shared transparent surface while normal state is transparent');

// Expansion animates the content height and opacity; visibility persists until height reaches zero.
assert(folder.includes('height: root.collapsed ? 0 : implicitHeight + 4'),
  'children height must animate from zero to measured content height');
assert(folder.includes('Behavior on height') && folder.includes('NumberAnimation'),
  'folder expansion/collapse must animate height');
assert(folder.includes('Behavior on opacity'),
  'folder expansion/collapse must animate opacity');
assert(folder.includes('visible: !root.collapsed || height > 0.5'),
  'children must remain visible until the collapse animation completes');
assert(folder.includes('clip: true'), 'animated content must clip to its animated height');

// All child rows must fit inside the expanded card's inset content region.
assert(folder.includes('readonly property real expandedContentWidth: Math.max(0, width - expandedCardInset * 2)'),
  'folder must expose a bounded inner content width');
assert(nav.includes('width: navigationGroupFolder.expandedContentWidth'),
  'nested row width must match the folder inner width, not its outer width');
assert(nav.includes('width: parent.width - navigationGroupFolder.childContentInset'),
  'nested page tab must retain an inner right inset');
assert(folder.includes('property int expandedCardInset: 4') && folder.includes('property int childContentInset: 6'),
  'compact card and nested tab insets must be explicit shared properties');

console.log('Settings navigation folder surface/animation/bounds: transparent tab surfaces, text/outline selection, smooth collapse and no right overflow: OK');
NODE

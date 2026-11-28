#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FOLDER="$ROOT/components/settings/primitives/SettingsNavigationFolder.qml"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
fail() { echo "Settings navigation folder card: FAIL: $*" >&2; exit 1; }

[[ -f "$FOLDER" ]] || fail 'folder primitive is missing'
grep -Fq 'visible: !root.collapsed || navigationItems.height > 0.5' "$FOLDER" || fail 'card frame does not remain during collapse animation'
grep -Fq 'anchors.fill: parent' "$FOLDER" || fail 'card frame does not cover the complete folder primitive'
grep -Fq 'border.width: Config.cardBordersEnabled ? 1 : 0' "$FOLDER" || fail 'expanded card frame is not a subtle one-pixel outline'
grep -Fq 'radius: Config.scaledCornerRadius(Config.frameRadius)' "$FOLDER" || fail 'expanded card does not use the shared frame radius'
grep -Fq 'spacing: 2' "$FOLDER" || fail 'folder layout spacing changes during the reveal'
grep -Fq 'root.collapsed ? root.width : root.expandedContentWidth' "$FOLDER" || fail 'expanded folder heading does not fit the inner card width'
grep -Fq 'x: root.expandedCardInset' "$FOLDER" || fail 'child list applies its horizontal inset only after expansion'
grep -Fq 'width: root.expandedContentWidth' "$FOLDER" || fail 'expanded child list is not inset into the card'
grep -Fq 'color: root.collapsed ? Config.textMuted : Config.accent' "$FOLDER" || fail 'expanded folder heading is not emphasized'
grep -Fq 'default property alias contentData: navigationItems.data' "$FOLDER" || fail 'folder child slot was removed'
grep -Fq 'color: Config.transparent' "$FOLDER" || fail 'folder card/header still paints a filled background'
grep -Fq 'Behavior on height' "$FOLDER" || fail 'folder expand/collapse height is not animated'
grep -Fq 'Behavior on opacity' "$FOLDER" || fail 'folder children do not fade during expand/collapse'
grep -Fq 'visible: !root.collapsed || height > 0.5' "$FOLDER" || fail 'children disappear before collapse animation completes'
grep -Fq 'SettingsNavigationFolder {' "$NAV" || fail 'navigation is not using the shared folder card'

node - "$FOLDER" <<'NODE'
const fs=require('fs'), assert=require('assert');
const s=fs.readFileSync(process.argv[2],'utf8');
assert(s.startsWith('import QtQuick\n') && s.includes('Item {\n    id: root'), 'folder uses a neutral Item root so the background frame is outside the layout positioner');
assert(s.includes('Column {\n        id: folderLayout\n        width: root.width\n        height: implicitHeight'), 'header and children use an internal layout column sized from its content');
assert(!s.includes('anchors.fill: parent\n        spacing: root.collapsed'), 'folder layout avoids a circular height binding');
assert(s.includes('x: root.expandedCardInset\n        width: root.expandedContentWidth'), 'child list target inset/width must already be established while collapsed');
assert(s.includes('spacing: 2'), 'folder layout spacing must not change at expansion start');
assert(s.indexOf('Rectangle {\n        anchors.fill: parent') < s.indexOf('Column {\n        id: folderLayout'), 'card outline is behind, not a layout child of the Column');
assert(!s.includes('Qt.darker(Config.settingsBackground'), 'expanded folder frame has no dark filled surface');
NODE

grep -Fq 'normalBackground: Config.transparent' "$NAV" || fail 'unselected navigation tabs still paint a background'
grep -Fq 'normalBorderColor: Config.transparent' "$NAV" || fail 'unselected navigation tabs still paint a normal border'
grep -Fq 'width: navigationGroupFolder.expandedContentWidth' "$NAV" || fail 'nested page row exceeds inner card width'
grep -Fq 'width: parent.width - navigationGroupFolder.childContentInset' "$NAV" || fail 'nested page tab does not respect its right inset'
echo 'Settings navigation folder card: transparent surfaces, active fill retained, animated collapse and bounded child width: OK'

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
TAB="$ROOT/components/settings/primitives/SettingsTabBase.qml"
FOLDER="$ROOT/components/settings/primitives/SettingsNavigationFolder.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"

node - "$WIDGET" "$NAV" "$TAB" "$WINDOW" "$FOLDER" <<'NODE'
const fs = require('fs');
const assert = require('assert');
const [widgetPath, navPath, tabPath, windowPath, folderPath] = process.argv.slice(2);
const widget = fs.readFileSync(widgetPath, 'utf8');
const nav = fs.readFileSync(navPath, 'utf8');
const tab = fs.readFileSync(tabPath, 'utf8');
const folder = fs.readFileSync(folderPath, 'utf8');
const windowQml = fs.readFileSync(windowPath, 'utf8');

assert(widget.includes('spacing: width < 440 ? 10 : 16'),
  'settings body reduces the inter-column gap for narrow windows');
assert(widget.includes('Math.min(176, Math.max(112, Math.round(settingsBody.width * 0.33)))'),
  'sidebar width adapts proportionally while retaining readable minimum and desktop maximum');
assert(widget.includes('Math.max(0, parent.width - settingsNavigation.width - settingsBody.spacing)'),
  'page content receives the exact remaining width instead of overflowing');
assert(nav.includes('readonly property bool compactNavigation: width < 148'),
  'navigation switches to compact typography and spacing below the sidebar breakpoint');
assert(nav.includes('mainSettingsTabs.width - (root.compactNavigation ? 4 : 10)'),
  'compact mode reclaims outer sidebar width for navigation labels');
assert(folder.includes('root.compactNavigation ? 5 : 8'),
  'group header margins tighten in compact mode');
assert(folder.includes('groupLabelText.implicitWidth > groupLabelText.width + 1'),
  'clipped group names expose their full label in a tooltip');
assert(folder.includes('currentPageHint.implicitWidth > currentPageHint.width + 1'),
  'clipped active-page hints expose their full label in a tooltip');
assert(tab.includes('tabLabel.implicitWidth > tabLabel.width + 1'),
  'clipped page labels expose their full label in a tooltip');
assert(tab.includes('ToolTip.text: root.settingsSearchMatched && root.settingsSearchMatchHint.length > 0'),
  'search match explanations retain precedence over the plain full-label tooltip');
assert(windowQml.includes('readonly property int orderSpacing: width < 220 ? 3 : 5'),
  'frame/page order rows reduce spacing on narrow page content');
assert(windowQml.includes('readonly property int indexWidth: width < 220 ? 14 : 19'),
  'frame/page order rows reduce number-column width on narrow page content');
assert(windowQml.includes('readonly property int handleWidth: width < 220 ? 24 : 26'),
  'frame/page drag handles keep a compact hit slot before forcing row overflow');
assert(windowQml.includes('Math.max(42, parent.width - settingsNavigationPageOrderRow.indexWidth'),
  'page label editor has a controlled compact minimum width');
assert(windowQml.includes('minimum: fieldIndex === 2 ? 320'),
  'responsive navigation is tested against the existing 320px minimum Settings window width');
assert((nav.match(/height: root\.compactNavigation \? 36 : 34/g) || []).length === 3,
  'standalone tabs, folder page rows and their page-tab controls use the same height');

function layout(bodyWidth) {
  const navigationWidth = Math.min(176, Math.max(112, Math.round(bodyWidth * 0.33)));
  const gap = bodyWidth < 440 ? 10 : 16;
  return { navigationWidth, gap, pageWidth: Math.max(0, bodyWidth - navigationWidth - gap) };
}
for (const width of [300, 340, 380, 420, 460, 500, 540]) {
  const result = layout(width);
  assert(result.navigationWidth >= 112 && result.navigationWidth <= 176,
    `navigation width remains bounded at ${width}px`);
  assert(result.pageWidth > 0, `page content remains visible at ${width}px`);
  assert.strictEqual(result.navigationWidth + result.gap + result.pageWidth, width,
    `navigation and page content fit exactly at ${width}px`);
}
assert.deepStrictEqual(layout(300), { navigationWidth: 112, gap: 10, pageWidth: 178 },
  'minimum supported settings width returns enough space to the page instead of reserving a fixed 176px sidebar');
assert.deepStrictEqual(layout(540), { navigationWidth: 176, gap: 16, pageWidth: 348 },
  'default desktop layout preserves the original sidebar and content widths');

function editorRow(width) {
  const spacing = width < 220 ? 3 : 5;
  const indexWidth = width < 220 ? 14 : 19;
  const handleWidth = width < 220 ? 24 : 26;
  const labelWidth = Math.max(42, width - indexWidth - handleWidth - spacing * 2);
  return { spacing, indexWidth, handleWidth, labelWidth, total: spacing * 2 + indexWidth + handleWidth + labelWidth };
}
for (const width of [150, 166, 180, 210, 220, 300]) {
  const row = editorRow(width);
  assert(row.total <= width || row.labelWidth === 42,
    `editor rows adapt controls before exceeding available width (${width}px)`);
}
console.log('Settings narrow-window navigation: responsive sidebar, readable clipped labels and compact framed-editor rows: OK');
NODE

echo 'settings narrow-window navigation: OK'

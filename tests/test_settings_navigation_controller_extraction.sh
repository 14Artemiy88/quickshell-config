#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
NAV="$ROOT/components/settings/SettingsNavigationController.qml"
[[ -f "$NAV" ]] || { echo 'SettingsNavigationController.qml is missing' >&2; exit 1; }
grep -Fq 'SettingsNavigationController {' "$WIDGET"
grep -Fq 'host: root' "$WIDGET"
grep -Fq 'property alias currentPageId: settingsNavigationController.currentPageId' "$WIDGET"
grep -Fq 'property alias currentPageSubTabIndex: settingsNavigationController.currentPageSubTabIndex' "$WIDGET"
grep -Fq 'function settingsTabLabelForId(id) { return settingsNavigationController.settingsTabLabelForId(id) }' "$WIDGET"
grep -Fq 'function resetCurrentSettingsPage() { return settingsNavigationController.resetCurrentSettingsPage() }' "$WIDGET"
grep -Fq 'root.host.resetSettingsPageScroll()' "$NAV"
grep -Fq 'root.currentPageSubTabIndex = 0' "$NAV"
grep -Fq 'Qt.callLater(root.host.rebuildSettingsSearchIndex)' "$NAV"
! grep -Fq 'function settingsSubTabChangeSpec(pageId, sub) {' "$WIDGET"
! grep -Fq 'var specs = {' "$WIDGET"
! grep -Fq 'onCurrentPageIdChanged:' "$WIDGET"
! grep -Fq 'function settingsTabOrderNormalized() {' "$WIDGET"

node - "$WIDGET" "$NAV" <<'NODE'
const assert = require('assert');
const fs = require('fs');
for (const file of process.argv.slice(2)) {
  const source = fs.readFileSync(file, 'utf8');
  const stack = [];
  const pairs = { ')': '(', ']': '[', '}': '{' };
  let mode = 'code', escaped = false, line = 1;
  for (let i = 0; i < source.length; i++) {
    const ch = source[i], next = source[i + 1];
    if (ch === '\n') line++;
    if (mode === 'line') { if (ch === '\n') mode = 'code'; continue; }
    if (mode === 'block') { if (ch === '*' && next === '/') { mode = 'code'; i++; } continue; }
    if (['single','double','template'].includes(mode)) {
      if (escaped) { escaped = false; continue; }
      if (ch === '\\') { escaped = true; continue; }
      if ((mode === 'single' && ch === "'") || (mode === 'double' && ch === '"') || (mode === 'template' && ch === '`')) mode = 'code';
      continue;
    }
    if (ch === '/' && next === '/') { mode = 'line'; i++; continue; }
    if (ch === '/' && next === '*') { mode = 'block'; i++; continue; }
    if (ch === "'") { mode = 'single'; continue; }
    if (ch === '"') { mode = 'double'; continue; }
    if (ch === '`') { mode = 'template'; continue; }
    if ('([{'.includes(ch)) stack.push({ch,line});
    else if (pairs[ch]) { const open = stack.pop(); assert(open && open.ch === pairs[ch], `${file}: unexpected ${ch} at ${line}`); }
  }
  assert.strictEqual(mode, 'code', `${file}: unterminated ${mode}`);
  assert.deepStrictEqual(stack, [], `${file}: unmatched delimiters`);
}
NODE

echo 'SettingsNavigationController extraction and host API: OK'

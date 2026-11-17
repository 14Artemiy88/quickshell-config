#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
HOST="$ROOT/components/settings/SettingsPageHost.qml"
CONTENT="$ROOT/components/settings/SettingsPageContent.qml"
NAV="$ROOT/components/settings/SettingsNavigationController.qml"
grep -Fq 'SettingsPageHost {' "$CONTENT"
grep -Fq 'host: root' "$WIDGET"
grep -Fq 'default property alias pageContent: otherColumn.data' "$HOST"
grep -Fq 'function resetScroll()' "$HOST"
grep -Fq 'visible: root.host.currentPageId !== "modules" && root.host.currentPageId !== "themes"' "$CONTENT"
grep -Fq 'objectName: "settings-search-page:calendar"' "$CONTENT"
grep -Fq 'objectName: "settings-search-page:notifications"' "$CONTENT"
grep -Fq 'root.host.settingsSubTabHasChanges(root.host.currentPageId, index)' "$HOST"
grep -Fq 'root.host.resetCurrentSettingsPage()' "$HOST"
! grep -Fq 'id: otherFlick' "$WIDGET"
! grep -Fq 'id: otherColumn' "$WIDGET"
grep -Fq 'SettingsPageContent {' "$WIDGET"
grep -Fq 'function resetScroll()' "$CONTENT"
grep -Fq 'root.host.currentPageId' "$CONTENT"
grep -Fq 'SettingsModulesSection {' "$CONTENT"
grep -Fq 'SettingsColorsSection {' "$CONTENT"
node - "$WIDGET" "$HOST" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const files = process.argv.slice(2).concat(process.argv[2].replace(/SettingsWidget\.qml$/, "SettingsPageContent.qml"));
for (const file of files) {
const source = fs.readFileSync(file, 'utf8');
const stack = [];
const pairs = { ')': '(', ']': '[', '}': '{' };
let state = 'code';
let escaped = false;
let line = 1;
for (let i = 0; i < source.length; i++) {
  const ch = source[i];
  const next = source[i + 1];
  if (ch === '\n') line++;
  if (state === 'lineComment') {
    if (ch === '\n') state = 'code';
    continue;
  }
  if (state === 'blockComment') {
    if (ch === '*' && next === '/') { state = 'code'; i++; }
    continue;
  }
  if (state === 'single' || state === 'double' || state === 'template') {
    if (escaped) { escaped = false; continue; }
    if (ch === '\\') { escaped = true; continue; }
    if ((state === 'single' && ch === "'") || (state === 'double' && ch === '"') || (state === 'template' && ch === '`')) state = 'code';
    continue;
  }
  if (ch === '/' && next === '/') { state = 'lineComment'; i++; continue; }
  if (ch === '/' && next === '*') { state = 'blockComment'; i++; continue; }
  if (ch === "'") { state = 'single'; continue; }
  if (ch === '"') { state = 'double'; continue; }
  if (ch === '`') { state = 'template'; continue; }
  if (ch === '(' || ch === '[' || ch === '{') stack.push({ ch, line });
  else if (Object.hasOwn(pairs, ch)) {
    const open = stack.pop();
    assert(open && open.ch === pairs[ch], `unmatched ${ch} at line ${line}`);
  }
}
assert.strictEqual(state, 'code', `unterminated comment/string state: ${state}`);
assert.deepStrictEqual(stack, [], `${file}: unclosed delimiter(s): ${JSON.stringify(stack)}`);
}
NODE
echo 'Settings page assembly extraction: shared host, dedicated page content component, stable routing, and balanced QML delimiters: OK'

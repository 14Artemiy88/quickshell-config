#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
FOLDER="$ROOT/components/settings/primitives/SettingsNavigationFolder.qml"
SUBTAB="$ROOT/components/settings/primitives/SettingsSubTab.qml"
TAB_BASE="$ROOT/components/settings/primitives/SettingsTabBase.qml"
GROUP="$ROOT/components/settings/primitives/SettingsGroup.qml"
fail() { echo "Settings navigation folder primitive: FAIL: $*" >&2; exit 1; }

[[ -f "$FOLDER" ]] || fail 'reusable SettingsNavigationFolder primitive is missing'
grep -Fq 'SettingsNavigationFolder {' "$NAV" || fail 'SettingsNavigation does not use the folder primitive'
grep -Fq 'default property alias contentData: navigationItems.data' "$FOLDER" || fail 'folder does not expose its child page slot'
grep -Fq 'signal toggleRequested()' "$FOLDER" || fail 'folder does not expose its expansion action'
grep -Fq 'Accessible.role: Accessible.Button' "$FOLDER" || fail 'folder lacks accessible button semantics'
grep -Fq 'Accessible.onPressAction: root.toggleRequested()' "$FOLDER" || fail 'folder accessible action is not connected'
grep -Fq 'folderHeader.focus = false' "$FOLDER" || fail 'mouse expansion does not clear stale folder focus'
grep -Fq 'root.navigationHost.focusAdjacentSettingsNavigationItem(folderHeader' "$FOLDER" || fail 'keyboard traversal is not delegated to the navigation host'
grep -Fq 'searchMatchCount' "$FOLDER" || fail 'folder search match feedback is missing'
grep -Fq 'currentPageLabel' "$FOLDER" || fail 'collapsed active-page hint is missing'
grep -Fq 'SettingsTabBase {' "$SUBTAB" || fail 'SettingsSubTab no longer extends the shared tab primitive'
grep -Fq 'showFrame: false' "$GROUP" || fail 'SettingsGroup section primitive is unexpectedly coupled to navigation folders'
! grep -Fq 'id: navigationGroupHeader' "$NAV" || fail 'folder header implementation is still duplicated inline in SettingsNavigation'
! grep -Fq 'id: navigationGroupItems' "$NAV" || fail 'folder page list implementation is still duplicated inline in SettingsNavigation'

node - "$NAV" "$FOLDER" <<'NODE'
const fs = require('fs');
const assert = require('assert');
for (const file of process.argv.slice(2)) {
  const source = fs.readFileSync(file, 'utf8');
  const stack = [];
  const pairs = { ')': '(', ']': '[', '}': '{' };
  let state = 'code', escaped = false;
  for (let i = 0; i < source.length; i++) {
    const c = source[i], n = source[i + 1];
    if (state === 'line') { if (c === '\n') state = 'code'; continue; }
    if (state === 'block') { if (c === '*' && n === '/') { state = 'code'; i++; } continue; }
    if (state === 'single' || state === 'double') {
      if (escaped) { escaped = false; continue; }
      if (c === '\\') { escaped = true; continue; }
      if ((state === 'single' && c === "'") || (state === 'double' && c === '"')) state = 'code';
      continue;
    }
    if (c === '/' && n === '/') { state = 'line'; i++; continue; }
    if (c === '/' && n === '*') { state = 'block'; i++; continue; }
    if (c === "'") { state = 'single'; continue; }
    if (c === '"') { state = 'double'; continue; }
    if ('([{'.includes(c)) stack.push(c);
    else if (pairs[c]) assert.strictEqual(stack.pop(), pairs[c], `${file}: unbalanced ${c}`);
  }
  assert.deepStrictEqual(stack, [], `${file}: unclosed QML delimiters`);
  assert.notStrictEqual(state, 'single');
  assert.notStrictEqual(state, 'double');
}
NODE

echo 'Settings navigation folder primitive: shared folder, tab and section-group roles: OK'

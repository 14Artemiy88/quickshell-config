#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
CONTROLLER="$ROOT/components/settings/SettingsSearchController.qml"
fail() { echo "Settings search controller extraction: FAIL: $*" >&2; exit 1; }

[[ -f "$CONTROLLER" ]] || fail 'SettingsSearchController.qml is missing'
grep -Fq 'SettingsSearchController {' "$WIDGET" || fail 'SettingsWidget does not instantiate the controller'
grep -Fq 'host: root' "$WIDGET" || fail 'controller does not receive the navigation host'
grep -Fq 'searchRoot: root' "$WIDGET" || fail 'controller does not receive the complete searchable tree'
grep -Fq 'searchInput: settingsSearchInput' "$WIDGET" || fail 'search field is not passed to the controller'
grep -Fq 'highlight: settingsSearchHighlight' "$WIDGET" || fail 'highlight item is not passed to the controller'
grep -Fq 'highlightTimer: settingsSearchHighlightTimer' "$WIDGET" || fail 'highlight timer is not passed to the controller'
for state in settingsSearchIndex settingsSearchResults settingsSearchQuery settingsSearchSelectedIndex settingsSearchCandidateSubTab; do
    grep -Fq "property alias $state: settingsSearchController.$state" "$WIDGET" || fail "$state compatibility alias is missing"
    grep -Eq "property [A-Za-z]+ $state" "$CONTROLLER" || fail "$state is not owned by the controller"
done
for method in settingsSearchPageInfo settingsSearchSiblingLabel settingsSearchItemLabel settingsSearchGroupHeading collectSettingsSearchItems rebuildSettingsSearchIndex updateSettingsSearchResults isSettingsSearchTargetVisible openSettingsSearchResult trySettingsSearchSubTab findSettingsSearchFlickable finishSettingsSearchNavigation showSettingsSearchHighlight handleSettingsSearchKey; do
    grep -Fq "function $method(" "$CONTROLLER" || fail "$method was not moved to the controller"
done
! grep -Eq 'function (settingsSearchPageInfo|settingsSearchSiblingLabel|settingsSearchItemLabel|settingsSearchGroupHeading|collectSettingsSearchItems|trySettingsSearchSubTab|findSettingsSearchFlickable|finishSettingsSearchNavigation|showSettingsSearchHighlight)\(' "$WIDGET" || fail 'search implementation remains duplicated in SettingsWidget'
for method in rebuildSettingsSearchIndex updateSettingsSearchResults openSettingsSearchResult handleSettingsSearchKey; do
    grep -Fq "settingsSearchController.$method(" "$WIDGET" || fail "SettingsWidget no longer delegates $method"
done

node - "$WIDGET" "$CONTROLLER" <<'NODE'
const assert = require('assert');
const fs = require('fs');
for (const file of process.argv.slice(2)) {
  const source = fs.readFileSync(file, 'utf8');
  const stack = [];
  const pairs = { ')': '(', ']': '[', '}': '{' };
  let state = 'code', escaped = false;
  for (let i = 0; i < source.length; i++) {
    const c = source[i], n = source[i + 1];
    if (state === 'line') { if (c === '\n') state = 'code'; continue; }
    if (state === 'block') { if (c === '*' && n === '/') { state = 'code'; i++; } continue; }
    if (state === 'single' || state === 'double' || state === 'template') {
      if (escaped) { escaped = false; continue; }
      if (c === '\\') { escaped = true; continue; }
      if ((state === 'single' && c === "'") || (state === 'double' && c === '"') || (state === 'template' && c === '`')) state = 'code';
      continue;
    }
    if (c === '/' && n === '/') { state = 'line'; i++; continue; }
    if (c === '/' && n === '*') { state = 'block'; i++; continue; }
    if (c === "'") { state = 'single'; continue; }
    if (c === '"') { state = 'double'; continue; }
    if (c === '`') { state = 'template'; continue; }
    if ('([{'.includes(c)) stack.push(c);
    else if (pairs[c]) assert.strictEqual(stack.pop(), pairs[c], `${file}: unmatched ${c}`);
  }
  assert.deepStrictEqual(stack, [], `${file}: unclosed delimiter`);
  assert.strictEqual(state, 'code', `${file}: unterminated lexical state`);
}
NODE

echo 'Settings search controller extraction: state ownership, delegated navigation, compatibility aliases and balanced QML delimiters: OK'

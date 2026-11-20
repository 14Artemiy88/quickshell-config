#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SEARCH="$ROOT/js/settings/SettingsSearch.js"
CONTROLLER="$ROOT/components/settings/SettingsSearchController.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
fail() { echo "Settings search match cycling: FAIL: $*" >&2; exit 1; }

grep -Fq 'function cycleIndex(entries, pageId, currentId, direction)' "$SEARCH" || fail 'pure page-local cycle helper is missing'
grep -Fq 'SettingsSearch.cycleIndex(' "$CONTROLLER" || fail 'controller does not use the page-local cycle helper'
grep -Fq 'function cycleSettingsSearchMatch(direction)' "$CONTROLLER" || fail 'controller cycle handler is missing'
grep -Fq 'function scrollSettingsSearchEntryIntoView(entry)' "$CONTROLLER" || fail 'selected match is not scrolled into view'
grep -Fq 'settingsSearchActiveMatchId' "$CONTROLLER" || fail 'active match identity is not tracked'
grep -Fq 'sequence: "F3"' "$WIDGET" || fail 'next-match shortcut is missing'
grep -Fq 'sequence: "Shift+F3"' "$WIDGET" || fail 'previous-match shortcut is missing'
grep -Fq 'settingsSearchController.cycleSettingsSearchMatch(1)' "$WIDGET" || fail 'F3 does not invoke forward cycling'
grep -Fq 'settingsSearchController.cycleSettingsSearchMatch(-1)' "$WIDGET" || fail 'Shift+F3 does not invoke backward cycling'
grep -Fq 'Shift+F3 — предыдущее совпадение' "$NAV" || fail 'keyboard hint is missing from search status tooltip'

for primitive in SettingsInputField SettingsCheckBox SettingsComboBox SettingsNumberField SettingsColorField SettingsFontField; do
    file="$ROOT/components/settings/primitives/$primitive.qml"
    grep -Fq 'property bool settingsSearchCurrentMatch: false' "$file" || fail "$primitive cannot mark the active match"
done
for primitive in SettingsCheckBox SettingsNumberField SettingsColorField SettingsFontField; do
    grep -Fq 'currentMatch: root.settingsSearchCurrentMatch' "$ROOT/components/settings/primitives/$primitive.qml" || fail "$primitive does not pass active-match state to the shared outline"
done
for primitive in SettingsInputField SettingsComboBox; do
    grep -Fq 'root.settingsSearchCurrentMatch ? Config.accent' "$ROOT/components/settings/primitives/$primitive.qml" || fail "$primitive does not visually distinguish the active match"
done
grep -Fq 'root.currentMatch' "$ROOT/components/settings/primitives/SettingsSearchHighlight.qml" || fail 'shared outline does not receive active-match state'
grep -Fq 'Config.accent' "$ROOT/components/settings/primitives/SettingsSearchHighlight.qml" || fail 'shared outline has no active-match accent'

node - "$ROOT" <<'NODE'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/settings/SettingsSearch.js'), 'utf8')
  .replace(/^\.pragma library\s*/m, '');
const api = {};
vm.runInNewContext(source, api, { filename: 'SettingsSearch.js' });
const entries = [
  {id:'weather/a', pageId:'weather'},
  {id:'mopidy/a', pageId:'mopidy'},
  {id:'weather/b', pageId:'weather'},
  {id:'weather/c', pageId:'weather'},
  {id:'player/a', pageId:'player'}
];
const cases = [
  ['weather', '', 1, 0, 'first forward match'],
  ['weather', '', -1, 3, 'first reverse match starts at last'],
  ['weather', 'weather/a', 1, 2, 'forward next match'],
  ['weather', 'weather/c', 1, 0, 'forward wraps around'],
  ['weather', 'weather/a', -1, 3, 'reverse wraps around'],
  ['weather', 'not-present', 1, 0, 'unknown current match resets forward'],
  ['mopidy', 'weather/a', 1, 1, 'cycling stays page-local'],
  ['missing', '', 1, -1, 'page without matches is a no-op']
];
for (const [page, current, direction, expected, label] of cases) {
  const actual = api.cycleIndex(entries, page, current, direction);
  if (actual !== expected) throw new Error(`${label}: expected ${expected}, got ${actual}`);
}
console.log('Page-local next/previous cycling, wrap-around and empty-page handling: 8/8');
NODE

echo 'settings search match cycling: OK'

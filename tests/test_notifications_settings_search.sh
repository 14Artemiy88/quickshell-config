#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SECTION="$ROOT/components/settings/sections/SettingsNotificationsSection.qml"
ANIMATION="$ROOT/components/settings/primitives/SettingsAnimationGroup.qml"
CHECKBOX="$ROOT/components/settings/primitives/SettingsCheckBox.qml"
TEXT_FIELD="$ROOT/components/settings/primitives/SettingsTextField.qml"
ROW="$ROOT/components/settings/primitives/SettingsRow.qml"
CONTROLLER="$ROOT/components/settings/SettingsSearchController.qml"
fail() { echo "Notifications settings search: FAIL: $*" >&2; exit 1; }

for id in \
    notifications-do-not-disturb \
    notifications-history-limit \
    notifications-history-retention \
    notifications-dnd-sender-search \
    notifications-dnd-show-all \
    notifications-default-timeout \
    notifications-critical-timeout \
    notifications-timeout-indicator-visible \
    notifications-card-spacing \
    notifications-image-height \
    notifications-show-app-icon \
    notifications-show-body-images \
    notifications-show-progress \
    notifications-summary-font \
    notifications-summary-font-size \
    notifications-summary-color \
    notifications-leading-visual-size \
    notifications-app-name-font \
    notifications-app-name-font-size \
    notifications-app-name-color \
    notifications-app-name-bold \
    notifications-leading-visual-radius \
    notifications-card-padding \
    notifications-body-font \
    notifications-body-font-size \
    notifications-body-color \
    notifications-background-color \
    notifications-vertical-anchor \
    notifications-animation-visibility-style; do
    grep -Fq "settingsSearchId: \"$id\"" "$SECTION" || fail "missing settings search entry $id"
done

for file in "$SECTION" "$ANIMATION"; do
    grep -Eq 'settingsSearch(Label|Keywords):' "$file" || fail "missing readable search metadata in $file"
done

grep -Fq 'settingsSearchId: "notifications-dnd-ignore-" + String(modelData.id || modelData.name || "sender")' "$SECTION" \
    || fail 'per-sender Ignore DND controls are not searchable by sender identity'
grep -Fq 'settingsSearchId: "notifications-dnd-disable-" + String(modelData.id || modelData.name || "sender")' "$SECTION" \
    || fail 'per-sender Disable controls are not searchable by sender identity'
grep -Fq 'settingsSearchSubTabIndex: 1' "$SECTION" \
    || fail 'Notifications/DND application controls have no subtab routing'
grep -Fq 'settingsSearchSubTabIndex: 2' "$SECTION" \
    || fail 'history controls have no subtab routing'
grep -Fq 'settingsSearchSubTabIndex: 3' "$SECTION" \
    || fail 'animation controls have no subtab routing'
grep -Fq 'profileSearchId: "notifications-animation-profile"' "$SECTION" \
    || fail 'notification animation profile has no search ID'
grep -Fq 'durationSearchId: "notifications-animation-duration"' "$SECTION" \
    || fail 'notification animation duration has no search ID'
grep -Fq 'property string profileSearchId: ""' "$ANIMATION" \
    || fail 'shared animation primitive lacks optional profile-search metadata'
grep -Fq 'settingsSearchId: root.profileSearchId' "$ANIMATION" \
    || fail 'animation profile search metadata is not forwarded to its control'
grep -Fq 'settingsSearchId: root.durationSearchId' "$ANIMATION" \
    || fail 'animation duration search metadata is not forwarded to its control'
grep -Fq 'property int settingsSearchSubTabIndex: -1' "$CHECKBOX" \
    || fail 'checkbox primitive lacks direct subtab search metadata'
grep -Fq 'property int settingsSearchSubTabIndex: -1' "$TEXT_FIELD" \
    || fail 'text-field primitive lacks direct subtab search metadata'
grep -Fq 'property int settingsSearchSubTabIndex: -1' "$ROW" \
    || fail 'settings row primitive lacks inherited subtab search metadata'
grep -Fq 'var current = item || null' "$CONTROLLER" \
    || fail 'settings search controller does not inspect the matched control itself for subtab metadata'

node - "$SECTION" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const source = fs.readFileSync(process.argv[2], 'utf8');
const ids = [...source.matchAll(/settingsSearchId:\s*"([^"]+)"/g)].map(m => m[1]);
const duplicates = ids.filter((id, i) => ids.indexOf(id) !== i);
assert.deepStrictEqual(duplicates, [], 'static notification settings search IDs are unique');
assert(ids.length >= 30, 'notifications section exposes broad explicit settings-search metadata');
const idLines = source.split(/\r?\n/);
for (let i = 0; i < idLines.length; i++) {
  if (!idLines[i].includes('settingsSearchId:')) continue;
  const block = idLines.slice(i, i + 5).join('\n');
  assert(/settingsSearchLabel:/.test(block), `search label follows id at line ${i + 1}`);
  assert(/settingsSearchKeywords:/.test(block), `search keywords follow id at line ${i + 1}`);
}
console.log(`Notifications settings search metadata: ${ids.length} unique static entries plus per-sender DND rules: OK`);
NODE

node - "$CONTROLLER" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const source = fs.readFileSync(process.argv[2], 'utf8');
const start = source.indexOf('    function settingsSearchSubTabIndex(item, pageRoot)');
assert(start >= 0, 'subtab resolver exists');
const open = source.indexOf('{', start);
let depth = 0, end = -1, state = 'code';
for (let i = open; i < source.length; i++) {
  const c = source[i];
  if (state === 'string') { if (c === '\\') i++; else if (c === '"') state = 'code'; continue; }
  if (state === 'single') { if (c === '\\') i++; else if (c === "'") state = 'code'; continue; }
  if (c === '"') { state = 'string'; continue; }
  if (c === "'") { state = 'single'; continue; }
  if (c === '{') depth++;
  else if (c === '}' && --depth === 0) { end = i + 1; break; }
}
assert(end > open, 'subtab resolver body is complete');
const fn = vm.runInNewContext(`(${source.slice(start, end).replace(/^\s*function\s+settingsSearchSubTabIndex/, 'function')})`);
const page = {};
const dnd = { settingsSearchSubTabIndex: 1, parent: page };
const control = { settingsSearchSubTabIndex: -1, parent: dnd };
assert.strictEqual(fn(control, page), 1, 'default -1 on a control falls through to its DND Applications group');
const historyRow = { settingsSearchSubTabIndex: 2, parent: dnd };
const historyControl = { parent: historyRow };
assert.strictEqual(fn(historyControl, page), 2, 'history row overrides the parent group context');
const explicitControl = { settingsSearchSubTabIndex: 0, parent: dnd };
assert.strictEqual(fn(explicitControl, page), 0, 'direct DND mode control overrides parent context');
console.log('Settings search subtab routing from control and row metadata: OK');
NODE

echo 'notifications settings search: OK'

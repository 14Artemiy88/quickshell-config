#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
CONTROLLER="$ROOT/components/settings/SettingsProfileController.qml"
HOST="$ROOT/components/settings/SettingsPageHost.qml"
CONTENT="$ROOT/components/settings/SettingsPageContent.qml"
WINDOW="$ROOT/components/settings/sections/SettingsWindowSection.qml"
MODULES="$ROOT/components/settings/sections/SettingsModulesSection.qml"
COLORS="$ROOT/components/settings/sections/SettingsColorsSection.qml"
PROFILES="$ROOT/js/settings/SettingsProfiles.js"
SETTINGS="$ROOT/Settings.qml"

grep -Fq 'SettingsProfileController {' "$WIDGET"
grep -Fq 'property alias profileController: settingsProfileController' "$WIDGET"
grep -Fq 'settings: root.settings' "$WIDGET"
grep -Fq 'property alias profileModel: profileEntries' "$CONTROLLER"
grep -Fq 'function refreshProfileModel()' "$CONTROLLER"
grep -Fq 'function indexOfProfile(name)' "$CONTROLLER"
grep -Fq 'function canSaveScope(scope, argument)' "$CONTROLLER"
grep -Fq 'function canResetScope(scope, argument)' "$CONTROLLER"
grep -Fq 'function saveAll()' "$CONTROLLER"
grep -Fq 'function saveScope(scope, argument)' "$CONTROLLER"
grep -Fq 'function loadProfile(name)' "$CONTROLLER"
grep -Fq 'function deleteProfile(name)' "$CONTROLLER"
grep -Fq 'onProfilesRevisionChanged() { root.refreshProfileModel() }' "$CONTROLLER"
! grep -Fq 'id: profileModel' "$WIDGET"
! grep -Fq 'function refreshProfileModel()' "$WIDGET"
grep -Fq 'root.host.profileController.saveAll()' "$HOST"
grep -Fq 'root.host.profileController.saveScope(root.host.currentPageSaveScope)' "$HOST"
grep -Fq 'model: host && host.profileController ? host.profileController.profileModel : []' "$WINDOW"
grep -Fq 'host.profileController.indexOfProfile' "$WINDOW"
grep -Fq 'host.profileController.saveProfile(text)' "$WINDOW"
grep -Fq 'host.profileController.loadProfile(profileCombo.currentText)' "$WINDOW"
grep -Fq 'host.profileController.deleteProfile(profileCombo.currentText)' "$WINDOW"
grep -Fq 'host.profileController.saveScope("modules")' "$MODULES"
grep -Fq 'host.profileController.saveScope("module", moduleRow.moduleName)' "$MODULES"
grep -Fq 'host.profileController.saveScope("themes")' "$COLORS"
grep -Fq 'host.profileController.saveScope("colors", modelData.colors)' "$COLORS"
# Sparse-profile storage and mutation remain in the existing backend; the UI
# controller is only an adapter and must not duplicate the persistence format.
grep -Fq 'var SPARSE_FORMAT = "sparse-v1"' "$PROFILES"
grep -Fq 'function saveProfile(name)' "$SETTINGS"
grep -Fq 'return SettingsProfiles.saveProfile(root, name)' "$SETTINGS"
grep -Fq 'function saveProfileScope(name, scope, argument)' "$SETTINGS"
grep -Fq 'return SettingsProfiles.saveProfileScope(root, name, scope, argument)' "$SETTINGS"

node - "$WIDGET" "$CONTROLLER" "$HOST" "$WINDOW" "$MODULES" "$COLORS" <<'NODE'
const assert = require('assert');
const fs = require('fs');
for (const file of process.argv.slice(2)) {
  const source = fs.readFileSync(file, 'utf8');
  const stack = [];
  const pairs = { ')': '(', ']': '[', '}': '{' };
  let mode = 'code', escaped = false;
  for (let i = 0; i < source.length; i++) {
    const ch = source[i], next = source[i + 1];
    if (mode === 'line') { if (ch === '\n') mode = 'code'; continue; }
    if (mode === 'block') { if (ch === '*' && next === '/') { mode = 'code'; i++; } continue; }
    if (mode === 'single' || mode === 'double' || mode === 'template') {
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
    if (ch === '(' || ch === '[' || ch === '{') stack.push(ch);
    else if (Object.prototype.hasOwnProperty.call(pairs, ch)) assert.strictEqual(stack.pop(), pairs[ch], `${file}: unmatched ${ch}`);
  }
  assert.strictEqual(mode, 'code', `${file}: unterminated comment/string`);
  assert.deepStrictEqual(stack, [], `${file}: unclosed QML delimiters`);
}
NODE

echo 'Settings profile controller extraction: centralized UI model/actions, explicit profile-model wiring, sparse persistence backend preserved, QML delimiters balanced: OK'

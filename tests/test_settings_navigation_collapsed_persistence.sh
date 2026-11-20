#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
SCHEMA="$ROOT/js/settings/SettingsSchema.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplyCore.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
PROFILES="$ROOT/js/settings/SettingsProfiles.js"
SETTINGS="$ROOT/Settings.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"

grep -Fq 'property var settingsNavigationCollapsedGroups: ({ appearance: false, modules: false })' "$CONFIG"
grep -Fq 'settingsNavigationCollapsedGroups: ({ appearance: false, modules: false })' "$DEFAULTS"
grep -Fq 'settingsNavigationCollapsedGroups: cloneValue(config.settingsNavigationCollapsedGroups' "$PERSIST"
grep -Fq 'Schema.normalizeSettingsNavigationCollapsedGroups(' "$APPLY"
grep -Fq '"settingsNavigationCollapsedGroups"' "$RESETS"
grep -Fq '"settingsNavigationCollapsedGroups"' "$PROFILES"
grep -Fq 'settingsNavigationCollapsedGroups' "$SETTINGS"
grep -Fq 'readonly property var collapsedSettingsNavigationGroups: Config.settingsNavigationCollapsedGroups' "$WIDGET"
grep -Fq 'root.settings.save()' "$WIDGET"

node - "$SCHEMA" "$PERSIST" "$APPLY" "$PROFILES" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const sandbox = {};
vm.runInNewContext(source, sandbox, { filename: process.argv[2] });
const normalize = sandbox.normalizeSettingsNavigationCollapsedGroups;
assert.deepStrictEqual(JSON.parse(JSON.stringify(normalize({}, { appearance: true, modules: false }))), {
  appearance: true, modules: false
}, 'partial input preserves the current group state');
assert.deepStrictEqual(JSON.parse(JSON.stringify(normalize({ appearance: false, modules: true, stale: true }, {}))), {
  appearance: false, modules: true
}, 'unknown group IDs are discarded');
assert.deepStrictEqual(JSON.parse(JSON.stringify(normalize({ appearance: 'yes', modules: 1 }, {}))), {
  appearance: false, modules: false
}, 'non-boolean values fall back to expanded');
assert.deepStrictEqual(JSON.parse(JSON.stringify(normalize(['appearance'], { appearance: true, modules: true }))), {
  appearance: true, modules: true
}, 'non-object input cannot corrupt the current state');

const persistenceSource = fs.readFileSync(process.argv[3], 'utf8').replace(/^\.pragma library\s*/, '');
const persistence = {};
vm.runInNewContext(persistenceSource, persistence, { filename: process.argv[3] });
const owner = { moduleNames: [], colorNames: [], weatherToken: '' };
const config = { settingsNavigationCollapsedGroups: { appearance: true, modules: false } };
const snapshot = persistence.snapshotObject(owner, config);
assert.deepStrictEqual(JSON.parse(JSON.stringify(snapshot.settingsNavigationCollapsedGroups)), {
  appearance: true, modules: false
}, 'settings snapshots retain collapsed group preferences');

const applySource = fs.readFileSync(process.argv[4], 'utf8').replace(/^\.pragma library\s*/, '').replace(/^\.import .*$/gm, '');
const applySandbox = { Schema: sandbox };
vm.runInNewContext(applySource, applySandbox, { filename: process.argv[4] });
const restored = { settingsNavigationCollapsedGroups: { appearance: false, modules: false } };
applySandbox.apply({}, restored, { settingsNavigationCollapsedGroups: { appearance: true, modules: true, stale: true } });
assert.deepStrictEqual(JSON.parse(JSON.stringify(restored.settingsNavigationCollapsedGroups)), {
  appearance: true, modules: true
}, 'settings loading restores only supported group state');

const profilesSource = fs.readFileSync(process.argv[5], 'utf8').replace(/^\.pragma library\s*/, '');
const profiles = {};
vm.runInNewContext(profilesSource, profiles, { filename: process.argv[5] });
assert.strictEqual(profiles.profileSavePathMatches({}, 'settingsWindow', null, ['settingsNavigationCollapsedGroups', 'modules']), true,
  'collapsed group preferences belong to the settings-window profile scope');
console.log('settings navigation collapsed-state schema, settings round-trip and profile scope: OK');
NODE

echo 'settings navigation collapsed-state persistence: OK'

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAV="$ROOT/components/settings/SettingsNavigationController.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
REGISTRY="$ROOT/js/settings/SettingsPageRegistry.js"

# QML imports are lexical to each component file. The navigation controller
# reads Config directly and therefore must import the root qmldir itself.
grep -Fq 'import "../.."' "$NAV" || {
  echo 'SettingsNavigationController must import the root module for Config/Settings singletons' >&2
  exit 1
}
grep -Fq 'var saved = Config.settingsTabOrder' "$NAV"
grep -Fq 'var labels = Config.settingsTabLabels' "$NAV"
grep -Fq 'settings: root.settings' "$WIDGET"
grep -Fq 'model: root.settingsNavigationItems' "$WIDGET"

node - "$REGISTRY" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const sandbox = {};
vm.runInNewContext(source, sandbox, { filename: process.argv[2] });
const tabs = sandbox.tabDefinitions();
assert.strictEqual(tabs.length, 15, 'all settings tabs must be registered');
assert.strictEqual(tabs[0].id, 'modules');
assert.strictEqual(tabs[tabs.length - 1].id, 'settingsWindow');
assert.strictEqual(new Set(tabs.map(tab => tab.id)).size, tabs.length, 'tab IDs must be unique');
console.log('Settings navigation registry: 15 unique tabs');
NODE

echo 'SettingsNavigationController singleton import scope: OK'

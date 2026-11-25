#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const qml = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
const propertyCount = name => (qml.match(new RegExp('^\\s*' + name + '\\s*:', 'gm')) || []).length;
const functionCount = name => (qml.match(new RegExp('^\\s*function\\s+' + name + '\\s*\\(', 'gm')) || []).length;
assert.strictEqual(propertyCount('screen'), 1,
  'Dashboard PanelWindow must define screen exactly once');
assert.strictEqual(functionCount('resolveDashboardScreen'), 1,
  'Dashboard must have one monitor resolver; module monitor selection stays centralized');
assert(qml.includes('readonly property string configuredMonitorName: String((Settings.moduleMonitors || {}).dashboard || Config.monitorName || "")'),
  'Dashboard monitor resolution must honor the per-module monitor selection');
assert(qml.includes('screen: root.resolveDashboardScreen()'),
  'Dashboard PanelWindow screen must use its configured monitor resolver');
console.log('Dashboard QML unique screen property and monitor resolver: OK');
JS

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const helperPath = path.join(root, 'js/ModulePresentation.js');
const helperSource = fs.readFileSync(helperPath, 'utf8').replace(/^\.pragma library\s*/, '');
const sandbox = {};
vm.createContext(sandbox);
vm.runInContext(helperSource + '\nthis.api = {MODES, normalizeMode, resolveMode};', sandbox);
const api = sandbox.api;
const equal = (actual, expected, label) => {
  if (actual !== expected) throw new Error(`${label}: expected ${expected}, got ${actual}`);
};

// Shared default thresholds are inclusive at both ends and use logical pixels.
for (const width of [Number.NaN, -10, 0])
  equal(api.resolveMode(width, 'auto', 260, 420), 'regular', `uninitialized geometry ${width}`);
for (const width of [1, 259, 260])
  equal(api.resolveMode(width, 'auto', 260, 420), 'compact', `compact boundary ${width}`);
for (const width of [260.001, 261, 315, 419, 419.999])
  equal(api.resolveMode(width, 'auto', 260, 420), 'regular', `regular boundary ${width}`);
for (const width of [420, 421, 1000])
  equal(api.resolveMode(width, 'auto', 260, 420), 'wide', `wide boundary ${width}`);

// Explicit overrides are normalized; invalid overrides fall back to regular.
equal(api.resolveMode(180, ' COMPACT ', 260, 420), 'compact', 'compact override');
equal(api.resolveMode(315, 'Wide', 260, 420), 'wide', 'wide override');
equal(api.resolveMode(600, 'regular', 260, 420), 'regular', 'regular override');
equal(api.resolveMode(180, 'unknown', 260, 420), 'regular', 'invalid override fallback');
equal(api.normalizeMode(' WIDE ', 'regular'), 'wide', 'mode normalization');
equal(api.normalizeMode('broken', 'regular'), 'regular', 'normalization fallback');

// Per-window thresholds work, while invalid values recover safe defaults.
equal(api.resolveMode(300, 'auto', 300, 500), 'compact', 'custom compact threshold');
equal(api.resolveMode(499, 'auto', 300, 500), 'regular', 'custom regular interval');
equal(api.resolveMode(500, 'auto', 300, 500), 'wide', 'custom wide threshold');
equal(api.resolveMode(260, 'auto', -1, 0), 'compact', 'invalid threshold fallback');

const windowQml = fs.readFileSync(path.join(root, 'components/WidgetWindow.qml'), 'utf8');
const frameQml = fs.readFileSync(path.join(root, 'components/primitives/ModuleFrame.qml'), 'utf8');
for (const token of [
  'property string presentationModeOverride: "auto"',
  'property int compactWidthBreakpoint: 260',
  'property int wideWidthBreakpoint: 420',
  'root.contentWidth,',
  'readonly property string presentationMode: root.presentationMode',
  'readonly property real widthBudget: root.contentWidth',
  'readonly property bool active: root.visible',
]) if (!windowQml.includes(token)) throw new Error(`WidgetWindow host contract missing: ${token}`);
for (const token of [
  'root.hostPresentationMode !== ""',
  'ModulePresentation.normalizeMode(root.hostPresentationMode, "regular")',
  'ModulePresentation.resolveMode(root.width, "auto", 260, 420)',
  'host && host.widthBudget !== undefined',
  'readonly property bool compactPresentation:',
  'readonly property bool regularPresentation:',
  'readonly property bool widePresentation:',
  'readonly property bool presentationActive:',
]) if (!frameQml.includes(token)) throw new Error(`ModuleFrame forwarding/fallback contract missing: ${token}`);

console.log('Shared module presentation thresholds, overrides, host forwarding and fallback: OK');
JS

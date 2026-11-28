#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = process.argv[2];
const read = p => fs.readFileSync(path.join(root, p), 'utf8');

const curvesSource = read('js/AnimationCurves.js').replace(/^\.pragma library\s*/m, '');
const curvesContext = {};
vm.createContext(curvesContext);
vm.runInContext(curvesSource + '\nthis.api = { overshootFactor, normalizeProfile };', curvesContext);
const curves = curvesContext.api;

assert.equal(curves.overshootFactor('linear'), 0, 'linear curve needs no overscan');
assert.equal(curves.overshootFactor('ease-out'), 0, 'standard ease-out stays in [0,1]');
assert.ok(Math.abs(curves.overshootFactor('cubic-bezier(0.34, 1.56, 0.64, 1)') - 0.098) < 0.002,
  'the spring example computes its actual CSS overshoot');
assert.ok(curves.overshootFactor('cubic-bezier(0.34, -0.4, 0.64, 1)') > 0.05,
  'negative undershoot is measured too');

const widget = read('components/WidgetWindow.qml');
for (const token of [
  'property string visibilityAnimationStyle: "none"',
  'property string visibilityAnimationProfile: "ease-out"',
  'AnimationCurves.overshootFactor(root.visibilityAnimationProfile)',
  'Number(root.contentWidth) || 0) * root.visibilityOvershootFactor',
  'Number(root.contentHeight) || 0) * root.visibilityOvershootFactor',
  'root.visualContentWidth + root.visibilityOverscanPhysicalX * 2',
  'root.visualContentHeight + root.visibilityOverscanPhysicalY * 2',
  'margins.left: root.offsetX - root.visibilityOverscanPhysicalX',
  'margins.top: root.offsetY - root.visibilityOverscanPhysicalY',
  'x: root.visibilityOverscanPhysicalX',
  'y: root.visibilityOverscanPhysicalY',
  'item: root.inputMaskEnabled ? contentHost : null',
  'width: root.visualContentWidth',
  'height: root.visualContentHeight',
]) assert.ok(widget.includes(token), `WidgetWindow overscan contract missing: ${token}`);

const shell = read('shell.qml');
for (const [module, key] of [
  ['calendar', 'Calendar'], ['mopidy', 'Mopidy'], ['networks', 'Network'], ['settings', 'Settings']
]) {
  const start = shell.indexOf(`moduleName: "${module}"`);
  assert.ok(start >= 0, `${module} WidgetWindow exists`);
  const block = shell.slice(shell.lastIndexOf('WidgetWindow {', start), shell.indexOf('\n    WidgetWindow {', start) < 0 ? shell.length : shell.indexOf('\n    WidgetWindow {', start));
  assert.ok(block.includes(`visibilityAnimationStyle: Config.animation${key}VisibilityStyle`), `${module} style is connected to surface overscan`);
  assert.ok(block.includes(`visibilityAnimationProfile: Config.animation${key}VisibilityProfile`), `${module} curve is connected to surface overscan`);
}
assert.ok(shell.includes('settingsWindow.visualContentWidth') && shell.includes('settingsWindow.visualContentHeight'),
  'settings move proxy uses the real content dimensions, not the expanded surface');

console.log('WidgetWindow CSS overshoot bleed, preserved module origin/input geometry and curve bindings: OK');
JS

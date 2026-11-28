#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
curves = (root / "js/AnimationCurves.js").read_text(encoding="utf-8")
config = (root / "Config.qml").read_text(encoding="utf-8")
primitive = (root / "components/settings/primitives/SettingsAnimationGroup.qml").read_text(encoding="utf-8")
assert '"ease": [0.25, 0.1, 0.25, 1, 1, 1]' in curves
assert '"ease-in": [0.42, 0, 1, 1, 1, 1]' in curves
assert '"ease-out": [0, 0, 0.58, 1, 1, 1]' in curves
assert '"ease-in-out": [0.42, 0, 0.58, 1, 1, 1]' in curves
assert 'return ["linear", "ease", "ease-in", "ease-out", "ease-in-out", "cubic-bezier()"]' in curves
assert 'function parseBezier(value)' in curves
assert 'values[0] < 0 || values[0] > 1 || values[2] < 0 || values[2] > 1' in curves
assert 'values[0] < 0 || values[0] > 1 || values[2] < 0 || values[2] > 1' in curves
assert 'values[1] < -5' not in curves
assert 'return AnimationCurves.forProfile(profile, phase)' in config
assert 'return Easing.BezierSpline' in config
assert 'name === "none" || name === "linear" || name === ""' in config
assert 'property var profileValues: ["none", "linear", "ease", "ease-in", "ease-out", "ease-in-out", "cubic-bezier"]' in primitive
assert 'property string profileLabel: "Функция сглаживания"' in primitive
assert 'label: "Параметры кривой"' in primitive
assert 'root.profileEdited("cubic-bezier(" + parts.join(", ") + ")")' in primitive
assert 'minimum: index % 2 === 0 ? 0 : -Infinity' in primitive
assert 'maximum: index % 2 === 0 ? 1 : Infinity' in primitive
assert 'inputMethodHints: Qt.ImhFormattedNumbersOnly' in primitive
print("CSS easing options, Bezier control points, custom cubic-bezier editor and validation bounds: OK")
PY
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(root + '/js/AnimationCurves.js', 'utf8').replace(/^\.pragma library\s*/m, '');
const curves = {}; vm.createContext(curves); vm.runInContext(source, curves);
const expected = { none: 'none', linear: 'linear', ease: 'ease', 'ease-in': 'ease-in', 'ease-out': 'ease-out', 'ease-in-out': 'ease-in-out' };
for (const [input, value] of Object.entries(expected)) if (curves.normalizeProfile(input) !== value) throw new Error(`normalize ${input}`);
const bezier = 'cubic-bezier(0.2, -12.3, 0.8, 14.4)';
if (curves.normalizeProfile(bezier) !== bezier) throw new Error('custom Bezier normalization');
if (curves.forProfile(bezier, 'enter').join(',') !== '0.2,-12.3,0.8,14.4,1,1') throw new Error('custom Bezier mapping');
if (curves.forProfile('linear', 'enter').length !== 0) throw new Error('linear should use Easing.Linear');
if (curves.forProfile('ease', 'enter').join(',') !== '0.25,0.1,0.25,1,1,1') throw new Error('ease mapping');
for (const bad of ['cubic-bezier(-0.1, 0, 1, 1)', 'cubic-bezier(0, 0, 1.1, 1)', 'cubic-bezier(0, 0, 1, NaN)', 'cubic-bezier(0, 0, 1)']) if (curves.normalizeProfile(bad) !== '') throw new Error(`accepted invalid curve: ${bad}`);
const legacy = {standard:'ease-out', spatial:'ease-out', effects:'ease-in', expressive:'ease-in-out'};
for (const [oldValue, newValue] of Object.entries(legacy)) if (curves.normalizeProfile(oldValue) !== newValue) throw new Error(`legacy ${oldValue} migration`);
console.log('CSS easing runtime mapping, cubic-bezier validation and legacy-profile migration: OK');
JS

node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
const configSource = fs.readFileSync(root + '/Config.qml', 'utf8');
const curveSource = fs.readFileSync(root + '/js/AnimationCurves.js', 'utf8').replace(/^\.pragma library\s*/m, '');
const curves = {}; vm.createContext(curves); vm.runInContext(curveSource, curves);
const functionBody = configSource.slice(configSource.indexOf('function normalizeAnimationProfile(profile)'), configSource.indexOf('property string monitorName:'));
const context = { AnimationCurves: curves, Easing: { Linear: 0, BezierSpline: 1 } };
vm.createContext(context);
vm.runInContext(functionBody + '\nthis.normalize = normalizeAnimationProfile; this.easing = animationEasingType; this.bezier = animationBezierCurve; this.values = animationBezierValues;', context);
if (context.easing('linear') !== 0 || context.easing('none') !== 0) throw new Error('linear/none must use Easing.Linear');
for (const profile of ['ease', 'ease-in', 'ease-out', 'ease-in-out', 'cubic-bezier(0.2, -0.5, 0.8, 1.5)']) {
  if (context.easing(profile) !== 1) throw new Error(`${profile} must use Easing.BezierSpline`);
}
if (context.bezier('ease').join(',') !== '0.25,0.1,0.25,1,1,1') throw new Error('Config ease curve mapping');
if (context.bezier('cubic-bezier(0.2, -0.5, 0.8, 1.5)').join(',') !== '0.2,-0.5,0.8,1.5,1,1') throw new Error('Config custom Bezier mapping');
console.log('Config runtime easing type and Bezier mapping: OK');
for (const relative of ['/js/settings/SettingsSchema.js', '/js/settings/SettingsProfiles.js']) {
  const helperSource = fs.readFileSync(root + relative, 'utf8').replace(/^\.pragma library\s*/m, '');
  const helperContext = {};
  vm.createContext(helperContext);
  vm.runInContext(helperSource + '\nthis.normalize = normalizeAnimationProfileValue;', helperContext);
  if (helperContext.normalize('spatial') !== 'ease-out') throw new Error(`${relative}: legacy alias migration`);
  if (helperContext.normalize('ease-in-out') !== 'ease-in-out') throw new Error(`${relative}: CSS keyword normalization`);
  const custom = 'cubic-bezier(0.15, -1.25, 0.85, 1.75)';
  if (helperContext.normalize(custom) !== custom) throw new Error(`${relative}: custom Y overshoot must survive persistence normalization`);
  if (helperContext.normalize('cubic-bezier(-0.1, 0, 0.8, 1)') !== '') throw new Error(`${relative}: invalid X control point accepted`);
}
console.log('Settings schema/profile persistence normalization for CSS curves and legacy aliases: OK');
JS

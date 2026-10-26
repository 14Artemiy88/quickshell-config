#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
launcher = (root / "components/launcher/Launcher.qml").read_text()
settings = (root / "components/settings/sections/SettingsLauncherSection.qml").read_text()
config = (root / "Config.qml").read_text()
defaults = (root / "js/settings/SettingsDefaults.js").read_text()
persist = (root / "js/settings/SettingsPersistence.js").read_text()
apply = (root / "js/settings/SettingsApplySystemVisual.js").read_text()
resets = (root / "js/settings/SettingsResets.js").read_text()
assert 'readonly property int modeCalculator: 9' in launcher
assert '{ id: 9, icon: "󰃬", label: "Calculator", mode: root.modeCalculator }' in launcher
assert 'case "calculator":' in launcher and 'case "calc":' in launcher
assert 'visible: root.mode === root.modeCalculator' in launcher
assert 'function buildCalculatorResults()' in launcher
assert 'Config.launcherCrossSearchCalculator !== false && Calculator.hasOperators(query)' in launcher
assert 'root.copyCalculatorResult(root.calculatorResults[0].result)' in launcher
assert 'function openCalculator(): void' in (root / 'shell.qml').read_text()
for file in (config, defaults, persist, apply, resets, settings):
    assert 'launcherCrossSearchCalculator' in file, 'calculator cross-search must be persisted and resettable'
assert 'pointer.globalPosition' in launcher or 'point.globalPosition' in launcher
assert 'root.disarmPointerHover()' in launcher
# Delegate hover-enter events may not assign selection; only the root pointer-motion handler does.
for delegate, list_name in [('appDelegate','appList'),('runDelegate','runList'),('windowDelegate','windowList'),('clipboardDelegate','clipboardList'),('networkDelegate','networkList'),('nixDelegate','nixList'),('passDelegate','passList'),('projectDelegate','projectList'),('powerDelegate','powerList')]:
    assert f'{list_name}.currentIndex = {delegate}.index' not in launcher
print('Launcher calculator tab, cross-search and hover gating wiring: OK')
PY
node - "$ROOT" <<'NODE'
const fs = require('fs'), vm = require('vm'), path = require('path');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/launcher/Calculator.js'), 'utf8').split('\n').slice(1).join('\n') + '\nthis.evaluate = evaluate; this.hasOperators = hasOperators;';
const sandbox = {}; vm.runInNewContext(source, sandbox);
for (const [expr, expected] of [['2+2','4'], ['(2+3)*4','20'], ['2^3^2','512'], ['-2^2','-4'], ['10/4','2.5'], ['8%3','2'], ['.5+1.25','1.75'], ['2×3','6'], ['8÷2','4'], ['5−7','-2']]) {
  const actual = sandbox.evaluate(expr);
  if (!actual || actual.text !== expected) throw new Error(`${expr}: expected ${expected}, got ${JSON.stringify(actual)}`);
}
for (const expr of ['1/0','foo()','2+','1..2','2**2','', '2/0']) {
  if (sandbox.evaluate(expr) !== null) throw new Error(`invalid expression was accepted: ${expr}`);
}
if (!sandbox.hasOperators('2+2') || !sandbox.hasOperators('2×2') || !sandbox.hasOperators('5−7') || sandbox.hasOperators('42')) throw new Error('cross-search operator detection failed');
console.log('Launcher calculator parser arithmetic/error cases: OK');
NODE
printf 'launcher calculator and explicit-hover test: OK\n'

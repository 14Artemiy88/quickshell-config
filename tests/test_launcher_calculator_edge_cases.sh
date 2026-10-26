#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/launcher/Calculator.js'), 'utf8')
  .split('\n').slice(1).join('\n') + '\nthis.evaluate = evaluate; this.hasOperators = hasOperators;';
const sandbox = {};
vm.runInNewContext(source, sandbox);
function expect(expression, expected) {
  const actual = sandbox.evaluate(expression);
  if (!actual || actual.text !== expected)
    throw new Error(`${JSON.stringify(expression)}: expected ${expected}, got ${JSON.stringify(actual)}`);
}
function reject(expression) {
  const actual = sandbox.evaluate(expression);
  if (actual !== null)
    throw new Error(`invalid expression accepted: ${JSON.stringify(expression)} -> ${JSON.stringify(actual)}`);
}
// Locale-aware decimals and existing ASCII/typographic operators.
expect('1,5 + 2,25', '3.75');
expect(',5 + 1,25', '1.75');
expect('1,5 + 2.5', '4');
expect('2×3', '6');
expect('8÷2', '4');
expect('5−7', '-2');
expect('2^-2', '0.25');
expect('2^(1+2)', '8');
expect('2^3^2', '512');
expect('-2^2', '-4');
expect('10/4', '2.5');
expect('8%3', '2');
expect('.5+1.25', '1.75');
expect('1 / 3', '0.333333333333');
expect('0-0', '0');
for (const expr of [
  '1/0', '1/-0', '10%0', 'foo()', '2+', '1..2', '2**2', '',
  '1,2,3', '1e3', 'Infinity', 'NaN', '(2+3', '2+)3', '0^-1',
  '2^10000', '9'.repeat(129)
]) reject(expr);
for (const expr of ['2+2', '2×2', '5−7', '1,5+2']) {
  if (!sandbox.hasOperators(expr) || !sandbox.evaluate(expr))
    throw new Error(`cross-search expression not recognized: ${expr}`);
}
for (const expr of ['42', '1,5']) {
  if (sandbox.hasOperators(expr))
    throw new Error(`bare numeric literal should not qualify as cross-search calculation: ${expr}`);
}
console.log('Launcher calculator arithmetic and edge cases: OK');
NODE
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
launcher = (root / 'components/launcher/Launcher.qml').read_text()
assert 'root.mode === root.modeCalculator &&\n                            (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)' in launcher
assert 'root.copyCalculatorResult(root.calculatorResults[0].result)' in launcher
assert 'case root.modeCalculator:\n\n            if (calculatorList.count > 0)\n                calculatorList.currentIndex = 0' in launcher
assert 'root.copyCalculatorResult(root.calculatorResults[calculatorList.currentIndex].result)' in launcher
# Clipboard content is passed as a positional argument rather than shell-interpolated.
assert 'command: ["sh", "-c", "printf \'%s\' \\"$1\\" | wl-copy", "launcher-calculator-copy", root.calculatorCopyPending]' in launcher
copy_function = launcher[launcher.index('function copyCalculatorResult(value)'):launcher.index('Process {\n        id: calculatorCopyProcess')]
assert 'if (!text || calculatorCopyProcess.running)' in copy_function
assert 'root.hideLauncher()' in copy_function
print('Launcher calculator keyboard activation and safe clipboard routing: OK')
PY

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

node - "$ROOT" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const path = require('path');
const root = process.argv[2];
const file = path.join(root, 'js/launcher/CalculatorHistory.js');
const source = fs.readFileSync(file, 'utf8').split('\n').slice(1).join('\n') + `
this.parseHistory = parseHistory;
this.remember = remember;
this.applyMutations = applyMutations;
this.serialize = serialize;
this.MAX_ENTRIES = MAX_ENTRIES;
`;
const api = {};
vm.runInNewContext(source, api);

const diskEntries = [
  { expression: '1 + 1', result: '2' },
  { expression: '(4 + 2) * 3', result: '18' },
  { expression: '10 / 4', result: '2.5' },
];
const parsed = api.parseHistory(JSON.stringify(diskEntries));
if (parsed.length !== 3 || parsed[0].expression !== '1 + 1') throw new Error('history load/order failed');
if (api.parseHistory('{broken').length !== 0) throw new Error('malformed history must be safe');
if (api.parseHistory(JSON.stringify([{ expression: '', result: '1' }, { expression: '2+2', result: '4' }])).length !== 1) throw new Error('invalid entry filtering failed');

const repeated = api.remember(parsed, { expression: '10 / 4', result: '2.5' });
if (repeated.length !== 3 || repeated[0].expression !== '10 / 4' || repeated[1].expression !== '1 + 1') throw new Error('remember must move duplicate to newest position');
const added = api.remember(repeated, { expression: '6*7', result: '42' });
if (added[0].expression !== '6*7' || added.length !== 4) throw new Error('new calculation not added');

const merged = api.applyMutations(diskEntries, [
  { type: 'clear' },
  { type: 'remember', entry: { expression: '8*8', result: '64' } },
]);
if (merged.length !== 1 || merged[0].expression !== '8*8') throw new Error('startup merge must apply clear then new calculation');
const mergedRemember = api.applyMutations(diskEntries, [
  { type: 'remember', entry: { expression: '3^3', result: '27' } },
]);
if (mergedRemember[0].expression !== '3^3' || mergedRemember.length !== 4) throw new Error('startup merge lost pending calculation');
const roundTrip = api.parseHistory(api.serialize(added));
if (roundTrip.length !== added.length || roundTrip[0].expression !== '6*7') throw new Error('history JSON round trip failed');
const capped = api.parseHistory(JSON.stringify(Array.from({ length: 60 }, (_, i) => ({ expression: `x${i}`, result: String(i) }))));
if (capped.length !== api.MAX_ENTRIES || capped[0].expression !== 'x0') throw new Error('history cap/order failed');
console.log('Calculator history parser, deduplication, bounded storage and startup merge: OK');
NODE

python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
launcher = (root / 'components/launcher/Launcher.qml').read_text()
module = (root / 'js/launcher/CalculatorHistory.js').read_text()
assert 'import "../../js/launcher/CalculatorHistory.js" as CalculatorHistory' in launcher
assert 'property string calculatorHistoryFile: Quickshell.env("HOME") + "/.cache/quickshell-launcher-calculator-history.json"' in launcher
assert '__CALCULATOR_HISTORY_REQUEST__%s' in launcher
assert 'root.acceptCalculatorHistory(this.text)' in launcher
assert 'root.finishCalculatorHistoryWrite(exitCode)' in launcher
assert 'root.persistCalculatorHistory()' in launcher
assert 'root.calculatorHistoryPersistAfterLoad = true' in launcher
assert 'CalculatorHistory.applyMutations(diskEntries, mutations)' in launcher
assert 'loadCalculatorHistoryFromDisk()' in launcher
assert 'root.rememberCalculatorCalculation(acceptedExpression, text)' in launcher
assert 'function buildCalculatorDisplayResults()' in launcher
assert 'return root.calculatorResults' in launcher
assert 'root.calculatorHistoryEntries' in launcher
assert 'root.clearCalculatorHistory()' in launcher
assert 'model: root.calculatorDisplayResults' in launcher
assert 'item.kind === "calculatorHistory"' in launcher
assert 'root.calculatorCopyPending' in launcher
assert 'function applyMutations(entries, mutations)' in module
print('Calculator history UI, serialized persistence and calculation activation wiring: OK')
PY
printf 'launcher calculator history test: OK\n'

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/dashboard/DashboardCards.js'), 'utf8')
  .replace(/^\.pragma library\s*$/gm, '')
  .replace(/^\.import .*$/gm, '');
const context = {};
vm.runInNewContext(source + '\nthis.normalizeRemainingTime = normalizeRemainingTime;', context);
const normalize = value => context.normalizeRemainingTime(value);

for (const [input, expected] of [
  ['-03:47', '03:47'],
  ['-01:00:51', '01:00:51'],
  ['-00:00', '00:00'],
  ['  -00:09  ', '00:09'],
  ['999:59', '999:59'],
  ['123:59:59', '123:59:59'],
  ['0:05', '0:05']
]) {
  assert.strictEqual(normalize(input), expected, `valid Player remaining-time format ${input}`);
}

for (const input of [
  undefined, null, '', '   ', '1:99', '01:60:00', '01:00:60',
  '01:0:00', '1:7', '1000:00', '1:02:03:04', '--01:00',
  '+01:00', '01:00junk', '-00:09\tremaining'
]) {
  assert.strictEqual(normalize(input), '', `invalid Player remaining-time value ${String(input)}`);
}

const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
assert(dashboard.includes('readonly property string mediaRemainingTime: DashboardCards.normalizeRemainingTime(root.playerData.timeleft)'),
  'Dashboard uses the tested normalizer for the existing Player timeleft field');
assert(dashboard.includes('mediaRemainingTime !== ""'),
  'invalid remaining-time metadata stays omitted from the visual and accessibility summaries');
console.log('Dashboard Media remaining-time validation: valid clock formats retained and malformed minute/second values omitted: OK');
NODE
echo 'Dashboard Media remaining-time validation: OK'

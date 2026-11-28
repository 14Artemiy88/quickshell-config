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
vm.runInNewContext(source + '\nthis.normalizeWeatherPressure = normalizeWeatherPressure;', context);
const normalize = value => context.normalizeWeatherPressure(value);

for (const [input, expected] of [
  [760, '760'],
  [760.5, '760.5'],
  ['760', '760'],
  ['760.5', '760.5'],
  ['760,5', '760,5'],
  ['  755.20  ', '755.20'],
  ['.5', '.5'],
  [',5', ',5'],
  ['000760', '000760']
]) {
  assert.strictEqual(normalize(input), expected, `valid pressure ${String(input)}`);
}

for (const input of [
  undefined, null, '', '   ', 0, '0', -1, '-0.1', 'NaN', 'Infinity', '-Infinity',
  '760 mmHg', 'pressure', '1e3', '0x2f8', '+760', '760.', '1,2.3', '1..2',
  true, false, [], [760], {}, { value: 760 }
]) {
  assert.strictEqual(normalize(input), '', `invalid pressure ${String(input)}`);
}

const weatherNow = fs.readFileSync(path.join(root, 'components/WeatherNow.qml'), 'utf8');
assert(weatherNow.includes('DashboardCards.normalizeWeatherPressure(pressure)'),
  'Weather Now uses the shared pressure normalizer');
assert(weatherNow.includes('text: root.normalizedPressure')
    && weatherNow.includes('visible: root.normalizedPressure !== ""'),
  'invalid pressure values are hidden');
assert(weatherNow.includes('text: "MM.PT.CT"\n                        visible: root.normalizedPressure !== ""'),
  'pressure unit is hidden together with an invalid or absent measurement');
assert(!weatherNow.includes('text: root.weather.pressure?.mm_hg_atm ?? ""'),
  'Weather Now no longer renders raw pressure metadata');

const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
assert(dashboard.includes('DashboardCards.normalizeWeatherPressure(pressure)'),
  'Dashboard uses the same pressure normalizer as Weather Now');
assert(!/Number\(textValue\.replace\(",", "\."\)\)/.test(dashboard),
  'Dashboard no longer has a separate permissive pressure coercion path');
console.log('Weather pressure validation: positive decimal values retained, malformed samples and units omitted: OK');
NODE
echo 'Weather pressure metadata validation: OK'

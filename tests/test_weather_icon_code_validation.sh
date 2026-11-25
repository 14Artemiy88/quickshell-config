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
vm.runInNewContext(source + '\nthis.normalizeWeatherIconCode = normalizeWeatherIconCode;', context);
const normalize = value => context.normalizeWeatherIconCode(value);

for (const [input, expected] of [
  ['d_4', 'd_4'], ['n_3', 'n_3'], ['day-cloudy', 'day-cloudy'],
  ['0', '0'], [0, '0'], [4, '4'], ['  d_4  ', 'd_4'], ['A_B-9', 'A_B-9']
]) {
  assert.strictEqual(normalize(input), expected, `valid local weather icon code ${String(input)}`);
}
for (const input of [
  undefined, null, '', ' ', '../d_4', '..', '/etc/passwd', 'd_4/../../x',
  'd\\\\4', '.hidden', '-d_4', '_d_4', 'd_4.png', 'd_4?x', 'd 4',
  'x'.repeat(33), true, false, [], ['d_4'], {}, { code: 'd_4' },
  -1, 1.5, NaN, Infinity, -Infinity
]) {
  assert.strictEqual(normalize(input), '', `unsafe or malformed icon code ${String(input)}`);
}

const dashboardCards = fs.readFileSync(path.join(root, 'js/dashboard/DashboardCards.js'), 'utf8');
assert(dashboardCards.includes('function normalizeWeatherIconCode(value)'), 'shared icon code normalizer is exported from DashboardCards');
const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
const weatherNow = fs.readFileSync(path.join(root, 'components/WeatherNow.qml'), 'utf8');
const forecast = fs.readFileSync(path.join(root, 'components/WeatherForecastItem.qml'), 'utf8');
assert(dashboard.includes('DashboardCards.normalizeWeatherIconCode(root.weatherData && root.weatherData.icon)'),
  'Dashboard uses normalized icon codes before constructing the image source');
assert(weatherNow.includes('DashboardCards.normalizeWeatherIconCode(root.weather && root.weather.icon)'),
  'Weather Now uses the same normalized icon code');
assert(forecast.includes('DashboardCards.normalizeWeatherIconCode(root.entry && root.entry.icon)'),
  'hourly and daily forecasts use the same normalized icon code');
assert(!dashboard.includes('String(root.weatherData.icon) + ".png"'), 'Dashboard no longer concatenates raw API icon data');
assert(!weatherNow.includes('root.weather.icon + ".png"'), 'Weather Now no longer concatenates raw API icon data');
assert(!forecast.includes('(root.entry.icon || "") + ".png"'), 'forecast no longer concatenates raw API icon data');
assert(forecast.includes('Image {\n        id: forecastIconImage'), 'forecast image remains a direct Image element');
assert(forecast.includes('forecastIconImage.status !== Image.Ready') && forecast.includes('text: "☁"'),
  'forecast shows a cloud fallback while its validated image loads or fails');
assert(weatherNow.includes('weatherNowIconImage.status !== Image.Ready') && weatherNow.includes('text: "☁"'),
  'Weather Now shows a cloud fallback while its validated image loads or fails');
console.log('Weather icon code validation: safe filename tokens retained, unsafe paths rejected, all consumers normalized: OK');
NODE
echo 'Weather icon code validation: OK'

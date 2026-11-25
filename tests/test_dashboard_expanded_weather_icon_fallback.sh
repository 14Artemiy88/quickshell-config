#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
const start = dashboard.indexOf('// Weather keeps the current sample intact.');
const end = dashboard.indexOf('// Wide Media lead separates track identity', start);
assert(start >= 0 && end > start, 'expanded Weather block exists');
const weather = dashboard.slice(start, end);
assert(weather.includes('visible: infoCard.expanded && infoCard.cardId === "weather"'),
  'the existing expanded Weather layout remains the owner of this icon');
assert(weather.includes('visible: infoCard.iconSource !== ""'),
  'the icon slot remains hidden when Weather has no icon source');
assert(weather.includes('id: expandedWeatherIcon')
    && weather.includes('source: infoCard.iconSource')
    && weather.includes('anchors.fill: parent')
    && weather.includes('asynchronous: true')
    && weather.includes('cache: true'),
  'the expanded icon keeps its existing source and async cache behavior');
assert(weather.includes('visible: expandedWeatherIcon.status !== Image.Ready')
    && weather.includes('text: "☁"'),
  'the cloud fallback appears for both ordinary and wide expanded Weather while its image is loading or failed');
assert(weather.includes('Layout.preferredWidth: visible ? (infoCard.narrow ? 36 : 42) : 0')
    && weather.includes('Layout.preferredHeight: visible ? (infoCard.narrow ? 36 : 42) : 0'),
  'the existing 36/42 px icon geometry is retained');
assert(weather.includes('columns: infoCard.wideLead ? 2 : 1')
    && weather.includes('Layout.horizontalStretchFactor: infoCard.wideLead ? 42 : 1')
    && weather.includes('Layout.horizontalStretchFactor: infoCard.wideLead ? 58 : 1'),
  'wide column balance and ordinary expanded stacking are unchanged');
assert(!weather.includes('infoCard.wideLead && expandedWeatherIcon.status'),
  'the fallback is not accidentally restricted to wide expanded cards');
assert(weather.includes('text: "Ощущается " + infoCard.comfortText')
    && weather.includes('text: "Давление " + infoCard.pressureText + " мм рт. ст."'),
  'feels-like and pressure metrics remain intact');
assert(!weather.includes('Process {'), 'the icon fallback introduces no process or polling');
console.log('Dashboard expanded Weather icon fallback: shared async placeholder, empty-source handling, geometry and existing metrics: OK');
NODE
echo 'Dashboard expanded Weather icon fallback: OK'

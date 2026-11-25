#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');

const start = dashboard.indexOf('// Compact wide Weather:');
const end = dashboard.indexOf('// Compact wide Media:', start);
assert(start >= 0 && end > start, 'compact wide Weather block exists');
const weather = dashboard.slice(start, end);
assert(weather.includes('!infoCard.expanded && infoCard.wideLead && infoCard.cardId === "weather"'),
  'the fallback remains scoped to compact wide Weather only');
assert(weather.includes('visible: infoCard.iconSource !== ""'),
  'the icon slot stays hidden when Weather is disabled or the source has no icon code');
assert(weather.includes('id: compactWeatherIconImage')
    && weather.includes('source: infoCard.iconSource')
    && weather.includes('asynchronous: true'),
  'the existing weather icon source remains asynchronously loaded');
assert(weather.includes('visible: compactWeatherIconImage.status !== Image.Ready')
    && weather.includes('text: "☁"'),
  'a cloud placeholder covers both loading and failed-image states until the icon is ready');
assert(weather.includes('Layout.preferredWidth: visible ? 38 : 0')
    && weather.includes('Layout.preferredHeight: visible ? 38 : 0')
    && weather.includes('Layout.maximumWidth: visible ? 38 : 0')
    && weather.includes('Layout.maximumHeight: visible ? 38 : 0'),
  'the image and placeholder share a fixed 38 px slot without changing the card geometry');
assert(weather.includes('text: infoCard.primaryText')
    && weather.includes('text: infoCard.secondaryText')
    && weather.includes('text: "Ощущается " + infoCard.comfortText')
    && weather.includes('text: "Давление " + infoCard.pressureText + " мм рт. ст."'),
  'temperature, conditions, feels-like and pressure remain in their established groups');
assert(!weather.includes('Process {'), 'the icon fallback introduces no process or polling');
console.log('Dashboard compact wide Weather icon fallback: loading/error placeholder, hidden empty source, fixed geometry and existing data path: OK');
NODE
echo 'Dashboard compact wide Weather icon fallback: OK'

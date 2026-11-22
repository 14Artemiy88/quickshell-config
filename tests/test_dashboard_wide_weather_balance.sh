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
assert(start >= 0 && end > start, 'expanded Weather content block exists');
const weather = dashboard.slice(start, end);
assert(weather.includes('columns: infoCard.wideLead ? 2 : 1'),
  'wide Weather keeps two top-level groups while ordinary expanded Weather remains stacked');
assert(weather.includes('Layout.horizontalStretchFactor: infoCard.wideLead ? 42 : 1')
    && weather.includes('Layout.horizontalStretchFactor: infoCard.wideLead ? 58 : 1'),
  'wide Weather gives the primary condition group 42% and supporting metrics 58% of the width');
assert(weather.includes('columns: 2'),
  'comfort and wind occupy two balanced subcolumns rather than a single narrow vertical stack');
assert(weather.includes('text: "Ощущается " + infoCard.comfortText')
    && weather.includes('text: "Давление " + infoCard.pressureText + " мм рт. ст."'),
  'feels-like temperature and pressure remain available');
assert(weather.includes('infoCard.windDirection === "Штиль"')
    && weather.includes('"Ветер " + infoCard.windDirection'),
  'wind direction and speed formatting remains unchanged');
assert(weather.includes('Layout.alignment: infoCard.wideLead ? Qt.AlignVCenter : Qt.AlignTop'),
  'wide groups remain vertically balanced without changing ordinary top alignment');
assert(dashboard.includes('details.push("Атмосферное давление " + pressure + " миллиметров ртутного столба")'),
  'screen-reader weather details remain intact');
console.log('Dashboard wide Weather: 42/58 grouping, two supporting metrics, all data and accessibility preserved: OK');
NODE
echo 'Dashboard wide Weather balance: OK'

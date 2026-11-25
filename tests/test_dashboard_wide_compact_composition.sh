#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
const cards = fs.readFileSync(path.join(root, 'js/dashboard/DashboardCards.js'), 'utf8');

function block(startMarker, endMarker, description) {
  const start = dashboard.indexOf(startMarker);
  const end = dashboard.indexOf(endMarker, start + startMarker.length);
  assert(start >= 0 && end > start, `${description} block is present`);
  return dashboard.slice(start, end);
}

const ordinaryCompact = block(
  '// Ordinary compact cards keep their original stacked summary.',
  '// Compact wide System:',
  'ordinary compact fallback'
);
assert(ordinaryCompact.includes('!infoCard.expanded && !infoCard.wideLead && infoCard.cardId !== "today"'),
  'the original stacked summary remains exclusive to non-wide compact cards');

const system = block('// Compact wide System:', '// Compact wide Network:', 'compact wide System');
assert(system.includes('!infoCard.expanded && infoCard.wideLead && infoCard.cardId === "system"'),
  'System compact composition is used only for a compact wide lead');
assert(system.includes('label: "CPU"') && system.includes('label: "RAM"')
    && (system.match(/dense: true/g) || []).length === 2,
  'CPU and RAM use balanced compact meters');
assert(system.includes('infoCard.cpuCoreCount') && system.includes('infoCard.cpuCorePeak')
    && system.includes('infoCard.ramCapacityText'),
  'the compact System lead uses the existing CPU core and RAM capacity sample');
assert(system.includes('infoCard.topResourceAppName') && system.includes('Layout.columnSpan: 2'),
  'the existing leading resource application can span both columns');

const network = block('// Compact wide Network:', '// Compact wide Weather:', 'compact wide Network');
assert(network.includes('!infoCard.expanded && infoCard.wideLead && infoCard.cardId === "network"'),
  'Network compact composition is used only for a compact wide lead');
assert(network.includes('ЗАГРУЗКА ↓') && network.includes('ОТДАЧА ↑')
    && network.includes('Всего · " + infoCard.detailPrimaryText')
    && network.includes('Всего · " + infoCard.detailSecondaryText'),
  'download and upload rates are paired with their accumulated totals');
assert(network.includes('infoCard.networkConnectionHeading')
    && network.includes('infoCard.networkConnectionDetails'),
  'active connection details remain optional and share the full-width row');

const weather = block('// Compact wide Weather:', '// Compact wide Media:', 'compact wide Weather');
assert(weather.includes('!infoCard.expanded && infoCard.wideLead && infoCard.cardId === "weather"'),
  'Weather compact composition is used only for a compact wide lead');
assert(weather.includes('Layout.horizontalStretchFactor: 42')
    && weather.includes('Layout.horizontalStretchFactor: 58'),
  'Weather retains its balanced 42/58 primary/supporting split');
assert(weather.includes('source: infoCard.iconSource')
    && weather.includes('infoCard.primaryText') && weather.includes('infoCard.secondaryText')
    && weather.includes('infoCard.comfortText') && weather.includes('infoCard.windDirection')
    && weather.includes('infoCard.pressureText'),
  'Weather reuses the current icon, condition and supporting metrics');

const media = block('// Compact wide Media:', '// Wide System lead:', 'compact wide Media');
assert(media.includes('!infoCard.expanded && infoCard.wideLead && infoCard.cardId === "media"'),
  'Media compact composition is used only for a compact wide lead');
assert(media.includes('Layout.horizontalStretchFactor: 56')
    && media.includes('Layout.horizontalStretchFactor: 44'),
  'Media gives track identity more width than album/progress details');
assert(media.includes('infoCard.primaryText') && media.includes('infoCard.secondaryText')
    && media.includes('infoCard.tertiaryText') && media.includes('infoCard.mediaProgressPercent')
    && media.includes('infoCard.mediaRemainingTime'),
  'Media reuses the current track metadata and bounded progress fields');

assert(dashboard.includes('if ((infoCard.expanded || infoCard.wideLead) && infoCard.ramCapacityAccessibleText !== "")')
    && dashboard.includes('if (infoCard.expanded || infoCard.wideLead) {\n                        if (infoCard.networkConnectionAccessibleText !== "")')
    && dashboard.includes('if (infoCard.expanded || infoCard.wideLead) {\n                        if (String(infoCard.comfortText || "").trim() !== "")')
    && dashboard.includes('if ((infoCard.expanded || infoCard.wideLead) && infoCard.mediaProgressPercent >= 0)'),
  'screen-reader descriptions include the additional data visible in compact wide leads');
assert(dashboard.includes('infoCard.expanded && infoCard.cardId === "system" && infoCard.wideLead')
    && dashboard.includes('infoCard.expanded && infoCard.cardId === "network"')
    && dashboard.includes('infoCard.expanded && infoCard.cardId === "weather"')
    && dashboard.includes('infoCard.expanded && infoCard.cardId === "media"'),
  'existing expanded and non-wide compositions remain separate');
assert(cards.includes('var COMPACT_CARD_HEIGHTS') && cards.includes('var EXPANDED_CARD_HEIGHTS'),
  'shared compact/expanded card silhouettes remain defined and unchanged');
assert(!dashboard.includes('Process {'), 'compact wide cards do not add independent polling processes');
console.log('Dashboard compact wide-lead composition: System, Network, Weather, Media, accessibility and fallback contracts: OK');
NODE
echo 'Dashboard compact wide composition: OK'

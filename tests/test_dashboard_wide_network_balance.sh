#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');

const start = dashboard.indexOf('// Network expansion shows both live rate and accumulated transfer totals.');
const end = dashboard.indexOf('// Weather keeps the current sample intact', start);
assert(start >= 0 && end > start, 'Network content block exists');
const network = dashboard.slice(start, end);
assert(network.includes('spacing: infoCard.wideLead ? DashboardCards.WIDE_LEAD_GROUP_GAP : 12'),
  'wide Network direction groups use the shared wide-lead gutter');
assert.strictEqual((network.match(/spacing: infoCard\.wideLead \? 6 : 4/g) || []).length, 2,
  'download and upload groups retain balanced internal spacing');
assert(network.includes('infoCard.primaryText.replace("↓", "").trim()')
    && network.includes('infoCard.secondaryText.replace("↑", "").trim()'),
  'live download and upload rates remain independently represented');
assert(network.includes('infoCard.wideLead ? "Всего · " + infoCard.detailPrimaryText : infoCard.detailPrimaryText')
    && network.includes('infoCard.wideLead ? "Всего · " + infoCard.detailSecondaryText : infoCard.detailSecondaryText'),
  'wide download and upload groups explicitly label their accumulated transfer totals');
assert(dashboard.includes('readonly property string networkConnectionHeading:')
    && dashboard.includes('readonly property string networkConnectionDetails:'),
  'the connection summary is separated into a heading and a names/devices line');
const connectionStart = dashboard.indexOf('// The wide lead gives active connection details their own full-width');
const connectionEnd = dashboard.indexOf('// Weather keeps the current sample intact', connectionStart);
const connection = dashboard.slice(connectionStart, connectionEnd);
assert(connection.includes('infoCard.wideLead && infoCard.networkConnectionText !== ""'),
  'the dedicated connection section is shown only when a wide lead has active connections');
assert(connection.includes('text: infoCard.networkConnectionHeading.toUpperCase()')
    && connection.includes('text: infoCard.networkConnectionDetails'),
  'connection heading and connection names/devices have separate visual roles');
assert(connection.includes('Layout.fillWidth: true')
    && connection.includes('wrapMode: Text.WrapAtWordBoundaryOrAnywhere')
    && connection.includes('maximumLineCount: 2')
    && connection.includes('textFormat: Text.PlainText'),
  'the full-width connection details safely wrap long profile/device names');
assert(connection.includes('!infoCard.wideLead && infoCard.networkConnectionText !== ""')
    && connection.includes('text: infoCard.networkConnectionText'),
  'ordinary non-wide Network cards retain their previous combined connection summary');
assert(dashboard.includes('networkConnectionAccessibleText')
    && dashboard.includes('details.push(infoCard.networkConnectionAccessibleText)'),
  'screen-reader connection description remains sourced from the full active-connection model');
assert(!dashboard.includes('Process {'), 'Dashboard does not add a polling process for network details');
console.log('Dashboard wide Network: paired live rates, labelled transfer totals, full-width active connections and non-wide fallback: OK');
NODE
echo 'Dashboard wide Network balance: OK'

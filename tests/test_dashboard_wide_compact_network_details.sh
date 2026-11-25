#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');

const start = dashboard.indexOf('// Compact wide Network:');
const end = dashboard.indexOf('// Compact wide Weather:', start);
assert(start >= 0 && end > start, 'compact wide Network block exists');
const network = dashboard.slice(start, end);
assert(network.includes('!infoCard.expanded && infoCard.wideLead && infoCard.cardId === "network"'),
  'the compact wide Network composition remains isolated from ordinary and expanded cards');
assert(network.includes('Layout.columnSpan: 2'),
  'active connection details use the full width below both transfer columns');
assert(network.includes('text: infoCard.networkConnectionHeading.toUpperCase()'),
  'the connection count/state has its own concise heading');
assert(network.includes('text: infoCard.networkConnectionDetails'),
  'the active profile/device names remain a separate detail line');
assert(network.includes('wrapMode: Text.WrapAtWordBoundaryOrAnywhere')
    && network.includes('maximumLineCount: 2')
    && network.includes('elide: Text.ElideRight')
    && network.includes('textFormat: Text.PlainText'),
  'long names wrap across up to two safe plain-text lines before being elided');
assert(network.includes('Layout.preferredHeight: 1') && network.includes('spacing: 3'),
  'the details section is visually separated without adding a large vertical gap');
assert(dashboard.includes('if (infoCard.expanded || infoCard.wideLead) {')
    && dashboard.includes('if (infoCard.networkConnectionAccessibleText !== "")'),
  'screen readers continue to receive the complete active connection description');
assert(dashboard.includes('!infoCard.wideLead && infoCard.networkConnectionText !== ""'),
  'the ordinary compact and expanded non-wide cards retain their existing connection presentation');
assert(!dashboard.includes('Process {'),
  'the compact details reuse the existing NetworkManager sample without another process');
console.log('Dashboard compact wide Network details: two-line profile/device wrapping, full-width heading and accessibility: OK');
NODE
echo 'Dashboard compact wide Network details: OK'

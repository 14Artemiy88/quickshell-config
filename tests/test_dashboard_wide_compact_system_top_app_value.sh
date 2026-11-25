#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');

const start = dashboard.indexOf('// Compact wide System:');
const end = dashboard.indexOf('// Compact wide Network:', start);
assert(start >= 0 && end > start, 'compact wide System block exists');
const system = dashboard.slice(start, end);

assert(system.includes('visible: !infoCard.expanded && infoCard.wideLead && infoCard.cardId === "system"'),
  'the updated top-resource row remains exclusive to compact wide System');
assert(system.includes('RowLayout {\n                    visible: infoCard.topResourceAppText !== ""'),
  'the top application summary uses independent layout slots');
assert(system.includes('text: infoCard.topResourceAppLabel + " ·"'),
  'the resource category remains independently visible');
assert(system.includes('text: infoCard.topResourceAppName')
    && system.includes('Layout.minimumWidth: 0')
    && system.includes('elide: Text.ElideRight'),
  'only the potentially long application name is allowed to elide');
assert(system.includes('visible: infoCard.topResourceAppProcessCount !== ""')
    && system.includes('text: infoCard.topResourceAppProcessCount'),
  'process-group count remains a separate optional slot');
assert(system.includes('visible: infoCard.topResourceAppValue !== ""')
    && system.includes('text: infoCard.topResourceAppValue'),
  'CPU percentage or RAM amount/share is protected from name elision');
assert(!system.includes('text: infoCard.topResourceAppLabel + " · " + infoCard.topResourceAppName'),
  'the full summary is no longer flattened into one right-eliding text item');

const accessibleStart = dashboard.indexOf('function accessibleDetails()');
const accessibleEnd = dashboard.indexOf('onActiveFocusChanged:', accessibleStart);
assert(accessibleStart >= 0 && accessibleEnd > accessibleStart, 'InfoCard accessibility description exists');
const accessible = dashboard.slice(accessibleStart, accessibleEnd);
assert(accessible.includes('infoCard.topResourceAppAccessibleText !== ""')
    && accessible.includes('details.push(infoCard.topResourceAppAccessibleText)'),
  'screen readers retain the complete top-resource application description');
assert(!dashboard.includes('Process {'), 'the display change adds no independent polling process');
console.log('Dashboard compact wide System top-resource row: value protected from long app-name elision: OK');
NODE
echo 'Dashboard wide compact System top application value: OK'

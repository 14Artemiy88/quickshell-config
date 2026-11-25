#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');

const systemStart = dashboard.indexOf('// Compact wide System:');
const systemEnd = dashboard.indexOf('// Compact wide Network:', systemStart);
assert(systemStart >= 0 && systemEnd > systemStart, 'compact wide System block exists');
const system = dashboard.slice(systemStart, systemEnd);

assert(system.includes('visible: !infoCard.expanded && infoCard.wideLead && infoCard.cardId === "system"'),
  'the denser System composition is restricted to compact wide leads');
assert.strictEqual((system.match(/UsageMeter \{/g) || []).length, 2,
  'CPU and RAM remain separate primary resource meters');
assert(system.includes('visible: infoCard.cpuLoadAverageText !== ""')
    && system.includes('text: infoCard.cpuLoadAverageText'),
  'CPU load averages are shown only when the shared sampler supplies a valid value');
assert(system.includes('visible: infoCard.swapCapacityText !== ""')
    && system.includes('text: "Подкачка · " + infoCard.swapCapacityText'),
  'swap capacity is shown only when the shared sampler supplies a valid value');
assert(system.includes('infoCard.cpuCoreCount > 0')
    && system.includes('infoCard.ramCapacityText !== ""'),
  'existing CPU core and RAM capacity details remain in their respective columns');
assert(system.includes('" · пик " + infoCard.cpuCorePeak + "%"')
    && system.includes('infoCard.cpuCorePeakId !== "" ? " · " + infoCard.cpuCorePeakId : ""'),
  'compact wide System shows the hottest logical CPU id when the shared sampler provides a verified id');
assert(system.includes('infoCard.cpuCorePeak >= 0'),
  'the hottest-core label remains hidden while the peak value is unavailable');
assert.strictEqual((system.match(/maximumLineCount: 1/g) || []).length, 8,
  'compact support metrics and independently protected top-app fields remain single-line and bounded');

const accessibleStart = dashboard.indexOf('function accessibleDetails()');
const accessibleEnd = dashboard.indexOf('onActiveFocusChanged:', accessibleStart);
assert(accessibleStart >= 0 && accessibleEnd > accessibleStart, 'InfoCard accessible description exists');
const accessible = dashboard.slice(accessibleStart, accessibleEnd);
assert(accessible.includes('(infoCard.expanded || infoCard.wideLead) && infoCard.swapCapacityAccessibleText !== ""')
    && accessible.includes('details.push(infoCard.swapCapacityAccessibleText)'),
  'screen readers announce swap capacity in expanded cards and compact wide leads');
assert(accessible.includes('(infoCard.expanded || infoCard.wideLead) && infoCard.cpuLoadAverageAccessibleText !== ""')
    && accessible.includes('details.push(infoCard.cpuLoadAverageAccessibleText)'),
  'screen readers announce 1/5/15-minute load averages in expanded cards and compact wide leads');
assert(accessible.includes('if (infoCard.expanded && infoCard.swapCapacityAccessibleText !== "")') === false
    && accessible.includes('if (infoCard.expanded && infoCard.cpuLoadAverageAccessibleText !== "")') === false,
  'compact wide accessibility is not accidentally excluded by expanded-only guards');
assert(!dashboard.includes('Process {'), 'the detail expansion adds no polling process');
console.log('Dashboard compact wide System: CPU load average, RAM swap, unavailable-value guards and accessibility: OK');
NODE
echo 'Dashboard wide compact System details: OK'

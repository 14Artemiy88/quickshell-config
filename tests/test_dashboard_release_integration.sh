#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];

function loadLibrary(relativePath) {
  const source = fs.readFileSync(path.join(root, relativePath), 'utf8')
    .replace(/^\s*\.pragma library\s*/m, '');
  const context = {};
  vm.runInNewContext(source, context, { filename: relativePath });
  return context;
}

const dashboard = loadLibrary('js/dashboard/DashboardCards.js');
const resets = loadLibrary('js/settings/SettingsResets.js');
const persistence = loadLibrary('js/settings/SettingsPersistence.js');
const qml = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
const configQml = fs.readFileSync(path.join(root, 'Config.qml'), 'utf8');
const defaultsJs = fs.readFileSync(path.join(root, 'js/settings/SettingsDefaults.js'), 'utf8');
const checkScript = fs.readFileSync(path.join(root, 'CHECK.sh'), 'utf8');
const expectedIds = ['today', 'system', 'network', 'weather', 'media'];
const asArray = value => Array.from(value);
const idsOf = cards => asArray(cards).map(card => card.id);

assert.deepStrictEqual(asArray(dashboard.DEFAULT_IDS), expectedIds,
  'Dashboard runtime IDs must stay in the documented canonical order');
assert.deepStrictEqual(idsOf(dashboard.DEFINITIONS), expectedIds,
  'every canonical card must have exactly one runtime definition');
assert.match(configQml, /property var dashboardVisibleCards: \["today", "system", "network", "weather", "media"\]/,
  'Config defaults must match the five runtime cards');
assert.match(configQml, /property var dashboardCardOrder: \["today", "system", "network", "weather", "media"\]/,
  'Config default order must match the runtime order');
assert.match(defaultsJs, /dashboardVisibleCards: \["today", "system", "network", "weather", "media"\]/,
  'settings defaults must match the Config visibility default');
assert.match(defaultsJs, /dashboardCardOrder: \["today", "system", "network", "weather", "media"\]/,
  'settings defaults must match the Config card order');

for (const id of expectedIds) {
  assert.ok(dashboard.DEFINITIONS.find(card => card.id === id),
    `${id} must have a presentation definition`);
  assert.ok(!dashboard.DEFINITIONS.find(card => card.id === id).settingsPageId,
    `${id} must stay an informational card without a Settings click destination`);
  assert.ok(qml.includes(`infoCard.cardId === "${id}"`),
    `${id} must have a corresponding Dashboard content renderer`);
}

// A current profile can intentionally disable Today; legacy migration only
// restores it when the stored card order also proves the profile is old.
const currentOrder = expectedIds.slice();
const visibleWithoutToday = asArray(dashboard.setEnabled(expectedIds, 'today', false));
assert.deepStrictEqual(visibleWithoutToday, expectedIds.slice(1));
assert.deepStrictEqual(asArray(dashboard.normalize(visibleWithoutToday)), expectedIds.slice(1));
assert.deepStrictEqual(asArray(resets.normalizeDashboardCards(visibleWithoutToday, currentOrder)), expectedIds.slice(1));
assert.deepStrictEqual(asArray(persistence.normalizeDashboardCards(visibleWithoutToday, currentOrder)), expectedIds.slice(1));
const legacyVisible = ['system', 'network', 'weather', 'media'];
assert.deepStrictEqual(asArray(resets.normalizeDashboardCards(legacyVisible, legacyVisible)), expectedIds,
  'settings reset migration must restore Today for the old four-card profile');
assert.deepStrictEqual(asArray(persistence.normalizeDashboardCards(legacyVisible, legacyVisible)), expectedIds,
  'settings persistence migration must restore Today for the old four-card profile');

// Integration matrix: every visibility subset, both canonical/reversed order,
// all size patterns, all column modes and widths around the real breakpoints.
const widths = [469, 470, 499, 500, 524];
const modes = ['auto', 'one', 'two'];
const sizePatterns = [
  {},
  { today: 'expanded', system: 'compact', network: 'expanded', weather: 'compact', media: 'expanded' },
  { today: 'compact', system: 'expanded', network: 'compact', weather: 'expanded', media: 'compact' }
];
let scenarios = 0;
for (let mask = 0; mask < (1 << expectedIds.length); mask++) {
  const visible = expectedIds.filter((_, index) => (mask & (1 << index)) !== 0);
  for (const order of [expectedIds, expectedIds.slice().reverse()]) {
    const ordered = dashboard.orderedVisible(order, visible);
    assert.deepStrictEqual(idsOf(ordered), order.filter(id => visible.includes(id)),
      'visible card order must follow the configured order');
    for (const sizes of sizePatterns) {
      for (const mode of modes) {
        for (const width of widths) {
          const layout = dashboard.resolveDashboardLayout(ordered, mode, width, sizes, dashboard.COLUMN_GAP);
          let activeIds = [];
          if (layout.kind === 'wide-lead-horizontal') {
            const peerColumns = dashboard.wideLeadPeerColumns(layout.peers, sizes, dashboard.COLUMN_GAP);
            activeIds = [...idsOf(layout.lead), ...idsOf(peerColumns.left), ...idsOf(peerColumns.right)];
            assert.deepStrictEqual(idsOf(layout.lead), [ordered[0].id],
              'the first configured card must remain the wide lead');
          } else {
            activeIds = [...idsOf(layout.left), ...idsOf(layout.right)];
            assert.deepStrictEqual(idsOf(layout.lead), [], 'inactive lead model must stay empty');
            assert.deepStrictEqual(idsOf(layout.peers), [], 'inactive peers model must stay empty');
          }
          assert.strictEqual(new Set(activeIds).size, activeIds.length,
            'no card may be assigned to more than one active layout model');
          assert.deepStrictEqual(activeIds.slice().sort(), visible.slice().sort(),
            'every visible card must be assigned exactly once and hidden cards must stay absent');
          scenarios++;
        }
      }
    }
  }
}
assert.ok(scenarios > 0, 'the Dashboard integration matrix must execute');
assert.ok(!qml.includes('ScrollBar.vertical:'), 'the visual vertical scrollbar must remain absent');
assert.ok(!qml.includes('ScrollBar.horizontal:'), 'the visual horizontal scrollbar must remain absent');
assert.ok(qml.includes('DashboardCards.wheelScrollPosition('), 'wheel/touchpad scrolling must remain wired');
assert.ok(checkScript.includes('tests/test_dashboard_release_integration.sh'),
  'the integration audit must be registered in CHECK.sh');
console.log(`Dashboard release integration: PASS (${scenarios} layout/configuration scenarios)`);
NODE

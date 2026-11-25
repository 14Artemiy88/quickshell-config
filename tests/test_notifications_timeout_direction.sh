#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
config = (root / "Config.qml").read_text(encoding="utf-8")
defaults = (root / "js/settings/SettingsDefaults.js").read_text(encoding="utf-8")
persistence = (root / "js/settings/SettingsPersistence.js").read_text(encoding="utf-8")
apply_core = (root / "js/settings/SettingsApplyCore.js").read_text(encoding="utf-8")
schema = (root / "js/settings/SettingsSchema.js").read_text(encoding="utf-8")
resets = (root / "js/settings/SettingsResets.js").read_text(encoding="utf-8")
nav = (root / "components/settings/SettingsNavigationController.qml").read_text(encoding="utf-8")
ui = (root / "components/settings/sections/SettingsNotificationsSection.qml").read_text(encoding="utf-8")
qml = (root / "components/notifications/Notifications.qml").read_text(encoding="utf-8")
helper = (root / "js/notifications/NotificationTimeout.js").read_text(encoding="utf-8")
assert 'property string notificationsTimeoutIndicatorDirection: "clockwise"' in config
assert 'notificationsTimeoutIndicatorDirection: "clockwise"' in defaults
assert 'notificationsTimeoutIndicatorDirection: config.notificationsTimeoutIndicatorDirection' in persistence
assert 'Config.notificationsTimeoutIndicatorDirection = String(o.notificationsTimeoutIndicatorDirection) === "counterclockwise"' in apply_core
assert 'notificationsTimeoutIndicatorDirection: config.notificationsTimeoutIndicatorDirection' in persistence
assert 'notificationsTimeoutIndicatorDirection' in nav
assert 'notificationsTimeoutIndicatorDirection' in resets
assert 'notificationsTimeoutIndicatorDirection' in schema
assert 'settingsSearchId: "notifications-timeout-indicator-direction"' in ui
assert 'model: ["По часовой стрелке", "Против часовой стрелки"]' in ui
assert 'visible: Config.notificationsTimeoutIndicatorStyle === "border"' in ui
assert 'progressDirection: Config.notificationsTimeoutIndicatorDirection || "clockwise"' in qml
assert qml.count('countdownProgress, 1, progressDirection') == 1
assert 'String(direction || "clockwise") === "counterclockwise"' in helper
print("notification timeout direction setting, search, persistence, migration and Canvas wiring: OK")
PY
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(root + '/js/notifications/NotificationTimeout.js', 'utf8').replace(/^\.pragma library\s*/m, '');
const context = {};
vm.createContext(context);
vm.runInContext(source + '\nthis.points = roundedPerimeterPoints;', context);
const clockwise = context.points(400, 180, 18, 0.12, 1, 'clockwise');
const counter = context.points(400, 180, 18, 0.12, 1, 'counterclockwise');
assert(clockwise.length > 1 && counter.length > 1, 'both directions need a visible segment');
assert(Math.abs(clockwise[0].x - counter[0].x) < 1e-9 && Math.abs(clockwise[0].y - counter[0].y) < 1e-9, 'both directions start at the same anchor');
assert(clockwise[1].x > clockwise[0].x && Math.abs(clockwise[1].y - clockwise[0].y) < 1e-9, 'clockwise path starts along the top edge');
assert(counter[1].x < counter[0].x && counter[1].y > counter[0].y, 'counterclockwise path starts around the top-left corner');
for (const direction of ['clockwise', 'counterclockwise']) {
  const empty = context.points(400, 180, 18, 0, 1, direction);
  const half = context.points(400, 180, 18, 0.5, 1, direction);
  const full = context.points(400, 180, 18, 1, 1, direction);
  assert.strictEqual(empty.length, 1, `${direction}: zero progress remains empty`);
  assert(half.length > 10 && full.length > 20, `${direction}: corners are smoothly sampled`);
  const length = points => points.slice(1).reduce((sum, p, i) => sum + Math.hypot(p.x-points[i].x, p.y-points[i].y), 0);
  assert(Math.abs(length(half) / length(full) - 0.5) < 0.02, `${direction}: half progress covers half the perimeter`);
  assert(Math.hypot(full[0].x-full[full.length-1].x, full[0].y-full[full.length-1].y) < 0.001, `${direction}: full path closes`);
}
const schemaSource = fs.readFileSync(root + '/js/settings/SettingsSchema.js', 'utf8').replace(/^\.pragma library\s*/m, '');
const schemaContext = {};
vm.createContext(schemaContext);
vm.runInContext(schemaSource + '\nthis.normalizeProfileForTest = normalizeProfile;', schemaContext);
assert.strictEqual(schemaContext.normalizeProfileForTest({notificationsTimeoutIndicatorStyle:'border'}, false).notificationsTimeoutIndicatorDirection, 'clockwise', 'legacy full profiles keep old clockwise direction');
assert.strictEqual(schemaContext.normalizeProfileForTest({notificationsTimeoutIndicatorDirection:'counterclockwise'}, true).notificationsTimeoutIndicatorDirection, 'counterclockwise', 'sparse profiles preserve selected direction');
assert(!Object.prototype.hasOwnProperty.call(schemaContext.normalizeProfileForTest({notificationsTimeoutIndicatorDirection:'sideways'}, true), 'notificationsTimeoutIndicatorDirection'), 'invalid sparse direction is discarded');
assert.strictEqual(schemaContext.normalizeProfileForTest({notificationsTimeoutIndicatorDirection:'sideways'}, false).notificationsTimeoutIndicatorDirection, 'clockwise', 'invalid full profile direction falls back safely');
console.log('timeout frame clockwise/counterclockwise geometry and profile migration: PASS');
JS

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1])
qml=(root/'components/notifications/Notifications.qml').read_text(encoding='utf-8')
ui=(root/'components/settings/sections/SettingsNotificationsSection.qml').read_text(encoding='utf-8')
nav=(root/'components/settings/SettingsNavigationController.qml').read_text(encoding='utf-8')
config=(root/'Config.qml').read_text(encoding='utf-8')
defaults=(root/'js/settings/SettingsDefaults.js').read_text(encoding='utf-8')
persistence=(root/'js/settings/SettingsPersistence.js').read_text(encoding='utf-8')
resets=(root/'js/settings/SettingsResets.js').read_text(encoding='utf-8')
assert 'property string notificationsTimeoutIndicatorColor: ""' in config
assert 'property string notificationsTimeoutIndicatorStyle: "bar"' in config
assert 'notificationsTimeoutIndicatorColor: ""' in defaults and 'notificationsTimeoutIndicatorStyle: "bar"' in defaults
assert 'notificationsTimeoutIndicatorColor: config.notificationsTimeoutIndicatorColor' in persistence
assert 'notificationsTimeoutIndicatorStyle: config.notificationsTimeoutIndicatorStyle' in persistence
assert 'notificationsTimeoutIndicatorDirection: config.notificationsTimeoutIndicatorDirection' in persistence
assert resets.count('"notificationsTimeoutIndicatorColor"') >= 2
assert resets.count('"notificationsTimeoutIndicatorStyle"') >= 2
assert 'notificationsTimeoutIndicatorColor' in nav and 'notificationsTimeoutIndicatorStyle' in nav and 'notificationsTimeoutIndicatorDirection' in nav
assert 'settingsSearchId: "notifications-timeout-indicator-color"' in ui
assert 'settingsSearchId: "notifications-timeout-indicator-style"' in ui
assert 'Config.notificationsTimeoutIndicatorStyle = index === 1 ? "border" : "bar"' in ui
assert 'Config.notificationsTimeoutIndicatorColor' in ui
assert 'timeoutIndicatorResolvedColor' in qml and 'Config.accent' in qml
assert 'id: timeoutFrameIndicator' in qml and 'Canvas {' in qml
assert 'NotificationTimeout.roundedPerimeterPoints' in qml
assert 'progressDirection: Config.notificationsTimeoutIndicatorDirection' in qml
assert 'ctx.lineCap = "round"' in qml and 'ctx.lineJoin = "round"' in qml
assert 'String(Config.notificationsTimeoutIndicatorStyle || "bar") === "border"' in qml
assert 'String(Config.notificationsTimeoutIndicatorStyle || "bar") !== "border"' in qml
print('notification timeout color/style settings and rounded perimeter Canvas wiring: OK')
PY
node - "$ROOT/js/notifications/NotificationTimeout.js" <<'JS'
const fs = require('fs');
const vm = require('vm');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/m, '');
const context = {};
vm.createContext(context);
vm.runInContext(source + '\nthis.points = roundedPerimeterPoints;', context);
function length(points) {
  let total=0;
  for(let i=1;i<points.length;i++) total += Math.hypot(points[i].x-points[i-1].x, points[i].y-points[i-1].y);
  return total;
}
const empty=context.points(400,180,18,0,1);
const half=context.points(400,180,18,.5,1);
const full=context.points(400,180,18,1,1);
if (empty.length !== 1) throw new Error('zero fraction must not draw a segment');
if (half.length < 10 || full.length < 20) throw new Error('perimeter points need smooth rounded corners');
const fullLength=length(full), halfLength=length(half);
if (Math.abs(halfLength/fullLength-.5) > .015) throw new Error(`half perimeter is not half length: ${halfLength/fullLength}`);
if (Math.hypot(full[0].x-full[full.length-1].x, full[0].y-full[full.length-1].y) > .001) throw new Error('full perimeter must close at its start point');
for (const p of full) if (p.x < 0 || p.y < 0 || p.x > 400 || p.y > 180) throw new Error('perimeter point outside the card');
const short=context.points(20,10,12,.7,1);
for (const p of short) if (!Number.isFinite(p.x) || !Number.isFinite(p.y)) throw new Error('small geometry generated invalid coordinates');
console.log('rounded timeout perimeter geometry: zero/half/full/small-card cases PASS');
JS

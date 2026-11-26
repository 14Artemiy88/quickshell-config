#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const dashboard = fs.readFileSync(path.join(root, 'components/Dashboard.qml'), 'utf8');
const notifications = fs.readFileSync(path.join(root, 'components/notifications/Notifications.qml'), 'utf8');
const config = fs.readFileSync(path.join(root, 'Config.qml'), 'utf8');

assert.match(dashboard, /function toggleNotificationsDoNotDisturb\(\)[\s\S]*?if \(!Settings\.notifications\)[\s\S]*?Config\.notificationsDoNotDisturb = !Config\.notificationsDoNotDisturb[\s\S]*?Settings\.save\(\)/,
  'Dashboard toggles the existing persisted DND setting and refuses changes when Notifications is disabled');
assert.match(dashboard, /id: notificationsDndButton[\s\S]*?enabled: Settings\.notifications[\s\S]*?Accessible\.role: Accessible\.Button/,
  'the DND control is disabled when the Notifications module is unavailable and remains accessible');
assert.match(dashboard, /Accessible\.name: Config\.notificationsDoNotDisturb \? "Выключить режим Не беспокоить" : "Включить режим Не беспокоить"/,
  'the accessible name describes the action for the current DND state');
assert.match(dashboard, /color: !enabled \? \"transparent\"[\s\S]*?dndVisualActive[\s\S]*?\? Config\.accent[\s\S]*?: \"transparent\"/,
  'the DND control uses a filled accent background only when DND is enabled');
assert.match(dashboard, /border\.width: activeFocus \? 2/,
  'keyboard focus is indicated independently by an outline');
assert.match(dashboard, /color: notificationsDndButton\.dndVisualActive[\s\S]*?Config\.black : \(notificationsDndButton\.activeFocus \? Config\.accent/,
  'the DND label contrasts with the filled active background while focus remains separate');
assert.match(dashboard, /function onNotificationsDoNotDisturbChanged\(\)[\s\S]*?notificationsDndButton\.dndVisualActive = Config\.notificationsDoNotDisturb/,
  'the DND button mirrors Config changes immediately instead of waiting for the Dashboard to close');
assert.match(dashboard, /MouseArea \{[\s\S]*?id: dndMouse[\s\S]*?root\.toggleNotificationsDoNotDisturb\(\)/,
  'pointer activation uses the same DND toggle path');
assert.match(dashboard, /Keys\.onPressed: function\(event\)[\s\S]*?root\.toggleNotificationsDoNotDisturb\(\)/,
  'keyboard activation uses the same DND toggle path');
assert.match(notifications, /Config\.notificationsDoNotDisturb/,
  'Dashboard does not introduce a second DND state; the Notifications server consumes Config');
assert.match(config, /property bool notificationsDoNotDisturb: false/,
  'the existing Config property remains the single source of truth');
console.log('Dashboard DND control, persistence, accessibility and shared Notifications state: OK');
NODE

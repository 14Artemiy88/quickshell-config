#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const assert = require('assert');
const root = process.argv[2];
const shell = fs.readFileSync(root + '/shell.qml', 'utf8');
const qml = fs.readFileSync(root + '/components/notifications/Notifications.qml', 'utf8');
const settings = fs.readFileSync(root + '/components/settings/sections/SettingsNotificationsSection.qml', 'utf8');
const readme = fs.readFileSync(root + '/README.md', 'utf8');
assert(/Loader\s*\{\s*id: notificationsModuleLoader\s*active: Settings\.loaded/.test(shell), 'NotificationServer QML bridge remains active for the shell process after settings load');
assert(shell.includes('process-wide C++ singleton') && shell.includes('cannot hand the D-Bus name to another daemon at runtime'), 'shell documents the distinction between QML Loader and D-Bus process lifetime');
assert(qml.includes('keepOnReload: true'), 'tracked notifications are retained across shell reloads');
assert(qml.includes('readonly property bool notificationsModuleEnabled: Settings.notifications === true'), 'module toggle gates the notification UI independently of server lifetime');
assert(qml.includes('notificationSurfaceActive: notificationsModuleEnabled'), 'disabled module hides the popup surface');
assert(qml.includes('function acceptNotification(notification)') && qml.includes('if (!root.notificationsModuleEnabled || !notification) return false'), 'disabled module does not track or record new notifications');
assert(qml.includes('function dismissTrackedNotifications()') && qml.includes('notification.dismiss()'), 'turning off module dismisses already tracked notifications');
assert(qml.includes('Instantiator {') && qml.includes('model: notificationServer.trackedNotifications'), 'all tracked objects are watched, including DND-hidden notifications');
for (const property of ['AppName', 'DesktopEntry', 'AppIcon', 'Summary', 'Body', 'Urgency', 'ExpireTimeout', 'Image', 'Actions', 'HasActionIcons', 'Resident', 'Transient', 'HasInlineReply', 'InlineReplyPlaceholder', 'Hints'])
  assert(qml.includes('function on' + property + 'Changed() { root.scheduleTrackedNotificationRefresh(modelData) }'), 'replacement watcher observes ' + property);
assert(qml.includes('Qt.callLater(function()') && qml.includes('pendingNotificationRefreshIds'), 'rapid property notifications are coalesced per D-Bus ID');
assert(qml.includes('NotificationHistory.upsertEntry(') && qml.includes('root.reconcileDndNotifications()'), 'replaced notifications refresh history and current DND state');
assert(settings.includes('org.freedesktop.Notifications') && settings.includes('завершить Quickshell'), 'settings explain when the D-Bus name is actually released');
assert(readme.includes('### Жизненный цикл NotificationServer и D-Bus') && readme.includes('replacesId'), 'README documents server lifecycle and Notify replacement behavior');
assert(readme.includes('session bus ещё не подключён') && readme.includes('потребуется перезапустить Quickshell'), 'README documents the startup-time D-Bus connection limitation');
console.log('NotificationServer process lifetime, module gating, reload adoption and replacesId lifecycle: OK');
JS

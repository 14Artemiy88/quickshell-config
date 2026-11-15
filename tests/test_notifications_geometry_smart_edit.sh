#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
shell = (root / "shell.qml").read_text()
notifications = (root / "components/notifications/Notifications.qml").read_text()
geometry = (root / "js/settings/SettingsGeometry.js").read_text()
modules = (root / "components/settings/sections/SettingsModulesSection.qml").read_text()

assert 'item.layoutEditor = moduleLayoutEditorWindow' in shell
assert 'item.layoutEditMode = shell.layoutEditMode' in shell
assert 'function onLayoutEditModeChanged()' in shell
assert 'notificationsModuleLoader.item.layoutEditMode = shell.layoutEditMode' in shell
assert 'property bool layoutEditMode: false' in notifications
assert 'property var layoutEditor: null' in notifications
assert 'Settings.geometryForLayout("notifications")' in notifications
assert 'visible: notificationServer.trackedNotifications.values.length > 0 || root.layoutEditMode' in notifications
assert 'root.layoutEditMode && notificationServer.trackedNotifications.values.length === 0' in notifications
assert 'text: "Предварительный просмотр уведомления"' in notifications
assert 'Settings.beginGeometryDrag("notifications")' in notifications
assert 'root.layoutEditor.beginProxyDrag(' in notifications
assert 'root.layoutEditor.updateProxyDrag(globalX, globalY, popupWindow.width, popupWindow.height)' in notifications
assert 'Settings.endGeometryDrag("notifications", root.screenStorageName(targetScreen), localX, localY)' in notifications
assert 'NotificationsGeometry.storedVerticalOffset(' in notifications
assert 'Settings.cancelGeometryDrag("notifications")' in notifications
assert 'root.layoutEditor.endProxyDrag()' in notifications
assert 'Settings.geometryForLayout("notifications")' in notifications
assert 'notificationsGeometryValue(index)' in modules and 'writeNotificationsGeometry(index, n)' in modules
assert 'function geometryForLayout(owner, moduleName)' in geometry
assert 'monitors[moduleName] = String(monitorName)' in geometry
print('Notifications smart-edit wiring, empty-queue preview, absolute geometry and monitor selection: OK')
PY

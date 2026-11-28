#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
shell = (root / "shell.qml").read_text()
editor = (root / "components/ModuleLayoutEditorWindow.qml").read_text()
proxy = (root / "components/LayoutEditorProxyWindow.qml").read_text()
notifications = (root / "components/notifications/Notifications.qml").read_text()
launcher = (root / "components/launcher/Launcher.qml").read_text()
dashboard = (root / "components/Dashboard.qml").read_text()
check = (root / "CHECK.sh").read_text()

# All three independently rendered surfaces must use the same module editor,
# not competing windows or separate edit-mode state.
assert 'id: moduleLayoutEditorWindow' in shell
assert shell.count('layoutEditor: moduleLayoutEditorWindow') >= 2  # Dashboard + ordinary widgets
assert 'item.layoutEditor = moduleLayoutEditorWindow' in shell  # lazy Launcher
assert 'item.layoutEditor = moduleLayoutEditorWindow' in shell  # Notifications loader
assert 'layoutEditMode: Settings.dashboard && shell.layoutEditMode' in shell
assert 'item.layoutEditMode = shell.layoutEditMode' in shell
assert 'function onLayoutEditModeChanged()' in shell
assert 'active: shell.layoutEditMode' in shell
assert 'onExitRequested:' in shell and 'shell.layoutEditMode = false' in shell

# Shared editor and per-monitor proxy windows carry one moving module surface.
assert 'function beginProxyDrag(moduleName, globalX, globalY, width, height)' in editor
assert 'function updateProxyDrag(globalX, globalY, width, height)' in editor
assert 'function endProxyDrag()' in editor
assert 'root.updateProxyScreen()' in editor
assert 'function findScreenForGlobalPoint(globalX, globalY)' in editor
assert 'editor.proxyModuleName !== "settings"' in proxy
assert 'editor.proxyGlobalX' in proxy and 'editor.proxyWidth' in proxy
assert 'editor.proxyTargetScreen' not in proxy or 'targetScreen' in proxy

# Each surface completes the same drag contract: global proxy movement, local
# monitor coordinates, persisted monitor identity, and cancellation cleanup.
for name, source in (("Dashboard", dashboard), ("Notifications", notifications), ("Launcher", launcher)):
    assert 'Settings.beginGeometryDrag("%s")' % name.lower() in source, name
    assert 'beginProxyDrag(' in source, name
    assert 'updateProxyDrag(' in source, name
    assert 'endProxyDrag()' in source, name
    assert 'Settings.endGeometryDrag("%s", root.screenStorageName(targetScreen), localX, localY)' % name.lower() in source, name
    assert 'Settings.cancelGeometryDrag("%s")' % name.lower() in source, name
    assert 'function screenStorageName(screen)' in source, name

# Editing must not leave the surfaces competing for keyboard focus. Normal
# focus returns only after edit mode exits.
assert 'focusable: root.open && !root.layoutEditMode' in dashboard
assert 'WlrLayershell.keyboardFocus: root.open && !root.layoutEditMode ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None' in dashboard
assert 'focusable: !root.layoutEditMode' in launcher
assert 'WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None' in editor
assert 'function onLayoutEditModeChanged()' in shell
assert 'if (notificationsModuleLoader.item)' in shell

# The cross-surface contract remains part of the regular focused test suite.
assert 'tests/test_modules_cross_surface_integration.sh' in check
print('Cross-surface Notifications / Launcher / Dashboard Smart Editing contract: PASS')
PY
node - "$ROOT/js/settings/SettingsGeometry.js" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/mg, '');
const context = {};
vm.createContext(context);
vm.runInContext(source, context);
for (const [name, initial, final, monitor] of [
  ['notifications', [10,20,420,260], [110,120,420,260], 'DP-1'],
  ['launcher', [30,40,720,640], [230,240,720,640], 'DP-2'],
  ['dashboard', [50,60,900,700], [350,360,900,700], 'DP-3']
]) {
  let saves = 0;
  const owner = { geometry: {[name]: initial.slice()}, layoutEditGeometry: {}, moduleMonitors: {}, save() { saves++; } };
  context.beginGeometryDrag(owner, name);
  assert.deepStrictEqual(Array.from(context.geometryForLayout(owner, name)), initial);
  context.updateGeometryDrag(owner, name, final[0], final[1]);
  assert.deepStrictEqual(Array.from(context.geometryForLayout(owner, name)), final);
  assert.deepStrictEqual(Array.from(owner.geometry[name]), initial, 'live drag must not prematurely persist');
  context.endGeometryDrag(owner, name, monitor, final[0], final[1]);
  assert.deepStrictEqual(Array.from(owner.geometry[name]), final);
  assert.strictEqual(owner.moduleMonitors[name], monitor);
  assert.strictEqual(owner.layoutEditGeometry[name], undefined);
  assert.strictEqual(saves, 1);
  context.beginGeometryDrag(owner, name);
  context.updateGeometryDrag(owner, name, 999, 999);
  context.cancelGeometryDrag(owner, name);
  assert.deepStrictEqual(Array.from(owner.geometry[name]), final, 'cancel must preserve the last saved position');
  assert.strictEqual(owner.layoutEditGeometry[name], undefined);
  assert.strictEqual(saves, 1, 'cancel must not write settings');
}
console.log('Shared geometry drag / save / monitor / cancel behavior: PASS (3 modules)');
JS

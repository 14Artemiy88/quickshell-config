#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const dashboard = read('components/Dashboard.qml');
const shell = read('shell.qml');
const editor = read('components/ModuleLayoutEditorWindow.qml');
const proxy = read('components/LayoutEditorProxyWindow.qml');

assert(shell.includes('layoutEditMode: Settings.dashboard && shell.layoutEditMode'),
  'Dashboard receives the global Smart Editing mode only while enabled');
assert(shell.includes('layoutEditor: moduleLayoutEditorWindow'),
  'Dashboard uses the existing shared ModuleLayoutEditorWindow');
assert(dashboard.includes('property bool layoutEditMode: false')
  && dashboard.includes('property var layoutEditor: null'),
  'Dashboard exposes the same layout editor contract as other movable modules');
assert(dashboard.includes('root.open || root.keepWindowDuringClose || root.layoutEditMode'),
  'Dashboard preview remains visible while Smart Editing is active even if normally closed');
assert(dashboard.includes('x: (root.layoutEditMode || (root.open && root.visibilityAnimationReady)) ? targetX : hiddenX'),
  'the real drawer remains at its configured location during Smart Editing while normal opening waits for settled geometry');
assert(dashboard.includes('WlrLayershell.layer: root.layoutEditMode ? WlrLayer.Top : WlrLayer.Overlay'),
  'Dashboard is promoted to the interactive edit layer while moving');
assert(dashboard.includes('mask: Region { item: root.layoutEditMode ? dashboardEditInputRegion : (root.open ? fullInputRegion : null) }'),
  'the fullscreen Dashboard surface only captures the drawer area during layout editing');
assert(dashboard.includes('visible: root.layoutEditMode')
  && dashboard.includes('visible: !root.layoutDragHidden')
  && dashboard.includes('text: "Dashboard · перетащите для перемещения"'),
  'Dashboard keeps its drag input surface alive while hiding only the visuals during proxy movement');
assert(dashboard.includes('Settings.beginGeometryDrag("dashboard")')
  && dashboard.includes('root.layoutEditor.beginProxyDrag(\n            "dashboard"'),
  'Dashboard starts the same proxy drag transaction used by other modules');
assert(dashboard.includes('root.layoutEditor.updateProxyDrag(globalX, globalY, drawer.width * root.drawerUiScale, drawer.height * root.drawerUiScale)'),
  'the shared editor tracks the Dashboard drawer and its actual size');
assert(dashboard.includes('Settings.endGeometryDrag("dashboard", root.screenStorageName(targetScreen), localX, localY)'),
  'dropping commits local coordinates and the destination monitor to Settings');
assert(dashboard.includes('Settings.cancelGeometryDrag("dashboard")')
  && dashboard.includes('onCanceled: root.cancelDashboardLayoutDrag()'),
  'cancel and Esc exit paths restore the original Dashboard geometry');
assert(dashboard.includes('drawer.grabToImage(')
  && dashboard.includes('root.layoutEditor.setProxySource(result.url)'),
  'the moving preview uses an image of the actual Dashboard drawer');
assert(editor.includes('function beginProxyDrag(moduleName, globalX, globalY, width, height)')
  && proxy.includes('editor.proxyModuleName !== "settings"'),
  'the existing proxy windows already support Dashboard without a new parallel editor');
console.log('Dashboard Smart Editing integration: OK');
NODE

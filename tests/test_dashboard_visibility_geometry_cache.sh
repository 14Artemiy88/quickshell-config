#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
source = (Path(sys.argv[1]) / "components/Dashboard.qml").read_text()

def block(start, end):
    a = source.index(start)
    b = source.index(end, a)
    return source[a:b]

assert 'property bool visibilityAnimationReady: false' in source
assert 'property var visibilityReadyScreen: null' in source
assert 'property real visibilityReadyWidth: 0' in source
assert 'property real visibilityReadyHeight: 0' in source
assert 'property real visibilityReadyScreenWidth: 0' in source
assert 'property real visibilityReadyScreenHeight: 0' in source
assert 'property real visibilityReadyDrawerWidth: 0' in source
assert 'property real visibilityReadyDrawerHeight: 0' in source
cache = block('function visibilityGeometryCacheIsCurrent()', 'property var clock: null')
assert 'root.visibilityReadyScreen === root.screen' in cache
assert 'root.width' in cache and 'root.visibilityReadyWidth' in cache
assert 'root.height' in cache and 'root.visibilityReadyHeight' in cache
assert 'root.screen.width' in cache and 'root.screen.height' in cache
assert 'drawer.width' in cache and 'drawer.height' in cache
assert 'onScreenChanged: root.invalidateVisibilityGeometryCache()' in cache
assert 'onWidthChanged: root.invalidateVisibilityGeometryCache()' in cache
assert 'onHeightChanged: root.invalidateVisibilityGeometryCache()' in cache

open_change = block('onOpenChanged: {', 'color: Config.transparent')
assert 'if (!root.visibilityGeometryCacheIsCurrent())' in open_change
assert 'visibilityAnimationReadyTimer.restart()' in open_change
ready_timer = block('id: visibilityAnimationReadyTimer', 'Timer {\n        id: closeWindowTimer')
assert 'DashboardAnimation.geometryReady(' in ready_timer
assert 'root.visibilityReadyScreen = root.screen' in ready_timer
assert 'root.visibilityReadyWidth = root.width' in ready_timer
assert 'root.visibilityReadyHeight = root.height' in ready_timer
assert 'root.visibilityReadyScreenWidth = root.screen.width' in ready_timer
assert 'root.visibilityReadyScreenHeight = root.screen.height' in ready_timer
assert 'root.visibilityReadyDrawerWidth = drawer.width' in ready_timer
assert 'root.visibilityReadyDrawerHeight = drawer.height' in ready_timer
assert ready_timer.index('root.visibilityReadyHeight = root.height') < ready_timer.index('root.visibilityAnimationReady = true')
close_timer = block('id: closeWindowTimer', 'Item {\n        id: fullInputRegion')
assert 'root.keepWindowDuringClose = false' in close_timer
assert 'root.visibilityAnimationReady = false' not in close_timer, 'closing should retain validated geometry for next open'
assert 'root.invalidateVisibilityGeometryCache()' in source
assert 'onWidthChanged: root.invalidateVisibilityGeometryCache()' in source
assert 'onHeightChanged: root.invalidateVisibilityGeometryCache()' in source
print('Dashboard validated geometry cache, invalidation and repeated-open fast path: OK')
PY
echo 'dashboard visibility geometry cache: OK'

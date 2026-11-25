#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMPONENT="$ROOT/components/primitives/DragReorderHandle.qml"
HELPER="$ROOT/js/utils/DragReorder.js"

python3 - "$COMPONENT" "$HELPER" <<'PY'
from pathlib import Path
import sys
component = Path(sys.argv[1]).read_text()
helper = Path(sys.argv[2]).read_text()

# The marker uses an explicit, non-layout SettingsGroup host, not the Repeater's Column parent.
assert 'property Item dropIndicatorHost: null' in component
assert 'root.dropIndicatorHost !== null' in component
assert 'parent: root.dropIndicatorHost' in component

# Initial marker placement is explicit and independent of pointer hit-testing.
active = component.split('onActiveChanged:', 1)[1].split('onCentroidChanged:', 1)[0]
assert 'root.setDropTarget(root.itemIndex, false)' in active
assert 'root.updateDropTarget(' not in active
assert 'root.dragStartSceneX = centroid.scenePosition.x' in active
assert 'root.dragStartSceneY = centroid.scenePosition.y' in active

# The pointer must actually travel before the target is re-evaluated.
assert 'function updateDropTargetAfterMovement(sceneX, sceneY)' in component
assert 'Math.sqrt(dx * dx + dy * dy) < root.dragStartThreshold' in component
assert 'property real dragStartThreshold: 6' in component

# The marker animates between insertion slots rather than teleporting.
for prop in ('x', 'y', 'width', 'height', 'radius', 'color', 'border.width'):
    assert f'Behavior on {prop}' in component, f'missing smooth {prop} transition'
assert component.count('NumberAnimation { duration: 160; easing.type: Easing.OutCubic }') == 6
assert 'ColorAnimation { duration: 160; easing.type: Easing.OutCubic }' in component
assert 'dropSlotHysteresis' not in component
assert 'function insertionSlotGeometry(destination)' in component
assert 'function listLayoutSpacing()' in component
assert 'var spacing = root.listLayoutSpacing()' in component
assert 'DragReorder.insertionGapCenter(' in component
assert 'property bool dragPointerLeftSourceRow: false' in component
assert 'property real sourceRowExitPadding: 5' in component
assert 'function pointerInsideSourceRow(sceneX, sceneY)' in component
assert 'if (root.pointerInsideSourceRow(sceneX, sceneY))' in component
assert 'root.dragPointerLeftSourceRow = true' in component
assert 'DragReorder.pointerInsideSourceRow(' in component
assert 'DragReorder.nearestInsertionSlot(slotPositions, pointer.y)' in component
assert 'geometry.centerY' in component

# Current position is represented after the source row, not by its top edge.
assert 'if (destination < source)' in helper
assert 'if (destination <= source)' not in helper
assert 'destination + 1 < length' in helper

assert 'function pointerInsideSourceRow(sourceTop, sourceHeight, pointerY, padding)' in helper
assert 'return y >= top - inset && y <= top + height + inset' in helper
assert 'var topLeft = candidate.mapToItem(root.dropIndicatorHost, 0, 0)' in component
# The two physical gaps adjacent to the dragged item intentionally resolve
# to one logical no-op target, represented by a full-row highlight.
assert 'function sourceAdjacentGapGeometry(edge)' in component
assert 'sourceAdjacentNoopDestination(' in component
assert 'id: dropIndicator' in component
assert 'id: sourceDropHighlight' not in component, 'source frame and insertion line must be one morphing shape'
assert 'height: root.dropIndicatorHeight' in component
assert 'radius: root.dropIndicatorRadius' in component
assert 'color: root.dropIndicatorFill' in component
assert 'border.width: root.dropIndicatorBorderWidth' in component
assert 'root.dropIndicatorHeight = sourceGeometry.height' in component
assert 'root.dropIndicatorHeight = 2' in component
assert 'root.dropIndicatorFill = Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.09)' in component
assert 'root.dropIndicatorFill = Config.accent' in component
assert 'root.dropIndicatorBorderWidth = 1' in component
assert 'root.dropIndicatorBorderWidth = 0' in component
print('Drag reorder current-item no-op highlight: OK')

PY

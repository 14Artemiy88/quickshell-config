import QtQuick
import QtQuick.Controls
import ".."
import "../.."
import "../../js/utils/DragReorder.js" as DragReorder

Item {
    id: root

    property var listRepeater: null
    // Optional adapter for virtualized lists (e.g. ListView). It exposes count,
    // geometryAt(index, host), and may override insertionSlotGeometry /
    // sourceAdjacentGapGeometry when visual rows include non-sortable headers.
    property var reorderAdapter: null
    property int itemIndex: -1
    property string accessibleLabel: "элемент"
    property bool interactionEnabled: true
    property real horizontalSlop: 120
    property real verticalSlop: 76
    property int dragSourceIndex: -1
    property int dropIndex: -1
    // The two physical gaps immediately before and after the dragged row are
    // the same logical no-op destination. Represent both with one highlighted
    // source row instead of making the insertion line jump between them.
    property string dropTargetKind: "slot"
    // All delegates in a list share the containing SettingsGroup as a stable
    // overlay host. It is a plain Item, not the Repeater's Column/Row parent:
    // positioners would treat the marker as another layout child and push it
    // to the bottom while competing with our x/y animation.
    property Item dropIndicatorHost: null
    property real dropIndicatorInset: 4
    property real dropIndicatorX: 0
    property real dropIndicatorY: 0
    property real dropIndicatorWidth: 0
    property real dropIndicatorHeight: 2
    property real dropIndicatorRadius: 1
    property color dropIndicatorFill: Config.accent
    property real dropIndicatorBorderWidth: 0
    property bool dropIndicatorAnimatePosition: false
    property real dragStartSceneX: 0
    property real dragStartSceneY: 0
    property real lastDragSceneX: 0
    property real lastDragSceneY: 0
    property bool dragPointerMoved: false
    property bool dragPointerLeftSourceRow: false
    property real dragStartThreshold: 6
    property real sourceRowExitPadding: 5
    readonly property bool dragging: dragHandler.active
    readonly property bool hovered: hoverHandler.hovered

    signal reorderRequested(int fromIndex, int toIndex)
    signal dragPositionChanged(real sceneX, real sceneY)

    implicitWidth: 26
    implicitHeight: 26
    activeFocusOnTab: true
    function itemCount() {
        if (root.reorderAdapter && root.reorderAdapter.count !== undefined)
            return Math.max(0, Number(root.reorderAdapter.count) || 0)
        return root.listRepeater ? Math.max(0, Number(root.listRepeater.count) || 0) : 0
    }

    enabled: root.interactionEnabled && (root.listRepeater !== null || root.reorderAdapter !== null)
             && root.dropIndicatorHost !== null
             && root.itemCount() > 1 && root.itemIndex >= 0

    function delegateTarget(index) {
        if (!root.listRepeater || index < 0 || index >= root.listRepeater.count)
            return null
        var delegate = root.listRepeater.itemAt(index)
        if (!delegate)
            return null
        return delegate.reorderTargetItem || delegate
    }

    function listLayoutSpacing() {
        if (root.reorderAdapter && root.reorderAdapter.spacing !== undefined) {
            var adapterSpacing = Number(root.reorderAdapter.spacing)
            return isFinite(adapterSpacing) && adapterSpacing >= 0 ? adapterSpacing : 0
        }
        var list = root.listRepeater
        if (list && list.spacing !== undefined) {
            var listSpacing = Number(list.spacing)
            if (isFinite(listSpacing) && listSpacing >= 0) return listSpacing
        }
        var layout = list ? list.parent : null
        var spacing = layout && layout.spacing !== undefined ? Number(layout.spacing) : 5
        return isFinite(spacing) && spacing >= 0 ? spacing : 5
    }

    function targetGeometry(index) {
        if (index < 0 || index >= root.itemCount() || !root.dropIndicatorHost)
            return null
        if (root.reorderAdapter && typeof root.reorderAdapter.geometryAt === "function") {
            var provided = root.reorderAdapter.geometryAt(index, root.dropIndicatorHost)
            if (!provided) return null
            return {
                x: Number(provided.x) || 0,
                y: Number(provided.y) || 0,
                width: Math.max(0, Number(provided.width) || 0),
                height: Math.max(0, Number(provided.height) || 0)
            }
        }
        var candidate = root.delegateTarget(index)
        if (!candidate || !candidate.mapToItem)
            return null
        var topLeft = candidate.mapToItem(root.dropIndicatorHost, 0, 0)
        return { x: topLeft.x, y: topLeft.y, width: candidate.width, height: candidate.height }
    }

    function insertionSlotGeometry(destination) {
        var count = root.itemCount()
        if (count < 1 || !root.dropIndicatorHost
                || destination < 0 || destination >= count)
            return null

        var anchorInfo = DragReorder.insertionSlotAnchor(
                    root.dragSourceIndex, destination, count)
        if (anchorInfo.index < 0)
            return null

        if (root.reorderAdapter && typeof root.reorderAdapter.insertionSlotGeometry === "function") {
            var customGeometry = root.reorderAdapter.insertionSlotGeometry(
                        root.dragSourceIndex, destination, root.dropIndicatorHost, anchorInfo)
            if (customGeometry) return customGeometry
            return null
        }

        var candidate = root.targetGeometry(anchorInfo.index)
        if (!candidate)
            return null
        var candidateBottom = candidate.y + candidate.height
        var previous = !anchorInfo.afterLast && anchorInfo.index > 0
                ? root.targetGeometry(anchorInfo.index - 1) : null
        var spacing = root.listLayoutSpacing()
        var centerY

        if (anchorInfo.afterLast) {
            centerY = DragReorder.insertionGapCenter(
                        candidateBottom, NaN, spacing, "after")
        } else if (previous) {
            var previousBottom = previous.y + previous.height
            centerY = DragReorder.insertionGapCenter(
                        previousBottom, candidate.y, spacing, "between")
        } else {
            centerY = DragReorder.insertionGapCenter(
                        NaN, candidate.y, spacing, "before")
        }

        var left = candidate.x
        var right = candidate.x + candidate.width
        if (previous) {
            left = Math.max(left, previous.x)
            right = Math.min(right, previous.x + previous.width)
        }

        return {
            destination: destination,
            x: left + root.dropIndicatorInset,
            y: centerY - 1,
            width: Math.max(0, right - left - root.dropIndicatorInset * 2),
            centerY: centerY
        }
    }

    function sourceRowHighlightGeometry() {
        if (root.dragSourceIndex < 0)
            return null
        var source = root.targetGeometry(root.dragSourceIndex)
        if (!source)
            return null
        var inset = Math.min(root.dropIndicatorInset, Math.max(0, source.width / 4))
        return {
            x: source.x + inset,
            y: source.y + 1,
            width: Math.max(0, source.width - inset * 2),
            height: Math.max(0, source.height - 2)
        }
    }

    // The gap before the source row is an alias for the same no-op result as
    // the gap after it. Both are resolved to the whole-row source highlight.
    function sourceAdjacentGapGeometry(edge) {
        var noopDestination = DragReorder.sourceAdjacentNoopDestination(
                    root.dragSourceIndex, root.itemCount(), edge)
        if (noopDestination < 0 || !root.dropIndicatorHost)
            return null
        if (root.reorderAdapter && typeof root.reorderAdapter.sourceAdjacentGapGeometry === "function") {
            var customGeometry = root.reorderAdapter.sourceAdjacentGapGeometry(
                        root.dragSourceIndex, edge, root.dropIndicatorHost)
            if (customGeometry) return customGeometry
            return null
        }
        if (edge === "after") {
            var afterGeometry = root.insertionSlotGeometry(noopDestination)
            if (afterGeometry)
                afterGeometry.kind = "source"
            return afterGeometry
        }

        var source = root.targetGeometry(noopDestination)
        if (!source)
            return null
        var previous = noopDestination > 0 ? root.targetGeometry(noopDestination - 1) : null
        var spacing = root.listLayoutSpacing()
        var centerY
        var left = source.x
        var right = source.x + source.width

        if (previous) {
            var previousBottom = previous.y + previous.height
            centerY = DragReorder.insertionGapCenter(
                        previousBottom, source.y, spacing, "between")
            left = Math.max(left, previous.x)
            right = Math.min(right, previous.x + previous.width)
        } else {
            centerY = DragReorder.insertionGapCenter(
                        NaN, source.y, spacing, "before")
        }

        return {
            destination: noopDestination,
            kind: "source",
            x: left + root.dropIndicatorInset,
            y: centerY - 1,
            width: Math.max(0, right - left - root.dropIndicatorInset * 2),
            centerY: centerY
        }
    }

    function clearDropTarget() {
        root.dropIndicatorAnimatePosition = false
        root.dropIndex = -1
        root.dropTargetKind = "slot"
        root.dropIndicatorX = 0
        root.dropIndicatorY = 0
        root.dropIndicatorWidth = 0
        root.dropIndicatorHeight = 2
        root.dropIndicatorRadius = 1
        root.dropIndicatorFill = Config.accent
        root.dropIndicatorBorderWidth = 0
    }

    function setDropTarget(destination, animatePosition, targetKind) {
        var resolvedKind = targetKind || (destination === root.dragSourceIndex ? "source" : "slot")
        if (resolvedKind === "source") {
            var sourceGeometry = root.sourceRowHighlightGeometry()
            if (!sourceGeometry) {
                root.clearDropTarget()
                return false
            }
            root.dropIndicatorAnimatePosition = !!animatePosition
            // Morph the same visual from a thin insertion line into a full-row
            // highlight. A single shape avoids a perceptible cross-fade gap or
            // double emphasis when switching between a normal slot and no-op.
            root.dropIndicatorX = sourceGeometry.x
            root.dropIndicatorY = sourceGeometry.y
            root.dropIndicatorWidth = sourceGeometry.width
            root.dropIndicatorHeight = sourceGeometry.height
            root.dropIndicatorRadius = 6
            root.dropIndicatorFill = Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.09)
            root.dropIndicatorBorderWidth = 1
            root.dropTargetKind = "source"
            root.dropIndex = root.dragSourceIndex
            return true
        }

        var geometry = root.insertionSlotGeometry(destination)
        if (!geometry) {
            root.clearDropTarget()
            return false
        }

        // Ordinary destinations use one line centered in the measured gap.
        root.dropIndicatorAnimatePosition = !!animatePosition
        root.dropIndicatorX = geometry.x
        root.dropIndicatorY = geometry.y
        root.dropIndicatorWidth = geometry.width
        root.dropIndicatorHeight = 2
        root.dropIndicatorRadius = 1
        root.dropIndicatorFill = Config.accent
        root.dropIndicatorBorderWidth = 0
        root.dropTargetKind = "slot"
        root.dropIndex = destination
        return true
    }

    function updateDropTarget(sceneX, sceneY) {
        if (!root.enabled || root.dragSourceIndex < 0)
            return

        var host = root.dropIndicatorHost
        if (!host || !host.mapFromItem) {
            root.clearDropTarget()
            return
        }

        var pointer = host.mapFromItem(null, sceneX, sceneY)
        var slotPositions = []
        var slotCandidates = []

        // Every destination maps to the center of one measured gap. The actual
        // row bounds and its positioner's spacing are used, not an inset inside
        // the target row, so the indicator never covers its contents.
        for (var destination = 0; destination < root.itemCount(); ++destination) {
            // Add the source row's upper adjacent gap as a second physical
            // alias for the same no-op destination. The lower gap is already
            // represented by insertionSlotGeometry(sourceIndex). Both aliases
            // render one stable full-row highlight, never two competing lines.
            if (destination === root.dragSourceIndex) {
                var sourceBefore = root.sourceAdjacentGapGeometry("before")
                if (sourceBefore) {
                    slotPositions.push(sourceBefore.centerY)
                    slotCandidates.push(sourceBefore)
                }
            }

            var geometry = root.insertionSlotGeometry(destination)
            if (!geometry)
                continue
            geometry.kind = destination === root.dragSourceIndex ? "source" : "slot"
            slotPositions.push(geometry.centerY)
            slotCandidates.push(geometry)
        }

        // Pure nearest-gap selection: same pointer coordinates always resolve
        // to the same destination, independent of the pointer's approach path.
        var nearestSlot = DragReorder.nearestInsertionSlot(slotPositions, pointer.y)
        var bestIndex = -1
        if (nearestSlot >= 0 && nearestSlot < slotCandidates.length) {
            var best = slotCandidates[nearestSlot]
            var markerRight = best.x + best.width
            var dx = pointer.x < best.x ? best.x - pointer.x
                       : (pointer.x > markerRight ? pointer.x - markerRight : 0)
            var dy = Math.abs(pointer.y - best.centerY)
            if (dx <= root.horizontalSlop && dy <= root.verticalSlop)
                bestIndex = best.destination
        }

        if (bestIndex >= 0) {
            var selected = slotCandidates[nearestSlot]
            var selectedKind = selected.kind || (bestIndex === root.dragSourceIndex ? "source" : "slot")
            if (bestIndex !== root.dropIndex || selectedKind !== root.dropTargetKind)
                root.setDropTarget(bestIndex, true, selectedKind)
        } else {
            root.clearDropTarget()
        }
    }

    function pointerInsideSourceRow(sceneX, sceneY) {
        var host = root.dropIndicatorHost
        var source = root.targetGeometry(root.dragSourceIndex)
        if (!host || !source || !host.mapFromItem)
            return true

        var pointer = host.mapFromItem(null, sceneX, sceneY)
        return DragReorder.pointerInsideSourceRow(
                    source.y, source.height, pointer.y, root.sourceRowExitPadding)
    }

    function refreshDropTargetForLayoutChange() {
        if (!dragHandler.active || !root.dragPointerMoved || !root.dragPointerLeftSourceRow)
            return
        root.updateDropTarget(root.lastDragSceneX, root.lastDragSceneY)
    }

    function updateDropTargetAfterMovement(sceneX, sceneY) {
        root.lastDragSceneX = sceneX
        root.lastDragSceneY = sceneY
        root.dragPositionChanged(sceneX, sceneY)
        if (!root.dragPointerMoved) {
            var dx = sceneX - root.dragStartSceneX
            var dy = sceneY - root.dragStartSceneY
            if (Math.sqrt(dx * dx + dy * dy) < root.dragStartThreshold)
                return
            root.dragPointerMoved = true
        }

        // Do not re-hit-test while the pointer is still inside the source row.
        // Its centre is not an insertion boundary, so using it immediately
        // would make the marker jump to the neighbouring slot on drag start.
        if (!root.dragPointerLeftSourceRow) {
            if (root.pointerInsideSourceRow(sceneX, sceneY))
                return
            root.dragPointerLeftSourceRow = true
        }

        root.updateDropTarget(sceneX, sceneY)
    }

    function finishDrag() {
        var from = root.dragSourceIndex
        var to = root.dropIndex
        root.dropIndicatorAnimatePosition = false
        root.dragSourceIndex = -1
        root.clearDropTarget()
        if (from >= 0 && to >= 0 && from !== to)
            root.reorderRequested(from, to)
    }

    Rectangle {
        anchors.fill: parent
        radius: 5
        color: dragHandler.active || hoverHandler.hovered
               ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.14)
               : "transparent"
        border.width: dragHandler.active || root.activeFocus ? 1 : 0
        border.color: Config.accent
    }

    Text {
        anchors.fill: parent
        text: "⠿"
        color: dragHandler.active || hoverHandler.hovered || root.activeFocus ? Config.accent : Config.textMuted
        font.family: Config.settingsFont
        font.pixelSize: 18
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Rectangle {
        id: dropIndicator
        // One shape morphs between the thin insertion line and the full-row
        // no-op highlight. Geometry, radius, fill and outline animate together,
        // so the transition never flashes or briefly shows both markers.
        parent: root.dropIndicatorHost ? root.dropIndicatorHost : root
        visible: dragHandler.active && root.dragSourceIndex >= 0
                 && root.dropIndicatorHost !== null && root.dropIndex >= 0
        x: root.dropIndicatorX
        y: root.dropIndicatorY
        width: root.dropIndicatorWidth
        height: root.dropIndicatorHeight
        radius: root.dropIndicatorRadius
        color: root.dropIndicatorFill
        border.width: root.dropIndicatorBorderWidth
        border.color: Config.accent
        z: 10000

        Behavior on x {
            enabled: root.dropIndicatorAnimatePosition
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            enabled: root.dropIndicatorAnimatePosition
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            enabled: root.dropIndicatorAnimatePosition
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            enabled: root.dropIndicatorAnimatePosition
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on radius {
            enabled: root.dropIndicatorAnimatePosition
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on color {
            enabled: root.dropIndicatorAnimatePosition
            ColorAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on border.width {
            enabled: root.dropIndicatorAnimatePosition
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
    }

    HoverHandler { id: hoverHandler }

    ToolTip.visible: hoverHandler.hovered && !dragHandler.active
    ToolTip.text: "Перетащить · Alt + ↑/↓"
    ToolTip.delay: 500

    DragHandler {
        id: dragHandler
        target: null
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton

        onActiveChanged: {
            if (active) {
                root.dragSourceIndex = root.itemIndex
                root.dragStartSceneX = centroid.scenePosition.x
                root.dragStartSceneY = centroid.scenePosition.y
                root.lastDragSceneX = centroid.scenePosition.x
                root.lastDragSceneY = centroid.scenePosition.y
                root.dragPointerMoved = false
                root.dragPointerLeftSourceRow = false
                root.dragPositionChanged(centroid.scenePosition.x, centroid.scenePosition.y)
                // Show the current final-order slot immediately. Do not use the
                // pointer centre to guess a neighbouring slot on the first frame.
                root.setDropTarget(root.itemIndex, false)
            } else {
                root.dropIndicatorAnimatePosition = false
                root.finishDrag()
                root.dragPointerMoved = false
                root.dragPointerLeftSourceRow = false
            }
        }
        onCentroidChanged: {
            if (active)
                root.updateDropTargetAfterMovement(centroid.scenePosition.x, centroid.scenePosition.y)
        }
        onActiveTranslationChanged: {
            if (active)
                root.updateDropTargetAfterMovement(centroid.scenePosition.x, centroid.scenePosition.y)
        }
    }

    Keys.onPressed: function(event) {
        if (!(event.modifiers & Qt.AltModifier))
            return
        var delta = event.key === Qt.Key_Up ? -1 : (event.key === Qt.Key_Down ? 1 : 0)
        if (delta === 0)
            return
        var target = root.itemIndex + delta
        if (target >= 0 && target < root.itemCount()) {
            root.reorderRequested(root.itemIndex, target)
            event.accepted = true
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: "Переместить " + root.accessibleLabel
    Accessible.description: "Перетащите маркер, чтобы изменить порядок. Также доступны Alt и стрелки вверх или вниз."
}

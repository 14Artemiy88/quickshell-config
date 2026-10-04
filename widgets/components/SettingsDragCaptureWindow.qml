import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    property var editor: null
    property var targetScreen: null
    property bool captureActive: Boolean(
        editor && editor.active && editor.proxyActive &&
        editor.proxyModuleName === "settings" && targetScreen &&
        String(editor.proxyInputScreenName || "").trim().toLowerCase() === root.screenStorageName(targetScreen).trim().toLowerCase()
    )
    property bool dragging: false
    property real pressMouseX: 0
    property real pressMouseY: 0
    property real dragStartGlobalX: 0
    property real dragStartGlobalY: 0

    visible: root.captureActive
    screen: targetScreen
    color: Config.transparent
    focusable: false
    exclusionMode: ExclusionMode.Ignore
    anchors.left: true
    anchors.top: true
    implicitWidth: targetScreen ? Math.max(1, Number(targetScreen.width || 1)) : 1
    implicitHeight: targetScreen ? Math.max(1, Number(targetScreen.height || 1)) : 1
    aboveWindows: true
    WlrLayershell.layer: WlrLayer.Overlay

    function screenStorageName(screen) {
        if (!screen) return ""
        if (screen.name && String(screen.name).trim() !== "")
            return String(screen.name)
        if (screen.model && String(screen.model).trim() !== "")
            return String(screen.model)
        return ""
    }

    function globalFromMouse(mouseX, mouseY) {
        return {
            x: Number(targetScreen && targetScreen.x || 0) + Number(mouseX),
            y: Number(targetScreen && targetScreen.y || 0) + Number(mouseY)
        }
    }

    function pointInProxy(globalX, globalY) {
        if (!editor || !editor.proxyActive)
            return false
        var px = Number(editor.proxyGlobalX || 0)
        var py = Number(editor.proxyGlobalY || 0)
        var pw = Math.max(1, Number(editor.proxyWidth || 1))
        var ph = Math.max(1, Number(editor.proxyHeight || 1))
        return globalX >= px && globalX <= px + pw && globalY >= py && globalY <= py + ph
    }

    function finishDrag() {
        if (!root.dragging || !editor || !editor.proxyActive)
            return

        var centerX = Number(editor.proxyGlobalX || 0) + Number(editor.proxyWidth || 1) / 2
        var centerY = Number(editor.proxyGlobalY || 0) + Number(editor.proxyHeight || 1) / 2
        var currentScreen = null
        var nearest = null
        var nearestDistance = Number.POSITIVE_INFINITY
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var s = Quickshell.screens[i]
            if (!s) continue
            var sx = Number(s.x || 0)
            var sy = Number(s.y || 0)
            var sw = Number(s.width || 0)
            var sh = Number(s.height || 0)
            if (centerX >= sx && centerX < sx + sw && centerY >= sy && centerY < sy + sh) {
                currentScreen = s
                break
            }
            var cx = Math.max(sx, Math.min(centerX, sx + sw))
            var cy = Math.max(sy, Math.min(centerY, sy + sh))
            var dx = centerX - cx
            var dy = centerY - cy
            var distance = dx * dx + dy * dy
            if (distance < nearestDistance) {
                nearestDistance = distance
                nearest = s
            }
        }
        if (!currentScreen)
            currentScreen = nearest || targetScreen || null

        if (currentScreen) {
            var localX = Number(editor.proxyGlobalX || 0) - Number(currentScreen.x || 0)
            var localY = Number(editor.proxyGlobalY || 0) - Number(currentScreen.y || 0)
            var screenName = root.screenStorageName(currentScreen)
            Settings.endSettingsGeometryDrag(
                screenName,
                localX,
                localY
            )

            // Keep the settings move mode active after release.
            // The proxy stays visible and can be dragged again until Esc.
            editor.proxyInputScreenName = screenName
        }

        root.dragging = false
    }

    function cancelDrag() {
        root.dragging = false
        if (editor)
            editor.endProxyDrag()
    }

    Rectangle {
        anchors.fill: parent
        color: Config.transparent
    }

    Item {
        id: proxyItem
        x: Number(editor && editor.proxyGlobalX || 0) - Number(root.targetScreen && root.targetScreen.x || 0)
        y: Number(editor && editor.proxyGlobalY || 0) - Number(root.targetScreen && root.targetScreen.y || 0)
        width: Math.max(1, Number(editor && editor.proxyWidth || 1))
        height: Math.max(1, Number(editor && editor.proxyHeight || 1))

        Rectangle {
            anchors.fill: parent
            color: Config.transparent
            border.color: Config.accent
            border.width: Math.max(2, Config.frameBorderWidth + 1)
            radius: Config.frameRadius
            antialiasing: true
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 5
            width: proxyLabel.implicitWidth + 14
            height: proxyLabel.implicitHeight + 8
            radius: 4
            color: Config.accent

            Text {
                id: proxyLabel
                anchors.centerIn: parent
                text: editor ? editor.proxyModuleName : ""
                color: Config.black
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                font.bold: true
            }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: root.captureActive
        visible: root.captureActive
        acceptedButtons: Qt.LeftButton
        preventStealing: true
        hoverEnabled: true

        onPressed: function(mouse) {
            var global = root.globalFromMouse(mouse.x, mouse.y)
            if (!root.pointInProxy(global.x, global.y)) {
                mouse.accepted = false
                return
            }
            root.dragging = true
            root.pressMouseX = Number(mouse.x)
            root.pressMouseY = Number(mouse.y)
            root.dragStartGlobalX = Number(editor.proxyGlobalX || 0)
            root.dragStartGlobalY = Number(editor.proxyGlobalY || 0)
        }

        onPositionChanged: function(mouse) {
            if (!pressed || !root.dragging || !editor || !editor.proxyActive)
                return
            var dx = Number(mouse.x) - root.pressMouseX
            var dy = Number(mouse.y) - root.pressMouseY
            editor.updateProxyDrag(
                root.dragStartGlobalX + dx,
                root.dragStartGlobalY + dy,
                editor.proxyWidth,
                editor.proxyHeight
            )
        }

        onReleased: function(mouse) {
            if (!root.dragging)
                return
            var dx = Number(mouse.x) - root.pressMouseX
            var dy = Number(mouse.y) - root.pressMouseY
            editor.updateProxyDrag(
                root.dragStartGlobalX + dx,
                root.dragStartGlobalY + dy,
                editor.proxyWidth,
                editor.proxyHeight
            )
            root.finishDrag()
        }

        onCanceled: {
            // Keep the move mode alive just like the module editor.
            // Esc is the explicit way to leave the mode.
            root.dragging = false
        }
    }
}

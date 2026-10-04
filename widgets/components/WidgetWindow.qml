import QtQuick
import ".."
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    property int offsetX: 0
    property int offsetY: 0
    property int contentWidth: 315
    property int contentHeight: 100
    property bool bottomLayer: true
    property bool keyboardEnabled: false
    property bool backgroundBlurEnabled: false
    property int backgroundBlurRadius: 7
    property string moduleName: ""
    property bool layoutEditMode: false
    property bool liveDragging: false
    property var layoutEditor: null
    property real dragBaseGlobalX: 0
    property real dragBaseGlobalY: 0
    property real dragPressX: 0
    property real dragPressY: 0
    property string screenName: {
        var configured = root.moduleName && Settings.moduleMonitors ? Settings.moduleMonitors[root.moduleName] : ""
        return String(configured || Config.monitorName)
    }

    function screenMatchesName(screen, name) {
        if (!screen || !name) return false
        var wanted = String(name).trim().toLowerCase()
        return String(screen.name || "").trim().toLowerCase() === wanted
            || String(screen.model || "").trim().toLowerCase() === wanted
            || String(screen).trim().toLowerCase() === wanted
    }

    function screenStorageName(screen) {
        if (!screen) return ""
        if (screen.name && String(screen.name).trim() !== "")
            return String(screen.name)
        if (screen.model && String(screen.model).trim() !== "")
            return String(screen.model)
        return ""
    }

    function findScreenForGlobalPoint(globalX, globalY) {
        var nearest = null
        var nearestDistance = Number.POSITIVE_INFINITY
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var s = Quickshell.screens[i]
            if (!s) continue
            var sx = Number(s.x || 0)
            var sy = Number(s.y || 0)
            var sw = Number(s.width || 0)
            var sh = Number(s.height || 0)
            if (globalX >= sx && globalX < sx + sw && globalY >= sy && globalY < sy + sh)
                return s
            var cx = Math.max(sx, Math.min(globalX, sx + sw))
            var cy = Math.max(sy, Math.min(globalY, sy + sh))
            var dx = globalX - cx
            var dy = globalY - cy
            var distance = dx * dx + dy * dy
            if (distance < nearestDistance) {
                nearestDistance = distance
                nearest = s
            }
        }
        return nearest || root.screen || Quickshell.screens[0] || null
    }

    function resolveScreen(name) {
        var wanted = String(name || "").trim()
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            if (screenMatchesName(Quickshell.screens[i], wanted))
                return Quickshell.screens[i]
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    screen: root.resolveScreen(root.screenName || Config.monitorName)
    implicitWidth: contentWidth
    implicitHeight: contentHeight
    color: Config.transparent
    focusable: keyboardEnabled
    exclusionMode: ExclusionMode.Ignore
    anchors.left: true
    anchors.top: true
    margins.left: root.offsetX
    margins.top: root.offsetY
    WlrLayershell.layer: root.layoutEditMode ? WlrLayer.Top : (bottomLayer ? WlrLayer.Bottom : WlrLayer.Top)

    Item {
        id: editOverlay
        anchors.fill: parent
        visible: root.layoutEditMode && root.moduleName !== ""
        z: 10000

        Rectangle {
            id: editBorder
            anchors.fill: parent
            visible: !root.liveDragging
            color: "transparent"
            border.color: Config.accent
            border.width: Math.max(2, Config.frameBorderWidth + 1)
            radius: Config.frameRadius
            antialiasing: true
        }

        Rectangle {
            id: editLabelBox
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 5
            visible: !root.liveDragging
            width: editLabel.implicitWidth + 14
            height: editLabel.implicitHeight + 8
            radius: 4
            color: Config.accent
            border.color: Config.accent
            border.width: 1

            Text {
                id: editLabel
                anchors.centerIn: parent
                text: root.moduleName
                color: Config.black
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                font.bold: true
            }
        }

        MouseArea {
            id: editDragArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            hoverEnabled: true

            function finishDrag(mouseX, mouseY) {
                if (!root.liveDragging)
                    return

                var currentGlobalX = root.dragBaseGlobalX + (Number(mouseX) - root.dragPressX)
                var currentGlobalY = root.dragBaseGlobalY + (Number(mouseY) - root.dragPressY)
                var currentScreen = root.findScreenForGlobalPoint(
                    currentGlobalX + root.width / 2,
                    currentGlobalY + root.height / 2
                )
                var targetName = root.screenStorageName(currentScreen)
                var localX = currentGlobalX - Number(currentScreen && currentScreen.x || 0)
                var localY = currentGlobalY - Number(currentScreen && currentScreen.y || 0)

                if (root.layoutEditor)
                    root.layoutEditor.endProxyDrag()

                Settings.endGeometryDrag(root.moduleName, targetName, localX, localY)

                root.liveDragging = false
                Qt.callLater(function() {
                    root.contentItem.opacity = 1
                })
            }

            onPressed: function(mouse) {
                if (!root.layoutEditMode || root.liveDragging)
                    return

                root.dragPressX = Number(mouse.x)
                root.dragPressY = Number(mouse.y)
                root.dragBaseGlobalX = Number(root.screen && root.screen.x || 0) + Number(root.offsetX)
                root.dragBaseGlobalY = Number(root.screen && root.screen.y || 0) + Number(root.offsetY)
                root.liveDragging = true
                Settings.beginGeometryDrag(root.moduleName)

                var startGlobalX = root.dragBaseGlobalX
                var startGlobalY = root.dragBaseGlobalY
                if (root.layoutEditor) {
                    root.layoutEditor.beginProxyDrag(
                        root.moduleName,
                        startGlobalX,
                        startGlobalY,
                        root.width,
                        root.height
                    )
                }

                root.contentItem.grabToImage(function(result) {
                    if (!root.liveDragging) {
                        root.contentItem.opacity = 1
                        return
                    }
                    root.contentItem.opacity = 0
                    if (root.layoutEditor)
                        root.layoutEditor.setProxySource(result.url)
                }, Qt.size(Math.max(1, Math.round(root.width)), Math.max(1, Math.round(root.height))))
            }

            onPositionChanged: function(mouse) {
                if (!pressed || !root.liveDragging)
                    return

                var currentGlobalX = root.dragBaseGlobalX + (Number(mouse.x) - root.dragPressX)
                var currentGlobalY = root.dragBaseGlobalY + (Number(mouse.y) - root.dragPressY)
                if (root.layoutEditor)
                    root.layoutEditor.updateProxyDrag(
                        currentGlobalX,
                        currentGlobalY,
                        root.width,
                        root.height
                    )
            }

            onReleased: function(mouse) {
                finishDrag(mouse.x, mouse.y)
            }

            onCanceled: function() {
                if (!root.liveDragging)
                    return
                if (root.layoutEditor)
                    root.layoutEditor.endProxyDrag()
                Settings.cancelGeometryDrag(root.moduleName)
                root.liveDragging = false
                root.contentItem.opacity = 1
            }
        }
    }

    // Blur what is behind this layer-shell surface, not its own contents.
    // Requires compositor support for ext-background-effect-v1.
    BackgroundEffect.blurRegion: Region {
        item: root.backgroundBlurEnabled ? root.contentItem : null
        radius: Math.max(0, root.backgroundBlurRadius)
    }
}

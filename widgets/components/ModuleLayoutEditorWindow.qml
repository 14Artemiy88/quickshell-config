import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    visible: root.active
    screen: root.editScreen
    implicitWidth: root.editScreen ? Math.max(1, root.editScreen.width) : 1
    implicitHeight: root.editScreen ? Math.max(1, root.editScreen.height) : 1
    anchors.left: true
    anchors.top: true
    aboveWindows: true
    focusable: root.active
    color: Config.transparent
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool active: false
    property var settings: Settings
    property var editScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    property bool proxyActive: false
    property string proxyModuleName: ""
    property string proxySource: ""
    property real proxyGlobalX: 0
    property real proxyGlobalY: 0
    property real proxyWidth: 1
    property real proxyHeight: 1
    property var proxyTargetScreen: null
    signal exitRequested()

    function screenMatchesName(screen, name) {
        if (!screen || !name) return false
        var wanted = String(name).trim().toLowerCase()
        return String(screen.name || '').trim().toLowerCase() === wanted
            || String(screen.model || '').trim().toLowerCase() === wanted
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
        return nearest || root.editScreen || Quickshell.screens[0] || null
    }

    function setProxySource(source) {
        if (!root.proxyActive)
            return
        root.proxySource = String(source || "")
    }

    function beginProxyDrag(moduleName, globalX, globalY, width, height) {
        root.proxyModuleName = String(moduleName || "")
        root.proxyGlobalX = Number(globalX) || 0
        root.proxyGlobalY = Number(globalY) || 0
        root.proxyWidth = Math.max(1, Number(width) || 1)
        root.proxyHeight = Math.max(1, Number(height) || 1)
        root.proxySource = ""
        root.proxyActive = true
        root.updateProxyScreen()
    }

    function updateProxyScreen() {
        var centerX = root.proxyGlobalX + root.proxyWidth / 2
        var centerY = root.proxyGlobalY + root.proxyHeight / 2
        root.proxyTargetScreen = root.findScreenForGlobalPoint(centerX, centerY)
        if (root.proxyTargetScreen)
            root.editScreen = root.proxyTargetScreen
    }

    function updateProxyDrag(globalX, globalY, width, height) {
        if (!root.proxyActive)
            return
        root.proxyGlobalX = Number(globalX) || 0
        root.proxyGlobalY = Number(globalY) || 0
        if (width !== undefined)
            root.proxyWidth = Math.max(1, Number(width) || 1)
        if (height !== undefined)
            root.proxyHeight = Math.max(1, Number(height) || 1)
        root.updateProxyScreen()
    }

    function endProxyDrag() {
        root.proxyActive = false
        root.proxyModuleName = ""
        root.proxySource = ""
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (root.proxyActive)
                root.updateProxyScreen()
            else if (!root.editScreen && Quickshell.screens.length > 0)
                root.editScreen = Quickshell.screens[0]
        }
    }

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: root.active

        Component.onCompleted: {
            if (root.active) forceActiveFocus()
        }

        onVisibleChanged: {
            if (root.active && visible) forceActiveFocus()
        }

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true
                root.exitRequested()
            }
        }
    }

    Item {
        id: proxyItem
        x: root.proxyGlobalX - Number(root.editScreen && root.editScreen.x || 0)
        y: root.proxyGlobalY - Number(root.editScreen && root.editScreen.y || 0)
        width: root.proxyWidth
        height: root.proxyHeight
        visible: root.proxyActive
        z: 10000

        Image {
            anchors.fill: parent
            visible: source !== ""
            source: root.proxySource
            asynchronous: true
            fillMode: Image.Stretch
            smooth: true
            cache: false
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
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
                text: root.proxyModuleName
                color: Config.black
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                font.bold: true
            }
        }
    }

    mask: Region {
        item: root.proxyActive ? proxyInputRegion : null
    }

    Item {
        id: proxyInputRegion
        x: proxyItem.x
        y: proxyItem.y
        width: proxyItem.width
        height: proxyItem.height
    }

    onActiveChanged: {
        if (active) Qt.callLater(function() { if (root.active) keyHandler.forceActiveFocus() })
        else endProxyDrag()
    }
}

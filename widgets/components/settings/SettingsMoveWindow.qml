import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."

PanelWindow {
    id: root

    visible: root.active
    screen: moveScreen
    aboveWindows: true
    focusable: root.active
    color: Config.transparent
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var settings: Settings
    property bool active: false
    signal exitRequested()

    property var moveScreen: root.resolveSettingsScreen(root.settings ? root.settings.settingsMonitorName : Config.monitorName)

    function screenMatchesName(screen, name) {
        if (!screen || !name)
            return false
        return screen.name === name || screen.model === name || String(screen) === name
    }

    function resolveSettingsScreen(name) {
        var wanted = String(name || "")
        var found = Quickshell.screens.find(function(s) {
            return root.screenMatchesName(s, wanted)
        })
        if (found)
            return found

        var configured = Quickshell.screens.find(function(s) {
            return root.screenMatchesName(s, Config.monitorName)
        })
        return configured || Quickshell.screens[0]
    }

    function screenStorageName(screen) {
        if (!screen)
            return ""
        if (screen.name && String(screen.name).trim() !== "")
            return String(screen.name)
        if (screen.model && String(screen.model).trim() !== "")
            return String(screen.model)
        return ""
    }

    function findScreenForGlobalRectCenter(globalX, globalY) {
        var exact = null
        var nearest = null
        var nearestDistance = Number.POSITIVE_INFINITY

        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var s = Quickshell.screens[i]
            if (!s)
                continue

            var gx = Number(s.x || 0)
            var gy = Number(s.y || 0)
            var gw = Number(s.width || 0)
            var gh = Number(s.height || 0)

            if (globalX >= gx && globalX < gx + gw &&
                globalY >= gy && globalY < gy + gh) {
                exact = s
                break
            }

            var cx = Math.max(gx, Math.min(globalX, gx + gw))
            var cy = Math.max(gy, Math.min(globalY, gy + gh))
            var dx = globalX - cx
            var dy = globalY - cy
            var distance = dx * dx + dy * dy
            if (distance < nearestDistance) {
                nearestDistance = distance
                nearest = s
            }
        }

        return exact || nearest || root.moveScreen || Quickshell.screens[0]
    }

    onActiveChanged: {
        if (active) {
            moveScreen = root.resolveSettingsScreen(root.settings ? root.settings.settingsMonitorName : Config.monitorName)
            Qt.callLater(function() {
                if (root.active)
                    keyHandler.forceActiveFocus()
            })
        }
    }

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: root.active

        onVisibleChanged: {
            if (root.active && visible)
                forceActiveFocus()
        }

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true
                root.exitRequested()
            }
        }
    }

    Rectangle {
        id: dimmer
        anchors.fill: parent
        color: "#18000000"
    }

    Rectangle {
        id: settingsFrame
        x: Number(root.settings.settingsGeometry[0]) || 0
        y: Number(root.settings.settingsGeometry[1]) || 0
        width: Math.max(320, Number(root.settings.settingsGeometry[2]) || 560)
        height: Math.max(240, Number(root.settings.settingsGeometry[3]) || 850)
        color: Config.settingsBackground
        border.color: Config.accent
        border.width: Math.max(2, Config.frameBorderWidth + 1)
        radius: Config.frameRadius
        opacity: dragHandler.active ? 0.88 : 0.72
        antialiasing: true

        Text {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 10
            text: "НАСТРОЙКИ"
            color: dragHandler.active ? Config.black : Config.accent
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(12)
            font.bold: true
        }

        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            text: Math.round(settingsFrame.x) + ":" + Math.round(settingsFrame.y)
                  + "  " + Math.round(settingsFrame.width) + "×" + Math.round(settingsFrame.height)
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            style: Text.Outline
            styleColor: Config.black
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            text: root.moveScreen ? (root.moveScreen.name || root.moveScreen.model || "") : ""
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 360)
            height: 74
            radius: 6
            color: dragHandler.active ? Config.accent : Config.settingsBackground
            border.color: Config.accent
            border.width: 1

            Text {
                anchors.fill: parent
                anchors.margins: 12
                text: dragHandler.active
                    ? "Перемещайте окно мышью"
                    : "Зажмите ЛКМ и переместите окно"
                color: dragHandler.active ? Config.black : Config.accent
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(12)
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
        }

        DragHandler {
            id: dragHandler
            target: null
            acceptedButtons: Qt.LeftButton

            property real startX: 0
            property real startY: 0
            property var dragScreen: null

            onActiveChanged: {
                if (active) {
                    dragScreen = root.moveScreen || root.resolveSettingsScreen(root.settings.settingsMonitorName)
                    var g = root.settings.settingsGeometry || [0, 0, width, height]
                    startX = Number(g[0]) || 0
                    startY = Number(g[1]) || 0
                    root.settings.beginSettingsGeometryDrag()
                } else {
                    var s = dragScreen || root.moveScreen || root.resolveSettingsScreen(root.settings.settingsMonitorName)
                    var sg = s ? { x: Number(s.x || 0), y: Number(s.y || 0) } : { x: 0, y: 0 }
                    var finalLocalX = Number(settingsFrame.x) || 0
                    var finalLocalY = Number(settingsFrame.y) || 0
                    var centerGlobalX = Number(sg.x) + finalLocalX + settingsFrame.width / 2
                    var centerGlobalY = Number(sg.y) + finalLocalY + settingsFrame.height / 2
                    var targetScreen = root.findScreenForGlobalRectCenter(centerGlobalX, centerGlobalY)

                    if (targetScreen && targetScreen !== s) {
                        var tgx = Number(targetScreen.x || 0)
                        var tgy = Number(targetScreen.y || 0)
                        finalLocalX = centerGlobalX - tgx - settingsFrame.width / 2
                        finalLocalY = centerGlobalY - tgy - settingsFrame.height / 2
                        root.settings.updateSettingsGeometryDrag(
                            finalLocalX,
                            finalLocalY,
                            root.screenStorageName(targetScreen)
                        )
                        root.moveScreen = targetScreen
                    }

                    root.settings.endSettingsGeometryDrag()
                    dragScreen = null
                }
            }

            onActiveTranslationChanged: {
                if (!active)
                    return

                root.settings.updateSettingsGeometryDrag(
                    startX + activeTranslation.x,
                    startY + activeTranslation.y
                )
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.SizeAllCursor
        }
    }
}

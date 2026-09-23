import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    visible: root.active
    screen: editScreen
    aboveWindows: true
    focusable: root.active
    color: Config.transparent
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var settings: Settings
    property bool active: false
    signal exitRequested()
    property var editScreen: Quickshell.screens.find(s =>
        s.name === Config.monitorName ||
        s.model === Config.monitorName ||
        s.toString() === Config.monitorName
    ) || Quickshell.screens[0]

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

    Repeater {
        model: settings.moduleNames

        delegate: Item {
            id: editorItem
            property string moduleName: modelData
            property string moduleLabel: settings.moduleLabels[moduleName] || moduleName
            property var currentGeometry: settings.geometryForLayout(moduleName) || [0, 0, 100, 100]
            property bool moduleEnabled: !!settings[moduleName]

            visible: moduleEnabled
            x: currentGeometry[0]
            y: currentGeometry[1]
            width: Math.max(1, currentGeometry[2])
            height: Math.max(1, currentGeometry[3])

            function geometryChangedByDrag() {
                var g = settings.geometryForLayout(moduleName) || [0, 0, width, height]
                return g
            }

            Rectangle {
                anchors.fill: parent
                color: "#1800cccc"
                border.color: Config.accent
                border.width: Math.max(1, Config.frameBorderWidth)
                radius: Config.frameRadius
                opacity: 0.55
            }

            Rectangle {
                id: badge
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 5
                width: label.implicitWidth + 14
                height: label.implicitHeight + 8
                radius: 4
                color: Config.settingsBackground
                border.color: Config.accent
                border.width: 1

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: editorItem.moduleLabel
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    font.bold: true
                }
            }

            Text {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 5
                text: {
                    var g = settings.geometryForLayout(editorItem.moduleName) || [0, 0, 0, 0]
                    return Math.round(g[0]) + ":" + Math.round(g[1]) + "  " + Math.round(g[2]) + "×" + Math.round(g[3])
                }
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
                style: Text.Outline
                styleColor: Config.black
            }

            DragHandler {
                id: dragHandler
                target: null
                acceptedButtons: Qt.LeftButton

                property real startX: 0
                property real startY: 0

                onActiveChanged: {
                    if (active) {
                        var g = settings.geometryForLayout(editorItem.moduleName) || [0, 0, 100, 100]
                        startX = Number(g[0]) || 0
                        startY = Number(g[1]) || 0
                        settings.beginGeometryDrag(editorItem.moduleName)
                    } else {
                        settings.endGeometryDrag(editorItem.moduleName)
                    }
                }

                onActiveTranslationChanged: {
                    if (!active)
                        return

                    settings.updateGeometryDrag(
                        editorItem.moduleName,
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
}

import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    property var editor: null
    property var targetScreen: null
    readonly property real proxyUiScale: Config.moduleUiScale()

    visible: Boolean(editor && editor.proxyActive && editor.proxyModuleName !== "settings" && targetScreen && root.intersectsProxy)
    screen: targetScreen
    color: Config.transparent
    focusable: false
    exclusionMode: ExclusionMode.Ignore
    anchors.left: true
    anchors.top: true
    aboveWindows: true
    WlrLayershell.layer: WlrLayer.Top

    readonly property bool intersectsProxy: {
        if (!editor || !targetScreen)
            return false
        var sx = Number(targetScreen.x || 0)
        var sy = Number(targetScreen.y || 0)
        var sw = Number(targetScreen.width || 0)
        var sh = Number(targetScreen.height || 0)
        var px = Number(editor.proxyGlobalX || 0)
        var py = Number(editor.proxyGlobalY || 0)
        var pw = Math.max(1, Number(editor.proxyWidth || 1))
        var ph = Math.max(1, Number(editor.proxyHeight || 1))
        return px < sx + sw && px + pw > sx && py < sy + sh && py + ph > sy
    }

    Item {
        id: proxyItem
        x: Number(editor && editor.proxyGlobalX || 0) - Number(root.targetScreen && root.targetScreen.x || 0)
        y: Number(editor && editor.proxyGlobalY || 0) - Number(root.targetScreen && root.targetScreen.y || 0)
        width: Math.max(1, Number(editor && editor.proxyWidth || 1))
        height: Math.max(1, Number(editor && editor.proxyHeight || 1))

        Image {
            anchors.fill: parent
            visible: source !== ""
            source: editor && editor.proxySource !== undefined ? String(editor.proxySource) : ""
            asynchronous: true
            fillMode: Image.Stretch
            smooth: true
            cache: false
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Config.accent
            border.width: Math.max(2, Math.round((Config.frameBorderWidth + 1) * root.proxyUiScale))
            radius: Math.round(Config.scaledCornerRadius(Config.frameRadius) * root.proxyUiScale)
            antialiasing: true
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: Math.round(5 * root.proxyUiScale)
            width: proxyLabel.implicitWidth + Math.round(14 * root.proxyUiScale)
            height: proxyLabel.implicitHeight + Math.round(8 * root.proxyUiScale)
            radius: Math.round(4 * root.proxyUiScale)
            color: Config.accent

            Text {
                id: proxyLabel
                anchors.centerIn: parent
                text: editor ? editor.proxyModuleName : ""
                color: Config.black
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(11)
                font.bold: true
            }
        }
    }
}

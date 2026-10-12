import QtQuick
import Quickshell
import ".."
import "primitives" as Primitives

Item {
    id: root

    property var network: null
    readonly property bool active: network !== null && network !== undefined && network.status === "on"
    readonly property bool hovered: buttonSurface.hovered

    implicitWidth: 280
    implicitHeight: 34

    function toggleConnection() {
        if (!root.network || !root.network.name)
            return;
        Quickshell.execDetached([
            "nmcli", "--ask", "con",
            root.active ? "down" : "up",
            root.network.name
        ]);
    }

    Primitives.HoverButtonSurface {
        id: buttonSurface
        anchors.fill: parent
        backgroundColor: root.active ? Config.activeNetworkBackground : Config.transparent
        borderColor: Config.transparent
        borderWidth: 1
        hoverBorderEnabled: true
        hoverBorderColor: Config.accent
        hoverBorderWidth: 1
        cornerRadius: 7
        onClicked: root.toggleConnection()

        Row {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            Text {
                id: typeIcon
                width: 30
                height: parent.height
                text: root.network && root.network.type ? root.network.type : ""
                color: root.active ? Config.accent : Config.textDisabled
                font.pixelSize: Config.uiFontSize(21)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                width: Math.max(0, parent.width - typeIcon.width - parent.spacing)
                height: parent.height
                text: root.network && root.network.name ? root.network.name : ""
                color: root.active ? Config.textMuted : Config.textDisabled
                font.pixelSize: Config.uiFontSize(14)
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }
}

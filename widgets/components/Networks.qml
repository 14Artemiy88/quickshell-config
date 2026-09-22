import QtQuick
import ".."
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Frame {
    id: root
    width: 300
    height: 180
    property var monitor
    ScrollView {
        anchors.fill: parent
        clip: true
        Column {
            width: 280
            spacing: 5
            Repeater {
                model: root.monitor.data.network ?? []
                delegate: Rectangle {
                    width: 275; height: 34; radius: 7
                    color: modelData.status === "on" ? Config.activeNetworkBackground : Config.transparent
                    border.color: mouse.containsMouse ? Config.accent : Config.transparent
                    Row {
                        anchors.fill: parent
                        anchors.margins: 5
                        Text { width: 35; text: modelData.type; color: modelData.status === "on" ? Config.accent : Config.textDisabled; font.pixelSize: 21; verticalAlignment: Text.AlignVCenter; anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: -3 }
                        Text { width: 220; text: modelData.name; color: modelData.status === "on" ? Config.textMuted : Config.textDisabled; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; font.pixelSize: 14 }
                    }
                    MouseArea {
                        id: mouse; anchors.fill: parent; hoverEnabled: true
                        onClicked: Quickshell.execDetached(["nmcli", "--ask", "con", modelData.status === "on" ? "down" : "up", modelData.name])
                    }
                }
            }
        }
    }
}

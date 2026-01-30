import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common

Rectangle {
    anchors.left: parent.left

    anchors.top: parent.top
    anchors.topMargin: 10

    Rectangle {
        id: workspaceLayout
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
        }

        RowLayout {
            anchors {
                verticalCenter: parent.verticalCenter
            }
            spacing: 5

            Repeater {
                model: niri.workspaces

                Rectangle {
                    visible: index > 1 || model.isFocused
                    implicitWidth: 10

                    Text {
                        id: worspaceIndex
                        anchors {
                            verticalCenter: parent.verticalCenter
                        }
                        text: model.isActive ? "" : ""
                        color: model.isActive ? Config.accentColor : Config.nonAccentColor
                        font.pixelSize: 16
                        font.family: "JetBrainsMonoNF"
                        Component.onCompleted: {
                            parent.width = powerDisplay.contentWidth;
                        }
                    }
                }
            }
        }
    }
}

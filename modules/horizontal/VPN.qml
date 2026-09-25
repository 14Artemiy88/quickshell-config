import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.common

import "../../launcher/theme"

Item {
    Theme { id: theme }
    id: vpn

    anchors.top: parent.top
    anchors.topMargin: -2

    implicitWidth: 55
    implicitHeight: 22

    Column {
        id: mainCol
        width: parent.width

        // Кнопка-заголовок
        Rectangle {
            width: parent.width
            height: 22
            color: theme.transparent

            Text {
                anchors.centerIn: parent
                text: "  " + Network.vpnIsActive
                // color: theme.nonAccent
                font.pointSize: 10
                font.family: theme.fontFamily

                // Плавная анимация цвета
                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }

                color: {
                    return mouseHandler.containsMouse ? theme.textClipboard : theme.nonAccent;
                }
            }

            MouseArea {
                id: mouseHandler
                hoverEnabled: true
                anchors.fill: parent
                onClicked: Network.expanded = !Network.expanded
            }
        }
    }
}

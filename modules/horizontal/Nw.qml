import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.common

Item {
    id: root

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
            color: "#00000000"

            Text {
                anchors.centerIn: parent
                text: "  " + Network.activeNetwork
                // color: Config.nonAccentColor
                font.pointSize: 10
                font.family: Config.font

                // Плавная анимация цвета
                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }

                color: {
                    return mouseHandler.containsMouse ? "#dddddd" : Config.nonAccentColor;
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

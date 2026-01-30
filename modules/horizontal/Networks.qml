import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.modules.common

PanelWindow {
    id: networks

    readonly property var networkHeight: 24

    visible: Network.expanded
    // visible: true

    anchors {
        top: true
        right: true
    }

    margins {
        // top: Network.expanded ? -60 : 30
        top: 30
        right: 82
    }

    // Behavior on margins.top {
    //     NumberAnimation {
    //         duration: 250
    //         easing.type: Easing.OutQuart
    //     }
    // }

    exclusionMode: ExclusionMode.Normal
    implicitHeight: Network.networks.length * networkHeight + 10
    implicitWidth: 120
    color: "transparent"
    // color: "#00cccc"

    Rectangle {
        anchors {
            fill: parent
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 0
            leftMargin: 0
            rightMargin: 0
        }

        // color: "#cc181818"

        color: "transparent"
        radius: 5

        RowLayout {
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }

            // Список сетей
            Column {
                width: parent.width
                visible: Network.expanded
                // visible: true
                spacing: 2

                Repeater {
                    model: Network.networks

                    delegate: Rectangle {
                        implicitWidth: 100
                        implicitHeight: networkHeight

                        border.width: 1
                        border.color: "#666666"
                        radius: 5

                        // Плавная анимация цвета
                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }

                        // Определяем цвет фона в зависимости от состояния
                        color: {
                            return mouseHandler.containsMouse ? "#313244" : "#cc181818"; // Подсветка или обычный фон
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            spacing: 5

                            Text {
                                text: modelData.bars
                                color: modelData.inUse ? Config.accentColor : "#88ff88"
                                font.pointSize: 8
                            }

                            Text {
                                text: modelData.ssid
                                color: Config.nonAccentColor
                                font.pointSize: 10
                                font.family: Config.font
                                width: 80
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: mouseHandler
                            hoverEnabled: true
                            anchors.fill: parent
                            onClicked: {
                                Network.connectTo(modelData.ssid);
                                Network.refresh();
                                Network.expanded = false;
                            }
                        }
                    }
                }

                // Если после загрузки пусто
                Text {
                    visible: Network.networks.length === 0
                    text: "  Scanning..."
                    color: Config.nonAccentColor
                    font.pointSize: 8
                    font.family: Config.font
                    height: 22
                }
            }
        }
    }
}

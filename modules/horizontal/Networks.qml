import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.modules.common

import "../../launcher/theme"

PanelWindow {
    Theme { id: theme }
    id: networks

    readonly property var networkHeight: 24

    visible: Network.expanded

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
    color: theme.transparent
    // color: theme.accent

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

        color: theme.transparent
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
                        border.color: theme.borderStrong
                        radius: 5

                        // Плавная анимация цвета
                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }

                        // Определяем цвет фона в зависимости от состояния
                        color: {
                            return mouseHandler.containsMouse ? theme.hover : theme.barBackground; // Подсветка или обычный фон
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            spacing: 5

                            Text {
                                text: modelData.bars
                                color: modelData.inUse ? theme.accent : theme.networkSignal
                                font.pointSize: 8
                            }

                            Text {
                                text: modelData.ssid
                                color: theme.nonAccent
                                font.pointSize: 10
                                font.family: theme.fontFamily
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
                    color: theme.nonAccent
                    font.pointSize: 8
                    font.family: theme.fontFamily
                    height: 22
                }
            }
        }
    }
}

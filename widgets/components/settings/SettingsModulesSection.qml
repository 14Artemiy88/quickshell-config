import QtQuick
import QtQuick.Controls
import Quickshell
import "../.."

Item {
    id: modulesSection

    property var host: null
    property var settings: Settings

    function resetScroll() {
        modulesFlick.contentY = 0
    }
    visible: host && host.currentTab === 0
    width: parent ? parent.width : 0
    height: visible ? parent.height - y : 0

    Flickable {
        id: modulesFlick
        visible: host.currentTab === 0
        width: parent.width
        height: parent.height - y
        contentWidth: Math.max(width, modulesColumn.width)
        contentHeight: modulesColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.LeftButton
            onClicked: host.clearSettingsFocus()
        }
        ScrollBar.vertical: SettingsScrollBar { visible: modulesFlick.contentHeight > modulesFlick.height + 1 }

        Column {
            id: modulesColumn
            width: modulesFlick.width - 12
            spacing: 10

            Row {
                width: parent.width
                height: 32
                Text {
                    width: parent.width - 38
                    text: "Модули и их расположение"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(15)
                    verticalAlignment: Text.AlignVCenter
                }
                SettingsResetButton {
                    tooltip: "Сбросить модули"
                    onClicked: settings.resetModules()
                }
            }

            Row {
                width: parent.width
                height: 18
                spacing: 6

                Item { width: 110; height: 18 }

                Repeater {
                    model: ["X", "Y", "Width", "Height"]
                    delegate: Text {
                        width: 60
                        height: 18
                        text: modelData
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Text { width: 42; height: 18; text: "Рамка"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                Text { width: 42; height: 18; text: "Фон"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                Text { width: 42; height: 18; text: "Сброс"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }

            Repeater {
                model: settings.moduleNames

                delegate: Row {
                    id: moduleRow
                    width: parent.width
                    height: 30
                    spacing: 6
                    property string moduleName: modelData

                    SettingsCheckBox {
                        id: enabledBox
                        width: 110
                        height: 30
                        text: settings.moduleLabels[moduleRow.moduleName]
                        checked: settings[moduleRow.moduleName]
                        onToggled: {
                            settings[moduleRow.moduleName] = checked
                            settings.save()
                        }
                        contentItem: Text {
                            text: parent.text
                            color: Config.text
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(11)
                            leftPadding: parent.indicator.width + 5
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }

                    Repeater {
                        model: ["X", "Y", "Width", "Height"]

                        delegate: SettingsTextField {
                            id: geometryField
                            width: 60
                            height: 30
                            text: String(settings.geometry[moduleRow.moduleName][index])
                            color: Config.text
                            selectionColor: Config.accent
                            selectedTextColor: Config.black
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(10)
                            horizontalAlignment: Text.AlignHCenter
                            activeFocusOnTab: true
                            inputMethodHints: Qt.ImhDigitsOnly

                            background: Rectangle {
                                color: Config.settingsBackground
                                border.color: (geometryField.activeFocus || geometryField.pointerHovered) ? Config.accent : Config.baseColor
                                border.width: 1
                                radius: 4
                            }

                            onEditingFinished: {
                                var g = Object.assign({}, settings.geometry)
                                var a = (g[moduleRow.moduleName] || [0, 0, 100, 100]).slice()
                                var n = Number(text)
                                if (!isNaN(n)) {
                                    if (index >= 2) n = Math.max(1, n)
                                    a[index] = n
                                    g[moduleRow.moduleName] = a
                                    settings.geometry = g
                                    settings.save()
                                    text = String(n)
                                } else {
                                    text = String(settings.geometry[moduleRow.moduleName][index])
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton
                                        onWheel: wheel => {
                                    var delta = host.wheelDelta(wheel, 1)
                                    settings.adjustGeometry(moduleRow.moduleName, index, delta)
                                    geometryField.text = String(settings.geometry[moduleRow.moduleName][index])
                                    wheel.accepted = true
                                }
                            }

                            Connections {
                                target: settings
                                function onGeometryChanged() {
                                    geometryField.text = String(settings.geometry[moduleRow.moduleName][index])
                                }
                            }

                            ToolTip.visible: hovered
                            ToolTip.text: ["X", "Y", "Width", "Height"][index]
                            ToolTip.delay: 500
                        }
                    }

                    SettingsCheckBox {
                        id: frameBox
                        width: 42
                        height: 30
                        text: ""
                        indicatorOnly: true
                        checked: settings.moduleFrames[moduleRow.moduleName] !== false
                        onToggled: {
                            var values = Object.assign({}, settings.moduleFrames)
                            values[moduleRow.moduleName] = checked
                            settings.moduleFrames = values
                            settings.save()
                        }
                    }

                    SettingsCheckBox {
                        id: backgroundBox
                        width: 42
                        height: 30
                        text: ""
                        indicatorOnly: true
                        checked: settings.moduleBackgrounds[moduleRow.moduleName] !== false
                        onToggled: {
                            var values = Object.assign({}, settings.moduleBackgrounds)
                            values[moduleRow.moduleName] = checked
                            settings.moduleBackgrounds = values
                            settings.save()
                        }
                    }

                    SettingsResetButton {
                        width: 42
                        height: 30
                        tooltip: "Сбросить настройки модуля"
                        onClicked: settings.resetModule(moduleRow.moduleName)
                    }
                }
            }

            Item { width: 1; height: 4 }

            Row {
                width: parent.width
                height: 46
                spacing: 10

                Rectangle {
                    id: layoutEditButton
                    width: 270
                    height: 46
                    radius: Config.frameRadius
                    color: layoutEditMouse.containsMouse ? Config.accent : "transparent"
                    border.color: Config.accent
                    border.width: Math.max(1, Config.frameBorderWidth)

                    Text {
                        anchors.fill: parent
                        text: "УМНОЕ РЕДАКТИРОВАНИЕ"
                        color: layoutEditMouse.containsMouse ? Config.black : Config.accent
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: layoutEditMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: host.layoutEditRequested()
                    }
                }

                Text {
                    width: parent.width - 280
                    height: 46
                    text: "Скрывает окно настроек и позволяет перетаскивать видимые блоки мышью.\nEsc — завершить редактирование и вернуться сюда."
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}

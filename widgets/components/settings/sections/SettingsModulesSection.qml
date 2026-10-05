import QtQuick
import QtQuick.Controls
import Quickshell
import "../../.."
import "../primitives"

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
                    }

                    Repeater {
                        model: ["X", "Y", "Width", "Height"]

                        delegate: SettingsNumberField {
                            id: geometryField
                            width: 60
                            height: 30
                            value: Number(settings.geometry[moduleRow.moduleName][index])
                            minimum: index >= 2 ? 1 : -Infinity
                            maximum: Infinity
                            step: 1
                            wheelStep: 1
                            compact: true
                            fieldWidth: 60
                            fieldFontSize: 10
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            valueWriter: function(n) {
                                var g = Object.assign({}, settings.geometry)
                                var a = (g[moduleRow.moduleName] || [0, 0, 100, 100]).slice()
                                a[index] = n
                                g[moduleRow.moduleName] = a
                                settings.geometry = g
                                settings.save()
                            }
                            ToolTip.visible: geometryField.pointerHovered
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

                SettingsButton {
                    id: layoutEditButton
                    width: 270
                    height: 46
                    text: "УМНОЕ РЕДАКТИРОВАНИЕ"
                    fontSize: 11
                    fontBold: true
                    fillOnHover: true
                    borderOnHover: true
                    accentColor: Config.accent
                    backgroundColor: "transparent"
                    textColor: Config.accent
                    onClicked: host.layoutEditRequested()
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

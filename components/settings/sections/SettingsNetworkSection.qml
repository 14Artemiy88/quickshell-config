import QtQuick
import "../../.."
import "../primitives"

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentOtherTab === 6
    width: parent ? parent.width : 0
    spacing: 10

    SettingsGroup {
        visible: host && host.currentOtherTab === 6 && host.currentOtherSubTab === 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["systemMonitorInterval"] })
        padding: 8
        contentSpacing: 6

        Text {
            text: "Обновление данных"
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            width: parent.width
        }

        Row {
            width: parent.width
            height: 30
            spacing: 8

            Text {
                width: 210
                height: 30
                text: "Интервал обновления данных (мс)"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsNumberField {
                width: 100
                height: 30
                value: Config.systemMonitorInterval
                minimum: 200
                maximum: 10000
                step: 100
                wheelStep: 100
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "systemMonitorInterval"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
    }

    SettingsGroup {
        visible: host && host.currentOtherTab === 6 && host.currentOtherSubTab === 1
        width: parent.width
        showFrame: true
        heading: "Показ"
        changeKeys: ({ keys: ["networksAlwaysVisible"] })
        padding: 8
        contentSpacing: 6

        SettingsCheckBox {
            id: networksAlwaysVisibleCheck
            width: parent.width
            height: 30
            text: "Показывать Networks всегда"
            checked: Config.networksAlwaysVisible
            onToggled: {
                Config.networksAlwaysVisible = checked
                settings.save()
            }
            Connections {
                target: Config
                function onNetworksAlwaysVisibleChanged() {
                    networksAlwaysVisibleCheck.checked = Config.networksAlwaysVisible
                }
            }
        }
    }

    SettingsGroup {
        visible: host && host.currentOtherTab === 6 && host.currentOtherSubTab === 1
        width: parent.width
        showFrame: true
        heading: "Расположение"
        changeKeys: ({ keys: ["networkShowUpload", "networkShowDownload", "networkSpacing", "networkRightPadding", "networkTopPadding"] })
        padding: 8
        contentSpacing: 6

        Row {
            width: parent.width
            height: 30
            spacing: 8

            SettingsCheckBox {
                width: 145
                height: 30
                text: "Показывать Upload"
                checked: Config.networkShowUpload
                onToggled: {
                    Config.networkShowUpload = checked
                    settings.save()
                }
            }

            SettingsCheckBox {
                width: 150
                height: 30
                text: "Показывать Download"
                checked: Config.networkShowDownload
                onToggled: {
                    Config.networkShowDownload = checked
                    settings.save()
                }
            }
        }

        Row {
            width: parent.width
            height: 30
            spacing: 8

            Text {
                width: 210
                height: 30
                text: "Интервал строк"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsNumberField {
                width: 100
                height: 30
                value: Config.networkSpacing
                minimum: 0
                maximum: 20
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "networkSpacing"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        Row {
            width: parent.width
            height: 30
            spacing: 8

            Text {
                width: 210
                height: 30
                text: "Отступ сверху"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsNumberField {
                width: 100
                height: 30
                value: Config.networkTopPadding
                minimum: 0
                maximum: 40
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "networkTopPadding"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        Row {
            width: parent.width
            height: 30
            spacing: 8

            Text {
                width: 210
                height: 30
                text: "Отступ значений справа"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsNumberField {
                width: 100
                height: 30
                value: Config.networkRightPadding
                minimum: 0
                maximum: 40
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "networkRightPadding"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
    }

    SettingsGroup {
        visible: host && host.currentOtherTab === 6 && host.currentOtherSubTab === 1
        width: parent.width
        showFrame: true
        heading: "Иконки"
        changeKeys: ({ keys: ["networkIconLeftPadding", "networkIconSize"] })
        padding: 8
        contentSpacing: 6

        Row {
            width: parent.width
            height: 30
            spacing: 8

            Text {
                width: 210
                height: 30
                text: "Размер иконки"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsNumberField {
                width: 100
                height: 30
                value: Config.networkIconSize
                minimum: 8
                maximum: 40
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "networkIconSize"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        Row {
            width: parent.width
            height: 30
            spacing: 8

            Text {
                width: 210
                height: 30
                text: "Отступ иконки слева"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsNumberField {
                width: 100
                height: 30
                value: Config.networkIconLeftPadding
                minimum: 0
                maximum: 40
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "networkIconLeftPadding"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
    }

    SettingsGroup {
        visible: host && host.currentOtherTab === 6 && host.currentOtherSubTab === 1
        width: parent.width
        showFrame: true
        heading: "Текст"
        changeKeys: ({ keys: ["networkFont", "networkValueFontSize"] })
        padding: 8
        contentSpacing: 6

        SettingsFontField {
            width: parent.width
            height: 30
            label: "Семейство шрифта"
            labelWidth: 130
            fieldWidth: 160
            fieldFontSize: 11
            value: Config.networkFont
            targetObject: Config
            targetProperty: "networkFont"
            settingsObject: root.settings
            saveOnEdit: true
        }

        Row {
            width: parent.width
            height: 30
            spacing: 8

            Text {
                width: 210
                height: 30
                text: "Размер текста"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsNumberField {
                width: 100
                height: 30
                value: Config.networkValueFontSize
                minimum: 8
                maximum: 32
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "networkValueFontSize"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
    }
}

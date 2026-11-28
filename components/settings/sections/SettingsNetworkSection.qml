import QtQuick
import "../../.."
import "../primitives"

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentPageId === "network"
    width: parent ? parent.width : 0
    spacing: 10

    SettingsGroup {
                visible: host && host.currentPageId === "network" && host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["systemMonitorInterval"] })
        padding: 8
        contentSpacing: 6

        Text {
            text: "Обновление данных"
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(10)
            width: parent.width
        }

        SettingsRow {
            label: "Интервал обновления данных (мс)"
            labelWidth: 210
            width: parent.width
            height: 30
            spacing: 8

            

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
                visible: host && host.currentPageId === "network" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
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
                visible: host && host.currentPageId === "network" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
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

        SettingsRow {
            label: "Интервал строк"
            labelWidth: 210
            width: parent.width
            height: 30
            spacing: 8

            

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

        SettingsRow {
            label: "Отступ сверху"
            labelWidth: 210
            width: parent.width
            height: 30
            spacing: 8

            

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

        SettingsRow {
            label: "Отступ значений справа"
            labelWidth: 210
            width: parent.width
            height: 30
            spacing: 8

            

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
                visible: host && host.currentPageId === "network" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        heading: "Иконки"
        changeKeys: ({ keys: ["networkIconLeftPadding", "networkIconSize"] })
        padding: 8
        contentSpacing: 6

        SettingsRow {
            label: "Размер иконки"
            labelWidth: 210
            width: parent.width
            height: 30
            spacing: 8

            

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

        SettingsRow {
            label: "Отступ иконки слева"
            labelWidth: 210
            width: parent.width
            height: 30
            spacing: 8

            

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
                visible: host && host.currentPageId === "network" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
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

        SettingsRow {
            label: "Размер текста"
            labelWidth: 210
            width: parent.width
            height: 30
            spacing: 8

            

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

    SettingsAnimationGroup {
        visible: root.host && root.host.currentPageId === "network" && root.host.currentPageSubTabIndex === 2
        width: root.width
        settings: root.settings
        heading: "Внутренние переходы Networks"
        changeKeys: ({ keys: ["animationNetworkMorphDuration", "animationNetworkMorphProfile"] })
        duration: Config.animationNetworkMorphDuration
        profile: Config.animationNetworkMorphProfile

        onDurationEdited: function(value) {
            Config.animationNetworkMorphDuration = value
            root.settings.save()
        }
        onProfileEdited: function(value) {
            Config.animationNetworkMorphProfile = value
            root.settings.save()
        }

        SettingsGroup {
            visible: Config.settingsShowDescriptions
            width: parent.width
            showFrame: true
            heading: "Что управляется"
            padding: 8
            contentSpacing: 4
            SettingsDescription {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Настройки влияют на появление и удаление строк подключений, перестройку списка и изменение высоты панели Networks. Анимация появления самого модуля остаётся независимой."
                color: Config.textMuted
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(10)
            }
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageId === "network"
            && root.host.currentPageSubTabIndex === 2 && !Config.networksAlwaysVisible
        width: root.width
        showFrame: true
        heading: "Появление модуля"
        changeKeys: ({ keys: ["animationNetworkVisibilityStyle", "animationNetworkVisibilityProfile", "animationNetworkVisibilityDuration"] })
        padding: 8
        contentSpacing: 6

        SettingsRow {
            label: "Стиль"
            labelWidth: 210
            width: parent.width
            height: 30
            spacing: 8

            SettingsComboBox {
                id: networkVisibilityStyleBox
                width: 180
                height: 30
                property var values: ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
                model: ["Нет", "Плавное затухание", "Слева", "Справа", "Сверху", "Снизу"]
                currentIndex: Math.max(0, values.indexOf(Config.animationNetworkVisibilityStyle))
                onItemChosen: function(index) {
                    if (index < 0 || index >= values.length) return
                    Config.animationNetworkVisibilityStyle = values[index]
                    root.settings.save()
                }
                Connections {
                    target: Config
                    function onAnimationNetworkVisibilityStyleChanged() {
                        networkVisibilityStyleBox.currentIndex = Math.max(0, networkVisibilityStyleBox.values.indexOf(Config.animationNetworkVisibilityStyle))
                    }
                }
                background: Rectangle {
                    color: "transparent"
                    border.color: (networkVisibilityStyleBox.activeFocus || networkVisibilityStyleBox.pointerHovered) ? Config.accent : Config.baseColor
                    border.width: (Config.inputBordersEnabled || networkVisibilityStyleBox.activeFocus) ? 1 : 0
                    radius: Config.scaledCornerRadius(Config.settingsUiSize(4))
                }
                contentItem: Text {
                    text: networkVisibilityStyleBox.currentText
                    color: Config.text
                    font.family: Config.settingsFontFamily
                    font.pixelSize: Config.settingsUiSize(11)
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 8
                }
            }
        }

        SettingsAnimationCurveControl {
            profile: Config.animationNetworkVisibilityProfile
            searchId: "network-visibility-animation-curve"
            searchLabel: "CSS-кривая появления Networks"
            searchKeywords: "сеть networks модуль появление закрытие bezier"
            onProfileEdited: function(value) {
                Config.animationNetworkVisibilityProfile = value
                root.settings.save()
            }
        }

        SettingsRow {
            label: "Длительность (мс)"
            labelWidth: 210
            width: parent.width
            height: 30
            spacing: 8

            SettingsNumberField {
                width: 100
                height: 30
                value: Config.animationNetworkVisibilityDuration
                minimum: 0
                maximum: 5000
                step: 50
                wheelStep: 50
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "animationNetworkVisibilityDuration"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
    }
}

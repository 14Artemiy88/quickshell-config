import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"
import "../../primitives"

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentPageId === "cava"
    width: parent ? parent.width : 0
    spacing: 10
    SettingsGroup {
                visible: host && host.currentPageId === "cava" && host.currentPageSubTabIndex === 0
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["cavaFramerate", "cavaHideWhenSilent", "cavaHideZeroBars", "cavaMode"] })
        padding: 8
        contentSpacing: 6

        SettingsRow {
            label: "Режим CAVA"
            labelWidth: 210
            visible: host.currentPageId === "cava" && host.currentPageSubTabIndex === 0
            width: parent.width
            height: 30
            spacing: 8

            

                SettingsComboBox {
                id: cavaModeCombo
                width: 100
                height: 30
                model: ["Обе половины", "Только верхние", "Только нижние"]
                currentIndex: ["both", "top", "bottom"].indexOf(Config.cavaMode) >= 0 ? ["both", "top", "bottom"].indexOf(Config.cavaMode) : 0
                onItemChosen: index => {
                    Config.cavaMode = ["both", "top", "bottom"][index]
                    settings.save()
                }
            }

        }

        SettingsRow {
            label: "Скрывать полоски без звука"
            labelWidth: 210
            visible: host.currentPageId === "cava" && host.currentPageSubTabIndex === 0
            width: parent.width
            height: 30
            spacing: 8

            

            SettingsCheckBox {
                id: cavaHideWhenSilentCheckBox
                width: 58
                height: 30
                indicatorOnly: true
                checked: Config.cavaHideWhenSilent
                onToggled: {
                    Config.cavaHideWhenSilent = checked
                    settings.save()
                }
                Connections {
                    target: Config
                    function onCavaHideWhenSilentChanged() { cavaHideWhenSilentCheckBox.checked = Config.cavaHideWhenSilent }
                }
            }
        }

        MorphGeometry {
            id: cavaHideZeroBarsMorph
            width: parent.width
            enabled: Config.cavaHideWhenSilent
            clip: true
            visible: Config.cavaHideWhenSilent || normalizedProgress > 0.001
            fromGeometry: Qt.rect(0, 0, parent.width, 0)
            toGeometry: Qt.rect(0, 0, parent.width, cavaHideZeroBarsContent.implicitHeight)
            progress: Config.cavaHideWhenSilent ? 1 : 0
            animationDuration: Config.animationDuration(180, "appearance")
            animationEasing: Config.animationEasingType("ease-out", Config.cavaHideWhenSilent ? "enter" : "exit")

            SettingsRow {
                id: cavaHideZeroBarsContent
                label: "Скрывать пустые полоски"
                labelWidth: 210
                width: parent.width
                height: 30
                spacing: 8

                

                SettingsCheckBox {
                    id: cavaHideZeroBarsCheckBox
                    width: 58
                    height: 30
                    indicatorOnly: true
                    checked: Config.cavaHideZeroBars
                    onToggled: {
                        Config.cavaHideZeroBars = checked
                        settings.save()
                    }
                    Connections {
                        target: Config
                        function onCavaHideZeroBarsChanged() { cavaHideZeroBarsCheckBox.checked = Config.cavaHideZeroBars }
                    }
                }
            }
        }



        SettingsRow {
            id: cavaFramerateField
            label: "Частота обновления CAVA (FPS)"
            labelWidth: 210
            visible: host.currentPageId === "cava" && host.currentPageSubTabIndex === 0
            width: parent.width
            height: 30
            spacing: 8

            

            SettingsNumberField {
            width: 100
            height: 30
            value: Config.cavaFramerate
            minimum: 1
            maximum: 120
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "cavaFramerate"
            settingsObject: root.settings
            saveOnEdit: true
        }
        }
    }

    SettingsGroup {
                visible: host && host.currentPageId === "cava" && host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["cavaBars", "cavaBarWidthRatio", "cavaRowSpacing"] })
        padding: 8
        contentSpacing: 6

        SettingsRow {
            id: cavaBarsField
            label: "Количество полос CAVA"
            labelWidth: 210
            visible: host.currentPageId === "cava" && host.currentPageSubTabIndex === 1
            width: parent.width
            height: 30
            spacing: 8

            

            SettingsNumberField {
            width: 100
            height: 30
            value: Config.cavaBars
            minimum: 8
            maximum: 120
            step: 1
            wheelStep: 1
            decimals: 0
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhDigitsOnly
            targetObject: Config
            targetProperty: "cavaBars"
            settingsObject: root.settings
            saveOnEdit: true
        }
        }

        SettingsRow {
            id: cavaRowSpacingField
            label: "Зазор между слотами CAVA"
            labelWidth: 210
            visible: host.currentPageId === "cava" && host.currentPageSubTabIndex === 1; width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
            width: 100
            height: 30
            value: Config.cavaRowSpacing
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
            targetProperty: "cavaRowSpacing"
            settingsObject: root.settings
            saveOnEdit: true
        }
        }
        SettingsRow {
            id: cavaBarWidthRatioField
            label: "Ширина полоски (% слота)"
            labelWidth: 210
            visible: host.currentPageId === "cava" && host.currentPageSubTabIndex === 1; width: parent.width; height: 30; spacing: 8
            
            SettingsNumberField {
            width: 100
            height: 30
            value: Config.cavaBarWidthRatio
            minimum: 0.05
            maximum: 1
            step: 0.05
            wheelStep: 0.05
            decimals: 2
            compact: true
            fieldWidth: 100
            fieldFontSize: 11
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            targetObject: Config
            targetProperty: "cavaBarWidthRatio"
            settingsObject: root.settings
            saveOnEdit: true
        }
        }
    }

    SettingsAnimationGroup {
        visible: host && host.currentPageId === "cava" && host.currentPageSubTabIndex === 2
        width: root.width
        settings: root.settings
        heading: "Внутренние переходы CAVA"
        changeKeys: ({ keys: ["animationCavaMorphDuration", "animationCavaMorphProfile"] })
        duration: Config.animationCavaMorphDuration
        profile: Config.animationCavaMorphProfile

        onDurationEdited: function(value) {
            Config.animationCavaMorphDuration = value
            root.settings.save()
        }
        onProfileEdited: function(value) {
            Config.animationCavaMorphProfile = value
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
                text: "Профиль и длительность управляют плавным появлением и скрытием графика при обнаружении или потере звука. Эффект используется, когда включено «Скрывать полоски без звука». Анимация появления самого модуля остаётся независимой."
                color: Config.textMuted
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.settingsUiSize(10)
            }
        }
    }
}

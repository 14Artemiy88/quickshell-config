import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"

Column {
    id: settingsWindowColumn
    property var host
    property var settings: Settings

    width: parent ? parent.width : 0
    spacing: 10

                    Text {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 0
                        text: "Настройки интерфейса настроек"
                        color: Config.accent
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(14)
                    }

                    Text {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 0
                        text: "Отдельный шрифт, размер текста и внутренние отступы самого окна настроек."
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    Row {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 0
                        width: parent.width
                        height: 34
                        spacing: 8
                        Text { width: 210; text: "Шрифт настроек"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                        SettingsTextField {
                            id: settingsFontField
                            width: 160; height: 30
                            text: Config.settingsFont
                            color: Config.text; selectionColor: Config.accent; selectedTextColor: Config.black
                            font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                            activeFocusOnTab: true
                            background: Rectangle { color: Config.settingsBackground; border.color: (settingsFontField.activeFocus || settingsFontField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                            onEditingFinished: { Config.settingsFont = text.trim() || Config.settingsFont; text = Config.settingsFont; settings.save() }
                            Connections { target: Config; function onSettingsFontChanged() { settingsFontField.text = Config.settingsFont } }
                        }
                    }

                    Row {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 0
                        width: parent.width
                        height: 34
                        spacing: 8
                        Text { width: 210; text: "Размер шрифта настроек"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                        SettingsNumberField {
    id: settingsFontSizeField
    width: 100
    height: 30
    value: Config.settingsFontSize
    minimum: 6
    maximum: 32
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "settingsFontSize"
    settingsObject: root.settings
    saveOnEdit: true
}
                    }

                    Row {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 0
                        width: parent.width
                        height: 34
                        spacing: 8
                        Text { width: 210; text: "Внутренний отступ"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                        SettingsNumberField {
    id: settingsPaddingField
    width: 100
    height: 30
    value: Config.settingsPadding
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
    targetProperty: "settingsPadding"
    settingsObject: root.settings
    saveOnEdit: true
}
                    }

                    Row {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 0
                        width: parent.width
                        height: 34
                        spacing: 8
                        Text { width: 210; text: "Расстояние между элементами"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                        SettingsNumberField {
    id: settingsSpacingField
    width: 100
    height: 30
    value: Config.settingsSpacing
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
    targetProperty: "settingsSpacing"
    settingsObject: root.settings
    saveOnEdit: true
}
                    }

                    Text {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 1
                        text: "Окно настроек"
                        color: Config.accent
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(14)
                    }

                    Text {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 1
                        text: "Координаты и размеры окна настроек"
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                    }

                    Row {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 1
                        width: parent.width
                        height: 18
                        spacing: 6

                        Item { width: 0; height: 18 }

                        Repeater {
                            model: ["X", "Y", "Width", "Height"]
                            delegate: Text {
                                width: 76
                                height: 18
                                text: modelData
                                color: Config.textMuted
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(10)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    Row {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 1
                        width: parent.width
                        height: 30
                        spacing: 6

                        Repeater {
                            model: [0, 1, 2, 3]
                            delegate: SettingsNumberField {
                                id: settingsGeometryField
                                width: 76
                                height: 30
                                property int fieldIndex: modelData
                                value: Number(settings.settingsGeometry[fieldIndex])
                                minimum: fieldIndex === 2 ? 320 : fieldIndex === 3 ? 240 : -Infinity
                                maximum: Infinity
                                step: 1
                                wheelStep: 1
                                compact: true
                                fieldWidth: 76
                                fieldFontSize: 10
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                valueWriter: function(n) {
                                    var a = (settings.settingsGeometry || [640, 40, 560, 850]).slice()
                                    a[fieldIndex] = Math.round(n)
                                    settings.settingsGeometry = a
                                    settings.save()
                                }
                                ToolTip.visible: settingsGeometryField.pointerHovered
                                ToolTip.text: ["X", "Y", "Width", "Height"][fieldIndex]
                                ToolTip.delay: 500
                            }
                        }
                    }

                    Text {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 1
                        text: "Изменения применяются и сохраняются сразу. Для X/Y/Width/Height можно использовать колесо мыши с шагом 1."
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(9)
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    Text {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 2
                        text: "Профили"
                        color: Config.accent
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(14)
                    }

                    Text {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 2
                        text: "Сохраняй несколько вариантов всей конфигурации и переключайся между ними без ручной перенастройки."
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    Row {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 2
                        width: parent.width
                        height: 30
                        spacing: 8

                        Text {
                            width: 120
                            height: 30
                            text: "Имя профиля"
                            color: Config.text
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(11)
                            verticalAlignment: Text.AlignVCenter
                        }

                        SettingsTextField {
                            id: profileNameField
                            width: 180
                            height: 30
                            placeholderText: "Имя профиля"
                            text: settings.activeProfile
                            color: Config.text
                            selectionColor: Config.accent
                            selectedTextColor: Config.black
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(11)
                            activeFocusOnTab: true
                            background: Rectangle {
                                color: Config.settingsBackground
                                border.color: profileNameSavedFeedback.running || profileNameSavedFeedback.paused
                                    ? Config.accent
                                    : ((profileNameField.activeFocus || profileNameField.pointerHovered) ? Config.accent : Config.baseColor)
                                border.width: 1
                                radius: 4
                            }

                            SequentialAnimation {
                                id: profileNameSavedFeedback
                                PropertyAnimation {
                                    target: profileSavedMark
                                    property: "opacity"
                                    to: 1
                                    duration: Config.animationDuration(90, "appearance")
                                    easing.type: Config.easingType()
                                }
                                PauseAnimation { duration: Config.animationDuration(550, "appearance") }
                                PropertyAnimation {
                                    target: profileSavedMark
                                    property: "opacity"
                                    to: 0
                                    duration: Config.animationDuration(260, "appearance")
                                    easing.type: Config.easingType()
                                }
                            }

                            onAccepted: {
                                if (settings.saveProfile(text))
                                    profileNameSavedFeedback.restart()
                                host.clearSettingsFocus()
                            }
                        }

                        Text {
                            id: profileSavedMark
                            width: 75
                            height: 28
                            text: "✓ сохранено"
                            color: Config.accent
                            opacity: 0
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(9)
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                        }
                    }

                    Row {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 2
                        width: parent.width
                        height: 30
                        spacing: 8

                        Text {
                            width: 120
                            height: 30
                            text: "Активный профиль"
                            color: Config.text
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(11)
                            verticalAlignment: Text.AlignVCenter
                        }

                        SettingsComboBox {
                            id: profileCombo
                            width: 150
                            height: 30
                            model: profileModel
                            textRole: "name"
                            valueRole: "name"
                            displayText: currentIndex >= 0 ? currentText : "Профили не созданы"
                            contentItem: Text {
                                text: profileCombo.displayText
                                color: Config.text
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(11)
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 10
                                elide: Text.ElideRight
                            }
                            background: Rectangle {
                                color: Config.settingsBackground
                                border.color: (profileCombo.activeFocus || profileCombo.pointerHovered) ? Config.accent : Config.baseColor
                                border.width: 1
                                radius: Config.frameRadius
                            }
                            currentIndex: {
                                var names = settings.profileNames()
                                var idx = names.indexOf(settings.activeProfile)
                                return idx >= 0 ? idx : -1
                            }
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(11)
                        }

                        SettingsButton {
                            width: 85
                            height: 30
                            text: "Загрузить"
                            fontSize: 10
                            enabled: profileCombo.currentIndex >= 0 && profileCombo.currentText.length > 0
                            fillOnHover: true
                            borderOnHover: true
                            accentColor: Config.accent
                            backgroundColor: "transparent"
                            textColor: Config.accent
                            onClicked: {
                                if (settings.loadProfile(profileCombo.currentText))
                                    profileActionFeedback.showMessage("✓ профиль загружен")
                            }
                        }

                        SettingsButton {
                            width: 85
                            height: 30
                            text: "Удалить"
                            fontSize: 10
                            enabled: profileCombo.currentIndex >= 0 && profileCombo.currentText.length > 0
                            fillOnHover: true
                            borderOnHover: true
                            accentColor: Config.accent
                            backgroundColor: "transparent"
                            textColor: Config.accent
                            onClicked: {
                                if (settings.deleteProfile(profileCombo.currentText))
                                    profileActionFeedback.showMessage("✓ профиль удалён")
                            }
                        }
                    }

                    Item {
                        id: profileActionFeedback
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 2
                        width: parent.width
                        height: 22

                        property string message: ""

                        function showMessage(value) {
                            message = value
                            feedbackAnimation.restart()
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.message
                            color: Config.accent
                            opacity: parent.message.length > 0 ? 1 : 0
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(9)
                        }

                        SequentialAnimation {
                            id: feedbackAnimation
                            PauseAnimation { duration: 900 }
                            PropertyAction { target: profileActionFeedback; property: "message"; value: "" }
                        }
                    }

                    Text {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 2
                        width: parent.width
                        text: settings.activeProfile ? "Текущий профиль: " + settings.activeProfile : "Текущий профиль: по умолчанию"
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(10)
                    }

                    Row {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 2
                        width: parent.width
                        height: 30
                        spacing: 8
                        Text {
                            width: parent.width - 38
                            text: "Сбросить все настройки"
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(10)
                            verticalAlignment: Text.AlignVCenter
                        }
                        SettingsResetButton {
                            tooltip: "Сбросить все параметры"
                            onClicked: settings.resetAllSettings()
                        }
                    }

                    Row {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 3
                        width: parent.width
                        height: 46
                        spacing: 10

                        SettingsButton {
                            id: settingsMoveButton
                            width: 270
                            height: 46
                            text: "УМНОЕ ПЕРЕМЕЩЕНИЕ"
                            fontSize: 11
                            fontBold: true
                            fillOnHover: true
                            borderOnHover: true
                            accentColor: Config.accent
                            backgroundColor: "transparent"
                            textColor: Config.accent
                            onClicked: host.settingsMoveRequested()
                        }
                        Text {
                            width: parent.width - 280
                            height: 46
                            text: "Скрывает окно настроек и позволяет перемещать его мышью.\nEsc — завершить перемещение и вернуться сюда."
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: Config.settingsUiSize(10)
                            wrapMode: Text.WordWrap
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

}

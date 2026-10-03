import QtQuick
import QtQuick.Controls
import "../.."

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
                        SettingsTextField {
                            id: settingsFontSizeField
                            width: 100; height: 30
                            text: String(Config.settingsFontSize)
                            color: Config.text; selectionColor: Config.accent; selectedTextColor: Config.black
                            font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                            horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
                            background: Rectangle { color: Config.settingsBackground; border.color: (settingsFontSizeField.activeFocus || settingsFontSizeField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.settingsFontSize; n=Math.max(6,Math.min(32,Math.round(n))); Config.settingsFontSize=n; text=String(n); settings.save() }
                            onEditingFinished: applyValue(text)
                            MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ settingsFontSizeField.applyValue(Config.settingsFontSize+host.wheelDelta(wheel, 1)); wheel.accepted=true } }
                            Connections { target: Config; function onSettingsFontSizeChanged() { settingsFontSizeField.text = String(Config.settingsFontSize) } }
                        }
                    }

                    Row {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 0
                        width: parent.width
                        height: 34
                        spacing: 8
                        Text { width: 210; text: "Внутренний отступ"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                        SettingsTextField {
                            id: settingsPaddingField
                            width: 100; height: 30
                            text: String(Config.settingsPadding)
                            color: Config.text; selectionColor: Config.accent; selectedTextColor: Config.black
                            font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                            horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
                            background: Rectangle { color: Config.settingsBackground; border.color: (settingsPaddingField.activeFocus || settingsPaddingField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.settingsPadding; n=Math.max(0,Math.min(40,Math.round(n))); Config.settingsPadding=n; text=String(n); settings.save() }
                            onEditingFinished: applyValue(text)
                            MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ settingsPaddingField.applyValue(Config.settingsPadding+host.wheelDelta(wheel, 1)); wheel.accepted=true } }
                            Connections { target: Config; function onSettingsPaddingChanged() { settingsPaddingField.text = String(Config.settingsPadding) } }
                        }
                    }

                    Row {
                        visible: host.currentOtherTab === 9 && host.currentOtherSubTab === 0
                        width: parent.width
                        height: 34
                        spacing: 8
                        Text { width: 210; text: "Расстояние между элементами"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                        SettingsTextField {
                            id: settingsSpacingField
                            width: 100; height: 30
                            text: String(Config.settingsSpacing)
                            color: Config.text; selectionColor: Config.accent; selectedTextColor: Config.black
                            font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11)
                            horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly
                            background: Rectangle { color: Config.settingsBackground; border.color: (settingsSpacingField.activeFocus || settingsSpacingField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                            function applyValue(v) { var n=Number(v); if(!isFinite(n)) n=Config.settingsSpacing; n=Math.max(0,Math.min(40,Math.round(n))); Config.settingsSpacing=n; text=String(n); settings.save() }
                            onEditingFinished: applyValue(text)
                            MouseArea { anchors.fill: parent; acceptedButtons: Qt.NoButton; onWheel: wheel=>{ settingsSpacingField.applyValue(Config.settingsSpacing+host.wheelDelta(wheel, 1)); wheel.accepted=true } }
                            Connections { target: Config; function onSettingsSpacingChanged() { settingsSpacingField.text = String(Config.settingsSpacing) } }
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
                            delegate: SettingsTextField {
                                id: settingsGeometryField
                                width: 76
                                height: 30
                                property int fieldIndex: modelData
                                text: String(settings.settingsGeometry[fieldIndex])
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
                                    border.color: (settingsGeometryField.activeFocus || settingsGeometryField.pointerHovered) ? Config.accent : Config.baseColor
                                    border.width: 1
                                    radius: 4
                                }
                                onEditingFinished: {
                                    var a = (settings.settingsGeometry || [640, 40, 560, 850]).slice()
                                    var n = Number(text)
                                    if (!isNaN(n)) {
                                        if (fieldIndex === 2) n = Math.max(320, Math.round(n))
                                        if (fieldIndex === 3) n = Math.max(240, Math.round(n))
                                        a[fieldIndex] = Math.round(n)
                                        settings.settingsGeometry = a
                                        settings.save()
                                        text = String(a[fieldIndex])
                                    } else {
                                        text = String(settings.settingsGeometry[fieldIndex])
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.NoButton
                                    onWheel: wheel => {
                                        settings.adjustSettingsGeometry(settingsGeometryField.fieldIndex, host.wheelDelta(wheel, 1))
                                        settingsGeometryField.text = String(settings.settingsGeometry[settingsGeometryField.fieldIndex])
                                        wheel.accepted = true
                                    }
                                }
                                Connections {
                                    target: settings
                                    function onSettingsGeometryChanged() {
                                        settingsGeometryField.text = String(settings.settingsGeometry[settingsGeometryField.fieldIndex])
                                    }
                                }
                                ToolTip.visible: hovered
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

                        Button {
                            width: 85
                            height: 30
                            text: "Загрузить"
                            enabled: profileCombo.currentIndex >= 0 && profileCombo.currentText.length > 0
                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? (parent.hovered ? Config.black : Config.accent) : Config.textMuted
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(10)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.enabled && parent.hovered ? Config.accent : "transparent"
                                border.color: parent.enabled ? Config.accent : Config.baseColor
                                border.width: 1
                                radius: Config.radius
                            }
                            onClicked: {
                                if (settings.loadProfile(profileCombo.currentText))
                                    profileActionFeedback.showMessage("✓ профиль загружен")
                            }
                        }

                        Button {
                            width: 85
                            height: 30
                            text: "Удалить"
                            enabled: profileCombo.currentIndex >= 0 && profileCombo.currentText.length > 0
                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? (parent.hovered ? Config.black : Config.accent) : Config.textMuted
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(10)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.enabled && parent.hovered ? Config.accent : "transparent"
                                border.color: parent.enabled ? Config.accent : Config.baseColor
                                border.width: 1
                                radius: Config.radius
                            }
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

                        Rectangle {
                            id: settingsMoveButton
                            width: 270
                            height: 46
                            radius: Config.frameRadius
                            color: settingsMoveMouse.containsMouse ? Config.accent : "transparent"
                            border.color: Config.accent
                            border.width: Math.max(1, Config.frameBorderWidth)

                            Text {
                                anchors.fill: parent
                                text: "УМНОЕ ПЕРЕМЕЩЕНИЕ"
                                color: settingsMoveMouse.containsMouse ? Config.black : Config.accent
                                font.family: Config.settingsFont
                                font.pixelSize: Config.settingsUiSize(11)
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                id: settingsMoveMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: host.settingsMoveRequested()
                            }
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

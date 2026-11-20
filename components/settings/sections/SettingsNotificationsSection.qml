import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentPageId === "notifications"
    width: parent ? parent.width : 0
    spacing: 10

    SettingsGroup {
        visible: root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 0
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsDefaultTimeout", "notificationsCriticalTimeout"] })
        heading: "Тайм-ауты"
        padding: 8
        contentSpacing: 6

        Text {
            width: parent.width
            text: "Сервер уведомлений работает, пока модуль включён в разделе «Модули». Здесь настраиваются тайм-ауты и содержимое карточек."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
        }

        Text {
            width: parent.width
            text: "Время указывается в секундах. Значение 0 отключает автоматическое закрытие. Явный тайм-аут, переданный приложением, имеет приоритет."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
        }

        Row {
            width: parent.width
            height: 30
            spacing: 8
            Text {
                width: 220
                height: 30
                text: "Обычные уведомления (с)"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            SettingsNumberField {
                width: 100
                height: 30
                value: Math.round(Config.notificationsDefaultTimeout / 1000)
                minimum: 0
                maximum: 120
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                onValueEdited: value => {
                    Config.notificationsDefaultTimeout = Math.round(value * 1000)
                    root.settings.save()
                }
            }
        }

        Row {
            width: parent.width
            height: 30
            spacing: 8
            Text {
                width: 220
                height: 30
                text: "Критические уведомления (с)"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            SettingsNumberField {
                width: 100
                height: 30
                value: Math.round(Config.notificationsCriticalTimeout / 1000)
                minimum: 0
                maximum: 120
                step: 1
                wheelStep: 1
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                onValueEdited: value => {
                    Config.notificationsCriticalTimeout = Math.round(value * 1000)
                    root.settings.save()
                }
            }
        }

        Text {
            width: parent.width
            text: "По умолчанию критические уведомления не закрываются автоматически."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsCardSpacing", "notificationsImageHeight", "notificationsShowAppIcon", "notificationsShowBodyImages", "notificationsShowProgress"] })
        heading: "Интервалы и изображения"
        padding: 8
        contentSpacing: 6

        Row {
            width: parent.width
            height: 30
            spacing: 8
            Text { width: 220; height: 30; text: "Расстояние между карточками"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
            SettingsNumberField {
                value: Config.notificationsCardSpacing
                minimum: 0
                maximum: 32
                step: 1
                wheelStep: 1
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                targetObject: Config
                targetProperty: "notificationsCardSpacing"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        Row {
            width: parent.width
            height: 30
            spacing: 8
            Text { width: 220; height: 30; text: "Максимальная высота превью"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
            SettingsNumberField {
                value: Config.notificationsImageHeight
                minimum: 0
                maximum: 320
                step: 8
                wheelStep: 8
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                targetObject: Config
                targetProperty: "notificationsImageHeight"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsShowAppIcon", "notificationsShowBodyImages", "notificationsShowProgress"] })
        heading: "Элементы карточки"
        padding: 8
        contentSpacing: 4

        SettingsCheckBox {
            id: notificationsShowAppIconCheck
            width: parent.width
            height: 28
            text: "Показывать иконку приложения"
            checked: Config.notificationsShowAppIcon
            onToggled: { Config.notificationsShowAppIcon = checked; root.settings.save() }
            Connections { target: Config; function onNotificationsShowAppIconChanged() { notificationsShowAppIconCheck.checked = Config.notificationsShowAppIcon } }
        }
        SettingsCheckBox {
            id: notificationsShowBodyImagesCheck
            width: parent.width
            height: 28
            text: "Показывать изображения в сообщениях"
            checked: Config.notificationsShowBodyImages
            onToggled: { Config.notificationsShowBodyImages = checked; root.settings.save() }
            Connections { target: Config; function onNotificationsShowBodyImagesChanged() { notificationsShowBodyImagesCheck.checked = Config.notificationsShowBodyImages } }
        }
        SettingsCheckBox {
            id: notificationsShowProgressCheck
            width: parent.width
            height: 28
            text: "Показывать индикатор прогресса"
            checked: Config.notificationsShowProgress
            onToggled: { Config.notificationsShowProgress = checked; root.settings.save() }
            Connections { target: Config; function onNotificationsShowProgressChanged() { notificationsShowProgressCheck.checked = Config.notificationsShowProgress } }
        }
    }
    SettingsGroup {
        visible: root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 2
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsVerticalAnchor"] })
        heading: "Расположение"
        padding: 8
        contentSpacing: 6

        Text {
            width: parent.width
            text: "Уведомления можно привязать к верхнему или нижнему краю выбранного монитора. Горизонтальная координата X всегда отсчитывается слева."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
            wrapMode: Text.WordWrap
        }

        Row {
            width: parent.width
            height: 30
            spacing: 8

            Text {
                width: 220
                height: 30
                text: "Вертикальная привязка"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            SettingsComboBox {
                id: notificationsVerticalAnchorCombo
                width: 140
                height: 30
                model: ["Сверху", "Снизу"]
                currentIndex: Config.notificationsVerticalAnchor === "bottom" ? 1 : 0
                onItemChosen: index => root.settings.setNotificationsVerticalAnchor(index === 1 ? "bottom" : "top")
            }
        }
    }

    SettingsAnimationGroup {
        visible: root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 3
        width: parent.width
        settings: root.settings
        heading: "Переходы карточек уведомлений"
        detailsHeading: "Параметры переходов"
        changeKeys: ({ keys: ["animationNotificationsMorphDuration", "animationNotificationsMorphProfile", "animationNotificationsVisibilityStyle"] })
        duration: Config.animationNotificationsMorphDuration
        durationLabel: "Длительность (мс)"
        minimumDuration: 0
        maximumDuration: 2000
        durationStep: 10
        profile: Config.animationNotificationsMorphProfile
        onDurationEdited: value => {
            Config.animationNotificationsMorphDuration = Math.max(0, Math.min(2000, Math.round(Number(value) || 0)))
            root.settings.save()
        }
        onProfileEdited: value => {
            Config.animationNotificationsMorphProfile = value
            root.settings.save()
        }

        SettingsGroup {
            width: parent.width
            showFrame: true
            heading: "Вид появления и исчезновения"
            changeKeys: ({ keys: ["animationNotificationsVisibilityStyle"] })
            padding: 8
            contentSpacing: 6

            Row {
                width: parent.width
                height: 30
                spacing: 8

                Text {
                    width: 210
                    height: 30
                    text: "Направление движения"
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                SettingsComboBox {
                    id: notificationVisibilityStyleBox
                    width: 180
                    height: 30
                    property var values: ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
                    model: ["Нет", "Плавное затухание", "Слева", "Справа", "Сверху", "Снизу"]
                    currentIndex: Math.max(0, values.indexOf(Config.animationNotificationsVisibilityStyle))
                    onItemChosen: function(index) {
                        if (index >= 0 && index < values.length) {
                            Config.animationNotificationsVisibilityStyle = values[index]
                            root.settings.save()
                        }
                    }
                    Connections {
                        target: Config
                        function onAnimationNotificationsVisibilityStyleChanged() {
                            notificationVisibilityStyleBox.currentIndex = Math.max(0, notificationVisibilityStyleBox.values.indexOf(Config.animationNotificationsVisibilityStyle))
                        }
                    }
                    background: Rectangle {
                        color: Config.settingsBackground
                        border.color: (notificationVisibilityStyleBox.activeFocus || notificationVisibilityStyleBox.pointerHovered) ? Config.accent : Config.baseColor
                        border.width: 1
                        radius: 4
                    }
                    contentItem: Text {
                        text: notificationVisibilityStyleBox.currentText
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: Config.settingsUiSize(11)
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 8
                    }
                }
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Стиль применяется к появлению и исчезновению новых карточек. Профиль кривой и длительность задают характер движения; перемещение остальных карточек в очереди настраивается отдельно."
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(10)
            }
        }
    }

}

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
settingsSearchSubTabIndex: 0
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsDefaultTimeout", "notificationsCriticalTimeout", "notificationsShowTimeoutIndicator", "notificationsTimeoutIndicatorColor", "notificationsTimeoutIndicatorStyle", "notificationsTimeoutIndicatorDirection"] })
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

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Обычные уведомления (с)"
            labelWidth: 220
            labelElide: Text.ElideRight

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

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Критические уведомления (с)"
            labelWidth: 220
            labelElide: Text.ElideRight

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

        SettingsCheckBox {
            id: notificationsShowTimeoutIndicatorCheck
            width: parent.width
            height: 28
            text: "Показывать время до закрытия"
            checked: Config.notificationsShowTimeoutIndicator
            onToggled: { Config.notificationsShowTimeoutIndicator = checked; root.settings.save() }
            Connections { target: Config; function onNotificationsShowTimeoutIndicatorChanged() { notificationsShowTimeoutIndicatorCheck.checked = Config.notificationsShowTimeoutIndicator } }
        }
        Text {
            width: parent.width
            text: "Индикатор показывает оставшееся время до автоматического закрытия. При наведении на карточку отсчёт приостанавливается."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Вид индикатора"
            labelWidth: 220
            labelElide: Text.ElideRight
            SettingsComboBox {
                id: notificationsTimeoutIndicatorStyleCombo
                width: 140
                height: 30
                model: ["Полоса", "Рамка"]
                currentIndex: Config.notificationsTimeoutIndicatorStyle === "border" ? 1 : 0
                settingsSearchId: "notifications-timeout-indicator-style"
                settingsSearchLabel: "Вид индикатора оставшегося времени"
                settingsSearchKeywords: "уведомления таймер обратный отсчёт полоса рамка периметр border outline style"
                onItemChosen: index => {
                    Config.notificationsTimeoutIndicatorStyle = index === 1 ? "border" : "bar"
                    root.settings.save()
                }
            }
        }
        Connections {
            target: Config
            function onNotificationsTimeoutIndicatorStyleChanged() {
                notificationsTimeoutIndicatorStyleCombo.currentIndex = Config.notificationsTimeoutIndicatorStyle === "border" ? 1 : 0
            }
        }
        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            visible: Config.notificationsTimeoutIndicatorStyle === "border"
            label: "Направление рамки"
            labelWidth: 220
            labelElide: Text.ElideRight
            SettingsComboBox {
                id: notificationsTimeoutIndicatorDirectionCombo
                width: 180
                height: 30
                model: ["По часовой стрелке", "Против часовой стрелки"]
                currentIndex: Config.notificationsTimeoutIndicatorDirection === "counterclockwise" ? 1 : 0
                settingsSearchId: "notifications-timeout-indicator-direction"
                settingsSearchLabel: "Направление исчезновения рамки уведомления"
                settingsSearchKeywords: "уведомления таймер рамка направление по часовой против часовой clockwise counterclockwise reverse обратное периметр"
                onItemChosen: index => {
                    Config.notificationsTimeoutIndicatorDirection = index === 1 ? "counterclockwise" : "clockwise"
                    root.settings.save()
                }
            }
        }
        Connections {
            target: Config
            function onNotificationsTimeoutIndicatorDirectionChanged() {
                notificationsTimeoutIndicatorDirectionCombo.currentIndex = Config.notificationsTimeoutIndicatorDirection === "counterclockwise" ? 1 : 0
            }
        }
        SettingsColorField {
            width: parent.width
            label: "Цвет индикатора"
            value: String(Config.notificationsTimeoutIndicatorColor || Config.accent)
            targetObject: Config
            targetProperty: "notificationsTimeoutIndicatorColor"
            settingsObject: root.settings
            saveOnEdit: true
            allowAlpha: false
            allowTransparent: false
            labelWidth: 220
            fieldWidth: 120
            settingsSearchId: "notifications-timeout-indicator-color"
            settingsSearchLabel: "Цвет полосы или рамки оставшегося времени уведомления"
            settingsSearchKeywords: "уведомления countdown таймер цвет полоска рамка progress accent"
        }
        Text {
            width: parent.width
            text: "Пустое значение использует основной цвет темы. Цвет применяется и к полосе, и к рамке. Для рамки можно выбрать направление обхода."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
    }

    SettingsGroup {
                visible: root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
settingsSearchSubTabIndex: 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsCardSpacing", "notificationsImageHeight", "notificationsShowAppIcon", "notificationsShowBodyImages", "notificationsShowProgress"] })
        heading: "Интервалы и изображения"
        padding: 8
        contentSpacing: 6

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Расстояние между карточками"
            labelWidth: 220
            labelElide: Text.ElideRight

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

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Максимальная высота превью"
            labelWidth: 220
            labelElide: Text.ElideRight

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
settingsSearchSubTabIndex: 1
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
        visible: root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsSummaryFont", "notificationsSummaryFontSize", "notificationsSummaryColor", "notificationsLeadingVisualSize"] })
        heading: "Заголовок и иконка"
        padding: 8
        contentSpacing: 6

        SettingsFontField {
            width: parent.width
            height: 30
            label: "Шрифт заголовка"
            value: Config.notificationsSummaryFont
            targetObject: Config
            targetProperty: "notificationsSummaryFont"
            settingsObject: root.settings
            saveOnEdit: true
            labelWidth: 220
            fieldWidth: 150
        }

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Размер заголовка"
            labelWidth: 220
            labelElide: Text.ElideRight

            SettingsNumberField {
                width: 100
                height: 30
                value: Config.notificationsSummaryFontSize
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
                targetProperty: "notificationsSummaryFontSize"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        SettingsColorField {
            width: parent.width
            label: "Цвет заголовка"
            value: String(Config.notificationsSummaryColor || Config.text)
            targetObject: Config
            targetProperty: "notificationsSummaryColor"
            settingsObject: root.settings
            saveOnEdit: true
            allowAlpha: true
            allowTransparent: false
            labelWidth: 220
            fieldWidth: 120
        }

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Размер иконки / аватара"
            labelWidth: 220
            labelElide: Text.ElideRight

            SettingsNumberField {
                width: 100
                height: 30
                value: Config.notificationsLeadingVisualSize
                minimum: 24
                maximum: 72
                step: 2
                wheelStep: 2
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "notificationsLeadingVisualSize"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }

        Text {
            width: parent.width
            text: "Пустой шрифт использует системный. Размер иконки применяется одинаково к иконкам приложений, аватарам и ведущим изображениям."
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
        changeKeys: ({ keys: ["notificationsAppNameFont", "notificationsAppNameFontSize", "notificationsAppNameColor", "notificationsAppNameBold"] })
        heading: "Название приложения"
        padding: 8
        contentSpacing: 6

        SettingsFontField {
            width: parent.width
            height: 30
            label: "Шрифт названия"
            value: Config.notificationsAppNameFont
            targetObject: Config
            targetProperty: "notificationsAppNameFont"
            settingsObject: root.settings
            saveOnEdit: true
            labelWidth: 220
            fieldWidth: 150
        }
        SettingsRow {
            width: parent.width
            height: 30
            label: "Размер названия"
            labelWidth: 220
            labelElide: Text.ElideRight
            SettingsNumberField {
                width: 100; height: 30; value: Config.notificationsAppNameFontSize
                minimum: 8; maximum: 24; step: 1; wheelStep: 1; decimals: 0
                compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config; targetProperty: "notificationsAppNameFontSize"
                settingsObject: root.settings; saveOnEdit: true
            }
        }
        SettingsColorField {
            width: parent.width
            label: "Цвет названия"
            value: String(Config.notificationsAppNameColor || Config.text)
            targetObject: Config; targetProperty: "notificationsAppNameColor"
            settingsObject: root.settings; saveOnEdit: true
            allowAlpha: true; allowTransparent: false
            labelWidth: 220; fieldWidth: 120
        }
        SettingsCheckBox {
            width: parent.width; height: 28
            text: "Полужирное начертание"
            checked: Config.notificationsAppNameBold
            onToggled: { Config.notificationsAppNameBold = checked; root.settings.save() }
        }
        Text {
            width: parent.width
            text: "Пустой шрифт и цвет используют системное семейство и активный цвет текста."
            color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(9)
            wrapMode: Text.WordWrap
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsLeadingVisualRadius"] })
        heading: "Скругление иконки / аватара"
        padding: 8
        contentSpacing: 6
        SettingsRow {
            width: parent.width; height: 30
            label: "Радиус скругления"; labelWidth: 220; labelElide: Text.ElideRight
            SettingsNumberField {
                width: 100; height: 30; value: Config.notificationsLeadingVisualRadius
                minimum: 0; maximum: 36; step: 1; wheelStep: 1; decimals: 0
                compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config; targetProperty: "notificationsLeadingVisualRadius"
                settingsObject: root.settings; saveOnEdit: true
            }
        }
        Text { width: parent.width; text: "0 — квадратные углы; максимальный радиус автоматически ограничивается половиной размера изображения."; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(9); wrapMode: Text.WordWrap }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsCardPadding"] })
        heading: "Внутренние отступы карточки"
        padding: 8
        contentSpacing: 6
        SettingsRow {
            width: parent.width; height: 30
            label: "Отступ от краёв"; labelWidth: 220; labelElide: Text.ElideRight
            SettingsNumberField {
                width: 100; height: 30; value: Config.notificationsCardPadding
                minimum: 0; maximum: 32; step: 1; wheelStep: 1; decimals: 0
                compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config; targetProperty: "notificationsCardPadding"
                settingsObject: root.settings; saveOnEdit: true
            }
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsBodyFont", "notificationsBodyFontSize", "notificationsBodyColor"] })
        heading: "Основной текст уведомления"
        padding: 8
        contentSpacing: 6
        SettingsFontField {
            width: parent.width
            height: 30
            label: "Шрифт основного текста"
            value: Config.notificationsBodyFont
            targetObject: Config
            targetProperty: "notificationsBodyFont"
            settingsObject: root.settings
            saveOnEdit: true
            labelWidth: 220
            fieldWidth: 150
            placeholderText: "Системный шрифт"
            settingsSearchId: "notifications-body-font"
            settingsSearchLabel: "Шрифт основного текста уведомления"
            settingsSearchKeywords: "основной текст тело сообщения уведомления шрифт family body font"
        }
        SettingsRow {
            width: parent.width; height: 30
            label: "Размер текста"; labelWidth: 220; labelElide: Text.ElideRight
            SettingsNumberField {
                width: 100; height: 30; value: Config.notificationsBodyFontSize
                minimum: 8; maximum: 32; step: 1; wheelStep: 1; decimals: 0
                compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config; targetProperty: "notificationsBodyFontSize"
                settingsObject: root.settings; saveOnEdit: true
            }
        }
        SettingsColorField {
            width: parent.width; label: "Цвет текста"
            value: String(Config.notificationsBodyColor || Config.text)
            targetObject: Config; targetProperty: "notificationsBodyColor"
            settingsObject: root.settings; saveOnEdit: true
            allowAlpha: true; allowTransparent: false
            labelWidth: 220; fieldWidth: 120
        }
        Text { width: parent.width; text: "Пустой цвет использует основной цвет активной темы."; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(9); wrapMode: Text.WordWrap }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 1
        width: parent.width
        showFrame: true
        settings: root.settings
        changeKeys: ({ keys: ["notificationsBackgroundColor"] })
        heading: "Фон уведомлений"
        padding: 8
        contentSpacing: 6

        SettingsColorField {
            width: parent.width
            label: "Цвет и прозрачность"
            value: String(Config.notificationsBackgroundColor)
            targetObject: Config
            targetProperty: "notificationsBackgroundColor"
            settingsObject: root.settings
            saveOnEdit: true
            allowAlpha: true
            allowTransparent: true
            labelWidth: 220
            fieldWidth: 120
        }
    }

    SettingsGroup {
                visible: root.host && root.host.currentPageId === "notifications" && root.host.currentPageSubTabIndex === 2
settingsSearchSubTabIndex: 2
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

        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Вертикальная привязка"
            labelWidth: 220
            labelElide: Text.ElideRight

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

            SettingsRow {
                label: "Направление движения"
                labelWidth: 210
                labelElide: Text.ElideRight
                width: parent.width
                height: 30
                spacing: 8

                

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

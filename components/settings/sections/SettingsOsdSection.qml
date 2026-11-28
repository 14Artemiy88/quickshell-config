import QtQuick
import QtQuick.Controls
import "../primitives"
import "../../.."

// Shared home for system OSD controls and the optional notifications-style presentation.
Column {
    id: root
    property var host: null
    property var settings: Settings
    spacing: 8
    width: parent ? parent.width : 0
    visible: host && host.currentPageId === "osd"
    readonly property int selectedMode: host ? host.currentPageSubTabIndex : 0

    SettingsGroup {
        visible: root.visible
        width: parent.width
        showFrame: true
        heading: "Интеграция с уведомлениями"
        changeKeys: ({ keys: ["osdIntegrateWithNotifications"] })
        padding: 8
        contentSpacing: 6

        SettingsCheckBox {
            id: osdNotificationsIntegrationCheck
            width: parent.width
            height: 30
            text: "Интегрировать OSD с уведомлениями"
            checked: Config.osdIntegrateWithNotifications
            settingsSearchId: "osd-integrate-with-notifications"
            settingsSearchLabel: "Интегрировать OSD с уведомлениями"
            settingsSearchKeywords: "osd уведомления карточка стиль оформление расположение очередь громкость плеер dnd"
            onToggled: { Config.osdIntegrateWithNotifications = checked; root.settings.save() }
            Connections {
                target: Config
                function onOsdIntegrateWithNotificationsChanged() {
                    osdNotificationsIntegrationCheck.checked = Config.osdIntegrateWithNotifications
                }
            }
        }
        SettingsDescription {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Использует оформление и анимацию карточек уведомлений. OSD появляется рядом с очередью уведомлений и не перекрывает её. При выключении сохраняется прежний отдельный экранный индикатор."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(9)
        }
    }

    SettingsGroup {
        visible: root.visible && root.selectedMode === 0
        width: parent.width
        showFrame: true
        heading: "Экранный индикатор громкости"
        changeKeys: ({ keys: ["volumeOsdEnabled", "volumeOsdHideDelay", "volumeOsdAnimationDuration", "animationVolumeOsdMorphProfile"] })
        padding: 8
        contentSpacing: 6

        SettingsCheckBox {
            id: volumeOsdEnabledCheck
            width: parent.width
            height: 30
            text: "Показывать OSD при изменении громкости и Mute"
            checked: Config.volumeOsdEnabled
            settingsSearchId: "volume-osd-enabled"
            settingsSearchLabel: "Показывать экранный индикатор громкости"
            settingsSearchKeywords: "osd экранный индикатор всплывающий popup громкость mute без звука аппаратные клавиши"
            settingsSearchSubTabIndex: 0
            onToggled: { Config.volumeOsdEnabled = checked; root.settings.save() }
            Connections {
                target: Config
                function onVolumeOsdEnabledChanged() { volumeOsdEnabledCheck.checked = Config.volumeOsdEnabled }
            }
        }
        SettingsDescription {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Индикатор реагирует на изменения системного выхода PipeWire, в том числе на аппаратные клавиши и управление из виджета громкости. Он не зависит от видимости самого виджета."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(9)
        }
        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Время показа (мс)"
            labelWidth: 210
            SettingsNumberField {
                value: Config.volumeOsdHideDelay
                minimum: 250
                maximum: 10000
                step: 50
                wheelStep: 50
                labelWidth: 0
                fieldWidth: 100
                compact: true
                targetObject: Config
                targetProperty: "volumeOsdHideDelay"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
    }
    SettingsAnimationGroup {
        visible: root.visible && root.selectedMode === 0
        width: root.width
        settings: root.settings
        heading: "Появление OSD громкости"
        detailsHeading: "Параметры анимации"
        changeKeys: ({ keys: ["animationVolumeOsdMorphProfile", "volumeOsdAnimationDuration"] })
        profile: Config.animationVolumeOsdMorphProfile
        duration: Config.volumeOsdAnimationDuration
        settingsSearchSubTabIndex: 0
        minimumDuration: 0
        maximumDuration: 1500
        durationStep: 10
        durationWheelStep: 10
        profileSearchId: "volume-osd-animation-profile"
        profileSearchLabel: "Профиль анимации OSD громкости"
        profileSearchKeywords: "osd popup громкость анимация кривая spatial expressive effects none"
        durationSearchId: "volume-osd-animation-duration"
        durationSearchLabel: "Длительность анимации OSD громкости"
        durationSearchKeywords: "osd popup громкость анимация длительность скорость"
        onDurationEdited: function(value) { Config.volumeOsdAnimationDuration = value; root.settings.save() }
        onProfileEdited: function(value) { Config.animationVolumeOsdMorphProfile = value; root.settings.save() }
    }

    SettingsGroup {
        visible: root.visible && root.selectedMode === 1
        width: parent.width
        showFrame: true
        heading: "Экранный индикатор плеера"
        changeKeys: ({ keys: ["playerOsdEnabled", "playerOsdHideDelay", "playerOsdAnimationDuration", "animationPlayerOsdMorphProfile"] })
        padding: 8
        contentSpacing: 6
        SettingsCheckBox {
            id: playerOsdEnabledCheck
            width: parent.width
            height: 30
            text: "Показывать OSD при смене трека или плеера"
            checked: Config.playerOsdEnabled
            settingsSearchId: "player-osd-enabled"
            settingsSearchLabel: "Экранный индикатор плеера"
            settingsSearchKeywords: "osd media track title artist artwork album обложка исполнитель композиция музыка"
            settingsSearchSubTabIndex: 1
            onToggled: { Config.playerOsdEnabled = checked; root.settings.save() }
            Connections {
                target: Config
                function onPlayerOsdEnabledChanged() { playerOsdEnabledCheck.checked = Config.playerOsdEnabled }
            }
        }
        SettingsDescription {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Показывает обложку, название композиции, исполнителя и источник воспроизведения. Первый снимок при запуске не вызывает OSD; индикатор появляется при последующей смене трека или активного backend."
            color: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(10)
        }
        SettingsRow {
            width: parent.width
            height: 30
            spacing: 8
            label: "Время показа (мс)"
            labelWidth: 210
            SettingsNumberField {
                width: 100
                value: Config.playerOsdHideDelay
                minimum: 500
                maximum: 15000
                step: 100
                wheelStep: 100
                compact: true
                labelWidth: 0
                targetObject: Config
                targetProperty: "playerOsdHideDelay"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
    }
    SettingsAnimationGroup {
        visible: root.visible && root.selectedMode === 1
        width: root.width
        settings: root.settings
        heading: "Появление OSD плеера"
        detailsHeading: "Параметры анимации"
        changeKeys: ({ keys: ["animationPlayerOsdMorphProfile", "playerOsdAnimationDuration"] })
        profile: Config.animationPlayerOsdMorphProfile
        duration: Config.playerOsdAnimationDuration
        settingsSearchSubTabIndex: 1
        minimumDuration: 0
        maximumDuration: 1500
        durationStep: 10
        durationWheelStep: 10
        profileSearchId: "player-osd-animation-profile"
        profileSearchLabel: "Профиль анимации OSD плеера"
        profileSearchKeywords: "osd media popup появление музыка анимация кривая none"
        durationSearchId: "player-osd-animation-duration"
        durationSearchLabel: "Длительность анимации OSD плеера"
        durationSearchKeywords: "osd media длительность скорость анимация"
        onDurationEdited: function(value) { Config.playerOsdAnimationDuration = value; root.settings.save() }
        onProfileEdited: function(value) { Config.animationPlayerOsdMorphProfile = value; root.settings.save() }
    }

    SettingsGroup {
        visible: root.visible && root.selectedMode === 2
        width: parent.width
        showFrame: true
        heading: "Экранный индикатор режима Не беспокоить"
        changeKeys: ({ keys: ["notificationsDndOsdEnabled", "notificationsDndOsdHideDelay", "notificationsDndOsdAnimationDuration", "animationNotificationsDndOsdMorphProfile"] })
        padding: 8
        contentSpacing: 6
        SettingsCheckBox {
            id: notificationsDndOsdEnabledCheck
            width: parent.width
            height: 30
            text: "Показывать OSD при включении и выключении DND"
            checked: Config.notificationsDndOsdEnabled
            settingsSearchId: "notifications-dnd-osd-enabled"
            settingsSearchLabel: "OSD режима Не беспокоить"
            settingsSearchKeywords: "экранный индикатор dnd do not disturb включение выключение уведомления popup всплывающий"
            settingsSearchSubTabIndex: 2
            onToggled: { Config.notificationsDndOsdEnabled = checked; root.settings.save() }
            Connections {
                target: Config
                function onNotificationsDndOsdEnabledChanged() { notificationsDndOsdEnabledCheck.checked = Config.notificationsDndOsdEnabled }
            }
        }
        SettingsRow {
            visible: Config.notificationsDndOsdEnabled
            settingsSearchSubTabIndex: 2
            width: parent.width
            height: 30
            spacing: 8
            label: "Время показа OSD (мс)"
            labelWidth: 190
            SettingsNumberField {
                width: 100
                value: Config.notificationsDndOsdHideDelay
                settingsSearchId: "notifications-dnd-osd-hide-delay"
                settingsSearchLabel: "Время показа OSD режима Не беспокоить"
                settingsSearchKeywords: "dnd osd задержка время скрытие миллисекунды duration timeout"
                minimum: 500
                maximum: 10000
                step: 100
                wheelStep: 100
                compact: true
                labelWidth: 0
                targetObject: Config
                targetProperty: "notificationsDndOsdHideDelay"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
    }
    SettingsAnimationGroup {
        visible: root.visible && root.selectedMode === 2 && Config.notificationsDndOsdEnabled
        width: root.width
        settings: root.settings
        heading: "Появление OSD режима Не беспокоить"
        detailsHeading: "Параметры анимации"
        settingsSearchSubTabIndex: 2
        profileSearchId: "notifications-dnd-osd-animation-profile"
        profileSearchLabel: "Профиль анимации OSD режима Не беспокоить"
        profileSearchKeywords: "dnd osd анимация кривая пространственная эффекты плавность"
        durationSearchId: "notifications-dnd-osd-animation-duration"
        durationSearchLabel: "Длительность анимации OSD режима Не беспокоить"
        durationSearchKeywords: "dnd osd анимация длительность миллисекунды скорость"
        changeKeys: ({ keys: ["animationNotificationsDndOsdMorphProfile", "notificationsDndOsdAnimationDuration"] })
        profile: Config.animationNotificationsDndOsdMorphProfile
        duration: Config.notificationsDndOsdAnimationDuration
        durationLabel: "Длительность (мс)"
        minimumDuration: 0
        maximumDuration: 1500
        durationStep: 10
        onDurationEdited: function(value) { Config.notificationsDndOsdAnimationDuration = Math.max(0, Math.min(1500, Math.round(Number(value) || 0))); root.settings.save() }
        onProfileEdited: function(value) { Config.animationNotificationsDndOsdMorphProfile = value; root.settings.save() }
    }
}

import QtQuick
import QtQuick.Controls
import "../primitives"
import "../../.."

Column {
    id: root
    property var host
    property var settings: Settings
    spacing: 10
    width: parent ? parent.width : 0

    visible: host && host.currentPageId === "player" && host.currentPageSubTabIndex === 7

    SettingsAnimationGroup {
        visible: root.host && root.host.currentPageId === "player" && root.host.currentPageSubTabIndex === 7
        settings: root.settings
        heading: "Переходы плеера"
        changeKeys: ({ keys: ["animationPlayerMorphDuration", "animationPlayerMorphProfile"] })
        duration: Config.animationPlayerMorphDuration
        durationLabel: "Длительность (мс)"
        profile: Config.animationPlayerMorphProfile

        onDurationEdited: function(value) {
            Config.animationPlayerMorphDuration = value
            root.settings.save()
        }
        onProfileEdited: function(value) {
            // Legacy compatibility flag is no longer exposed in the UI.
            // Keep it enabled so the selected profile is the sole control.
            Config.animationPlayerMorphEnabled = true
            Config.animationPlayerMorphProfile = value
            root.settings.save()
        }
    }

    SettingsGroup {
                visible: root.host && root.host.currentPageId === "player" && root.host.currentPageSubTabIndex === 7
settingsSearchSubTabIndex: 7
        width: parent.width
        showFrame: true
        heading: "Что управляется"
        padding: 8
        contentSpacing: 4
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Настройки влияют на раскрытие метаданных, появление кнопки следующего трека и показ шкалы прогресса. Они не меняют анимацию появления самого модуля плеера."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
        }
    }
}

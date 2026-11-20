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

    visible: host && host.currentPageId === "weather" && host.currentPageSubTabIndex === 4

    SettingsAnimationGroup {
        visible: root.visible
        settings: root.settings
        heading: "Внутренние переходы погоды"
        changeKeys: ({ keys: ["animationWeatherMorphDuration", "animationWeatherMorphProfile", "animationWeatherHourlyDuration"] })
        duration: Config.animationWeatherMorphDuration
        durationLabel: "Длительность переходов (мс)"
        profile: Config.animationWeatherMorphProfile

        onDurationEdited: function(value) {
            Config.animationWeatherMorphDuration = value
            root.settings.save()
        }
        onProfileEdited: function(value) {
            // Legacy compatibility flag is no longer exposed in the UI.
            // Keep it enabled so the selected profile is the sole control.
            Config.animationWeatherMorphEnabled = true
            Config.animationWeatherMorphProfile = value
            root.settings.save()
        }

        Row {
            width: parent.width
            height: 30
            spacing: 8
            Text {
                width: 210
                height: 30
                text: "Почасовой прогноз (мс)"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }
            SettingsNumberField {
                width: 100
                height: 30
                value: Config.animationWeatherHourlyDuration
                minimum: 0
                maximum: 5000
                step: 10
                wheelStep: 10
                decimals: 0
                compact: true
                fieldWidth: 100
                fieldFontSize: 11
                inputMethodHints: Qt.ImhDigitsOnly
                targetObject: Config
                targetProperty: "animationWeatherHourlyDuration"
                settingsObject: root.settings
                saveOnEdit: true
            }
        }
    }

    SettingsGroup {
        visible: root.visible
        width: parent.width
        showFrame: true
        heading: "Что управляется"
        padding: 8
        contentSpacing: 4
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Переходы температуры комфорта, погодной иконки и блока ветра; появление температур в прогнозе; плавное изменение ширины и количества часов при прокрутке колёсиком; появление заглушки при отсутствии данных. Изображения погодных значков остаются на прежнем пути отрисовки."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
        }
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Профиль «Без анимации» отключает также плавность прокрутки. Анимация появления самого модуля Weather управляется отдельно."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
        }
    }
}

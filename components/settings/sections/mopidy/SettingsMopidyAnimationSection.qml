import QtQuick
import QtQuick.Controls
import "../../primitives"
import "../../../.."

Column {
    id: root
    property var host
    property var settings: Settings
    spacing: 10
    width: parent ? parent.width : 0

    visible: host && host.currentPageId === "mopidy" && host.currentPageSubTabIndex === 4

    SettingsAnimationGroup {
        visible: root.host && root.host.currentPageId === "mopidy" && root.host.currentPageSubTabIndex === 4
        settings: root.settings
        heading: "Внутренние переходы"
        changeKeys: ({ keys: ["animationMopidyMorphDuration", "animationMopidyMorphProfile"] })
        duration: Config.animationMopidyMorphDuration
        durationLabel: "Длительность (мс)"
        profile: Config.animationMopidyMorphProfile

        onDurationEdited: function(value) {
            Config.animationMopidyMorphDuration = value
            root.settings.save()
        }
        onProfileEdited: function(value) {
            // Legacy compatibility flag is no longer exposed in the UI.
            // Keep it enabled so the selected profile is the sole control.
            Config.animationMopidyMorphEnabled = true
            Config.animationMopidyMorphProfile = value
            root.settings.save()
        }
    }

    SettingsGroup {
        visible: root.host && root.host.currentPageId === "mopidy" && root.host.currentPageSubTabIndex === 4
        width: parent.width
        showFrame: true
        changeKeys: ({ keys: ["animationMopidyVisibilityStyle"] })
        heading: "Появление модуля"
        padding: 8
        contentSpacing: 6

        Row {
            width: parent.width
            height: 30
            spacing: 8
            Text {
                width: 210
                height: 30
                text: "Стиль"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }
            SettingsComboBox {
                id: animationMopidyVisibilityBox
                width: 180
                height: 30
                property var values: ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
                model: ["Нет", "Плавное затухание", "Слева", "Справа", "Сверху", "Снизу"]
                currentIndex: Math.max(0, values.indexOf(Config.animationMopidyVisibilityStyle))
                onItemChosen: function(index) {
                    Config.animationMopidyVisibilityStyle = values[index]
                    root.settings.save()
                }
                Connections {
                    target: Config
                    function onAnimationMopidyVisibilityStyleChanged() {
                        animationMopidyVisibilityBox.currentIndex = Math.max(0, animationMopidyVisibilityBox.values.indexOf(Config.animationMopidyVisibilityStyle))
                    }
                }
                background: Rectangle {
                    color: Config.settingsBackground
                    border.color: (animationMopidyVisibilityBox.activeFocus || animationMopidyVisibilityBox.pointerHovered) ? Config.accent : Config.baseColor
                    border.width: 1
                    radius: 4
                }
                contentItem: Text {
                    text: animationMopidyVisibilityBox.currentText
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 8
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import "../../.."
import "../../primitives"

Column {
    id: root

    property var settings: Settings
    property string heading: "Внутренние переходы"
    property string detailsHeading: "Параметры анимации"
    // SettingsGroup renders its frame legend slightly above its own bounds.
    // Reserve that space inside the clipped MorphGeometry so the legend is not cropped.
    property real detailsTopInset: Math.ceil(Config.settingsUiSize(11) / 2) + 3
    property var changeKeys: null

    property real duration: 180
    property string durationLabel: "Длительность (мс)"
    property real minimumDuration: 0
    property real maximumDuration: 5000
    property real durationStep: 10
    property real durationWheelStep: durationStep

    property string profile: "expressive"
    property string profileLabel: "Профиль кривой"
    property var profileValues: ["none", "standard", "spatial", "effects", "expressive"]
    property var profileLabels: ["Без анимации", "Стандартный", "Пространственный", "Эффекты", "Выразительный"]

    signal durationEdited(real value)
    signal profileEdited(string value)

    // Modules may append module-specific controls to the animated details group.
    default property alias extraContent: extraContentColumn.data

    width: parent ? parent.width : 0
    height: implicitHeight
    spacing: 8

    SettingsGroup {
        id: profileGroup
        width: root.width
        settings: root.settings
        showFrame: true
        changeKeys: root.changeKeys
        heading: root.heading
        padding: 8
        contentSpacing: 6

        Row {
            width: parent.width
            height: 30
            spacing: 8

            Text {
                width: 210
                height: 30
                text: root.profileLabel
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: Config.settingsUiSize(11)
                verticalAlignment: Text.AlignVCenter
            }

            SettingsComboBox {
                id: profileComboBox
                width: 180
                height: 30
                property var values: root.profileValues
                model: root.profileLabels
                currentIndex: Math.max(0, values.indexOf(root.profile))
                onItemChosen: function(index) {
                    if (index >= 0 && index < values.length)
                        root.profileEdited(values[index])
                }

                Connections {
                    target: root
                    function onProfileChanged() {
                        profileComboBox.currentIndex = Math.max(0, profileComboBox.values.indexOf(root.profile))
                    }
                }
            }
        }

        Text {
            width: parent.width
            visible: root.profile === "none"
            wrapMode: Text.WordWrap
            text: "Внутренние переходы выполняются мгновенно. Сохранённые длительности не меняются, анимация появления самого модуля остаётся независимой."
            color: Config.textMuted
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(10)
        }
    }

    MorphGeometry {
        id: detailsMorph
        width: root.width
        clip: true
        visible: root.profile !== "none" || normalizedProgress > 0.001
        fromGeometry: Qt.rect(0, 0, parent.width, 0)
        toGeometry: Qt.rect(0, 0, parent.width, root.detailsTopInset + detailsGroup.implicitHeight)
        progress: root.profile !== "none" ? 1 : 0
        animationDuration: Config.animationDuration(180, "appearance")
        animationEasing: Config.animationEasingType("standard", root.profile !== "none" ? "enter" : "exit")

        SettingsGroup {
            id: detailsGroup
            y: root.detailsTopInset
            width: parent.width
            settings: root.settings
            showFrame: true
            heading: root.detailsHeading
            padding: 8
            contentSpacing: 6

            Row {
                width: parent.width
                height: 30
                spacing: 8

                Text {
                    width: 210
                    height: 30
                    text: root.durationLabel
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(11)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                SettingsNumberField {
                    width: 100
                    height: 30
                    value: root.duration
                    minimum: root.minimumDuration
                    maximum: root.maximumDuration
                    step: root.durationStep
                    wheelStep: root.durationWheelStep
                    decimals: 0
                    compact: true
                    fieldWidth: 100
                    fieldFontSize: 11
                    inputMethodHints: Qt.ImhDigitsOnly
                    valueWriter: function(value) {
                        root.durationEdited(value)
                    }
                }
            }

            Column {
                id: extraContentColumn
                width: parent.width
                spacing: 6
            }
        }
    }
}

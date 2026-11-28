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
    // Optional global-settings-search metadata for the two shared controls.
    property int settingsSearchSubTabIndex: -1
    property string profileSearchId: ""
    property string profileSearchLabel: ""
    property string profileSearchKeywords: ""
    property string durationSearchId: ""
    property string durationSearchLabel: ""
    property string durationSearchKeywords: ""

    property real duration: 180
    property string durationLabel: "Длительность (мс)"
    property real minimumDuration: 0
    property real maximumDuration: 5000
    property real durationStep: 10
    property real durationWheelStep: durationStep

    property string profile: "ease-in-out"
    property string profileLabel: "Функция сглаживания"
    property var profileValues: ["none", "linear", "ease", "ease-in", "ease-out", "ease-in-out", "cubic-bezier"]
    property var profileLabels: ["Без анимации", "linear", "ease", "ease-in", "ease-out", "ease-in-out", "cubic-bezier()"]
    readonly property string normalizedProfile: Config.normalizeAnimationProfile(root.profile)
    readonly property string selectedProfileOption: root.normalizedProfile.indexOf("cubic-bezier(") === 0 ? "cubic-bezier" : root.normalizedProfile
    readonly property bool customBezierVisible: root.selectedProfileOption === "cubic-bezier"
    readonly property var currentBezierValues: Config.animationBezierValues(root.profile)

    function updateBezierComponent(index, value) {
        var values = Config.animationBezierValues(root.profile)
        if (!values || index < 0 || index > 3) return
        var number = Number(value)
        if (!isFinite(number)) return
        if (index % 2 === 0) number = Math.max(0, Math.min(1, number))
        values[index] = Math.round(number * 100) / 100
        var parts = []
        for (var i = 0; i < 4; ++i) parts.push(Number(values[i]).toFixed(2))
        root.profileEdited("cubic-bezier(" + parts.join(", ") + ")")
    }

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

        SettingsRow {
            width: parent.width
            height: 30
            label: root.profileLabel
            labelWidth: 210
            labelFontSize: 11
            controlSpacing: 8

            SettingsComboBox {
                id: profileComboBox
                width: 180
                height: 30
                property var values: root.profileValues
                model: root.profileLabels
                currentIndex: Math.max(0, values.indexOf(root.selectedProfileOption))
                settingsSearchId: root.profileSearchId
                settingsSearchLabel: root.profileSearchLabel
                settingsSearchKeywords: root.profileSearchKeywords
                onItemChosen: function(index) {
                    if (index < 0 || index >= values.length) return
                    var selected = values[index]
                    if (selected === "cubic-bezier") {
                        if (!root.customBezierVisible)
                            root.profileEdited("cubic-bezier(0.25, 0.10, 0.25, 1.00)")
                    } else {
                        root.profileEdited(selected)
                    }
                }

                Connections {
                    target: root
                    function onProfileChanged() {
                        profileComboBox.currentIndex = Math.max(0, profileComboBox.values.indexOf(root.selectedProfileOption))
                    }
                }
            }
        }

        SettingsDescription {
            width: parent.width
            wrapMode: Text.WordWrap
            text: root.normalizedProfile === "none"
                ? "Анимация внутренних переходов отключена. Анимация появления самого модуля управляется отдельно."
                : (root.customBezierVisible
                    ? "Используется собственная CSS-функция cubic-bezier(x1, y1, x2, y2). Для X1 и X2 должны находиться в диапазоне от 0 до 1; Y1 и Y2 могут принимать любые конечные числовые значения."
                    : "Используется CSS-функция сглаживания «" + root.selectedProfileOption + "». Длительность перехода задаётся отдельно.")
        }

        SettingsRow {
            visible: root.customBezierVisible
            width: parent.width
            height: visible ? 46 : 0
            label: "Параметры кривой"
            labelWidth: 170
            labelFontSize: 10
            controlSpacing: 4

            Row {
                height: parent.height
                spacing: 4
                Repeater {
                    model: ["X1", "Y1", "X2", "Y2"]
                    delegate: Column {
                        width: 54
                        spacing: 1
                        Text {
                            width: parent.width
                            height: 12
                            text: modelData
                            color: Config.textMuted
                            font.family: Config.settingsFontFamily
                            font.pixelSize: Config.settingsUiSize(8)
                            horizontalAlignment: Text.AlignHCenter
                        }
                        SettingsNumberField {
                            width: 54
                            height: 30
                            fieldWidth: 54
                            compact: true
                            value: root.currentBezierValues[index]
                            minimum: index % 2 === 0 ? 0 : -Infinity
                            maximum: index % 2 === 0 ? 1 : Infinity
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            step: 0.05
                            wheelStep: 0.05
                            decimals: 2
                            valueWriter: function(value) { root.updateBezierComponent(index, value) }
                        }
                    }
                }
            }
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
        animationDuration: root.profile === "none" ? 0 : Config.animationDuration(180, "appearance")
        animationEasing: Config.animationEasingType("ease-out", root.profile !== "none" ? "enter" : "exit")

        SettingsGroup {
            id: detailsGroup
            y: root.detailsTopInset
            width: parent.width
            settings: root.settings
            showFrame: true
            heading: root.detailsHeading
            padding: 8
            contentSpacing: 6

            SettingsRow {
                width: parent.width
                height: 30
                label: root.durationLabel
                labelWidth: 210
                labelFontSize: 11
                labelElide: Text.ElideRight
                controlSpacing: 8

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
                    settingsSearchId: root.durationSearchId
                    settingsSearchLabel: root.durationSearchLabel
                    settingsSearchKeywords: root.durationSearchKeywords
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

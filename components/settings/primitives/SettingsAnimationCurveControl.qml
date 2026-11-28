import QtQuick
import QtQuick.Controls
import "../../.."
import "../../primitives"

Column {
    id: root

    property string profile: "ease-out"
    property string label: "Кривая сглаживания"
    property int labelWidth: 210
    property string searchId: ""
    property string searchLabel: ""
    property string searchKeywords: ""
    readonly property string normalizedProfile: Config.normalizeAnimationProfile(root.profile)
    readonly property string selectedProfileOption: root.normalizedProfile.indexOf("cubic-bezier(") === 0
        ? "cubic-bezier" : (root.normalizedProfile || "ease-out")
    readonly property bool customBezierVisible: root.selectedProfileOption === "cubic-bezier"
    readonly property var currentBezierValues: Config.animationBezierValues(root.profile)

    signal profileEdited(string value)

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

    width: parent ? parent.width : 0
    spacing: 4

    SettingsRow {
        width: parent.width
        height: 30
        label: root.label
        labelWidth: root.labelWidth
        labelFontSize: 11
        controlSpacing: 8

        SettingsComboBox {
            id: curveComboBox
            width: 180
            height: 30
            property var values: ["linear", "ease", "ease-in", "ease-out", "ease-in-out", "cubic-bezier"]
            model: ["linear", "ease", "ease-in", "ease-out", "ease-in-out", "cubic-bezier()"]
            currentIndex: Math.max(0, values.indexOf(root.selectedProfileOption))
            settingsSearchable: true
            settingsSearchId: root.searchId
            settingsSearchLabel: root.searchLabel
            settingsSearchKeywords: root.searchKeywords + " css easing timing curve сглаживание ускорение замедление bezier"
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
                    curveComboBox.currentIndex = Math.max(0, curveComboBox.values.indexOf(root.selectedProfileOption))
                }
            }
        }
    }

    SettingsDescription {
        width: parent.width
        wrapMode: Text.WordWrap
        text: root.customBezierVisible
            ? "CSS cubic-bezier(x1, y1, x2, y2). X1 и X2 находятся в диапазоне от 0 до 1; Y1 и Y2 могут выходить за эти границы и создавать эффект перелёта."
            : "CSS-функция «" + root.selectedProfileOption + "» применяется к движению модуля при открытии и закрытии."
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

import QtQuick
import QtQuick.Controls

import "../../.."

Item {
    id: root

    // Settings search metadata is intentionally independent from displayed labels.
    property bool settingsSearchable: true
    property bool settingsSearchHighlighted: false
    property bool settingsSearchCurrentMatch: false
    property string settingsSearchMatchHint: ""
    property string settingsSearchId: ""
    property string settingsSearchLabel: ""
    property string settingsSearchKeywords: ""

    // An empty family delegates font selection to the system/application default.
    property string label: ""
    property string value: ""
    property var targetObject: null
    property string targetProperty: ""
    property var settingsObject: null
    property bool saveOnEdit: false
    property int labelWidth: 210
    property int fieldWidth: 160
    property int fieldHeight: 30
    property int fieldFontSize: 11
    property bool compact: false
    property string placeholderText: "Системный шрифт"
    property string resetTooltip: "Сбросить на системный шрифт"
    readonly property bool pointerHovered: field.pointerHovered

    signal valueEdited(string value)

    width: root.compact
        ? root.fieldWidth + 8 + 30
        : (parent ? parent.width : root.labelWidth + 8 + root.fieldWidth + 8 + 30)
    height: root.fieldHeight

    function normalizedFamily(raw) {
        return String(raw ?? "")
            .replace(/[\r\n\t]/g, " ")
            .trim()
            .slice(0, 128)
    }

    function commit(raw) {
        var family = root.normalizedFamily(raw)

        if (root.targetObject && root.targetProperty !== "")
            root.targetObject[root.targetProperty] = family

        field.text = family
        root.valueEdited(family)

        if (
            root.saveOnEdit &&
            root.settingsObject &&
            root.settingsObject.save
        ) {
            root.settingsObject.save()
        }
    }

    SettingsSearchHighlight {
        anchors.fill: parent
        overlayZ: 5
        highlighted: root.settingsSearchHighlighted
        currentMatch: root.settingsSearchCurrentMatch
        matchHint: root.settingsSearchMatchHint
        cornerRadius: 4
    }

    Row {
        anchors.fill: parent
        spacing: 8

        SettingsLabel {
            width: root.compact ? 0 : root.labelWidth
            height: root.fieldHeight
            visible: !root.compact && root.label !== ""
            text: root.label
            settingsFontSize: root.fieldFontSize
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        SettingsInputField {
            id: field
            width: root.fieldWidth
            height: root.fieldHeight
            text: String(root.value || "")
            color: Config.text
            selectionColor: Config.accent
            selectedTextColor: Config.black
            placeholderText: root.placeholderText
            placeholderTextColor: Config.textMuted
            font.family: Config.settingsFontFamily
            font.pixelSize: Config.settingsUiSize(root.fieldFontSize)
            activeFocusOnTab: true
            selectByMouse: true

            Binding {
                target: field
                property: "text"
                value: String(root.value || "")
                when: !field.activeFocus
            }

            onEditingFinished: root.commit(text)
        }

        SettingsResetButton {
            width: 30
            height: root.fieldHeight
            tooltip: root.resetTooltip
            actionAvailable: root.normalizedFamily(root.value) !== ""
            onClicked: root.commit("")
        }
    }
}

import QtQuick

import "../../.."

Item {
    id: root

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

    Row {
        anchors.fill: parent
        spacing: 8

        Text {
            width: root.compact ? 0 : root.labelWidth
            height: root.fieldHeight
            visible: !root.compact && root.label !== ""
            text: root.label
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(root.fieldFontSize)
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
            font.family: Config.settingsFont
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

import QtQuick

import "../../.."

Item {
    id: root

    property string label: ""
    property string value: ""
    property var targetObject: null
    property string targetProperty: ""
    property var settingsObject: null
    property bool saveOnEdit: false
    property bool allowAlpha: true
    property bool allowTransparent: true
    property int labelWidth: 210
    property int fieldWidth: 120
    property int fieldHeight: 30
    property int fieldFontSize: 11
    property int swatchSize: 24
    property bool compact: false

    signal valueEdited(string value)

    width: root.compact
        ? root.swatchSize + 8 + root.fieldWidth
        : (parent ? parent.width : root.labelWidth + 8 + root.swatchSize + 8 + root.fieldWidth)
    height: root.fieldHeight

    function validate(raw) {
        var v = String(raw ?? "").trim()
        var hexPattern = root.allowAlpha
            ? /^#[0-9a-fA-F]{6,8}$/
            : /^#[0-9a-fA-F]{6}$/

        if (hexPattern.test(v))
            return v

        if (root.allowTransparent && v === "transparent")
            return v

        return ""
    }

    function commit(raw) {
        var v = root.validate(raw)

        if (v === "") {
            field.text = String(root.value)
            return
        }

        if (root.targetObject && root.targetProperty !== "")
            root.targetObject[root.targetProperty] = v

        field.text = v
        root.valueEdited(v)

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
            visible: !root.compact
            text: root.label
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(root.fieldFontSize)
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Rectangle {
            width: root.swatchSize
            height: root.swatchSize
            radius: 4
            color: root.value || "transparent"
            border.color: Config.baseColor
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter
        }

        SettingsInputField {
            id: field
            width: root.fieldWidth
            height: root.fieldHeight
            text: String(root.value)
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(root.fieldFontSize)
            horizontalAlignment: Text.AlignHCenter
            activeFocusOnTab: true

            Binding {
                target: field
                property: "text"
                value: String(root.value)
                when: !field.activeFocus
            }

            onEditingFinished: root.commit(text)
        }
    }
}

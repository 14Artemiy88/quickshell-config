import QtQuick
import "../../.."
import "../primitives"

SettingsRow {
    id: root

    property string iconValue: ""
    property string fontValue: "JetBrainsMono Nerd Font"
    signal iconEdited(string value)
    signal fontEdited(string value)

    width: parent ? parent.width : 0
    height: 30
    spacing: 6
    labelWidth: 130
    controlSpacing: 6

    SettingsTextField {
        id: iconField
        width: 55
        height: 30
        color: Config.text
        selectionColor: Config.accent
        selectedTextColor: Config.black
        font.family: root.fontValue || Config.font
        font.pixelSize: Config.settingsUiSize(13)
        horizontalAlignment: TextInput.AlignHCenter
        activeFocusOnTab: true
        background: Rectangle {
            color: Config.settingsBackground
            border.color: (iconField.activeFocus || iconField.pointerHovered) ? Config.accent : Config.baseColor
            border.width: 1
            radius: 4
        }
        onEditingFinished: {
            root.iconEdited(text)
            text = root.iconValue
        }
    }

    SettingsFontField {
        id: fontField
        width: 150
        height: 30
        compact: true
        fieldWidth: 112
        fieldFontSize: 10
        value: root.fontValue
        onValueEdited: function(value) {
            root.fontEdited(value)
        }
    }

    Component.onCompleted: {
        iconField.text = root.iconValue
    }
    onIconValueChanged: iconField.text = root.iconValue
}

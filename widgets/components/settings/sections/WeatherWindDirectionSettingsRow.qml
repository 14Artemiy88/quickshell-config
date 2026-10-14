import QtQuick
import "../../.."
import "../primitives"

Row {
    id: root
    property string label: ""
    property string iconValue: ""
    property string fontValue: "JetBrainsMono Nerd Font"
    signal iconEdited(string value)
    signal fontEdited(string value)

    width: parent ? parent.width : 0
    height: 30
    spacing: 6

    Text {
        width: 130
        height: 30
        text: root.label
        color: Config.text
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

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

    SettingsTextField {
        id: fontField
        width: 150
        height: 30
        color: Config.text
        selectionColor: Config.accent
        selectedTextColor: Config.black
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
        activeFocusOnTab: true
        background: Rectangle {
            color: Config.settingsBackground
            border.color: (fontField.activeFocus || fontField.pointerHovered) ? Config.accent : Config.baseColor
            border.width: 1
            radius: 4
        }
        onEditingFinished: {
            root.fontEdited(text)
            text = root.fontValue
        }
    }

    Component.onCompleted: {
        iconField.text = root.iconValue
        fontField.text = root.fontValue
    }
    onIconValueChanged: iconField.text = root.iconValue
    onFontValueChanged: fontField.text = root.fontValue
}

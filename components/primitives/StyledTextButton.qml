import QtQuick
import QtQuick.Controls
import ".."
import "../.."

Button {
    id: root

    property color normalBackground: Config.settingsBackground
    property color pressedBackground: Config.baseColor
    property color textColor: Config.text
    property color outlineColor: Config.baseColor
    property string hoverMode: "none"
    property color hoverColor: Config.accent
    property real cornerRadius: 4
    property string textFontFamily: Config.settingsFont
    property int textFontPixelSize: Config.settingsUiSize(11)

    hoverEnabled: true
    font.family: root.textFontFamily
    font.pixelSize: root.textFontPixelSize

    contentItem: Text {
        text: root.text
        color: root.hovered && root.hoverMode === "text" ? root.hoverColor : root.textColor
        font.family: root.textFontFamily
        font.pixelSize: root.textFontPixelSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideNone
    }

    background: Rectangle {
        color: root.down ? root.pressedBackground : (root.hovered && root.hoverMode === "background" ? root.hoverColor : root.normalBackground)
        border.color: root.hovered && root.hoverMode === "frame" ? root.hoverColor : root.outlineColor
        border.width: 1
        radius: root.cornerRadius
    }
}

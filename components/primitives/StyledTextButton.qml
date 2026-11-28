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
    property string textFontFamily: Config.settingsFontFamily
    readonly property string resolvedTextFontFamily: Config.resolveFontFamily(root.textFontFamily)
    property int textFontPixelSize: Config.settingsUiSize(11)

    hoverEnabled: true
    font.family: root.resolvedTextFontFamily
    font.pixelSize: Config.uiFontSize(root.textFontPixelSize)

    contentItem: Text {
        text: root.text
        color: root.hovered && root.hoverMode === "text" ? root.hoverColor : root.textColor
        font.family: root.resolvedTextFontFamily
        font.pixelSize: Config.uiFontSize(root.textFontPixelSize)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideNone
    }

    background: Rectangle {
        color: root.down ? root.pressedBackground : (root.hovered && root.hoverMode === "background" ? root.hoverColor : root.normalBackground)
        border.color: root.hovered && root.hoverMode === "frame" ? root.hoverColor : root.outlineColor
        border.width: Config.buttonBordersEnabled ? 1 : (root.activeFocus ? 2 : 0)
        radius: Config.scaledCornerRadius(root.cornerRadius)
    }
}

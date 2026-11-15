import QtQuick
import ".."

// Shared upload/download row. The icon column is derived from icon size and
// its left inset, so there is no unrelated fixed column-width setting.
Row {
    id: root

    property string glyph: ""
    property color accentColor: Config.networkUpload
    property string valueText: ""
    readonly property int iconPixelSize: Config.uiFontSize(Config.networkIconSize)
    readonly property int valuePixelSize: Config.uiFontSize(Config.networkValueFontSize)
    readonly property int iconColumnWidth: Config.networkIconLeftPadding + iconPixelSize + 2
    readonly property string valueFontFamily: String(Config.networkFont || "").trim() !== ""
        ? String(Config.networkFont).trim()
        : Qt.application.font.family

    width: parent ? parent.width : 313
    height: Math.max(iconPixelSize, valuePixelSize) + Config.networkSpacing * 2
    spacing: 0

    Text {
        width: root.iconColumnWidth
        text: root.glyph
        color: root.accentColor
        font.pixelSize: root.iconPixelSize
        leftPadding: Config.networkIconLeftPadding
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        width: Math.max(0, parent.width - root.iconColumnWidth)
        text: root.valueText
        color: root.accentColor
        horizontalAlignment: Text.AlignRight
        rightPadding: Config.networkRightPadding
        font.family: root.valueFontFamily
        font.pixelSize: root.valuePixelSize
        verticalAlignment: Text.AlignVCenter
    }
}

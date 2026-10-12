import QtQuick
import ".."

// Shared layout for upload/download statistics. Keeping both directions on
// this component prevents icon/value columns and typography from drifting.
Row {
    id: root

    property string glyph: ""
    property color accentColor: Config.networkUpload
    property string valueText: ""

    width: parent ? parent.width : 313
    height: Config.networkRowHeight
    spacing: 0

    Text {
        width: Config.networkIconColumnWidth
        text: root.glyph
        color: root.accentColor
        font.pixelSize: Config.uiFontSize(Config.networkIconSize)
        leftPadding: Config.networkIconLeftPadding
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        width: Math.max(0, parent.width - Config.networkIconColumnWidth)
        text: root.valueText
        color: root.accentColor
        horizontalAlignment: Text.AlignRight
        rightPadding: Config.networkRightPadding
        font.pixelSize: Config.uiFontSize(Config.networkValueFontSize)
        verticalAlignment: Text.AlignVCenter
    }
}

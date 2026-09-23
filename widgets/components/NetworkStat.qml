import QtQuick
import ".."

Frame {
    width: 313
    height: 55
    property var monitor
    Column {
        spacing: Config.networkRowSpacing
        anchors.fill: parent
        anchors.leftMargin: Config.networkHorizontalPadding
        anchors.rightMargin: Config.networkHorizontalPadding
        anchors.topMargin: 5
        anchors.bottomMargin: 5
        Row {
            visible: Config.networkShowUpload
            width: parent.width
            height: Config.networkRowHeight
            Text { width: Config.networkIconColumnWidth; text: ""; color: Config.networkUpload; font.pixelSize: Config.uiFontSize(Config.networkIconSize); leftPadding: Config.networkIconLeftPadding; verticalAlignment: Text.AlignVCenter }
            Text { width: parent.width - Config.networkIconColumnWidth; text: (monitor?.data?.net_stat?.speed_up ?? "0 B") + " / " + (monitor?.data?.net_stat?.up ?? "0 B"); color: Config.networkUpload; horizontalAlignment: Text.AlignRight; rightPadding: Config.networkRightPadding; font.pixelSize: Config.uiFontSize(Config.networkValueFontSize); verticalAlignment: Text.AlignVCenter }
        }
        Row {
            visible: Config.networkShowDownload
            width: parent.width
            height: Config.networkRowHeight
            Text { width: Config.networkIconColumnWidth; text: ""; color: Config.networkDownload; font.pixelSize: Config.uiFontSize(Config.networkIconSize); leftPadding: Config.networkIconLeftPadding; verticalAlignment: Text.AlignVCenter }
            Text { width: parent.width - Config.networkIconColumnWidth; text: (monitor?.data?.net_stat?.speed_down ?? "0 B") + " / " + (monitor?.data?.net_stat?.down ?? "0 B"); color: Config.networkDownload; horizontalAlignment: Text.AlignRight; rightPadding: Config.networkRightPadding; font.pixelSize: Config.uiFontSize(Config.networkValueFontSize); verticalAlignment: Text.AlignVCenter }
        }
    }
}

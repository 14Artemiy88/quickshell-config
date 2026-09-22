import QtQuick
import ".."

Frame {
    width: 313
    height: 55
    property var monitor
    Column {
        anchors.fill: parent
        anchors.margins: 5
        Row {
            width: parent.width
            height: 22
            Text { width: 28; text: ""; color: Config.networkUpload; font.pixelSize: Config.uiFontSize(16); leftPadding: 10 }
            Text { width: parent.width - 28; text: (monitor?.data?.net_stat?.speed_up ?? "0 B") + " / " + (monitor?.data?.net_stat?.up ?? "0 B"); color: Config.networkUpload; horizontalAlignment: Text.AlignRight; rightPadding: 5; font.pixelSize: Config.uiFontSize(13) }
        }
        Row {
            width: parent.width
            height: 22
            Text { width: 28; text: ""; color: Config.networkDownload; font.pixelSize: Config.uiFontSize(16); leftPadding: 10 }
            Text { width: parent.width - 28; text: (monitor?.data?.net_stat?.speed_down ?? "0 B") + " / " + (monitor?.data?.net_stat?.down ?? "0 B"); color: Config.networkDownload; horizontalAlignment: Text.AlignRight; rightPadding: 5; font.pixelSize: Config.uiFontSize(13) }
        }
    }
}

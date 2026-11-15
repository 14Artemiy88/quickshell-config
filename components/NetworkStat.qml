import QtQuick
import "primitives" as Primitives
import ".."

Primitives.ModuleFrame {
    id: root
    moduleName: "networkStat"
    width: 313
    height: 55
    property var monitor

    Column {
        spacing: Config.networkSpacing
        anchors.fill: parent
        anchors.topMargin: Config.networkTopPadding
        anchors.bottomMargin: 5

        NetworkStatRow {
            visible: Config.networkShowUpload
            width: parent.width
            glyph: ""
            accentColor: Config.networkUpload
            valueText: (root.monitor?.data?.net_stat?.speed_up ?? "0 B/s") + " / " + (root.monitor?.data?.net_stat?.up ?? "0 B")
        }

        NetworkStatRow {
            visible: Config.networkShowDownload
            width: parent.width
            glyph: ""
            accentColor: Config.networkDownload
            valueText: (root.monitor?.data?.net_stat?.speed_down ?? "0 B/s") + " / " + (root.monitor?.data?.net_stat?.down ?? "0 B")
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: Settings.networks && !Config.networksAlwaysVisible
        acceptedButtons: Qt.LeftButton
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.networksRequested()
    }

    signal networksRequested()
}

import QtQuick
import "primitives" as Primitives
import ".."

Primitives.ModuleFrame {
    id: root
    moduleName: "networkStat"
    width: 313
    height: 55
    property var monitor
    readonly property real networkStatRowHeight: Math.max(
        Config.uiFontSize(Config.networkIconSize),
        Config.uiFontSize(Config.networkValueFontSize)
    ) + Config.networkSpacing * 2
    // Keep the gap between rows proportional to the upload row's current
    // animated height. This lets the download row travel smoothly to y=0 when
    // upload is hidden, without leaving a final spacing jump.
    readonly property real networkStatRowGap: networkStatRowHeight > 0
        ? Config.networkSpacing * uploadRowMorph.geometryHeight / networkStatRowHeight
        : 0

    Item {
        anchors.fill: parent
        anchors.topMargin: Config.networkTopPadding
        anchors.bottomMargin: 5

        Primitives.MorphGeometry {
            id: uploadRowMorph
            clip: true
            visible: Config.networkShowUpload || normalizedProgress > 0.001
            fromGeometry: Qt.rect(0, 0, parent.width, 0)
            toGeometry: Qt.rect(0, 0, parent.width, root.networkStatRowHeight)
            progress: Config.networkShowUpload ? 1 : 0
            animationDuration: Config.animationDuration(180, "appearance")
            animationEasing: Config.animationEasingType("standard", Config.networkShowUpload ? "enter" : "exit")

            NetworkStatRow {
                width: parent.width
                glyph: ""
                accentColor: Config.networkUpload
                valueText: (root.monitor?.data?.net_stat?.speed_up ?? "0 B/s") + " / " + (root.monitor?.data?.net_stat?.up ?? "0 B")
            }
        }

        Primitives.MorphGeometry {
            id: downloadRowMorph
            y: uploadRowMorph.geometryHeight + root.networkStatRowGap
            clip: true
            visible: Config.networkShowDownload || normalizedProgress > 0.001
            fromGeometry: Qt.rect(0, 0, parent.width, 0)
            toGeometry: Qt.rect(0, 0, parent.width, root.networkStatRowHeight)
            progress: Config.networkShowDownload ? 1 : 0
            animationDuration: Config.animationDuration(180, "appearance")
            animationEasing: Config.animationEasingType("standard", Config.networkShowDownload ? "enter" : "exit")

            NetworkStatRow {
                width: parent.width
                glyph: ""
                accentColor: Config.networkDownload
                valueText: (root.monitor?.data?.net_stat?.speed_down ?? "0 B/s") + " / " + (root.monitor?.data?.net_stat?.down ?? "0 B")
            }
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

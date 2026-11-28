import QtQuick
import "primitives" as Primitives
import ".."

Primitives.ModuleFrame {
    id: root
    moduleName: "networkStat"
    width: 313
    height: 55
    property var monitor

    // Keep the configured regular presentation unchanged. Compact trims visual
    // density, while wide separates live throughput from accumulated totals.
    readonly property real presentationSizeFactor: root.compactPresentation ? 0.9
        : root.widePresentation ? 1.05 : 1
    readonly property int effectiveNetworkSpacing: root.compactPresentation
        ? Math.max(1, Math.round(Config.networkSpacing * 0.75))
        : root.widePresentation ? Math.max(1, Math.round(Config.networkSpacing * 1.25))
        : Config.networkSpacing
    readonly property int effectiveTopPadding: root.compactPresentation
        ? Math.round(Config.networkTopPadding * 0.75)
        : root.widePresentation ? Math.round(Config.networkTopPadding * 1.2)
        : Config.networkTopPadding
    readonly property int effectiveBottomPadding: root.compactPresentation ? 3
        : root.widePresentation ? 7 : 5
    readonly property real networkStatRowHeight: Math.max(
        Config.uiFontSize(Config.networkIconSize) * root.presentationSizeFactor,
        Config.uiFontSize(Config.networkValueFontSize) * root.presentationSizeFactor
    ) + root.effectiveNetworkSpacing * 2
    // Keep the gap between rows proportional to the upload row's current
    // animated height. This lets the download row travel smoothly to y=0 when
    // upload is hidden, without leaving a final spacing jump.
    readonly property real networkStatRowGap: networkStatRowHeight > 0
        ? root.effectiveNetworkSpacing * uploadRowMorph.geometryHeight / networkStatRowHeight
        : 0

    Item {
        anchors.fill: parent
        anchors.topMargin: root.effectiveTopPadding
        anchors.bottomMargin: root.effectiveBottomPadding

        Primitives.MorphGeometry {
            id: uploadRowMorph
            clip: true
            visible: Config.networkShowUpload || normalizedProgress > 0.001
            fromGeometry: Qt.rect(0, 0, parent.width, 0)
            toGeometry: Qt.rect(0, 0, parent.width, root.networkStatRowHeight)
            progress: Config.networkShowUpload ? 1 : 0
            animationDuration: Config.animationDuration(180, "appearance")
            animationProfile: Config.animationNetworkMorphProfile
            animationPhase: Config.networkShowUpload ? "enter" : "exit"

            NetworkStatRow {
                width: parent.width
                presentationMode: root.presentationMode
                glyph: ""
                accentColor: Config.networkUpload
                speedText: root.monitor?.data?.net_stat?.speed_up ?? "0 B/s"
                totalText: root.monitor?.data?.net_stat?.up ?? "0 B"
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
            animationProfile: Config.animationNetworkMorphProfile
            animationPhase: Config.networkShowDownload ? "enter" : "exit"

            NetworkStatRow {
                width: parent.width
                presentationMode: root.presentationMode
                glyph: ""
                accentColor: Config.networkDownload
                speedText: root.monitor?.data?.net_stat?.speed_down ?? "0 B/s"
                totalText: root.monitor?.data?.net_stat?.down ?? "0 B"
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

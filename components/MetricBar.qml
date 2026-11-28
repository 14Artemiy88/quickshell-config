import QtQuick
import "primitives" as Primitives
import ".."

Item {
    id: root
    property string label: ""
    property real value: 0
    property color fillColor: Config.accent
    property color trackColor: Config.metricTrack
    property bool verticalGauge: false
    property int valueAnimationDuration: 0
    property string valueAnimationProfile: "ease-out"
    property string direction: Config.cpuBarDirection
    property int rowHeight: Config.cpuRowHeight
    property int labelFontSize: 12
    property int barOffset: Config.cpuBarLeftOffset
    property int barWidth: Config.cpuBarWidth
    property int labelPadding: Config.cpuLabelLeftPadding
    property bool fillAvailableWidth: false
    readonly property bool verticalDirection: direction === "topToBottom" || direction === "bottomToTop"
    height: verticalGauge ? (parent ? parent.height : 200) : root.rowHeight
    width: verticalGauge ? (parent ? parent.width : 32) : (fillAvailableWidth && parent ? parent.width : 303)

    Text {
        visible: !root.verticalGauge
        x: root.labelPadding
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Config.text
        font.family: Config.font
        font.pixelSize: Config.uiFontSize(root.labelFontSize)
    }

    // Horizontal modes retain the existing track layout while sharing the
    // track/fill renderer with Top Apps.
    Primitives.ProgressTrack {
        visible: !root.verticalGauge
        x: root.barOffset
        y: (parent.height - Config.cpuBarThickness) / 2
        width: root.barWidth
        height: Config.cpuBarThickness
        radius: Config.cpuBarRadius
        value: root.value
        valueAnimationDuration: root.valueAnimationDuration
        valueAnimationProfile: root.valueAnimationProfile
        direction: root.direction
        fillColor: root.fillColor
        trackColor: root.trackColor
    }

    // Vertical modes switch the CPU/RAM widget to a set of vertical meters.
    // The available height is used as the track length so the bars fit the
    // module instead of overlapping neighboring rows.
    Primitives.ProgressTrack {
        visible: root.verticalGauge
        width: Math.min(Config.cpuBarThickness, Math.max(4, parent.width - 4))
        height: Math.max(20, Math.min(Config.cpuBarWidth, parent.height - 30))
        x: (parent.width - width) / 2
        y: 4
        radius: Math.min(Config.cpuBarRadius, width / 2)
        value: root.value
        valueAnimationDuration: root.valueAnimationDuration
        valueAnimationProfile: root.valueAnimationProfile
        direction: root.direction
        fillColor: root.fillColor
        trackColor: root.trackColor
    }

    Text {
        visible: root.verticalGauge
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.label
        color: Config.text
        font.family: Config.font
        font.pixelSize: Config.uiFontSize(12)
        elide: Text.ElideNone
    }
}

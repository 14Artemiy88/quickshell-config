import QtQuick
import "primitives" as Primitives
import ".."

Primitives.ModuleFrame {
    id: root
    moduleName: "time"
    width: 315
    height: 55
    property var clock
    readonly property real timePresentationScale: root.compactPresentation ? 0.86
        : root.widePresentation ? 1.04 : 1.0
    readonly property real datePresentationScale: root.compactPresentation ? 0.86 : 1.0
    // The row's side margins and inter-column gap are accounted for once here.
    // Keep the primary clock at its configured regular size; only the date
    // text scales when its measured width cannot fit beside the time.
    readonly property real availableContentWidth: Math.max(1, root.widthBudget - Config.clockPaddingX * 2 - Config.clockColumnSpacing)
    readonly property real effectiveCompactLayoutScale: {
        const required = configuredTimeMetrics.width + configuredDateMetrics.width
        return Math.max(0.25, Math.min(1, (root.availableContentWidth - Config.clockDetailsRightPadding - 3) / Math.max(1, required)))
    }
    readonly property real effectiveDateLayoutScale: {
        const dateWidth = Math.max(1, configuredDateMetrics.width)
        const dateAvailable = root.availableContentWidth - Math.ceil(configuredTimeMetrics.width) - 2 - Config.clockDetailsRightPadding
        return Math.max(0.25, Math.min(1, dateAvailable / dateWidth))
    }
    readonly property real effectiveCompactScale: root.compactPresentation ? effectiveCompactLayoutScale : 1.0
    readonly property int effectiveTimeFontSize: Math.max(1, Math.round(
        Config.uiFontSize(Config.clockFontSize) * timePresentationScale * effectiveCompactScale))
    readonly property int effectiveDateFontSize: Math.max(1, Math.round(
        Config.uiFontSize(Config.clockDateFontSize) * datePresentationScale
            * (root.compactPresentation ? effectiveCompactScale : effectiveDateLayoutScale)))
    readonly property int effectiveWeekdayFontSize: Math.max(1, Math.round(
        Config.uiFontSize(Config.clockWeekdayFontSize) * datePresentationScale * effectiveCompactScale))
    readonly property int effectiveTimeWidth: Math.max(1, Math.ceil(
        configuredTimeMetrics.width * effectiveCompactScale) + 2)

    TextMetrics {
        id: configuredTimeMetrics
        font.family: Config.clockFont || Config.ledFont
        font.pixelSize: Math.max(1, Config.uiFontSize(Config.clockFontSize) * root.timePresentationScale)
        text: root.clock ? root.clock.time : "00:00:00"
    }

    TextMetrics {
        id: configuredDateMetrics
        font.family: Config.clockDateFont || Config.clockFont || Config.ledFont
        font.pixelSize: Math.max(1, Config.uiFontSize(Config.clockDateFontSize) * root.datePresentationScale)
        text: root.clock ? root.clock.dateText : "00.00.0000"
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Config.clockPaddingX
        anchors.rightMargin: Config.clockPaddingX
        anchors.topMargin: Config.clockPaddingY
        anchors.bottomMargin: Config.clockPaddingY
        spacing: Config.clockColumnSpacing
        Text {
            id: timeText
            width: root.effectiveTimeWidth
            anchors.verticalCenter: parent.verticalCenter
            text: root.clock.time
            color: Config.clockTimeColor || Config.text
            font.family: Config.clockFont || Config.ledFont
            font.pixelSize: root.effectiveTimeFontSize
        }
        Column {
            width: Math.max(0, parent.width - timeText.width - parent.spacing)
            topPadding: 2
            Text {
                id: dateText
                width: parent.width
                horizontalAlignment: Text.AlignRight
                topPadding: 3
                rightPadding: Config.clockDetailsRightPadding
                text: root.clock.dateText
                color: Config.clockDateColor || Config.text
                font.family: Config.clockDateFont || Config.clockFont || Config.ledFont
                font.pixelSize: root.effectiveDateFontSize
                elide: Text.ElideRight
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) root.settingsRequested()
                        else root.calendarRequested()
                    }
                }
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignRight
                rightPadding: Config.clockDetailsRightPadding
                text: root.clock.weekday
                color: Config.clockWeekdayColor || Config.text
                font.family: Config.clockWeekdayFont || "Ubuntu"
                font.pixelSize: root.effectiveWeekdayFontSize
                elide: Text.ElideRight
            }
        }
    }

    signal calendarRequested()
    signal settingsRequested()
}

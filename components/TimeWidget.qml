import QtQuick
import "primitives" as Primitives
import ".."

Primitives.ModuleFrame {
    id: root
    moduleName: "time"
    width: 315
    height: 55
    property var clock

    Row {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 6
        spacing: 8
        Text {
            id: timeText
            width: Math.min(205, Math.max(165, Config.clockFontSize * 3.68))
            anchors.verticalCenter: parent.verticalCenter
            text: root.clock.time
            color: Config.text
            font.family: Config.clockFont || Config.ledFont
            font.pixelSize: Config.clockFontSize
        }
        Column {
            width: Math.max(0, parent.width - timeText.width - parent.spacing)
            topPadding: 2
            Text {
                id: dateText
                width: parent.width
                horizontalAlignment: Text.AlignRight
                topPadding: 3
                rightPadding: 6
                text: root.clock.dateText
                color: Config.text
                font.family: Config.clockFont || Config.ledFont
                font.pixelSize: Config.clockDateFontSize
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
                rightPadding: 6
                text: root.clock.weekday
                color: Config.text
                font.family: Config.clockWeekdayFont || "Ubuntu"
                font.pixelSize: Config.clockWeekdayFontSize
            }
        }
    }

    signal calendarRequested()
    signal settingsRequested()
}

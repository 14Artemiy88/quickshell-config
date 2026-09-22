import QtQuick
import ".."

Rectangle {
    id: root
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
            width: Math.min(205, Math.max(165, parent.width - 112))
            anchors.verticalCenter: parent.verticalCenter
            text: root.clock.time
            color: Config.text
            font.family: Config.ledFont
            font.pixelSize: 55
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
                font.family: Config.ledFont
                font.pixelSize: 25
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
                font.family: "Ubuntu"
                font.pixelSize: 15
            }
        }
    }

    // TimeWidget uses its own outer Rectangle so the global frame settings
    // are applied to this window unambiguously.
    color: Config.background
    border.color: Config.baseColor
    border.width: Config.frameBorderWidth
    radius: Config.frameRadius
    antialiasing: true
    signal calendarRequested()
    signal settingsRequested()
}

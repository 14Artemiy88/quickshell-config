import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common

Rectangle {
    anchors.top: parent.top
    anchors.topMargin: -10

    width: 40

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
    Text {
        id: timeblock
        text: Qt.formatDateTime(clock.date, "HH:mm:ss")
        color: Config.nonAccentColor
        font.family: Config.font
        font.pixelSize: 16
        Component.onCompleted: {
            parent.width = timeBlock.contentWidth;
        }
    }
}

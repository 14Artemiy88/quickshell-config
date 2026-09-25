import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common

import "../../launcher/theme"

Rectangle {
    Theme { id: theme }
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
        color: theme.nonAccent
        font.family: theme.fontFamily
        font.pixelSize: 16
        Component.onCompleted: {
            parent.width = timeBlock.contentWidth;
        }
    }
}

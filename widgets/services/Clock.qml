import QtQuick
import Quickshell

Item {
    id: root
    property date now: new Date()
    property bool active: true
    readonly property var weekdayNames: [
        "Воскресенье", "Понедельник", "Вторник", "Среда",
        "Четверг", "Пятница", "Суббота"
    ]
    readonly property string time: Qt.formatTime(now, "HH:mm:ss")
    readonly property string dateText: Qt.formatDate(now, "dd.MM.yyyy")
    readonly property string weekday: weekdayNames[now.getDay()]

    Timer {
        interval: 1000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
}

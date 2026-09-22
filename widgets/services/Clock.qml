import QtQuick
import Quickshell

Item {
    id: root
    property date now: new Date()
    readonly property string time: Qt.formatTime(now, "HH:mm:ss")
    readonly property string dateText: Qt.formatDate(now, "dd.MM.yyyy")
    readonly property string weekday: ["Воскресенье", "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота"][now.getDay()]

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
}

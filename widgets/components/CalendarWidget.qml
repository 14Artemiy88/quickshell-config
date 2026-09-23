import QtQuick
import ".."
import QtQuick.Controls

Frame {
    id: root
    width: 315
    height: 285
    property date date: new Date()
    property int year: date.getFullYear()
    property int month: date.getMonth()
    property bool open: true
    property var names: ["Пн","Вт","Ср","Чт","Пт","Сб","Вс"]
    clip: true
    opacity: root.open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Config.animationDuration(Config.animationCalendarSlideDuration); easing.type: Easing.OutCubic } }

    // У календаря снова отдельный, настраиваемый фон.
    Rectangle {
        anchors.fill: parent
        color: Config.calendarBackground
        radius: Config.frameRadius
        antialiasing: true
        z: -1
    }

    Item {
        id: reveal
        anchors.fill: parent
        anchors.margins: 5
        y: root.open ? 0 : -height
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.985
        transformOrigin: Item.Bottom

        Behavior on y { NumberAnimation { duration: Config.animationDuration(Config.animationCalendarSlideDuration); easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Config.animationDuration(Config.animationCalendarFadeDuration); easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Config.animationDuration(Config.animationCalendarSlideDuration); easing.type: Easing.OutCubic } }

        Column {
            anchors.fill: parent
            Text {
                width: parent.width
                text: root.monthName(root.month) + " " + root.year
                color: Config.text
                font.family: Config.ledFont
                font.pixelSize: 20
                horizontalAlignment: Text.AlignHCenter
            }
            Row {
                width: parent.width
                height: 25
                Repeater {
                    model: root.names
                    delegate: Text {
                        width: parent.width / 7
                        text: modelData
                        color: Config.textDim
                        horizontalAlignment: Text.AlignHCenter
                        font.bold: true
                    }
                }
            }
            Grid {
                width: parent.width
                columns: 7
                rowSpacing: 3
                Repeater {
                    model: 42
                    delegate: Rectangle {
                        width: parent.width / 7
                        height: 30
                        color: Config.transparent
                        property int day: index - root.firstDay() + 1
                        Text {
                            anchors.centerIn: parent
                            text: parent.day >= 1 && parent.day <= root.daysInMonth() ? parent.day : ""
                            color: parent.day === new Date().getDate() && root.month === new Date().getMonth() && root.year === new Date().getFullYear() ? Config.accent : Config.text
                            font.pixelSize: Config.uiFontSize(14)
                        }
                    }
                }
            }
        }
    }

    function firstDay() { let d = new Date(year, month, 1).getDay(); return d === 0 ? 6 : d - 1 }
    function daysInMonth() { return new Date(year, month + 1, 0).getDate() }
    function monthName(m) { return ["Январь","Февраль","Март","Апрель","Май","Июнь","Июль","Август","Сентябрь","Октябрь","Ноябрь","Декабрь"][m] }
}

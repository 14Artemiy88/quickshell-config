import QtQuick
import "." as Widgets
import ".."
import QtQuick.Controls

Widgets.Frame {
    id: root
    moduleName: "calendar"
    moduleBackgroundColor: Config.calendarBackground
    width: 315
    height: 285
    property date date: new Date()
    property int year: date.getFullYear()
    property int month: date.getMonth()
    property bool open: true
    property var names: ["Пн","Вт","Ср","Чт","Пт","Сб","Вс"]
    clip: true
    opacity: root.open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Config.animationDuration(Config.animationCalendarSlideDuration, "appearance"); easing.type: Config.easingType() } }

    Item {
        id: reveal
        anchors.fill: parent
        anchors.margins: 5
        y: root.open ? 0 : -height
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.985
        transformOrigin: Item.Bottom

        Behavior on y { NumberAnimation { duration: Config.animationDuration(Config.animationCalendarSlideDuration, "movement"); easing.type: Config.easingType() } }
        Behavior on opacity { NumberAnimation { duration: Config.animationDuration(Config.animationCalendarFadeDuration, "appearance"); easing.type: Config.easingType() } }
        Behavior on scale { NumberAnimation { duration: Config.animationDuration(Config.animationCalendarSlideDuration, "size"); easing.type: Config.easingType() } }

        Column {
            anchors.fill: parent
            Row {
                width: parent.width
                height: 25
                spacing: 4

                Item {
                    width: 28
                    height: parent.height
                    Text {
                        x: Config.calendarPreviousX
                        y: Config.calendarArrowY
                        width: parent.width
                        height: parent.height
                        text: Config.calendarPreviousIcon
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: Config.calendarPreviousSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.shiftMonth(-1)
                    }
                }

                Text {
                    width: parent.width - 64
                    height: parent.height
                    y: Config.calendarTitleY
                    text: root.monthName(root.month) + " " + root.year
                    color: Config.text
                    font.family: Config.calendarTitleFont
                    font.pixelSize: Config.calendarTitleFontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Item {
                    width: 28
                    height: parent.height
                    Text {
                        x: Config.calendarNextX
                        y: Config.calendarArrowY
                        width: parent.width
                        height: parent.height
                        text: Config.calendarNextIcon
                        color: Config.text
                        font.family: Config.font
                        font.pixelSize: Config.calendarNextSize
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.shiftMonth(1)
                    }
                }
            }
            Row {
                width: parent.width
                height: 25
                Repeater {
                    model: root.names
                    delegate: Text {
                        x: 0
                        width: parent.width / 7
                        height: parent.height
                        y: Config.calendarWeekdayY
                        text: modelData
                        color: Config.textDim
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: Config.calendarWeekdayFontSize
                        font.family: Config.calendarWeekdayFont
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
                            x: 0
                            width: parent.width
                            height: parent.height
                            y: Config.calendarDayY
                            text: parent.day >= 1 && parent.day <= root.daysInMonth() ? parent.day : ""
                            color: parent.day === new Date().getDate() && root.month === new Date().getMonth() && root.year === new Date().getFullYear() ? Config.accent : Config.text
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: Config.calendarDayFontSize
                            font.family: Config.calendarDayFont
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0)
                root.shiftMonth(1)
            else if (wheel.angleDelta.y < 0)
                root.shiftMonth(-1)
            wheel.accepted = true
        }
    }

    function shiftMonth(delta) {
        const d = new Date(root.year, root.month + delta, 1)
        root.year = d.getFullYear()
        root.month = d.getMonth()
    }

    function firstDay() { let d = new Date(year, month, 1).getDay(); return d === 0 ? 6 : d - 1 }
    function daysInMonth() { return new Date(year, month + 1, 0).getDate() }
    function monthName(m) { return ["Январь","Февраль","Март","Апрель","Май","Июнь","Июль","Август","Сентябрь","Октябрь","Ноябрь","Декабрь"][m] }
}

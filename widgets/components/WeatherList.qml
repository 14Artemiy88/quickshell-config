import QtQuick
import ".."
import Quickshell

Frame {
    id: root
    property var entries: []
    property bool hourly: true
    property var days: ["", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    property var displayEntries: []
    property int itemCount: hourly ? Config.weatherHourlyCount : Config.weatherDailyCount
    property int topPadding: Config.weatherListTopPadding

    function rebuild() {
        const now = Date.now() / 1000
        const future = (entries || []).filter(e => Number(e.date?.unix ?? 0) > now)
        displayEntries = future.slice(0, itemCount)
    }

    onEntriesChanged: rebuild()
    onItemCountChanged: rebuild()
    Component.onCompleted: rebuild()

    // Give the weather list its own visible surface. The positive z-order
    // avoids the background ending up behind the root item's stacking layer.
    Rectangle {
        anchors.fill: parent
        color: Config.background
        radius: Config.frameRadius
        antialiasing: true
        z: 0
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: height
        clip: true
        interactive: false
        z: 1

        Row {
            id: contentRow
            x: 0
            y: root.topPadding
            width: flick.width
            height: Math.max(0, flick.height - root.topPadding)
            spacing: 0

            Repeater {
                model: root.displayEntries
                delegate: Item {
                    width: contentRow.width / Math.max(1, root.itemCount)
                    height: contentRow.height

                    Text {
                        x: 0
                        y: 0
                        width: parent.width
                        height: 16
                        text: root.dayText(modelData)
                        color: Config.tempZero
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Image {
                        x: (parent.width - 35) / 2
                        y: 20
                        width: 35
                        height: 45
                        fillMode: Image.PreserveAspectFit
                        source: Quickshell.shellDir + "/assets/gismeteo/new_png/" + (modelData.icon || "") + ".png"
                    }

                    Text {
                        x: 0
                        y: root.hourly ? 65 : 66
                        width: parent.width
                        height: 18
                        text: root.highText(modelData)
                        color: root.tempColor(root.highNumber(modelData))
                        font.pixelSize: root.hourly ? 12 : 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        visible: !root.hourly
                        x: 0
                        y: 85
                        width: parent.width
                        height: 18
                        text: root.lowText(modelData)
                        color: root.tempColor(root.lowNumber(modelData))
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Config.transparent
        border.color: Config.baseColor
        border.width: Config.frameBorderWidth
        radius: Config.frameRadius
        z: 2
        antialiasing: true
    }

    function dayText(e) {
        const ts = Number(e.date?.unix ?? 0) * 1000
        const d = new Date(ts)
        if (hourly) return Qt.formatTime(d, "HH:mm")
        const day = d.getDate()
        const js = d.getDay()
        const mondayIndex = js === 0 ? 7 : js
        return day + " " + days[mondayIndex] + "."
    }
    function highNumber(e) { return Number(hourly ? e.temperature?.air?.C : e.temperature?.air?.max?.C) }
    function lowNumber(e) { return Number(e.temperature?.air?.min?.C) }
    function highText(e) {
        const n = highNumber(e)
        return Number.isFinite(n) ? ((n >= 30 ? "󰈸 " : "") + n + "°") : ""
    }
    function lowText(e) {
        const n = lowNumber(e)
        return Number.isFinite(n) ? n + "°" : ""
    }
    function tempColor(t) {
        if (t >= 30) return Config.tempHot
        if (t >= 20) return Config.tempWarm
        if (t >= 10) return Config.tempMild
        if (t > 0) return Config.tempCool
        if (t === 0) return Config.tempZero
        if (t > -10) return Config.tempCold
        if (t > -20) return Config.tempVeryCold
        if (t > -30) return Config.tempFreezing
        return Config.tempZero
    }
}

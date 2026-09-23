import QtQuick
import ".."
import Quickshell

Frame {
    id: root
    property var entries: []
    property bool hourly: true
    property var weatherService: null
    property var days: ["", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    property var displayEntries: []
    property int itemCount: hourly ? Config.weatherHourlyCount : Config.weatherDailyCount
    property int topPadding: Config.weatherListTopPadding
    property bool hasData: displayEntries.length > 0
    property string statusMessage: {
        if (!weatherService) return "Погода недоступна"
        return hourly ? weatherService.hourlyStatusMessage : weatherService.dailyStatusMessage
    }

    function rebuild() {
        const now = Date.now() / 1000
        const future = (entries || []).filter(e => Number(e.date?.unix ?? 0) > now)
        displayEntries = future.slice(0, itemCount)
    }

    onEntriesChanged: rebuild()
    onItemCountChanged: rebuild()
    Component.onCompleted: rebuild()

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
                        height: Config.weatherListDayHeight
                        text: root.dayText(modelData)
                        color: Config.tempZero
                        font.pixelSize: Config.uiFontSize(Config.weatherListDayFontSize)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Image {
                        x: (parent.width - Config.weatherListIconWidth) / 2
                        y: Config.weatherListIconY
                        width: Config.weatherListIconWidth
                        height: Config.weatherListIconHeight
                        fillMode: Image.PreserveAspectFit
                        source: Quickshell.shellDir + "/assets/gismeteo/new_png/" + (modelData.icon || "") + ".png"
                    }

                    Text {
                        x: 0
                        y: root.hourly ? Config.weatherListHourlyTempY : Config.weatherListDailyTempY
                        width: parent.width
                        height: Config.weatherListTempHeight
                        text: root.highText(modelData)
                        color: root.tempColor(root.highNumber(modelData))
                        font.pixelSize: root.hourly ? Config.uiFontSize(Config.weatherListHourlyTempFontSize) : Config.uiFontSize(Config.weatherListDailyTempFontSize)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        visible: !root.hourly
                        x: 0
                        y: Config.weatherListLowTempY
                        width: parent.width
                        height: Config.weatherListTempHeight
                        text: root.lowText(modelData)
                        color: root.tempColor(root.lowNumber(modelData))
                        font.pixelSize: Config.uiFontSize(Config.weatherListLowTempFontSize)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    WeatherPlaceholder {
        visible: !root.hasData
        z: 1.5
        message: root.statusMessage
        weatherService: root.weatherService
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

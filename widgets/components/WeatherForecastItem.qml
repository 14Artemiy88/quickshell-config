import QtQuick
import ".."
import Quickshell

Item {
    id: root
    property var entry: ({})
    property bool hourly: true
    property var days: ["", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    Text {
        x: 0
        y: root.hourly ? Config.weatherHourlyDayY : Config.weatherDailyDayY
        width: parent.width
        height: implicitHeight
        text: root.dayText(root.entry)
        color: Config.tempZero
        font.pixelSize: Config.uiFontSize(root.hourly ? Config.weatherHourlyDayFontSize : Config.weatherDailyDayFontSize)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Image {
        x: (parent.width - (root.hourly ? Config.weatherHourlyIconWidth : Config.weatherDailyIconWidth)) / 2
        y: root.hourly ? Config.weatherHourlyIconY : Config.weatherDailyIconY
        width: root.hourly ? Config.weatherHourlyIconWidth : Config.weatherDailyIconWidth
        height: root.hourly ? Config.weatherHourlyIconHeight : Config.weatherDailyIconHeight
        fillMode: Image.PreserveAspectFit
        source: Quickshell.shellDir + "/assets/gismeteo/new_png/" + (root.entry.icon || "") + ".png"
    }

    Text {
        x: root.hourly ? 0 : Config.weatherDailyHighTempX
        y: root.hourly ? Config.weatherHourlyTempY : Config.weatherDailyHighTempY
        width: parent.width
        height: root.hourly ? Config.weatherHourlyTempHeight : Config.weatherDailyHighTempHeight
        text: root.highText(root.entry)
        color: root.tempColor(root.highNumber(root.entry))
        font.pixelSize: root.hourly ? Config.uiFontSize(Config.weatherHourlyTempFontSize) : Config.uiFontSize(Config.weatherDailyHighTempFontSize)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        visible: !root.hourly
        x: Config.weatherDailyLowTempX
        y: Config.weatherDailyLowTempY
        width: parent.width
        height: Config.weatherDailyLowTempHeight
        text: root.lowText(root.entry)
        color: root.tempColor(root.lowNumber(root.entry))
        font.pixelSize: Config.uiFontSize(Config.weatherDailyLowTempFontSize)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
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

    function highNumber(e) {
        return Number(hourly ? e.temperature?.air?.C : e.temperature?.air?.max?.C)
    }

    function lowNumber(e) {
        return Number(e.temperature?.air?.min?.C)
    }

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

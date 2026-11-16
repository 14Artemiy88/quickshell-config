import QtQuick
import "primitives" as Primitives
import ".."
import Quickshell

Item {
    id: root
    property var entry: ({})
    property bool hourly: true
    property var days: ["", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    readonly property bool hasHighTemperature: root.highText(root.entry) !== ""
    readonly property bool hasLowTemperature: !root.hourly && root.lowText(root.entry) !== ""
    readonly property int forecastMorphDuration: Config.animationDuration(180, "appearance")

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

    // Keep forecast icons on the original direct Image path. Wrapping this
    // Image in MorphGeometry made the icons disappear in the live QML view.
    Image {
        x: (parent.width - (root.hourly ? Config.weatherHourlyIconWidth : Config.weatherDailyIconWidth)) / 2
        y: root.hourly ? Config.weatherHourlyIconY : Config.weatherDailyIconY
        width: root.hourly ? Config.weatherHourlyIconWidth : Config.weatherDailyIconWidth
        height: root.hourly ? Config.weatherHourlyIconHeight : Config.weatherDailyIconHeight
        fillMode: Image.PreserveAspectFit
        source: Quickshell.shellDir + "/assets/gismeteo/new_png/" + (root.entry.icon || "") + ".png"
    }

    Primitives.MorphGeometry {
        id: forecastHighTemperatureMorph
        fromGeometry: Qt.rect(
            root.hourly ? 0 : Config.weatherDailyHighTempX,
            root.hourly ? Config.weatherHourlyTempY : Config.weatherDailyHighTempY,
            parent.width,
            root.hourly ? Config.weatherHourlyTempHeight : Config.weatherDailyHighTempHeight)
        toGeometry: fromGeometry
        progress: root.hasHighTemperature ? 1 : 0
        visible: root.hasHighTemperature || normalizedProgress > 0.001
        animationDuration: root.forecastMorphDuration
        animationEasing: Config.animationEasingType("standard", root.hasHighTemperature ? "enter" : "exit")

        Text {
            anchors.fill: parent
            text: root.highText(root.entry)
            color: root.tempColor(root.highNumber(root.entry))
            font.pixelSize: root.hourly ? Config.uiFontSize(Config.weatherHourlyTempFontSize) : Config.uiFontSize(Config.weatherDailyHighTempFontSize)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: forecastHighTemperatureMorph.normalizedProgress
            scale: 0.96 + 0.04 * forecastHighTemperatureMorph.normalizedProgress
            transformOrigin: Item.Center
        }
    }

    Primitives.MorphGeometry {
        id: forecastLowTemperatureMorph
        fromGeometry: Qt.rect(Config.weatherDailyLowTempX, Config.weatherDailyLowTempY, parent.width, Config.weatherDailyLowTempHeight)
        toGeometry: fromGeometry
        progress: root.hasLowTemperature ? 1 : 0
        visible: root.hasLowTemperature || normalizedProgress > 0.001
        animationDuration: root.forecastMorphDuration
        animationEasing: Config.animationEasingType("standard", root.hasLowTemperature ? "enter" : "exit")

        Text {
            anchors.fill: parent
            text: root.lowText(root.entry)
            color: root.tempColor(root.lowNumber(root.entry))
            font.pixelSize: Config.uiFontSize(Config.weatherDailyLowTempFontSize)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: forecastLowTemperatureMorph.normalizedProgress
            scale: 0.96 + 0.04 * forecastLowTemperatureMorph.normalizedProgress
            transformOrigin: Item.Center
        }
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

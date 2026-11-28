import QtQuick
import "primitives" as Primitives
import ".."
import "../js/dashboard/DashboardCards.js" as DashboardCards
import Quickshell

Item {
    id: root
    property var entry: ({})
    property bool hourly: true
    property var days: ["", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    property string presentationMode: "regular"
    // Regular remains the exact legacy layout. Compact and wide modes respond
    // to the actual per-slot width, so a high saved forecast count cannot force
    // oversized content into a narrow column.
    readonly property real referenceSlotWidth: root.hourly ? 67 : 81
    readonly property real presentationScale: {
        if (root.presentationMode === "regular") return 1.0
        const widthScale = root.width / root.referenceSlotWidth
        const maximum = root.presentationMode === "wide" ? 1.2 : 1.0
        return Math.max(0.45, Math.min(maximum, widthScale))
    }
    readonly property bool hasHighTemperature: root.highText(root.entry) !== ""
    readonly property bool hasLowTemperature: !root.hourly && root.lowText(root.entry) !== ""
    readonly property int effectiveHighTemperatureX: root.presentationMode === "compact" ? 0 : Config.weatherDailyHighTempX
    readonly property int effectiveLowTemperatureX: root.presentationMode === "compact" ? 0 : Config.weatherDailyLowTempX
    readonly property string iconCode: DashboardCards.normalizeWeatherIconCode(root.entry && root.entry.icon)
    readonly property int forecastMorphDuration: Config.animationDurationForProfile(Config.animationWeatherMorphEnabled, Config.animationWeatherMorphProfile, Config.animationWeatherMorphDuration, "appearance")

    Text {
        x: 0
        y: root.hourly ? Config.weatherHourlyDayY : Config.weatherDailyDayY
        width: parent.width
        height: implicitHeight
        text: root.dayText(root.entry)
        color: Config.tempZero
        font.pixelSize: Config.uiFontSize(Math.max(6, Math.round((root.hourly ? Config.weatherHourlyDayFontSize : Config.weatherDailyDayFontSize) * root.presentationScale)))
        elide: root.presentationMode === "compact" ? Text.ElideRight : Text.ElideNone
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    // Keep forecast icons on the original direct Image path. Wrapping this
    // Image in MorphGeometry made the icons disappear in the live QML view.
    Image {
        id: forecastIconImage
        x: (parent.width - (root.hourly ? Config.weatherHourlyIconWidth : Config.weatherDailyIconWidth)) / 2
        y: root.hourly ? Config.weatherHourlyIconY : Config.weatherDailyIconY
        width: root.hourly ? Config.weatherHourlyIconWidth : Config.weatherDailyIconWidth
        height: root.hourly ? Config.weatherHourlyIconHeight : Config.weatherDailyIconHeight
        scale: root.presentationScale
        visible: root.iconCode !== ""
        fillMode: Image.PreserveAspectFit
        source: root.iconCode !== ""
                ? Quickshell.shellDir + "/assets/gismeteo/new_png/" + root.iconCode + ".png"
                : ""
    }

    Text {
        x: forecastIconImage.x
        y: forecastIconImage.y
        width: forecastIconImage.width
        height: forecastIconImage.height
        visible: root.iconCode !== "" && forecastIconImage.status !== Image.Ready
        scale: root.presentationScale
        text: "☁"
        color: Config.accent
        font.family: Config.settingsFontFamily
        font.pixelSize: Config.uiFontSize(Math.max(14, Math.round(Math.min(width, height) * 0.68)))
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Primitives.MorphGeometry {
        id: forecastHighTemperatureMorph
        fromGeometry: Qt.rect(
            root.hourly ? 0 : root.effectiveHighTemperatureX,
            root.hourly ? Config.weatherHourlyTempY : Config.weatherDailyHighTempY,
            parent.width,
            root.hourly ? Config.weatherHourlyTempHeight : Config.weatherDailyHighTempHeight)
        toGeometry: fromGeometry
        progress: root.hasHighTemperature ? 1 : 0
        visible: root.hasHighTemperature || normalizedProgress > 0.001
        animationDuration: root.forecastMorphDuration
        animationProfile: Config.animationWeatherMorphProfile
        animationPhase: root.hasHighTemperature ? "enter" : "exit"
        animationEasing: Config.animationEasingType(Config.animationWeatherMorphProfile, root.hasHighTemperature ? "enter" : "exit")

        Text {
            anchors.fill: parent
            text: root.highText(root.entry)
            color: root.tempColor(root.highNumber(root.entry))
            font.pixelSize: root.hourly
                ? Config.uiFontSize(Math.max(6, Math.round(Config.weatherHourlyTempFontSize * root.presentationScale)))
                : Config.uiFontSize(Math.max(6, Math.round(Config.weatherDailyHighTempFontSize * root.presentationScale)))
            elide: Text.ElideNone
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: forecastHighTemperatureMorph.normalizedProgress
            scale: 0.96 + 0.04 * forecastHighTemperatureMorph.normalizedProgress
            transformOrigin: Item.Center
        }
    }

    Primitives.MorphGeometry {
        id: forecastLowTemperatureMorph
        fromGeometry: Qt.rect(root.effectiveLowTemperatureX, Config.weatherDailyLowTempY, parent.width, Config.weatherDailyLowTempHeight)
        toGeometry: fromGeometry
        progress: root.hasLowTemperature ? 1 : 0
        visible: root.hasLowTemperature || normalizedProgress > 0.001
        animationDuration: root.forecastMorphDuration
        animationProfile: Config.animationWeatherMorphProfile
        animationPhase: root.hasLowTemperature ? "enter" : "exit"
        animationEasing: Config.animationEasingType(Config.animationWeatherMorphProfile, root.hasLowTemperature ? "enter" : "exit")

        Text {
            anchors.fill: parent
            text: root.lowText(root.entry)
            color: root.tempColor(root.lowNumber(root.entry))
            font.pixelSize: Config.uiFontSize(Math.max(6, Math.round(Config.weatherDailyLowTempFontSize * root.presentationScale)))
            elide: Text.ElideNone
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: forecastLowTemperatureMorph.normalizedProgress
            scale: 0.96 + 0.04 * forecastLowTemperatureMorph.normalizedProgress
            transformOrigin: Item.Center
        }
    }

    function dayText(e) {
        const timestamp = DashboardCards.normalizeWeatherUnixTimestamp(e && e.date ? e.date.unix : null)
        if (!Number.isFinite(timestamp)) return ""

        const d = new Date(timestamp * 1000)
        if (!Number.isFinite(d.getTime())) return ""
        if (hourly) return Qt.formatTime(d, "HH:mm")
        const day = d.getDate()
        const js = d.getDay()
        const mondayIndex = js === 0 ? 7 : js
        return day + " " + days[mondayIndex] + "."
    }

    function normalizedTemperatureNumber(value) {
        const normalized = DashboardCards.normalizeWeatherTemperature(value)
        return normalized !== "" ? Number(normalized.replace(",", ".")) : NaN
    }

    function highNumber(e) {
        const value = hourly ? e.temperature?.air?.C : e.temperature?.air?.max?.C
        return normalizedTemperatureNumber(value)
    }

    function lowNumber(e) {
        return normalizedTemperatureNumber(e.temperature?.air?.min?.C)
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

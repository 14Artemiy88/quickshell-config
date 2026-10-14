import QtQuick
import "primitives" as Primitives
import ".."

Primitives.ModuleFrame {
    id: root
    moduleName: hourly ? "weatherHourly" : "weatherDaily"
    property var entries: []
    property bool hourly: true
    property var weatherService: null
    property var days: ["", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    property var displayEntries: []
    // Hourly scrolling is intentionally transient: it never writes back to Config.
    // -1 means use the saved value from Settings; a positive value is the live override.
    property int temporaryHourlyCount: -1
    property int availableHourlyCount: 12
    readonly property int itemCount: hourly
        ? Math.max(1, Math.min(temporaryHourlyCount > 0 ? temporaryHourlyCount : Config.weatherHourlyCount, availableHourlyCount))
        : Config.weatherDailyCount
    property int topPadding: root.hourly ? Config.weatherHourlyTopPadding : Config.weatherDailyTopPadding
    property bool hasData: displayEntries.length > 0
    property string statusMessage: {
        if (!weatherService) return "Погода недоступна"
        return hourly ? weatherService.hourlyStatusMessage : weatherService.dailyStatusMessage
    }

    function rebuild() {
        const now = Date.now() / 1000
        const future = (entries || []).filter(e => Number(e.date?.unix ?? 0) > now)
        if (hourly) {
            // Keep the temporary wheel override within the forecast data we actually have.
            availableHourlyCount = Math.min(12, Math.max(1, future.length))
        }
        displayEntries = future.slice(0, itemCount)
    }

    function adjustHourlyCount(direction) {
        if (!hourly || direction === 0) return
        const current = itemCount
        const maximum = Math.min(12, Math.max(1, availableHourlyCount))
        const next = Math.max(1, Math.min(maximum, current + (direction > 0 ? 1 : -1)))
        // Returning to the configured count clears the override entirely.
        temporaryHourlyCount = next === Config.weatherHourlyCount ? -1 : next
        rebuild()
    }

    onEntriesChanged: rebuild()
    onItemCountChanged: rebuild()
    Component.onCompleted: rebuild()

    Connections {
        target: Config
        function onWeatherHourlyCountChanged() {
            root.temporaryHourlyCount = -1
            root.rebuild()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.moduleBackgroundVisible ? Config.background : Config.transparent
        border.color: root.moduleFrameVisible ? Config.baseColor : Config.transparent
        border.width: root.moduleFrameVisible ? Config.frameBorderWidth : 0
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
                delegate: WeatherForecastItem {
                    width: contentRow.width / Math.max(1, root.itemCount)
                    height: contentRow.height
                    entry: modelData
                    hourly: root.hourly
                    days: root.days
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

    // No mouse buttons are accepted, so regular clicks still reach the weather
    // module. The wheel only changes the live count for the hourly forecast.
    MouseArea {
        anchors.fill: parent
        z: 3
        visible: root.hourly
        acceptedButtons: Qt.NoButton
        onWheel: function(wheel) {
            const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y
            if (delta !== 0) {
                root.adjustHourlyCount(delta > 0 ? 1 : -1)
                wheel.accepted = true
            }
        }
    }
}

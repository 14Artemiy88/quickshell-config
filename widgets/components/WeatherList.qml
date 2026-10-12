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
    property int itemCount: hourly ? Config.weatherHourlyCount : Config.weatherDailyCount
    property int topPadding: root.hourly ? Config.weatherHourlyTopPadding : Config.weatherDailyTopPadding
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
}

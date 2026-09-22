import QtQuick
import Quickshell
import Quickshell.Wayland
import "components"
import "services"

ShellRoot {
    id: shell
    Clock { id: clock }
    SystemMonitor { id: monitor }
    Loader {
        id: weatherLoader
        active: Settings.loaded && (Settings.weatherNow || Settings.weatherHourly || Settings.weatherDaily)
        sourceComponent: Component { Weather {} }
    }
    property bool calendarVisible: false
    property bool settingsVisible: false
    property bool timerOptionsVisible: false

    WidgetWindow { visible: Settings.time; offsetX: Settings.geometry.time[0]; offsetY: Settings.geometry.time[1]; contentWidth: Settings.geometry.time[2]; contentHeight: Settings.geometry.time[3]
        TimeWidget { anchors.fill: parent; clock: clock; onCalendarRequested: shell.calendarVisible = !shell.calendarVisible; onSettingsRequested: shell.settingsVisible = !shell.settingsVisible }
    }
    WidgetWindow { visible: Settings.cpu; offsetX: Settings.geometry.cpu[0]; offsetY: Settings.geometry.cpu[1]; contentWidth: Settings.geometry.cpu[2]; contentHeight: Settings.geometry.cpu[3]; CpuWidget { anchors.fill: parent } }
    WidgetWindow { visible: Settings.cpuGraph; offsetX: Settings.geometry.cpuGraph[0]; offsetY: Settings.geometry.cpuGraph[1]; contentWidth: Settings.geometry.cpuGraph[2]; contentHeight: Settings.geometry.cpuGraph[3]; CpuGraph { anchors.fill: parent } }
    WidgetWindow { visible: Settings.topApps; offsetX: Settings.geometry.topApps[0]; offsetY: Settings.geometry.topApps[1]; contentWidth: Settings.geometry.topApps[2]; contentHeight: Settings.geometry.topApps[3]; TopApps { anchors.fill: parent; monitor: monitor } }
    WidgetWindow { visible: Settings.networkStat; offsetX: Settings.geometry.networkStat[0]; offsetY: Settings.geometry.networkStat[1]; contentWidth: Settings.geometry.networkStat[2]; contentHeight: Settings.geometry.networkStat[3]; NetworkStat { anchors.fill: parent; monitor: monitor } }
    WidgetWindow { visible: Settings.weatherNow; offsetX: Settings.geometry.weatherNow[0]; offsetY: Settings.geometry.weatherNow[1]; contentWidth: Settings.geometry.weatherNow[2]; contentHeight: Settings.geometry.weatherNow[3]; WeatherNow { anchors.fill: parent; weather: weatherLoader.item ? weatherLoader.item.now : ({}); weatherService: weatherLoader.item } }
    WidgetWindow { visible: Settings.weatherHourly; offsetX: Settings.geometry.weatherHourly[0]; offsetY: Settings.geometry.weatherHourly[1]; contentWidth: Settings.geometry.weatherHourly[2]; contentHeight: Settings.geometry.weatherHourly[3]; WeatherList { anchors.fill: parent; entries: weatherLoader.item ? weatherLoader.item.day : []; hourly: true } }
    WidgetWindow { visible: Settings.weatherDaily; offsetX: Settings.geometry.weatherDaily[0]; offsetY: Settings.geometry.weatherDaily[1]; contentWidth: Settings.geometry.weatherDaily[2]; contentHeight: Settings.geometry.weatherDaily[3]; WeatherList { anchors.fill: parent; entries: weatherLoader.item ? weatherLoader.item.week : []; hourly: false } }
    WidgetWindow { visible: Settings.timer; offsetX: Settings.geometry.timer[0]; offsetY: Settings.geometry.timer[1]; contentWidth: Settings.geometry.timer[2]; contentHeight: timerWidget.adaptiveHeight; TimerWidget { id: timerWidget; anchors.fill: parent } }
    WidgetWindow {
        id: timerOptionsOverlay
        visible: Settings.timer && shell.timerOptionsVisible
        offsetX: 0
        offsetY: 0
        contentWidth: timerOverlayScreen ? timerOverlayScreen.width : 1
        contentHeight: timerOverlayScreen ? timerOverlayScreen.height : 1
        bottomLayer: false
        screen: timerOverlayScreen

        property var timerOverlayScreen: Quickshell.screens.find(s =>
            s.name === Config.monitorName ||
            s.model === Config.monitorName ||
            s.toString() === Config.monitorName
        ) || Quickshell.screens[0]

        MouseArea {
            anchors.fill: parent
            z: 0
            onClicked: timerOptionsPopup.startClose()
        }

        TimerOptions {
            id: timerOptionsPopup
            // Keep the action mini-window at its original configurable
            // position. The full-screen transparent parent still lets a click
            // anywhere outside the mini-window close it.
            x: Settings.geometry.timerOptions[0]
            y: Settings.geometry.timerOptions[1]
            width: Settings.geometry.timerOptions[2]
            height: Settings.geometry.timerOptions[3]
            z: 1
            timers: timerWidget.timers
            selectedFile: timerWidget.selectedFile
            onCloseRequested: timerOptionsPopup.startClose()
            onCloseFinished: {
                timerWidget.selectedFile = ""
                shell.timerOptionsVisible = false
                timerOptionsPopup.closing = false
            }
        }
    }

    Connections {
        target: timerWidget
        function onSelectedFileChanged() {
            if (timerWidget.selectedFile !== "") {
                shell.timerOptionsVisible = true
                timerOptionsPopup.closing = false
            } else if (shell.timerOptionsVisible && !timerOptionsPopup.closing) {
                timerOptionsPopup.startClose()
            }
        }
    }
    WidgetWindow { visible: shell.calendarVisible && Settings.calendar; offsetX: Settings.geometry.calendar[0]; offsetY: Settings.geometry.calendar[1]; contentWidth: Settings.geometry.calendar[2]; contentHeight: Settings.geometry.calendar[3]; bottomLayer: false; CalendarWidget { anchors.fill: parent; date: clock.now; open: shell.calendarVisible } }

    WidgetWindow { visible: Settings.volumes; offsetX: Settings.geometry.volumes[0]; offsetY: Settings.geometry.volumes[1]; contentWidth: Settings.geometry.volumes[2]; contentHeight: Math.min(Config.volumeMaxHeight, volumesWidget.adaptiveHeight); Volumes { id: volumesWidget; anchors.fill: parent; monitor: monitor } }
    WidgetWindow { visible: Settings.player; offsetX: Settings.geometry.player[0]; offsetY: Settings.geometry.player[1]; contentWidth: Settings.geometry.player[2]; contentHeight: Settings.geometry.player[3]; backgroundBlurEnabled: Config.playerBlurEnabled; backgroundBlurRadius: Config.playerBlurRadius; Player { anchors.fill: parent; anchors.margins: 0 } }
    WidgetWindow { visible: Settings.cava; offsetX: Settings.geometry.cava[0]; offsetY: Settings.geometry.cava[1]; contentWidth: Settings.geometry.cava[2]; contentHeight: Settings.geometry.cava[3]; Cava { anchors.fill: parent } }
    WidgetWindow { visible: Settings.networks; offsetX: Settings.geometry.networks[0]; offsetY: Settings.geometry.networks[1]; contentWidth: Settings.geometry.networks[2]; contentHeight: Settings.geometry.networks[3]; Networks { anchors.fill: parent; monitor: monitor } }

    WidgetWindow {
        visible: shell.settingsVisible
        keyboardEnabled: shell.settingsVisible
        offsetX: Settings.settingsGeometry[0]
        offsetY: Settings.settingsGeometry[1]
        contentWidth: Settings.settingsGeometry[2]
        contentHeight: Settings.settingsGeometry[3]
        bottomLayer: false
        SettingsWidget { anchors.fill: parent }
    }
}

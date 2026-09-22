import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    property var now: ({})
    property var day: []
    property var week: []
    property int manualPending: 0

    function refreshNow(forceApi) {
        if (Settings.loaded && Settings.weatherNow) {
            if (nowProc.running) {
                if (forceApi) nowProc.forceNext = true
            } else {
                nowProc.force = !!forceApi
                nowProc.running = true
            }
        }
    }

    function refreshHourly(forceApi) {
        if (Settings.loaded && Settings.weatherHourly) {
            if (dayProc.running) {
                if (forceApi) dayProc.forceNext = true
            } else {
                dayProc.force = !!forceApi
                dayProc.running = true
            }
        }
    }

    function refreshDaily(forceApi) {
        if (Settings.loaded && Settings.weatherDaily) {
            if (weekProc.running) {
                if (forceApi) weekProc.forceNext = true
            } else {
                weekProc.force = !!forceApi
                weekProc.running = true
            }
        }
    }

    function resetRefreshTimers() {
        if (Settings.weatherNow) nowTimer.restart(); else nowTimer.stop()
        if (Settings.weatherHourly) dayTimer.restart(); else dayTimer.stop()
        if (Settings.weatherDaily) weekTimer.restart(); else weekTimer.stop()
    }

    function finishManualRequest(wasForced) {
        if (!wasForced) return
        manualPending = Math.max(0, manualPending - 1)
        if (manualPending === 0)
            resetRefreshTimers()
    }

    // Force-refresh every enabled weather feed and restart its auto-refresh timer
    // after the requests have completed. The weather script bypasses its cache
    // when invoked with --force.
    function manualRefresh() {
        if (!Settings.loaded) return
        manualPending = 0
        if (Settings.weatherNow) manualPending++
        if (Settings.weatherHourly) manualPending++
        if (Settings.weatherDaily) manualPending++
        if (manualPending === 0) return

        refreshNow(true)
        refreshHourly(true)
        refreshDaily(true)
    }

    Process {
        id: nowProc
        property bool force: false
        property bool forceNext: false
        command: force
                 ? [Quickshell.shellDir + "/scripts/weather", "now", "--force"]
                 : [Quickshell.shellDir + "/scripts/weather", "now"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const wasForced = nowProc.force
                try { root.now = JSON.parse(this.text) } catch (e) {}
                nowProc.running = false
                if (nowProc.forceNext) {
                    nowProc.forceNext = false
                    nowProc.force = true
                    nowProc.running = true
                    return
                }
                nowProc.force = false
                root.finishManualRequest(wasForced)
            }
        }
    }

    Timer {
        id: nowTimer
        interval: Config.weatherNowIntervalMinutes * 60000
        running: Settings.loaded && Settings.weatherNow
        repeat: true
        onTriggered: root.refreshNow(false)
    }

    Process {
        id: dayProc
        property bool force: false
        property bool forceNext: false
        command: force
                 ? [Quickshell.shellDir + "/scripts/weather", "day", "--force"]
                 : [Quickshell.shellDir + "/scripts/weather", "day"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const wasForced = dayProc.force
                try { root.day = JSON.parse(this.text) } catch (e) {}
                dayProc.running = false
                if (dayProc.forceNext) {
                    dayProc.forceNext = false
                    dayProc.force = true
                    dayProc.running = true
                    return
                }
                dayProc.force = false
                root.finishManualRequest(wasForced)
            }
        }
    }

    Timer {
        id: dayTimer
        interval: Config.weatherHourlyIntervalMinutes * 60000
        running: Settings.loaded && Settings.weatherHourly
        repeat: true
        onTriggered: root.refreshHourly(false)
    }

    Process {
        id: weekProc
        property bool force: false
        property bool forceNext: false
        command: force
                 ? [Quickshell.shellDir + "/scripts/weather", "week", "--force"]
                 : [Quickshell.shellDir + "/scripts/weather", "week"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const wasForced = weekProc.force
                try { root.week = JSON.parse(this.text) } catch (e) {}
                weekProc.running = false
                if (weekProc.forceNext) {
                    weekProc.forceNext = false
                    weekProc.force = true
                    weekProc.running = true
                    return
                }
                weekProc.force = false
                root.finishManualRequest(wasForced)
            }
        }
    }

    Timer {
        id: weekTimer
        interval: Config.weatherDailyIntervalMinutes * 60000
        running: Settings.loaded && Settings.weatherDaily
        repeat: true
        onTriggered: root.refreshDaily(false)
    }

    Connections {
        target: Settings
        function onWeatherNowChanged() {
            if (Settings.weatherNow)
                root.refreshNow(false)
            else
                nowProc.running = false
        }
        function onWeatherHourlyChanged() {
            if (Settings.weatherHourly)
                root.refreshHourly(false)
            else
                dayProc.running = false
        }
        function onWeatherDailyChanged() {
            if (Settings.weatherDaily)
                root.refreshDaily(false)
            else
                weekProc.running = false
        }
    }

    Component.onCompleted: {
        refreshNow(false)
        refreshHourly(false)
        refreshDaily(false)
    }
}

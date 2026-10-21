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
    property int manualCooldownRemaining: 0
    readonly property bool manualRefreshCoolingDown: manualCooldownRemaining > 0

    property string nowStatus: "idle"
    property string hourlyStatus: "idle"
    property string dailyStatus: "idle"

    readonly property string nowStatusMessage: statusMessage(nowStatus)
    readonly property string hourlyStatusMessage: statusMessage(hourlyStatus)
    readonly property string dailyStatusMessage: statusMessage(dailyStatus)

    function hasValidObject(value) {
        return value && typeof value === "object" && !Array.isArray(value) && Object.keys(value).length > 0
    }

    function hasValidArray(value) {
        return Array.isArray(value) && value.length > 0
    }

    function statusMessage(status) {
        if (!String(Settings.weatherToken || "").trim())
            return "Нет токена Gismeteo"
        if (status === "loading")
            return "Загрузка погоды…"
        if (status === "error")
            return "Не удалось получить погоду"
        return "Погода недоступна"
    }

    function retryIntervalMs() {
        const minutes = Math.max(1, Number(Config.weatherRetryDelayMinutes) || 10)
        return minutes * 60000
    }

    function refreshNow(forceApi) {
        if (Settings.loaded && Settings.weatherNow) {
            nowRetryTimer.stop()
            if (nowProc.running) {
                if (forceApi) nowProc.forceNext = true
            } else {
                nowProc.force = !!forceApi
                nowStatus = "loading"
                nowProc.running = true
            }
        }
    }

    function refreshHourly(forceApi) {
        if (Settings.loaded && Settings.weatherHourly) {
            hourlyRetryTimer.stop()
            if (dayProc.running) {
                if (forceApi) dayProc.forceNext = true
            } else {
                dayProc.force = !!forceApi
                hourlyStatus = "loading"
                dayProc.running = true
            }
        }
    }

    function refreshDaily(forceApi) {
        if (Settings.loaded && Settings.weatherDaily) {
            dailyRetryTimer.stop()
            if (weekProc.running) {
                if (forceApi) weekProc.forceNext = true
            } else {
                weekProc.force = !!forceApi
                dailyStatus = "loading"
                weekProc.running = true
            }
        }
    }

    function finishFeed(feed, proc, text) {
        const wasForced = proc.force
        let parsed = null
        let success = false

        try {
            parsed = JSON.parse(text)
            if (feed === "now") success = hasValidObject(parsed)
            else success = hasValidArray(parsed)
        } catch (e) {
            success = false
        }

        if (feed === "now") {
            if (success) {
                now = parsed
                nowStatus = "ready"
                nowRetryTimer.stop()
                nowTimer.restart()
            } else {
                nowStatus = "error"
                nowTimer.stop()
                nowRetryTimer.interval = retryIntervalMs()
                nowRetryTimer.restart()
            }
        } else if (feed === "hourly") {
            if (success) {
                day = parsed
                hourlyStatus = "ready"
                hourlyRetryTimer.stop()
                dayTimer.restart()
            } else {
                hourlyStatus = "error"
                dayTimer.stop()
                hourlyRetryTimer.interval = retryIntervalMs()
                hourlyRetryTimer.restart()
            }
        } else if (feed === "daily") {
            if (success) {
                week = parsed
                dailyStatus = "ready"
                dailyRetryTimer.stop()
                weekTimer.restart()
            } else {
                dailyStatus = "error"
                weekTimer.stop()
                dailyRetryTimer.interval = retryIntervalMs()
                dailyRetryTimer.restart()
            }
        }

        proc.running = false

        if (proc.forceNext) {
            proc.forceNext = false
            if (feed === "now") nowRetryTimer.stop()
            else if (feed === "hourly") hourlyRetryTimer.stop()
            else dailyRetryTimer.stop()
            proc.force = true
            if (feed === "now") {
                nowStatus = "loading"
            } else if (feed === "hourly") {
                hourlyStatus = "loading"
            } else {
                dailyStatus = "loading"
            }
            proc.running = true
            return
        }

        proc.force = false
        if (wasForced) {
            manualPending = Math.max(0, manualPending - 1)
        }
    }

    function startCooldown() {
        manualCooldownRemaining = Math.max(1, Math.round(Number(Config.weatherManualRefreshCooldownSeconds) || 30))
        manualCooldownTimer.restart()
    }

    // Force-refresh every enabled weather feed while rate-limiting repeated clicks.
    // Successful requests reset their normal update timer; failed requests use the
    // retry delay instead, so a broken API/network cannot be hammered.
    function manualRefresh() {
        if (!Settings.loaded || manualRefreshCoolingDown)
            return
        if (!String(Settings.weatherToken || "").trim()) {
            nowStatus = "error"
            hourlyStatus = "error"
            dailyStatus = "error"
            return
        }

        manualPending = 0
        if (Settings.weatherNow) manualPending++
        if (Settings.weatherHourly) manualPending++
        if (Settings.weatherDaily) manualPending++
        if (manualPending === 0) return

        startCooldown()
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
            onStreamFinished: root.finishFeed("now", nowProc, this.text)
        }
    }

    Timer {
        id: nowTimer
        interval: Config.weatherNowIntervalMinutes * 60000
        running: Settings.loaded && Settings.weatherNow && root.nowStatus === "ready"
        repeat: true
        onTriggered: root.refreshNow(false)
    }

    Timer {
        id: nowRetryTimer
        interval: root.retryIntervalMs()
        repeat: false
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
            onStreamFinished: root.finishFeed("hourly", dayProc, this.text)
        }
    }

    Timer {
        id: dayTimer
        interval: Config.weatherHourlyIntervalMinutes * 60000
        running: Settings.loaded && Settings.weatherHourly && root.hourlyStatus === "ready"
        repeat: true
        onTriggered: root.refreshHourly(false)
    }

    Timer {
        id: hourlyRetryTimer
        interval: root.retryIntervalMs()
        repeat: false
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
            onStreamFinished: root.finishFeed("daily", weekProc, this.text)
        }
    }

    Timer {
        id: weekTimer
        interval: Config.weatherDailyIntervalMinutes * 60000
        running: Settings.loaded && Settings.weatherDaily && root.dailyStatus === "ready"
        repeat: true
        onTriggered: root.refreshDaily(false)
    }

    Timer {
        id: dailyRetryTimer
        interval: root.retryIntervalMs()
        repeat: false
        onTriggered: root.refreshDaily(false)
    }

    Timer {
        id: manualCooldownTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            manualCooldownRemaining = Math.max(0, manualCooldownRemaining - 1)
            if (manualCooldownRemaining === 0)
                stop()
        }
    }

    Connections {
        target: Settings

        function onWeatherNowChanged() {
            if (Settings.weatherNow) {
                nowStatus = "idle"
                refreshNow(false)
            } else {
                nowProc.forceNext = false
                nowProc.running = false
                nowTimer.stop()
                nowRetryTimer.stop()
                nowStatus = "idle"
            }
        }

        function onWeatherHourlyChanged() {
            if (Settings.weatherHourly) {
                hourlyStatus = "idle"
                refreshHourly(false)
            } else {
                dayProc.forceNext = false
                dayProc.running = false
                dayTimer.stop()
                hourlyRetryTimer.stop()
                hourlyStatus = "idle"
            }
        }

        function onWeatherDailyChanged() {
            if (Settings.weatherDaily) {
                dailyStatus = "idle"
                refreshDaily(false)
            } else {
                weekProc.forceNext = false
                weekProc.running = false
                weekTimer.stop()
                dailyRetryTimer.stop()
                dailyStatus = "idle"
            }
        }

        function onWeatherTokenChanged() {
            if (!String(Settings.weatherToken || "").trim()) {
                nowStatus = "error"
                hourlyStatus = "error"
                dailyStatus = "error"
                return
            }
            if (Settings.weatherNow) refreshNow(true)
            if (Settings.weatherHourly) refreshHourly(true)
            if (Settings.weatherDaily) refreshDaily(true)
        }
    }

    Component.onCompleted: {
        if (String(Settings.weatherToken || "").trim()) {
            refreshNow(false)
            refreshHourly(false)
            refreshDaily(false)
        } else {
            nowStatus = "error"
            hourlyStatus = "error"
            dailyStatus = "error"
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../js/dashboard/DashboardCards.js" as DashboardCards

PanelWindow {
    id: root

    property bool open: false
    // Keep the full-screen click-catcher alive only while opening/closing the
    // drawer. It must not create a transparent desktop-sized surface at startup.
    property bool keepWindowDuringClose: false
    property var clock: null
    property var cpuSource: null
    property var playerSource: null
    property var weatherSource: null
    property var monitorSource: null
    // Arrow-key navigation is spatial and starts without selecting a control.
    // The drawer itself receives keys until the user moves focus to a target.
    property var navigationTargets: []
    property var currentNavigationTarget: null
    // Retain the last focused target and its drawer-relative centre. If that
    // target is hidden, disabled, or destroyed while the Dashboard is open,
    // focus can move to the nearest remaining actionable element.
    property var lastNavigationTarget: null
    property point navigationAnchor: Qt.point(0, 0)
    property bool hasNavigationAnchor: false
    property bool navigationStarted: false
    // Preserve a card's logical identity across Repeater model rebuilds. The
    // focused Item may be destroyed/reused when Bento orientation or order
    // changes, but the card id remains the stable navigation target.
    property string navigationCardId: ""
    property bool cardsScrollClampScheduled: false
    property bool navigationLayoutRestoreScheduled: false

    signal closeRequested()
    signal launcherRequested()
    signal calendarRequested()
    signal settingsRequested()
    signal moduleSettingsRequested(string pageId)

    readonly property var playerData: root.playerSource && root.playerSource.player
                                      ? root.playerSource.player : ({})
    readonly property var weatherData: root.weatherSource && root.weatherSource.now
                                       ? root.weatherSource.now : ({})
    readonly property int cpuUsage: {
        if (!Settings.cpu || !root.cpuSource || !root.cpuSource.stats
                || !Array.isArray(root.cpuSource.stats.cpu)
                || root.cpuSource.stats.cpu.length === 0)
            return -1
        var values = root.cpuSource.stats.cpu
        var total = 0
        var count = 0
        for (var i = 0; i < values.length; ++i) {
            var value = Number(values[i])
            if (!isFinite(value)) continue
            total += Math.max(0, Math.min(100, value))
            count++
        }
        return count > 0 ? Math.round(total / count) : -1
    }
    readonly property int ramUsage: {
        if (!Settings.cpu || !root.cpuSource || !root.cpuSource.stats)
            return -1

        // CpuWidget starts with a zero-valued placeholder before its first
        // sampler snapshot. Do not present that placeholder as real 0% RAM.
        // The snapshot's CPU array and RAM field become available together
        // when cpu_stats_once has returned a valid payload.
        var cpuSamples = root.cpuSource.stats.cpu
        var rawRam = root.cpuSource.stats.ram
        if (!Array.isArray(cpuSamples) || cpuSamples.length === 0
                || rawRam === undefined || rawRam === null || String(rawRam).trim() === "")
            return -1

        var value = Number(rawRam)
        return isFinite(value) ? Math.max(0, Math.min(100, Math.round(value))) : -1
    }
    // Expose the used/total RAM capacity from the exact same CpuWidget
    // snapshot as the percentage. /proc/meminfo reports KiB; format as GiB
    // for people and announce the full relationship to screen readers.
    readonly property var ramCapacity: {
        if (!Settings.cpu || !root.cpuSource || !root.cpuSource.stats)
            return ({ compact: "", accessible: "" })
        var usedRaw = root.cpuSource.stats.ram_used_kib
        var totalRaw = root.cpuSource.stats.ram_total_kib
        if (usedRaw === undefined || usedRaw === null
                || totalRaw === undefined || totalRaw === null
                || String(usedRaw).trim() === "" || String(totalRaw).trim() === "")
            return ({ compact: "", accessible: "" })
        var used = Number(usedRaw)
        var total = Number(totalRaw)
        if (!isFinite(used) || !isFinite(total) || used < 0 || total <= 0 || used > total)
            return ({ compact: "", accessible: "" })
        var usedGiB = used / 1048576
        var totalGiB = total / 1048576
        var usedText = usedGiB.toFixed(1)
        var totalText = totalGiB.toFixed(1)
        return ({
            compact: usedText + " / " + totalText + " GiB",
            accessible: "Использовано " + usedText + " из " + totalText + " гибибайт"
        })
    }

    // Swap is optional on Linux systems. Reuse the same CpuWidget snapshot
    // and show it only when the sampler received a complete, valid pair.
    readonly property var swapCapacity: {
        if (!Settings.cpu || !root.cpuSource || !root.cpuSource.stats)
            return ({ compact: "", accessible: "" })
        var usedRaw = root.cpuSource.stats.swap_used_kib
        var totalRaw = root.cpuSource.stats.swap_total_kib
        if (usedRaw === undefined || usedRaw === null
                || totalRaw === undefined || totalRaw === null
                || String(usedRaw).trim() === "" || String(totalRaw).trim() === "")
            return ({ compact: "", accessible: "" })
        var used = Number(usedRaw)
        var total = Number(totalRaw)
        if (!isFinite(used) || !isFinite(total) || used < 0 || total <= 0 || used > total)
            return ({ compact: "", accessible: "" })
        var usedGiB = used / 1048576
        var totalGiB = total / 1048576
        var usedText = usedGiB.toFixed(1)
        var totalText = totalGiB.toFixed(1)
        var percent = Math.max(0, Math.min(100, Math.round(used * 100 / total)))
        return ({
            compact: usedText + " / " + totalText + " GiB · " + percent + "%",
            accessible: "Использовано в файле подкачки " + usedText + " из "
                        + totalText + " гибибайт, " + percent + " процентов"
        })
    }

    // The expanded System card adds a logical-CPU perspective using the same
    // CpuWidget snapshot. This reveals one saturated logical processor that
    // can be hidden by the average, without another sampler or process.
    readonly property var cpuCoreStats: {
        if (!Settings.cpu || !root.cpuSource || !root.cpuSource.stats
                || !Array.isArray(root.cpuSource.stats.cpu))
            return ({ count: 0, peak: -1, peakId: "" })

        var values = root.cpuSource.stats.cpu
        var cpuIds = root.cpuSource.stats.cpu_ids
        var count = 0
        var peak = -1
        var peakId = ""
        for (var i = 0; i < values.length; ++i) {
            var rawValue = values[i]
            if (rawValue === null || rawValue === undefined || String(rawValue).trim() === "")
                continue
            var value = Number(rawValue)
            if (!isFinite(value) || value < 0 || value > 100)
                continue
            count++
            if (value > peak) {
                peak = Math.round(value)
                // cpu_ids is optional for compatibility with an older or
                // externally supplied snapshot. Never infer an id from array
                // position because offline logical CPUs can leave gaps.
                var candidateId = Array.isArray(cpuIds) && i < cpuIds.length
                    ? String(cpuIds[i] || "") : ""
                peakId = /^cpu[0-9]+$/.test(candidateId)
                    ? "CPU " + Number(candidateId.slice(3)) : ""
            }
        }
        return { count: count, peak: peak, peakId: peakId }
    }
    // Linux load average is complementary to CPU percentage: it describes the
    // average number of runnable and uninterruptible tasks over 1/5/15 minutes.
    // The sampler reads /proc/loadavg during the existing CPU/RAM poll.
    readonly property var cpuLoadAverage: {
        if (!Settings.cpu || !root.cpuSource || !root.cpuSource.stats
                || !Array.isArray(root.cpuSource.stats.load_avg)
                || root.cpuSource.stats.load_avg.length < 3)
            return ({ text: "", accessible: "" })
        var values = []
        for (var i = 0; i < 3; ++i) {
            var rawValue = root.cpuSource.stats.load_avg[i]
            if (rawValue === null || rawValue === undefined || String(rawValue).trim() === "")
                return ({ text: "", accessible: "" })
            var value = Number(rawValue)
            if (!isFinite(value) || value < 0)
                return ({ text: "", accessible: "" })
            values.push(value.toFixed(2))
        }
        return ({
            text: "Нагрузка · 1/5/15 мин: " + values.join(" / "),
            accessible: "Средняя системная нагрузка: за 1 минуту — " + values[0]
                        + "; за 5 минут — " + values[1]
                        + "; за 15 минут — " + values[2]
        })
    }
    // Reuse the existing System Monitor Top Apps rankings in the expanded
    // System card. Prefer the leading CPU application; if no positive CPU
    // leader is available, fall back to the leading RAM application when its
    // sampler is enabled. Never start another process snapshot or invent zeroes.
    readonly property var dashboardTopResourceApp: {
        if (!Settings.cpu || !root.monitorSource || !root.monitorSource.data)
            return ({ text: "", label: "", name: "", processCount: "", value: "", accessible: "" })
        var topApps = root.monitorSource.data.top_apps
        var systemRemainderLabel = String(Config.topAppsSystemRemainderLabel || "Система/прочее").trim()
        if (Settings.topAppsCpu) {
            var cpuRows = topApps && Array.isArray(topApps.cpu) ? topApps.cpu : []
            for (var i = 0; i < cpuRows.length; ++i) {
                var cpuItem = cpuRows[i]
                if (!cpuItem || typeof cpuItem !== "object")
                    continue
                var cpuName = String(cpuItem.name || "").replace(/\s+/g, " ").trim()
                var cpuValue = String(cpuItem.value || "").trim()
                var cpuRatio = Number(cpuItem.ratio)
                var displayedPercent = Number(cpuValue.replace(/%$/, ""))
                var cpuProcessCount = Number(cpuItem.processCount)
                var hasCpuProcessGroup = isFinite(cpuProcessCount) && cpuProcessCount > 1
                        && Math.floor(cpuProcessCount) === cpuProcessCount
                var cpuGroupDescription = hasCpuProcessGroup
                    ? ", количество процессов в группе — " + cpuProcessCount : ""
                var cpuDisplayProcessCount = hasCpuProcessGroup ? "×" + cpuProcessCount : ""
                if (cpuName === "" || cpuName === systemRemainderLabel
                        || !/^[0-9]+([.][0-9]+)?%$/.test(cpuValue)
                        || !isFinite(cpuRatio) || cpuRatio <= 0
                        || !isFinite(displayedPercent) || displayedPercent <= 0)
                    continue
                return ({
                    text: "Топ CPU · " + cpuName + " · " + cpuValue,
                    label: "Топ CPU",
                    name: cpuName,
                    processCount: cpuDisplayProcessCount,
                    value: cpuValue,
                    accessible: "Приложение с наибольшей долей загрузки CPU: " + cpuName
                                + ", " + cpuValue.replace(/%$/, "")
                                + " процента от общей мощности процессора" + cpuGroupDescription
                })
            }
        }
        if (Settings.topAppsRam) {
            var memoryRows = topApps && Array.isArray(topApps.mem) ? topApps.mem : []
            for (var j = 0; j < memoryRows.length; ++j) {
                var memoryItem = memoryRows[j]
                if (!memoryItem || typeof memoryItem !== "object")
                    continue
                var memoryName = String(memoryItem.name || "").replace(/\s+/g, " ").trim()
                var memoryValue = String(memoryItem.value || "").trim()
                var memoryRatio = Number(memoryItem.ratio)
                var memoryValueMatch = /^([0-9]+([.][0-9]+)?) (Kb|Mb|Gb)$/.exec(memoryValue)
                var memoryProcessCount = Number(memoryItem.processCount)
                var hasMemoryProcessGroup = isFinite(memoryProcessCount) && memoryProcessCount > 1
                        && Math.floor(memoryProcessCount) === memoryProcessCount
                var memoryGroupDescription = hasMemoryProcessGroup
                    ? ", количество процессов в группе — " + memoryProcessCount : ""
                var memoryDisplayProcessCount = hasMemoryProcessGroup ? "×" + memoryProcessCount : ""
                if (memoryName === "" || memoryName === systemRemainderLabel
                        || !memoryValueMatch || Number(memoryValueMatch[1]) <= 0
                        || !isFinite(memoryRatio) || memoryRatio <= 0)
                    continue
                var memoryUnitAccessible = memoryValueMatch[3] === "Gb" ? "гигабайта"
                        : memoryValueMatch[3] === "Mb" ? "мегабайта" : "килобайта"
                var memorySharePercent = (memoryRatio * 100).toFixed(1)
                return ({
                    text: "Топ RAM · " + memoryName + " · " + memoryValue,
                    label: "Топ RAM",
                    name: memoryName,
                    processCount: memoryDisplayProcessCount,
                    value: memoryValue + " · " + memorySharePercent + "%",
                    accessible: "Приложение с наибольшим использованием оперативной памяти: "
                                + memoryName + ", " + memoryValueMatch[1] + " "
                                + memoryUnitAccessible + " оперативной памяти, "
                                + memorySharePercent
                                + " процента от общего объёма физической памяти"
                                + memoryGroupDescription
                })
            }
        }
        return ({ text: "", label: "", name: "", processCount: "", value: "", accessible: "" })
    }
    // System uptime is part of the same CPU/RAM sampler snapshot. Keep the
    // footer compact while exposing full, correctly inflected wording to
    // screen readers. Invalid data retains the generic CPU footer.
    readonly property var systemUptime: {
        if (!Settings.cpu || !root.cpuSource || !root.cpuSource.stats)
            return ({ text: "", accessible: "" })
        var rawSeconds = root.cpuSource.stats.uptime_seconds
        if (rawSeconds === undefined || rawSeconds === null || String(rawSeconds).trim() === "")
            return ({ text: "", accessible: "" })
        var seconds = Number(rawSeconds)
        if (!isFinite(seconds) || seconds < 0 || Math.floor(seconds) !== seconds)
            return ({ text: "", accessible: "" })

        var totalMinutes = Math.floor(seconds / 60)
        var days = Math.floor(totalMinutes / 1440)
        var hours = Math.floor((totalMinutes % 1440) / 60)
        var minutes = totalMinutes % 60
        var compact = []
        var spoken = []
        if (days > 0) {
            compact.push(days + " д")
            spoken.push(root.russianCountUnit(days, "день", "дня", "дней"))
        }
        if (hours > 0) {
            compact.push(hours + " ч")
            spoken.push(root.russianCountUnit(hours, "час", "часа", "часов"))
        }
        if (days === 0 && minutes > 0) {
            compact.push(minutes + " мин")
            spoken.push(root.russianCountUnit(minutes, "минута", "минуты", "минут"))
        } else if (days === 0 && hours === 0 && minutes === 0) {
            compact.push("<1 мин")
            spoken.push("менее минуты")
        } else if (days > 0 && minutes > 0) {
            // Keep the visible footer short when days are present, but retain
            // the remaining minutes in the full screen-reader description.
            spoken.push(root.russianCountUnit(minutes, "минута", "минуты", "минут"))
        }
        return ({
            text: "Время работы · " + compact.join(" "),
            accessible: "Время работы системы: " + spoken.join(" ")
        })
    }
    readonly property var networkData: root.monitorSource && root.monitorSource.data
                                       ? (root.monitorSource.data.net_stat || ({})) : ({})
    // System Monitor already receives NetworkManager's connection list for
    // the Networks module. Reuse its connected profiles in the expanded card;
    // never create another nmcli process or infer a connection from counters.
    readonly property var networkConnectionNames: {
        var connections = root.monitorSource && root.monitorSource.data
                && Array.isArray(root.monitorSource.data.network)
            ? root.monitorSource.data.network : []
        var names = []
        for (var i = 0; i < connections.length; ++i) {
            var connection = connections[i]
            if (!connection || String(connection.status || "").trim() !== "on")
                continue
            var name = String(connection.name || "").trim()
            if (name === "")
                continue
            var device = String(connection.device || "").trim()
            // The shared NetworkManager payload already carries the same type
            // glyph used by the Networks module. Reuse it for quick visual
            // recognition without starting another lookup or process.
            var icon = String(connection.type || "").trim()
            // Keep the semantic NetworkManager type separately from the glyph:
            // the accessible description needs a readable type, not a font icon.
            var kind = String(connection.kind || "").trim()
            var duplicate = false
            for (var j = 0; j < names.length; ++j) {
                // One profile name may be active on more than one device.
                // Keep those rows distinct, suppressing only exact duplicates.
                if (names[j].name === name && names[j].device === device) {
                    duplicate = true
                    break
                }
            }
            if (duplicate)
                continue
            names.push({
                name: name,
                device: device,
                icon: icon,
                kind: kind
            })
        }
        return names
    }
    readonly property string networkConnectionText: {
        var names = root.networkConnectionNames
        if (!Array.isArray(names) || names.length === 0)
            return ""
        var visibleNames = []
        for (var i = 0; i < Math.min(2, names.length); ++i) {
            var item = names[i]
            var label = item.device !== ""
                ? item.name + " (" + item.device + ")" : item.name
            visibleNames.push(item.icon !== "" ? item.icon + " " + label : label)
        }
        // Keep the total active-connection count before the potentially
        // elided names, so narrow cards still reveal that more links exist.
        var heading = names.length === 1
            ? "Подключено"
            : "Подключения (" + names.length + ")"
        return heading + " · " + visibleNames.join(" · ")
    }
    readonly property string networkConnectionAccessibleText: {
        var names = root.networkConnectionNames
        if (!Array.isArray(names) || names.length === 0)
            return ""
        var descriptions = []
        for (var i = 0; i < names.length; ++i) {
            var item = names[i]
            var details = [item.name]
            var typeLabel = root.networkConnectionTypeLabel(item.kind)
            if (typeLabel !== "")
                details.push("тип " + typeLabel)
            if (item.device !== "")
                details.push("устройство " + item.device)
            descriptions.push(details.join(", "))
        }
        var heading = names.length === 1
            ? "Активное сетевое подключение"
            : "Активные сетевые подключения (" + names.length + ")"
        // A semicolon separates complete connections from the comma-separated
        // attributes within each one, making the spoken list unambiguous.
        return heading + ": " + descriptions.join("; ")
    }
    // The first network counter snapshot establishes a baseline only. Totals
    // are usable after that sample, but rates remain unavailable until a valid
    // second sample can be compared against the baseline.
    readonly property bool networkSampleReady: Settings.networkStat
                                               && root.networkData.sample_ready === true
                                               && root.networkFieldAvailable("down")
                                               && root.networkFieldAvailable("up")
    readonly property bool networkSpeedReady: root.networkSampleReady
                                              && root.networkData.speed_ready === true
                                              && root.networkFieldAvailable("speed_down")
                                              && root.networkFieldAvailable("speed_up")
    readonly property string weatherTemperature: {
        var value = root.weatherData && root.weatherData.temperature
                    ? root.weatherData.temperature.air : null
        var celsius = value && value.C !== undefined ? String(value.C) : ""
        return celsius !== "" ? celsius + "°C" : "—"
    }
    readonly property string weatherDescription: {
        var description = root.weatherData && root.weatherData.description
                          ? String(root.weatherData.description.full || "") : ""
        if (description !== "") return description
        return root.weatherSource ? String(root.weatherSource.nowStatusMessage || "Погода недоступна") : "Погода отключена"
    }
    // Player backends use different line layouts. Normalize their payloads
    // here so the Dashboard always presents title first, artist second, and
    // album/extra metadata last without changing the shared Player protocol.
    readonly property string mediaBackendId: String(root.playerData.player || "").trim().toLowerCase()
    readonly property string mediaTitle: {
        if (root.mediaBackendId === "deadbeef") {
            var deadbeefTitle = String(root.playerData.third_line || "").trim()
            return deadbeefTitle !== "" ? deadbeefTitle : "Название недоступно"
        }

        var title = String(root.playerData.first_line || "").trim()
        if (title !== "") return title
        // A backend id means the Player has a current source payload. Do not
        // describe that state as idle merely because a backend omitted its title.
        return root.mediaBackendId !== "" ? "Название недоступно" : "Ничего не воспроизводится"
    }
    readonly property string mediaSubtitle: {
        if (root.mediaBackendId === "deadbeef")
            return String(root.playerData.text || root.playerData.first_line || "").trim()
        if (root.mediaBackendId === "mopidy") {
            // Mopidy's Player payload uses the literal "music" as a fallback
            // when no artist tag exists. It is not an artist name for Dashboard.
            var mopidyArtist = String(root.playerData.text || "").trim()
            return mopidyArtist === "music" ? "" : mopidyArtist
        }
        return String(root.playerData.second_line || "").trim()
    }
    readonly property string mediaDetail: {
        if (root.mediaBackendId === "deadbeef" || root.mediaBackendId === "mopidy")
            return String(root.playerData.second_line || "")
        return String(root.playerData.third_line || "")
    }
    readonly property string mediaDetailLabel: {
        if (root.mediaBackendId === "deadbeef" || root.mediaBackendId === "mopidy")
            return "Альбом"
        return "Дополнительные данные"
    }
    // Player backends expose playback state through the existing status icon.
    // MPV currently does not provide that field, so keep its state explicitly unknown.
    readonly property string mediaPlaybackState: {
        var status = String(root.playerData.status || "")
        if (status === "\uF04C") return "playing"
        if (status === "\uF04B") return "paused"
        return "unknown"
    }
    // The shared Player payload stores a clamped 0..100 progress percentage
    // only when the backend supplied both a valid position and a positive
    // duration. Keep the Dashboard fail-closed for live streams and incomplete
    // metadata instead of drawing a misleading empty progress bar.
    readonly property int mediaProgressPercent: {
        var rawPosition = String(root.playerData.position === undefined || root.playerData.position === null
                                 ? "" : root.playerData.position).trim()
        var rawDuration = String(root.playerData.duration === undefined || root.playerData.duration === null
                                 ? "" : root.playerData.duration).trim()
        if (!/^\d{1,3}$/.test(rawPosition) || !/^\d+$/.test(rawDuration))
            return -1
        var position = Number(rawPosition)
        var duration = Number(rawDuration)
        if (!isFinite(position) || position < 0 || position > 100
                || !isFinite(duration) || duration <= 0)
            return -1
        return position
    }
    // Backends encode the remaining time as a negative clock string. Normalize
    // only known clock formats for the small visual label; unknown values are
    // omitted rather than announced as if they were a valid countdown.
    readonly property string mediaRemainingTime: {
        var remaining = String(root.playerData.timeleft || "").trim().replace(/^-/, "")
        return /^\d{1,3}:\d{2}(?::\d{2})?$/.test(remaining) ? remaining : ""
    }
    readonly property string weatherIconSource: root.weatherData && root.weatherData.icon
                                                  ? Quickshell.shellDir + "/assets/gismeteo/new_png/" + String(root.weatherData.icon) + ".png" : ""
    readonly property string weatherComfortTemperature: {
        var temperature = root.weatherData && root.weatherData.temperature
                          ? root.weatherData.temperature : null
        var comfort = temperature && temperature.comfort ? temperature.comfort.C : null
        return comfort !== null && comfort !== undefined && String(comfort) !== String(temperature.air && temperature.air.C)
                ? String(comfort) + "°C" : ""
    }
    readonly property int weatherWindScale: {
        var wind = root.weatherData && root.weatherData.wind ? root.weatherData.wind : null
        var direction = wind && wind.direction ? wind.direction.scale_8 : null
        if (direction === null || direction === undefined || String(direction).trim() === "")
            return -1
        var scale = Number(direction)
        return isFinite(scale) && Math.round(scale) === scale && scale >= 0 && scale <= 8
                ? scale : -1
    }
    readonly property string weatherWindDirection: {
        switch (root.weatherWindScale) {
        case 0: return "Штиль"
        case 1: return "С"
        case 2: return "СВ"
        case 3: return "В"
        case 4: return "ЮВ"
        case 5: return "Ю"
        case 6: return "ЮЗ"
        case 7: return "З"
        case 8: return "СЗ"
        default: return ""
        }
    }
    readonly property string weatherWindDirectionName: {
        switch (root.weatherWindScale) {
        case 0: return "штиль"
        case 1: return "северный"
        case 2: return "северо-восточный"
        case 3: return "восточный"
        case 4: return "юго-восточный"
        case 5: return "южный"
        case 6: return "юго-западный"
        case 7: return "западный"
        case 8: return "северо-западный"
        default: return ""
        }
    }
    readonly property string weatherWindSpeed: {
        var wind = root.weatherData && root.weatherData.wind ? root.weatherData.wind : null
        var speed = wind && wind.speed ? wind.speed.m_s : null
        return speed !== null && speed !== undefined && String(speed) !== "" ? String(speed) + " м/с" : ""
    }
    // WeatherNow already consumes Gismeteo's mm_hg_atm field. Reuse the same
    // current sample for the expanded Dashboard card; do not start another poll.
    readonly property string weatherPressure: {
        var pressure = root.weatherData && root.weatherData.pressure
                       ? root.weatherData.pressure.mm_hg_atm : null
        var textValue = pressure === null || pressure === undefined
                        ? "" : String(pressure).trim()
        if (textValue === "") return ""
        var numericValue = Number(textValue.replace(",", "."))
        return isFinite(numericValue) && numericValue > 0 ? textValue : ""
    }

    function isCardEnabled(cardId) {
        return DashboardCards.contains(Config.dashboardVisibleCards, cardId)
    }

    function visibleCardCount() {
        return DashboardCards.normalize(Config.dashboardVisibleCards).length
    }

    function navigationTargetUsable(target) {
        return !!(target && target.enabled !== false && target.visible !== false
                  && target.width > 0 && target.height > 0)
    }

    function updateNavigationAnchor(target) {
        if (!target || !drawer || target.width <= 0 || target.height <= 0)
            return
        var point = target.mapToItem(drawer, target.width / 2, target.height / 2)
        navigationAnchor = Qt.point(point.x, point.y)
        hasNavigationAnchor = true
    }

    function setNavigationTargetFocused(target) {
        if (!target)
            return
        currentNavigationTarget = target
        lastNavigationTarget = target
        navigationStarted = true
        navigationCardId = target.navigationCard ? String(target.cardId || "") : ""
        updateNavigationAnchor(target)
    }

    function dashboardHasOrderedCard(cardId) {
        var wanted = String(cardId || "")
        if (wanted === "" || !cards || !Array.isArray(cards.orderedCards))
            return false
        for (var i = 0; i < cards.orderedCards.length; ++i) {
            if (String(cards.orderedCards[i].id || "") === wanted)
                return true
        }
        return false
    }

    function scheduleCardsScrollClamp() {
        if (cardsScrollClampScheduled)
            return
        cardsScrollClampScheduled = true
        Qt.callLater(function() {
            root.cardsScrollClampScheduled = false
            var boundedY = DashboardCards.clampScrollPosition(
                cardsFlickable.contentY, cardsFlickable.contentHeight, cardsFlickable.height
            )
            if (!isFinite(cardsFlickable.contentY)
                    || Math.abs(boundedY - cardsFlickable.contentY) > 0.5)
                cardsFlickable.contentY = boundedY
        })
    }

    function restoreNavigationCardFocus() {
        if (!root.open || !navigationStarted || navigationCardId === "")
            return

        var wanted = navigationCardId
        if (!dashboardHasOrderedCard(wanted)) {
            // The focused module was actually removed from the visible set.
            // Drop its identity and recover from the last drawer-relative point.
            navigationCardId = ""
            var replacement = nearestNavigationTarget(
                hasNavigationAnchor ? navigationAnchor : null, null
            )
            if (replacement)
                focusNavigationTarget(replacement)
            else if (drawer)
                drawer.forceActiveFocus()
            return
        }

        // Repeater delegates may be rebuilt asynchronously during a layout
        // transition. Keep the requested id pending until its new target has
        // registered instead of briefly moving focus to a neighbouring card.
        for (var i = 0; i < navigationTargets.length; ++i) {
            var target = navigationTargets[i]
            if (target && target.navigationCard
                    && String(target.cardId || "") === wanted
                    && navigationTargetUsable(target)) {
                focusNavigationTarget(target)
                return
            }
        }
    }

    function scheduleDashboardLayoutSync() {
        scheduleCardsScrollClamp()
        if (!navigationStarted || navigationCardId === "" || navigationLayoutRestoreScheduled)
            return
        navigationLayoutRestoreScheduled = true
        Qt.callLater(function() {
            root.navigationLayoutRestoreScheduled = false
            root.restoreNavigationCardFocus()
        })
    }

    function releaseNavigationTargetFocus(target) {
        if (!target)
            return
        updateNavigationAnchor(target)
        if (currentNavigationTarget === target)
            currentNavigationTarget = null
        // Keep lastNavigationTarget as a stable recovery reference when focus
        // temporarily leaves a card for a non-interactive part of the drawer.
    }

    function navigationRect(target) {
        if (!target || !drawer)
            return ({ left: 0, top: 0, right: 0, bottom: 0, centerX: 0, centerY: 0 })
        var topLeft = target.mapToItem(drawer, 0, 0)
        var left = topLeft.x
        var top = topLeft.y
        return ({
            left: left,
            top: top,
            right: left + target.width,
            bottom: top + target.height,
            centerX: left + target.width / 2,
            centerY: top + target.height / 2
        })
    }

    function navigationEntryCompare(a, b, key) {
        var ar = navigationRect(a)
        var br = navigationRect(b)
        var primaryDifference = 0
        var secondaryDifference = 0

        // Enter the target graph from the edge opposite the first arrow press.
        // Compare actual bounds rather than centres so a wide card and a small
        // close control are treated according to their visible edges.
        if (key === Qt.Key_Left) {
            primaryDifference = br.right - ar.right
            secondaryDifference = ar.centerY - br.centerY
        } else if (key === Qt.Key_Right) {
            primaryDifference = ar.left - br.left
            secondaryDifference = ar.centerY - br.centerY
        } else if (key === Qt.Key_Up) {
            primaryDifference = br.bottom - ar.bottom
            secondaryDifference = ar.centerX - br.centerX
        } else if (key === Qt.Key_Down) {
            primaryDifference = ar.top - br.top
            secondaryDifference = ar.centerX - br.centerX
        }

        if (Math.abs(primaryDifference) > 0.5)
            return primaryDifference
        return secondaryDifference
    }

    function directionalNavigationScore(currentRect, candidateRect, key) {
        var primaryGap = 0
        var secondaryGap = 0
        var secondaryCenterOffset = 0

        // A candidate must be fully in the requested direction. The score
        // measures the edge-to-edge gap on that axis, then penalizes separation
        // on the perpendicular axis. This favours targets on the same visual
        // row/column, even when their sizes differ.
        if (key === Qt.Key_Left) {
            if (candidateRect.right > currentRect.left + 1)
                return Number.POSITIVE_INFINITY
            primaryGap = currentRect.left - candidateRect.right
            secondaryGap = Math.max(0, Math.max(
                candidateRect.top - currentRect.bottom,
                currentRect.top - candidateRect.bottom
            ))
            secondaryCenterOffset = Math.abs(candidateRect.centerY - currentRect.centerY)
        } else if (key === Qt.Key_Right) {
            if (candidateRect.left < currentRect.right - 1)
                return Number.POSITIVE_INFINITY
            primaryGap = candidateRect.left - currentRect.right
            secondaryGap = Math.max(0, Math.max(
                candidateRect.top - currentRect.bottom,
                currentRect.top - candidateRect.bottom
            ))
            secondaryCenterOffset = Math.abs(candidateRect.centerY - currentRect.centerY)
        } else if (key === Qt.Key_Up) {
            if (candidateRect.bottom > currentRect.top + 1)
                return Number.POSITIVE_INFINITY
            primaryGap = currentRect.top - candidateRect.bottom
            secondaryGap = Math.max(0, Math.max(
                candidateRect.left - currentRect.right,
                currentRect.left - candidateRect.right
            ))
            secondaryCenterOffset = Math.abs(candidateRect.centerX - currentRect.centerX)
        } else if (key === Qt.Key_Down) {
            if (candidateRect.top < currentRect.bottom - 1)
                return Number.POSITIVE_INFINITY
            primaryGap = candidateRect.top - currentRect.bottom
            secondaryGap = Math.max(0, Math.max(
                candidateRect.left - currentRect.right,
                currentRect.left - candidateRect.right
            ))
            secondaryCenterOffset = Math.abs(candidateRect.centerX - currentRect.centerX)
        } else {
            return Number.POSITIVE_INFINITY
        }

        return primaryGap + secondaryGap * 2.25 + secondaryCenterOffset * 0.08
    }

    function wrappedNavigationTarget(current, candidates, key, preferredTargets) {
        if (!current || (key !== Qt.Key_Left && key !== Qt.Key_Right
                && key !== Qt.Key_Up && key !== Qt.Key_Down))
            return null

        var pool = Array.isArray(preferredTargets) && preferredTargets.length > 0
                   ? preferredTargets : candidates
        var currentRect = navigationRect(current)
        var aligned = []

        // Wrap within the same visual row/column whenever possible. This keeps
        // edge navigation local instead of jumping to an unrelated dashboard
        // section merely because it happens to be the global opposite edge.
        for (var i = 0; i < pool.length; ++i) {
            var candidate = pool[i]
            if (candidate === current || !navigationTargetUsable(candidate))
                continue

            var rect = navigationRect(candidate)
            var perpendicularOverlap = 0
            if (key === Qt.Key_Left || key === Qt.Key_Right) {
                perpendicularOverlap = Math.max(0,
                    Math.min(currentRect.bottom, rect.bottom)
                    - Math.max(currentRect.top, rect.top))
            } else {
                perpendicularOverlap = Math.max(0,
                    Math.min(currentRect.right, rect.right)
                    - Math.max(currentRect.left, rect.left))
            }

            if (perpendicularOverlap > 0.5)
                aligned.push(candidate)
        }

        if (aligned.length === 0 && pool !== candidates) {
            // A responsive layout may temporarily leave no card aligned with
            // this one. Fall back to the complete actionable set only then.
            pool = candidates
            for (var j = 0; j < pool.length; ++j) {
                var fallback = pool[j]
                if (fallback === current || !navigationTargetUsable(fallback))
                    continue
                aligned.push(fallback)
            }
        }

        aligned.sort(function(a, b) {
            return root.navigationEntryCompare(a, b, key)
        })
        return aligned.length > 0 ? aligned[0] : null
    }

    function nearestNavigationTarget(referencePoint, excludedTarget) {
        var candidates = navigationTargets.filter(function(target) {
            return target !== excludedTarget && root.navigationTargetUsable(target)
        })
        if (candidates.length === 0)
            return null

        var reference = referencePoint || Qt.point(drawer.width / 2, drawer.height / 2)
        var best = null
        var bestDistance = Number.POSITIVE_INFINITY
        for (var i = 0; i < candidates.length; ++i) {
            var candidate = candidates[i]
            var rect = navigationRect(candidate)
            var dx = rect.centerX - reference.x
            var dy = rect.centerY - reference.y
            var distance = dx * dx + dy * dy
            if (distance < bestDistance) {
                bestDistance = distance
                best = candidate
            }
        }
        return best
    }

    function recoverNavigationFocus(excludedTarget) {
        if (!root.open || !navigationStarted)
            return
        var replacement = nearestNavigationTarget(
            hasNavigationAnchor ? navigationAnchor : null,
            excludedTarget || null
        )
        if (replacement)
            focusNavigationTarget(replacement)
        else if (drawer)
            drawer.forceActiveFocus()
    }

    function invalidateNavigationTarget(target) {
        if (!target || (lastNavigationTarget !== target && currentNavigationTarget !== target))
            return
        updateNavigationAnchor(target)
        if (currentNavigationTarget === target)
            currentNavigationTarget = null
        if (lastNavigationTarget === target)
            lastNavigationTarget = null
        navigationCardId = ""
        recoverNavigationFocus(target)
    }

    function registerNavigationTarget(target) {
        if (!target || navigationTargets.indexOf(target) >= 0)
            return
        var updated = navigationTargets.slice()
        updated.push(target)
        navigationTargets = updated
        if (target.navigationCard && String(target.cardId || "") === navigationCardId)
            scheduleDashboardLayoutSync()
    }

    function unregisterNavigationTarget(target) {
        if (!target)
            return
        var wasLastTarget = lastNavigationTarget === target || currentNavigationTarget === target
        var cardId = target.navigationCard ? String(target.cardId || "") : ""
        if (wasLastTarget)
            updateNavigationAnchor(target)

        var updated = navigationTargets.slice()
        var index = updated.indexOf(target)
        if (index >= 0) {
            updated.splice(index, 1)
            navigationTargets = updated
        }
        if (currentNavigationTarget === target)
            currentNavigationTarget = null
        if (lastNavigationTarget === target)
            lastNavigationTarget = null

        if (wasLastTarget) {
            if (cardId !== "" && dashboardHasOrderedCard(cardId)) {
                // This is a layout-driven delegate rebuild, not a user removal.
                // Keep the card id so the replacement delegate can reclaim focus.
                navigationCardId = cardId
                scheduleDashboardLayoutSync()
            } else {
                navigationCardId = ""
                recoverNavigationFocus(target)
            }
        }
    }

    function clearNavigationFocus() {
        var targets = navigationTargets.slice()
        for (var i = 0; i < targets.length; ++i) {
            var target = targets[i]
            if (target && target.focus)
                target.focus = false
        }
        currentNavigationTarget = null
        lastNavigationTarget = null
        navigationCardId = ""
        hasNavigationAnchor = false
        navigationStarted = false
        navigationAnchor = Qt.point(0, 0)
    }

    function focusNavigationTarget(target) {
        if (!navigationTargetUsable(target))
            return
        target.forceActiveFocus()
        setNavigationTargetFocused(target)

        // Cards live inside the Flickable content item. Keep the newly focused
        // card visible when arrow navigation moves beyond the current viewport.
        if (target.navigationCard && cardsFlickable) {
            var position = target.mapToItem(cardsFlickable.contentItem, 0, 0)
            var top = position.y
            var bottom = top + target.height
            var visibleTop = cardsFlickable.contentY
            var visibleBottom = visibleTop + cardsFlickable.height
            if (top < visibleTop)
                cardsFlickable.contentY = Math.max(0, top)
            else if (bottom > visibleBottom)
                cardsFlickable.contentY = Math.max(0, bottom - cardsFlickable.height)
        }
    }

    function moveKeyboardFocus(key) {
        var candidates = navigationTargets.filter(function(target) {
            return root.navigationTargetUsable(target)
        })
        if (candidates.length === 0)
            return

        var current = currentNavigationTarget
        if (!current || candidates.indexOf(current) < 0) {
            // If focus briefly left the controls, resume from the last focused
            // target. If it disappeared, use its saved position to find the
            // nearest surviving control. Only the very first arrow press uses
            // the directional edge-entry rule.
            if (lastNavigationTarget && candidates.indexOf(lastNavigationTarget) >= 0) {
                current = lastNavigationTarget
            } else if (navigationStarted && hasNavigationAnchor) {
                current = nearestNavigationTarget(navigationAnchor, null)
            }

            if (!current) {
                candidates.sort(function(a, b) {
                    return root.navigationEntryCompare(a, b, key)
                })
                focusNavigationTarget(candidates[0])
                return
            }
        }

        var currentRect = navigationRect(current)
        var best = null
        var bestScore = Number.POSITIVE_INFINITY
        var candidatePool = candidates

        // In a two-column Dashboard, vertical movement should stay in the
        // current card stack whenever that stack has a target in the requested
        // direction. Only at the end of a stack do we fall back to the nearest
        // target in another column or in the header. Horizontal movement keeps
        // using the full spatial graph to reach the neighbouring stack.
        if (current.navigationCard && (key === Qt.Key_Up || key === Qt.Key_Down)) {
            var currentLeft = currentRect.left
            var currentRight = currentRect.right
            var sameColumnCandidates = []
            var sameColumnCards = []

            for (var columnIndex = 0; columnIndex < candidates.length; ++columnIndex) {
                var columnCandidate = candidates[columnIndex]
                if (columnCandidate === current || !columnCandidate.navigationCard)
                    continue

                var candidateRect = navigationRect(columnCandidate)
                var candidateRight = candidateRect.right
                var horizontalOverlap = Math.max(0,
                    Math.min(currentRight, candidateRight)
                    - Math.max(currentLeft, candidateRect.left))
                var minimumWidth = Math.min(current.width, columnCandidate.width)
                var sharesColumn = minimumWidth > 0
                        && horizontalOverlap >= minimumWidth * 0.5
                var isInRequestedDirection = key === Qt.Key_Up
                    ? candidateRect.bottom <= currentRect.top + 1
                    : candidateRect.top >= currentRect.bottom - 1

                // Half-width overlap is enough to tolerate small responsive
                // offsets while keeping the two independent card stacks apart.
                if (sharesColumn) {
                    sameColumnCards.push(columnCandidate)
                    if (isInRequestedDirection)
                        sameColumnCandidates.push(columnCandidate)
                }
            }

            if (sameColumnCandidates.length > 0)
                candidatePool = sameColumnCandidates
        }

        for (var i = 0; i < candidatePool.length; ++i) {
            var candidate = candidatePool[i]
            if (candidate === current)
                continue
            var candidateRect = navigationRect(candidate)
            var score = directionalNavigationScore(currentRect, candidateRect, key)
            if (score < bestScore) {
                bestScore = score
                best = candidate
            }
        }

        if (best) {
            focusNavigationTarget(best)
        } else {
            // At the end of a row or stack, wrap to its opposite edge. For
            // vertical card navigation, prefer the current column so a full
            // up/down cycle remains within the same card stack.
            var wrapPool = current.navigationCard
                    && (key === Qt.Key_Up || key === Qt.Key_Down)
                    ? sameColumnCards : null
            var wrapped = wrappedNavigationTarget(current, candidates, key, wrapPool)
            focusNavigationTarget(wrapped || current)
        }
    }

    function moveKeyboardPage(key) {
        if (!cardsFlickable || cardsFlickable.height <= 0)
            return

        var viewportHeight = cardsFlickable.height
        var maximumContentY = Math.max(0, cardsFlickable.contentHeight - viewportHeight)
        if (maximumContentY <= 1)
            return

        // Page navigation advances almost one viewport while retaining a small
        // overlap. That keeps the transition continuous instead of skipping a
        // card that straddles the old and new viewport boundaries.
        var overlap = Math.min(48, Math.max(24, viewportHeight * 0.12))
        var pageStep = Math.max(48, viewportHeight - overlap)
        var movingDown = key === Qt.Key_PageDown
        var requestedY = cardsFlickable.contentY + (movingDown ? pageStep : -pageStep)
        var nextY = Math.max(0, Math.min(maximumContentY, requestedY))
        if (Math.abs(nextY - cardsFlickable.contentY) <= 1)
            return

        cardsFlickable.contentY = nextY

        // Keep focus on a real card after paging. PageDown lands near the top
        // of the newly revealed area; PageUp lands near its bottom. A small
        // horizontal penalty preserves the current column when possible.
        // Use the drawer coordinate space for both the current target and
        // candidate cards. This avoids mixing Flickable content coordinates
        // with viewport coordinates when the list has already been scrolled.
        var currentRect = currentNavigationTarget
                ? navigationRect(currentNavigationTarget) : null
        var preferredX = currentRect ? currentRect.centerX : drawer.width / 2
        var viewportTop = cardsFlickable.mapToItem(drawer, 0, 0).y
        var viewportBottom = viewportTop + viewportHeight
        var edgeInset = Math.min(overlap, viewportHeight * 0.25)
        var anchorY = movingDown
                ? viewportTop + edgeInset
                : viewportBottom - edgeInset
        var bestCard = null
        var bestScore = Number.POSITIVE_INFINITY

        for (var i = 0; i < navigationTargets.length; ++i) {
            var candidate = navigationTargets[i]
            if (!navigationTargetUsable(candidate) || !candidate.navigationCard)
                continue

            var candidateRect = navigationRect(candidate)
            if (candidateRect.bottom <= viewportTop || candidateRect.top >= viewportBottom)
                continue

            var score = Math.abs(candidateRect.centerY - anchorY)
                    + Math.abs(candidateRect.centerX - preferredX) * 0.12
            if (score < bestScore) {
                bestScore = score
                bestCard = candidate
            }
        }

        if (bestCard)
            focusNavigationTarget(bestCard)
    }

    function moveKeyboardToEdge(key) {
        if (!cardsFlickable || !cards || (key !== Qt.Key_Home && key !== Qt.Key_End))
            return

        // Home/End follow the configured visible-card order, not the visual
        // column split. The same card therefore remains first/last when the
        // layout changes between one and two independently balanced columns.
        var orderedCards = Array.isArray(cards.orderedCards) ? cards.orderedCards : []
        if (orderedCards.length === 0)
            return

        var cardTargets = navigationTargets.filter(function(target) {
            return root.navigationTargetUsable(target) && target.navigationCard
        })
        if (cardTargets.length === 0)
            return

        var movingToEnd = key === Qt.Key_End
        var index = movingToEnd ? orderedCards.length - 1 : 0
        var step = movingToEnd ? -1 : 1
        var target = null

        for (; index >= 0 && index < orderedCards.length; index += step) {
            var cardId = String(orderedCards[index] && orderedCards[index].id || "")
            for (var i = 0; i < cardTargets.length; ++i) {
                if (String(cardTargets[i].cardId || "") === cardId) {
                    target = cardTargets[i]
                    break
                }
            }
            if (target)
                break
        }

        if (!target)
            return

        var maximumContentY = Math.max(0, cardsFlickable.contentHeight - cardsFlickable.height)
        cardsFlickable.contentY = movingToEnd ? maximumContentY : 0
        root.focusNavigationTarget(target)
    }

    function russianCountUnit(value, one, few, many) {
        var count = Math.max(0, Math.floor(Number(value) || 0))
        var lastTwo = count % 100
        if (lastTwo >= 11 && lastTwo <= 14)
            return count + " " + many
        switch (count % 10) {
        case 1: return count + " " + one
        case 2:
        case 3:
        case 4: return count + " " + few
        default: return count + " " + many
        }
    }

    function networkConnectionTypeLabel(connectionType) {
        switch (String(connectionType || "").trim()) {
        case "wifi":
        case "802-11-wireless": return "Wi-Fi"
        case "802-3-ethernet": return "Ethernet"
        case "vpn": return "VPN"
        case "wireguard": return "WireGuard"
        case "bluetooth": return "Bluetooth"
        case "gsm":
        case "cdma": return "Мобильная сеть"
        case "pppoe": return "PPPoE"
        case "infiniband": return "InfiniBand"
        }
        return ""
    }

    function networkFieldAvailable(fieldName) {
        if (!root.networkData || typeof root.networkData !== "object")
            return false
        var value = root.networkData[String(fieldName || "")]
        return value !== undefined && value !== null && String(value).trim() !== ""
    }

    function networkDisplayValue(fieldName) {
        return root.networkFieldAvailable(fieldName)
            ? String(root.networkData[String(fieldName)]).trim()
            : "—"
    }

    function cardPrimaryText(cardId) {
        switch (String(cardId || "")) {
        case "system": return root.cpuUsage >= 0 ? "CPU  " + root.cpuUsage + "%" : "CPU  —"
        case "network": return "↓  " + (root.networkSpeedReady ? root.networkDisplayValue("speed_down") : "—")
        case "weather": return Settings.weatherNow ? root.weatherTemperature : "Отключена"
        case "media": return Settings.player ? root.mediaTitle : "Плеер отключён"
        }
        return ""
    }

    function cardSecondaryText(cardId) {
        switch (String(cardId || "")) {
        case "system": return root.ramUsage >= 0 ? "RAM  " + root.ramUsage + "%" : "RAM  —"
        case "network": return "↑  " + (root.networkSpeedReady ? root.networkDisplayValue("speed_up") : "—")
        case "weather": return Settings.weatherNow ? root.weatherDescription : "Модуль погоды выключен"
        case "media": return Settings.player ? root.mediaSubtitle : ""
        }
        return ""
    }

    function weatherCardFooterText() {
        if (!Settings.weatherNow) return "Модуль погоды выключен"
        if (!root.weatherSource) return "Источник погоды недоступен"

        // Weather keeps the last successful payload when a later refresh
        // fails. Describe the state in user-facing language instead of
        // exposing the internal enum (idle/loading/ready/error), and make
        // it clear when the visible values are the previous good sample.
        var weatherStatus = String(root.weatherSource.nowStatus || "idle")
        var hasWeatherData = root.weatherData
                               && typeof root.weatherData === "object"
                               && Object.keys(root.weatherData).length > 0

        if (weatherStatus === "loading")
            return hasWeatherData
                ? "Обновление · показаны последние данные"
                : "Загрузка погоды…"
        if (weatherStatus === "ready") return "Данные погоды получены"
        if (weatherStatus === "error") {
            if (hasWeatherData)
                return "Ошибка обновления · показаны последние данные"
            return String(root.weatherSource.nowStatusMessage || "Не удалось получить погоду")
        }
        if (hasWeatherData) return "Ожидание следующего обновления"
        return String(root.weatherSource.nowStatusMessage || "Ожидание данных погоды")
    }

    function mediaBackendLabel() {
        var backend = String(root.playerData.player || "").trim()
        switch (backend) {
        case "deadbeef": return "DeaDBeeF"
        case "mopidy": return "Mopidy"
        case "mpv": return "mpv"
        case "spotify": return "Spotify"
        case "plasma-browser-integration": return "Браузер"
        case "org.telegram.desktop": return "Telegram"
        default: return backend
        }
    }

    function mediaCardFooterText() {
        if (!Settings.player) return "Модуль Player выключен"
        var backend = root.mediaBackendLabel()
        if (backend === "") return "Нет активного воспроизведения"
        if (root.mediaPlaybackState === "playing") return "Воспроизводится · " + backend
        if (root.mediaPlaybackState === "paused") return "На паузе · " + backend
        // Some sources (currently MPV) expose track metadata without a
        // playback-state field. Do not infer Playing or Paused for them.
        return "Источник: " + backend
    }

    function cardFooterText(cardId) {
        switch (String(cardId || "")) {
        case "system":
            if (!Settings.cpu) return "Модуль CPU выключен"
            return root.systemUptime.text !== "" ? root.systemUptime.text : "Данные модуля CPU"
        case "network":
            if (!Settings.networkStat) return "Статистика сети выключена"
            if (!root.networkSampleReady) return "Ожидание первого снимка"
            if (!root.networkSpeedReady) return "Нужен ещё один снимок"
            return "Текущая скорость передачи"
        case "weather": return root.weatherCardFooterText()
        case "media": return root.mediaCardFooterText()
        case "today": return "Заметки календаря · текущий день"
        }
        return ""
    }

    function resolveDashboardScreen() {
        var wanted = String(Config.monitorName || "").trim().toLowerCase()
        for (var i = 0; i < Quickshell.screens.length; ++i) {
            var candidate = Quickshell.screens[i]
            if (!candidate) continue
            if (wanted && (String(candidate.name || "").trim().toLowerCase() === wanted
                    || String(candidate.model || "").trim().toLowerCase() === wanted
                    || String(candidate).trim().toLowerCase() === wanted))
                return candidate
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    screen: root.resolveDashboardScreen()
    visible: Settings.loaded && (root.open || root.keepWindowDuringClose)
    onOpenChanged: {
        if (root.open) {
            closeWindowTimer.stop()
            root.keepWindowDuringClose = true
        } else {
            root.clearNavigationFocus()
            if (root.keepWindowDuringClose)
                closeWindowTimer.restart()
        }
    }
    color: Config.transparent
    focusable: root.open
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors.left: true
    anchors.right: true
    anchors.top: true
    anchors.bottom: true
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region { item: root.open ? fullInputRegion : null }

    Timer {
        id: closeWindowTimer
        interval: Config.animationDuration(300, "appearance") + 24
        repeat: false
        onTriggered: root.keepWindowDuringClose = false
    }

    Item {
        id: fullInputRegion
        anchors.fill: parent
    }

    Rectangle {
        anchors.fill: parent
        color: "#55000000"
        opacity: root.open ? 1 : 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation { duration: Config.animationDuration(220, "appearance"); easing.type: Easing.OutCubic }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }

    Rectangle {
        id: drawer
        readonly property real targetWidth: DashboardCards.drawerWidthForScreenWidth(parent.width)
        readonly property real targetHeight: Math.min(
            Math.max(1, parent.height - 32),
            Math.min(600, Math.max(420, cards.implicitHeight + 280))
        )
        width: targetWidth
        height: targetHeight
        y: Math.max(16, (parent.height - height) / 2)
        x: root.open ? parent.width - width - 16 : parent.width + 16
        radius: Config.frameRadius + 9
        color: Config.settingsBackground
        border.color: Config.settingsBorder
        border.width: Math.max(1, Config.frameBorderWidth)
        clip: true
        // The drawer is the invisible keyboard entry point. It has focus but
        // no visual selection; the first arrow press chooses a real target.
        focus: root.open
        activeFocusOnTab: false
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Right
                    || event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                event.accepted = true
                root.moveKeyboardFocus(event.key)
            } else if (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) {
                event.accepted = true
                root.moveKeyboardPage(event.key)
            } else if (event.key === Qt.Key_Home || event.key === Qt.Key_End) {
                event.accepted = true
                root.moveKeyboardToEdge(event.key)
            }
        }
        Behavior on x {
            NumberAnimation { duration: Config.animationDuration(300, "appearance"); easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Обзор"
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: 23
                        font.bold: true
                    }
                }
                Rectangle {
                    id: closeButton
                    // A real 36 px target keeps the visible control, mouse hit area
                    // and spatial-navigation bounds aligned with one another.
                    // Include it in the same navigation graph as quick actions/cards.
                    readonly property bool navigationCard: false
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignVCenter
                    radius: 9
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: "Закрыть обзор"
                    Accessible.description: "Закрывает панель Dashboard"
                    Component.onCompleted: root.registerNavigationTarget(closeButton)
                    Component.onDestruction: root.unregisterNavigationTarget(closeButton)
                    onActiveFocusChanged: {
                        if (activeFocus)
                            root.setNavigationTargetFocused(closeButton)
                        else
                            root.releaseNavigationTargetFocus(closeButton)
                    }
                    color: closeMouse.pressed
                           ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.22)
                           : (activeFocus
                              ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.18)
                              : (closeMouse.containsMouse
                                 ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.10)
                                 : "transparent"))
                    border.width: activeFocus ? 2 : (closeMouse.containsMouse ? 1 : 0)
                    border.color: activeFocus
                                  ? Config.accent
                                  : Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.48)
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                            event.accepted = true
                            root.closeRequested()
                        }
                    }
                    Behavior on color {
                        ColorAnimation { duration: Config.animationDuration(DashboardCards.CARD_HOVER_DURATION, "appearance") }
                    }
                    Behavior on border.color {
                        ColorAnimation { duration: Config.animationDuration(DashboardCards.CARD_HOVER_DURATION, "appearance") }
                    }
                    Behavior on border.width {
                        NumberAnimation { duration: Config.animationDuration(DashboardCards.CARD_HOVER_DURATION, "appearance"); easing.type: Easing.OutCubic }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: closeButton.activeFocus || closeMouse.containsMouse ? Config.accent : Config.textMuted
                        font.pixelSize: 26
                        font.bold: closeButton.activeFocus
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            closeButton.forceActiveFocus()
                            root.closeRequested()
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                QuickAction {
                    id: launcherQuickAction
                    Layout.fillWidth: true
                    label: "Лаунчер"
                    symbol: "⌕"
                    onClicked: {
                        root.closeRequested()
                        root.launcherRequested()
                    }
                }
                QuickAction {
                    Layout.fillWidth: true
                    label: "Календарь"
                    symbol: "▦"
                    enabled: Settings.calendar
                    onClicked: {
                        root.closeRequested()
                        root.calendarRequested()
                    }
                }
                QuickAction {
                    Layout.fillWidth: true
                    label: "Настройки"
                    symbol: "⚙"
                    onClicked: {
                        root.closeRequested()
                        root.settingsRequested()
                    }
                }
            }

            Flickable {
                id: cardsFlickable
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: cards.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                onContentHeightChanged: root.scheduleDashboardLayoutSync()
                onHeightChanged: root.scheduleDashboardLayoutSync()
                // Match the explicit mouse/touchpad scrolling used by other
                // long-running lists in the shell. Pixel deltas keep touchpad
                // motion precise; wheel notches use the same bounded path.
                WheelHandler {
                    target: null
                    enabled: cardsFlickable.contentHeight > cardsFlickable.height + 1
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: function(event) {
                        const maximumContentY = Math.max(
                            0,
                            cardsFlickable.contentHeight - cardsFlickable.height
                        )
                        const pixelDelta = Number(event.pixelDelta.y) || 0
                        const angleDelta = Number(event.angleDelta.y) || 0
                        const delta = pixelDelta !== 0
                            ? pixelDelta
                            : angleDelta / 120 * 64
                        if (delta === 0)
                            return

                        cardsFlickable.contentY = Math.max(
                            0,
                            Math.min(maximumContentY, cardsFlickable.contentY - delta)
                        )
                        event.accepted = true
                    }
                }

                Item {
                    id: cards
                    width: parent.width
                    property var orderedCards: DashboardCards.orderedVisible(Config.dashboardCardOrder, Config.dashboardVisibleCards)
                    onOrderedCardsChanged: root.scheduleDashboardLayoutSync()
                    // Recompute the full assignment whenever width, visibility,
                    // order or column mode changes. Vertical and horizontal
                    // Repeaters receive mutually exclusive arrays, so a card
                    // can never remain as a hidden duplicate focus target.
                    readonly property var layoutState: DashboardCards.resolveDashboardLayout(
                        orderedCards, Config.dashboardColumnsMode, width,
                        Config.dashboardCardSizes, DashboardCards.COLUMN_GAP
                    )
                    onLayoutStateChanged: root.scheduleDashboardLayoutSync()
                    onImplicitHeightChanged: root.scheduleCardsScrollClamp()
                    onWidthChanged: root.scheduleDashboardLayoutSync()
                    property bool useTwoColumns: layoutState.columns === 2
                    property bool useWideLeadHorizontalLayout: layoutState.kind === "wide-lead-horizontal"
                    property var horizontalLeadCards: layoutState.lead
                    property var horizontalPeerCards: layoutState.peers
                    readonly property real horizontalBentoRowHeight: useWideLeadHorizontalLayout
                        ? DashboardCards.threeCardHorizontalRowHeight(orderedCards, Config.dashboardCardSizes)
                        : 0
                    readonly property var horizontalPeerColumns: useWideLeadHorizontalLayout
                        ? DashboardCards.wideLeadPeerColumns(horizontalPeerCards, Config.dashboardCardSizes, DashboardCards.COLUMN_GAP)
                        : ({ left: [], right: [] })
                    readonly property real horizontalPeerRowHeight: useWideLeadHorizontalLayout
                        ? Math.max(
                            DashboardCards.stackHeight(horizontalPeerColumns.left, Config.dashboardCardSizes, DashboardCards.COLUMN_GAP),
                            DashboardCards.stackHeight(horizontalPeerColumns.right, Config.dashboardCardSizes, DashboardCards.COLUMN_GAP)
                        )
                        : 0
                    property var columnSplit: ({ left: layoutState.left, right: layoutState.right })
                    readonly property string spanningCardId: layoutState.kind === "three-vertical" && columnSplit.left.length > 0
                        ? String(columnSplit.left[0].id || "") : ""
                    readonly property real spanningCardHeight: layoutState.kind === "three-vertical"
                        ? DashboardCards.stackHeight(columnSplit.right, Config.dashboardCardSizes, DashboardCards.COLUMN_GAP)
                        : 0
                    implicitHeight: orderedCards.length === 0
                        ? 128
                        : (useWideLeadHorizontalLayout
                           ? DashboardCards.wideLeadHorizontalHeight(orderedCards, Config.dashboardCardSizes, DashboardCards.COLUMN_GAP)
                           : Math.max(leftColumn.implicitHeight, useTwoColumns ? rightColumn.implicitHeight : 0))
                    height: implicitHeight

                    // In wide two-column layouts, the first configured card spans
                    // the top row. Remaining cards form two balanced vertical stacks
                    // below it, preserving the original three-card side-by-side pair.
                    // Narrow three-card layouts keep the vertical spanning form;
                    // other narrow/two-column layouts use balanced independent stacks.
                    // One-column mode remains a simple ordered vertical list.
                    ColumnLayout {
                        id: horizontalBentoLayout
                        anchors.fill: parent
                        spacing: DashboardCards.COLUMN_GAP
                        visible: cards.useWideLeadHorizontalLayout

                        Repeater {
                            model: cards.horizontalLeadCards
                            delegate: Item {
                                id: horizontalLeadSlot
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: cards.horizontalBentoRowHeight

                                    // The top track matches the lead card's actual
                                    // selected height. Taller peer cards affect only
                                    // the lower row and cannot add blank space here.
                                    InfoCard {
                                        anchors.centerIn: parent
                                        width: parent.width
                                        height: DashboardCards.cardHeight(horizontalLeadSlot.modelData.id, Config.dashboardCardSizes)
                                        cardId: horizontalLeadSlot.modelData.id
                                        wideLead: true
                                        expanded: DashboardCards.cardSizeMode(Config.dashboardCardSizes, horizontalLeadSlot.modelData.id) === "expanded"
                                        title: horizontalLeadSlot.modelData.label
                                        symbol: horizontalLeadSlot.modelData.symbol
                                        settingsPageId: horizontalLeadSlot.modelData.settingsPageId
                                        onSettingsRequested: pageId => root.moduleSettingsRequested(pageId)
                                        primaryText: root.cardPrimaryText(horizontalLeadSlot.modelData.id)
                                        secondaryText: root.cardSecondaryText(horizontalLeadSlot.modelData.id)
                                        footerText: root.cardFooterText(horizontalLeadSlot.modelData.id)
                                        primaryValue: horizontalLeadSlot.modelData.id === "system" ? root.cpuUsage : -1
                                        secondaryValue: horizontalLeadSlot.modelData.id === "system" ? root.ramUsage : -1
                                        cpuCoreCount: horizontalLeadSlot.modelData.id === "system" ? root.cpuCoreStats.count : 0
                                        cpuCorePeak: horizontalLeadSlot.modelData.id === "system" ? root.cpuCoreStats.peak : -1
                                        cpuCorePeakId: horizontalLeadSlot.modelData.id === "system" ? root.cpuCoreStats.peakId : ""
                                        ramCapacityText: horizontalLeadSlot.modelData.id === "system" ? root.ramCapacity.compact : ""
                                        ramCapacityAccessibleText: horizontalLeadSlot.modelData.id === "system" ? root.ramCapacity.accessible : ""
                                        swapCapacityText: horizontalLeadSlot.modelData.id === "system" ? root.swapCapacity.compact : ""
                                        swapCapacityAccessibleText: horizontalLeadSlot.modelData.id === "system" ? root.swapCapacity.accessible : ""
                                        cpuLoadAverageText: horizontalLeadSlot.modelData.id === "system" ? root.cpuLoadAverage.text : ""
                                        cpuLoadAverageAccessibleText: horizontalLeadSlot.modelData.id === "system" ? root.cpuLoadAverage.accessible : ""
                                        topResourceAppText: horizontalLeadSlot.modelData.id === "system" ? root.dashboardTopResourceApp.text : ""
                                        topResourceAppLabel: horizontalLeadSlot.modelData.id === "system" ? root.dashboardTopResourceApp.label : ""
                                        topResourceAppName: horizontalLeadSlot.modelData.id === "system" ? root.dashboardTopResourceApp.name : ""
                                        topResourceAppProcessCount: horizontalLeadSlot.modelData.id === "system" ? String(root.dashboardTopResourceApp.processCount || "") : ""
                                        topResourceAppValue: horizontalLeadSlot.modelData.id === "system" ? root.dashboardTopResourceApp.value : ""
                                        topResourceAppAccessibleText: horizontalLeadSlot.modelData.id === "system" ? root.dashboardTopResourceApp.accessible : ""
                                        systemUptimeAccessibleText: horizontalLeadSlot.modelData.id === "system" ? root.systemUptime.accessible : ""
                                        detailPrimaryText: horizontalLeadSlot.modelData.id === "network" && root.networkSampleReady ? root.networkDisplayValue("down") : "—"
                                        detailSecondaryText: horizontalLeadSlot.modelData.id === "network" && root.networkSampleReady ? root.networkDisplayValue("up") : "—"
                                        networkConnectionText: horizontalLeadSlot.modelData.id === "network" ? root.networkConnectionText : ""
                                        networkConnectionAccessibleText: horizontalLeadSlot.modelData.id === "network" ? root.networkConnectionAccessibleText : ""
                                        tertiaryText: horizontalLeadSlot.modelData.id === "media" && Settings.player ? root.mediaDetail : ""
                                        tertiaryLabel: horizontalLeadSlot.modelData.id === "media" && Settings.player && root.mediaDetail !== "" ? root.mediaDetailLabel : ""
                                        mediaProgressPercent: horizontalLeadSlot.modelData.id === "media" && Settings.player ? root.mediaProgressPercent : -1
                                        mediaRemainingTime: horizontalLeadSlot.modelData.id === "media" && Settings.player ? root.mediaRemainingTime : ""
                                        iconSource: horizontalLeadSlot.modelData.id === "weather" && Settings.weatherNow ? root.weatherIconSource : ""
                                        comfortText: horizontalLeadSlot.modelData.id === "weather" && Settings.weatherNow ? root.weatherComfortTemperature : ""
                                        windText: horizontalLeadSlot.modelData.id === "weather" && Settings.weatherNow ? root.weatherWindSpeed : ""
                                        windDirection: horizontalLeadSlot.modelData.id === "weather" && Settings.weatherNow ? root.weatherWindDirection : ""
                                        windDirectionName: horizontalLeadSlot.modelData.id === "weather" && Settings.weatherNow ? root.weatherWindDirectionName : ""
                                        pressureText: horizontalLeadSlot.modelData.id === "weather" && Settings.weatherNow ? root.weatherPressure : ""
                                    }
                                }
                            }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: cards.horizontalPeerRowHeight
                            spacing: DashboardCards.COLUMN_GAP

                            Repeater {
                                model: [cards.horizontalPeerColumns.left, cards.horizontalPeerColumns.right]
                                delegate: ColumnLayout {
                                    id: horizontalPeerColumnSlot
                                    required property var modelData
                                    Layout.fillWidth: true
                                    // Keep shorter compact stacks at the top of the
                                    // peer row instead of centring them beside a taller
                                    // stack and creating an artificial preceding gap.
                                    Layout.alignment: Qt.AlignTop
                                    spacing: DashboardCards.COLUMN_GAP

                                    Repeater {
                                        model: horizontalPeerColumnSlot.modelData
                                        delegate: InfoCard {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.fillHeight: false
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.preferredHeight: DashboardCards.cardHeight(modelData.id, Config.dashboardCardSizes)
                                            cardId: modelData.id
                                            expanded: DashboardCards.cardSizeMode(Config.dashboardCardSizes, modelData.id) === "expanded"
                                            title: modelData.label
                                            symbol: modelData.symbol
                                            settingsPageId: modelData.settingsPageId
                                            onSettingsRequested: pageId => root.moduleSettingsRequested(pageId)
                                            primaryText: root.cardPrimaryText(modelData.id)
                                            secondaryText: root.cardSecondaryText(modelData.id)
                                            footerText: root.cardFooterText(modelData.id)
                                            primaryValue: modelData.id === "system" ? root.cpuUsage : -1
                                            secondaryValue: modelData.id === "system" ? root.ramUsage : -1
                                            cpuCoreCount: modelData.id === "system" ? root.cpuCoreStats.count : 0
                                            cpuCorePeak: modelData.id === "system" ? root.cpuCoreStats.peak : -1
                                            cpuCorePeakId: modelData.id === "system" ? root.cpuCoreStats.peakId : ""
                                            ramCapacityText: modelData.id === "system" ? root.ramCapacity.compact : ""
                                            ramCapacityAccessibleText: modelData.id === "system" ? root.ramCapacity.accessible : ""
                                            swapCapacityText: modelData.id === "system" ? root.swapCapacity.compact : ""
                                            swapCapacityAccessibleText: modelData.id === "system" ? root.swapCapacity.accessible : ""
                                            cpuLoadAverageText: modelData.id === "system" ? root.cpuLoadAverage.text : ""
                                            cpuLoadAverageAccessibleText: modelData.id === "system" ? root.cpuLoadAverage.accessible : ""
                                            topResourceAppText: modelData.id === "system" ? root.dashboardTopResourceApp.text : ""
                                            topResourceAppLabel: modelData.id === "system" ? root.dashboardTopResourceApp.label : ""
                                            topResourceAppName: modelData.id === "system" ? root.dashboardTopResourceApp.name : ""
                                            topResourceAppProcessCount: modelData.id === "system" ? String(root.dashboardTopResourceApp.processCount || "") : ""
                                            topResourceAppValue: modelData.id === "system" ? root.dashboardTopResourceApp.value : ""
                                            topResourceAppAccessibleText: modelData.id === "system" ? root.dashboardTopResourceApp.accessible : ""
                                            systemUptimeAccessibleText: modelData.id === "system" ? root.systemUptime.accessible : ""
                                            detailPrimaryText: modelData.id === "network" && root.networkSampleReady ? root.networkDisplayValue("down") : "—"
                                            detailSecondaryText: modelData.id === "network" && root.networkSampleReady ? root.networkDisplayValue("up") : "—"
                                            networkConnectionText: modelData.id === "network" ? root.networkConnectionText : ""
                                            networkConnectionAccessibleText: modelData.id === "network" ? root.networkConnectionAccessibleText : ""
                                            tertiaryText: modelData.id === "media" && Settings.player ? root.mediaDetail : ""
                                            tertiaryLabel: modelData.id === "media" && Settings.player && root.mediaDetail !== "" ? root.mediaDetailLabel : ""
                                            mediaProgressPercent: modelData.id === "media" && Settings.player ? root.mediaProgressPercent : -1
                                            mediaRemainingTime: modelData.id === "media" && Settings.player ? root.mediaRemainingTime : ""
                                            iconSource: modelData.id === "weather" && Settings.weatherNow ? root.weatherIconSource : ""
                                            comfortText: modelData.id === "weather" && Settings.weatherNow ? root.weatherComfortTemperature : ""
                                            windText: modelData.id === "weather" && Settings.weatherNow ? root.weatherWindSpeed : ""
                                            windDirection: modelData.id === "weather" && Settings.weatherNow ? root.weatherWindDirection : ""
                                            windDirectionName: modelData.id === "weather" && Settings.weatherNow ? root.weatherWindDirectionName : ""
                                            pressureText: modelData.id === "weather" && Settings.weatherNow ? root.weatherPressure : ""
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        id: cardColumns
                        anchors.fill: parent
                        spacing: DashboardCards.COLUMN_GAP
                        visible: cards.orderedCards.length > 0 && !cards.useWideLeadHorizontalLayout

                        ColumnLayout {
                            id: leftColumn
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.alignment: Qt.AlignTop
                            spacing: DashboardCards.COLUMN_GAP

                            Repeater {
                                model: cards.columnSplit.left
                                delegate: InfoCard {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: modelData.id === cards.spanningCardId
                                        ? cards.spanningCardHeight
                                        : DashboardCards.cardHeight(modelData.id, Config.dashboardCardSizes)
                                    cardId: modelData.id
                                    expanded: DashboardCards.cardSizeMode(Config.dashboardCardSizes, modelData.id) === "expanded"
                                    title: modelData.label
                                    symbol: modelData.symbol
                                    settingsPageId: modelData.settingsPageId
                                    onSettingsRequested: pageId => root.moduleSettingsRequested(pageId)
                                    primaryText: root.cardPrimaryText(modelData.id)
                                    secondaryText: root.cardSecondaryText(modelData.id)
                                    footerText: root.cardFooterText(modelData.id)
                                    primaryValue: modelData.id === "system" ? root.cpuUsage : -1
                                    secondaryValue: modelData.id === "system" ? root.ramUsage : -1
                                    cpuCoreCount: modelData.id === "system" ? root.cpuCoreStats.count : 0
                                    cpuCorePeak: modelData.id === "system" ? root.cpuCoreStats.peak : -1
                                    cpuCorePeakId: modelData.id === "system" ? root.cpuCoreStats.peakId : ""
                                    ramCapacityText: modelData.id === "system" ? root.ramCapacity.compact : ""
                                    ramCapacityAccessibleText: modelData.id === "system" ? root.ramCapacity.accessible : ""
                                    swapCapacityText: modelData.id === "system" ? root.swapCapacity.compact : ""
                                    swapCapacityAccessibleText: modelData.id === "system" ? root.swapCapacity.accessible : ""
                                    cpuLoadAverageText: modelData.id === "system" ? root.cpuLoadAverage.text : ""
                                    cpuLoadAverageAccessibleText: modelData.id === "system" ? root.cpuLoadAverage.accessible : ""
                                    topResourceAppText: modelData.id === "system" ? root.dashboardTopResourceApp.text : ""
                                    topResourceAppLabel: modelData.id === "system" ? root.dashboardTopResourceApp.label : ""
                                    topResourceAppName: modelData.id === "system" ? root.dashboardTopResourceApp.name : ""
                                    topResourceAppProcessCount: modelData.id === "system" ? String(root.dashboardTopResourceApp.processCount || "") : ""
                                    topResourceAppValue: modelData.id === "system" ? root.dashboardTopResourceApp.value : ""
                                    topResourceAppAccessibleText: modelData.id === "system" ? root.dashboardTopResourceApp.accessible : ""
                                    systemUptimeAccessibleText: modelData.id === "system" ? root.systemUptime.accessible : ""
                                    detailPrimaryText: modelData.id === "network" && root.networkSampleReady ? root.networkDisplayValue("down") : "—"
                                    detailSecondaryText: modelData.id === "network" && root.networkSampleReady ? root.networkDisplayValue("up") : "—"
                                    networkConnectionText: modelData.id === "network" ? root.networkConnectionText : ""
                                    networkConnectionAccessibleText: modelData.id === "network" ? root.networkConnectionAccessibleText : ""
                                    tertiaryText: modelData.id === "media" && Settings.player ? root.mediaDetail : ""
                                    tertiaryLabel: modelData.id === "media" && Settings.player && root.mediaDetail !== "" ? root.mediaDetailLabel : ""
                                    mediaProgressPercent: modelData.id === "media" && Settings.player ? root.mediaProgressPercent : -1
                                    mediaRemainingTime: modelData.id === "media" && Settings.player ? root.mediaRemainingTime : ""
                                    iconSource: modelData.id === "weather" && Settings.weatherNow ? root.weatherIconSource : ""
                                    comfortText: modelData.id === "weather" && Settings.weatherNow ? root.weatherComfortTemperature : ""
                                    windText: modelData.id === "weather" && Settings.weatherNow ? root.weatherWindSpeed : ""
                                    windDirection: modelData.id === "weather" && Settings.weatherNow ? root.weatherWindDirection : ""
                                    windDirectionName: modelData.id === "weather" && Settings.weatherNow ? root.weatherWindDirectionName : ""
                                    pressureText: modelData.id === "weather" && Settings.weatherNow ? root.weatherPressure : ""
                                }
                            }
                        }

                        ColumnLayout {
                            id: rightColumn
                            visible: cards.useTwoColumns && cards.columnSplit.right.length > 0
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.alignment: Qt.AlignTop
                            spacing: DashboardCards.COLUMN_GAP

                            Repeater {
                                model: cards.columnSplit.right
                                delegate: InfoCard {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: modelData.id === cards.spanningCardId
                                        ? cards.spanningCardHeight
                                        : DashboardCards.cardHeight(modelData.id, Config.dashboardCardSizes)
                                    cardId: modelData.id
                                    expanded: DashboardCards.cardSizeMode(Config.dashboardCardSizes, modelData.id) === "expanded"
                                    title: modelData.label
                                    symbol: modelData.symbol
                                    settingsPageId: modelData.settingsPageId
                                    onSettingsRequested: pageId => root.moduleSettingsRequested(pageId)
                                    primaryText: root.cardPrimaryText(modelData.id)
                                    secondaryText: root.cardSecondaryText(modelData.id)
                                    footerText: root.cardFooterText(modelData.id)
                                    primaryValue: modelData.id === "system" ? root.cpuUsage : -1
                                    secondaryValue: modelData.id === "system" ? root.ramUsage : -1
                                    cpuCoreCount: modelData.id === "system" ? root.cpuCoreStats.count : 0
                                    cpuCorePeak: modelData.id === "system" ? root.cpuCoreStats.peak : -1
                                    cpuCorePeakId: modelData.id === "system" ? root.cpuCoreStats.peakId : ""
                                    ramCapacityText: modelData.id === "system" ? root.ramCapacity.compact : ""
                                    ramCapacityAccessibleText: modelData.id === "system" ? root.ramCapacity.accessible : ""
                                    swapCapacityText: modelData.id === "system" ? root.swapCapacity.compact : ""
                                    swapCapacityAccessibleText: modelData.id === "system" ? root.swapCapacity.accessible : ""
                                    cpuLoadAverageText: modelData.id === "system" ? root.cpuLoadAverage.text : ""
                                    cpuLoadAverageAccessibleText: modelData.id === "system" ? root.cpuLoadAverage.accessible : ""
                                    topResourceAppText: modelData.id === "system" ? root.dashboardTopResourceApp.text : ""
                                    topResourceAppLabel: modelData.id === "system" ? root.dashboardTopResourceApp.label : ""
                                    topResourceAppName: modelData.id === "system" ? root.dashboardTopResourceApp.name : ""
                                    topResourceAppProcessCount: modelData.id === "system" ? String(root.dashboardTopResourceApp.processCount || "") : ""
                                    topResourceAppValue: modelData.id === "system" ? root.dashboardTopResourceApp.value : ""
                                    topResourceAppAccessibleText: modelData.id === "system" ? root.dashboardTopResourceApp.accessible : ""
                                    systemUptimeAccessibleText: modelData.id === "system" ? root.systemUptime.accessible : ""
                                    detailPrimaryText: modelData.id === "network" && root.networkSampleReady ? root.networkDisplayValue("down") : "—"
                                    detailSecondaryText: modelData.id === "network" && root.networkSampleReady ? root.networkDisplayValue("up") : "—"
                                    networkConnectionText: modelData.id === "network" ? root.networkConnectionText : ""
                                    networkConnectionAccessibleText: modelData.id === "network" ? root.networkConnectionAccessibleText : ""
                                    tertiaryText: modelData.id === "media" && Settings.player ? root.mediaDetail : ""
                                    tertiaryLabel: modelData.id === "media" && Settings.player && root.mediaDetail !== "" ? root.mediaDetailLabel : ""
                                    mediaProgressPercent: modelData.id === "media" && Settings.player ? root.mediaProgressPercent : -1
                                    mediaRemainingTime: modelData.id === "media" && Settings.player ? root.mediaRemainingTime : ""
                                    iconSource: modelData.id === "weather" && Settings.weatherNow ? root.weatherIconSource : ""
                                    comfortText: modelData.id === "weather" && Settings.weatherNow ? root.weatherComfortTemperature : ""
                                    windText: modelData.id === "weather" && Settings.weatherNow ? root.weatherWindSpeed : ""
                                    windDirection: modelData.id === "weather" && Settings.weatherNow ? root.weatherWindDirection : ""
                                    windDirectionName: modelData.id === "weather" && Settings.weatherNow ? root.weatherWindDirectionName : ""
                                    pressureText: modelData.id === "weather" && Settings.weatherNow ? root.weatherPressure : ""
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: Math.min(260, Math.max(1, parent.width - 32))
                        spacing: 10
                        visible: cards.orderedCards.length === 0

                        Text {
                            Layout.fillWidth: true
                            text: "Карточки не выбраны\nДобавь нужные карточки в обзор"
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.WordWrap
                        }

                        QuickAction {
                            id: configureDashboardAction
                            visible: cards.orderedCards.length === 0
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: Math.min(220, Math.max(160, parent.width - 16))
                            label: "Настроить карточки"
                            symbol: "⚙"
                            Accessible.name: "Настроить карточки Dashboard"
                            Accessible.description: "Открывает настройки Dashboard, где можно вернуть карточки в обзор."
                            onClicked: {
                                root.closeRequested()
                                root.moduleSettingsRequested("dashboard")
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: {
                        var actionHint = "Выбрать"
                        if (root.currentNavigationTarget === closeButton)
                            actionHint = "Закрыть"
                        else if (root.currentNavigationTarget === configureDashboardAction)
                            actionHint = "Настроить"
                        else if (root.currentNavigationTarget)
                            actionHint = "Открыть"

                        // Keep every implemented navigation key discoverable.
                        // The former decorative Dashboard caption used the space
                        // needed to explain Home/End and the empty-state action.
                        var navigationHint = drawer.width < 440
                            ? "←↑→↓ Навигация · PgUp/PgDn Листать · Home/End Края"
                            : "← ↑ → ↓ Навигация · PgUp/PgDn Листать · Home/End Начало/конец"
                        return navigationHint + " · Enter/Space " + actionHint + " · Esc Закрыть"
                    }
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: drawer.width < 440 ? 8 : 9
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }
    }

    Shortcut {
        sequence: "Esc"
        enabled: root.open
        onActivated: root.closeRequested()
    }

    component QuickAction: Rectangle {
        id: actionRoot
        readonly property bool navigationCard: false
        property string label: ""
        property string symbol: ""
        signal clicked()
        implicitHeight: 54
        radius: Config.frameRadius
        activeFocusOnTab: enabled
        Accessible.role: Accessible.Button
        Accessible.name: actionRoot.label
        Accessible.description: {
            if (actionRoot.label === "Лаунчер") return "Открывает лаунчер приложений и команд."
            if (actionRoot.label === "Календарь") return "Открывает календарь."
            if (actionRoot.label === "Настройки") return "Открывает настройки Quickshell Widgets."
            return "Выполняет быстрое действие Dashboard."
        }
        Component.onCompleted: root.registerNavigationTarget(actionRoot)
        Component.onDestruction: root.unregisterNavigationTarget(actionRoot)
        onActiveFocusChanged: {
            if (activeFocus)
                root.setNavigationTargetFocused(actionRoot)
            else
                root.releaseNavigationTargetFocus(actionRoot)
        }
        onEnabledChanged: {
            if (!enabled)
                root.invalidateNavigationTarget(actionRoot)
        }
        onVisibleChanged: {
            if (!visible)
                root.invalidateNavigationTarget(actionRoot)
        }
        // Pointer hover is a soft preview; keyboard focus is the persistent,
        // high-contrast selection state. Press remains the strongest transient state.
        color: actionMouse.pressed
               ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.22)
               : (actionRoot.activeFocus
                  ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, DashboardCards.CARD_FOCUS_SURFACE_ALPHA)
                  : (actionMouse.containsMouse
                     ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, DashboardCards.CARD_HOVER_SURFACE_ALPHA)
                     : Qt.rgba(Config.baseColor.r, Config.baseColor.g, Config.baseColor.b, 0.18)))
        border.color: actionRoot.activeFocus
                      ? Config.accent
                      : (actionMouse.containsMouse
                         ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, DashboardCards.CARD_HOVER_BORDER_ALPHA)
                         : Qt.rgba(Config.baseColor.r, Config.baseColor.g, Config.baseColor.b, 0.65))
        border.width: actionRoot.activeFocus ? DashboardCards.CARD_FOCUS_BORDER_WIDTH : 1
        opacity: enabled ? 1 : 0.45
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                event.accepted = true
                actionRoot.clicked()
            }
        }
        Behavior on color {
            ColorAnimation { duration: Config.animationDuration(DashboardCards.CARD_HOVER_DURATION, "appearance") }
        }
        Behavior on border.color {
            ColorAnimation { duration: Config.animationDuration(DashboardCards.CARD_HOVER_DURATION, "appearance") }
        }
        Behavior on border.width {
            NumberAnimation { duration: Config.animationDuration(DashboardCards.CARD_HOVER_DURATION, "appearance"); easing.type: Easing.OutCubic }
        }
        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: actionRoot.symbol
                color: Config.accent
                font.pixelSize: 17
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: actionRoot.label
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: 10
            }
        }
        MouseArea {
            id: actionMouse
            anchors.fill: parent
            enabled: actionRoot.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                actionRoot.forceActiveFocus()
                actionRoot.clicked()
            }
        }
    }

    component UsageMeter: ColumnLayout {
        id: usageMeter
        property string label: ""
        property int value: -1
        property bool dense: false
        spacing: dense ? 2 : 3

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: usageMeter.label
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: usageMeter.dense ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
            }
            Item { Layout.fillWidth: true }
            Text {
                text: usageMeter.value >= 0 ? usageMeter.value + "%" : "—"
                color: Config.text
                font.family: Config.settingsFont
                font.pixelSize: usageMeter.dense ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                font.bold: true
            }
        }

        Rectangle {
            id: meterTrack
            Layout.fillWidth: true
            height: usageMeter.dense ? 5 : 6
            radius: 3
            color: Qt.rgba(Config.baseColor.r, Config.baseColor.g, Config.baseColor.b, 0.34)

            Rectangle {
                width: usageMeter.value >= 0
                       ? meterTrack.width * Math.max(0, Math.min(100, usageMeter.value)) / 100
                       : 0
                height: parent.height
                radius: parent.radius
                color: Config.accent
            }
        }
    }

    component InfoCard: Rectangle {
        id: infoCard
        readonly property bool navigationCard: true
        property string cardId: ""
        onCardIdChanged: root.scheduleDashboardLayoutSync()
        property bool wideLead: false
        property bool expanded: false
        readonly property bool narrow: width < DashboardCards.NARROW_CARD_WIDTH
        property string title: ""
        property string symbol: ""
        property string primaryText: ""
        property string secondaryText: ""
        property string footerText: ""
        property int primaryValue: -1
        property int secondaryValue: -1
        property int cpuCoreCount: 0
        property int cpuCorePeak: -1
        property string cpuCorePeakId: ""
        property string ramCapacityText: ""
        property string ramCapacityAccessibleText: ""
        property string swapCapacityText: ""
        property string swapCapacityAccessibleText: ""
        property string cpuLoadAverageText: ""
        property string cpuLoadAverageAccessibleText: ""
        property string topResourceAppText: ""
        property string topResourceAppLabel: ""
        property string topResourceAppName: ""
        property string topResourceAppProcessCount: ""
        property string topResourceAppValue: ""
        property string topResourceAppAccessibleText: ""
        property string systemUptimeAccessibleText: ""
        property string detailPrimaryText: ""
        property string detailSecondaryText: ""
        property string networkConnectionText: ""
        property string networkConnectionAccessibleText: ""
        property string tertiaryText: ""
        property string tertiaryLabel: ""
        property int mediaProgressPercent: -1
        property string mediaRemainingTime: ""
        property string iconSource: ""
        property string comfortText: ""
        property string windText: ""
        property string windDirection: ""
        property string windDirectionName: ""
        property string pressureText: ""
        readonly property string todayTimeText: root.clock ? root.clock.time : Qt.formatTime(new Date(), "HH:mm:ss")
        readonly property string todayDateText: root.clock
            ? root.clock.weekday + " · " + root.clock.dateText
            : Qt.formatDate(new Date(), "dddd · dd.MM.yyyy")
        readonly property string todayNoteText: CalendarNotes.loaded ? String(CalendarNotes.todayNote || "") : ""
        readonly property string tomorrowNoteText: CalendarNotes.loaded ? String(CalendarNotes.tomorrowNote || "") : ""
        readonly property bool hasTodayNote: todayNoteText.trim() !== ""
        readonly property bool hasTomorrowNote: tomorrowNoteText.trim() !== ""
        readonly property bool hasAnyCalendarNotes: hasTodayNote || hasTomorrowNote
        property string settingsPageId: ""
        signal settingsRequested(string pageId)
        radius: Config.frameRadius + 1
        enabled: settingsPageId !== ""
        activeFocusOnTab: enabled
        Accessible.role: Accessible.Button
        Accessible.name: infoCard.title
        function accessibleDetails() {
            var details = []

            if (infoCard.cardId === "today") {
                details.push("Текущее время " + infoCard.todayTimeText)
                details.push("Дата " + infoCard.todayDateText)
                if (infoCard.todayNoteText.trim() !== "")
                    details.push("Заметка на сегодня: " + infoCard.todayNoteText.replace(/\s+/g, " ").trim())
                if (infoCard.tomorrowNoteText.trim() !== "")
                    details.push("Заметка на завтра: " + infoCard.tomorrowNoteText.replace(/\s+/g, " ").trim())
            } else if (infoCard.cardId === "system") {
                if (!Settings.cpu) {
                    details.push("Модуль CPU и RAM выключен")
                } else {
                    details.push(infoCard.primaryValue >= 0
                        ? "Загрузка процессора " + infoCard.primaryValue + " процентов"
                        : "Данные о загрузке процессора пока недоступны")
                    details.push(infoCard.secondaryValue >= 0
                        ? "Использование оперативной памяти " + infoCard.secondaryValue + " процентов"
                        : "Данные об использовании оперативной памяти пока недоступны")
                    if (infoCard.expanded && infoCard.ramCapacityAccessibleText !== "")
                        details.push(infoCard.ramCapacityAccessibleText)
                    if (infoCard.expanded && infoCard.cpuCoreCount > 0) {
                        details.push("Количество логических CPU " + infoCard.cpuCoreCount)
                        if (infoCard.cpuCorePeak >= 0)
                            details.push(infoCard.cpuCorePeakId !== ""
                                ? "Максимальная загрузка логического процессора " + infoCard.cpuCorePeakId + ": " + infoCard.cpuCorePeak + " процентов"
                                : "Максимальная загрузка наиболее загруженного логического процессора: " + infoCard.cpuCorePeak + " процентов")
                    }
                    if (infoCard.expanded && infoCard.swapCapacityAccessibleText !== "")
                        details.push(infoCard.swapCapacityAccessibleText)
                    if (infoCard.expanded && infoCard.cpuLoadAverageAccessibleText !== "")
                        details.push(infoCard.cpuLoadAverageAccessibleText)
                    if (infoCard.expanded && infoCard.topResourceAppAccessibleText !== "")
                        details.push(infoCard.topResourceAppAccessibleText)
                    if (infoCard.systemUptimeAccessibleText !== "")
                        details.push(infoCard.systemUptimeAccessibleText)
                }
            } else if (infoCard.cardId === "network") {
                if (!Settings.networkStat) {
                    details.push("Статистика сети выключена")
                } else {
                    var downloadRate = String(infoCard.primaryText || "").replace("↓", "").trim()
                    var uploadRate = String(infoCard.secondaryText || "").replace("↑", "").trim()
                    details.push(downloadRate !== "" && downloadRate !== "—"
                        ? "Скорость загрузки " + downloadRate
                        : "Скорость загрузки пока недоступна")
                    details.push(uploadRate !== "" && uploadRate !== "—"
                        ? "Скорость отдачи " + uploadRate
                        : "Скорость отдачи пока недоступна")
                    if (infoCard.expanded) {
                        if (infoCard.networkConnectionAccessibleText !== "")
                            details.push(infoCard.networkConnectionAccessibleText)
                        var downloadedTotal = String(infoCard.detailPrimaryText || "").trim()
                        var uploadedTotal = String(infoCard.detailSecondaryText || "").trim()
                        details.push(downloadedTotal !== "" && downloadedTotal !== "—"
                            ? "Загружено всего " + downloadedTotal
                            : "Общий объём загрузки пока недоступен")
                        details.push(uploadedTotal !== "" && uploadedTotal !== "—"
                            ? "Отправлено всего " + uploadedTotal
                            : "Общий объём отдачи пока недоступен")
                    }
                }
            } else if (infoCard.cardId === "weather") {
                if (!Settings.weatherNow) {
                    details.push("Модуль погоды выключен")
                } else {
                    var temperature = String(infoCard.primaryText || "").trim()
                    var conditions = String(infoCard.secondaryText || "").trim()
                    details.push(temperature !== "" && temperature !== "—"
                        ? "Температура " + temperature
                        : "Текущая температура пока недоступна")
                    if (conditions !== "" && conditions !== "—")
                        details.push("Погодные условия " + conditions)
                    else
                        details.push("Описание погодных условий пока недоступно")
                    if (infoCard.expanded) {
                        if (String(infoCard.comfortText || "").trim() !== "")
                            details.push("Ощущается " + infoCard.comfortText)
                        var windSpeed = String(infoCard.windText || "").trim()
                        var windDirectionName = String(infoCard.windDirectionName || "").trim()
                        if (windDirectionName === "штиль")
                            details.push(windSpeed !== "" ? "Штиль, " + windSpeed : "Штиль")
                        else if (windDirectionName !== "" && windSpeed !== "")
                            details.push("Ветер " + windDirectionName + ", " + windSpeed)
                        else if (windDirectionName !== "")
                            details.push("Направление ветра " + windDirectionName)
                        else if (windSpeed !== "")
                            details.push("Скорость ветра " + windSpeed)
                        var pressure = String(infoCard.pressureText || "").trim()
                        if (pressure !== "")
                            details.push("Атмосферное давление " + pressure + " миллиметров ртутного столба")
                    }
                }
            } else if (infoCard.cardId === "media") {
                if (!Settings.player) {
                    details.push("Модуль Player выключен")
                } else {
                    var trackTitle = String(infoCard.primaryText || "").trim()
                    var trackArtist = String(infoCard.secondaryText || "").trim()
                    var backendLabel = root.mediaBackendLabel()
                    if (trackTitle === "" || trackTitle === "Ничего не воспроизводится") {
                        details.push("Сейчас ничего не воспроизводится")
                    } else if (trackTitle === "Название недоступно") {
                        if (root.mediaPlaybackState === "paused")
                            details.push("Воспроизведение приостановлено, название трека недоступно")
                        else if (root.mediaPlaybackState === "playing")
                            details.push("Воспроизводится трек без доступного названия")
                        else {
                            details.push("Название текущего трека недоступно")
                            details.push("Источник не сообщает состояние воспроизведения")
                        }
                    } else if (root.mediaPlaybackState === "paused") {
                        details.push("На паузе " + trackTitle)
                    } else if (root.mediaPlaybackState === "playing") {
                        details.push("Сейчас воспроизводится " + trackTitle)
                    } else {
                        details.push("Текущий трек " + trackTitle)
                        details.push("Источник не сообщает состояние воспроизведения")
                    }
                    if (trackArtist !== "")
                        details.push("Исполнитель " + trackArtist)
                    if (backendLabel !== "")
                        details.push("Источник воспроизведения " + backendLabel)
                    if (infoCard.expanded && infoCard.mediaProgressPercent >= 0) {
                        details.push("Позиция воспроизведения " + infoCard.mediaProgressPercent + " процентов")
                        if (infoCard.mediaRemainingTime !== "")
                            details.push("Осталось " + infoCard.mediaRemainingTime)
                    }
                    if (infoCard.expanded && String(infoCard.tertiaryText || "").trim() !== "") {
                        var detailLabel = String(infoCard.tertiaryLabel || "Дополнительные данные").trim()
                        details.push(detailLabel + " " + String(infoCard.tertiaryText).trim())
                    }
                }
            }

            var footer = String(infoCard.footerText || "").trim()
            var announceFooter = (infoCard.cardId === "system" && Settings.cpu
                                  && infoCard.systemUptimeAccessibleText === "")
                || (infoCard.cardId === "network" && Settings.networkStat)
                || (infoCard.cardId === "weather" && Settings.weatherNow)
            if (announceFooter && footer !== "" && details.indexOf(footer) < 0)
                details.push(footer)
            details.push("Нажмите Enter или Пробел, чтобы открыть настройки модуля.")
            return details.join(". ")
        }
        Accessible.description: infoCard.accessibleDetails()
        Component.onCompleted: root.registerNavigationTarget(infoCard)
        Component.onDestruction: root.unregisterNavigationTarget(infoCard)
        onActiveFocusChanged: {
            if (activeFocus)
                root.setNavigationTargetFocused(infoCard)
            else
                root.releaseNavigationTargetFocus(infoCard)
        }
        onEnabledChanged: {
            if (!enabled)
                root.invalidateNavigationTarget(infoCard)
        }
        onVisibleChanged: {
            if (!visible)
                root.invalidateNavigationTarget(infoCard)
        }
        // Keep a single unmistakable selection: focus wins over hover, while
        // a hovered neighbour receives only a subdued preview treatment.
        // Dashboard cards have no permanent surface. Hover and keyboard focus
        // retain their temporary feedback so the whole-card settings action stays discoverable.
        color: infoCard.activeFocus
               ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, DashboardCards.CARD_FOCUS_SURFACE_ALPHA)
               : (cardMouse.containsMouse
                  ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, DashboardCards.CARD_HOVER_SURFACE_ALPHA)
                  : "transparent")
        border.color: infoCard.activeFocus
                      ? Config.accent
                      : (cardMouse.containsMouse
                         ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, DashboardCards.CARD_HOVER_BORDER_ALPHA)
                         : Qt.rgba(Config.baseColor.r, Config.baseColor.g, Config.baseColor.b, 0.52))
        border.width: infoCard.activeFocus ? Math.max(DashboardCards.CARD_FOCUS_BORDER_WIDTH, Config.frameBorderWidth + 1)
                                          : 1
        Keys.onPressed: function(event) {
            if (infoCard.settingsPageId !== ""
                    && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
                event.accepted = true
                infoCard.settingsRequested(infoCard.settingsPageId)
            }
        }
        Behavior on color {
            ColorAnimation { duration: Config.animationDuration(DashboardCards.CARD_HOVER_DURATION, "appearance") }
        }
        Behavior on border.color {
            ColorAnimation { duration: Config.animationDuration(DashboardCards.CARD_HOVER_DURATION, "appearance") }
        }
        Behavior on border.width {
            NumberAnimation { duration: Config.animationDuration(DashboardCards.CARD_HOVER_DURATION, "appearance"); easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: infoCard.cardId === "today" && infoCard.wideLead
                ? 6
                : (infoCard.wideLead ? DashboardCards.WIDE_LEAD_CARD_PADDING : DashboardCards.CARD_PADDING)
            spacing: DashboardCards.CARD_SECTION_GAP

            // A consistent icon badge creates a clear first level in the card
            // hierarchy without assigning a different visual language per module.
            RowLayout {
                Layout.fillWidth: true
                spacing: DashboardCards.CARD_HEADER_GAP

                Rectangle {
                    Layout.preferredWidth: DashboardCards.CARD_BADGE_SIZE
                    Layout.preferredHeight: DashboardCards.CARD_BADGE_SIZE
                    radius: 8
                    color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.13)
                    border.width: 1
                    border.color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.24)

                    Text {
                        anchors.centerIn: parent
                        text: infoCard.symbol
                        color: Config.accent
                        font.family: Config.font
                        font.pixelSize: 13
                    }
                }

                Text {
                    text: infoCard.title
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: 13
                    font.bold: true
                }

                Item { Layout.fillWidth: true }
            }

            // Keep each card's content block on a shared vertical centreline.
            // Matching flexible space above and below the body makes cards with
            // different module-specific content feel aligned without stretching
            // text rows or moving the common header/footer anchors.
            Item {
                Layout.fillHeight: !(infoCard.cardId === "today" && infoCard.wideLead)
                Layout.minimumHeight: 0
                Layout.preferredHeight: 0
            }

            // Every wide-lead Today card uses the same horizontal information
            // hierarchy. Compact cards use a content-sized track: one or zero
            // note rows stay tight, while two notes get room for four text lines.
            // Expanded cards retain their larger track and typography.
            RowLayout {
                visible: infoCard.cardId === "today" && infoCard.wideLead
                Layout.fillWidth: true
                Layout.fillHeight: false
                // Compact Today needs a denser, taller content track than the
                // original 76 px slot: its small type scale left too much unused
                // vertical room inside the fixed 164 px card silhouette.
                Layout.preferredHeight: infoCard.expanded ? 112 : 92
                Layout.minimumHeight: infoCard.expanded ? 104 : 88
                Layout.maximumHeight: infoCard.expanded ? 120 : 96
                spacing: infoCard.expanded ? 12 : 6

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.horizontalStretchFactor: infoCard.hasAnyCalendarNotes ? 40 : 100
                    Layout.minimumWidth: 0
                    Layout.alignment: Qt.AlignVCenter
                    spacing: infoCard.expanded ? 8 : 5

                    Text {
                        Layout.fillWidth: true
                        text: infoCard.todayTimeText
                        color: Config.text
                        font.family: Config.ledFont
                        font.pixelSize: infoCard.expanded ? 40 : 34
                        font.bold: false
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    Text {
                        Layout.fillWidth: true
                        text: infoCard.todayDateText
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.expanded ? 12 : 11
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    visible: infoCard.hasAnyCalendarNotes
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: infoCard.expanded ? 76 : 70
                    Layout.alignment: Qt.AlignVCenter
                    color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.30)
                }

                Rectangle {
                    visible: infoCard.hasAnyCalendarNotes
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.horizontalStretchFactor: 60
                    Layout.minimumWidth: 0
                    radius: infoCard.expanded ? 10 : 8
                    color: "transparent"
                    border.width: 0

                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: infoCard.expanded ? 6 : 2
                        anchors.rightMargin: infoCard.expanded ? 6 : 2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: infoCard.expanded ? 4 : 2

                        RowLayout {
                            visible: infoCard.hasTodayNote
                            Layout.fillWidth: true
                            Layout.minimumHeight: infoCard.expanded ? 34 : 30
                            Layout.preferredHeight: infoCard.expanded ? 34 : 30
                            Layout.maximumHeight: infoCard.expanded ? 34 : 30
                            spacing: 4

                            Text {
                                Layout.preferredWidth: infoCard.expanded ? 50 : 40
                                color: Config.textMuted
                                text: "СЕГОДНЯ"
                                font.family: Config.settingsFont
                                font.pixelSize: infoCard.expanded ? 9 : 9
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumWidth: 0
                                text: infoCard.todayNoteText
                                color: Config.text
                                font.family: Config.settingsFont
                                font.pixelSize: infoCard.expanded ? 12 : 11
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Rectangle {
                            visible: infoCard.hasTodayNote && infoCard.hasTomorrowNote
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Qt.rgba(Config.textMuted.r, Config.textMuted.g, Config.textMuted.b, 0.24)
                        }

                        RowLayout {
                            visible: infoCard.hasTomorrowNote
                            Layout.fillWidth: true
                            Layout.minimumHeight: infoCard.expanded ? 34 : 30
                            Layout.preferredHeight: infoCard.expanded ? 34 : 30
                            Layout.maximumHeight: infoCard.expanded ? 34 : 30
                            spacing: 4

                            Text {
                                Layout.preferredWidth: infoCard.expanded ? 50 : 40
                                color: Config.textMuted
                                text: "ЗАВТРА"
                                font.family: Config.settingsFont
                                font.pixelSize: infoCard.expanded ? 9 : 9
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.minimumWidth: 0
                                text: infoCard.tomorrowNoteText
                                color: Config.text
                                font.family: Config.settingsFont
                                font.pixelSize: infoCard.expanded ? 12 : 11
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }

            // Non-wide Today cards retain the original vertical reading order.
            ColumnLayout {
                visible: infoCard.cardId === "today" && !infoCard.wideLead
                Layout.fillWidth: true
                spacing: infoCard.expanded ? 7 : 4

                Text {
                    Layout.fillWidth: true
                    text: infoCard.todayTimeText
                    color: Config.text
                    font.family: Config.ledFont
                    font.pixelSize: infoCard.expanded ? 29 : 25
                    font.bold: false
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                Text {
                    Layout.fillWidth: true
                    text: infoCard.todayDateText
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: infoCard.expanded ? 12 : 11
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }
                RowLayout {
                    visible: infoCard.todayNoteText.trim() !== ""
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        text: "Сегодня"
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.expanded ? 10 : 9
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: infoCard.todayNoteText
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.expanded ? 11 : 10
                        wrapMode: Text.WordWrap
                        maximumLineCount: infoCard.expanded ? 3 : 1
                        elide: Text.ElideRight
                    }
                }
                RowLayout {
                    visible: infoCard.tomorrowNoteText.trim() !== ""
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        text: "Завтра"
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.expanded ? 10 : 9
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: infoCard.tomorrowNoteText
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.expanded ? 11 : 10
                        wrapMode: Text.WordWrap
                        maximumLineCount: infoCard.expanded ? 3 : 1
                        elide: Text.ElideRight
                    }
                }
            }

            // Compact cards retain the original two-line summary from v1219.
            ColumnLayout {
                visible: !infoCard.expanded && infoCard.cardId !== "today"
                Layout.fillWidth: true
                spacing: DashboardCards.CARD_BODY_GAP

                Text {
                    Layout.fillWidth: true
                    text: infoCard.primaryText
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: infoCard.narrow ? 16 : 18
                    font.bold: true
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                Text {
                    Layout.fillWidth: true
                    text: infoCard.secondaryText
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: infoCard.narrow ? 11 : 12
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                }
            }

            // The expanded System card uses two logical groups. In the wide
            // horizontal Bento lead they sit side by side: usage meters on the
            // left, supporting CPU/RAM details on the right. In all other cards
            // the same groups stack vertically, preserving the existing layout.
            GridLayout {
                visible: infoCard.expanded && infoCard.cardId === "system"
                Layout.fillWidth: true
                columns: infoCard.wideLead ? 2 : 1
                columnSpacing: infoCard.wideLead ? DashboardCards.WIDE_LEAD_GROUP_GAP : 0
                rowSpacing: 7

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: infoCard.wideLead ? Qt.AlignVCenter : Qt.AlignTop
                    spacing: 7

                    UsageMeter {
                        Layout.fillWidth: true
                        label: "CPU"
                        value: infoCard.primaryValue
                        dense: infoCard.narrow
                    }
                    UsageMeter {
                        Layout.fillWidth: true
                        label: infoCard.ramCapacityText !== ""
                               ? "RAM · " + infoCard.ramCapacityText : "RAM"
                        value: infoCard.secondaryValue
                        dense: infoCard.narrow
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: infoCard.wideLead ? Qt.AlignVCenter : Qt.AlignTop
                    spacing: 7

                    // Keep a short visual CPU-count label beside the hottest-core
                    // peak so both values remain readable in narrow cards. The
                    // Accessible description retains the full logical-CPU wording.
                    RowLayout {
                        visible: infoCard.cpuCoreCount > 0
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            // The count label is short and should keep its natural
                            // width so the more informative peak value gets the
                            // remaining space instead of both labels truncating equally.
                            Layout.fillWidth: false
                            Layout.preferredWidth: implicitWidth
                            text: "Лог. CPU: " + infoCard.cpuCoreCount
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                            maximumLineCount: 1
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: infoCard.cpuCorePeak >= 0
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            text: "Пик CPU" + (infoCard.cpuCorePeakId !== "" ? " " + infoCard.cpuCorePeakId : "")
                                  + ": " + infoCard.cpuCorePeak + "%"
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                            maximumLineCount: 1
                            elide: Text.ElideRight
                        }
                    }
                    Text {
                        visible: infoCard.swapCapacityText !== ""
                        Layout.fillWidth: true
                        text: "Подкачка · " + infoCard.swapCapacityText
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }
                    Text {
                        visible: infoCard.cpuLoadAverageText !== ""
                        Layout.fillWidth: true
                        text: infoCard.cpuLoadAverageText
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }
                    RowLayout {
                        visible: infoCard.topResourceAppText !== ""
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            Layout.fillWidth: false
                            Layout.minimumWidth: implicitWidth
                            Layout.preferredWidth: implicitWidth
                            text: infoCard.topResourceAppLabel + " ·"
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                            maximumLineCount: 1
                            textFormat: Text.PlainText
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: infoCard.topResourceAppName
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }
                        Text {
                            visible: infoCard.topResourceAppProcessCount !== ""
                            Layout.fillWidth: false
                            Layout.minimumWidth: implicitWidth
                            Layout.preferredWidth: implicitWidth
                            text: infoCard.topResourceAppProcessCount
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                            maximumLineCount: 1
                            textFormat: Text.PlainText
                        }
                        Text {
                            Layout.fillWidth: false
                            Layout.minimumWidth: implicitWidth
                            Layout.preferredWidth: implicitWidth
                            text: infoCard.topResourceAppValue
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                            maximumLineCount: 1
                            textFormat: Text.PlainText
                        }
                    }
                }
            }

            // Network expansion shows both live rate and accumulated transfer totals.
            RowLayout {
                visible: infoCard.expanded && infoCard.cardId === "network"
                Layout.fillWidth: true
                spacing: infoCard.wideLead ? DashboardCards.WIDE_LEAD_GROUP_GAP : 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: infoCard.wideLead ? 6 : 4
                    Text {
                        text: "ЗАГРУЗКА"
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.narrow ? DashboardCards.CARD_MICRO_LABEL_NARROW_SIZE : DashboardCards.CARD_MICRO_LABEL_SIZE
                        font.bold: true
                        font.letterSpacing: 0.7
                    }
                    Text {
                        Layout.fillWidth: true
                        text: infoCard.primaryText.replace("↓", "").trim()
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.narrow ? DashboardCards.CARD_METRIC_VALUE_NARROW_SIZE : DashboardCards.CARD_METRIC_VALUE_SIZE
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: infoCard.detailPrimaryText
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    width: 1
                    color: Qt.rgba(Config.baseColor.r, Config.baseColor.g, Config.baseColor.b, 0.48)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: infoCard.wideLead ? 6 : 4
                    Text {
                        text: "ОТДАЧА"
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.narrow ? DashboardCards.CARD_MICRO_LABEL_NARROW_SIZE : DashboardCards.CARD_MICRO_LABEL_SIZE
                        font.bold: true
                        font.letterSpacing: 0.7
                    }
                    Text {
                        Layout.fillWidth: true
                        text: infoCard.secondaryText.replace("↑", "").trim()
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.narrow ? DashboardCards.CARD_METRIC_VALUE_NARROW_SIZE : DashboardCards.CARD_METRIC_VALUE_SIZE
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: infoCard.detailSecondaryText
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                        elide: Text.ElideRight
                    }
                }
            }

            Text {
                visible: infoCard.expanded && infoCard.cardId === "network"
                         && infoCard.networkConnectionText !== ""
                Layout.fillWidth: true
                text: infoCard.networkConnectionText
                color: Config.textMuted
                font.family: Config.settingsFont
                font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                // Active profile and device names often exceed a narrow card's
                // width. Wrap at spaces first, but also break unusually long
                // unbroken names before the two-line limit is elided.
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 2
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            // Weather keeps the current sample intact. A wide Bento lead separates
            // the primary conditions from supporting comfort/wind/pressure details.
            GridLayout {
                visible: infoCard.expanded && infoCard.cardId === "weather"
                Layout.fillWidth: true
                columns: infoCard.wideLead ? 2 : 1
                columnSpacing: infoCard.wideLead ? DashboardCards.WIDE_LEAD_GROUP_GAP : 0
                rowSpacing: 5

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: infoCard.wideLead ? Qt.AlignVCenter : Qt.AlignTop
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 9
                        Image {
                            source: infoCard.iconSource
                            visible: source.toString() !== ""
                            Layout.preferredWidth: visible ? (infoCard.narrow ? 36 : 42) : 0
                            Layout.preferredHeight: visible ? (infoCard.narrow ? 36 : 42) : 0
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: infoCard.primaryText
                            color: Config.text
                            font.family: Config.ledFont
                            font.pixelSize: infoCard.narrow ? 24 : 27
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: infoCard.secondaryText
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.narrow ? 10 : 11
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: infoCard.wideLead ? Qt.AlignVCenter : Qt.AlignTop
                    spacing: 5

                    GridLayout {
                        Layout.fillWidth: true
                        columns: infoCard.wideLead ? 1 : 2
                        columnSpacing: infoCard.narrow ? 8 : 12
                        rowSpacing: 5
                        Text {
                            visible: infoCard.comfortText !== ""
                            Layout.fillWidth: true
                            text: "Ощущается " + infoCard.comfortText
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                            maximumLineCount: 1
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: infoCard.windText !== "" || infoCard.windDirection !== ""
                            Layout.fillWidth: true
                            text: infoCard.windDirection === "Штиль"
                                  ? (infoCard.windText !== "" ? "Штиль · " + infoCard.windText : "Штиль")
                                  : (infoCard.windDirection !== ""
                                     ? (infoCard.windText !== "" ? "Ветер " + infoCard.windDirection + " · " + infoCard.windText : "Ветер " + infoCard.windDirection)
                                     : "Ветер " + infoCard.windText)
                            color: Config.textMuted
                            font.family: Config.settingsFont
                            font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                            maximumLineCount: 1
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        visible: infoCard.pressureText !== ""
                        Layout.fillWidth: true
                        text: "Давление " + infoCard.pressureText + " мм рт. ст."
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }
                }
            }

            // Wide Media lead separates track identity from album and playback progress.
            GridLayout {
                visible: infoCard.expanded && infoCard.cardId === "media"
                Layout.fillWidth: true
                columns: infoCard.wideLead ? 2 : 1
                columnSpacing: DashboardCards.WIDE_LEAD_GROUP_GAP
                rowSpacing: 5

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: infoCard.wideLead ? Qt.AlignVCenter : Qt.AlignTop
                    spacing: 5

                    Text {
                        Layout.fillWidth: true
                        text: infoCard.primaryText
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.narrow ? 15 : 16
                        font.bold: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: infoCard.secondaryText
                        color: Config.text
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.narrow ? 10 : 11
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        opacity: 0.9
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: infoCard.wideLead ? Qt.AlignVCenter : Qt.AlignTop
                    spacing: 5

                    Text {
                        visible: infoCard.wideLead && infoCard.tertiaryText.trim() !== ""
                        Layout.fillWidth: true
                        text: infoCard.tertiaryLabel !== ""
                              ? infoCard.tertiaryLabel + " · " + infoCard.tertiaryText
                              : infoCard.tertiaryText
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                    Item {
                        visible: infoCard.mediaProgressPercent >= 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 10
                        Layout.minimumHeight: 10
                        Layout.maximumHeight: 10

                        RowLayout {
                            anchors.fill: parent
                            spacing: 8

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 4
                                Layout.minimumHeight: 4
                                Layout.maximumHeight: 4

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 2
                                    color: Qt.rgba(Config.baseColor.r, Config.baseColor.g, Config.baseColor.b, 0.52)
                                }
                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(100, infoCard.mediaProgressPercent)) / 100
                                    height: parent.height
                                    radius: 2
                                    color: Config.accent
                                    Behavior on width {
                                        NumberAnimation {
                                            duration: Config.animationDuration(180, "appearance")
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }
                            Text {
                                text: infoCard.mediaRemainingTime !== ""
                                      ? "−" + infoCard.mediaRemainingTime
                                      : infoCard.mediaProgressPercent + "%"
                                color: Config.textMuted
                                font.family: Config.settingsFont
                                font.pixelSize: 8
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                    Text {
                        visible: !infoCard.wideLead && infoCard.tertiaryText.trim() !== ""
                        Layout.fillWidth: true
                        text: infoCard.tertiaryLabel !== ""
                              ? infoCard.tertiaryLabel + " · " + infoCard.tertiaryText
                              : infoCard.tertiaryText
                        color: Config.textMuted
                        font.family: Config.settingsFont
                        font.pixelSize: infoCard.narrow ? DashboardCards.CARD_DETAIL_TEXT_NARROW_SIZE : DashboardCards.CARD_DETAIL_TEXT_SIZE
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
            }

            Item {
                Layout.fillHeight: !(infoCard.cardId === "today" && infoCard.wideLead)
                Layout.minimumHeight: 0
                Layout.preferredHeight: 0
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(Config.baseColor.r, Config.baseColor.g, Config.baseColor.b, 0.30)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: infoCard.footerText
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: infoCard.narrow ? DashboardCards.CARD_FOOTER_TEXT_NARROW_SIZE : DashboardCards.CARD_FOOTER_TEXT_SIZE
                    elide: Text.ElideRight
                }

            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            enabled: infoCard.settingsPageId !== ""
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton
            onClicked: {
                infoCard.forceActiveFocus()
                infoCard.settingsRequested(infoCard.settingsPageId)
            }
        }
    }
}

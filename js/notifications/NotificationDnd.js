.pragma library

function notificationId(notification) {
    if (!notification) return ""
    var id = notification.id
    return id === undefined || id === null ? "" : String(id)
}

function isSuppressed(notification, suppressedIds) {
    var id = notificationId(notification)
    return id !== "" && !!(suppressedIds && suppressedIds[id] === true)
}

function allowedAppTokens(value) {
    var raw = String(value === undefined || value === null ? "" : value).split(/[;,\n]+/)
    var result = []
    var seen = ({})
    for (var i = 0; i < raw.length; ++i) {
        var token = String(raw[i] || "").trim().toLowerCase()
        if (!token || seen[token] === true) continue
        seen[token] = true
        result.push(token)
    }
    return result
}

// Exact, case-insensitive matches avoid accidentally allowing similarly named apps.
// desktopEntry is preferred by users; appName is a practical fallback for senders
// that do not provide a desktop entry identifier.
function isAllowed(notification, configuredApps) {
    if (!notification) return false
    var allowed = allowedAppTokens(configuredApps)
    if (allowed.length === 0) return false
    var desktopEntry = String(notification.desktopEntry || "").trim().toLowerCase()
    var appName = String(notification.appName || "").trim().toLowerCase()
    for (var i = 0; i < allowed.length; ++i) {
        if (allowed[i] === desktopEntry || allowed[i] === appName) return true
    }
    return false
}

// DND has two complementary rule sets: allow-list while enabled, block-list while disabled.
function shouldSuppress(notification, doNotDisturb, allowedApps, blockedApps) {
    if (doNotDisturb === true) return !isAllowed(notification, allowedApps)
    return isAllowed(notification, blockedApps)
}

function arrayLikeValues(values) {
    if (!values || typeof values.length !== "number") return []
    var length = Math.max(0, Math.floor(Number(values.length) || 0))
    var result = []
    for (var i = 0; i < length; ++i) {
        var value = values[i]
        if (value !== null && value !== undefined) result.push(value)
    }
    return result
}

function visibleNotifications(values, suppressedIds) {
    // QML list properties are indexable/array-like but are not guaranteed to be
    // native JavaScript Arrays, so avoid depending on Array.filter on the input.
    var source = arrayLikeValues(values)
    var result = []
    for (var i = 0; i < source.length; ++i) {
        if (!isSuppressed(source[i], suppressedIds)) result.push(source[i])
    }
    return result
}

function boundedText(value, limit, allowDataUri) {
    var text = String(value === undefined || value === null ? "" : value)
    if (!allowDataUri && /^data:/i.test(text)) return ""
    return text.slice(0, Math.max(0, Number(limit) || 0))
}

// Store a bounded value snapshot only. No notification content is written to disk;
// large inline data images are omitted rather than copied into the memory history.
function snapshot(notification, receivedAt) {
    if (!notification) return null
    var id = notificationId(notification)
    if (id === "") return null
    return {
        id: id,
        appName: boundedText(notification.appName, 256, false),
        desktopEntry: boundedText(notification.desktopEntry, 256, false),
        appIcon: boundedText(notification.appIcon, 1024, false),
        summary: boundedText(notification.summary, 512, false),
        body: boundedText(notification.body, 8192, false),
        image: boundedText(notification.image, 2048, false),
        urgency: Number(notification.urgency) || 0,
        receivedAt: Math.max(0, Number(receivedAt) || 0)
    }
}

function trackedIdSet(values) {
    var result = ({})
    var source = arrayLikeValues(values)
    for (var i = 0; i < source.length; ++i) {
        var id = notificationId(source[i])
        if (id !== "") result[id] = true
    }
    return result
}

function pruneSuppressedIds(suppressedIds, trackedValues) {
    var active = trackedIdSet(trackedValues)
    var result = ({})
    var source = suppressedIds || ({})
    for (var id in source) {
        if (Object.prototype.hasOwnProperty.call(source, id) && active[id] === true)
            result[id] = true
    }
    return result
}

function pruneRecords(records, trackedValues) {
    var active = trackedIdSet(trackedValues)
    var source = arrayLikeValues(records)
    return source.filter(function(record) { return record && active[String(record.id)] === true })
}

function dueRecords(records, now) {
    var source = Array.isArray(records) ? records : []
    var current = Math.max(0, Number(now) || 0)
    return source.filter(function(record) {
        return record && Number(record.expiresAt) > 0 && current >= Number(record.expiresAt)
    })
}

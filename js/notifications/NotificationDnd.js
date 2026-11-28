.pragma library

.import "NotificationAppCatalog.js" as NotificationAppCatalog

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

// Exact, case-insensitive identity matching. desktopEntry is authoritative;
// appName is used only when it uniquely resolves to one observed sender. Legacy
// appName rules remain compatible while their alias is unambiguous.
function matchesApplicationRule(notification, configuredApps, senderEntries) {
    if (!notification) return false
    var configured = allowedAppTokens(configuredApps)
    if (configured.length === 0) return false

    var desktopEntry = String(notification.desktopEntry || "").trim().toLowerCase()
    var appName = String(notification.appName || "").trim().toLowerCase()
    if (desktopEntry) {
        // A desktop-entry ID is authoritative. App-name tokens are accepted
        // only as legacy aliases while that name uniquely identifies one sender.
        if (configured.indexOf(desktopEntry) >= 0) return true
        if (!appName) return false
        var legacyAliases = NotificationAppCatalog.legacyRuleIdsForDesktopEntry(desktopEntry, senderEntries)
        for (var i = 0; i < legacyAliases.length; ++i)
            if (configured.indexOf(String(legacyAliases[i]).trim().toLowerCase()) >= 0) return true
        return configured.indexOf(appName) >= 0
            && NotificationAppCatalog.isUniqueAppNameForDesktopEntry(appName, desktopEntry, senderEntries)
    }

    // Without a desktop ID, appName is the only available identity. If the
    // observed catalog proves that this name belongs to multiple senders, it
    // cannot safely select one of them.
    if (!appName || NotificationAppCatalog.isAmbiguousAppName(appName, senderEntries)) return false
    if (configured.indexOf(appName) >= 0) return true
    var nameAliases = NotificationAppCatalog.legacyRuleIdsForAppName(appName, senderEntries)
    for (var j = 0; j < nameAliases.length; ++j)
        if (configured.indexOf(String(nameAliases[j]).trim().toLowerCase()) >= 0) return true
    return false
}

function isAllowed(notification, configuredApps, senderEntries) {
    return matchesApplicationRule(notification, configuredApps, senderEntries)
}

// History exclusion is intentionally independent of DND popup suppression.
// It is evaluated only by the history-recording path.
function isHistoryIgnored(notification, configuredApps, senderEntries) {
    return matchesApplicationRule(notification, configuredApps, senderEntries)
}

// DND has two complementary rule sets: allow-list while enabled, block-list while disabled.
function shouldSuppress(notification, doNotDisturb, allowedApps, blockedApps, senderEntries) {
    if (doNotDisturb === true) return !isAllowed(notification, allowedApps, senderEntries)
    return isAllowed(notification, blockedApps, senderEntries)
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

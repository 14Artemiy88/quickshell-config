.pragma library

function appLabel(entry) {
    var name = String(entry && (entry.appName || entry.desktopEntry) || "").trim()
    return name || "Приложение"
}

// Groups are ordered by the newest notification in each app; items inside a
// group remain newest-first. A flat model keeps ListView's section support cheap.
function groupedEntries(history) {
    var source = Array.isArray(history) ? history : []
    var groups = ({})
    var order = []
    for (var i = 0; i < source.length; ++i) {
        var entry = source[i]
        if (!entry) continue
        var label = appLabel(entry)
        var key = label.toLowerCase()
        if (!groups[key]) {
            groups[key] = { label: label, latest: Number(entry.receivedAt) || 0, entries: [] }
            order.push(key)
        }
        groups[key].entries.push(entry)
        groups[key].latest = Math.max(groups[key].latest, Number(entry.receivedAt) || 0)
    }
    order.sort(function(a, b) { return groups[b].latest - groups[a].latest })
    var result = []
    for (var g = 0; g < order.length; ++g) {
        var group = groups[order[g]]
        group.entries.sort(function(a, b) { return (Number(b.receivedAt) || 0) - (Number(a.receivedAt) || 0) })
        for (var j = 0; j < group.entries.length; ++j) {
            var item = Object.assign({}, group.entries[j])
            item.appGroup = group.label
            result.push(item)
        }
    }
    return result
}

function unreadCount(history) {
    var source = Array.isArray(history) ? history : []
    var count = 0
    for (var i = 0; i < source.length; ++i)
        if (source[i] && source[i].unread === true) count += 1
    return count
}

function markAllRead(history) {
    var source = Array.isArray(history) ? history : []
    return source.map(function(entry) {
        if (!entry || entry.unread !== true) return entry
        var copy = Object.assign({}, entry)
        copy.unread = false
        return copy
    })
}

// Removes one retained notification by its stable D-Bus notification ID.
// Only the first matching item is removed so a malformed duplicate cannot
// accidentally erase multiple history entries in a single user action.
function removeEntryById(history, entryId) {
    var source = Array.isArray(history) ? history : []
    var target = String(entryId === undefined || entryId === null ? "" : entryId)
    if (target === "") return source.slice()

    var result = []
    var removed = false
    for (var i = 0; i < source.length; ++i) {
        var entry = source[i]
        if (!removed && entry && String(entry.id) === target) {
            removed = true
            continue
        }
        result.push(entry)
    }
    return result
}

// Removes every notification in the visible app group. Group identity follows
// groupedEntries(): appName is preferred, desktopEntry is the fallback, and
// labels compare case-insensitively. The history array remains immutable.
function removeGroupByApp(history, groupLabel) {
    var source = Array.isArray(history) ? history : []
    var target = String(groupLabel === undefined || groupLabel === null ? "" : groupLabel).trim().toLowerCase()
    if (target === "") return source.slice()

    return source.filter(function(entry) {
        return !entry || appLabel(entry).toLowerCase() !== target
    })
}

// Age expiry and item-count retention are applied together. A zero-day
// retention disables age expiry but never disables the item-count bound.
function pruneEntries(history, now, retentionDays, limit) {
    var source = Array.isArray(history) ? history : []
    var days = Math.max(0, Math.min(365, Math.round(Number(retentionDays) || 0)))
    var maxItems = Math.max(1, Math.min(200, Math.round(Number(limit) || 30)))
    var cutoff = days > 0 ? (Number(now) || Date.now()) - days * 86400000 : 0
    var retained = source.filter(function(entry) {
        if (!entry) return false
        return days <= 0 || (Number(entry.receivedAt) || 0) >= cutoff
    })
    if (retained.length > maxItems) retained = retained.slice(retained.length - maxItems)
    return retained
}

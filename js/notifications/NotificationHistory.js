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

// Filters the already grouped history model without changing its order or
// appGroup labels, so ListView section headers and group-level actions keep
// working while the search is active. Every query token must occur somewhere
// across the sender, title or body fields.
function applicationNames(history) {
    var grouped = groupedEntries(history)
    var names = []
    var seen = Object.create(null)
    for (var i = 0; i < grouped.length; ++i) {
        var name = String(grouped[i] && grouped[i].appGroup || "").trim()
        var key = name.toLowerCase()
        if (name !== "" && !seen[key]) {
            seen[key] = true
            names.push(name)
        }
    }
    return names
}

// Expanded app groups are kept as a small case-insensitive list of labels.
// Groups absent from this list start collapsed, so newly appearing applications
// are compact by default. Returning new arrays keeps QML bindings deterministic.
function isGroupExpanded(expandedGroups, groupLabel) {
    var target = String(groupLabel === undefined || groupLabel === null ? "" : groupLabel).trim().toLowerCase()
    if (target === "") return false
    var source = Array.isArray(expandedGroups) ? expandedGroups : []
    for (var i = 0; i < source.length; ++i)
        if (String(source[i] === undefined || source[i] === null ? "" : source[i]).trim().toLowerCase() === target) return true
    return false
}

function toggleExpandedGroup(expandedGroups, groupLabel) {
    var target = String(groupLabel === undefined || groupLabel === null ? "" : groupLabel).trim()
    if (target === "") return Array.isArray(expandedGroups) ? expandedGroups.slice() : []
    var source = Array.isArray(expandedGroups) ? expandedGroups : []
    var result = []
    var found = false
    for (var i = 0; i < source.length; ++i) {
        var current = String(source[i] === undefined || source[i] === null ? "" : source[i]).trim()
        if (current.toLowerCase() === target.toLowerCase()) {
            found = true
            continue
        }
        if (current !== "") result.push(current)
    }
    if (!found) result.push(target)
    return result
}

function removeExpandedGroup(expandedGroups, groupLabel) {
    var target = String(groupLabel === undefined || groupLabel === null ? "" : groupLabel).trim().toLowerCase()
    var source = Array.isArray(expandedGroups) ? expandedGroups : []
    if (target === "") return source.slice()
    return source.filter(function(label) {
        return String(label === undefined || label === null ? "" : label).trim().toLowerCase() !== target
    })
}

// Text search and an optional multi-application filter are combined with AND
// semantics. The filter uses the same appGroup label as the visible sections.
function filterEntries(entries, query, selectedApps) {
    var source = Array.isArray(entries) ? entries : []
    var normalized = String(query === undefined || query === null ? "" : query).trim().toLowerCase()
    var tokens = normalized === "" ? [] : normalized.split(/\s+/).filter(function(token) { return token !== "" })
    var selected = []
    var appSource = Array.isArray(selectedApps) ? selectedApps : []
    for (var s = 0; s < appSource.length; ++s) {
        var appName = String(appSource[s] === undefined || appSource[s] === null ? "" : appSource[s]).trim().toLowerCase()
        if (appName !== "" && selected.indexOf(appName) === -1) selected.push(appName)
    }

    return source.filter(function(entry) {
        if (!entry) return false
        if (selected.length > 0) {
            var group = String(entry.appGroup || entry.appName || entry.desktopEntry || "Приложение").trim().toLowerCase()
            if (selected.indexOf(group) === -1) return false
        }
        if (tokens.length === 0) return true
        var searchable = [
            entry.appName, entry.appGroup, entry.desktopEntry, entry.summary, entry.body
        ].map(function(value) { return String(value || "").toLowerCase() }).join(" ")
        for (var i = 0; i < tokens.length; ++i)
            if (searchable.indexOf(tokens[i]) === -1) return false
        return true
    })
}

// Upsert a snapshot by stable notification ID. Notify(replacesId) can update
// an existing tracked object in place, so refreshed content must replace the old
// history snapshot instead of creating a duplicate entry.
function upsertEntry(history, entry, limit) {
    var source = Array.isArray(history) ? history : []
    if (!entry || String(entry.id === undefined || entry.id === null ? "" : entry.id) === "")
        return source.slice()
    var id = String(entry.id)
    var result = source.filter(function(current) {
        return !current || String(current.id) !== id
    })
    result.push(entry)
    var maxItems = Math.max(1, Math.min(200, Math.round(Number(limit) || 30)))
    if (result.length > maxItems) result = result.slice(result.length - maxItems)
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

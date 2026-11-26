.pragma library

function valuesOf(value) {
    if (Array.isArray(value)) return value
    // A single app ID/name is a scalar value, not a list of characters.
    // This matters when QML passes QString-backed values across JS helpers.
    if (typeof value === "string") return value.length > 0 ? [value] : []
    if (!value || typeof value.length !== "number" || !isFinite(value.length)) return []
    var result = []
    for (var i = 0; i < value.length; ++i) {
        if (value[i] !== undefined && value[i] !== null)
            result.push(value[i])
    }
    return result
}

// Normalize the two persisted DND rule lists. Older builds could accidentally
// serialize a single sender name one character at a time (for example
// `n;o;t;i;f;y;-;s;e;n;d`). Those fragments are not useful app identities and
// were rendered as a row per character. Drop contiguous runs of 4+ one-character
// tokens, while preserving ordinary full IDs/names and isolated short names.
function normalizeDndRuleIds(value) {
    var raw = typeof value === "string"
        ? value.split(/[;,\n]+/)
        : valuesOf(value)
    var tokens = []
    var seen = ({})
    for (var i = 0; i < raw.length; ++i) {
        var token = cleanText(raw[i], 512)
        if (!token) continue
        var key = normalized(token)
        if (seen[key] === true) continue
        seen[key] = true
        tokens.push(token)
    }

    var result = []
    var index = 0
    while (index < tokens.length) {
        if (tokens[index].length > 1) {
            result.push(tokens[index])
            index += 1
            continue
        }

        var end = index
        while (end < tokens.length && tokens[end].length <= 1) end += 1
        var runLength = end - index
        if (runLength < 4) {
            for (var keep = index; keep < end; ++keep)
                result.push(tokens[keep])
        }
        // A longer one-character run is legacy string-to-character corruption.
        index = end
    }
    return result
}

function cleanText(value, limit) {
    return String(value === undefined || value === null ? "" : value)
        .replace(/[\r\n\t]+/g, " ")
        .trim()
        .slice(0, limit || 512)
}

function normalized(value) {
    return cleanText(value, 512).toLowerCase()
}

function copyStrings(value, limit) {
    return valuesOf(value).map(function(item) {
        return cleanText(item, limit || 256)
    }).filter(function(item) { return item.length > 0 })
}

function desktopEntrySnapshot(id, entry, fallbackName) {
    if (!entry) return null
    var stableId = cleanText(id || entry.id, 512)
    if (!stableId) return null
    return {
        id: stableId,
        name: cleanText(entry.name || fallbackName || stableId, 256),
        genericName: cleanText(entry.genericName, 256),
        comment: cleanText(entry.comment, 512),
        keywords: copyStrings(entry.keywords, 256),
        categories: copyStrings(entry.categories, 128),
        execString: cleanText(entry.execString, 1024),
        startupClass: cleanText(entry.startupClass, 256),
        runInTerminal: entry.runInTerminal === true,
        icon: cleanText(entry.icon, 512),
        desktopEntry: stableId,
        appName: "",
        notificationSender: true
    }
}

function makeSenderEntry(notification, lookupDesktopEntry) {
    if (!notification) return null
    var desktopEntryId = cleanText(notification.desktopEntry, 512)
    var appName = cleanText(notification.appName, 256)
    if (!desktopEntryId && !appName) return null

    var desktopEntry = null
    if (desktopEntryId && typeof lookupDesktopEntry === "function") {
        try { desktopEntry = lookupDesktopEntry(desktopEntryId) } catch (error) { desktopEntry = null }
    }

    var resolved = desktopEntrySnapshot(desktopEntryId, desktopEntry, appName)
    if (!resolved) {
        var fallbackId = desktopEntryId || appName
        resolved = {
            id: fallbackId,
            name: appName || fallbackId,
            genericName: "",
            comment: "",
            keywords: [],
            categories: [],
            execString: "",
            startupClass: "",
            runInTerminal: false,
            icon: cleanText(notification.appIcon, 512),
            desktopEntry: desktopEntryId,
            appName: appName,
            notificationSender: true
        }
    } else {
        resolved.appName = appName
        resolved.icon = resolved.icon || cleanText(notification.appIcon, 512)
    }
    return resolved
}

function upsertSender(entries, notification, lookupDesktopEntry) {
    var source = valuesOf(entries).slice()
    var candidate = makeSenderEntry(notification, lookupDesktopEntry)
    if (!candidate) return source

    var desktopKey = normalized(candidate.desktopEntry)
    var nameKey = normalized(candidate.appName)
    var existingIndex = -1

    for (var i = 0; i < source.length; ++i) {
        var current = source[i]
        if (!current) continue
        var currentDesktop = normalized(current.desktopEntry || "")
        var currentName = normalized(current.appName || "")
        // Exact desktop-entry identity wins. App-name matching is only a
        // fallback for senders that omit the desktop-entry hint, or to promote
        // an earlier name-only record when its desktop ID becomes available.
        if ((desktopKey && currentDesktop === desktopKey)
                || (desktopKey && !currentDesktop && nameKey && currentName === nameKey)
                || (!desktopKey && nameKey && currentName === nameKey)) {
            existingIndex = i
            break
        }
    }

    if (existingIndex < 0) {
        source.push(candidate)
        return source
    }

    // Prefer the desktop-entry identity if it becomes available later, while
    // retaining appName as an alias so existing DND rules keep matching.
    var previous = source[existingIndex]
    var merged = Object.assign({}, previous, candidate)
    if (!candidate.desktopEntry && previous.desktopEntry)
        merged.desktopEntry = previous.desktopEntry
    if (!candidate.appName && previous.appName)
        merged.appName = previous.appName
    if (previous.appName && candidate.appName && normalized(previous.appName) === normalized(candidate.appName))
        merged.appName = previous.appName
    merged.id = merged.desktopEntry || merged.id || merged.appName
    source[existingIndex] = merged
    return source
}

function ruleIds(entry) {
    if (!entry) return []
    var raw = [entry.id, entry.desktopEntry, entry.appName]
    var result = []
    var seen = ({})
    for (var i = 0; i < raw.length; ++i) {
        var value = cleanText(raw[i], 512)
        var key = normalized(value)
        if (!value || seen[key] === true) continue
        seen[key] = true
        result.push(value)
    }
    return result
}

// Remove a sender by its canonical identity. App-name aliases may be shared by
// distinct desktop entries, so the canonical ID is safer than filtering by all
// aliases when updating the runtime catalog.
function removeSenderById(entries, senderId) {
    var wanted = normalized(senderId)
    if (!wanted) return valuesOf(entries).slice()
    return valuesOf(entries).filter(function(entry) {
        return !entry || normalized(entry.id) !== wanted
    })
}

// Return rule aliases that can be removed without changing a different sender
// that happens to share the same appName. Configured-only rows represent one
// persisted identity and therefore remove that identity directly.
function removableRuleIds(entry, remainingEntries) {
    var aliases = ruleIds(entry)
    if (!entry || entry.configuredOnly === true) return aliases

    var others = valuesOf(remainingEntries)
    return aliases.filter(function(alias) {
        var key = normalized(alias)
        for (var i = 0; i < others.length; ++i) {
            var other = others[i]
            if (!other || normalized(other.id) === normalized(entry.id)) continue
            var otherAliases = ruleIds(other)
            for (var j = 0; j < otherAliases.length; ++j) {
                if (normalized(otherAliases[j]) === key) return false
            }
        }
        return true
    })
}

function matchesAnyRule(entry, configuredIds) {
    var configured = valuesOf(configuredIds).map(normalized)
    var candidates = ruleIds(entry).map(normalized)
    for (var i = 0; i < candidates.length; ++i)
        if (configured.indexOf(candidates[i]) >= 0) return true
    return false
}

// Persisted DND rules remain manageable after a restart even though the
// observed-sender catalog itself is intentionally runtime-only.
function mergeConfiguredEntries(observedEntries, allowedIds, blockedIds) {
    var result = valuesOf(observedEntries).slice()
    var configured = normalizeDndRuleIds(allowedIds).concat(normalizeDndRuleIds(blockedIds))
    var seen = ({})
    for (var i = 0; i < result.length; ++i) {
        var aliases = ruleIds(result[i])
        for (var a = 0; a < aliases.length; ++a)
            seen[normalized(aliases[a])] = true
    }
    for (var j = 0; j < configured.length; ++j) {
        var id = cleanText(configured[j], 512)
        var key = normalized(id)
        if (!id || seen[key] === true) continue
        seen[key] = true
        result.push({
            id: id,
            name: id,
            genericName: "",
            comment: "Ранее настроенное правило",
            keywords: [],
            categories: [],
            execString: "",
            startupClass: "",
            runInTerminal: false,
            desktopEntry: "",
            appName: "",
            notificationSender: false,
            configuredOnly: true
        })
    }
    return result
}

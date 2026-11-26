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
        appNameAliases: [],
        desktopMetadataAvailable: true,
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
            appNameAliases: appName ? [appName] : [],
            desktopMetadataAvailable: false,
            notificationSender: true
        }
    } else {
        resolved.appName = appName
        resolved.appNameAliases = appName ? [appName] : []
        resolved.icon = resolved.icon || cleanText(notification.appIcon, 512)
    }
    return resolved
}

function appNameAliases(entry) {
    if (!entry) return []
    var raw = copyStrings(entry.appNameAliases, 256)
    if (entry.appName) raw.push(cleanText(entry.appName, 256))
    var result = []
    var seen = ({})
    for (var i = 0; i < raw.length; ++i) {
        var value = cleanText(raw[i], 256)
        var key = normalized(value)
        if (!value || seen[key] === true) continue
        seen[key] = true
        result.push(value)
    }
    return result
}

function canonicalRuleIds(entry) {
    if (!entry) return []
    var value = cleanText(entry.desktopEntry || entry.id || entry.appName, 512)
    return value ? [value] : []
}

function uniqueLegacyRuleIds(entry, peers) {
    var canonical = canonicalRuleIds(entry).map(normalized)
    var aliases = appNameAliases(entry)
    var source = valuesOf(peers)
    if (source.length === 0) source = [entry]
    var result = []
    for (var i = 0; i < aliases.length; ++i) {
        var alias = aliases[i]
        var key = normalized(alias)
        if (!key || canonical.indexOf(key) >= 0) continue
        var owners = []
        var canonicalCollision = false
        for (var j = 0; j < source.length; ++j) {
            var peer = source[j]
            if (!peer) continue
            var peerIds = canonicalRuleIds(peer)
            var ownerId = peerIds.length > 0 ? normalized(peerIds[0]) : ""
            var peerAliases = appNameAliases(peer)
            var owns = false
            for (var k = 0; k < peerAliases.length; ++k) {
                if (normalized(peerAliases[k]) === key) { owns = true; break }
            }
            if (owns && ownerId && owners.indexOf(ownerId) < 0) owners.push(ownerId)
        }
        var entryIds = canonicalRuleIds(entry)
        var entryId = entryIds.length > 0 ? normalized(entryIds[0]) : ""
        for (var collisionIndex = 0; collisionIndex < source.length; ++collisionIndex) {
            var collisionEntry = source[collisionIndex]
            if (!collisionEntry || normalized(canonicalRuleIds(collisionEntry)[0] || "") !== key) continue
            var collisionId = normalized(canonicalRuleIds(collisionEntry)[0] || "")
            if (collisionId && collisionId !== entryId) canonicalCollision = true
        }
        if (owners.length === 1 && owners[0] === entryId && !canonicalCollision)
            result.push(alias)
    }
    return result
}

function uniqueRuleIds(entry, peers) {
    return canonicalRuleIds(entry).concat(uniqueLegacyRuleIds(entry, peers))
}

function upsertSender(entries, notification, lookupDesktopEntry) {
    var source = valuesOf(entries).slice()
    var candidate = makeSenderEntry(notification, lookupDesktopEntry)
    if (!candidate) return source

    var desktopKey = normalized(candidate.desktopEntry)
    var nameKey = normalized(candidate.appName)
    var existingIndex = -1

    // A desktop ID is the strongest identity. Always update an exact match,
    // regardless of changes to the display/app name.
    if (desktopKey) {
        for (var i = 0; i < source.length; ++i) {
            var current = source[i]
            if (current && normalized(current.desktopEntry || "") === desktopKey) {
                existingIndex = i
                break
            }
        }

        // Promote an earlier name-only sender only when no desktop-backed
        // sender already uses that name. Otherwise the name is ambiguous and
        // the two identities must remain separate.
        if (existingIndex < 0 && nameKey) {
            var hasDesktopName = false
            var nameOnlyIndex = -1
            for (var j = 0; j < source.length; ++j) {
                var byName = source[j]
                if (!byName) continue
                var aliases = appNameAliases(byName)
                var sharesName = aliases.some(function(alias) { return normalized(alias) === nameKey })
                if (!sharesName) continue
                if (cleanText(byName.desktopEntry, 512)) hasDesktopName = true
                else if (nameOnlyIndex < 0) nameOnlyIndex = j
            }
            if (!hasDesktopName) existingIndex = nameOnlyIndex
        }
    } else if (nameKey) {
        // A name-only notification can be associated with one desktop-backed
        // sender when that appName maps to exactly one known identity. If the
        // name is shared by multiple desktop IDs, keep a separate name-only
        // record instead of arbitrarily assigning it to one of them.
        var desktopNameOwners = []
        var nameOnlyIndex = -1
        for (var k = 0; k < source.length; ++k) {
            var nameCandidate = source[k]
            if (!nameCandidate) continue
            var nameAliases = appNameAliases(nameCandidate)
            if (!nameAliases.some(function(alias) { return normalized(alias) === nameKey })) continue
            if (cleanText(nameCandidate.desktopEntry, 512)) {
                var ownerId = normalized(nameCandidate.desktopEntry)
                if (desktopNameOwners.indexOf(ownerId) < 0) desktopNameOwners.push(ownerId)
            } else if (nameOnlyIndex < 0) {
                nameOnlyIndex = k
            }
        }
        if (nameOnlyIndex >= 0) existingIndex = nameOnlyIndex
        else if (desktopNameOwners.length === 1) {
            for (var m = 0; m < source.length; ++m) {
                if (source[m] && normalized(source[m].desktopEntry || "") === desktopNameOwners[0]) {
                    existingIndex = m
                    break
                }
            }
        }
    }

    if (existingIndex < 0) {
        source.push(candidate)
        return source
    }

    // Keep historical appName values as aliases when an application changes
    // its notification name while retaining the same desktop-entry identity.
    var previous = source[existingIndex]
    var merged = Object.assign({}, previous, candidate)
    if (!candidate.desktopEntry && previous.desktopEntry) {
        // A name-only notification may refresh the appName alias for a unique
        // desktop-backed sender, but must not downgrade its canonical ID.
        merged.desktopEntry = previous.desktopEntry
        merged.id = previous.id || previous.desktopEntry
    }
    if (candidate.desktopMetadataAvailable !== true && previous.desktopMetadataAvailable === true) {
        // The fallback `name` is only the D-Bus appName, not desktop metadata.
        // Preserve the complete resolved desktop snapshot even when fallback
        // fields are non-empty; otherwise a name-only event could overwrite
        // the desktop name (e.g. "Mail A" -> "Mail") and lose its metadata.
        var metadataKeys = ["name", "genericName", "comment", "keywords", "categories", "execString", "startupClass", "runInTerminal", "icon"]
        for (var metadataIndex = 0; metadataIndex < metadataKeys.length; ++metadataIndex) {
            var metadataKey = metadataKeys[metadataIndex]
            merged[metadataKey] = previous[metadataKey]
        }
        merged.desktopMetadataAvailable = true
    }
    var combinedAliases = appNameAliases(previous).concat(appNameAliases(candidate))
    merged.appNameAliases = []
    var seenAliases = ({})
    for (var aliasIndex = 0; aliasIndex < combinedAliases.length; ++aliasIndex) {
        var aliasValue = cleanText(combinedAliases[aliasIndex], 256)
        var aliasKey = normalized(aliasValue)
        if (!aliasValue || seenAliases[aliasKey] === true) continue
        seenAliases[aliasKey] = true
        merged.appNameAliases.push(aliasValue)
    }
    if (!candidate.appName && previous.appName)
        merged.appName = previous.appName
    merged.id = merged.desktopEntry || merged.id || merged.appName
    source[existingIndex] = merged
    return source
}

function ruleIds(entry) {
    if (!entry) return []
    var raw = canonicalRuleIds(entry).concat(appNameAliases(entry))
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

function matchesAnyRule(entry, configuredIds, peers) {
    if (entry && !cleanText(entry.desktopEntry, 512)
            && isAmbiguousAppName(entry.appName, peers))
        return false
    var configured = valuesOf(configuredIds).map(normalized)
    var canonical = canonicalRuleIds(entry).map(normalized)
    for (var i = 0; i < canonical.length; ++i)
        if (configured.indexOf(canonical[i]) >= 0) return true

    var legacyAliases = uniqueLegacyRuleIds(entry, peers).map(normalized)
    for (var j = 0; j < legacyAliases.length; ++j)
        if (configured.indexOf(legacyAliases[j]) >= 0) return true
    return false
}

function legacyRuleIdsForDesktopEntry(desktopEntryId, entries) {
    var wanted = normalized(desktopEntryId)
    if (!wanted) return []
    var source = valuesOf(entries)
    for (var i = 0; i < source.length; ++i) {
        var entry = source[i]
        if (entry && normalized(entry.desktopEntry || "") === wanted)
            return uniqueLegacyRuleIds(entry, source)
    }
    return []
}

function legacyRuleIdsForAppName(appName, entries) {
    var wanted = normalized(appName)
    if (!wanted) return []
    var source = valuesOf(entries)
    var matching = []
    for (var i = 0; i < source.length; ++i) {
        var entry = source[i]
        if (!entry) continue
        var aliases = appNameAliases(entry)
        if (!aliases.some(function(alias) { return normalized(alias) === wanted })) continue
        var ids = canonicalRuleIds(entry)
        if (ids.length === 0) continue
        var owner = normalized(ids[0])
        if (!matching.some(function(item) { return normalized(canonicalRuleIds(item)[0]) === owner }))
            matching.push(entry)
    }
    if (matching.length !== 1) return []
    var result = uniqueLegacyRuleIds(matching[0], source)
    var desktopEntry = cleanText(matching[0].desktopEntry, 512)
    if (desktopEntry && result.map(normalized).indexOf(normalized(desktopEntry)) < 0) {
        var tokenCollision = source.some(function(peer) {
            if (!peer || normalized(peer.id) === normalized(matching[0].id)) return false
            return normalized(canonicalRuleIds(peer)[0] || "") === normalized(desktopEntry)
                || appNameAliases(peer).some(function(alias) { return normalized(alias) === normalized(desktopEntry) })
        })
        if (!tokenCollision) result.unshift(desktopEntry)
    }
    return result
}

function isUniqueAppNameForDesktopEntry(appName, desktopEntryId, entries) {
    var wantedName = normalized(appName)
    var wantedDesktop = normalized(desktopEntryId)
    if (!wantedName || !wantedDesktop) return false
    var owners = []
    var source = valuesOf(entries)
    for (var i = 0; i < source.length; ++i) {
        var entry = source[i]
        if (!entry) continue
        var aliases = appNameAliases(entry)
        var hasName = aliases.some(function(alias) { return normalized(alias) === wantedName })
        if (!hasName) continue
        var ids = canonicalRuleIds(entry)
        if (ids.length === 0) continue
        var owner = normalized(ids[0])
        if (owners.indexOf(owner) < 0) owners.push(owner)
    }
    if (owners.length !== 1 || owners[0] !== wantedDesktop) return false
    for (var collisionIndex = 0; collisionIndex < source.length; ++collisionIndex) {
        var collisionEntry = source[collisionIndex]
        if (!collisionEntry) continue
        var collisionId = normalized(canonicalRuleIds(collisionEntry)[0] || "")
        if (collisionId === wantedName && collisionId !== wantedDesktop) return false
    }
    return true
}

function isAmbiguousAppName(appName, entries) {
    var wantedName = normalized(appName)
    if (!wantedName) return false
    var owners = []
    var source = valuesOf(entries)
    for (var i = 0; i < source.length; ++i) {
        var entry = source[i]
        if (!entry) continue
        var aliases = appNameAliases(entry)
        if (!aliases.some(function(alias) { return normalized(alias) === wantedName })) continue
        var ids = canonicalRuleIds(entry)
        if (ids.length === 0) continue
        var owner = normalized(ids[0])
        if (owners.indexOf(owner) < 0) owners.push(owner)
    }
    return owners.length > 1
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
    // A name-only sender that became ambiguous is represented by its own
    // legacy token. Deleting that row must remove the token even though the
    // desktop-backed peers intentionally retain the same appName as an alias.
    // Conversely, deleting one desktop-backed peer must preserve that shared
    // token because it may still refer to another peer.
    if (!cleanText(entry.desktopEntry, 512)
            && isAmbiguousAppName(entry.appName || entry.id, others))
        return canonicalRuleIds(entry)

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

// Persisted DND rules remain manageable after a restart even though the
// observed-sender catalog itself is intentionally runtime-only.
function migrateUniqueLegacyRules(entries, configuredIds) {
    var source = valuesOf(entries)
    var result = normalizeDndRuleIds(configuredIds)
    for (var i = 0; i < source.length; ++i) {
        var entry = source[i]
        if (!entry || !cleanText(entry.desktopEntry, 512)) continue
        var canonical = cleanText(entry.desktopEntry, 512)
        var aliases = uniqueLegacyRuleIds(entry, source)
        for (var j = 0; j < aliases.length; ++j) {
            var alias = aliases[j]
            var index = -1
            for (var k = 0; k < result.length; ++k) {
                if (normalized(result[k]) === normalized(alias)) { index = k; break }
            }
            if (index < 0) continue
            result.splice(index, 1)
            var alreadyCanonical = result.some(function(value) { return normalized(value) === normalized(canonical) })
            if (!alreadyCanonical) result.push(canonical)
        }
    }
    return result
}

function mergeConfiguredEntries(observedEntries, allowedIds, blockedIds) {
    var result = valuesOf(observedEntries).slice()
    var configured = normalizeDndRuleIds(allowedIds).concat(normalizeDndRuleIds(blockedIds))
    var seen = ({})
    for (var i = 0; i < result.length; ++i) {
        var editableIds = uniqueRuleIds(result[i], result)
        for (var a = 0; a < editableIds.length; ++a)
            seen[normalized(editableIds[a])] = true
    }
    for (var j = 0; j < configured.length; ++j) {
        var id = cleanText(configured[j], 512)
        var key = normalized(id)
        if (!id || seen[key] === true) continue
        var ambiguousRule = isAmbiguousAppName(id, result)
        seen[key] = true
        result.push({
            id: id,
            name: id,
            genericName: "",
            comment: ambiguousRule
                ? "Неоднозначное имя отправителя: невозможно безопасно определить приложение"
                : "Ранее настроенное правило",
            keywords: [],
            categories: [],
            execString: "",
            startupClass: "",
            runInTerminal: false,
            desktopEntry: "",
            appName: "",
            notificationSender: false,
            configuredOnly: true,
            unusableRule: ambiguousRule
        })
    }
    return result
}


// Provide catalog-wide status counters independent of the current search,
// Show All switch, or row limit. Counts are identity-aware and include
// configured-only legacy rules separately from senders observed this session.
function summarizeSenders(observedEntries, allowedIds, blockedIds) {
    var observed = valuesOf(observedEntries).filter(function(entry) {
        return !!entry && entry.notificationSender !== false && entry.configuredOnly !== true
    })
    var allowed = normalizeDndRuleIds(allowedIds)
    var blocked = normalizeDndRuleIds(blockedIds)
    var allEntries = mergeConfiguredEntries(observed, allowed, blocked)
    var sendersWithRules = 0
    var allowedSenders = 0
    var blockedSenders = 0
    var configuredOnly = 0
    var unresolved = 0

    for (var i = 0; i < allEntries.length; ++i) {
        var entry = allEntries[i]
        if (!entry) continue
        var isAllowed = matchesAnyRule(entry, allowed, allEntries)
        var isBlocked = matchesAnyRule(entry, blocked, allEntries)
        if (entry.configuredOnly === true) {
            configuredOnly += 1
        } else {
            if (isAllowed) allowedSenders += 1
            if (isBlocked) blockedSenders += 1
            if (isAllowed || isBlocked) sendersWithRules += 1
        }
        if (entry.unusableRule === true
                || (!cleanText(entry.desktopEntry, 512)
                    && isAmbiguousAppName(entry.appName || entry.id, allEntries)))
            unresolved += 1
    }

    return {
        senderCount: observed.length,
        senderWithRulesCount: sendersWithRules,
        senderWithoutRulesCount: Math.max(0, observed.length - sendersWithRules),
        ignoreDndCount: allowedSenders,
        disabledOutsideDndCount: blockedSenders,
        savedOnlyCount: configuredOnly,
        unresolvedCount: unresolved,
        managedEntryCount: allEntries.length
    }
}

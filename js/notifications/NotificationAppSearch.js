.pragma library

.import "../launcher/LauncherAppSearch.js" as LauncherAppSearch
.import "NotificationAppCatalog.js" as NotificationAppCatalog

// DND's searchable catalog is populated only by actual NotificationServer
// senders, plus identities referenced by already-saved DND rules. Search and
// ranking still use the exact Launcher application-search primitive.
function buildRows(entries, allowedIds, blockedIds, query, limit, fuzzyEnabled, favoriteIds, showAll) {
    var allowed = NotificationAppCatalog.normalizeDndRuleIds(allowedIds).map(function(id) {
        return String(id === undefined || id === null ? "" : id).trim()
    })
    var blocked = NotificationAppCatalog.normalizeDndRuleIds(blockedIds).map(function(id) {
        return String(id === undefined || id === null ? "" : id).trim()
    })
    var favorites = LauncherAppSearch.valuesOf(favoriteIds).map(function(id) {
        return String(id === undefined || id === null ? "" : id).trim()
    })
    var source = NotificationAppCatalog.mergeConfiguredEntries(entries, allowed, blocked)
    var needle = String(query === undefined || query === null ? "" : query).trim()
    var rows = []

    var specialQuery = LauncherAppSearch.parseSpecialQuery(needle)
    if (specialQuery && specialQuery.code === "c" && specialQuery.query === "") {
        var categories = LauncherAppSearch.collectCategories(source, [])
        for (var categoryIndex = 0; categoryIndex < categories.length; ++categoryIndex) {
            var category = categories[categoryIndex]
            rows.push({
                kind: "category",
                category: category.name,
                id: "",
                name: category.label,
                comment: String(category.count) + " отправителей уведомлений · нажмите, чтобы открыть",
                count: category.count,
                allowed: false,
                blocked: false,
                ruleIds: [],
                score: 0
            })
        }
        return rows
    }

    if (needle.length === 0) {
        // Match Launcher empty-query behavior for DND: do not expose the whole
        // observed catalog until the user searches; only show configured rules.
        for (var i = 0; i < source.length; ++i) {
            var configuredEntry = source[i]
            if (!configuredEntry || !configuredEntry.id)
                continue

            var isAllowed = NotificationAppCatalog.matchesAnyRule(configuredEntry, allowed, source)
            var isBlocked = NotificationAppCatalog.matchesAnyRule(configuredEntry, blocked, source)
            var legacyAliases = NotificationAppCatalog.uniqueLegacyRuleIds(configuredEntry, source)
            var ambiguousName = NotificationAppCatalog.isAmbiguousAppName(configuredEntry.appName, source)
            var canonicalIds = NotificationAppCatalog.canonicalRuleIds(configuredEntry)
            var ambiguousSavedRule = ambiguousName && !configuredEntry.desktopEntry && canonicalIds.some(function(id) {
                var key = String(id).trim().toLowerCase()
                return allowed.some(function(value) { return String(value).trim().toLowerCase() === key })
                    || blocked.some(function(value) { return String(value).trim().toLowerCase() === key })
            })
            if (showAll !== true && !isAllowed && !isBlocked && !ambiguousSavedRule)
                continue

            rows.push({
                kind: "application",
                id: String(configuredEntry.id),
                name: String(configuredEntry.name || configuredEntry.id),
                comment: ambiguousName
                    ? (configuredEntry.desktopEntry
                        ? "Идентификатор: " + String(configuredEntry.desktopEntry)
                        : "Имя отправителя неоднозначно: desktopEntry не передан")
                    : String(configuredEntry.comment || configuredEntry.genericName || configuredEntry.id),
                allowed: isAllowed,
                blocked: isBlocked,
                ruleIds: NotificationAppCatalog.canonicalRuleIds(configuredEntry),
                legacyRuleIds: legacyAliases,
                ambiguousAppName: ambiguousName,
                unusableRule: configuredEntry.unusableRule === true
                    || (ambiguousName && !configuredEntry.desktopEntry),
                favoriteIndex: favorites.indexOf(String(configuredEntry.id)),
                score: 0
            })
        }

        rows.sort(function(a, b) {
            return a.name.localeCompare(b.name)
        })
        return rows
    }

    var matches = LauncherAppSearch.buildApplicationResults(
        source, needle, fuzzyEnabled, favorites, [], {}, [], limit
    )
    for (var matchIndex = 0; matchIndex < matches.length; ++matchIndex) {
        var match = matches[matchIndex]
        var entry = match.entry
        if (!entry || !entry.id)
            continue

        var id = String(entry.id).trim()
        if (!id)
            continue

        rows.push({
            kind: "application",
            id: id,
            name: String(entry.name || id),
            comment: NotificationAppCatalog.isAmbiguousAppName(entry.appName, source)
                ? (entry.desktopEntry
                    ? "Идентификатор: " + String(entry.desktopEntry)
                    : "Имя отправителя неоднозначно: desktopEntry не передан")
                : String(entry.comment || entry.genericName || entry.appName || id),
            allowed: NotificationAppCatalog.matchesAnyRule(entry, allowed, source),
            blocked: NotificationAppCatalog.matchesAnyRule(entry, blocked, source),
            ruleIds: NotificationAppCatalog.canonicalRuleIds(entry),
            legacyRuleIds: NotificationAppCatalog.uniqueLegacyRuleIds(entry, source),
            ambiguousAppName: NotificationAppCatalog.isAmbiguousAppName(entry.appName, source),
            unusableRule: NotificationAppCatalog.isAmbiguousAppName(entry.appName, source) && !entry.desktopEntry,
            favoriteIndex: favorites.indexOf(id),
            score: match.score
        })
    }

    var maxRows = Math.max(1, Number(limit) || 40)
    if (rows.length > maxRows)
        rows = rows.slice(0, maxRows)
    return rows
}

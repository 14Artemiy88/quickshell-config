import QtQuick
import "../../js/settings/SettingsSearch.js" as SettingsSearch
import "../../js/settings/SettingsPageRegistry.js" as SettingsPageRegistry

// Owns the global settings search index, matching, keyboard selection and
// navigation to visible controls. The parent widget remains the navigation
// host and supplies the search tree and visual highlight/input items.
Item {
    id: root
    visible: false

    property var host: null
    property var searchRoot: null
    property var searchInput: null
    property var settingsSearchIndex: []
    property var settingsSearchResults: []
    property string settingsSearchQuery: ""
    property string settingsSearchActiveMatchId: ""

    function settingsSearchPageInfo(item, inheritedPageId, inheritedPageRoot) {
        var pageId = inheritedPageId || ""
        var pageRoot = inheritedPageRoot || null
        var objectName = item && item.objectName !== undefined ? String(item.objectName) : ""
        var prefix = "settings-search-page:"
        if (objectName.indexOf(prefix) === 0) {
            pageId = objectName.slice(prefix.length)
            pageRoot = item
        }
        return { id: pageId, root: pageRoot }
    }

    function settingsSearchSiblingLabel(item) {
        if (!item || !item.parent || !item.parent.children)
            return ""
        var siblings = item.parent.children
        var itemIndex = -1
        for (var i = 0; i < siblings.length; ++i) {
            if (siblings[i] === item) { itemIndex = i; break }
        }
        if (itemIndex < 0)
            return ""
        for (var j = itemIndex - 1; j >= 0; --j) {
            var candidate = siblings[j]
            if (!candidate || candidate.text === undefined || candidate.font === undefined)
                continue
            var text = String(candidate.text || "").trim()
            if (text.length > 0 && candidate.visible !== false)
                return text
        }
        return ""
    }

    function settingsSearchAncestorRowLabel(item) {
        var current = item ? item.parent : null
        while (current) {
            if (current.settingsSearchRowLabel !== undefined) {
                var rowLabel = String(current.settingsSearchRowLabel || "").trim()
                if (rowLabel.length > 0)
                    return rowLabel
            }
            current = current.parent
        }
        return ""
    }

    function settingsSearchItemLabel(item) {
        if (!item)
            return ""
        if (item.settingsSearchLabel !== undefined && String(item.settingsSearchLabel).trim().length > 0)
            return String(item.settingsSearchLabel).trim()
        var preferSibling = item.settingsSearchUseSiblingLabel === true
        if (preferSibling) {
            var siblingLabel = root.settingsSearchSiblingLabel(item)
            if (siblingLabel.length > 0)
                return siblingLabel
        }
        if (item.label !== undefined && String(item.label).trim().length > 0)
            return String(item.label).trim()
        var rowLabel = root.settingsSearchAncestorRowLabel(item)
        if (rowLabel.length > 0)
            return rowLabel
        if (item.text !== undefined && String(item.text).trim().length > 0 && !preferSibling)
            return String(item.text).trim()
        var fallbackSibling = root.settingsSearchSiblingLabel(item)
        if (fallbackSibling.length > 0)
            return fallbackSibling
        if (item.placeholderText !== undefined && String(item.placeholderText).trim().length > 0)
            return String(item.placeholderText).trim()
        return ""
    }

    function settingsSearchGroupHeading(item, pageRoot) {
        var current = item ? item.parent : null
        while (current && current !== pageRoot) {
            if (current.heading !== undefined && String(current.heading).trim().length > 0)
                return String(current.heading).trim()
            if (current.renderedHeading !== undefined && String(current.renderedHeading).trim().length > 0)
                return String(current.renderedHeading).trim()
            current = current.parent
        }
        return ""
    }

    function settingsSearchSubTabIndex(item, pageRoot) {
        var current = item || null
        while (current && current !== pageRoot) {
            if (current.settingsSearchSubTabIndex !== undefined) {
                var index = Number(current.settingsSearchSubTabIndex)
                if (isFinite(index) && index >= 0)
                    return Math.floor(index)
            }
            current = current.parent
        }
        return -1
    }

    // Return a compact, user-facing route for a matched setting. All labels
    // come from the live page metadata and the current custom page label, so
    // breadcrumbs follow navigation reordering and renaming automatically.
    function settingsSearchBreadcrumb(entry) {
        if (!entry)
            return ""
        var candidates = [
            entry.navigationGroupLabel,
            entry.pageLabel,
            entry.subTabLabel,
            entry.group,
            entry.label
        ]
        var segments = []
        for (var i = 0; i < candidates.length; ++i) {
            var value = String(candidates[i] === undefined || candidates[i] === null ? "" : candidates[i]).trim()
            if (value.length === 0)
                continue
            if (segments.length > 0 && segments[segments.length - 1] === value)
                continue
            segments.push(value)
        }
        return segments.join(" › ")
    }

    function collectSettingsSearchItems(item, pageId, pageRoot, entries, ordinalByPage, idCounts) {
        if (!item)
            return
        var pageInfo = root.settingsSearchPageInfo(item, pageId, pageRoot)
        var activePageId = pageInfo.id
        var activePageRoot = pageInfo.root

        if (activePageId && activePageRoot && item.settingsSearchable === true) {
            var label = root.settingsSearchItemLabel(item)
            var targetKey = item.targetProperty !== undefined ? String(item.targetProperty || "") : ""
            var explicitId = item.settingsSearchId !== undefined ? String(item.settingsSearchId || "").trim() : ""
            if (label.length === 0)
                label = SettingsSearch.humanizeKey(targetKey || explicitId)
            if (label.length > 0) {
                var baseId = explicitId || targetKey || (activePageId + "/control-" + String(ordinalByPage[activePageId] || 0))
                ordinalByPage[activePageId] = Number(ordinalByPage[activePageId] || 0) + 1
                var occurrence = Number(idCounts[baseId] || 0)
                idCounts[baseId] = occurrence + 1
                var stableId = occurrence === 0 ? baseId : baseId + "#" + String(occurrence + 1)
                var group = root.settingsSearchGroupHeading(item, activePageRoot)
                var pageLabel = root.host ? root.host.settingsTabLabelForId(activePageId) : activePageId
                var pageMetadata = typeof SettingsPageRegistry.pageMetadataForId === "function"
                    ? (SettingsPageRegistry.pageMetadataForId(activePageId) || ({})) : ({})
                var navigationGroupLabel = pageMetadata.navigationGroupLabel
                    || SettingsPageRegistry.navigationGroupLabelForTabId(activePageId)
                var pageDescription = String(pageMetadata.description || "")
                var pageKeywords = Array.isArray(pageMetadata.keywords) ? pageMetadata.keywords.join(" ") : String(pageMetadata.keywords || "")
                var subTabIndex = root.settingsSearchSubTabIndex(item, activePageRoot)
                var subTabMetadata = pageMetadata.subTabs && subTabIndex >= 0
                    ? pageMetadata.subTabs[subTabIndex] : null
                var subTabLabel = subTabMetadata ? String(subTabMetadata.label || "") : ""
                var subTabKeywords = subTabMetadata && Array.isArray(subTabMetadata.keywords)
                    ? subTabMetadata.keywords.join(" ") : ""
                var controlKeywords = item.settingsSearchKeywords !== undefined ? String(item.settingsSearchKeywords || "") : ""
                var keywords = [controlKeywords, pageKeywords, subTabKeywords].filter(function(value) { return value.length > 0 }).join(" ")
                var keyTerms = SettingsSearch.keyTerms([label, group, navigationGroupLabel, activePageId, targetKey, explicitId, subTabLabel].join(" "))
                // Keep page descriptions as result context, not as a broad
                // per-control match source. Page/subtab keywords remain the
                // deliberate searchable metadata channels.
                var searchable = [label, group, navigationGroupLabel, pageLabel, activePageId, subTabLabel, targetKey, explicitId, keywords, keyTerms].join(" ")
                entries.push({
                    id: stableId,
                    label: label,
                    group: group,
                    navigationGroupLabel: navigationGroupLabel,
                    pageId: activePageId,
                    pageLabel: pageLabel,
                    pageDescription: pageDescription,
                    pageKeywords: pageKeywords,
                    subTabId: subTabMetadata ? subTabMetadata.id : "",
                    subTabLabel: subTabLabel,
                    subTabIndex: subTabIndex,
                    navigationPath: root.settingsSearchBreadcrumb({
                        navigationGroupLabel: navigationGroupLabel,
                        pageLabel: pageLabel,
                        subTabLabel: subTabLabel,
                        group: group,
                        label: label
                    }),
                    target: item,
                    pageRoot: activePageRoot,
                    targetKey: targetKey,
                    keywords: keywords,
                    keyTerms: [targetKey, explicitId, keyTerms, keywords].join(" "),
                    searchText: searchable
                })
            }
        }

        var children = item.children
        if (!children)
            return
        for (var childIndex = 0; childIndex < children.length; ++childIndex)
            root.collectSettingsSearchItems(children[childIndex], activePageId, activePageRoot, entries, ordinalByPage, idCounts)
    }

    function clearSettingsSearchHighlights(entries) {
        var source = entries || []
        for (var i = 0; i < source.length; ++i) {
            var entry = source[i]
            var current = entry ? entry.target : null
            while (current) {
                if (current.settingsSearchHighlighted !== undefined)
                    current.settingsSearchHighlighted = false
                if (current.settingsSearchCurrentMatch !== undefined)
                    current.settingsSearchCurrentMatch = false
                if (current.settingsSearchMatchHint !== undefined)
                    current.settingsSearchMatchHint = ""
                if (current === entry.pageRoot)
                    break
                current = current.parent
            }
        }
    }

    function applySettingsSearchHighlights() {
        root.clearSettingsSearchHighlights(root.settingsSearchIndex)
        var results = root.settingsSearchResults
        for (var i = 0; i < results.length; ++i) {
            var entry = results[i]
            var current = entry ? entry.target : null
            var explanation = SettingsSearch.explainMatch(entry, root.settingsSearchQuery)
            var breadcrumb = String(entry.navigationPath || root.settingsSearchBreadcrumb(entry))
            var ancestorHint = "• " + (breadcrumb || entry.label) + "\n  " + explanation
            while (current) {
                if (current.settingsSearchHighlighted !== undefined)
                    current.settingsSearchHighlighted = true
                if (current.settingsSearchCurrentMatch !== undefined)
                    current.settingsSearchCurrentMatch = current === entry.target
                        && String(entry.id || "") === root.settingsSearchActiveMatchId
                if (current.settingsSearchMatchHint !== undefined) {
                    if (current === entry.target) {
                        current.settingsSearchMatchHint = (breadcrumb.length > 0 ? "Путь: " + breadcrumb + "\n" : "")
                            + "Совпадение: " + explanation
                    } else {
                        var existing = String(current.settingsSearchMatchHint || "")
                        var header = "Найдено внутри:\n"
                        var body = existing.indexOf(header) === 0 ? existing.slice(header.length) : existing
                        var lines = body.length > 0 ? body.split("\n") : []
                        if (lines.indexOf(ancestorHint) < 0 && lines.length < 4)
                            lines.push(ancestorHint)
                        current.settingsSearchMatchHint = header + lines.join("\n")
                    }
                }
                if (current === entry.pageRoot)
                    break
                current = current.parent
            }
        }
    }

    function rebuildSettingsSearchIndex() {
        root.clearSettingsSearchHighlights(root.settingsSearchIndex)
        var entries = []
        var treeRoot = root.searchRoot || root.host
        if (treeRoot)
            root.collectSettingsSearchItems(treeRoot, "", null, entries, ({}), ({}))
        root.settingsSearchIndex = entries
        root.updateSettingsSearchResults(root.settingsSearchQuery)
    }

    function updateSettingsSearchResults(query) {
        root.settingsSearchQuery = String(query === undefined || query === null ? "" : query)
        root.settingsSearchActiveMatchId = ""
        root.settingsSearchResults = SettingsSearch.search(root.settingsSearchIndex, root.settingsSearchQuery, root.settingsSearchIndex.length)
        root.applySettingsSearchHighlights()
    }

    function scrollSettingsSearchEntryIntoView(entry) {
        var target = entry ? entry.target : null
        if (!target)
            return false

        var current = target.parent
        while (current) {
            if (current.contentItem !== undefined
                    && current.contentY !== undefined
                    && current.contentHeight !== undefined
                    && current.height !== undefined) {
                var point = target.mapToItem(current.contentItem, 0, 0)
                var itemHeight = Math.max(1, Number(target.height) || Number(target.implicitHeight) || 24)
                var viewportTop = Number(current.contentY) || 0
                var viewportHeight = Math.max(0, Number(current.height) || 0)
                var margin = Math.min(24, viewportHeight / 4)
                var nextContentY = viewportTop

                if (point.y < viewportTop + margin)
                    nextContentY = point.y - margin
                else if (point.y + itemHeight > viewportTop + viewportHeight - margin)
                    nextContentY = point.y + itemHeight - viewportHeight + margin

                var maxContentY = Math.max(0, Number(current.contentHeight) - viewportHeight)
                current.contentY = Math.max(0, Math.min(maxContentY, nextContentY))
                return true
            }
            current = current.parent
        }
        return false
    }

    function cycleSettingsSearchMatch(direction) {
        if (!root.host || root.settingsSearchQuery.trim().length === 0)
            return false

        var index = SettingsSearch.cycleIndex(
            root.settingsSearchResults,
            root.host.currentPageId,
            root.settingsSearchActiveMatchId,
            direction
        )
        if (index < 0 || index >= root.settingsSearchResults.length)
            return false

        var entry = root.settingsSearchResults[index]
        if (!entry || !entry.target)
            return false

        root.settingsSearchActiveMatchId = String(entry.id || "")
        if (entry.subTabIndex >= 0
                && root.host.currentPageSubTabIndex !== entry.subTabIndex) {
            root.host.currentPageSubTabIndex = entry.subTabIndex
        }

        root.applySettingsSearchHighlights()
        // Let the selected subtab and its content finish updating before mapping
        // the target into the nearest Flickable's content coordinate system.
        Qt.callLater(function() {
            Qt.callLater(function() {
                root.scrollSettingsSearchEntryIntoView(entry)
            })
        })
        return true
    }

    function settingsSearchCountMatches(predicate) {
        if (root.settingsSearchQuery.trim().length === 0)
            return 0
        var count = 0
        for (var i = 0; i < root.settingsSearchResults.length; ++i) {
            if (predicate(root.settingsSearchResults[i]))
                count += 1
        }
        return count
    }

    function settingsSearchPageMatchCount(pageId) {
        var page = String(pageId || "")
        if (!page)
            return 0
        return root.settingsSearchCountMatches(function(entry) { return entry.pageId === page })
    }

    function settingsSearchNavigationGroupMatchCount(groupId) {
        var group = String(groupId || "")
        if (!group)
            return 0
        return root.settingsSearchCountMatches(function(entry) {
            return SettingsPageRegistry.navigationGroupIdForTabId(entry.pageId) === group
        })
    }

    function settingsSearchSubTabMatchCount(pageId, subTabIndex) {
        var page = String(pageId || "")
        var index = Number(subTabIndex)
        if (!page || !isFinite(index))
            return 0
        return root.settingsSearchCountMatches(function(entry) {
            return entry.pageId === page && entry.subTabIndex === index
        })
    }

    function settingsSearchPageHasMatches(pageId) {
        return root.settingsSearchPageMatchCount(pageId) > 0
    }

    function settingsSearchNavigationGroupHasMatches(groupId) {
        return root.settingsSearchNavigationGroupMatchCount(groupId) > 0
    }

    function settingsSearchSubTabHasMatches(pageId, subTabIndex) {
        return root.settingsSearchSubTabMatchCount(pageId, subTabIndex) > 0
    }

    function settingsSearchMatchesHint(predicate) {
        if (root.settingsSearchQuery.trim().length === 0)
            return ""
        var matches = []
        for (var i = 0; i < root.settingsSearchResults.length; ++i) {
            var entry = root.settingsSearchResults[i]
            if (predicate(entry))
                matches.push(entry)
        }
        if (matches.length === 0)
            return ""
        var lines = ["Найдено параметров: " + String(matches.length)]
        var cap = Math.min(matches.length, 4)
        for (var j = 0; j < cap; ++j) {
            var match = matches[j]
            var breadcrumb = String(match.navigationPath || root.settingsSearchBreadcrumb(match))
            lines.push("• " + (breadcrumb || match.label) + "\n  "
                + SettingsSearch.explainMatch(match, root.settingsSearchQuery))
        }
        if (matches.length > cap)
            lines.push("…и ещё " + String(matches.length - cap))
        return lines.join("\n")
    }

    function settingsSearchPageMatchHint(pageId) {
        var page = String(pageId || "")
        return root.settingsSearchMatchesHint(function(entry) { return entry.pageId === page })
    }

    function settingsSearchNavigationGroupMatchHint(groupId) {
        var group = String(groupId || "")
        return root.settingsSearchMatchesHint(function(entry) {
            return SettingsPageRegistry.navigationGroupIdForTabId(entry.pageId) === group
        })
    }

    function settingsSearchSubTabMatchHint(pageId, subTabIndex) {
        var page = String(pageId || "")
        var index = Number(subTabIndex)
        return root.settingsSearchMatchesHint(function(entry) {
            return entry.pageId === page && entry.subTabIndex === index
        })
    }

    function openSettingsSearchResult(entry) {
        if (!entry || !entry.pageId || !root.host)
            return
        // Keyboard activation follows the navigation path only. The query stays
        // active so matching tabs, sections and controls remain outlined.
        root.host.expandSettingsNavigationGroupForPage(entry.pageId)
        root.host.currentPageId = entry.pageId
        var pageId = String(entry.pageId)
        var subTabIndex = Number(entry.subTabIndex)
        Qt.callLater(function() {
            if (root.host && root.host.currentPageId === pageId) {
                if (isFinite(subTabIndex) && subTabIndex >= 0)
                    root.host.currentPageSubTabIndex = subTabIndex
                // Keep the query and highlights, but move keyboard focus to the
                // selected page so subsequent Up/Down navigation stays in the sidebar.
                root.host.focusSettingsNavigationPage(pageId)
            }
        })
    }

    function handleSettingsSearchKey(event) {
        if (!event || !root.host)
            return
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.settingsSearchResults.length > 0)
                root.openSettingsSearchResult(root.settingsSearchResults[0])
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            root.settingsSearchQuery = ""
            root.settingsSearchActiveMatchId = ""
            root.settingsSearchResults = []
            root.applySettingsSearchHighlights()
            if (root.searchInput)
                root.searchInput.text = ""
            root.host.clearSettingsFocus()
            event.accepted = true
        }
    }
}

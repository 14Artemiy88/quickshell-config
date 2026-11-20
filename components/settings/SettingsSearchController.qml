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
    property var highlight: null
    property var highlightTimer: null

    property var settingsSearchIndex: []
    property var settingsSearchResults: []
    property string settingsSearchQuery: ""
    property int settingsSearchSelectedIndex: 0
    property int settingsSearchCandidateSubTab: 0

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
                var navigationGroupLabel = SettingsPageRegistry.navigationGroupLabelForTabId(activePageId)
                var keywords = item.settingsSearchKeywords !== undefined ? String(item.settingsSearchKeywords || "") : ""
                var keyTerms = SettingsSearch.keyTerms([label, group, navigationGroupLabel, activePageId, targetKey, explicitId].join(" "))
                var searchable = [label, group, navigationGroupLabel, pageLabel, activePageId, targetKey, explicitId, keywords, keyTerms].join(" ")
                entries.push({
                    id: stableId,
                    label: label,
                    group: group,
                    navigationGroupLabel: navigationGroupLabel,
                    pageId: activePageId,
                    pageLabel: pageLabel,
                    target: item,
                    pageRoot: activePageRoot,
                    targetKey: targetKey,
                    keyTerms: [targetKey, explicitId, keyTerms].join(" "),
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

    function rebuildSettingsSearchIndex() {
        var entries = []
        var treeRoot = root.searchRoot || root.host
        if (treeRoot)
            root.collectSettingsSearchItems(treeRoot, "", null, entries, ({}), ({}))
        root.settingsSearchIndex = entries
        root.updateSettingsSearchResults(root.settingsSearchQuery)
    }

    function updateSettingsSearchResults(query) {
        root.settingsSearchQuery = String(query === undefined || query === null ? "" : query)
        root.settingsSearchResults = SettingsSearch.search(root.settingsSearchIndex, root.settingsSearchQuery, 40)
        root.settingsSearchSelectedIndex = 0
    }

    function isSettingsSearchTargetVisible(entry) {
        if (!entry || !entry.target || !entry.pageRoot)
            return false
        var current = entry.target
        while (current) {
            if (current.visible === false)
                return false
            if (current === entry.target && (Number(current.width) <= 0 || Number(current.height) <= 0))
                return false
            if (current === entry.pageRoot)
                return true
            current = current.parent
        }
        return false
    }

    function openSettingsSearchResult(entry) {
        if (!entry || !entry.target || !root.host)
            return
        root.settingsSearchQuery = ""
        root.settingsSearchResults = []
        if (root.searchInput)
            root.searchInput.text = ""
        root.host.expandSettingsNavigationGroupForPage(entry.pageId)
        if (entry.pageId === "modules" || entry.pageId === "themes") {
            root.host.currentPageId = entry.pageId
            Qt.callLater(function() { root.finishSettingsSearchNavigation(entry) })
            return
        }
        if (!SettingsPageRegistry.hasOtherPageId(entry.pageId))
            return
        root.host.currentPageId = entry.pageId
        Qt.callLater(function() {
            root.settingsSearchCandidateSubTab = 0
            root.trySettingsSearchSubTab(entry)
        })
    }

    function trySettingsSearchSubTab(entry) {
        if (!entry || !entry.target || !root.host)
            return
        var count = root.host.currentPageSubTabs.length
        if (root.settingsSearchCandidateSubTab >= count) {
            root.host.currentPageSubTabIndex = 0
            Qt.callLater(function() { root.finishSettingsSearchNavigation(entry) })
            return
        }
        root.host.currentPageSubTabIndex = root.settingsSearchCandidateSubTab
        Qt.callLater(function() {
            if (root.isSettingsSearchTargetVisible(entry)) {
                root.finishSettingsSearchNavigation(entry)
                return
            }
            root.settingsSearchCandidateSubTab += 1
            root.trySettingsSearchSubTab(entry)
        })
    }

    function findSettingsSearchFlickable(target) {
        var current = target ? target.parent : null
        while (current && current !== root.host) {
            if (current.contentY !== undefined && current.contentHeight !== undefined && current.contentItem)
                return current
            current = current.parent
        }
        return null
    }

    function finishSettingsSearchNavigation(entry) {
        if (!entry || !entry.target || !root.isSettingsSearchTargetVisible(entry))
            return
        var flickable = root.findSettingsSearchFlickable(entry.target)
        if (flickable) {
            var localPosition = entry.target.mapToItem(flickable.contentItem, 0, 0)
            var wantedY = Math.max(0, localPosition.y - 42)
            var maximumY = Math.max(0, flickable.contentHeight - flickable.height)
            flickable.contentY = Math.min(maximumY, wantedY)
        }
        Qt.callLater(function() { root.showSettingsSearchHighlight(entry.target) })
    }

    function showSettingsSearchHighlight(target) {
        if (!target || target.visible === false || target.width <= 0 || target.height <= 0
                || !root.host || !root.highlight)
            return
        var position = target.mapToItem(root.host, 0, 0)
        root.highlight.x = Math.max(0, position.x - 3)
        root.highlight.y = Math.max(0, position.y - 3)
        root.highlight.width = Math.min(root.host.width, target.width + 6)
        root.highlight.height = target.height + 6
        root.highlight.visible = true
        if (root.highlightTimer)
            root.highlightTimer.restart()
    }

    function handleSettingsSearchKey(event) {
        if (!event || !root.host)
            return
        if (event.key === Qt.Key_Down) {
            if (root.settingsSearchResults.length > 0)
                root.settingsSearchSelectedIndex = Math.min(root.settingsSearchResults.length - 1, root.settingsSearchSelectedIndex + 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            if (root.settingsSearchResults.length > 0)
                root.settingsSearchSelectedIndex = Math.max(0, root.settingsSearchSelectedIndex - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.settingsSearchResults.length > 0)
                root.openSettingsSearchResult(root.settingsSearchResults[root.settingsSearchSelectedIndex])
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            root.settingsSearchQuery = ""
            root.settingsSearchResults = []
            if (root.searchInput)
                root.searchInput.text = ""
            root.host.clearSettingsFocus()
            event.accepted = true
        }
    }
}

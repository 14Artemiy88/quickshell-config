.pragma library

// A multi-page navigation group is a collapsible folder, not a selected page.
// Only singleton groups (for example Dashboard or General) can show the
// selected-page treatment on their header.
function groupContainsCurrentPage(group, currentPageId) {
    if (!group || !Array.isArray(group.items))
        return false
    var target = String(currentPageId || "")
    if (!target)
        return false
    for (var i = 0; i < group.items.length; ++i) {
        if (String(group.items[i].id || "") === target)
            return true
    }
    return false
}

function isStandalonePageSelected(group, currentPageId) {
    return !!group && Array.isArray(group.items) && group.items.length === 1
        && String(group.items[0].id || "") === String(currentPageId || "")
}

function shouldShowCollapsedPageHint(group, collapsed, currentPageId) {
    return collapsed === true && groupContainsCurrentPage(group, currentPageId)
}

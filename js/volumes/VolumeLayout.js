.pragma library

// Keep the minimum-height preference for a visible stream list only. When the
// streams are collapsed (or there are no streams), the widget hugs its main
// control instead of reserving blank space for an invisible list.
function adaptiveHeight(streamsExpanded, streamCount, mainContentHeight, gapHeight, listContentHeight, minHeight, maxHeight) {
    var showStreamList = streamsExpanded === true && Number(streamCount) > 0
    var mainHeight = Math.max(0, Math.ceil(Number(mainContentHeight) || 0))
    var listHeight = showStreamList
        ? Math.max(0, Math.ceil(Number(gapHeight) || 0)) + Math.max(0, Math.ceil(Number(listContentHeight) || 0))
        : 0
    var desiredHeight = mainHeight + listHeight
    var minimumHeight = showStreamList ? Math.max(0, Math.ceil(Number(minHeight) || 0)) : 0
    var maximumHeight = Math.max(0, Math.ceil(Number(maxHeight) || 0))
    return Math.min(maximumHeight, Math.max(minimumHeight, desiredHeight))
}

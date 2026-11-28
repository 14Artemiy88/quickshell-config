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

// Responsive values are derived from the saved preferences. They never write
// back to Config, so switching the host width cannot mutate user settings.
function presentationScale(mode) {
    if (mode === "compact") return 0.9
    if (mode === "wide") return 1.12
    return 1.0
}

function verticalPadding(mode, configured) {
    var value = Math.max(0, Math.ceil(Number(configured) || 0))
    return mode === "compact" ? Math.max(0, Math.round(value * 0.75)) : value
}

function mainTrackWidth(mode, widgetWidth, padding, iconWidth, configuredTrackWidth) {
    var available = Math.max(1, Math.floor((Number(widgetWidth) || 0) - 2 * Math.max(0, Number(padding) || 0) - Math.max(0, Number(iconWidth) || 0)))
    var configured = Math.max(1, Math.round(Number(configuredTrackWidth) || 1))
    // Begin wide growth at the breakpoint itself without a sudden jump.
    var width = Math.max(0, Number(widgetWidth) || 0)
    var desired = mode === "wide"
        ? configured + Math.round(Math.max(0, width - 420) * 0.35)
        : configured
    return Math.max(1, Math.min(available, desired))
}

function trackHeight(mode, configured) {
    var value = Math.max(1, Math.round(Number(configured) || 1))
    if (mode === "compact") return Math.max(4, Math.round(value * 0.9))
    if (mode === "wide") return Math.max(value, Math.round(value * 1.15))
    return value
}

function streamRowHeight(mode, configuredRowHeight, configuredTrackHeight) {
    var base = Math.max(0, Math.ceil(Number(configuredRowHeight) || 0), Math.ceil(Number(configuredTrackHeight) || 0))
    if (mode === "compact") return Math.max(18, Math.round(base * 0.95))
    if (mode === "wide") return Math.max(base, Math.round(base * 1.08))
    return base
}

function streamListSpacing(mode) {
    if (mode === "compact") return 5
    if (mode === "wide") return 9
    return 7
}

function streamLabelSpacing(mode, configured) {
    var value = Math.max(0, Math.round(Number(configured) || 0))
    if (mode === "compact") return Math.max(0, Math.round(value * 0.9))
    if (mode === "wide") return Math.round(value * 1.12)
    return value
}


.pragma library

function albumHeaderDisplayIndex(queueItems, trackIndex) {
    var track = Number(trackIndex)
    if (!Array.isArray(queueItems) || !isFinite(track) || Math.floor(track) !== track || track < 0)
        return -1
    for (var i = 0; i < queueItems.length; ++i) {
        var item = queueItems[i]
        if (!item || item.kind !== "album") continue
        var start = Number(item.startIndex)
        var end = Number(item.endIndex)
        if (isFinite(start) && isFinite(end) && track >= start && track <= end)
            return i
    }
    return -1
}

// Map a final destination index (after removing the dragged item) to the
// correct visual boundary in the original queue. When source and destination
// remain inside the same album segment, insert after its header; when entering
// a different segment, insert before the target segment's header so the header
// remains attached to its first track.
function insertionAnchorDisplayIndex(queueItems, trackDisplayIndices, trackIndex, sourceTrackIndex) {
    var track = Number(trackIndex)
    if (!Array.isArray(trackDisplayIndices) || !isFinite(track) || Math.floor(track) !== track
            || track < 0 || track >= trackDisplayIndices.length)
        return -1

    var trackDisplay = Number(trackDisplayIndices[track])
    if (!isFinite(trackDisplay) || trackDisplay < 0)
        return -1

    var targetHeader = albumHeaderDisplayIndex(queueItems, track)
    var source = Number(sourceTrackIndex)
    var sourceHeader = isFinite(source) && Math.floor(source) === source && source >= 0
        ? albumHeaderDisplayIndex(queueItems, source) : -1

    if (targetHeader >= 0 && targetHeader === sourceHeader)
        return trackDisplay

    if (targetHeader >= 0) {
        var header = queueItems[targetHeader]
        if (Number(header.startIndex) === track)
            return targetHeader
    }
    return trackDisplay
}

function gapCenterBefore(nextTop, spacing) {
    var top = Number(nextTop)
    var gap = Number(spacing)
    if (!isFinite(top)) return 0
    if (!isFinite(gap) || gap < 0) gap = 0
    return top - gap / 2
}

function gapCenterBetween(previousBottom, nextTop) {
    var previous = Number(previousBottom)
    var next = Number(nextTop)
    if (!isFinite(previous) || !isFinite(next)) return 0
    return (previous + next) / 2
}

function gapCenterAfter(previousBottom, spacing) {
    var bottom = Number(previousBottom)
    var gap = Number(spacing)
    if (!isFinite(bottom)) return 0
    if (!isFinite(gap) || gap < 0) gap = 0
    return bottom + gap / 2
}

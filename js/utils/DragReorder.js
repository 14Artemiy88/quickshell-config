.pragma library

function validIndex(value, count) {
    var index = Number(value)
    return isFinite(index) && Math.floor(index) === index && index >= 0 && index < count
}

// Convert a drop on the upper/lower half of a row into the final index after
// removing the dragged item. This keeps forward and backward moves symmetric.
function destinationIndex(sourceIndex, targetIndex, afterTarget, count) {
    var source = Number(sourceIndex)
    var target = Number(targetIndex)
    var length = Number(count)
    if (!isFinite(length) || Math.floor(length) !== length || length < 1
            || !validIndex(source, length) || !validIndex(target, length) || source === target)
        return source

    var insertion = target + (afterTarget ? 1 : 0)
    if (source < insertion)
        insertion -= 1
    return Math.max(0, Math.min(length - 1, insertion))
}

function move(items, fromIndex, toIndex) {
    var result = Array.isArray(items) ? items.slice(0) : []
    var from = Number(fromIndex)
    var to = Number(toIndex)
    if (!validIndex(from, result.length) || !validIndex(to, result.length) || from === to)
        return result
    var item = result.splice(from, 1)[0]
    result.splice(to, 0, item)
    return result
}

// Map a final destination index (after removing the dragged item) to its
// canonical visual insertion boundary in the original list. For the no-op
// destination this is the gap immediately after the source row; the UI also
// treats the gap immediately before it as an alias and highlights the whole
// source row for both, avoiding a jump between equivalent no-op positions.
function insertionSlotAnchor(sourceIndex, destinationIndex, count) {
    var source = Number(sourceIndex)
    var destination = Number(destinationIndex)
    var length = Number(count)
    if (!isFinite(length) || Math.floor(length) !== length || length < 1
            || !validIndex(source, length) || !validIndex(destination, length))
        return { index: -1, afterLast: false }

    if (destination < source)
        return { index: destination, afterLast: false }
    if (destination + 1 < length)
        return { index: destination + 1, afterLast: false }
    return { index: length - 1, afterLast: true }
}

// The two physical gaps adjacent to the dragged row (before and after it)
// both leave the item at its original index. Keep that no-op identity explicit
// so the UI can highlight the whole source row instead of switching markers.
function sourceAdjacentNoopDestination(sourceIndex, count, edge) {
    var source = Number(sourceIndex)
    var length = Number(count)
    if (!validIndex(source, length) || (edge !== "before" && edge !== "after"))
        return -1
    return source
}

// Pick the nearest insertion gap. Equal-distance ties always resolve to the
// earlier slot, so a pointer coordinate has one deterministic result.
// Position the marker in the measured gap between two delegates. For the
// first/last destination, use half of the actual positioner spacing before or
// after the edge row. This keeps the marker outside every row rectangle.
function insertionGapCenter(previousBottom, nextTop, spacing, edge) {
    var previous = Number(previousBottom)
    var next = Number(nextTop)
    var gap = Number(spacing)
    if (!isFinite(gap) || gap < 0)
        gap = 0

    if (edge === "before" && isFinite(next))
        return next - gap / 2
    if (edge === "after" && isFinite(previous))
        return previous + gap / 2
    if (isFinite(previous) && isFinite(next))
        return (previous + next) / 2
    if (isFinite(next))
        return next - gap / 2
    if (isFinite(previous))
        return previous + gap / 2
    return 0
}

function pointerInsideSourceRow(sourceTop, sourceHeight, pointerY, padding) {
    var top = Number(sourceTop)
    var height = Number(sourceHeight)
    var y = Number(pointerY)
    var inset = Number(padding)
    if (!isFinite(top) || !isFinite(height) || height < 0 || !isFinite(y)
            || !isFinite(inset) || inset < 0)
        return false
    return y >= top - inset && y <= top + height + inset
}

function nearestInsertionSlot(slotPositions, pointerY) {
    if (!(slotPositions instanceof Array) || slotPositions.length === 0)
        return -1
    var y = Number(pointerY)
    if (!isFinite(y))
        return -1
    var bestIndex = -1
    var bestDistance = Number.POSITIVE_INFINITY
    for (var i = 0; i < slotPositions.length; ++i) {
        var slotY = Number(slotPositions[i])
        if (!isFinite(slotY))
            continue
        var distance = Math.abs(y - slotY)
        // Strict comparison makes equal-distance ties deterministic.
        if (distance < bestDistance) {
            bestDistance = distance
            bestIndex = i
        }
    }
    return bestIndex
}

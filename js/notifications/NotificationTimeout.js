.pragma library

// Return the fraction of an auto-dismiss timeout that remains.
// Persistent notifications (timeout <= 0) intentionally have no countdown.
function remainingFraction(elapsed, timeout) {
    var total = Number(timeout)
    var used = Number(elapsed)
    if (!isFinite(total) || total <= 0 || !isFinite(used)) return 0
    return Math.max(0, Math.min(1, 1 - Math.max(0, used) / total))
}

// Measure actual wall-clock time between visible countdown ticks. Qt Quick timers
// can be delayed by a busy event loop, so adding the configured interval would
// make the bar drift and visibly jump. A non-positive/invalid delta is ignored.
function elapsedDelta(previousTick, currentTick) {
    var previous = Number(previousTick)
    var current = Number(currentTick)
    if (!isFinite(previous) || !isFinite(current) || previous <= 0 || current < previous)
        return 0
    return current - previous
}

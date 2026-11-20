.pragma library

// Normalize untrusted JSON samples before they reach SegmentBarGraph. The
// daemon contract is a fixed history length of integer percentages; a malformed
// whole sample is rejected, while bad individual values become safe zeroes.
function normalizeHistory(values, expectedCount) {
    if (!Array.isArray(values) || !Number.isInteger(expectedCount) || expectedCount < 1)
        return null
    if (values.length !== expectedCount)
        return null

    var normalized = []
    for (var i = 0; i < values.length; i++) {
        var value = values[i]
        if (typeof value !== "number" || !isFinite(value))
            value = 0
        normalized.push(Math.max(0, Math.min(100, value)))
    }
    return normalized
}


// Build one seamless scrolling frame from two consecutive rolling histories.
// The outgoing sample stays at the left edge while the newest sample enters
// from the right; after moving one slot, dropping the first item yields the
// daemon's next 51-sample history without changing any measured values.
function buildFlowFrame(previous, next) {
    if (!Array.isArray(previous) || !Array.isArray(next) ||
        previous.length < 1 || previous.length !== next.length)
        return null

    for (var i = 0; i < previous.length - 1; i++) {
        if (previous[i + 1] !== next[i])
            return null
    }

    return previous.concat([next[next.length - 1]])
}

function settleFlowFrame(frame) {
    if (!Array.isArray(frame) || frame.length < 2)
        return null
    return frame.slice(1)
}


// Smooth small daemon-cadence jitter so the graph does not subtly speed up
// and slow down from one sample to the next. Large changes are accepted
// immediately (for example when the user changes the sampling interval).
function smoothSampleInterval(previousInterval, measuredInterval) {
    var previous = Number(previousInterval)
    var measured = Number(measuredInterval)
    if (!isFinite(previous) || previous <= 0)
        previous = 1000
    if (!isFinite(measured) || measured <= 0)
        return previous

    if (Math.abs(measured - previous) > 150)
        return measured

    return Math.round(previous * 0.75 + measured * 0.25)
}


// Match one-slot scrolling to the measured interval between daemon samples.
// Keep a tiny headroom so the next sample can start the following movement
// before a visible idle frame appears. The daemon normally samples about once
// per second, but its read/JSON delivery overhead can make that interval drift.
function resolveFlowDuration(sampleInterval) {
    var interval = Number(sampleInterval)
    if (!isFinite(interval) || interval <= 0)
        interval = 1000

    return Math.max(750, Math.min(1500, Math.round(interval - 8)))
}

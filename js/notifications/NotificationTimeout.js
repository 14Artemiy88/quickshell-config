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

// Return points along a rounded rectangular perimeter, starting at the top-left
// tangent and proceeding clockwise. This lets the notification countdown draw a
// true border progress without depending on Canvas dashed-line support.
function roundedPerimeterPoints(width, height, radius, fraction, inset, direction) {
    var w = Math.max(0, Number(width) || 0)
    var h = Math.max(0, Number(height) || 0)
    var pad = Math.max(0, Number(inset) || 0)
    var left = Math.min(w / 2, pad)
    var top = Math.min(h / 2, pad)
    var right = Math.max(left, w - pad)
    var bottom = Math.max(top, h - pad)
    var r = Math.max(0, Math.min(Number(radius) || 0, (right - left) / 2, (bottom - top) / 2))
    var segments = []
    var total = 0

    function addLine(x1, y1, x2, y2) {
        var length = Math.hypot(x2 - x1, y2 - y1)
        segments.push({ type: "line", x1: x1, y1: y1, x2: x2, y2: y2, length: length })
        total += length
    }
    function addArc(cx, cy, start, end) {
        var length = Math.abs(end - start) * r
        segments.push({ type: "arc", cx: cx, cy: cy, start: start, end: end, length: length })
        total += length
    }

    // Both directions begin at the same top-left tangent so switching the
    // setting changes only the traversal direction, not the visual anchor.
    if (String(direction || "clockwise") === "counterclockwise") {
        addArc(left + r, top + r, -Math.PI / 2, -Math.PI)
        addLine(left, top + r, left, bottom - r)
        addArc(left + r, bottom - r, Math.PI, Math.PI / 2)
        addLine(left + r, bottom, right - r, bottom)
        addArc(right - r, bottom - r, Math.PI / 2, 0)
        addLine(right, bottom - r, right, top + r)
        addArc(right - r, top + r, 0, -Math.PI / 2)
        addLine(right - r, top, left + r, top)
    } else {
        addLine(left + r, top, right - r, top)
        addArc(right - r, top + r, -Math.PI / 2, 0)
        addLine(right, top + r, right, bottom - r)
        addArc(right - r, bottom - r, 0, Math.PI / 2)
        addLine(right - r, bottom, left + r, bottom)
        addArc(left + r, bottom - r, Math.PI / 2, Math.PI)
        addLine(left, bottom - r, left, top + r)
        addArc(left + r, top + r, Math.PI, Math.PI * 1.5)
    }

    if (total <= 0) return []
    var progress = Number(fraction)
    if (!isFinite(progress)) progress = 0
    var remaining = total * Math.max(0, Math.min(1, progress))
    var points = [{ x: left + r, y: top }]

    for (var i = 0; i < segments.length && remaining > 0.000001; ++i) {
        var segment = segments[i]
        if (segment.length <= 0) continue
        var used = Math.min(remaining, segment.length)
        var ratio = used / segment.length
        if (segment.type === "line") {
            points.push({
                x: segment.x1 + (segment.x2 - segment.x1) * ratio,
                y: segment.y1 + (segment.y2 - segment.y1) * ratio
            })
        } else {
            var angleSpan = (segment.end - segment.start) * ratio
            var steps = Math.max(1, Math.ceil(Math.abs(angleSpan) * 12))
            for (var step = 1; step <= steps; ++step) {
                var angle = segment.start + angleSpan * step / steps
                points.push({
                    x: segment.cx + Math.cos(angle) * r,
                    y: segment.cy + Math.sin(angle) * r
                })
            }
        }
        remaining -= used
    }

    if (progress >= 1 && points.length > 1)
        points.push({ x: points[0].x, y: points[0].y })
    return points
}

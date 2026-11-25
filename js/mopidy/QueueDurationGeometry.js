.pragma library

function normalizedOffset(alignment, value) {
    var numeric = Number(value)
    if (!isFinite(numeric)) numeric = 0
    numeric = Math.round(numeric)
    // In left mode X is an inset from the panel's left edge. Negative values
    // were previously needed only because the slot was anchored to the right.
    // Treat those legacy values as zero after switching to the real left anchor.
    return alignment === "left" ? Math.max(0, numeric) : numeric
}

function slotX(alignment, offset, rightEdge, slotWidth) {
    var safeWidth = Number(slotWidth)
    if (!isFinite(safeWidth) || safeWidth < 0) safeWidth = 0
    var safeRightEdge = Number(rightEdge)
    if (!isFinite(safeRightEdge)) safeRightEdge = 0
    var safeOffset = normalizedOffset(alignment, offset)
    if (alignment === "left") return safeOffset
    return safeRightEdge - safeWidth + safeOffset
}

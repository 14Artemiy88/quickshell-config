.pragma library

// Move a linear launcher selection and wrap at both ends. An unset selection
// starts at the first item, matching the launcher's previous initial behavior.
function moveLinearIndex(currentIndex, direction, count) {
    var total = Math.max(0, Math.floor(Number(count) || 0))
    if (total <= 0)
        return -1

    var current = Math.floor(Number(currentIndex))
    if (!isFinite(current) || current < 0 || current >= total)
        return 0

    var step = Number(direction) > 0 ? 1 : (Number(direction) < 0 ? -1 : 0)
    if (step === 0)
        return current
    return (current + step + total) % total
}

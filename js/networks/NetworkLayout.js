.pragma library

function naturalHeight(itemCount, rowHeight, rowSpacing, verticalPadding, emptyStateHeight) {
    const count = Math.max(0, Math.floor(Number(itemCount) || 0))
    const row = Math.max(1, Math.round(Number(rowHeight) || 32))
    const spacing = Math.max(0, Math.round(Number(rowSpacing) || 0))
    const padding = Math.max(0, Math.round(Number(verticalPadding) || 0))
    const emptyHeight = Math.max(1, Math.round(Number(emptyStateHeight) || row))

    if (count === 0)
        return padding * 2 + emptyHeight

    return padding * 2 + count * row + Math.max(0, count - 1) * spacing
}

function panelHeight(itemCount, maximumHeight, rowHeight, rowSpacing, verticalPadding, emptyStateHeight) {
    const natural = naturalHeight(itemCount, rowHeight, rowSpacing, verticalPadding, emptyStateHeight)
    const requestedMaximum = Number(maximumHeight)
    const maximum = Math.max(48, Math.round(Number.isFinite(requestedMaximum) && requestedMaximum > 0 ? requestedMaximum : 171))
    return Math.min(maximum, natural)
}

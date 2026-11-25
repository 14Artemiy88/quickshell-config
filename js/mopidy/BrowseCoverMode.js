function normalizeMode(value) {
    var mode = String(value || "selected")
    return ["off", "selected", "all-visible"].indexOf(mode) >= 0 ? mode : "selected"
}

function shouldLoad(mode, entryType, inViewport, selected) {
    var normalized = normalizeMode(mode)
    if (entryType !== "directory" || normalized === "off") return false
    if (normalized === "all-visible") return !!inViewport
    return !!selected
}

function shouldDisplay(mode, entryType, inViewport, hovered, keepSelectedVisible, hasCover) {
    var normalized = normalizeMode(mode)
    if (entryType !== "directory" || normalized === "off" || !hasCover) return false
    if (normalized === "all-visible") return !!inViewport
    return !!hovered || !!keepSelectedVisible
}

.pragma library

// Shared responsive presentation contract for built-in module surfaces.
// Widths are logical QML pixels, before the global UI scale is applied.
var MODES = ["compact", "regular", "wide"]

function normalizeMode(value, fallback) {
    var mode = String(value === undefined || value === null ? "" : value).trim().toLowerCase()
    if (MODES.indexOf(mode) >= 0)
        return mode
    return fallback || "regular"
}

function resolveMode(width, override, compactBreakpoint, wideBreakpoint) {
    var requested = String(override === undefined || override === null ? "auto" : override).trim().toLowerCase()
    if (requested !== "" && requested !== "auto")
        return normalizeMode(requested, "regular")

    var logicalWidth = Number(width)
    // During initial construction the host may briefly have no geometry yet.
    // Keep the stable regular layout until a meaningful width is available.
    if (!isFinite(logicalWidth) || logicalWidth <= 0)
        return "regular"

    var compactAt = Number(compactBreakpoint)
    if (!isFinite(compactAt) || compactAt <= 0)
        compactAt = 260

    var wideAt = Number(wideBreakpoint)
    if (!isFinite(wideAt) || wideAt <= compactAt)
        wideAt = Math.max(compactAt + 1, 420)

    if (logicalWidth <= compactAt)
        return "compact"
    if (logicalWidth >= wideAt)
        return "wide"
    return "regular"
}

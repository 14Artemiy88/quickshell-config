.pragma library

var VISIBILITY_STYLES = ["auto", "none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]

function normalizeVisibilityStyle(value) {
    var style = String(value === undefined || value === null ? "" : value)
    return VISIBILITY_STYLES.indexOf(style) >= 0 ? style : "auto"
}

// Auto follows the edge nearest to the Dashboard's configured resting position.
// A right-aligned Dashboard therefore preserves the historical right-side slide,
// while a Dashboard moved to the left edge enters from the left.
function resolveVisibilityStyle(value, targetX, drawerWidth, screenWidth) {
    var style = normalizeVisibilityStyle(value)
    if (style !== "auto") return style

    var x = Number(targetX)
    var width = Number(drawerWidth)
    var availableWidth = Number(screenWidth)
    if (!isFinite(x)) x = 0
    if (!isFinite(width) || width < 0) width = 0
    if (!isFinite(availableWidth) || availableWidth <= 0) availableWidth = width

    var leftDistance = Math.max(0, x)
    var rightDistance = Math.max(0, availableWidth - x - width)
    return leftDistance <= rightDistance ? "slideLeft" : "slideRight"
}

function hiddenX(styleValue, targetX, drawerWidth, screenWidth, margin) {
    var style = normalizeVisibilityStyle(styleValue)
    var x = Number(targetX)
    var width = Number(drawerWidth)
    var availableWidth = Number(screenWidth)
    var inset = Number(margin)
    if (!isFinite(x)) x = 0
    if (!isFinite(width) || width < 0) width = 0
    if (!isFinite(availableWidth) || availableWidth < 0) availableWidth = 0
    if (!isFinite(inset) || inset < 0) inset = 16
    if (style === "slideLeft") return -width - inset
    if (style === "slideRight") return availableWidth + inset
    return x
}

function hiddenY(styleValue, targetY, drawerHeight, screenHeight, margin) {
    var style = normalizeVisibilityStyle(styleValue)
    var y = Number(targetY)
    var height = Number(drawerHeight)
    var availableHeight = Number(screenHeight)
    var inset = Number(margin)
    if (!isFinite(y)) y = 0
    if (!isFinite(height) || height < 0) height = 0
    if (!isFinite(availableHeight) || availableHeight < 0) availableHeight = 0
    if (!isFinite(inset) || inset < 0) inset = 16
    if (style === "slideUp") return -height - inset
    if (style === "slideDown") return availableHeight + inset
    return y
}


// A visibility transition must not start while a freshly shown PanelWindow
// still reports a transient 1x1 or partially resolved size. Waiting for both
// the host and drawer to have valid geometry prevents the first frame from
// animating a narrow sliver across the screen before the full panel appears.
function geometryReady(windowWidth, windowHeight, drawerWidth, drawerHeight, screenWidth, screenHeight) {
    var ww = Number(windowWidth)
    var wh = Number(windowHeight)
    var dw = Number(drawerWidth)
    var dh = Number(drawerHeight)
    var sw = Number(screenWidth)
    var sh = Number(screenHeight)
    return isFinite(ww) && isFinite(wh) && isFinite(dw) && isFinite(dh)
        && isFinite(sw) && isFinite(sh)
        && ww > 1 && wh > 1 && dw > 1 && dh > 1 && sw > 1 && sh > 1
        && dw <= ww && dh <= wh
        // A panel can be re-targeted to another monitor while hidden. Do not
        // animate until the compositor has applied that screen's dimensions.
        && Math.abs(ww - sw) <= 1 && Math.abs(wh - sh) <= 1
}

function normalizeDuration(value) {
    var duration = Number(value)
    if (!isFinite(duration)) duration = 300
    return Math.max(0, Math.min(5000, Math.round(duration)))
}

function usesFade(styleValue) {
    var style = normalizeVisibilityStyle(styleValue)
    return style === "fade" || style === "none"
}

function transitionDuration(styleValue, durationValue) {
    return normalizeVisibilityStyle(styleValue) === "none" ? 0 : normalizeDuration(durationValue)
}

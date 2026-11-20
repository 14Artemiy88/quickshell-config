.pragma library

function motionOffsetX(style, width) {
    var extent = Math.max(0, Number(width) || 0)
    if (style === "slideLeft") return -extent
    if (style === "slideRight") return extent
    return 0
}

function motionOffsetY(style, height) {
    var extent = Math.max(0, Number(height) || 0)
    if (style === "slideUp") return -extent
    if (style === "slideDown") return extent
    return 0
}

function effectiveStyle(profile, style) {
    var profileName = String(profile || "standard").trim().toLowerCase()
    if (profileName === "none") return "none"

    var selected = String(style || "fade").trim()
    var normalized = selected.toLowerCase()
    var styles = {
        none: "none",
        fade: "fade",
        slideleft: "slideLeft",
        slideright: "slideRight",
        slideup: "slideUp",
        slidedown: "slideDown"
    }
    return styles[normalized] || "fade"
}

function normalizedProgress(progress) {
    var value = Number(progress)
    if (!isFinite(value)) return 1
    return Math.max(0, Math.min(1, value))
}

// One normalized progress value drives the whole card transition. Slide styles
// never alter opacity; only the fade style changes alpha. This prevents a
// fallback opacity animation from masking a selected directional slide.
function opacityForProgress(style, phase, progress) {
    if (style !== "fade") return 1
    var value = normalizedProgress(progress)
    return phase === "enter" ? value : 1 - value
}

function motionOffsetXForProgress(style, width, phase, progress) {
    var offset = motionOffsetX(style, width)
    var value = normalizedProgress(progress)
    return phase === "enter" ? offset * (1 - value) : offset * value
}

function motionOffsetYForProgress(style, height, phase, progress) {
    var offset = motionOffsetY(style, height)
    var value = normalizedProgress(progress)
    return phase === "enter" ? offset * (1 - value) : offset * value
}

function visibilityDuration(style, duration) {
    var ms = Number(duration)
    if (style === "none" || !isFinite(ms) || ms <= 0) return 0
    return Math.max(0, Math.round(ms))
}

function shouldAnimate(style, duration) {
    var ms = Number(duration)
    return style !== "none" && isFinite(ms) && ms > 0
}

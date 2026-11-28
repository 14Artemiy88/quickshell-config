.pragma library

function fontScale(mode) {
    if (mode === "compact") return 0.92
    if (mode === "wide") return 1.04
    return 1
}

function fontSize(mode, configuredSize) {
    var base = Math.max(1, Number(configuredSize) || 1)
    return Math.max(8, Math.round(base * fontScale(mode)))
}

function trackRowHeight(mode, configuredHeight) {
    var base = Math.max(1, Number(configuredHeight) || 1)
    if (mode === "compact") return Math.max(27, Math.round(base * 0.9))
    if (mode === "wide") return Math.round(base * 1.05)
    return Math.round(base)
}

function albumHeaderHeight(mode, configuredFontSize) {
    var base = Math.max(26, (Number(configuredFontSize) || 1) + 9)
    if (mode === "compact") return Math.max(24, Math.round(base * 0.92))
    if (mode === "wide") return Math.round(base * 1.04)
    return Math.round(base)
}

function queueSpacing(mode) {
    if (mode === "compact") return 1
    if (mode === "wide") return 3
    return 2
}

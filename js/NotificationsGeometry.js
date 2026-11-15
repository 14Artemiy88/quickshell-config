.pragma library

var AUTO_COORDINATE = -999999
var DEFAULT_GAP = 16
var DEFAULT_HEIGHT = 180

function resolvedCoordinate(geometry, index, screenWidth, cardWidth, gap) {
    var values = Array.isArray(geometry) ? geometry : []
    var value = Number(values[index])
    if (isFinite(value) && value >= -10000)
        return Math.round(value)

    if (index === 0) {
        var width = isFinite(Number(screenWidth)) ? Number(screenWidth) : 1920
        var card = Math.max(1, isFinite(Number(cardWidth)) ? Number(cardWidth) : 380)
        var rightGap = Math.max(0, isFinite(Number(gap)) ? Number(gap) : DEFAULT_GAP)
        return Math.max(0, Math.round(width - card - rightGap))
    }
    if (index === 1)
        return DEFAULT_GAP
    return 0
}

function migrateLegacyPlacement(position, offsetX, offsetY, screenWidth, screenHeight, cardWidth, popupHeight) {
    var anchor = String(position || "top-right")
    if (["top-right", "top-left", "bottom-right", "bottom-left"].indexOf(anchor) < 0)
        anchor = "top-right"

    var xOffset = Math.max(0, Math.min(500, Math.round(Number(offsetX) || 0)))
    var yOffset = Math.max(0, Math.min(500, Math.round(Number(offsetY) || 0)))
    var width = Math.max(1, Number(cardWidth) || 380)
    var height = Math.max(52, Number(popupHeight) || DEFAULT_HEIGHT)
    var sw = Math.max(1, Number(screenWidth) || 1920)
    var sh = Math.max(1, Number(screenHeight) || 1080)

    var x = anchor.endsWith("-left") ? xOffset : Math.max(0, Math.round(sw - width - xOffset))
    var y = anchor.indexOf("bottom-") === 0 ? Math.max(0, Math.round(sh - height - yOffset)) : yOffset
    return [x, y, width, 0]
}

function resolvedTopCoordinate(anchor, verticalOffset, screenHeight, panelHeight) {
    var offset = isFinite(Number(verticalOffset)) ? Math.round(Number(verticalOffset)) : DEFAULT_GAP
    if (String(anchor || "top") !== "bottom")
        return offset
    var height = Math.max(0, isFinite(Number(panelHeight)) ? Number(panelHeight) : 0)
    var screen = Math.max(1, isFinite(Number(screenHeight)) ? Number(screenHeight) : 1080)
    return Math.round(screen - offset - height)
}

function storedVerticalOffset(anchor, topCoordinate, screenHeight, panelHeight) {
    var top = isFinite(Number(topCoordinate)) ? Number(topCoordinate) : DEFAULT_GAP
    if (String(anchor || "top") !== "bottom")
        return Math.round(top)
    var height = Math.max(0, isFinite(Number(panelHeight)) ? Number(panelHeight) : 0)
    var screen = Math.max(1, isFinite(Number(screenHeight)) ? Number(screenHeight) : 1080)
    return Math.round(screen - top - height)
}

function convertVerticalOffset(verticalOffset, screenHeight, panelHeight) {
    var offset = isFinite(Number(verticalOffset)) ? Number(verticalOffset) : DEFAULT_GAP
    var height = Math.max(0, isFinite(Number(panelHeight)) ? Number(panelHeight) : 0)
    var screen = Math.max(1, isFinite(Number(screenHeight)) ? Number(screenHeight) : 1080)
    return Math.round(screen - offset - height)
}

function normalizeGeometry(value, cardWidth) {
    var source = Array.isArray(value) ? value : []
    var x = Number(source[0])
    var y = Number(source[1])
    if (!isFinite(x)) x = AUTO_COORDINATE
    if (!isFinite(y)) y = DEFAULT_GAP
    var width = Math.max(1, Number(cardWidth) || Number(source[2]) || 380)
    var height = Number(source[3])
    if (!isFinite(height) || height < 0) height = 0
    return [Math.round(x), Math.round(y), Math.round(width), Math.round(Math.min(10000, height))]
}

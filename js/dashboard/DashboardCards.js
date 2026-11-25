.pragma library

var DEFAULT_IDS = ["today", "system", "network", "weather", "media"]
var COLUMN_MODES = ["auto", "one", "two"]
var CARD_SIZE_MODES = ["compact", "expanded"]
// Two-column layouts keep each card at least 230 px wide. Preserve the
// established 470 px activation threshold while tightening the visible gutter.
var COLUMN_GAP = 6
var MIN_CARD_COLUMN_WIDTH = 230
var MIN_TWO_COLUMN_WIDTH = MIN_CARD_COLUMN_WIDTH * 2 + 10
var AUTO_TWO_COLUMN_WIDTH = 500
// The Dashboard drawer keeps its established compact maximum width in every
// card configuration. The horizontal three-card Bento adapts to the available
// card area instead of widening the panel to reach an artificial breakpoint.
var DRAWER_SCREEN_INSET = 32
var DEFAULT_DRAWER_MAX_WIDTH = 560
// Horizontal Bento starts once a two-column card area is available; the
// existing auto/two-column thresholds guarantee readable peer-card widths.
var THREE_CARD_HORIZONTAL_WIDTH = AUTO_TWO_COLUMN_WIDTH
// Two-column cards remain readable at the minimum width by using a slightly
// denser type scale below this threshold; full-width cards retain the base scale.
var NARROW_CARD_WIDTH = 270

// Shared card geometry keeps Dashboard cards visually related while
// allowing their content blocks to retain card-specific typography.
var CARD_PADDING = 12
// Wide leads use more of their horizontal canvas: tighter edge insets and
// group spacing keep useful content from looking stranded in the centre.
var WIDE_LEAD_CARD_PADDING = 8
var CARD_SECTION_GAP = 4
// One shared, compact gutter separates logical content groups in every wide lead.
var WIDE_LEAD_GROUP_GAP = 14
var CARD_HEADER_GAP = 9
var CARD_BODY_GAP = 5
var CARD_BADGE_SIZE = 24
var CARD_FOOTER_HEIGHT = 19
// Shared semantic type sizes keep supporting labels and secondary values
// consistent across the module-specific expanded card layouts.
var CARD_MICRO_LABEL_SIZE = 8
var CARD_MICRO_LABEL_NARROW_SIZE = 7
var CARD_METRIC_VALUE_SIZE = 16
var CARD_METRIC_VALUE_NARROW_SIZE = 14
var CARD_DETAIL_TEXT_SIZE = 10
var CARD_DETAIL_TEXT_NARROW_SIZE = 9
var CARD_FOOTER_TEXT_SIZE = 9
var CARD_FOOTER_TEXT_NARROW_SIZE = 8
var CARD_HOVER_DURATION = 140
// Keep pointer hover discoverable but visually secondary to keyboard focus.
// Focus remains the strongest state so two simultaneous interaction modes
// are never mistaken for two selected cards.
var CARD_HOVER_SURFACE_ALPHA = 0.075
var CARD_FOCUS_SURFACE_ALPHA = 0.15
var CARD_HOVER_BORDER_ALPHA = 0.48
var CARD_FOCUS_BORDER_WIDTH = 2
var DEFAULT_CARD_SIZES = {
    today: "compact",
    system: "compact",
    network: "compact",
    weather: "compact",
    media: "compact"
}

// Cards that use the same size mode share one silhouette regardless of module.
// This keeps compact cards visually aligned with each other, and expanded cards
// equally prominent; the internal content remains module-specific.
var COMPACT_CARD_HEIGHTS = { today: 164, system: 164, network: 164, weather: 164, media: 164 }
// Expanded cards reserve more vertical room for the growing detail blocks while keeping one shared silhouette.
var EXPANDED_CARD_HEIGHTS = { today: 208, system: 208, network: 208, weather: 208, media: 208 }

// Player backends expose the remaining track time as a negative clock string.
// Accept only MM:SS or H:MM:SS values with real minute/second ranges so
// malformed metadata cannot appear as a plausible countdown in Dashboard.
function normalizeRemainingTime(value) {
    if (value === undefined || value === null) return ""

    var raw = String(value).trim()
    if (raw.charAt(0) === "-") raw = raw.slice(1)
    if (raw === "") return ""

    var parts = raw.split(":")
    if (parts.length !== 2 && parts.length !== 3) return ""
    if (!/^\d{1,3}$/.test(parts[0])) return ""

    var seconds = parts[parts.length - 1]
    if (!/^\d{2}$/.test(seconds) || Number(seconds) >= 60) return ""

    if (parts.length === 3) {
        if (!/^\d{2}$/.test(parts[1]) || Number(parts[1]) >= 60) return ""
    }

    return parts.join(":")
}

// Gismeteo wind speed is expected to be a non-negative decimal value in m/s.
// Do not surface malformed API strings (NaN, Infinity, negative values, or
// arbitrary text) as if they were a real measurement in Dashboard.
function normalizeWeatherWindSpeed(value) {
    if (value === undefined || value === null) return ""

    var raw = String(value).trim()
    if (raw === "" || !/^(?:\d+(?:[.,]\d+)?|[.,]\d+)$/.test(raw)) return ""

    var numeric = Number(raw.replace(",", "."))
    if (!isFinite(numeric) || numeric < 0) return ""

    return raw
}

// Gismeteo atmospheric pressure is expected as a positive decimal in mmHg.
// Accept plain decimal numbers (including comma decimals), but reject coercible
// values such as booleans, arrays, exponent notation and malformed strings.
function normalizeWeatherPressure(value) {
    if (typeof value !== "number" && typeof value !== "string") return ""

    var raw = String(value).trim()
    if (raw === "" || !/^(?:\d+(?:[.,]\d+)?|[.,]\d+)$/.test(raw)) return ""

    var numeric = Number(raw.replace(",", "."))
    if (!isFinite(numeric) || numeric <= 0) return ""

    return raw
}

// Gismeteo air and comfort temperatures are Celsius measurements. Accept
// signed plain decimals (including comma decimals), but reject malformed
// strings and coercible non-numeric values instead of displaying them as data.
function normalizeWeatherTemperature(value) {
    if (typeof value !== "number" && typeof value !== "string") return ""

    var raw = String(value).trim()
    if (raw === "" || !/^[+-]?(?:\d+(?:[.,]\d+)?|[.,]\d+)$/.test(raw)) return ""

    var numeric = Number(raw.replace(",", "."))
    if (!isFinite(numeric)) return ""

    return raw
}

// Gismeteo forecast dates use Unix timestamps in whole seconds. Validate the
// raw value before Date conversion: Number() alone would coerce booleans,
// arrays, exponent-form strings, and Infinity-like values into misleading dates.
// The upper bound is the largest timestamp representable by JavaScript Date.
function normalizeWeatherUnixTimestamp(value) {
    if (typeof value !== "number" && typeof value !== "string") return NaN

    var raw = String(value).trim()
    if (raw === "" || !/^\d+$/.test(raw)) return NaN

    var timestamp = Number(raw)
    if (!isFinite(timestamp) || Math.floor(timestamp) !== timestamp
            || timestamp <= 0 || timestamp > 8640000000000) return NaN

    return timestamp
}

// Gismeteo's eight-point compass scale is an integer from 0 (calm) through
// 8 (north-west). Accept numeric values and plain decimal integer strings,
// but reject coercible non-numbers such as booleans, arrays, hex and exponent
// notation so malformed payloads cannot masquerade as a valid direction.
function normalizeWeatherWindScale(value) {
    if (typeof value !== "number" && typeof value !== "string") return -1
    if (typeof value === "string" && !/^\d+$/.test(value.trim())) return -1

    var scale = Number(value)
    return isFinite(scale) && Math.floor(scale) === scale && scale >= 0 && scale <= 8
            ? scale : -1
}

// Gismeteo icon codes become local PNG filenames. Keep the value to one safe
// filename token so malformed API data cannot inject path separators or
// traversal segments into a shell-local image path.
function normalizeWeatherIconCode(value) {
    if (typeof value !== "string" && typeof value !== "number") return ""
    if (typeof value === "number"
            && (!isFinite(value) || Math.floor(value) !== value || value < 0)) return ""

    var code = String(value).trim()
    if (code === "" || code.length > 32 || !/^[A-Za-z0-9][A-Za-z0-9_-]*$/.test(code))
        return ""

    return code
}

function normalizeCardSizeMode(value) {
    var mode = String(value === undefined || value === null ? "" : value)
    return CARD_SIZE_MODES.indexOf(mode) >= 0 ? mode : "compact"
}

function normalizeCardSizes(values) {
    var source = values && typeof values === "object" && !Array.isArray(values) ? values : ({})
    var result = {}
    for (var i = 0; i < DEFAULT_IDS.length; ++i) {
        var id = DEFAULT_IDS[i]
        result[id] = normalizeCardSizeMode(source[id])
    }
    return result
}

function setCardSize(values, id, mode) {
    var key = String(id || "")
    var result = normalizeCardSizes(values)
    if (DEFAULT_IDS.indexOf(key) < 0) return result
    result[key] = normalizeCardSizeMode(mode)
    return result
}

function cardSizeMode(values, id) {
    var key = String(id || "")
    if (DEFAULT_IDS.indexOf(key) < 0) return "compact"
    return normalizeCardSizes(values)[key]
}

function cardSizeModeIndex(values, id) {
    return CARD_SIZE_MODES.indexOf(cardSizeMode(values, id))
}

function cardHeight(id, sizes) {
    var key = String(id || "")
    if (DEFAULT_IDS.indexOf(key) < 0) return 126
    var heights = cardSizeMode(sizes, key) === "expanded"
        ? EXPANDED_CARD_HEIGHTS : COMPACT_CARD_HEIGHTS
    return heights[key]
}


// Split cards into two vertical stacks. Keeping each stack independent avoids
// GridLayout's row-height coupling: a tall card in one column no longer leaves
// a blank strip below a shorter neighbour. The best partition minimizes the
// total-height difference; ties prefer the natural alternating order.
function balancedColumns(cards, sizes, spacing) {
    var source = Array.isArray(cards) ? cards.slice() : []
    if (source.length <= 1) return { left: source, right: [] }

    var gap = Number(spacing)
    if (!isFinite(gap) || gap < 0) gap = 0

    var best = null
    var bestDifference = Infinity
    var bestAlternationPenalty = Infinity
    var bestCountDifference = Infinity
    var limit = 1 << source.length

    // Pin the first card to the left to avoid evaluating mirrored partitions.
    for (var mask = 1; mask < limit - 1; ++mask) {
        if ((mask & 1) === 0) continue

        var left = []
        var right = []
        var leftHeight = 0
        var rightHeight = 0
        var alternationPenalty = 0

        for (var i = 0; i < source.length; ++i) {
            var goesLeft = (mask & (1 << i)) !== 0
            var item = source[i]
            var height = cardHeight(item && item.id, sizes)

            if (goesLeft) {
                left.push(item)
                leftHeight += height
                if (i % 2 !== 0) alternationPenalty++
            } else {
                right.push(item)
                rightHeight += height
                if (i % 2 === 0) alternationPenalty++
            }
        }

        leftHeight += Math.max(0, left.length - 1) * gap
        rightHeight += Math.max(0, right.length - 1) * gap

        var difference = Math.abs(leftHeight - rightHeight)
        var countDifference = Math.abs(left.length - right.length)

        if (difference < bestDifference
                || (difference === bestDifference && alternationPenalty < bestAlternationPenalty)
                || (difference === bestDifference && alternationPenalty === bestAlternationPenalty
                    && countDifference < bestCountDifference)) {
            best = { left: left, right: right }
            bestDifference = difference
            bestAlternationPenalty = alternationPenalty
            bestCountDifference = countDifference
        }
    }

    return best || { left: source.slice(0, 1), right: source.slice(1) }
}

// Wide two-column windows use a horizontal Bento composition: the first
// configured card occupies the top row, with the remaining cards balanced below.
function threeCardOrientation(width) {
    var availableWidth = Number(width)
    if (!isFinite(availableWidth) || availableWidth < THREE_CARD_HORIZONTAL_WIDTH)
        return "vertical"
    return "horizontal"
}

function threeCardHorizontalRowHeight(cards, sizes) {
    var source = Array.isArray(cards) ? cards : []
    if (source.length === 0) return 0
    // The lead owns the first row; a taller card in the lower peers must not
    // inflate the lead row and create an artificial gap before the peers.
    return cardHeight(source[0] && source[0].id, sizes)
}

function threeCardHorizontalHeight(cards, sizes, spacing) {
    var source = Array.isArray(cards) ? cards : []
    if (source.length !== 3) return stackHeight(source, sizes, spacing)

    var gap = Number(spacing)
    if (!isFinite(gap) || gap < 0) gap = 0

    // The lead and lower peer row use their own natural heights. The shorter
    // peer column is top-aligned in QML rather than vertically centred.
    var peerColumns = wideLeadPeerColumns(source.slice(1), sizes, gap)
    var peerHeight = Math.max(
        stackHeight(peerColumns.left, sizes, gap),
        stackHeight(peerColumns.right, sizes, gap)
    )
    return threeCardHorizontalRowHeight(source, sizes) + gap + peerHeight
}

// The first configured card remains the full-width lead whenever a two-column
// area can support the horizontal Bento. All remaining cards are split into
// two balanced vertical stacks, so adding the fourth or fifth card does not
// silently remove the lead treatment. With exactly three cards this resolves
// to the original side-by-side pair beneath the lead.
function wideLeadPeerColumns(peers, sizes, spacing) {
    return balancedColumns(peers, sizes, spacing)
}

function wideLeadHorizontalHeight(cards, sizes, spacing) {
    var source = Array.isArray(cards) ? cards : []
    if (source.length < 3) return stackHeight(source, sizes, spacing)

    var gap = Number(spacing)
    if (!isFinite(gap) || gap < 0) gap = 0

    // The first row follows only the lead card's selected size. Lower columns
    // are measured independently; shorter columns are top-aligned in QML.
    var leadTrackHeight = cardHeight(source[0] && source[0].id, sizes)
    var peerColumns = wideLeadPeerColumns(source.slice(1), sizes, gap)
    var peerTrackHeight = Math.max(
        stackHeight(peerColumns.left, sizes, gap),
        stackHeight(peerColumns.right, sizes, gap)
    )
    return leadTrackHeight + gap + peerTrackHeight
}

function stackHeight(cards, sizes, spacing) {
    var source = Array.isArray(cards) ? cards : []
    if (source.length === 0) return 0

    var gap = Number(spacing)
    if (!isFinite(gap) || gap < 0) gap = 0

    var total = Math.max(0, source.length - 1) * gap
    for (var i = 0; i < source.length; ++i)
        total += cardHeight(source[i] && source[i].id, sizes)
    return total
}

// Keep Flickable's offset within the newly resolved content bounds after
// a responsive layout, visibility or viewport-height change. Invalid startup
// measurements safely collapse to the top instead of leaking NaN into QML.
function clampScrollPosition(position, contentHeight, viewportHeight) {
    var current = Number(position)
    var content = Number(contentHeight)
    var viewport = Number(viewportHeight)

    if (!isFinite(current)) current = 0
    if (!isFinite(content) || content < 0) content = 0
    if (!isFinite(viewport) || viewport < 0) viewport = 0

    var maximum = Math.max(0, content - viewport)
    return Math.max(0, Math.min(maximum, current))
}

// Convert mouse-wheel notches and high-resolution touchpad pixel deltas into
// one bounded Flickable position. A null result means the event had no vertical
// movement and should be left unhandled; non-zero events stay consumed even at
// the scroll boundaries so the outer shell does not move underneath Dashboard.
function wheelScrollPosition(position, contentHeight, viewportHeight, pixelDeltaY, angleDeltaY) {
    var pixelDelta = Number(pixelDeltaY)
    var angleDelta = Number(angleDeltaY)
    if (!isFinite(pixelDelta)) pixelDelta = 0
    if (!isFinite(angleDelta)) angleDelta = 0

    var delta = pixelDelta !== 0 ? pixelDelta : angleDelta / 120 * 64
    if (delta === 0) return null

    var current = clampScrollPosition(position, contentHeight, viewportHeight)
    return clampScrollPosition(
        current - delta,
        contentHeight,
        viewportHeight
    )
}

function normalizeColumnsMode(value) {
    var mode = String(value === undefined || value === null ? "" : value)
    return COLUMN_MODES.indexOf(mode) >= 0 ? mode : "auto"
}

function columnsForWidth(mode, width) {
    var key = normalizeColumnsMode(mode)
    var availableWidth = Number(width)
    if (!isFinite(availableWidth) || availableWidth <= 0) return 1
    if (key === "one") return 1

    // Explicit two-column mode may use the full readable minimum. Auto mode
    // is deliberately more conservative and needs a little extra breathing room.
    var threshold = key === "two" ? MIN_TWO_COLUMN_WIDTH : AUTO_TWO_COLUMN_WIDTH
    return availableWidth >= threshold ? 2 : 1
}

// Keep the drawer at its established maximum width and preserve outer screen
// insets. Card count and column mode affect only the inner composition, never
// the panel's width.
function drawerWidthForScreenWidth(screenWidth) {
    var availableScreenWidth = Number(screenWidth)
    if (!isFinite(availableScreenWidth) || availableScreenWidth <= 0)
        return 1

    var availableDrawerWidth = Math.max(1, availableScreenWidth - DRAWER_SCREEN_INSET)
    return Math.max(1, Math.min(DEFAULT_DRAWER_MAX_WIDTH, availableDrawerWidth))
}

// Resolve the entire composition from the current ordered visible set and
// width. Recomputing one state object keeps breakpoint, order and visibility
// transitions atomic: every visible card belongs to exactly one active model,
// while all inactive layout models receive empty arrays.
function resolveDashboardLayout(cards, mode, width, sizes, spacing) {
    var source = Array.isArray(cards) ? cards.slice() : []
    var columns = columnsForWidth(mode, width)
    var state = {
        columns: columns,
        kind: source.length === 0 ? "empty" : "single",
        left: [],
        right: [],
        lead: [],
        peers: []
    }

    if (source.length === 0)
        return state

    if (columns !== 2) {
        state.left = source
        return state
    }

    if (source.length >= 3 && threeCardOrientation(width) === "horizontal") {
        state.kind = "wide-lead-horizontal"
        state.lead = [source[0]]
        state.peers = source.slice(1)
        return state
    }

    if (source.length === 3) {
        state.kind = "three-vertical"
        state.left = [source[0]]
        state.right = source.slice(1)
        return state
    }

    var split = balancedColumns(source, sizes, spacing)
    state.kind = source.length === 1 ? "single" : "balanced"
    state.left = split.left
    state.right = split.right
    return state
}

// Resolve the complete card composition from the current ordered visible set
// and width. Keeping this decision pure makes live visibility, order and
// breakpoint changes deterministic: each card is assigned to exactly one
// visible model and the inactive composition receives empty arrays.

var DEFINITIONS = [
    { id: "today", label: "Сегодня", settingsLabel: "Сегодня — время, дата и заметки", description: "Текущее время, дата и заметки календаря", symbol: "󰃭", keywords: "today time date calendar notes current clock время дата календарь заметки сегодня" },
    { id: "system", label: "Система", settingsLabel: "Система — CPU и RAM", description: "Использование CPU и RAM", symbol: "", keywords: "system cpu ram performance memory processor система производительность память процессор" },
    { id: "network", label: "Сеть", settingsLabel: "Сеть — скорость загрузки и отдачи", description: "Скорость загрузки и отдачи", symbol: "󰖩", keywords: "network speed upload download internet сеть скорость интернет передача" },
    { id: "weather", label: "Погода", settingsLabel: "Погода — текущие условия", description: "Текущая температура и условия", symbol: "󰖐", keywords: "weather temperature forecast погода температура прогноз" },
    { id: "media", label: "Медиа", settingsLabel: "Медиа — текущий плеер", description: "Текущий плеер и композиция", symbol: "󰎆", keywords: "media player music track artist медиа плеер музыка композиция исполнитель" }
]

function defaults() {
    return DEFAULT_IDS.slice()
}

function normalize(values) {
    if (!Array.isArray(values)) return defaults()

    // Runtime visibility is literal: a four-card selection without Today is
    // a valid user choice, not a legacy default. Legacy migration is performed
    // only while loading a profile, where the old card-order field can confirm
    // that the profile predates the Today card.
    var result = []
    for (var i = 0; i < values.length; ++i) {
        var id = String(values[i] || "")
        if (DEFAULT_IDS.indexOf(id) >= 0 && result.indexOf(id) < 0)
            result.push(id)
    }
    return result
}

function contains(values, id) {
    return normalize(values).indexOf(String(id || "")) >= 0
}

function setEnabled(values, id, enabled) {
    var key = String(id || "")
    if (DEFAULT_IDS.indexOf(key) < 0) return normalize(values)
    var result = normalize(values)
    var index = result.indexOf(key)
    if (enabled && index < 0) result.push(key)
    else if (!enabled && index >= 0) result.splice(index, 1)
    return result
}


// Card order is independent from visibility: every known card always appears
// exactly once in this list, even when its checkbox is disabled.
function normalizeOrder(values) {
    if (!Array.isArray(values)) return defaults()
    var result = []
    for (var i = 0; i < values.length; ++i) {
        var id = String(values[i] || "")
        if (DEFAULT_IDS.indexOf(id) >= 0 && result.indexOf(id) < 0)
            result.push(id)
    }
    for (var j = 0; j < DEFAULT_IDS.length; ++j) {
        var fallbackId = DEFAULT_IDS[j]
        if (result.indexOf(fallbackId) < 0) result.push(fallbackId)
    }
    return result
}

function indexOf(values, id) {
    return normalizeOrder(values).indexOf(String(id || ""))
}

function move(values, id, direction) {
    var result = normalizeOrder(values)
    var from = result.indexOf(String(id || ""))
    var delta = Number(direction)
    if (from < 0 || !isFinite(delta) || delta === 0) return result
    var to = Math.max(0, Math.min(result.length - 1, from + (delta < 0 ? -1 : 1)))
    if (to === from) return result
    var item = result[from]
    result.splice(from, 1)
    result.splice(to, 0, item)
    return result
}

// Move one card directly before another. Dashboard's in-panel editor uses
// this after a drag/drop gesture; visibility remains independent of order.
function moveBefore(values, sourceId, targetId) {
    var result = normalizeOrder(values)
    var source = String(sourceId || "")
    var target = String(targetId || "")
    if (source === target || DEFAULT_IDS.indexOf(source) < 0 || DEFAULT_IDS.indexOf(target) < 0)
        return result

    var from = result.indexOf(source)
    var to = result.indexOf(target)
    if (from < 0 || to < 0) return result

    result.splice(from, 1)
    to = result.indexOf(target)
    if (to < 0) return normalizeOrder(result)
    result.splice(to, 0, source)
    return result
}

// Reorder in the direction of the drop. Dropping an earlier card on a later
// card places it after the target; dropping a later card on an earlier one
// places it before. This avoids the old forward-drop no-op of moveBefore().
function moveByDrop(values, sourceId, targetId) {
    var result = normalizeOrder(values)
    var source = String(sourceId || "")
    var target = String(targetId || "")
    if (source === target || DEFAULT_IDS.indexOf(source) < 0 || DEFAULT_IDS.indexOf(target) < 0)
        return result

    var from = result.indexOf(source)
    var to = result.indexOf(target)
    if (from < 0 || to < 0) return result

    var placeAfter = from < to
    result.splice(from, 1)
    to = result.indexOf(target)
    if (to < 0) return normalizeOrder(result)
    result.splice(placeAfter ? to + 1 : to, 0, source)
    return result
}

// Measure pointer-to-card-rectangle distance. A point anywhere inside the
// card is a valid target; a modest outside tolerance also makes the gaps
// between neighbouring cards forgiving without requiring a centre hit.
function cardDropTargetScore(point, rect, toleranceX, toleranceY) {
    if (!point || !rect) return Number.POSITIVE_INFINITY
    var left = Number(rect.left)
    var right = Number(rect.right)
    var top = Number(rect.top)
    var bottom = Number(rect.bottom)
    var x = Number(point.x)
    var y = Number(point.y)
    if (![left, right, top, bottom, x, y].every(isFinite)
            || right <= left || bottom <= top)
        return Number.POSITIVE_INFINITY

    var dx = x < left ? left - x : (x > right ? x - right : 0)
    var dy = y < top ? top - y : (y > bottom ? y - bottom : 0)
    if (dx > Math.max(0, Number(toleranceX) || 0)
            || dy > Math.max(0, Number(toleranceY) || 0))
        return Number.POSITIVE_INFINITY
    return dx * dx + dy * dy
}

function orderedVisible(order, visibleIds) {
    var orderIds = normalizeOrder(order)
    var visible = Array.isArray(visibleIds) ? normalize(visibleIds) : DEFAULT_IDS.slice()
    var result = []
    for (var i = 0; i < orderIds.length; ++i) {
        if (visible.indexOf(orderIds[i]) < 0) continue
        for (var j = 0; j < DEFINITIONS.length; ++j) {
            if (DEFINITIONS[j].id === orderIds[i]) {
                result.push(DEFINITIONS[j])
                break
            }
        }
    }
    return result
}

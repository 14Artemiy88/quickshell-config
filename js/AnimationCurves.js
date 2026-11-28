.pragma library

// CSS timing functions represented as Qt Quick BezierSpline control points.
// Values are [x1, y1, x2, y2, 1, 1]. The legacy tokens are normalized so
// existing settings and profiles keep their motion instead of being reset.
var cssCurves = {
    "ease": [0.25, 0.1, 0.25, 1, 1, 1],
    "ease-in": [0.42, 0, 1, 1, 1, 1],
    "ease-out": [0, 0, 0.58, 1, 1, 1],
    "ease-in-out": [0.42, 0, 0.58, 1, 1, 1]
}

var legacyProfiles = {
    "standard": "ease-out",
    "spatial": "ease-out",
    "effects": "ease-in",
    "expressive": "ease-in-out",
    "expressivespatial": "ease-out",
    "expressiveeffects": "ease-in"
}

var defaultBezier = [0.25, 0.1, 0.25, 1]

function parseBezier(value) {
    var match = String(value || "").trim().match(/^cubic-bezier\(\s*([^)]*)\s*\)$/i)
    if (!match) return null
    var parts = match[1].split(",")
    if (parts.length !== 4) return null
    var values = []
    for (var i = 0; i < 4; ++i) {
        var number = Number(String(parts[i]).trim())
        if (!isFinite(number)) return null
        values.push(number)
    }
    // CSS constrains x control points to [0, 1]; y may overshoot.
    if (values[0] < 0 || values[0] > 1 || values[2] < 0 || values[2] > 1)
        return null
    return values
}

function formatBezier(values) {
    var parts = []
    for (var i = 0; i < 4; ++i) {
        var rounded = Math.round(Number(values[i]) * 1000) / 1000
        parts.push(String(rounded))
    }
    return "cubic-bezier(" + parts.join(", ") + ")"
}

function normalizeProfile(profile) {
    var name = String(profile || "ease-in-out").trim().toLowerCase()
    if (name === "none" || name === "linear" || name === "ease" || name === "ease-in"
            || name === "ease-out" || name === "ease-in-out")
        return name
    if (Object.prototype.hasOwnProperty.call(legacyProfiles, name))
        return legacyProfiles[name]
    var values = parseBezier(name)
    return values ? formatBezier(values) : ""
}

function bezierValues(profile) {
    var name = normalizeProfile(profile)
    if (name === "linear") return [0, 0, 1, 1, 1, 1]
    if (Object.prototype.hasOwnProperty.call(cssCurves, name)) return cssCurves[name].slice(0)
    var custom = parseBezier(name)
    if (custom) return [custom[0], custom[1], custom[2], custom[3], 1, 1]
    return []
}

function forProfile(profile, phase) {
    var name = normalizeProfile(profile)
    if (name === "none" || name === "linear") return []
    return bezierValues(name)
}

function get(name) {
    return bezierValues(name)
}

function bezierYAt(t, y1, y2) {
    var inverse = 1 - t
    return 3 * inverse * inverse * t * y1
        + 3 * inverse * t * t * y2
        + t * t * t
}

// Return the maximum distance by which a CSS easing curve leaves [0, 1].
// Layer-shell surfaces use this to reserve transparent paint space for a
// legitimate cubic-bezier overshoot without moving the module's saved origin.
function overshootFactor(profile) {
    var values = bezierValues(profile)
    if (!values || values.length < 6) return 0

    var y1 = Number(values[1])
    var y2 = Number(values[3])
    if (!isFinite(y1) || !isFinite(y2)) return 0

    // y(t) = a*t^3 + b*t^2 + c*t; solve y'(t) = 0 for its
    // interior extrema. CSS constrains x controls but intentionally allows
    // arbitrary finite y controls.
    var a = 3 * y1 - 3 * y2 + 1
    var b = -6 * y1 + 3 * y2
    var c = 3 * y1
    var derivativeA = 3 * a
    var derivativeB = 2 * b
    var derivativeC = c
    var candidates = [0, 1]

    if (Math.abs(derivativeA) < 1e-9) {
        if (Math.abs(derivativeB) >= 1e-9) {
            var linearRoot = -derivativeC / derivativeB
            if (linearRoot > 0 && linearRoot < 1) candidates.push(linearRoot)
        }
    } else {
        var discriminant = derivativeB * derivativeB - 4 * derivativeA * derivativeC
        if (discriminant >= 0) {
            var squareRoot = Math.sqrt(discriminant)
            var firstRoot = (-derivativeB - squareRoot) / (2 * derivativeA)
            var secondRoot = (-derivativeB + squareRoot) / (2 * derivativeA)
            if (firstRoot > 0 && firstRoot < 1) candidates.push(firstRoot)
            if (secondRoot > 0 && secondRoot < 1) candidates.push(secondRoot)
        }
    }

    var minimum = 0
    var maximum = 1
    for (var i = 0; i < candidates.length; ++i) {
        var y = bezierYAt(candidates[i], y1, y2)
        minimum = Math.min(minimum, y)
        maximum = Math.max(maximum, y)
    }
    return Math.max(0, maximum - 1, -minimum)
}

function names() {
    return ["linear", "ease", "ease-in", "ease-out", "ease-in-out", "cubic-bezier()"]
}

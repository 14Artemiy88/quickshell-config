.pragma library

// Motion curves adapted from Caelestia's animation token library.
// Each Bezier spline is represented as Qt Quick expects it:
// control point 1, control point 2, end point (repeated for each segment).
var curves = {
    emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1],
    emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1],
    emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1],
    standard: [0.2, 0, 0, 1, 1, 1],
    standardAccel: [0.3, 0, 1, 1, 1, 1],
    standardDecel: [0, 0, 0, 1, 1, 1],
    expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1],
    expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1],
    expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1],
    expressiveFastEffects: [0.31, 0.94, 0.34, 1, 1, 1],
    expressiveDefaultEffects: [0.34, 0.8, 0.34, 1, 1, 1],
    expressiveSlowEffects: [0.34, 0.88, 0.34, 1, 1, 1]
}

function get(name) {
    var curve = curves[String(name || "")]
    return curve ? curve.slice(0) : []
}

function forProfile(profile, phase) {
    var name = String(profile || "standard").toLowerCase()
    var direction = String(phase || "enter").toLowerCase()

    if (name === "none")
        return []
    if (name === "expressive")
        return get(direction === "exit" ? "emphasizedAccel" : "emphasizedDecel")
    if (name === "expressivespatial")
        return get("expressiveDefaultSpatial")
    if (name === "expressiveeffects")
        return get("expressiveDefaultEffects")
    return []
}

function names() {
    return Object.keys(curves)
}

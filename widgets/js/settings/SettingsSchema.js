.pragma library

// Keep old settings readable while new snapshots contain only canonical fields.
function normalizeSavedColor(value, fallback) {
    if (typeof value === "string") {
        var text = value.trim()
        if (/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(text) || text.toLowerCase() === "transparent")
            return text
        return fallback
    }
    if (value && typeof value === "object" && value.valid === true) {
        var channels = [value.a, value.r, value.g, value.b]
        for (var i = 0; i < channels.length; ++i) {
            if (typeof channels[i] !== "number" || !isFinite(channels[i])) return fallback
        }
        function hexByte(component) {
            var n = Math.max(0, Math.min(255, Math.round(component * 255)))
            return (n < 16 ? "0" : "") + n.toString(16)
        }
        return "#" + hexByte(value.a) + hexByte(value.r) + hexByte(value.g) + hexByte(value.b)
    }
    return fallback
}

function normalizeProfile(profile, isSparse) {
    if (!profile || typeof profile !== "object") return null
    var p = JSON.parse(JSON.stringify(profile))

    // Migrate old separate finished-image margins to the current shared field.
    if (p.timerFinishedImageMargin === undefined) {
        var oldMargin = p.timerFinishedImageTopMargin !== undefined
            ? Number(p.timerFinishedImageTopMargin)
            : (p.timerFinishedImageBottomMargin !== undefined ? Number(p.timerFinishedImageBottomMargin) : NaN)
        if (isFinite(oldMargin)) p.timerFinishedImageMargin = Math.max(0, Math.min(100, Math.round(oldMargin)))
    }
    delete p.timerFinishedImageTopMargin
    delete p.timerFinishedImageBottomMargin

    // Migrate the old one-size-fits-all Player icon size only by dropping it;
    // current Player controls have independent size settings.
    delete p.playerControlIconSize

    // Migrate the former shared Mopidy move-button switch when split values are absent.
    if (p.mopidyShowMoveUpIcon === undefined && p.mopidyShowMoveDownIcon === undefined && p.mopidyShowMoveButtons !== undefined) {
        p.mopidyShowMoveUpIcon = !!p.mopidyShowMoveButtons
        p.mopidyShowMoveDownIcon = !!p.mopidyShowMoveButtons
    }
    delete p.mopidyShowMoveButtons

    if (!isSparse && p.mopidyAlbumBold === undefined) p.mopidyAlbumBold = true
    if (p.weatherToken !== undefined) p.weatherToken = String(p.weatherToken).trim()
    if (isSparse) delete p.weatherToken
    if (p.timerFinishedBackgroundColor !== undefined)
        p.timerFinishedBackgroundColor = normalizeSavedColor(p.timerFinishedBackgroundColor, "#4d000000")
    if (p.timerFinishedTitleColor !== undefined)
        p.timerFinishedTitleColor = normalizeSavedColor(p.timerFinishedTitleColor, "#ffffff")

    // QColor values in old JSON files are objects. Convert valid entries to
    // canonical ARGB strings; omit invalid entries so the captured defaults
    // are inherited when the profile is expanded.
    if (p.colors && typeof p.colors === "object") {
        var normalizedColors = {}
        for (var colorName in p.colors) {
            if (!Object.prototype.hasOwnProperty.call(p.colors, colorName)) continue
            var normalizedColor = normalizeSavedColor(p.colors[colorName], null)
            if (normalizedColor !== null) normalizedColors[colorName] = normalizedColor
        }
        p.colors = normalizedColors
    }
    return p
}

function normalizeProfiles(profiles, isSparse) {
    var clean = {}
    if (!profiles || typeof profiles !== "object") return clean
    for (var name in profiles) {
        if (!Object.prototype.hasOwnProperty.call(profiles, name)) continue
        var p = normalizeProfile(profiles[name], !!isSparse)
        if (p) clean[name] = p
    }
    return clean
}

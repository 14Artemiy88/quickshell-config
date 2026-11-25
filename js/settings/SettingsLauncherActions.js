.pragma library

function clone(value) {
    return JSON.parse(JSON.stringify(value))
}

function singleLine(value, maxLength) {
    return String(value === undefined || value === null ? "" : value)
        .replace(/[\r\n\t]/g, " ")
        .trim()
        .slice(0, maxLength)
}

function uniqueId(preferred, used, fallbackIndex) {
    var base = singleLine(preferred, 64).replace(/[^A-Za-z0-9_-]/g, "-")
    if (!base) base = "custom-" + String(fallbackIndex + 1)
    var candidate = base
    var suffix = 2
    while (used[candidate]) {
        candidate = base + "-" + String(suffix)
        suffix++
    }
    used[candidate] = true
    return candidate
}

function validateRequiredFields(action) {
    var item = action && typeof action === "object" ? action : {}
    var enabled = item.enabled !== false
    var missingName = enabled && singleLine(item.name, 128).length === 0
    var missingCommand = enabled && singleLine(item.command, 2048).length === 0
    return {
        valid: !missingName && !missingCommand,
        missingName: missingName,
        missingCommand: missingCommand
    }
}

function normalize(source) {
    if (!Array.isArray(source)) return []
    var result = []
    var used = ({})
    var limit = Math.min(source.length, 100)
    for (var i = 0; i < limit; ++i) {
        var item = source[i] && typeof source[i] === "object" ? source[i] : {}
        result.push({
            id: uniqueId(item.id, used, i),
            enabled: item.enabled === undefined ? true : !!item.enabled,
            icon: singleLine(item.icon || "󰌌", 16) || "󰌌",
            name: singleLine(item.name, 128),
            description: singleLine(item.description, 240),
            command: singleLine(item.command, 2048)
        })
    }
    return result
}

function update(source, index, field, value) {
    var allowed = ["enabled", "icon", "name", "description", "command"]
    var result = normalize(source)
    var i = Number(index)
    var key = String(field)
    if (!isFinite(i) || Math.floor(i) !== i || i < 0 || i >= result.length || allowed.indexOf(key) < 0)
        return result
    var item = clone(result[i])
    if (key === "enabled") item.enabled = !!value
    else {
        var limits = { icon: 16, name: 128, description: 240, command: 2048 }
        item[key] = singleLine(value, limits[key])
        if (key === "icon" && item.icon === "") item.icon = "󰌌"
    }
    result[i] = item
    return result
}

function updateFields(source, index, values) {
    var result = normalize(source)
    var i = Number(index)
    if (!isFinite(i) || Math.floor(i) !== i || i < 0 || i >= result.length
            || !values || typeof values !== "object")
        return result

    var item = clone(result[i])
    var limits = { icon: 16, name: 128, description: 240, command: 2048 }
    if (Object.prototype.hasOwnProperty.call(values, "enabled"))
        item.enabled = !!values.enabled
    var fields = ["icon", "name", "description", "command"]
    for (var f = 0; f < fields.length; ++f) {
        var key = fields[f]
        if (!Object.prototype.hasOwnProperty.call(values, key)) continue
        item[key] = singleLine(values[key], limits[key])
        if (key === "icon" && item.icon === "") item.icon = "󰌌"
    }
    result[i] = item
    return result
}

function add(source) {
    var result = normalize(source)
    if (result.length >= 100) return result
    var used = ({})
    for (var i = 0; i < result.length; ++i) used[result[i].id] = true
    result.push({
        id: uniqueId("custom-" + String(result.length + 1), used, result.length),
        enabled: true,
        icon: "󰌌",
        name: "",
        description: "",
        command: ""
    })
    return result
}

function remove(source, index) {
    var result = normalize(source)
    var i = Number(index)
    if (isFinite(i) && Math.floor(i) === i && i >= 0 && i < result.length)
        result.splice(i, 1)
    return result
}

function move(source, index, delta) {
    var result = normalize(source)
    var i = Number(index)
    var to = i + Number(delta)
    if (!isFinite(i) || Math.floor(i) !== i || i < 0 || i >= result.length
            || !isFinite(to) || Math.floor(to) !== to || to < 0 || to >= result.length)
        return result
    var item = result.splice(i, 1)[0]
    result.splice(to, 0, item)
    return result
}
function moveTo(source, fromIndex, toIndex) {
    var result = normalize(source)
    var from = Number(fromIndex)
    var to = Number(toIndex)
    if (!isFinite(from) || Math.floor(from) !== from || from < 0 || from >= result.length
            || !isFinite(to) || Math.floor(to) !== to || to < 0 || to >= result.length || from === to)
        return result
    var item = result.splice(from, 1)[0]
    result.splice(to, 0, item)
    return result
}


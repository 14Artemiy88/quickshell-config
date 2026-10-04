.pragma library

function geometryForLayout(owner, moduleName) {
    var live = owner.layoutEditGeometry[moduleName]
    if (live && live.length === 4)
        return live
    return owner.geometry[moduleName] || [0, 0, 100, 100]
}

function beginGeometryDrag(owner, moduleName) {
    var source = owner.geometry[moduleName] || [0, 0, 100, 100]
    var live = Object.assign({}, owner.layoutEditGeometry)
    live[moduleName] = source.slice()
    owner.layoutEditGeometry = live
}

function updateGeometryDrag(owner, moduleName, x, y) {
    var source = owner.geometry[moduleName] || [0, 0, 100, 100]
    var live = Object.assign({}, owner.layoutEditGeometry)
    var a = (live[moduleName] || source).slice()
    a[0] = Math.round(Number(x))
    a[1] = Math.round(Number(y))
    live[moduleName] = a
    owner.layoutEditGeometry = live
}

function endGeometryDrag(owner, moduleName, monitorName, x, y) {
    var live = owner.layoutEditGeometry[moduleName]
    if (!live || live.length !== 4)
        return

    var g = Object.assign({}, owner.geometry)
    var a = (g[moduleName] || [0, 0, 100, 100]).slice()
    var finalX = x !== undefined && isFinite(Number(x)) ? Number(x) : Number(live[0])
    var finalY = y !== undefined && isFinite(Number(y)) ? Number(y) : Number(live[1])
    a[0] = Math.round(finalX)
    a[1] = Math.round(finalY)
    g[moduleName] = a
    owner.geometry = g

    if (monitorName !== undefined && String(monitorName).trim() !== "") {
        var monitors = Object.assign({}, owner.moduleMonitors || {})
        monitors[moduleName] = String(monitorName)
        owner.moduleMonitors = monitors
    }

    var overrides = Object.assign({}, owner.layoutEditGeometry)
    delete overrides[moduleName]
    owner.layoutEditGeometry = overrides

    owner.save()
}

function cancelGeometryDrag(owner, moduleName) {
    var overrides = Object.assign({}, owner.layoutEditGeometry)
    delete overrides[moduleName]
    owner.layoutEditGeometry = overrides
}

function adjustGeometry(owner, moduleName, index, delta) {
    var g = Object.assign({}, owner.geometry)
    var a = (g[moduleName] || [0, 0, 100, 100]).slice()
    var current = Number(a[index])
    if (!isFinite(current)) current = index < 2 ? 0 : 100
    var next = current + Number(delta)
    if (index >= 2) next = Math.max(1, next)
    a[index] = next
    g[moduleName] = a
    owner.geometry = g
    owner.save()
}

function adjustSettingsGeometry(owner, index, delta) {
    var a = (owner.settingsGeometry || [640, 40, 560, 850]).slice()
    var current = Number(a[index])
    if (!isFinite(current)) current = index < 2 ? 0 : 560
    var next = current + Number(delta)
    if (index >= 2) {
        next = Math.max(index === 2 ? 320 : 240, next)
    }
    a[index] = next
    owner.settingsGeometry = a
    owner.save()
}

function beginSettingsGeometryDrag(owner) {
    owner.settingsGeometryDragStart = (owner.settingsGeometry || [640, 40, 560, 850]).slice()
}

function updateSettingsGeometryDrag(owner, newX, newY, monitorName) {
    var a = (owner.settingsGeometry || [640, 40, 560, 850]).slice()
    a[0] = Math.round(Number(newX) || 0)
    a[1] = Math.round(Number(newY) || 0)
    owner.settingsGeometry = a
    if (monitorName !== undefined && String(monitorName).trim() !== "")
        owner.settingsMonitorName = String(monitorName)
}

function endSettingsGeometryDrag(owner, monitorName, x, y) {
    var a = (owner.settingsGeometry || [640, 40, 560, 850]).slice()
    if (x !== undefined && isFinite(Number(x)))
        a[0] = Number(x)
    if (y !== undefined && isFinite(Number(y)))
        a[1] = Number(y)
    owner.settingsGeometry = a
    if (monitorName !== undefined && String(monitorName).trim() !== "")
        owner.settingsMonitorName = String(monitorName)
    owner.save()
}


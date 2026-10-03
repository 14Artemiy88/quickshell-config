.pragma library

function updateTimerPreset(root, index, value) {
    setTimerPresetDefault(root, index, value)
}

function setTimerPresetDefault(root, index, value) {
    var defaults = (root.timerPresetDefaults || []).slice()
    if (index < 0 || index >= defaults.length) return

    var n = Number(value)
    if (!isFinite(n)) return
    n = Math.max(0, Math.round(n))

    defaults[index] = n
    root.timerPresetDefaults = defaults
    root.timerPresets = defaults.slice()
    root.save()
}

// Wheel changes are temporary runtime values; middle click restores the
// configured default for the clicked preset button.
function adjustTimerPreset(root, index, delta) {
    var a = (root.timerPresets || []).slice()
    if (index < 0 || index >= a.length) return

    var current = Number(a[index])
    if (!isFinite(current)) current = 0
    a[index] = Math.max(0, Math.round(current + Number(delta)))
    root.timerPresets = a
}

function adjustTimerPresetDefault(root, index, delta) {
    var defaults = (root.timerPresetDefaults || []).slice()
    if (index < 0 || index >= defaults.length) return

    var current = Number(defaults[index])
    if (!isFinite(current)) current = 0
    defaults[index] = Math.max(0, Math.round(current + Number(delta)))
    root.timerPresetDefaults = defaults
    root.timerPresets = defaults.slice()
    root.save()
}

function resetTimerPreset(root, index) {
    var defaults = root.timerPresetDefaults || []
    if (index < 0 || index >= defaults.length) return

    var a = (root.timerPresets || []).slice()
    a[index] = Number(defaults[index])
    root.timerPresets = a
}

function addTimerPreset(root, value) {
    var defaults = (root.timerPresetDefaults || []).slice()
    var n = Number(value)
    if (!isFinite(n)) n = 5
    n = Math.max(0, Math.round(n))

    defaults.push(n)
    root.timerPresetDefaults = defaults
    root.timerPresets = defaults.slice()
    root.save()
}

function removeTimerPreset(root, index) {
    var defaults = (root.timerPresetDefaults || []).slice()
    if (index < 0 || index >= defaults.length) return

    defaults.splice(index, 1)
    root.timerPresetDefaults = defaults
    root.timerPresets = defaults.slice()
    root.save()
}

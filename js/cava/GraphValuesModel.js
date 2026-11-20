.pragma library

// Keep a stable ListModel for the CAVA bars. Updating only changed row roles
// avoids invalidating every delegate binding when the audio stream emits a new
// frame. The mirrored upper/lower graphs can share the same model.
function sync(model, samples, targetCount) {
    if (!model || typeof model.append !== "function" ||
        typeof model.remove !== "function" || typeof model.setProperty !== "function" ||
        typeof model.get !== "function") {
        return { peak: 0, changedCount: 0 }
    }

    var count = Math.max(0, Math.floor(Number(targetCount) || 0))
    while (model.count > count)
        model.remove(model.count - 1)
    while (model.count < count)
        model.append({ value: 0.0 })

    var sampleCount = Array.isArray(samples) ? samples.length : 0
    var peak = 0
    var changedCount = 0
    var scanCount = Math.max(count, sampleCount)

    for (var i = 0; i < scanCount; ++i) {
        var value = i < sampleCount ? Number(samples[i]) : 0
        if (!isFinite(value)) value = 0
        if (value > peak) peak = value

        if (i < count && model.get(i).value !== value) {
            model.setProperty(i, "value", value)
            changedCount++
        }
    }

    return { peak: peak, changedCount: changedCount }
}

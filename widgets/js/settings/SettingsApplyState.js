.pragma library

function apply(owner, Config, o, moduleNames, defaultModuleFrames, defaultModuleBackgrounds, colorNames) {
        var presetSource = o.timerPresetDefaults instanceof Array ? o.timerPresetDefaults : o.timerPresets
        if (presetSource instanceof Array) {
            var presets = []
            for (var p = 0; p < presetSource.length; ++p) {
                var value = Number(presetSource[p])
                if (isFinite(value)) presets.push(Math.max(0, Math.round(value)))
            }
            owner.timerPresetDefaults = presets
            owner.timerPresets = presets.slice()
        }
        var modules = o.modules || {}
        for (var i=0; i<moduleNames.length; ++i) if (modules[moduleNames[i]] !== undefined) owner[moduleNames[i]] = !!modules[moduleNames[i]]
        var frames = Object.assign({}, defaultModuleFrames)
        var savedFrames = o.moduleFrames || {}
        for (var fi=0; fi<moduleNames.length; ++fi) if (savedFrames[moduleNames[fi]] !== undefined) frames[moduleNames[fi]] = !!savedFrames[moduleNames[fi]]
        owner.moduleFrames = frames
        var backgrounds = Object.assign({}, defaultModuleBackgrounds)
        var savedBackgrounds = o.moduleBackgrounds || {}
        for (var bi=0; bi<moduleNames.length; ++bi) if (savedBackgrounds[moduleNames[bi]] !== undefined) backgrounds[moduleNames[bi]] = !!savedBackgrounds[moduleNames[bi]]
        owner.moduleBackgrounds = backgrounds
        var monitors = {}
        var savedMonitors = o.moduleMonitors || {}
        for (var mi=0; mi<moduleNames.length; ++mi) {
            var monitorValue = savedMonitors[moduleNames[mi]]
            if (monitorValue !== undefined && String(monitorValue).trim() !== "")
                monitors[moduleNames[mi]] = String(monitorValue)
        }
        owner.moduleMonitors = monitors
        if (o.geometry) {
            var g = Object.assign({}, owner.geometry)
            for (var k in o.geometry) if (o.geometry[k] && o.geometry[k].length === 4) g[k] = o.geometry[k].map(Number)

            // v408 placed Mopidy over the default Networks surface, so its input
            // could be intercepted even though the module was visibly rendered.
            // Migrate only the untouched old default; preserve any user-moved layout.
            var mopidyGeometry = g.mopidy
            if (mopidyGeometry && mopidyGeometry.length === 4
                    && Number(mopidyGeometry[0]) === 330
                    && Number(mopidyGeometry[1]) === 730
                    && Number(mopidyGeometry[2]) === 300
                    && Number(mopidyGeometry[3]) === 150) {
                g.mopidy = [330, 865, 300, 150]
            }

            owner.geometry = g
        }
        if (o.settingsGeometry && o.settingsGeometry.length === 4) {
            owner.settingsGeometry = o.settingsGeometry.map(Number)
        }
        if (o.settingsMonitorName !== undefined && String(o.settingsMonitorName).trim() !== "") {
            owner.settingsMonitorName = String(o.settingsMonitorName)
        }
        var colors = o.colors || {}
        for (var j=0; j<colorNames.length; ++j) {
            var name = colorNames[j]
            if (colors[name] !== undefined) Config[name] = colors[name]
        }
        if (o.profiles !== undefined && o.profiles && typeof o.profiles === "object") {
            owner.profiles = o.profiles
            owner.rebuildProfileList()
        }
        if (o.customThemes !== undefined && o.customThemes && typeof o.customThemes === "object")
            owner.customThemes = o.customThemes
        if (o.activeProfile !== undefined) owner.activeProfile = String(o.activeProfile)
        if (o.activeTheme !== undefined) owner.activeTheme = String(o.activeTheme)
        owner.rebuildProfileList()
        owner.loaded = true
        owner.themeStateRevision++
        owner.changed()


}

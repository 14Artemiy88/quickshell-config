.pragma library

.import "SettingsSchema.js" as Schema
.import "SettingsProfiles.js" as Profiles

function migrateLegacyTopAppsMap(source) {
    var result = Object.assign({}, source || {})
    if (result.topApps !== undefined) {
        if (result.topAppsCpu === undefined) result.topAppsCpu = result.topApps
        if (result.topAppsRam === undefined) result.topAppsRam = result.topApps
        delete result.topApps
    }
    return result
}

function splitLegacyTopAppsGeometry(geometry) {
    var x = Number(geometry[0]) || 0
    var y = Number(geometry[1]) || 0
    var width = Math.max(1, Number(geometry[2]) || 315)
    var totalHeight = Math.max(7, Number(geometry[3]) || 198)
    var gap = 5
    var sectionHeight = Math.max(1, Math.floor((totalHeight - gap) / 2))
    return [[x, y, width, sectionHeight], [x, y + sectionHeight + gap, width, sectionHeight]]
}

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
        var modules = migrateLegacyTopAppsMap(o.modules || {})
        for (var i=0; i<moduleNames.length; ++i) if (modules[moduleNames[i]] !== undefined) owner[moduleNames[i]] = !!modules[moduleNames[i]]
        var frames = Object.assign({}, defaultModuleFrames)
        var savedFrames = migrateLegacyTopAppsMap(o.moduleFrames || {})
        for (var fi=0; fi<moduleNames.length; ++fi) if (savedFrames[moduleNames[fi]] !== undefined) frames[moduleNames[fi]] = !!savedFrames[moduleNames[fi]]
        owner.moduleFrames = frames
        var backgrounds = Object.assign({}, defaultModuleBackgrounds)
        var savedBackgrounds = migrateLegacyTopAppsMap(o.moduleBackgrounds || {})
        for (var bi=0; bi<moduleNames.length; ++bi) if (savedBackgrounds[moduleNames[bi]] !== undefined) backgrounds[moduleNames[bi]] = !!savedBackgrounds[moduleNames[bi]]
        owner.moduleBackgrounds = backgrounds
        var monitors = {}
        var savedMonitors = migrateLegacyTopAppsMap(o.moduleMonitors || {})
        for (var mi=0; mi<moduleNames.length; ++mi) {
            var monitorValue = savedMonitors[moduleNames[mi]]
            if (monitorValue !== undefined && String(monitorValue).trim() !== "")
                monitors[moduleNames[mi]] = String(monitorValue)
        }
        owner.moduleMonitors = monitors
        if (o.geometry) {
            var g = Object.assign({}, owner.geometry)
            for (var k in o.geometry) if (o.geometry[k] && o.geometry[k].length === 4) g[k] = o.geometry[k].map(Number)

            // Split the legacy combined Top Apps window into independently movable CPU/RAM windows.
            var legacyTopAppsGeometry = o.geometry.topApps
            if (legacyTopAppsGeometry && legacyTopAppsGeometry.length === 4) {
                var splitTopApps = splitLegacyTopAppsGeometry(legacyTopAppsGeometry)
                if (!o.geometry.topAppsCpu) g.topAppsCpu = splitTopApps[0]
                if (!o.geometry.topAppsRam) g.topAppsRam = splitTopApps[1]
            }
            delete g.topApps

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
            if (colors[name] !== undefined)
                Config[name] = Schema.normalizeSavedColor(colors[name], String(Config[name]))
        }
        if (o.profiles !== undefined && o.profiles && typeof o.profiles === "object") {
            var sparseProfiles = String(o.profileStorageFormat || "") === Profiles.SPARSE_FORMAT
            var normalizedProfiles = Schema.normalizeProfiles(o.profiles, sparseProfiles)
            if (sparseProfiles) {
                owner.profiles = normalizedProfiles
                owner.profileStorageFormat = Profiles.SPARSE_FORMAT
            } else {
                // One-time migration: convert legacy full snapshots to sparse
                // deltas against the defaults captured before settings load.
                owner.profiles = Profiles.sparsifyProfiles(owner, normalizedProfiles)
                owner.profileStorageFormat = Profiles.SPARSE_FORMAT
                owner.profileMigrationPending = true
            }
            owner.rebuildProfileList()
        } else if (String(o.profileStorageFormat || "") === Profiles.SPARSE_FORMAT) {
            owner.profileStorageFormat = Profiles.SPARSE_FORMAT
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

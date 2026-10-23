.pragma library

.import "SettingsSchema.js" as Schema
.import "SettingsProfiles.js" as Profiles
.import "SettingsThemes.js" as Themes

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

function apply(owner, Config, o, moduleNames, defaultModuleFrames, defaultModuleBackgrounds, colorNames, defaultModuleBlurEnabled) {
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
        // The launcher is a separate window, but shares the module-level frame toggle.
        if (savedFrames.launcher !== undefined) frames.launcher = !!savedFrames.launcher
        owner.moduleFrames = frames
        var backgrounds = Object.assign({}, defaultModuleBackgrounds)
        var savedBackgrounds = migrateLegacyTopAppsMap(o.moduleBackgrounds || {})
        for (var bi=0; bi<moduleNames.length; ++bi) if (savedBackgrounds[moduleNames[bi]] !== undefined) backgrounds[moduleNames[bi]] = !!savedBackgrounds[moduleNames[bi]]
        // The launcher is a separate window, but shares the module-level background toggle.
        if (savedBackgrounds.launcher !== undefined) backgrounds.launcher = !!savedBackgrounds.launcher
        owner.moduleBackgrounds = backgrounds

        // Individual blur toggles were introduced after the legacy Player-only
        // switch. Prefer the new map when present; migrate old Player settings.
        var blurEnabled = Object.assign({}, defaultModuleBlurEnabled || {})
        var savedBlurEnabled = migrateLegacyTopAppsMap(o.moduleBlurEnabled || {})
        var blurNames = moduleNames.concat(["launcher", "settings"])
        for (var bli = 0; bli < blurNames.length; ++bli) {
            var blurName = blurNames[bli]
            if (savedBlurEnabled[blurName] !== undefined)
                blurEnabled[blurName] = !!savedBlurEnabled[blurName]
        }
        if (savedBlurEnabled.player === undefined && o.playerBlurEnabled !== undefined)
            blurEnabled.player = !!o.playerBlurEnabled
        owner.moduleBlurEnabled = blurEnabled
        Config.playerBlurEnabled = !!blurEnabled.player

        var monitors = {}
        var savedMonitors = migrateLegacyTopAppsMap(o.moduleMonitors || {})
        for (var mi=0; mi<moduleNames.length; ++mi) {
            var monitorValue = savedMonitors[moduleNames[mi]]
            if (monitorValue !== undefined && String(monitorValue).trim() !== "")
                monitors[moduleNames[mi]] = String(monitorValue)
        }
        // Launcher has its own row in Modules, but uses the same monitor/geometry system.
        if (savedMonitors.launcher !== undefined && String(savedMonitors.launcher).trim() !== "")
            monitors.launcher = String(savedMonitors.launcher)
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
                // Legacy full snapshots can predate settings added by newer
                // releases. Fill missing top-level and nested values from the
                // captured defaults before diffing, so new launcher fields,
                // module toggles, geometry, and colors inherit valid defaults
                // instead of turning the entire old snapshot into a replacement.
                var completedLegacyProfiles = {}
                for (var legacyProfileName in normalizedProfiles) {
                    if (!Object.prototype.hasOwnProperty.call(normalizedProfiles, legacyProfileName)) continue
                    completedLegacyProfiles[legacyProfileName] = Profiles.completeLegacySnapshot(
                        owner.profileDefaults || {}, normalizedProfiles[legacyProfileName])
                }
                owner.profiles = Profiles.sparsifyProfiles(owner, completedLegacyProfiles)
                owner.profileStorageFormat = Profiles.SPARSE_FORMAT
                owner.profileMigrationPending = true
            }
            owner.rebuildProfileList()
        } else if (String(o.profileStorageFormat || "") === Profiles.SPARSE_FORMAT) {
            owner.profileStorageFormat = Profiles.SPARSE_FORMAT
        }
        owner.customThemes = Schema.normalizeCustomThemes(
            o.customThemes !== undefined ? o.customThemes : (owner.customThemes || {}),
            Themes.palette("14 Theme", {}))

        var requestedProfile = o.activeProfile !== undefined
            ? String(o.activeProfile).trim()
            : String(owner.activeProfile || "").trim()
        // Older snapshots can retain an active-profile name after the profile
        // was deleted, or after malformed profile entries were filtered out.
        // Never leave the UI pointing at a profile that cannot be loaded/reset.
        owner.activeProfile = requestedProfile !== ""
                && owner.profiles
                && Object.prototype.hasOwnProperty.call(owner.profiles, requestedProfile)
            ? requestedProfile
            : ""

        // Old settings can retain the name of a custom theme that was renamed
        // or deleted, or an active theme unavailable in the current release.
        // Keep the loaded color values untouched: select an exact matching
        // available palette when possible, otherwise use a valid default name
        // and let the UI correctly represent those colors as modified.
        var requestedTheme = o.activeTheme !== undefined
            ? String(o.activeTheme)
            : String(owner.activeTheme || "14 Theme")
        var themeNames = Themes.builtinThemeNames.slice()
        Object.keys(owner.customThemes || {}).sort(function(a, b) { return a.localeCompare(b) }).forEach(function(name) {
            if (themeNames.indexOf(name) < 0) themeNames.push(name)
        })
        if (themeNames.indexOf(requestedTheme) >= 0) {
            owner.activeTheme = requestedTheme
        } else {
            var matchingTheme = ""
            for (var ti = 0; ti < themeNames.length; ++ti) {
                var candidatePalette = Themes.palette(themeNames[ti], owner.customThemes)
                var matches = true
                for (var ci = 0; ci < colorNames.length; ++ci) {
                    var colorKey = colorNames[ci]
                    // Older snapshots naturally lack color keys introduced in
                    // later releases. Compare only colors actually persisted;
                    // the missing keys are migrated from the resolved palette
                    // below instead of preventing an otherwise exact match.
                    if (colors[colorKey] === undefined) continue
                    if (candidatePalette[colorKey] === undefined
                            || String(Schema.normalizeSavedColor(colors[colorKey], String(Config[colorKey]))) !== String(candidatePalette[colorKey])) {
                        matches = false
                        break
                    }
                }
                if (matches) {
                    matchingTheme = themeNames[ti]
                    break
                }
            }
            owner.activeTheme = matchingTheme || "14 Theme"
        }

        // Color keys added in newer releases were absent from old root-level
        // color maps. Initialize only those missing keys from the resolved
        // active palette so a custom theme keeps its identity after upgrade.
        var resolvedPalette = Themes.palette(owner.activeTheme, owner.customThemes)
        for (var missingColorIndex = 0; missingColorIndex < colorNames.length; ++missingColorIndex) {
            var missingColorName = colorNames[missingColorIndex]
            if (colors[missingColorName] === undefined && resolvedPalette[missingColorName] !== undefined)
                Config[missingColorName] = resolvedPalette[missingColorName]
        }
        owner.rebuildProfileList()
        owner.loaded = true
        owner.themeStateRevision++
        owner.changed()


}

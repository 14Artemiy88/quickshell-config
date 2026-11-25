.pragma library


var SPARSE_FORMAT = "sparse-v1"
var PROFILE_SETTINGS_SCHEMA_VERSION = 1
var REPLACE_MARKER = "__profile_replace__"
var MAX_PROFILE_NAME_LENGTH = 32

// Profile catalogs are dictionaries keyed by user-controlled names. Define
// keys explicitly so names such as "__proto__" remain ordinary JSON keys
// instead of invoking Object.prototype setters.
function setOwn(object, key, value) {
    Object.defineProperty(object, String(key), {
        value: value, enumerable: true, configurable: true, writable: true
    })
}

function copyProfileMap(source) {
    var result = {}
    if (!isObject(source)) return result
    var names = Object.keys(source)
    for (var i = 0; i < names.length; ++i)
        setOwn(result, names[i], clone(source[names[i]]))
    return result
}

function hasProfile(owner, name) {
    return !!(owner && isObject(owner.profiles)
        && Object.prototype.hasOwnProperty.call(owner.profiles, String(name)))
}

function normalizedProfileName(value) {
    return String(value === undefined || value === null ? "" : value).trim()
}

function clone(value) {
    if (value === undefined) return undefined
    return JSON.parse(JSON.stringify(value))
}

function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value)
}

function sameValue(a, b) {
    if (a === b) return true
    if (a === null || b === null || a === undefined || b === undefined) return a === b
    if (Array.isArray(a) || Array.isArray(b)) {
        if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) return false
        for (var i = 0; i < a.length; ++i) if (!sameValue(a[i], b[i])) return false
        return true
    }
    if (isObject(a) && isObject(b)) {
        var ak = Object.keys(a).sort()
        var bk = Object.keys(b).sort()
        if (ak.length !== bk.length) return false
        for (var j = 0; j < ak.length; ++j) {
            if (ak[j] !== bk[j] || !sameValue(a[ak[j]], b[bk[j]])) return false
        }
        return true
    }
    return false
}

// Return only values that differ from the captured application defaults.
// Arrays are atomic values; objects are diffed recursively to keep nested
// structures such as colors, module toggles and geometry compact too.
function diffValue(base, current) {
    if (sameValue(base, current)) return undefined

    if (isObject(base) && isObject(current)) {
        var baseKeys = Object.keys(base)
        var currentKeys = Object.keys(current)
        for (var m = 0; m < baseKeys.length; ++m) {
            if (!Object.prototype.hasOwnProperty.call(current, baseKeys[m])) {
                var replacement = {}
                replacement[REPLACE_MARKER] = clone(current)
                return replacement
            }
        }
        var out = {}
        for (var i = 0; i < currentKeys.length; ++i) {
            var key = currentKeys[i]
            var delta = diffValue(base[key], current[key])
            if (delta !== undefined) out[key] = delta
        }
        return out
    }

    return clone(current)
}

function mergeValue(base, delta) {
    if (isObject(delta) && Object.keys(delta).length === 1 && Object.prototype.hasOwnProperty.call(delta, REPLACE_MARKER))
        return clone(delta[REPLACE_MARKER])

    if (isObject(base) && isObject(delta)) {
        var merged = clone(base)
        for (var key in delta) {
            if (!Object.prototype.hasOwnProperty.call(delta, key)) continue
            merged[key] = mergeValue(base[key], delta[key])
        }
        return merged
    }
    return clone(delta)
}

function profileBase(owner) {
    var base = clone(owner.profileDefaults || {})
    // Weather credentials belong to the installation, not to a visual profile.
    delete base.weatherToken
    return base
}


var STORAGE_FORMAT = "profile-overrides-v1"

// Expand the compact settings file back into the effective flat snapshot used
// by the existing QML settings adapters. The active profile is the base;
// profileOverrides contains only deliberate differences from that profile.

function fallbackNavigationOrder(source) {
    var groupOrder = ["appearance", "modules", "dashboard", "launcher", "general"]
    var defaults = {
        appearance: ["themes", "settingsWindow"],
        modules: ["modules", "time", "timers", "player", "mopidy", "weather", "cava", "cpuRam", "network", "volume", "calendar", "notifications"],
        dashboard: ["dashboard"],
        launcher: ["launcher", "launcherSearch", "launcherTabs", "launcherProjects", "launcherActions", "launcherAnimation", "launcherApplications"],
        general: ["general"]
    }
    var input = isObject(source) ? source : {}
    var result = { groupOrder: [], pagesByGroup: {} }
    var seenGroups = {}
    var groups = Array.isArray(input.groupOrder) ? input.groupOrder : []
    for (var i = 0; i < groups.length; ++i) {
        var groupId = groups[i]
        if (typeof groupId === "string" && defaults[groupId] && !seenGroups[groupId]) {
            seenGroups[groupId] = true
            result.groupOrder.push(groupId)
        }
    }
    for (var j = 0; j < groupOrder.length; ++j)
        if (!seenGroups[groupOrder[j]]) result.groupOrder.push(groupOrder[j])
    var savedPages = isObject(input.pagesByGroup) ? input.pagesByGroup : {}
    for (var g = 0; g < groupOrder.length; ++g) {
        var id = groupOrder[g], pageList = [], seenPages = {}
        var candidates = Array.isArray(savedPages[id]) ? savedPages[id] : []
        for (var p = 0; p < candidates.length; ++p) {
            var pageId = candidates[p]
            if (typeof pageId === "string" && defaults[id].indexOf(pageId) >= 0 && !seenPages[pageId]) {
                seenPages[pageId] = true
                pageList.push(pageId)
            }
        }
        for (var d = 0; d < defaults[id].length; ++d)
            if (!seenPages[defaults[id][d]]) pageList.push(defaults[id][d])
        result.pagesByGroup[id] = pageList
    }
    return result
}

function fallbackNavigationOrderFromLegacy(source) {
    var defaults = fallbackNavigationOrder(null)
    var pagesByGroup = {}
    for (var i = 0; i < defaults.groupOrder.length; ++i) pagesByGroup[defaults.groupOrder[i]] = []
    var seen = {}, saved = Array.isArray(source) ? source : []
    for (var j = 0; j < saved.length; ++j) {
        var pageId = saved[j]
        if (typeof pageId !== "string" || seen[pageId]) continue
        for (var g = 0; g < defaults.groupOrder.length; ++g) {
            var groupId = defaults.groupOrder[g]
            if (defaults.pagesByGroup[groupId].indexOf(pageId) >= 0) {
                pagesByGroup[groupId].push(pageId)
                seen[pageId] = true
                break
            }
        }
    }
    return fallbackNavigationOrder({ groupOrder: defaults.groupOrder, pagesByGroup: pagesByGroup })
}

function normalizeNavigationOrderForOwner(owner, source) {
    return owner && typeof owner.normalizeSettingsNavigationOrder === "function"
        ? owner.normalizeSettingsNavigationOrder(source) : fallbackNavigationOrder(source)
}

function legacyNavigationOrderForOwner(owner, source) {
    return owner && typeof owner.settingsNavigationOrderFromLegacyTabOrder === "function"
        ? owner.settingsNavigationOrderFromLegacyTabOrder(source) : fallbackNavigationOrderFromLegacy(source)
}

function migrateLegacyNavigationOrderObject(owner, value) {
    if (!isObject(value)) return false
    var changed = false
    if (value.settingsNavigationOrder === undefined && value.settingsTabOrder !== undefined) {
        value.settingsNavigationOrder = legacyNavigationOrderForOwner(owner, value.settingsTabOrder)
        changed = true
    }
    if (value.settingsTabOrder !== undefined) {
        delete value.settingsTabOrder
        changed = true
    }
    return changed
}

function expandStoredSettings(owner, stored) {
    if (!stored || typeof stored !== "object" || stored.settingsPersistenceFormat !== STORAGE_FORMAT)
        return clone(stored)

    var defaults = profileBase(owner)
    var profiles = copyProfileMap(stored.profiles || {})
    var sparse = String(stored.profileStorageFormat || "") === SPARSE_FORMAT
    var requestedProfileName = String(stored.activeProfile || "").trim()
    var legacyOverrides = isObject(stored.profileOverrides) ? clone(stored.profileOverrides) : {}
    var navigationOrderMigrationPending = migrateLegacyNavigationOrderObject(owner, legacyOverrides)
    var legacyRootNavigationOrder = stored.settingsNavigationOrder !== undefined
        ? normalizeNavigationOrderForOwner(owner, stored.settingsNavigationOrder)
        : (stored.settingsTabOrder !== undefined
            ? legacyNavigationOrderForOwner(owner, stored.settingsTabOrder) : undefined)
    if (stored.settingsTabOrder !== undefined)
        navigationOrderMigrationPending = true
    for (var navigationProfileName in profiles) {
        if (!Object.prototype.hasOwnProperty.call(profiles, navigationProfileName)) continue
        if (migrateLegacyNavigationOrderObject(owner, profiles[navigationProfileName]))
            navigationOrderMigrationPending = true
    }
    var navigationGroupState = stored.settingsNavigationCollapsedGroups
    var hasLegacyNavigationState = Object.prototype.hasOwnProperty.call(legacyOverrides, "settingsNavigationCollapsedGroups")
    for (var profileCheckName in profiles) {
        if (!Object.prototype.hasOwnProperty.call(profiles, profileCheckName)) continue
        if (isObject(profiles[profileCheckName])
                && Object.prototype.hasOwnProperty.call(profiles[profileCheckName], "settingsNavigationCollapsedGroups"))
            hasLegacyNavigationState = true
    }
    // Earlier releases stored this UI-only preference inside profile overrides
    // (and sometimes the profile itself). Recover the current value once, then
    // strip it from every profile so future profile saves cannot reintroduce it.
    if (navigationGroupState === undefined
            && Object.prototype.hasOwnProperty.call(legacyOverrides, "settingsNavigationCollapsedGroups"))
        navigationGroupState = clone(legacyOverrides.settingsNavigationCollapsedGroups)
    if (navigationGroupState === undefined && requestedProfileName
            && Object.prototype.hasOwnProperty.call(profiles, requestedProfileName)) {
        var requestedProfile = sparse
            ? mergeValue(defaults, profiles[requestedProfileName])
            : clone(profiles[requestedProfileName])
        if (requestedProfile && Object.prototype.hasOwnProperty.call(requestedProfile, "settingsNavigationCollapsedGroups"))
            navigationGroupState = clone(requestedProfile.settingsNavigationCollapsedGroups)
    }
    if (navigationGroupState === undefined)
        navigationGroupState = { appearance: false, modules: false, launcher: false }
    if ((hasLegacyNavigationState || navigationOrderMigrationPending) && owner)
        owner.profileMigrationPending = true

    if (sparse) {
        var cleanedProfiles = {}
        for (var cleanedProfileName in profiles) {
            if (!Object.prototype.hasOwnProperty.call(profiles, cleanedProfileName)) continue
            var cleanedProfile = clone(profiles[cleanedProfileName])
            if (isObject(cleanedProfile)) delete cleanedProfile.settingsNavigationCollapsedGroups
            setOwn(cleanedProfiles, cleanedProfileName, cleanedProfile)
        }
        profiles = cleanedProfiles
    }
    var needsTimerOptionsStyleMigration = Number(stored.settingsSchemaVersion || 0) < PROFILE_SETTINGS_SCHEMA_VERSION

    // New-format files are written with sparse profiles. If a hand-edited or
    // interrupted migration leaves a legacy profile representation under the
    // new marker, normalize it to sparse deltas before choosing the base.
    if (!sparse) {
        var migrated = {}
        for (var legacyName in profiles) {
            if (!Object.prototype.hasOwnProperty.call(profiles, legacyName)) continue
            var legacyProfile = clone(profiles[legacyName])
            if (isObject(legacyProfile)) delete legacyProfile.settingsNavigationCollapsedGroups
            var completed = completeLegacySnapshot(defaults, legacyProfile)
            setOwn(migrated, legacyName, sparseProfile(owner, completed))
        }
        profiles = migrated
    }

    // Prior releases used animationTimerVisibilityStyle for both the timer
    // widget and its options popup. Migrate old sparse profiles once, before
    // expanding the active profile, so their previous popup style is retained.
    if (needsTimerOptionsStyleMigration) {
        var migratedTimerStyles = {}
        for (var timerStyleProfileName in profiles) {
            if (!Object.prototype.hasOwnProperty.call(profiles, timerStyleProfileName)) continue
            var timerStyleProfile = mergeValue(defaults, profiles[timerStyleProfileName])
            timerStyleProfile.animationTimerOptionsVisibilityStyle = String(
                timerStyleProfile.animationTimerVisibilityStyle !== undefined
                    ? timerStyleProfile.animationTimerVisibilityStyle
                    : (defaults.animationTimerOptionsVisibilityStyle || "fade"))
            setOwn(migratedTimerStyles, timerStyleProfileName, sparseProfile(owner, timerStyleProfile))
        }
        profiles = migratedTimerStyles
    }

    // Normalize the former per-module master checkbox into the explicit
    // "none" curve profile. Remove the obsolete key from every stored profile
    // so a later scoped save cannot resurrect the old false value.
    var legacyAnimationPairs = [
        ["animationMopidyMorphEnabled", "animationMopidyMorphProfile"],
        ["animationPlayerMorphEnabled", "animationPlayerMorphProfile"],
        ["animationWeatherMorphEnabled", "animationWeatherMorphProfile"],
        ["animationTimerMorphEnabled", "animationTimerMorphProfile"]
    ]
    var normalizedAnimationProfiles = {}
    for (var animationProfileName in profiles) {
        if (!Object.prototype.hasOwnProperty.call(profiles, animationProfileName)) continue
        var animationProfile = mergeValue(defaults, profiles[animationProfileName])
        for (var ap = 0; ap < legacyAnimationPairs.length; ++ap) {
            var legacyEnabledKey = legacyAnimationPairs[ap][0]
            var animationProfileKey = legacyAnimationPairs[ap][1]
            if (animationProfile[legacyEnabledKey] === false)
                animationProfile[animationProfileKey] = "none"
            delete animationProfile[legacyEnabledKey]
        }
        setOwn(normalizedAnimationProfiles, animationProfileName, sparseProfile(owner, animationProfile))
    }
    profiles = normalizedAnimationProfiles

    var requested = String(stored.activeProfile || "").trim()
    var active = requested && Object.prototype.hasOwnProperty.call(profiles, requested) ? requested : ""
    var base = clone(defaults)
    if (active)
        base = mergeValue(base, profiles[active])

    var overrides = isObject(legacyOverrides) ? clone(legacyOverrides) : {}
    if (isObject(overrides)) delete overrides.settingsNavigationCollapsedGroups
    if (legacyRootNavigationOrder !== undefined && overrides.settingsNavigationOrder === undefined)
        overrides.settingsNavigationOrder = legacyRootNavigationOrder
    if (owner) owner.resetOverrides = clone(overrides)
    var reserved = [
        "settingsPersistenceFormat", "profileOverrides", "managedKeys", "managedNestedKeys",
        "settingsNavigationCollapsedGroups", "settingsTabOrder", "settingsNavigationOrder",
        "weatherToken", "profiles", "profileStorageFormat", "activeProfile", "customThemes", "settingsSchemaVersion"
    ]
    // Preserve unrecognized top-level fields from newer app versions. They
    // are passthrough extensions, not part of this version's active schema.
    var extras = {}
    for (var key in stored) {
        if (!Object.prototype.hasOwnProperty.call(stored, key) || reserved.indexOf(key) >= 0) continue
        extras[key] = clone(stored[key])
    }

    var effective = mergeValue(base, overrides)
    effective = mergeValue(effective, extras)
    if (needsTimerOptionsStyleMigration) {
        effective.animationTimerOptionsVisibilityStyle = String(
            effective.animationTimerVisibilityStyle !== undefined
                ? effective.animationTimerVisibilityStyle
                : (defaults.animationTimerOptionsVisibilityStyle || "fade"))
    }
    effective.settingsNavigationCollapsedGroups = clone(navigationGroupState)
    effective.settingsNavigationOrder = normalizeNavigationOrderForOwner(owner, effective.settingsNavigationOrder)
    effective.weatherToken = String(stored.weatherToken || "").trim()
    effective.profiles = profiles
    effective.profileStorageFormat = SPARSE_FORMAT
    effective.activeProfile = active
    effective.customThemes = clone(stored.customThemes || {})
    return effective
}

function captureDefaults(owner) {
    var base = clone(owner.snapshotObject())
    delete base.weatherToken
    return base
}

function rebuildProfileList(owner) {
    var names = Object.keys(owner.profiles || {}).sort(function(a, b) {
        return a.localeCompare(b)
    })
    owner.profileList = names
    owner.profilesRevision++
}

function profileNames(owner) {
    return Array.isArray(owner && owner.profileList) ? owner.profileList.slice() : []
}

// Complete a legacy full snapshot with defaults that did not exist when the
// profile was created. This is intentionally a recursive merge for plain
// objects (module flags, geometry, colors); arrays and scalar values stored by
// the legacy profile remain authoritative and replace the defaults atomically.
function completeLegacySnapshot(defaults, profile) {
    if (!isObject(defaults) || !isObject(profile)) return clone(profile)

    var result = clone(defaults)
    for (var key in profile) {
        if (!Object.prototype.hasOwnProperty.call(profile, key)) continue
        if (isObject(defaults[key]) && isObject(profile[key]))
            result[key] = completeLegacySnapshot(defaults[key], profile[key])
        else
            result[key] = clone(profile[key])
    }
    return result
}

function sparseProfile(owner, fullSnapshot) {
    var full = clone(fullSnapshot || {})
    delete full.weatherToken
    var sparse = diffValue(profileBase(owner), full) || {}

    // Colors are user-facing visual preferences. Keep a complete color map in
    // each saved profile instead of inheriting colors that happen to equal the
    // current release defaults. Otherwise a later release changing a default
    // can silently change an existing profile on its next load.
    if (isObject(full.colors)) {
        sparse.colors = clone(full.colors)
        var colorNames = owner && Array.isArray(owner.colorNames) ? owner.colorNames : []
        for (var i = 0; i < colorNames.length; ++i) {
            var colorName = colorNames[i]
            if (full.colors[colorName] !== undefined)
                sparse.colors[colorName] = String(full.colors[colorName])
        }
    }
    return sparse
}

function sparsifyProfiles(owner, fullProfiles) {
    var result = {}
    for (var name in (fullProfiles || {})) {
        if (!Object.prototype.hasOwnProperty.call(fullProfiles, name)) continue
        setOwn(result, name, sparseProfile(owner, fullProfiles[name]))
    }
    return result
}

function expandProfile(owner, profile) {
    if (!profile || typeof profile !== "object") return null
    var normalizedProfile = clone(profile)
    // Profiles created before v1353 may still contain the flat tab order.
    // Convert it before merging sparse data with the new hierarchical defaults.
    migrateLegacyNavigationOrderObject(owner, normalizedProfile)
    var expanded
    if (owner.profileStorageFormat === SPARSE_FORMAT)
        expanded = mergeValue(profileBase(owner), normalizedProfile)
    else
        expanded = normalizedProfile
    delete expanded.weatherToken
    expanded.settingsNavigationOrder = normalizeNavigationOrderForOwner(owner, expanded.settingsNavigationOrder)
    // Profiles expose only the canonical hierarchy. The former flat array is
    // accepted only by the one-time migration reader and never recreated at runtime.
    delete expanded.settingsTabOrder
    return expanded
}

function expandedProfileByName(owner, name) {
    var key = String(name || owner.activeProfile || "")
    var profile = hasProfile(owner, key) ? owner.profiles[key] : null
    return profile ? expandProfile(owner, profile) : null
}

function updateResetOverrideCache(owner, profileBaseline, currentSnapshot) {
    if (!owner) return
    var current = clone(currentSnapshot || owner.snapshotObject() || {})
    delete current.weatherToken
    var next = diffValue(profileBaseline || {}, current) || {}
    var existing = isObject(owner.resetOverrides) ? owner.resetOverrides : {}
    if (!sameValue(existing, next)) owner.resetOverrides = clone(next)
}

function saveProfile(owner, name) {
    var n = normalizedProfileName(name)
    if (!n) return false
    // Existing legacy names longer than the current limit remain saveable;
    // new names are rejected rather than silently truncated into collisions.
    if (n.length > MAX_PROFILE_NAME_LENGTH && !hasProfile(owner, n)) return false
    var current = owner.snapshotObject()
    var next = copyProfileMap(owner.profiles || {})
    setOwn(next, n, sparseProfile(owner, current))
    owner.profiles = next
    owner.profileStorageFormat = SPARSE_FORMAT
    owner.activeProfile = n
    rebuildProfileList(owner)
    // Hide Save/Reset controls immediately, even if a previous settings write
    // is still in flight and the disk writer has to queue the next snapshot.
    updateResetOverrideCache(owner, expandedProfileByName(owner, n), current)
    owner.save()
    return true
}

function collectChangedPaths(delta, path, output) {
    if (delta === undefined) return
    if (isObject(delta)) {
        var keys = Object.keys(delta)
        if (keys.length === 1 && keys[0] === REPLACE_MARKER) {
            output.push(path.slice())
            return
        }
        if (keys.length === 0) return
        for (var i = 0; i < keys.length; ++i)
            collectChangedPaths(delta[keys[i]], path.concat([keys[i]]), output)
        return
    }
    output.push(path.slice())
}

function startsWithAny(value, prefixes) {
    for (var i = 0; i < prefixes.length; ++i)
        if (String(value).indexOf(prefixes[i]) === 0) return true
    return false
}

function modulePathMatches(path, moduleName) {
    var root = path[0]
    var mapRoots = ["modules", "moduleFrames", "moduleBackgrounds", "moduleBlurEnabled", "moduleMonitors", "geometry"]
    if (mapRoots.indexOf(root) >= 0)
        return path.length > 1 && String(path[1]) === String(moduleName)

    var prefixes = {
        calendar: ["calendar", "animationCalendar"],
        time: ["clock"],
        cpu: ["cpu", "animationCpu"],
        cpuGraph: ["cpuGraph"],
        topAppsCpu: ["topApps"], topAppsRam: ["topApps"],
        networkStat: ["network", "systemMonitor"], networks: ["network", "systemMonitor", "animationNetwork"],
        weatherNow: ["weather", "animationWeather"], weatherHourly: ["weather", "animationWeather"], weatherDaily: ["weather", "animationWeather"],
        timer: ["timer"], volumes: ["volume", "animationVolume"], player: ["player", "animationPlayer"],
        mopidy: ["mopidy", "animationMopidy"], cava: ["cava", "animationCava"], launcher: ["launcher", "animationLauncher"], notifications: ["notifications", "animationNotifications"]
    }[String(moduleName)] || []
    if (String(moduleName) === "cpu" && root === "cpuGraphMode") return false
    return startsWithAny(root, prefixes)
}

function profileSavePathMatches(owner, scope, argument, path) {
    if (!path || !path.length || path[0] === "weatherToken") return false
    var root = String(path[0])
    var child = path.length > 1 ? String(path[1]) : ""

    if (scope === "all") return true
    if (scope === "themes") return root === "activeTheme" || root === "colors"
    if (scope === "colors") {
        if (root !== "colors") return false
        if (path.length < 2) return true
        return Array.isArray(argument) && argument.indexOf(child) >= 0
    }
    if (scope === "modules") {
        if (["modules", "moduleFrames", "moduleBackgrounds", "moduleMonitors", "geometry"].indexOf(root) >= 0)
            return true
        if (root === "notificationsCardWidth") return true
        if (root === "moduleBlurEnabled") return path.length < 2 || child !== "settings"
        return false
    }
    if (scope === "module") return modulePathMatches(path, argument)
    if (scope === "clock") return startsWithAny(root, ["clock"])
    if (scope === "dashboard") return root === "dashboardVisibleCards" || root === "dashboardCardOrder" || root === "dashboardColumnsMode" || root === "dashboardCardSizes" || root === "animationDashboardVisibilityStyle" || root === "animationDashboardVisibilityDuration"
    if (scope === "dashboardModule") {
        if (root === "modules" || root === "moduleFrames" || root === "moduleBackgrounds"
                || root === "moduleBlurEnabled" || root === "moduleMonitors" || root === "geometry")
            return path.length > 1 && child === "dashboard"
        return root === "dashboardVisibleCards" || root === "dashboardCardOrder"
            || root === "dashboardColumnsMode" || root === "dashboardCardSizes"
            || root === "animationDashboardVisibilityStyle" || root === "animationDashboardVisibilityDuration"
    }
    if (scope === "launcher") {
        if (["modules", "moduleFrames", "moduleBackgrounds", "moduleBlurEnabled", "moduleMonitors", "geometry"].indexOf(root) >= 0)
            return path.length < 2 || child === "launcher"
        return startsWithAny(root, ["launcher", "animationLauncher"])
    }
    if (scope === "settingsWindow") {
        if (root === "colors") return path.length < 2 || ["settingsBackground", "settingsBorder"].indexOf(child) >= 0
        if (root === "moduleBlurEnabled") return path.length < 2 || child === "settings"
        return startsWithAny(root, ["settingsGeometry", "settingsMonitorName", "settingsFont", "settingsFontSize", "settingsPadding", "settingsSpacing", "settingsSearchHighlightColor", "settingsSearchHighlightBorderWidth", "settingsSearchMatchCountFontSize", "settingsSearchVisible", "settingsNavigationOrder", "settingsTabLabels", "animationSettings"])
    }
    if (scope === "general")
        return ["font", "fontSize", "ledFont", "frameBorderWidth", "frameRadius", "backgroundBlurRadius"].indexOf(root) >= 0

    if (scope === "cpu" && root === "colors")
        return ["topAppsCpuBarColor", "topAppsCpuBarTrackColor", "topAppsRamBarColor", "topAppsRamBarTrackColor"].indexOf(child) >= 0

    var prefixesByScope = {
        timer: ["timer", "animationTimer"], player: ["player", "animationPlayer"], weather: ["weather", "animationWeather"],
        cava: ["cava", "animationCava"], cpu: ["cpu", "cpuGraph", "topApps", "animationCpu"],
        network: ["network", "systemMonitor", "animationNetwork"], volume: ["volume", "animationVolume"],
        calendar: ["calendar", "animationCalendar"], mopidy: ["mopidy", "animationMopidy"],
        notifications: ["notifications", "animationNotifications"]
    }
    var prefixes = prefixesByScope[scope]
    if (scope === "notifications" && root === "notificationsCardWidth") return false
    if (prefixes) return startsWithAny(root, prefixes)
    return false
}

function currentValueAtPath(value, path) {
    var current = value
    for (var i = 0; i < path.length; ++i) {
        if (current === null || current === undefined) return undefined
        current = current[path[i]]
    }
    return current
}

function assignValueAtPath(target, path, value) {
    if (!path.length) return
    var current = target
    for (var i = 0; i < path.length - 1; ++i) {
        var key = path[i]
        if (!isObject(current[key]) && !Array.isArray(current[key])) current[key] = {}
        current = current[key]
    }
    current[path[path.length - 1]] = clone(value)
}

function expandRootReplacementPaths(owner, scope, argument, path, current, output) {
    if (path.length !== 1) {
        if (profileSavePathMatches(owner, scope, argument, path)) output.push(path)
        return
    }
    var root = path[0]
    var currentMap = current[root]
    var mapRoots = ["modules", "moduleFrames", "moduleBackgrounds", "moduleBlurEnabled", "moduleMonitors", "geometry"]

    if (root === "colors" && (scope === "colors" || scope === "settingsWindow")) {
        var names = scope === "settingsWindow" ? ["settingsBackground", "settingsBorder"] : (Array.isArray(argument) ? argument : [])
        for (var c = 0; c < names.length; ++c)
            if (currentMap && Object.prototype.hasOwnProperty.call(currentMap, names[c])) output.push(["colors", names[c]])
        return
    }
    if (mapRoots.indexOf(root) >= 0) {
        if (scope === "dashboardModule" && currentMap
                && Object.prototype.hasOwnProperty.call(currentMap, "dashboard")) {
            output.push([root, "dashboard"])
            return
        }
        if (scope === "module" && currentMap && Object.prototype.hasOwnProperty.call(currentMap, String(argument))) {
            output.push([root, String(argument)])
            return
        }
        if ((scope === "launcher" || scope === "settingsWindow") && currentMap) {
            var specialKey = scope === "launcher" ? "launcher" : "settings"
            if (Object.prototype.hasOwnProperty.call(currentMap, specialKey)) output.push([root, specialKey])
            return
        }
        if (scope === "modules" && currentMap) {
            var keys = Object.keys(currentMap)
            for (var m = 0; m < keys.length; ++m)
                if (root !== "moduleBlurEnabled" || keys[m] !== "settings") output.push([root, keys[m]])
            return
        }
    }
    if (profileSavePathMatches(owner, scope, argument, path)) output.push(path)
}

// Save only the changed paths belonging to the selected module/section. Other
// unsaved differences remain in the active settings snapshot and stay visible
// through the sparse reset/save cache when owner.save() prepares the next write.
function saveProfileScope(owner, name, scope, argument) {
    var n = normalizedProfileName(name)
    if (!n || !hasProfile(owner, n)) return false
    var current = owner.snapshotObject()
    var base = expandedProfileByName(owner, n) || profileBase(owner)
    var delta = diffValue(base, current) || {}
    var changedPaths = []
    collectChangedPaths(delta, [], changedPaths)
    var selectedPaths = []
    for (var i = 0; i < changedPaths.length; ++i)
        expandRootReplacementPaths(owner, String(scope || ""), argument, changedPaths[i], current, selectedPaths)

    // A scoped Save action is intentionally a no-op when the section has no
    // changed paths; it must never silently save the entire profile as fallback.
    if (!selectedPaths.length) return false

    var updatedFullProfile = clone(base)
    for (var p = 0; p < selectedPaths.length; ++p) {
        var selectedPath = selectedPaths[p]
        assignValueAtPath(updatedFullProfile, selectedPath, currentValueAtPath(current, selectedPath))
    }

    var next = copyProfileMap(owner.profiles || {})
    setOwn(next, n, sparseProfile(owner, updatedFullProfile))
    owner.profiles = next
    owner.profileStorageFormat = SPARSE_FORMAT
    owner.activeProfile = n
    rebuildProfileList(owner)
    updateResetOverrideCache(owner, expandedProfileByName(owner, n), current)
    owner.save()
    return true
}

function loadProfile(owner, name) {
    var n = normalizedProfileName(name)
    var profile = hasProfile(owner, n) ? owner.profiles[n] : null
    if (!profile) return false
    var expanded = expandProfile(owner, profile)
    if (!expanded) return false
    owner.applyObject(clone(expanded))
    owner.activeProfile = n
    owner.profileStorageFormat = SPARSE_FORMAT
    rebuildProfileList(owner)
    owner.save()
    return true
}

function deleteProfile(owner, name) {
    var n = normalizedProfileName(name)
    if (!hasProfile(owner, n)) return false
    var next = copyProfileMap(owner.profiles)
    delete next[n]
    owner.profiles = next
    if (owner.activeProfile === n) owner.activeProfile = ""
    rebuildProfileList(owner)
    owner.save()
    return true
}


// Keep profiles valid when a referenced custom theme is renamed or deleted.
// Saved color values remain profile-scoped, while the custom theme catalog is
// global; a deleted theme therefore falls back to an exact matching palette
// when possible, or the default theme while retaining the saved colors.
function rewriteThemeReferences(owner, themes, oldName, newName) {
    var current = owner.profiles || {}
    var next = copyProfileMap(current)
    var changed = false
    var candidateNames = (themes && themes.builtinThemeNames ? themes.builtinThemeNames.slice() : [])
    Object.keys(owner.customThemes || {}).sort(function(a, b) { return a.localeCompare(b) }).forEach(function(name) {
        if (candidateNames.indexOf(name) < 0) candidateNames.push(name)
    })
    var colorNames = owner && Array.isArray(owner.themeManagedColorNames)
        ? owner.themeManagedColorNames
        : (owner.colorNames || []).filter(function(key) {
            return ["settingsBackground", "playerProgressTrack", "playerProgressFill",
                "topAppsCpuBarColor", "topAppsRamBarColor", "topAppsCpuBarTrackColor", "topAppsRamBarTrackColor"].indexOf(key) < 0
        })

    function matchingTheme(profile) {
        var colors = profile && profile.colors ? profile.colors : {}
        for (var i = 0; i < candidateNames.length; ++i) {
            var candidate = candidateNames[i]
            var palette = themes.palette(candidate, owner.customThemes)
            var matches = true
            for (var j = 0; j < colorNames.length; ++j) {
                var key = colorNames[j]
                if (colors[key] === undefined) continue
                if (String(colors[key]) !== String(palette[key] !== undefined ? palette[key] : "")) {
                    matches = false
                    break
                }
            }
            if (matches) return candidate
        }
        return candidateNames.indexOf("14 Theme") >= 0 ? "14 Theme" : (candidateNames[0] || "14 Theme")
    }

    Object.keys(current).forEach(function(name) {
        var full = expandProfile(owner, current[name])
        if (!full || String(full.activeTheme || "") !== String(oldName)) return
        full.activeTheme = newName ? String(newName) : matchingTheme(full)
        setOwn(next, name, owner.profileStorageFormat === SPARSE_FORMAT ? sparseProfile(owner, full) : full)
        changed = true
    })

    if (changed) owner.profiles = next
    return changed
}

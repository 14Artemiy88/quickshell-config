pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "js/settings/SettingsDefaults.js" as SettingsDefaults
import "js/settings/SettingsThemes.js" as SettingsThemes
import "js/settings/SettingsProfiles.js" as SettingsProfiles
import "js/settings/SettingsResets.js" as SettingsResets
import "js/settings/SettingsPersistence.js" as SettingsPersistence
import "js/settings/SettingsThemeManager.js" as SettingsThemeManager
import "js/settings/SettingsTimerPresets.js" as SettingsTimerPresets
import "js/settings/SettingsLauncherProjects.js" as SettingsLauncherProjects
import "js/settings/SettingsGeometry.js" as SettingsGeometry
import "js/settings/SettingsApply.js" as SettingsApply
import "js/settings/SettingsMetadata.js" as SettingsMetadata
import "."

QtObject {
    id: root
    property bool loaded: false
    property string weatherToken: ""
    // Last weather token confirmed by disk load or a successful settings write.
    // Full UI snapshots use this baseline to avoid overwriting a newer CLI update.
    property string persistedWeatherToken: ""
    property var timerPresets: [5, 7, 15]
    property var timerPresetDefaults: [5, 7, 15]
    property bool time: true
    property bool cpu: true
    property bool cpuGraph: true
    property bool topAppsCpu: true
    property bool topAppsRam: true
    property bool networkStat: true
    property bool weatherNow: true
    property bool weatherHourly: true
    property bool weatherDaily: true
    property bool timer: true
    property bool volumes: true
    property bool player: true
    property bool mopidy: false
    property bool cava: true
    property bool networks: true
    property bool calendar: true
    property var moduleFrames: ({time:true, calendar:true, cpu:true, cpuGraph:true, topAppsCpu:true, topAppsRam:true, networkStat:true, weatherNow:true, weatherHourly:true, weatherDaily:true, timer:true, volumes:true, player:true, mopidy:false, cava:true, networks:true, launcher:true})
    property var moduleMonitors: ({})
    property var moduleBackgrounds: ({time:true, calendar:true, cpu:true, cpuGraph:true, topAppsCpu:true, topAppsRam:true, networkStat:true, weatherNow:true, weatherHourly:true, weatherDaily:true, timer:true, volumes:true, player:true, mopidy:false, cava:true, networks:true, launcher:true})
    property var moduleBlurEnabled: ({time:false, calendar:false, cpu:false, cpuGraph:false, topAppsCpu:false, topAppsRam:false, networkStat:false, weatherNow:false, weatherHourly:false, weatherDaily:false, timer:false, volumes:false, player:false, mopidy:false, cava:false, networks:false, launcher:false, settings:false})
    // Temporary geometry used while dragging modules in layout-edit mode.
    // It is never persisted until the mouse button is released.
    property var layoutEditGeometry: ({})

    property var geometry: ({
        time: [3,5,315,55], cpu: [5,65,315,170], cpuGraph: [5,235,315,82],
        topAppsCpu: [5,322,315,96], topAppsRam: [5,423,315,96], networkStat: [5,526,313,55], weatherNow: [3,585,315,80],
        weatherHourly: [3,665,335,125], weatherDaily: [3,795,325,125], timer: [3,930,315,145],
        timerOptions: [325,888,90,95], calendar: [5,65,315,285], volumes: [331,72,275,210],
        player: [330,405,300,320], mopidy: [330,865,300,150], cava: [325,578,300,80], networks: [331,675,300,180], launcher: [-999999,-999999,720,640]
    })
    // Geometry of the settings window itself: X, Y, Width, Height.
    property var settingsGeometry: [640, 40, 560, 850]
    property string settingsMonitorName: Config.monitorName
    property var settingsGeometryDragStart: [640, 40, 560, 850]
    // Named configuration profiles (first feature outside the original layout).
    property var profiles: ({})
    property var profileList: []
    property string activeProfile: ""
    property int profilesRevision: 0
    // Profiles store deltas relative to this immutable startup baseline.
    property var profileDefaults: ({})
    property string profileStorageFormat: "sparse-v1"
    property bool profileMigrationPending: false
    property var customThemes: ({})
    property string activeTheme: "14 Theme"
    property var themeDraft: ({})
    property string themeDraftSource: ""
    property int themeDraftRevision: 0
    property int themeStateRevision: 0
    readonly property bool currentThemeModified: {
        var revision = themeStateRevision
        var currentName = activeTheme
        return SettingsThemeManager.isCurrentThemeModified(root, SettingsThemes, colorNames, Config)
    }
    readonly property var moduleNames: SettingsMetadata.moduleNames
    readonly property var moduleLabels: SettingsMetadata.moduleLabels
    readonly property var colorNames: SettingsMetadata.colorNames
    // Built-in defaults used by the reset controls in the settings UI.
    // These values are intentionally taken from the current settings.json baseline.
    readonly property var defaultConfig: SettingsDefaults.defaultConfig
    readonly property string defaultWeatherToken: SettingsMetadata.defaultWeatherToken
    readonly property var defaultTimerPresetDefaults: SettingsMetadata.defaultTimerPresetDefaults
    readonly property var defaultGeometry: SettingsMetadata.defaultGeometry
    readonly property var defaultSettingsGeometry: SettingsMetadata.defaultSettingsGeometry
    readonly property var defaultModules: SettingsMetadata.defaultModules
    readonly property var defaultModuleFrames: SettingsMetadata.defaultModuleFrames
    readonly property var defaultModuleBackgrounds: SettingsMetadata.defaultModuleBackgrounds
    readonly property var defaultModuleBlurEnabled: SettingsMetadata.defaultModuleBlurEnabled
    readonly property var defaultModuleMonitors: SettingsMetadata.defaultModuleMonitors
    signal changed()
    signal saved()
    signal resetUnavailable(string message)

    function applyObject(o) { return SettingsApply.applyObject(root, Config, o, moduleNames, defaultModuleFrames, defaultModuleBackgrounds, colorNames, defaultModuleBlurEnabled) }
    function setModuleBlurEnabled(moduleName, enabled) {
        var values = Object.assign({}, root.moduleBlurEnabled || {})
        values[String(moduleName)] = !!enabled
        root.moduleBlurEnabled = values
        if (String(moduleName) === "player") Config.playerBlurEnabled = !!enabled
        root.save()
    }

    property var loader: null
    property var writer: null
    property bool pendingWriteRequested: false

    function flushPendingWrite() {
        if (!root.loaded || !root.pendingWriteRequested || !root.writer || root.writer.running)
            return
        // Defer until the current QML property-change stack has settled. If a
        // newer save starts first, it captures the current complete snapshot.
        Qt.callLater(function() {
            SettingsPersistence.flushPendingWrite(root, Config)
        })
    }

    onLoadedChanged: {
        if (root.loaded)
            root.flushPendingWrite()
    }

    property Component loaderComponent: Component {
        Process {
            command: [Quickshell.shellDir + "/scripts/settings", "get"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        root.applyObject(JSON.parse(this.text))
                        root.persistedWeatherToken = String(root.weatherToken || "").trim()
                        if (root.profileMigrationPending) {
                            root.profileMigrationPending = false
                            Qt.callLater(function() { root.save() })
                        }
                    } catch (e) {
                        root.persistedWeatherToken = String(root.weatherToken || "").trim()
                        root.loaded = true
                        root.changed()
                    }
                }
            }
        }
    }

    property Component writerComponent: Component {
        Process {
            id: writeProc
            property string payload: "{}"
            property string commandMode: "set-json-ui"
            property string tokenBaseline: ""
            property string tokenRequested: ""
            property string tokenResult: ""
            property bool tokenOutputFinished: false
            property bool processExited: false
            property int writerExitCode: -1
            command: [Quickshell.shellDir + "/scripts/settings", commandMode, payload, tokenBaseline]
            function finalizeWriteIfReady() {
                if (!writeProc.processExited || !writeProc.tokenOutputFinished)
                    return
                if (writeProc.writerExitCode === 0 && writeProc.commandMode === "set-json-ui") {
                    var committedToken = String(writeProc.tokenResult || "").trim()
                    var requestedToken = String(writeProc.tokenRequested || "").trim()
                    // Reconcile the token returned by disk only if the user has
                    // not edited the field again while this write was in flight.
                    if (String(root.weatherToken || "").trim() === requestedToken)
                        root.weatherToken = committedToken
                    root.persistedWeatherToken = committedToken
                }
                writeProc.processExited = false
                writeProc.tokenOutputFinished = false
                writeProc.writerExitCode = -1
                if (root.pendingWriteRequested)
                    root.flushPendingWrite()
            }
            stdout: StdioCollector {
                onStreamFinished: {
                    writeProc.tokenResult = this.text
                    writeProc.tokenOutputFinished = true
                    writeProc.finalizeWriteIfReady()
                }
            }
            onExited: function(exitCode) {
                writeProc.writerExitCode = exitCode
                writeProc.processExited = true
                writeProc.finalizeWriteIfReady()
            }
        }
    }

    Component.onCompleted: {
        // Capture QML's actual initial defaults before loading user settings.
        profileDefaults = SettingsProfiles.captureDefaults(root)
        writer = writerComponent.createObject(root)
        loader = loaderComponent.createObject(root)
    }

    function geometryForLayout(moduleName) { return SettingsGeometry.geometryForLayout(root, moduleName) }

    function beginGeometryDrag(moduleName) { SettingsGeometry.beginGeometryDrag(root, moduleName) }

    function updateGeometryDrag(moduleName, x, y) { SettingsGeometry.updateGeometryDrag(root, moduleName, x, y) }

    function endGeometryDrag(moduleName, monitorName, x, y) { SettingsGeometry.endGeometryDrag(root, moduleName, monitorName, x, y) }

    function cancelGeometryDrag(moduleName) { SettingsGeometry.cancelGeometryDrag(root, moduleName) }

    function adjustGeometry(moduleName, index, delta) { SettingsGeometry.adjustGeometry(root, moduleName, index, delta) }

    function adjustSettingsGeometry(index, delta) { SettingsGeometry.adjustSettingsGeometry(root, index, delta) }

    function beginSettingsGeometryDrag() { SettingsGeometry.beginSettingsGeometryDrag(root) }

    function updateSettingsGeometryDrag(newX, newY, monitorName) { SettingsGeometry.updateSettingsGeometryDrag(root, newX, newY, monitorName) }

    function endSettingsGeometryDrag(monitorName, x, y) { SettingsGeometry.endSettingsGeometryDrag(root, monitorName, x, y) }

    function updateTimerPreset(index, value) {
        SettingsTimerPresets.updateTimerPreset(root, index, value)
    }

    function setTimerPresetDefault(index, value) {
        SettingsTimerPresets.setTimerPresetDefault(root, index, value)
    }

    function adjustTimerPreset(index, delta) {
        SettingsTimerPresets.adjustTimerPreset(root, index, delta)
    }

    function adjustTimerPresetDefault(index, delta) {
        SettingsTimerPresets.adjustTimerPresetDefault(root, index, delta)
    }

    function resetTimerPreset(index) {
        SettingsTimerPresets.resetTimerPreset(root, index)
    }

    function addTimerPreset(value) {
        SettingsTimerPresets.addTimerPreset(root, value)
    }

    function removeTimerPreset(index) {
        SettingsTimerPresets.removeTimerPreset(root, index)
    }

    function updateLauncherProject(index, field, value) {
        Config.launcherProjects = SettingsLauncherProjects.update(Config.launcherProjects, index, field, value)
        root.save()
    }

    function addLauncherProject() {
        Config.launcherProjects = SettingsLauncherProjects.add(Config.launcherProjects)
        root.save()
    }

    function removeLauncherProject(index) {
        Config.launcherProjects = SettingsLauncherProjects.remove(Config.launcherProjects, index)
        root.save()
    }

    function moveLauncherProject(index, delta) {
        Config.launcherProjects = SettingsLauncherProjects.move(Config.launcherProjects, index, delta)
        root.save()
    }

    function resetConfigKeys(names) { SettingsResets.resetConfigKeys(root, Config, names) }

    function activeProfileData() { return SettingsResets.activeProfileData(root) }

    function expandedProfileData(name) { return SettingsProfiles.expandedProfileByName(root, name) }

    function applyConfigKeysFromProfile(profile, names) { SettingsResets.applyConfigKeysFromProfile(root, Config, profile, names) }

    function resetColorsFromProfile(names) { SettingsResets.resetColorsFromProfile(root, Config, names, SettingsThemes, colorNames) }

    function resetSettingsWindowFromProfile() { SettingsResets.resetSettingsWindowFromProfile(root, Config) }

    function resetModule(moduleName) { SettingsResets.resetModule(root, Config, moduleName) }

    function resetModules() { SettingsResets.resetModules(root, Config) }

    function resetColors(names) { SettingsResets.resetColors(root, Config, names, SettingsThemes, colorNames) }

    function resetCpuSettings() { SettingsResets.resetCpuSettings(root, Config) }

    function resetNetworkSettings() { SettingsResets.resetNetworkSettings(root, Config) }

    function resetVolumeSettings() { SettingsResets.resetVolumeSettings(root, Config) }

    function resetTimerSettings() { SettingsResets.resetTimerSettings(root, Config) }

    function resetPlayerSettings() { SettingsResets.resetPlayerSettings(root, Config) }
    function resetMopidySettings() { SettingsResets.resetMopidySettings(root, Config) }

    function resetWeatherSettings() { SettingsResets.resetWeatherSettings(root, Config) }

    function resetCalendarSettings() { SettingsResets.resetCalendarSettings(root, Config) }

    function resetCavaSettings() { SettingsResets.resetCavaSettings(root, Config) }

    function resetGeneralSettings() { SettingsResets.resetGeneralSettings(root, Config) }

    function resetAnimationSettings() { SettingsResets.resetAnimationSettings(root, Config) }

    function resetSettingsWindow() { SettingsResets.resetSettingsWindow(root, Config) }

    function resetLauncherSettings() { SettingsResets.resetLauncherSettings(root, Config) }

    function resetAllSettings() { SettingsResets.resetAllSettings(root, SettingsThemes, colorNames) }

    function snapshotObject() { return SettingsPersistence.snapshotObject(root, Config) }

    function save() { return SettingsPersistence.save(root, Config) }

    function rebuildProfileList() {
        SettingsProfiles.rebuildProfileList(root)
    }

    function profileNames() {
        return SettingsProfiles.profileNames(root)
    }

    readonly property var builtinThemeNames: SettingsThemes.builtinThemeNames
    readonly property var themeNames: builtinThemeNames.concat(Object.keys(customThemes || {}).sort(function(a, b) { return a.localeCompare(b) }))

    function themePalette(name) { return SettingsThemeManager.palette(root, SettingsThemes, name) }

    function currentThemeColors() { return SettingsThemeManager.currentThemeColors(root, colorNames, Config) }

    function isCurrentThemeModified() { return currentThemeModified }

    function bumpThemeStateRevision() { themeStateRevision++ }

    function saveCurrentTheme(name) { return SettingsThemeManager.saveCurrentTheme(root, colorNames, Config, name) }

    function applyTheme(name) { SettingsThemeManager.applyTheme(root, SettingsThemes, Config, name) }

    function themePreview(name) { return SettingsThemeManager.preview(root, SettingsThemes, name) }

    function themeDescription(name) { return SettingsThemeManager.description(SettingsThemes, name) }

    function isCustomTheme(name) { return SettingsThemeManager.isCustomTheme(root, name) }

    function beginThemeEdit(name) { SettingsThemeManager.beginThemeEdit(root, SettingsThemes, name) }

    function themeDraftValue(name) { return SettingsThemeManager.themeDraftValue(root, Config, name) }

    function setThemeDraftColor(name, value) { return SettingsThemeManager.setThemeDraftColor(root, name, value) }

    function saveCustomTheme(name) { return SettingsThemeManager.saveCustomTheme(root, SettingsThemes, Config, name) }

    function deleteCustomTheme(name) { return SettingsThemeManager.deleteCustomTheme(root, SettingsThemes, Config, name) }

    function renameCustomTheme(oldName, newName) { return SettingsThemeManager.renameCustomTheme(root, SettingsThemes, Config, oldName, newName) }

    function saveProfile(name) {
        return SettingsProfiles.saveProfile(root, name)
    }

    function loadProfile(name) {
        return SettingsProfiles.loadProfile(root, name)
    }

    function deleteProfile(name) {
        return SettingsProfiles.deleteProfile(root, name)
    }

}

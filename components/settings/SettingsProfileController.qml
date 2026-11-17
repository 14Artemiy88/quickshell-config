import QtQuick

// Owns the settings UI's profile model and action facade. Settings.qml and
// SettingsProfiles.js remain the source of truth for profile data, sparse
// overrides, migrations and persistence; this component only centralizes the
// UI-facing model and guards/actions used by settings pages.
Item {
    id: root

    property var settings: Settings
    property alias profileModel: profileEntries

    readonly property string activeProfileName: settings && settings.activeProfile
        ? String(settings.activeProfile) : ""
    readonly property bool hasActiveProfile: {
        var name = root.activeProfileName
        return name.length > 0 && settings && settings.profiles
            && settings.profiles[name] !== undefined
    }

    visible: false
    width: 0
    height: 0

    ListModel {
        id: profileEntries
    }

    function profileNames() {
        return settings && typeof settings.profileNames === "function"
            ? settings.profileNames() : []
    }

    function refreshProfileModel() {
        profileEntries.clear()
        var names = root.profileNames()
        for (var i = 0; i < names.length; ++i)
            profileEntries.append({ name: String(names[i]) })
    }

    function indexOfProfile(name) {
        var wanted = String(name || "")
        for (var i = 0; i < profileEntries.count; ++i) {
            if (String(profileEntries.get(i).name) === wanted)
                return i
        }
        return -1
    }

    function canSaveScope(scope, argument) {
        var key = String(scope || "")
        return root.hasActiveProfile && key.length > 0
            && settings.hasResetChanges(key, argument)
    }

    function canResetScope(scope, argument) {
        var key = String(scope || "")
        return root.hasActiveProfile && key.length > 0
            && settings.hasResetChanges(key, argument)
    }

    function saveProfile(name) {
        return !!settings && settings.saveProfile(String(name || ""))
    }

    function saveAll() {
        return root.hasActiveProfile && root.saveProfile(root.activeProfileName)
    }

    function saveScope(scope, argument) {
        if (!root.canSaveScope(scope, argument)) return false
        return settings.saveProfileScope(root.activeProfileName, String(scope), argument)
    }

    function loadProfile(name) {
        var key = String(name || "").trim()
        return key.length > 0 && !!settings && settings.loadProfile(key)
    }

    function deleteProfile(name) {
        var key = String(name || "").trim()
        return key.length > 0 && !!settings && settings.deleteProfile(key)
    }

    Connections {
        target: root.settings
        function onProfilesRevisionChanged() { root.refreshProfileModel() }
    }

    Component.onCompleted: root.refreshProfileModel()
}

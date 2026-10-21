.pragma library

.import "SettingsApplyCore.js" as Core
.import "SettingsApplyBehaviour.js" as Behaviour
.import "SettingsApplySystemVisual.js" as SystemVisual
.import "SettingsApplyTimerPlayer.js" as TimerPlayer
.import "SettingsApplyWeather.js" as Weather
.import "SettingsApplyState.js" as State

function applyObject(owner, Config, o, moduleNames, defaultModuleFrames, defaultModuleBackgrounds, colorNames) {
    if (!o) return

    var legacyTimerIconOrder = Core.apply(owner, Config, o)
    Behaviour.apply(Config, o)
    SystemVisual.apply(Config, o)
    TimerPlayer.apply(Config, o, legacyTimerIconOrder)
    Weather.apply(Config, o)
    State.apply(owner, Config, o, moduleNames, defaultModuleFrames, defaultModuleBackgrounds, colorNames)
}

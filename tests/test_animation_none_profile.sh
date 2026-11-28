#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
def read(path): return (root / path).read_text(encoding="utf-8")

config = read("Config.qml")
curves = read("js/AnimationCurves.js")
primitive = read("components/settings/primitives/SettingsAnimationGroup.qml")
apply = read("js/settings/SettingsApplyBehaviour.js")
defaults = read("js/settings/SettingsDefaults.js")
shell = read("shell.qml")
timer_options = read("components/TimerOptions.qml")

# The common animation settings primitive exposes the explicit no-motion option.
assert 'property var profileValues: ["none", "linear", "ease", "ease-in", "ease-out", "ease-in-out", "cubic-bezier"]' in primitive
assert 'property string profileLabel: "Функция сглаживания"' in primitive
assert 'root.profileEdited("cubic-bezier(0.25, 0.10, 0.25, 1.00)")' in primitive
assert '"Без анимации"' in primitive
assert 'text: root.normalizedProfile === "none"' in primitive
assert 'visible: root.profile !== "none" || normalizedProgress > 0.001' in primitive
assert 'progress: root.profile !== "none" ? 1 : 0' in primitive
assert 'animationDuration: root.profile === "none" ? 0 : Config.animationDuration(180, "appearance")' in primitive
assert 'animationEasing: Config.animationEasingType("ease-out", root.profile !== "none" ? "enter" : "exit")' in primitive
assert primitive.index('SettingsGroup {') < primitive.index('MorphGeometry {')
assert 'SettingsCheckBox {' not in primitive
assert 'animationEnabledEdited' not in primitive
assert "Анимация внутренних переходов отключена" in primitive

# All four module profile loaders accept the option; legacy defaults remain unchanged.
for key in ("animationMopidyMorphProfile", "animationPlayerMorphProfile", "animationWeatherMorphProfile", "animationTimerMorphProfile"):
    assert f'{key}: "ease-in-out"' in defaults
    assert f'applyMorphProfile(Config, o, "{key}")' in apply

# No-animation has a central effective-duration gate and a neutral easing fallback.
# Legacy master flags are migration-only and are absent from future snapshots.
assert 'function animationProfileIsEnabled(enabled, profile)' in config
assert 'AnimationCurves.normalizeProfile(profile) !== "none"' in config
assert 'function normalizeAnimationProfile(profile)' in config
assert 'function animationDurationForProfile(enabled, profile, baseMs, category)' in config
assert 'return animationProfileIsEnabled(enabled, profile) ? animationDuration(baseMs, category) : 0' in config
persistence = read("js/settings/SettingsPersistence.js")
for legacy_key in ("animationMopidyMorphEnabled", "animationPlayerMorphEnabled", "animationWeatherMorphEnabled", "animationTimerMorphEnabled"):
    assert f'{legacy_key}: config.{legacy_key}' not in persistence
    assert f'"{legacy_key}"' in persistence[persistence.index("var managedKeys"):]
apply = read("js/settings/SettingsApplyBehaviour.js")
for module in ("Mopidy", "Player", "Weather", "Timer"):
    key = f"legacy{module}MorphEnabled"
    profile_key = f"animation{module}MorphProfile"
    assert f'var {key} = o.animation{module}MorphEnabled' in apply
    assert f'if ({key} === false)' in apply
    assert f'Config.{profile_key} = "none"' in apply
resets = read("js/settings/SettingsResets.js")
assert 'if (profile[enabledKey] === false)' in resets and 'config[profileKey] = "none"' in resets
assert 'name === "none" || name === "linear" || name === ""' in config
assert 'if (name === "none" || name === "linear") return []' in curves
assert 'function normalizeProfile(profile)' in curves

# All internal transitions in the four modules use the no-animation gate.
mopidy_files = [
    "components/mopidy/Mopidy.qml",
    "components/mopidy/MopidyQueueTrackRow.qml",
    "components/mopidy/MopidyLibraryView.qml",
    "components/mopidy/MopidyPlaylistDialog.qml",
    "components/mopidy/MopidyTopPanel.qml",
    "components/mopidy/MopidyFileBrowser.qml",
]
assert sum(read(name).count("animationDuration: Config.animationDurationForProfile(") for name in mopidy_files) == 9
player = read("components/Player.qml")
assert player.count("animationDuration: Config.animationDurationForProfile(") == 3
weather_now = read("components/WeatherNow.qml")
weather_placeholder = read("components/WeatherPlaceholder.qml")
weather_forecast = read("components/WeatherForecastItem.qml")
weather_list = read("components/WeatherList.qml")
assert weather_now.count("animationDuration: Config.animationDurationForProfile(") == 3
assert "animationDuration: Config.animationDurationForProfile(" in weather_placeholder
assert "readonly property int forecastMorphDuration: Config.animationDurationForProfile(" in weather_forecast
assert "readonly property int hourlyMorphDuration: Config.animationDurationForProfile(" in weather_list
assert "duration: root.hourly ? root.hourlyMorphDuration : 0" in weather_list
assert "animationDuration: root.hourly ? root.hourlyMorphDuration : 0" in weather_list

timer = read("components/TimerWidget.qml")
assert "readonly property int timerRowMorphDuration: Config.animationDurationForProfile(" in timer
assert timer.count("Config.animationProfileIsEnabled(Config.animationTimerMorphEnabled, Config.animationTimerMorphProfile)") >= 2
assert "animationStyle: Config.animationTimerVisibilityStyle" in timer
assert "animationProfile: Config.animationTimerVisibilityProfile" in timer

# The module-level appearance transitions and Timer Options popup remain separately controlled.
assert "animationStyle: Config.animationMopidyVisibilityStyle" in shell
assert "Config.animationTimerOptionsVisibilityStyle" in timer_options
assert "Config.animationTimerOptionsDuration" in timer_options
print("No-animation profile: shared UI, four-module validation, duration gating, immediate transitions and independent module/options visibility: OK")
PY
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
const config = fs.readFileSync(root + '/Config.qml', 'utf8');
const curvesSource = fs.readFileSync(root + '/js/AnimationCurves.js', 'utf8').replace(/^\.pragma library\s*/m, '');
function extractFunction(source, name) {
  const marker = `function ${name}(`;
  const start = source.indexOf(marker);
  if (start < 0) throw new Error(`missing ${name}`);
  const open = source.indexOf('{', start);
  let depth = 0, quote = null, escaped = false;
  for (let i = open; i < source.length; i++) {
    const c = source[i];
    if (quote) {
      if (escaped) escaped = false;
      else if (c === '\\') escaped = true;
      else if (c === quote) quote = null;
      continue;
    }
    if (c === '"' || c === "'") { quote = c; continue; }
    if (c === '{') depth++;
    else if (c === '}' && --depth === 0) return source.slice(start, i + 1);
  }
  throw new Error(`unclosed ${name}`);
}
const easing = { Linear: 0, BezierSpline: 1, InCubic: 2, OutCubic: 3, InQuad: 4, OutQuad: 5 };
const curveLibrary = {};
vm.createContext(curveLibrary);
vm.runInContext(curvesSource, curveLibrary);
const extracted = [
  'animationDuration', 'animationProfileIsEnabled', 'animationDurationForProfile', 'animationEasingType'
].map(name => extractFunction(config, name)).join('\n');
const context = { Easing: easing, AnimationCurves: curveLibrary };
vm.createContext(context);
vm.runInContext(extracted, context);
if (context.animationDurationForProfile(true, 'none', 450, 'appearance') !== 0) throw new Error('none must force zero duration');
if (context.animationDurationForProfile(true, 'expressive', 450, 'appearance') !== 450) throw new Error('Expressive duration changed');
if (context.animationDurationForProfile(false, 'standard', 450, 'appearance') !== 0) throw new Error('master toggle must still disable motion');
if (context.animationProfileIsEnabled(true, 'none')) throw new Error('none profile must be inactive');
if (context.animationEasingType('none', 'exit') !== easing.Linear) throw new Error('none easing must be linear/immediate');
const curveContext = {};
vm.createContext(curveContext);
vm.runInContext(curvesSource, curveContext);
if (curveContext.forProfile('none', 'enter').length !== 0) throw new Error('none must not expose a motion curve');
console.log('No-animation profile runtime helpers: zero duration, unchanged active profiles, master toggle and no curve: OK');
JS
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
function extractFunction(source, name) {
  const marker = `function ${name}(`;
  const start = source.indexOf(marker);
  if (start < 0) throw new Error(`missing ${name}`);
  const open = source.indexOf('{', start);
  let depth = 0, quote = null, escaped = false;
  for (let i = open; i < source.length; i++) {
    const c = source[i];
    if (quote) {
      if (escaped) escaped = false;
      else if (c === '\\') escaped = true;
      else if (c === quote) quote = null;
      continue;
    }
    if (c === '"' || c === "'") { quote = c; continue; }
    if (c === '{') depth++;
    else if (c === '}' && --depth === 0) return source.slice(start, i + 1);
  }
  throw new Error(`unclosed ${name}`);
}
const applySource = fs.readFileSync(root + '/js/settings/SettingsApplyBehaviour.js', 'utf8');
const applyBody = extractFunction(applySource, 'apply');
const applyMorphHelper = extractFunction(applySource, 'applyMorphProfile');
const applyContext = {};
vm.createContext(applyContext);
vm.runInContext(applyMorphHelper + '\n' + applyBody, applyContext);
const legacyConfig = { normalizeAnimationProfile: value => {
  const aliases = {standard:'ease-out', spatial:'ease-out', effects:'ease-in', expressive:'ease-in-out'};
  return aliases[String(value)] || String(value);
} };
applyContext.apply(legacyConfig, {
  animationMopidyMorphEnabled: false, animationMopidyMorphProfile: 'standard',
  animationPlayerMorphEnabled: false, animationPlayerMorphProfile: 'effects',
  animationWeatherMorphEnabled: false, animationWeatherMorphProfile: 'expressive',
  animationTimerMorphEnabled: false, animationTimerMorphProfile: 'spatial'
});
for (const name of ['Mopidy', 'Player', 'Weather', 'Timer']) {
  if (legacyConfig[`animation${name}MorphProfile`] !== 'none')
    throw new Error(`${name}: legacy disabled value was not migrated to none`);
  if (legacyConfig[`animation${name}MorphEnabled`] !== true)
    throw new Error(`${name}: hidden compatibility flag was not normalized`);
}

const resetSource = fs.readFileSync(root + '/js/settings/SettingsResets.js', 'utf8');
const resetBody = extractFunction(resetSource, 'applyConfigKeysFromProfile');
const resetContext = {};
vm.createContext(resetContext);
vm.runInContext(resetBody, resetContext);
resetContext.config = { animationTimerMorphEnabled: true, animationTimerMorphProfile: 'expressive' };
resetContext.profile = {
  animationTimerMorphEnabled: false,
  animationTimerMorphProfile: 'standard'
};
vm.runInContext('applyConfigKeysFromProfile({}, config, profile, ["animationTimerMorphEnabled", "animationTimerMorphProfile"])', resetContext);
if (resetContext.config.animationTimerMorphProfile !== 'none' || resetContext.config.animationTimerMorphEnabled !== true)
  throw new Error('Timer reset did not migrate legacy false to none');

const curvesSourceForProfiles = fs.readFileSync(root + '/js/AnimationCurves.js', 'utf8').replace(/^\.pragma library\s*/m, '');
const curveLibrary = {};
vm.createContext(curveLibrary);
vm.runInContext(curvesSourceForProfiles, curveLibrary);
const profilesSource = fs.readFileSync(root + '/js/settings/SettingsProfiles.js', 'utf8').replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/m, '');
const profilesContext = { AnimationCurves: curveLibrary };
vm.createContext(profilesContext);
vm.runInContext(profilesSource, profilesContext);
const owner = {
  profileDefaults: {
    animationMopidyMorphProfile: 'expressive',
    animationPlayerMorphProfile: 'expressive',
    animationWeatherMorphProfile: 'expressive',
    animationTimerMorphProfile: 'expressive',
    animationMopidyMorphDuration: 180,
    animationPlayerMorphDuration: 180,
    animationWeatherMorphDuration: 180,
    animationTimerMorphDuration: 220
  },
  colorNames: []
};
const stored = {
  settingsPersistenceFormat: 'profile-overrides-v1',
  settingsSchemaVersion: 1,
  profileStorageFormat: 'sparse-v1',
  activeProfile: 'Legacy',
  profiles: {
    Legacy: {
      animationMopidyMorphEnabled: false,
      animationMopidyMorphProfile: 'standard',
      animationPlayerMorphEnabled: false,
      animationPlayerMorphProfile: 'effects',
      animationWeatherMorphEnabled: false,
      animationWeatherMorphProfile: 'expressive',
      animationTimerMorphEnabled: false,
      animationTimerMorphProfile: 'spatial',
      animationTimerMorphDuration: 640
    }
  },
  profileOverrides: {},
  customThemes: {}
};
const expanded = profilesContext.expandStoredSettings(owner, stored);
const migratedTimerProfile = expanded.profiles.Legacy;
for (const name of ['Mopidy', 'Player', 'Weather', 'Timer']) {
  if (migratedTimerProfile[`animation${name}MorphProfile`] !== 'none')
    throw new Error(`${name}: stored profile did not convert legacy false to none`);
  if (Object.prototype.hasOwnProperty.call(migratedTimerProfile, `animation${name}MorphEnabled`))
    throw new Error(`${name}: stored profile retained the obsolete enabled key`);
}
if (migratedTimerProfile.animationTimerMorphDuration !== 640)
  throw new Error('Stored profile normalization lost the saved duration');
console.log('Legacy profile migration: disabled flags map to none on load/reset and are removed from normalized profiles: OK');
JS

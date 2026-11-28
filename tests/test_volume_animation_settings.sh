#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
need() { grep -Fq -- "$2" "$1" || { echo "missing '$2' in $1" >&2; exit 1; }; }
need "$ROOT/Config.qml" 'property string animationVolumeMorphProfile: "ease-in-out"'
need "$ROOT/js/settings/SettingsDefaults.js" 'animationVolumeMorphProfile: "ease-in-out"'
need "$ROOT/js/settings/SettingsPersistence.js" 'animationVolumeMorphProfile: config.animationVolumeMorphProfile'
need "$ROOT/js/settings/SettingsApplyBehaviour.js" 'applyMorphProfile(Config, o, "animationVolumeMorphProfile")'
need "$ROOT/js/settings/SettingsApplyBehaviour.js" 'Config.animationVolumeMorphProfile = "none"'
need "$ROOT/js/settings/SettingsApplyBehaviour.js" ': legacyAnimationStyle) === "none"'
need "$ROOT/js/settings/SettingsApplyBehaviour.js" 'Config.animationVolumeStreamsVisibilityStyle = "fade"'
need "$ROOT/js/settings/SettingsSchema.js" 'if (p.animationVolumeMorphProfile === undefined && legacyVolumeAnimationStyle === "none")'
need "$ROOT/components/settings/SettingsNavigationController.qml" '{ keys: ["animationVolumeStreamsVisibilityStyle", "animationVolumeStreamsVisibilityProfile", "animationVolumeMorphProfile", "volumeStreamsAnimationDuration"] }'
need "$ROOT/components/settings/sections/SettingsVolumeSection.qml" 'SettingsAnimationGroup {'
need "$ROOT/components/settings/sections/SettingsVolumeSection.qml" 'profile: Config.animationVolumeMorphProfile'
need "$ROOT/components/settings/sections/SettingsVolumeSection.qml" 'property var values: ["fade", "slideLeft", "slideRight", "slideUp", "slideDown"]'
need "$ROOT/components/settings/sections/SettingsVolumeSection.qml" 'Внутренняя перестройка высоты остаётся независимой.'
need "$ROOT/components/Volumes.qml" 'Config.animationDurationForProfile('
need "$ROOT/components/Volumes.qml" 'Config.animationEasingType(Config.animationVolumeMorphProfile'
need "$ROOT/components/Volumes.qml" 'Config.animationBezierCurve(Config.animationVolumeMorphProfile'
need "$ROOT/js/settings/SettingsProfiles.js" 'volumes: ["volume", "animationVolume"]'
need "$ROOT/js/settings/SettingsResets.js" '"animationVolumeStreamsVisibilityStyle", "animationVolumeStreamsVisibilityProfile", "animationVolumeMorphProfile", "volumeStreamsAnimationDuration"'
need "$ROOT/CHECK.sh" 'test_volume_animation_settings.sh'
echo 'Volume animation settings schema, migration, profile/reset persistence and transition wiring passed'
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
function load(relativePath) {
  const source = fs.readFileSync(root + '/' + relativePath, 'utf8').replace(/^\.pragma library\s*/m, '');
  const context = {};
  vm.createContext(context);
  vm.runInContext(source, context, { filename: relativePath });
  return context;
}
const behaviour = load('js/settings/SettingsApplyBehaviour.js');
const schema = load('js/settings/SettingsSchema.js');
const curves = load('js/AnimationCurves.js');
const defaults = { animationVolumeStreamsVisibilityStyle: 'fade', animationVolumeMorphProfile: 'expressive', normalizeAnimationProfile: curves.normalizeProfile };
const legacyConfig = { ...defaults };
behaviour.apply(legacyConfig, { animationVolumeStreamsVisibilityStyle: 'none' });
if (legacyConfig.animationVolumeMorphProfile !== 'none' || legacyConfig.animationVolumeStreamsVisibilityStyle !== 'fade')
  throw new Error('Legacy root settings did not migrate none to the shared profile');
const currentConfig = { ...defaults };
behaviour.apply(currentConfig, { animationVolumeStreamsVisibilityStyle: 'slideLeft', animationVolumeMorphProfile: 'spatial' });
if (currentConfig.animationVolumeMorphProfile !== 'ease-out' || currentConfig.animationVolumeStreamsVisibilityStyle !== 'slideLeft')
  throw new Error('Current volume animation options did not survive settings apply');
const legacyProfile = schema.normalizeProfile({ animationVolumeStreamsVisibilityStyle: 'none' }, true);
if (legacyProfile.animationVolumeMorphProfile !== 'none' || legacyProfile.animationVolumeStreamsVisibilityStyle !== 'fade')
  throw new Error('Legacy sparse profile did not migrate none to the shared profile');
const currentProfile = schema.normalizeProfile({ animationVolumeStreamsVisibilityStyle: 'slideDown', animationVolumeMorphProfile: 'effects' }, true);
if (currentProfile.animationVolumeMorphProfile !== 'ease-in' || currentProfile.animationVolumeStreamsVisibilityStyle !== 'slideDown')
  throw new Error('Current profile values did not survive normalization');
console.log('Volume legacy/current settings migration runtime: 4/4 passed');
JS

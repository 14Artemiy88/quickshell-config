#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
NAV="$ROOT/components/settings/SettingsNavigationController.qml"
VARIANTS="$ROOT/js/launcher/LauncherSchemeVariantPicker.js"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
README="$ROOT/README.md"

node - "$CONFIG" "$DEFAULTS" "$APPLY" "$PERSIST" "$RESETS" "$NAV" "$VARIANTS" "$LAUNCHER" "$README" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const [config, defaults, apply, persist, resets, nav, variantSource, launcher, readme] = process.argv.slice(2).map(p => fs.readFileSync(p, 'utf8'));
const helperSource = variantSource.replace(/^\.pragma library\s*/, '');
const helper = vm.runInThisContext(helperSource + '\n({ DEFAULT_VARIANT, normalizeVariant })');
assert(config.includes('property string launcherDynamicSchemeVariant: "scheme-tonal-spot"'), 'Config defaults to Tonal Spot');
assert(defaults.includes('launcherDynamicSchemeVariant: "scheme-tonal-spot"'), 'SettingsDefaults use Tonal Spot');
assert(apply.includes('LauncherSchemeVariantPicker.js" as LauncherSchemeVariantPicker'), 'profile loader imports the allow-list');
assert(apply.includes('Config.launcherDynamicSchemeVariant = LauncherSchemeVariantPicker.normalizeVariant(o.launcherDynamicSchemeVariant)'), 'profile restore validates the variant');
assert(persist.includes('launcherDynamicSchemeVariant: String(config.launcherDynamicSchemeVariant || "scheme-tonal-spot")'), 'variant is persisted with the profile');
assert(resets.includes('"launcherDynamicSchemeVariant"'), 'Launcher reset includes the selected variant');
assert(resets.includes('profile.launcherDynamicSchemeVariant === undefined'), 'older profiles receive a fallback');
assert(resets.includes('normalizeLauncherDynamicSchemeVariant(profile.launcherDynamicSchemeVariant)'), 'profile reset validates unknown values');
assert(resets.includes('function normalizeLauncherDynamicSchemeVariant(value)'), 'reset helper validates variants without an external JS realm dependency');
assert(nav.includes('"launcherWallpaperDirectory", "launcherDynamicSchemeVariant"'), 'variant is tracked with Launcher General dirty state');
assert(launcher.includes('Settings.applyGeneratedTheme(LauncherDynamicScheme.GENERATED_THEME_NAME, generated.palette)'), 'variant selection uses the shared theme apply/save path');
assert(launcher.includes('Config.launcherDynamicSchemeVariant = root.dynamicSchemePendingVariant'), 'selected variant is only persisted after a valid generated palette');
assert(readme.includes('>scheme variants') && readme.includes('>variant') && readme.includes('Fruit Salad') && readme.includes('Tonal Spot'), 'README documents the canonical command and its legacy alias');
assert.strictEqual(helper.normalizeVariant('unknown'), '');
assert.strictEqual(helper.normalizeVariant(undefined), helper.DEFAULT_VARIANT);

const resetSource = resets.replace(/^\.pragma library\s*/m, '').replace(/^\.import .*$/mg, '');
const resetContext = {};
vm.createContext(resetContext);
vm.runInContext(resetSource, resetContext);
function resetVariant(profile) {
  const owner = {
    activeProfile: 'test', profiles: { test: profile }, geometry: {}, moduleMonitors: {},
    moduleFrames: {}, moduleBackgrounds: {}, moduleBlurEnabled: {},
    defaultGeometry: { launcher: [-999999, -999999, 720, 640] },
    defaultModuleBlurEnabled: { launcher: false }, save() {}, resetUnavailable() {}
  };
  const config = { launcherWidth: 720, launcherHeight: 640 };
  resetContext.resetLauncherSettings(owner, config);
  return config.launcherDynamicSchemeVariant;
}
assert.strictEqual(resetVariant({}), 'scheme-tonal-spot', 'old profiles without the variant fall back to Tonal Spot');
assert.strictEqual(resetVariant({ launcherDynamicSchemeVariant: 'scheme-fidelity' }), 'scheme-fidelity', 'profile reset restores a valid selected variant');
assert.strictEqual(resetVariant({ launcherDynamicSchemeVariant: 'unsupported' }), 'scheme-tonal-spot', 'profile reset rejects unsupported variants');
console.log('Dynamic scheme variant defaults, validation, profile persistence, legacy fallback and dirty-state: OK');
JS

echo 'Launcher scheme variant persistence: OK'

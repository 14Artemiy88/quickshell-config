#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="$ROOT/js/launcher/LauncherDynamicScheme.js"
WALLPAPER_MODULE="$ROOT/js/launcher/LauncherWallpaperPicker.js"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
SETTINGS="$ROOT/Settings.qml"
THEME_MANAGER="$ROOT/js/settings/SettingsThemeManager.js"
THEMES="$ROOT/js/settings/SettingsThemes.js"
METADATA="$ROOT/js/settings/SettingsMetadata.js"
SCRIPT="$ROOT/scripts/launcher_dynamic_scheme"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

node - "$MODULE" "$WALLPAPER_MODULE" "$METADATA" "$THEMES" "$THEME_MANAGER" "$LAUNCHER" "$SETTINGS" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const [modulePath, wallpaperPath, metadataPath, themesPath, managerPath, launcherPath, settingsPath] = process.argv.slice(2);
const wallpaperSource = fs.readFileSync(wallpaperPath, 'utf8').replace(/^\.pragma library\s*/, '');
const wallpaperApi = vm.runInNewContext(wallpaperSource + '\n({ isValidLocalImagePath, recentUsageForScreen })');
const source = fs.readFileSync(modulePath, 'utf8')
  .replace(/^\.pragma library\s*/, '')
  .replace(/^\.import .*$/gm, '');
const context = { WallpaperPicker: wallpaperApi, console, JSON, Object, Array, String, Number, Math, isFinite };
vm.createContext(context);
vm.runInContext(source + '\nthis.api = { GENERATED_THEME_NAME, parseQuery, latestWallpaperForScreen, buildResults, isHexColor, alphaColor, extractJson, buildPaletteFromMatugen };', context);
const api = context.api;

for (const command of ['scheme dynamic', 'theme dynamic', 'schemes wallpaper', 'color-scheme dynamic', 'colour-scheme wallpaper', 'палитра обои', 'тема динамика', 'темы динамическая']) {
  assert.strictEqual(api.parseQuery(command).active, true, `${command} activates wallpaper-derived scheme mode`);
}
assert.strictEqual(api.parseQuery('scheme nord').active, false, 'ordinary scheme query remains in the static theme picker');
assert.strictEqual(api.parseQuery('theme dynamic mountains').query, 'mountains', 'text after dynamic is preserved for filtering');
assert.strictEqual(api.GENERATED_THEME_NAME, 'Wallpaper Dynamic');

const data = {
  version: 1,
  favorites: [],
  usage: [
    { path: '/wallpapers/sunset-mountain.jpg', screenName: 'DP-1', count: 4, lastUsed: 200 },
    { path: '/wallpapers/forest.png', screenName: 'DP-1', count: 1, lastUsed: 100 },
    { path: '/wallpapers/other-screen.png', screenName: 'HDMI-A-1', count: 3, lastUsed: 300 }
  ]
};
assert.strictEqual(api.latestWallpaperForScreen(data, 'DP-1').path, '/wallpapers/sunset-mountain.jpg', 'latest wallpaper is isolated to the selected output');
assert.strictEqual(api.latestWallpaperForScreen(data, 'HDMI-A-1').path, '/wallpapers/other-screen.png', 'another output uses its own latest wallpaper');
assert.strictEqual(api.latestWallpaperForScreen(data, 'DP-2'), null, 'an output without wallpaper history does not inherit another output');
const score = (text, query) => String(text).toLowerCase().includes(String(query).toLowerCase()) ? 100 : -1;
let rows = api.buildResults(data, 'DP-1', false, '', '', score);
assert.strictEqual(rows[0].kind, 'dynamicSchemeGenerate', 'valid selected-screen history offers palette generation');
assert.strictEqual(rows[0].screenName, 'DP-1');
assert.strictEqual(rows[0].usageCount, 4);
assert.strictEqual(api.buildResults(data, 'DP-1', true, '', '', score).length, 0, 'busy state is represented by a notification, not a Launcher result row');
assert.strictEqual(api.buildResults(data, 'DP-1', false, 'Matugen failed', '', score)[0].kind, 'dynamicSchemeError', 'process errors have a dedicated result');
assert.strictEqual(api.buildResults(data, 'DP-2', false, '', '', score)[0].kind, 'dynamicSchemeUnavailable', 'no history reports a selected-screen-specific empty state');
assert.strictEqual(api.buildResults(data, 'DP-1', false, '', 'mountain', score)[0].kind, 'dynamicSchemeGenerate', 'optional fuzzy search matches the recent wallpaper filename');
assert.strictEqual(api.buildResults(data, 'DP-1', false, '', 'unrelated', score)[0].kind, 'dynamicSchemeUnavailable', 'optional query rejects nonmatching wallpaper names');

const metadataSource = fs.readFileSync(metadataPath, 'utf8');
const colorNamesMatch = metadataSource.match(/var colorNames\s*=\s*(\[[^\n]+\])/);
assert(colorNamesMatch, 'Settings exposes its full persisted color-name list');
const colorNames = vm.runInNewContext(`(${colorNamesMatch[1]})`);
const basePalette = Object.fromEntries(colorNames.map(name => [name, '#112233']));
basePalette.settingsBackground = '#44112233';
basePalette.playerProgressTrack = '#55112233';
basePalette.playerProgressFill = '#66112233';
basePalette.topAppsCpuBarColor = '#77112233';
basePalette.topAppsRamBarColor = '#88112233';
basePalette.topAppsCpuBarTrackColor = '#99112233';
basePalette.topAppsRamBarTrackColor = '#aa112233';
const tokens = {
  primary: { color: '#adc6ff' }, secondary: { color: '#bbc6e4' }, tertiary: { color: '#e5b8e8' }, error: { color: '#ffb4ab' },
  background: { color: '#1b1b1f' }, surface: { color: '#1b1b1f' }, surface_variant: { color: '#44474f' },
  on_background: { color: '#e3e2e6' }, on_surface: { color: '#e3e2e6' }, on_surface_variant: { color: '#c4c6d0' },
  outline: { color: '#8e9099' }, outline_variant: { color: '#44474f' }, secondary_container: { color: '#3b475f' },
  primary_container: { color: '#004494' }, tertiary_container: { color: '#5d3a62' }, inverse_primary: { color: '#005ac1' },
  error_container: { color: '#93000a' }, source_color: { color: '#4285f4' }
};
// Matugen 4.x native JSON is token-first; each color role contains dark/light/default.
const modernColors = Object.fromEntries(Object.entries(tokens).map(([name, value]) => [name, {
  dark: value, light: value, default: value
}]));
const matugenJson = JSON.stringify({
  image: '/wallpapers/sunset-mountain.jpg', mode: 'dark', is_dark_mode: true,
  colors: modernColors,
  palettes: { primary: {}, secondary: {}, tertiary: {}, neutral: {}, neutral_variant: {}, error: {} }
});
const generated = api.buildPaletteFromMatugen(matugenJson, basePalette, colorNames);
assert.strictEqual(generated.ok, true, generated.error || 'valid Matugen JSON builds a palette');
assert.strictEqual(generated.sourceColor, '#4285f4');
assert.strictEqual(generated.palette.accent, '#adc6ff', 'Matugen v4+ color objects are unwrapped');
assert.strictEqual(generated.palette.text, '#e3e2e6');
assert.strictEqual(generated.palette.black, '#1b1b1f');
assert.strictEqual(generated.palette.background, '#4d1b1b1f', 'translucent shell background uses ARGB');
assert.strictEqual(generated.palette.calendarBackground, '#cc1b1b1f');
assert.strictEqual(generated.palette.cpu1, '#ffb4ab');
assert.strictEqual(generated.palette.ram, '#bbc6e4');
assert.strictEqual(generated.palette.settingsBackground, basePalette.settingsBackground, 'independent settings background remains unchanged');
assert.strictEqual(generated.palette.playerProgressTrack, basePalette.playerProgressTrack, 'independent player track remains unchanged');
assert.strictEqual(generated.palette.playerProgressFill, basePalette.playerProgressFill, 'independent player fill remains unchanged');
assert.strictEqual(generated.palette.topAppsCpuBarColor, basePalette.topAppsCpuBarColor, 'independent top-app colors remain unchanged');
assert(colorNames.every(name => typeof generated.palette[name] === 'string' && generated.palette[name].length > 0), 'generated palette covers all persisted color keys');
const legacyTokens = Object.fromEntries(Object.entries(tokens).map(([key, value]) => [key, value.color]));
assert.strictEqual(api.buildPaletteFromMatugen(JSON.stringify({ colors: { dark: legacyTokens } }), basePalette, colorNames).ok, true, 'Matugen 3.x mode-first plain-hex output remains supported');
const modernLegacyStrings = Object.fromEntries(Object.entries(legacyTokens).map(([name, value]) => [name, { dark: value, light: value, default: value }]));
assert.strictEqual(api.buildPaletteFromMatugen(JSON.stringify({ colors: modernLegacyStrings }), basePalette, colorNames).ok, true, 'Matugen 4.x token-first output with --old-json-output remains supported');
assert.strictEqual(api.buildPaletteFromMatugen('{broken', basePalette, colorNames).ok, false, 'malformed JSON is rejected');
assert.strictEqual(api.buildPaletteFromMatugen(JSON.stringify({ colors: { light: tokens } }), basePalette, colorNames).ok, false, 'missing dark palette is rejected');
const incomplete = { ...tokens }; delete incomplete.primary;
assert.strictEqual(api.buildPaletteFromMatugen(JSON.stringify({ colors: { dark: incomplete } }), basePalette, colorNames).ok, false, 'missing required Material tokens are rejected');
const incompleteModern = { ...modernColors }; delete incompleteModern.primary;
assert.strictEqual(api.buildPaletteFromMatugen(JSON.stringify({ colors: incompleteModern }), basePalette, colorNames).ok, false, 'missing required Matugen 4.x token is rejected');
assert.strictEqual(api.alphaColor('#ABCDEF', '4d'), '#4dabcdef');
assert.strictEqual(api.alphaColor('transparent', '4d'), '');

const managerSource = fs.readFileSync(managerPath, 'utf8').replace(/^\.pragma library\s*/, '').replace(/^\.import .*$/gm, '');
const managerContext = { Profiles: { rewriteThemeReferences() {} }, console, JSON, Object, Array, String };
vm.createContext(managerContext);
vm.runInContext(managerSource + '\nthis.manager = { applyGeneratedTheme, renameCustomTheme, saveCurrentTheme, GENERATED_WALLPAPER_THEME_NAME };', managerContext);
const manager = managerContext.manager;
const config = Object.fromEntries(colorNames.map(name => [name, '#223344']));
config.settingsBackground = '#55112233';
config.playerProgressTrack = '#66112233';
config.playerProgressFill = '#77112233';
config.topAppsCpuBarColor = '#88112233';
config.topAppsRamBarColor = '#99112233';
config.topAppsCpuBarTrackColor = '#aa112233';
config.topAppsRamBarTrackColor = '#bb112233';
const owner = {
  customThemes: {}, activeTheme: 'Nord', themeDraftSource: 'Nord', themeDraft: {},
  themeDraftRevision: 0, themeStateRevision: 0, colorNames,
  saveCount: 0, save() { this.saveCount++; }
};
const themes = {
  builtinThemeNames: ['Nord'],
  palette(name, customs) { return (customs && customs[name]) || Object.fromEntries(colorNames.map(key => [key, '#334455'])); }
};
assert.strictEqual(manager.applyGeneratedTheme(owner, themes, config, colorNames, 'Wallpaper Dynamic', generated.palette), true, 'generated theme is saved through the shared theme manager');
assert.strictEqual(owner.activeTheme, 'Wallpaper Dynamic');
assert.strictEqual(owner.saveCount, 1, 'generated theme uses normal Settings save path');
assert.strictEqual(config.accent, generated.palette.accent, 'generated theme applies its accent');
assert.strictEqual(config.settingsBackground, '#55112233', 'shared manager preserves manually tuned independent background');
assert.strictEqual(config.topAppsRamBarColor, '#99112233', 'shared manager preserves manually tuned top-app colors');
assert.strictEqual(manager.saveCurrentTheme(owner, colorNames, config, 'Wallpaper Dynamic'), true, 'active generated theme can be saved after manual color edits');
owner.activeTheme = 'Nord';
assert.strictEqual(manager.saveCurrentTheme(owner, colorNames, config, 'Wallpaper Dynamic'), false, 'reserved generated name cannot be created as an unrelated custom theme');
assert.strictEqual(manager.renameCustomTheme(owner, themes, config, 'Nord', 'Wallpaper Dynamic'), false, 'reserved generated name cannot be claimed by another custom theme');

const launcher = fs.readFileSync(launcherPath, 'utf8');
const settings = fs.readFileSync(settingsPath, 'utf8');
assert(launcher.includes('LauncherDynamicScheme.js" as LauncherDynamicScheme'));
assert(launcher.includes('LauncherSchemeVariantPicker.js" as LauncherSchemeVariantPicker'));
assert(launcher.includes('root.dynamicSchemePendingVariant'));
assert(launcher.includes('Settings.applyGeneratedTheme(LauncherDynamicScheme.GENERATED_THEME_NAME, generated.palette)'));
assert(launcher.includes('Config.launcherDynamicSchemeVariant = root.dynamicSchemePendingVariant'));
assert(launcher.includes('root.generateDynamicScheme(source.path, source.screenName, selectedVariant)'));
assert(launcher.includes('LauncherDynamicScheme.parseQuery(normalizedQuery)'));
assert(launcher.includes('root.wallpaperPickerData,\n                root.wallpaperSelectedScreenName'));
assert(launcher.includes('LauncherDynamicScheme.buildResults(') && launcher.includes('root.runFuzzyScore(searchText, normalizedSearch)'));
assert(launcher.includes('scripts/launcher_dynamic_scheme'));
assert(launcher.includes('root.dynamicSchemeStdoutReady && root.dynamicSchemeStderrReady'));
assert(launcher.includes('root.wallpaperSelectedScreenName') && launcher.includes('dynamicSchemePickerActive'));
assert(launcher.includes('function reportDynamicSchemeError(message)'));
assert(launcher.includes('root.reportDynamicSchemeError(detail.indexOf("MATUGEN_NOT_FOUND") >= 0'));
assert(launcher.includes('root.reportDynamicSchemeError(String(generated.error'));
assert(launcher.includes('root.reportDynamicSchemeError("Сначала установите обои'));
assert(launcher.includes('id: dynamicSchemeNotificationProcess'));
assert(launcher.includes('"notify-send"'));
assert(launcher.includes('"--urgency=critical"'));
assert(launcher.includes('"--expire-time=12000"'));
assert(launcher.includes('root.dynamicSchemeNotificationBody'));
assert(launcher.includes('--action=copy-error=Копировать ошибку'), 'standard error notification exposes a copy action');
assert(launcher.includes('String(this.text || "").trim() === "copy-error"'), 'notification action result is handled');
assert(launcher.includes('Quickshell.shellDir + "/scripts/copy_text"'), 'copy action reuses shared clipboard helper');
assert(launcher.includes('Config.launcherDynamicSchemeVariant = previousVariant || LauncherSchemeVariantPicker.DEFAULT_VARIANT'));
assert(settings.includes('function applyGeneratedTheme(name, palette)'));
console.log('Dynamic scheme query, per-monitor source, Matugen JSON palette mapping, user-color preservation and Settings integration: OK');
JS

bash -n "$SCRIPT"
tmp_image="$TMP/test-wallpaper.png"
printf 'not-a-real-image' > "$tmp_image"
mkdir -p "$TMP/bin" "$TMP/no-matugen"
cat > "$TMP/bin/matugen" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--version" ]]; then
    printf 'matugen %s\n' "${MATUGEN_TEST_VERSION:-4.2.0}"
    exit 0
fi
printf '%s\n' "$@" > "$MATUGEN_ARGS_FILE"
config_path="$2"
cp -- "$config_path" "$MATUGEN_CONFIG_COPY"
printf '{"colors":{"primary":{"dark":{"color":"#adc6ff"},"light":{"color":"#d8e2ff"},"default":{"color":"#adc6ff"}}}}\n'
SH
chmod +x "$TMP/bin/matugen"
MATUGEN_ARGS_FILE="$TMP/args" MATUGEN_CONFIG_COPY="$TMP/config-copy" PATH="$TMP/bin:/usr/bin:/bin" \
    bash "$SCRIPT" "$tmp_image" scheme-fidelity > "$TMP/matugen.json"
[[ "$(sed -n '1p' "$TMP/args")" == "-c" ]]
config_path="$(sed -n '2p' "$TMP/args")"
[[ "$(sed -n '3p' "$TMP/args")" == "image" ]]
[[ "$(sed -n '4p' "$TMP/args")" == "$tmp_image" ]]
[[ "$(sed -n '5p' "$TMP/args")" == "-m" ]]
[[ "$(sed -n '6p' "$TMP/args")" == "dark" ]]
[[ "$(sed -n '7p' "$TMP/args")" == "-t" ]]
[[ "$(sed -n '8p' "$TMP/args")" == "scheme-fidelity" ]]
[[ "$(sed -n '9p' "$TMP/args")" == "--json" ]]
[[ "$(sed -n '10p' "$TMP/args")" == "hex" ]]
[[ "$(sed -n '11p' "$TMP/args")" == "--dry-run" ]]
if grep -Fxq -- '--old-json-output' "$TMP/args"; then
    echo 'Matugen 4 native JSON should be parsed directly, not compatibility-forced' >&2
    exit 1
fi
grep -Fq '[config.wallpaper]' "$TMP/config-copy"
grep -Fqx '[templates]' "$TMP/config-copy"
grep -Fq 'command = "true"' "$TMP/config-copy"
grep -Fq 'set = false' "$TMP/config-copy"
python3 - "$TMP/config-copy" <<'PYTOML'
import sys
import tomllib
with open(sys.argv[1], 'rb') as stream:
    config = tomllib.load(stream)
assert config['config']['wallpaper']['command'] == 'true'
assert config['config']['wallpaper']['set'] is False
assert config['templates'] == {}
PYTOML
grep -Fq 'source_color_index = 0' "$TMP/config-copy"
grep -Fq 'caching = false' "$TMP/config-copy"
grep -Fq 'version_check = false' "$TMP/config-copy"
[[ "$(grep -Fc '[templates]' "$TMP/config-copy")" -eq 1 ]]
if grep -Fq '[templates.' "$TMP/config-copy"; then exit 1; fi
[[ ! -e "$config_path" ]]
node - "$TMP/matugen.json" <<'JS'
const fs = require('fs'); const assert = require('assert');
const output = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
assert.strictEqual(output.colors.primary.dark.color, '#adc6ff');
console.log('Matugen wrapper: isolated config disables wallpaper/template side effects and Matugen 4 JSON passes through: OK');
JS

set +e
PATH="$TMP/no-matugen" /bin/bash "$SCRIPT" "$tmp_image" > "$TMP/missing.out" 2> "$TMP/missing.err"
missing_status=$?
PATH="$TMP/no-matugen" /bin/bash "$SCRIPT" "$TMP/no-such-image.png" > "$TMP/invalid.out" 2> "$TMP/invalid.err"
invalid_status=$?
PATH="$TMP/no-matugen" /bin/bash "$SCRIPT" "$tmp_image" scheme-unsupported > "$TMP/variant.out" 2> "$TMP/variant.err"
variant_status=$?
set -e
[[ "$missing_status" -eq 127 ]]
grep -Fq 'MATUGEN_NOT_FOUND' "$TMP/missing.err"
[[ "$invalid_status" -eq 2 ]]
grep -Fq 'missing or unreadable' "$TMP/invalid.err"
[[ "$variant_status" -eq 2 ]]
grep -Fq 'Unsupported Matugen scheme variant' "$TMP/variant.err"
grep -Fq 'test_launcher_dynamic_scheme.sh' "$ROOT/CHECK.sh"
echo 'Launcher dynamic wallpaper scheme and Matugen wrapper: OK'

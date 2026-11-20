#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCORING="$ROOT/js/launcher/LauncherSearchScoring.js"
SCHEMES="$ROOT/js/launcher/LauncherSchemePicker.js"
WALLPAPERS="$ROOT/js/launcher/LauncherWallpaperPicker.js"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
NAV="$ROOT/components/settings/SettingsNavigationController.qml"
UI="$ROOT/components/settings/sections/SettingsLauncherSection.qml"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
README="$ROOT/README.md"

node - "$SCORING" "$SCHEMES" "$WALLPAPERS" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const load = (file, names) => {
  const source = fs.readFileSync(file, 'utf8').replace(/^\.pragma library\s*/, '');
  return vm.runInThisContext(source + `\n({ ${names.join(', ')} })`);
};
const scoring = load(process.argv[2], ['fuzzyScore']);
const schemes = load(process.argv[3], ['buildResults']);
const wallpapers = load(process.argv[4], ['buildResults']);
const score = (enabled) => (text, query) => scoring.fuzzyScore(text, query, enabled);

// Fuzzy on keeps subsequence matching, strict mode retains exact/prefix/substring.
const themeNames = ['Tokyo Night', 'Nord', 'Dracula'];
const themeResults = (query, enabled) => schemes.buildResults(
  query, themeNames, 'Nord', () => ['#111111', '#222222'], () => '', score(enabled), 100
);
assert.strictEqual(themeResults('tn', true).some(item => item.name === 'Tokyo Night'), true,
  'fuzzy scheme search finds a gapped subsequence');
assert.strictEqual(themeResults('tn', false).length, 0,
  'strict scheme search rejects a gapped subsequence');
assert.strictEqual(themeResults('tok', false)[0].name, 'Tokyo Night',
  'strict scheme search keeps prefix matches');
assert.strictEqual(themeResults('night', false)[0].name, 'Tokyo Night',
  'strict scheme search keeps contiguous substring matches');

const wallpaperEntries = [{ path: '/walls/sunrise-beach.png', name: 'sunrise-beach.png' }];
const wallpaperResults = (query, enabled) => wallpapers.buildResults(
  query, wallpaperEntries, score(enabled), 100, { version: 1, favorites: [], usage: [] }, 'all', 'DP-1'
);
assert.strictEqual(wallpaperResults('sb', true).length, 1,
  'fuzzy wallpaper search finds gapped filename subsequences');
assert.strictEqual(wallpaperResults('sb', false).length, 0,
  'strict wallpaper search rejects gapped filename subsequences');
assert.strictEqual(wallpaperResults('sun', false).length, 1,
  'strict wallpaper search keeps filename prefixes');
assert.strictEqual(wallpaperResults('rise-beach', false).length, 1,
  'strict wallpaper search keeps contiguous filename substrings');
JS

node - "$CONFIG" "$DEFAULTS" "$APPLY" "$PERSIST" "$RESETS" "$NAV" "$UI" "$LAUNCHER" "$README" <<'JS'
const fs = require('fs');
const assert = require('assert');
const [config, defaults, apply, persist, resets, nav, ui, launcher, readme] = process.argv.slice(2).map(p => fs.readFileSync(p, 'utf8'));
for (const key of ['launcherFuzzySearchSchemes', 'launcherFuzzySearchWallpapers']) {
  assert(config.includes(`property bool ${key}: true`), `${key} defaults enabled in Config`);
  assert(defaults.includes(`${key}: true`), `${key} defaults enabled in SettingsDefaults`);
  assert(apply.includes(`if (o.${key} !== undefined)`) && apply.includes(`Config.${key} = !!o.${key}`), `${key} is restored from a profile`);
  assert(persist.includes(`${key}: config.${key}`), `${key} is persisted`);
  assert(resets.includes(`"${key}"`), `${key} is included in Launcher reset`);
  assert(resets.includes(`if (profile.${key} === undefined) config.${key} = true`), `${key} preserves old profile behavior`);
  assert(nav.includes(key), `${key} participates in launcher dirty-state tracking`);
  assert(ui.includes(`changeKeys: ({ keys: ["${key}"] })`), `${key} has an independent dirty-state group`);
  assert(ui.includes(`Config.${key} = checked`) && ui.includes(`function on${key[0].toUpperCase()}${key.slice(1)}Changed()`), `${key} has a connected Settings switch`);
}
assert(ui.includes('heading: "Поиск цветовых схем"') && ui.includes('heading: "Поиск обоев"'), 'both search groups are placed in the Launcher Search subtab');
for (const key of ['launcherFuzzySearchSchemes', 'launcherFuzzySearchWallpapers']) {
  const marker = `changeKeys: ({ keys: [\"${key}\"] })`;
  const position = ui.indexOf(marker);
  const preceding = ui.slice(Math.max(0, position - 180), position);
  assert(preceding.includes('currentPageSubTabIndex === 1'), `${key} control is visible only in Search subtab`);
}
assert(launcher.includes('readonly property bool fuzzySchemeSearchEnabled: Config.launcherFuzzySearchSchemes !== false'), 'scheme setting is reactive');
assert(launcher.includes('readonly property bool fuzzyWallpaperSearchEnabled: Config.launcherFuzzySearchWallpapers !== false'), 'wallpaper setting is reactive');
assert(launcher.includes('root.fuzzySchemeSearchEnabled, root.fuzzyWallpaperSearchEnabled'), 'result binding depends on both settings');
assert(launcher.includes('function buildLauncherActionResults(query, fuzzyActionsEnabled, fuzzySchemesEnabled, fuzzyWallpapersEnabled)'), 'action builder receives both preferences');
assert(launcher.includes('function buildAppsUnifiedResults(applicationEntries, fuzzyActionsEnabled, availableCategories, fuzzySchemesEnabled, fuzzyWallpapersEnabled)'), 'Apps result builder forwards both preferences');
assert(launcher.includes('fuzzySchemes)') && launcher.includes('fuzzyWallpapers)'), 'scheme, dynamic-scheme and wallpaper scorers use their independent toggles');
assert(readme.includes('цветовых схем и обоев') && readme.includes('Schemes setting') && readme.includes('Wallpapers setting'), 'README documents the additional search modes');
JS

echo 'Launcher fuzzy scheme and wallpaper settings: OK'

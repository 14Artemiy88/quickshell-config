#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_MODEL="$ROOT/components/launcher/models/AppModel.qml"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
SETTINGS="$ROOT/components/settings/sections/SettingsLauncherSection.qml"

node - "$APP_MODEL" "$LAUNCHER" "$SETTINGS" <<'JS'
const fs = require('fs');
const assert = require('assert');
const [model, launcher, settings] = process.argv.slice(2).map(p => fs.readFileSync(p, 'utf8'));

assert(model.includes('const entries = DesktopEntries.applications.values || []'),
  'AppModel reads the live ObjectModel values directly inside the results binding');
assert(model.includes('readonly property int desktopEntryCount: DesktopEntries.applications.values.length'),
  'the empty state reads the current system catalog count reactively');
assert(!model.includes('desktopEntriesSnapshot') && !model.includes('refreshDesktopEntries'),
  'there is no imperative snapshot or polling path that can become stale');
assert(model.includes('root.hiddenAppIds.indexOf(appId) >= 0'),
  'hidden apps are excluded from every Apps result source');
assert(model.includes('favoriteIndex: favoriteIndex'),
  'favorite app IDs are used to rank applications');
assert(launcher.includes('property var appsUnifiedResults: {')
  && launcher.includes('return root.buildAppsUnifiedResults(\n            appModel.applications, root.fuzzyCustomActionsEnabled'),
  'the ListView result binding directly depends on AppModel applications');
assert(launcher.includes('const wallpaperData = root.wallpaperPickerData')
  && launcher.includes('const wallpaperEntries = root.wallpaperCatalogEntries')
  && launcher.includes('const wallpaperScreen = root.wallpaperSelectedScreenName'),
  'wallpaper favorites, recent screen and catalog changes invalidate the unified result binding');
assert(launcher.includes('function buildAppsUnifiedResults(applicationEntries, fuzzyActionsEnabled, availableCategories, fuzzySchemesEnabled, fuzzyWallpapersEnabled)'),
  'the unified result builder receives its application list as an explicit dependency');
assert(launcher.includes('appModel.desktopEntryCount === 0'),
  'the empty state distinguishes an empty system catalog from no matching results');
assert(settings.includes('if (!needle && !isFavorite && !isHidden) continue'),
  'settings retain the intentional empty-search behavior');
assert(settings.includes('Пока нет выбранных приложений.'),
  'settings still explain their compact empty state');
JS

echo 'Launcher asynchronous desktop catalog refresh: OK'

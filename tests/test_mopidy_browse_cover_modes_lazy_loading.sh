#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT/js/mopidy/BrowseCoverMode.js"
BROWSER="$ROOT/components/mopidy/MopidyFileBrowser.qml"
MOPIDY="$ROOT/components/mopidy/Mopidy.qml"
SETTINGS="$ROOT/components/settings/sections/mopidy/SettingsMopidySection.qml"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
APPLY="$ROOT/js/settings/SettingsApplyTimerPlayer.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
NAV="$ROOT/components/settings/SettingsNavigationController.qml"
LIBRARY="$ROOT/scripts/mopidy/library.sh"

node --input-type=module - "$HELPER" <<'NODE'
import fs from 'node:fs'
import vm from 'node:vm'
const source = fs.readFileSync(process.argv[2], 'utf8')
const context = {}
vm.createContext(context)
vm.runInContext(source, context)
const assert = (value, message) => { if (!value) throw new Error(message) }
assert(context.normalizeMode('off') === 'off', 'off mode should remain off')
assert(context.normalizeMode('selected') === 'selected', 'selected mode missing')
assert(context.normalizeMode('all-visible') === 'all-visible', 'all-visible mode missing')
assert(context.normalizeMode('broken') === 'selected', 'invalid mode should safely fall back to selected')
assert(!context.shouldLoad('off', 'directory', true, true), 'off must never request covers')
assert(context.shouldLoad('selected', 'directory', false, true), 'selected mode should request only the hovered/selected directory')
assert(!context.shouldLoad('selected', 'directory', true, false), 'selected mode must not request other folders')
assert(context.shouldLoad('all-visible', 'directory', true, false), 'all-visible must request visible directories')
assert(!context.shouldLoad('all-visible', 'directory', false, true), 'all-visible must not request offscreen directories')
assert(!context.shouldLoad('all-visible', 'track', true, true), 'track rows must never request folder covers')
assert(!context.shouldLoad('all-visible', 'parent', true, true), 'parent row must never request a cover')
NODE

grep -Fq 'property string mopidyBrowseCoverMode: "selected"' "$CONFIG"
grep -Fq 'property bool mopidyBrowseCoverKeepSelectedVisible: false' "$CONFIG"
grep -Fq 'mopidyBrowseCoverMode: "selected"' "$DEFAULTS"
grep -Fq 'mopidyBrowseCoverKeepSelectedVisible: false' "$DEFAULTS"
grep -Fq 'mopidyBrowseCoverMode: config.mopidyBrowseCoverMode' "$PERSIST"
grep -Fq 'mopidyBrowseCoverKeepSelectedVisible: config.mopidyBrowseCoverKeepSelectedVisible' "$PERSIST"
grep -Fq 'if (o.mopidyBrowseCoverMode !== undefined)' "$APPLY"
grep -Fq '"mopidyBrowseCoverMode"' "$RESETS"
grep -Fq '"mopidyBrowseCoverMode"' "$NAV"
grep -Fq 'heading: "Обложки библиотеки"' "$SETTINGS"
grep -Fq '"Все видимые"' "$SETTINGS"
grep -Fq '"Только выбранная"' "$SETTINGS"
grep -Fq 'Обложка уже открытой папки в заголовке не зависит' "$SETTINGS"
grep -Fq 'import "../../js/mopidy/BrowseCoverMode.js" as BrowseCoverMode' "$BROWSER"
grep -Fq 'cacheBuffer: 0' "$BROWSER"
grep -Fq 'BrowseCoverMode.shouldLoad(Config.mopidyBrowseCoverMode' "$BROWSER"
grep -Fq 'BrowseCoverMode.shouldDisplay(Config.mopidyBrowseCoverMode' "$BROWSER"
grep -Fq 'asynchronous: true' "$BROWSER"
grep -Fq 'cache: true' "$BROWSER"
grep -Fq 'controller.requestBrowseEntryCover(modelData.uri)' "$BROWSER"
grep -Fq 'controller.releaseBrowseEntryCover(modelData.uri)' "$BROWSER"
grep -Fq 'property var browseEntryCoverQueue: []' "$MOPIDY"
grep -Fq 'browseEntryCoverActiveUri' "$MOPIDY"
grep -Fq 'function pumpBrowseEntryCoverQueue()' "$MOPIDY"
grep -Fq '"folder_cover"' "$MOPIDY"
grep -Fq 'folder_cover)' "$LIBRARY"
[[ "$(grep -c 'id: browseEntryCoverProcess' "$MOPIDY")" == 1 ]]
printf 'Mopidy browser cover modes: off/selected/all-visible, viewport gating, selected-row gating, serial request queue, persistence, settings, async cache and process wiring passed\n'

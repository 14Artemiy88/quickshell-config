#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT/js/mopidy/BrowseCoverMode.js"
BROWSER="$ROOT/components/mopidy/MopidyFileBrowser.qml"
SETTINGS="$ROOT/components/settings/sections/mopidy/SettingsMopidySection.qml"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
APPLY="$ROOT/js/settings/SettingsApplyTimerPlayer.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
NAV="$ROOT/components/settings/SettingsNavigationController.qml"
SCHEMA="$ROOT/js/settings/SettingsSchema.js"

node --input-type=module - "$HELPER" <<'NODE'
import fs from 'node:fs'
import vm from 'node:vm'
const context = {}
vm.createContext(context)
vm.runInContext(fs.readFileSync(process.argv[2], 'utf8'), context)
const assert = (value, message) => { if (!value) throw new Error(message) }
assert(context.shouldDisplay('selected', 'directory', true, true, false, true), 'hovered folder cover should display')
assert(!context.shouldDisplay('selected', 'directory', true, false, false, true), 'cover should hide after pointer leaves by default')
assert(context.shouldDisplay('selected', 'directory', true, false, true, true), 'keep option should preserve loaded cover after pointer leaves')
assert(!context.shouldDisplay('selected', 'directory', true, false, true, false), 'keep option must not show an image before it is loaded')
assert(context.shouldDisplay('all-visible', 'directory', true, false, false, true), 'all-visible should remain visible inside viewport')
assert(!context.shouldDisplay('all-visible', 'directory', false, true, true, true), 'all-visible should hide outside viewport')
assert(!context.shouldDisplay('off', 'directory', true, true, true, true), 'off mode must hide all covers')
assert(!context.shouldDisplay('selected', 'track', true, true, true, true), 'track rows must not show folder cover')
NODE

grep -Fq 'property bool mopidyBrowseCoverKeepSelectedVisible: false' "$CONFIG"
grep -Fq 'mopidyBrowseCoverKeepSelectedVisible: false' "$DEFAULTS"
grep -Fq 'mopidyBrowseCoverKeepSelectedVisible: config.mopidyBrowseCoverKeepSelectedVisible' "$PERSIST"
grep -Fq 'if (o.mopidyBrowseCoverKeepSelectedVisible !== undefined)' "$APPLY"
grep -Fq '"mopidyBrowseCoverKeepSelectedVisible"' "$RESETS"
grep -Fq '"mopidyBrowseCoverKeepSelectedVisible"' "$NAV"
grep -Fq 'mopidyBrowseCoverKeepSelectedVisible' "$SCHEMA"
grep -Fq 'Оставлять обложку после снятия курсора' "$SETTINGS"
grep -Fq 'checked: Config.mopidyBrowseCoverKeepSelectedVisible' "$SETTINGS"
grep -Fq 'Config.mopidyBrowseCoverKeepSelectedVisible = checked' "$SETTINGS"
grep -Fq 'BrowseCoverMode.shouldDisplay(Config.mopidyBrowseCoverMode' "$BROWSER"
printf 'Mopidy hover-exit option: default hide, optional keep, all-visible viewport behavior, off mode, profile persistence/reset/schema migration passed\n'

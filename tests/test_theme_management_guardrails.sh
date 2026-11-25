#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];
function load(file, extra = {}) {
  const source = fs.readFileSync(path.join(root, file), 'utf8')
    .replace(/^\.pragma library\s*/m, '')
    .replace(/^\.import .*$/mg, '');
  const context = {...extra};
  vm.createContext(context);
  vm.runInContext(source, context, {filename:file});
  return context;
}
const Metadata = load('js/settings/SettingsMetadata.js');
const Themes = load('js/settings/SettingsThemes.js');
const Profiles = load('js/settings/SettingsProfiles.js', {Metadata});
const Manager = load('js/settings/SettingsThemeManager.js', {Metadata, Profiles});
const clone = value => JSON.parse(JSON.stringify(value));
const basePalette = Themes.palette('14 Theme', {});
const makeOwner = (customThemes = {}, activeTheme = '14 Theme') => ({
  activeTheme, builtinThemeNames: Themes.builtinThemeNames.slice(),
  customThemes: clone(customThemes), colorNames: Metadata.colorNames,
  themeManagedColorNames: Metadata.themeManagedColorNames,
  independentThemeColorNames: Metadata.independentThemeColorNames,
  themeDraft: {}, themeDraftSource: '', themeDraftRevision: 0, themeStateRevision: 0,
  saveCount: 0, save() { this.saveCount++; }, profiles: {},
  profileDefaults: {}, profileList: [], rebuildProfileList() {}
});
const config = {...clone(basePalette), settingsSubheading:'#abcdef'};

// Name validation rejects overlong names without truncating them into a collision.
{
  const owner = makeOwner();
  assert.strictEqual(Manager.saveCurrentTheme(owner, Metadata.colorNames, config, 'X'.repeat(33)), false);
  assert.strictEqual(Object.keys(owner.customThemes).length, 0);
  assert.strictEqual(Manager.saveCurrentTheme(owner, Metadata.colorNames, config, 'constructor'), false);
  assert.strictEqual(Manager.saveCurrentTheme(owner, Metadata.colorNames, config, '__proto__'), false);
  assert.strictEqual(Manager.saveCurrentTheme(owner, Metadata.colorNames, config, '14 Theme'), false,
    'built-in themes cannot be shadowed by custom palettes');
}

// A custom palette cannot be overwritten by saving another active theme under its name.
{
  const existing = {...basePalette, accent:'#112233'};
  const owner = makeOwner({'Work Palette': existing}, '14 Theme');
  assert.strictEqual(Manager.saveCurrentTheme(owner, Metadata.colorNames, config, 'Work Palette'), false);
  assert.strictEqual(owner.customThemes['Work Palette'].accent, '#112233');
  assert.strictEqual(owner.saveCount, 0);
}

// Saving the active custom theme updates it; a new unique name creates a separate palette.
{
  const owner = makeOwner({'Work Palette': clone(basePalette)}, 'Work Palette');
  const edited = {...config, accent:'#123456'};
  assert.strictEqual(Manager.saveCurrentTheme(owner, Metadata.colorNames, edited, 'Work Palette'), true);
  assert.strictEqual(owner.customThemes['Work Palette'].accent, '#123456');
  assert.strictEqual(owner.activeTheme, 'Work Palette');
  assert.strictEqual(Manager.saveCurrentTheme(owner, Metadata.colorNames, edited, 'Second Palette'), true);
  assert.strictEqual(owner.customThemes['Second Palette'].accent, '#123456');
}

// The editor saves an isolated draft as a new palette and rejects overwriting another custom theme.
{
  const owner = makeOwner({'Work Palette': clone(basePalette)});
  assert.strictEqual(Manager.beginThemeEdit(owner, Themes, '14 Theme', config), true);
  assert.strictEqual(Manager.setThemeDraftColor(owner, 'accent', '#334455'), true);
  assert.strictEqual(Manager.saveCustomTheme(owner, Themes, config, 'Work Palette'), false,
    'a draft cannot overwrite a different existing custom theme');
  assert.strictEqual(Manager.saveCustomTheme(owner, Themes, config, 'Draft Custom'), true);
  assert.strictEqual(owner.activeTheme, 'Draft Custom');
  assert.strictEqual(owner.customThemes['Draft Custom'].accent, '#334455');
  assert.strictEqual(owner.customThemes['Draft Custom'].settingsSubheading, '#abcdef');
  for (const key of Metadata.independentThemeColorNames)
    assert.strictEqual(Object.prototype.hasOwnProperty.call(owner.customThemes['Draft Custom'], key), false,
      `${key} remains outside the global custom palette`);
}

// Existing imported long names remain saveable under their original identity.
{
  const legacyName = 'Legacy Imported Theme Name That Exceeds Thirty Two';
  const owner = makeOwner({[legacyName]: clone(basePalette)}, legacyName);
  const edited = {...config, accent:'#654321'};
  assert.strictEqual(Manager.saveCurrentTheme(owner, Metadata.colorNames, edited, legacyName), true);
  assert.strictEqual(owner.customThemes[legacyName].accent, '#654321');
  assert.strictEqual(Manager.renameCustomTheme(owner, Themes, config, legacyName, 'Legacy Renamed'), true);
  assert(owner.customThemes['Legacy Renamed']);
}

// Rename rejects truncation, reserved names, built-ins and existing custom themes.
{
  const owner = makeOwner({'Work Palette': clone(basePalette), 'Other Palette': clone(basePalette)}, 'Work Palette');
  const originalKeys = Object.keys(owner.customThemes).sort();
  assert.strictEqual(Manager.renameCustomTheme(owner, Themes, config, 'Work Palette', 'A'.repeat(33)), false);
  assert.strictEqual(Manager.renameCustomTheme(owner, Themes, config, 'Work Palette', '__proto__'), false);
  assert.strictEqual(Manager.renameCustomTheme(owner, Themes, config, 'Work Palette', 'Dracula'), false);
  assert.strictEqual(Manager.renameCustomTheme(owner, Themes, config, 'Work Palette', 'Other Palette'), false);
  assert.deepStrictEqual(Object.keys(owner.customThemes).sort(), originalKeys);
  assert.strictEqual(Manager.renameCustomTheme(owner, Themes, config, 'Work Palette', 'Renamed'), true);
  assert(owner.customThemes.Renamed);
  assert(!Object.prototype.hasOwnProperty.call(owner.customThemes, 'Work Palette'));
}

// Draft editing only accepts declared, existing theme-managed color keys and valid colors.
{
  const owner = makeOwner();
  assert.strictEqual(Manager.beginThemeEdit(owner, Themes, '14 Theme', config), true);
  assert.strictEqual(owner.themeDraft.settingsSubheading, '#abcdef', 'editor draft carries managed compatibility colors absent from built-in palettes');
  assert.strictEqual(Manager.setThemeDraftColor(owner, 'settingsSubheading', '#112233'), true);
  assert.strictEqual(owner.themeDraft.settingsSubheading, '#112233');
  assert.strictEqual(Manager.setThemeDraftColor(owner, 'accent', '#ABCDEF'), true);
  assert.strictEqual(owner.themeDraft.accent, '#abcdef');
  assert.strictEqual(Manager.setThemeDraftColor(owner, 'accent', '#1234567'), false);
  assert.strictEqual(Manager.setThemeDraftColor(owner, '__proto__', '#123456'), false);
  assert.strictEqual(Manager.setThemeDraftColor(owner, 'unknownColor', '#123456'), false);
  assert.strictEqual(Manager.setThemeDraftColor(owner, 'settingsBackground', '#123456'), false,
    'independent component colors are not editable as global theme palette fields');
  assert.strictEqual(Manager.beginThemeEdit(owner, Themes, 'missing theme'), false);
}

console.log('Custom theme names, collision protection, safe keys, and color draft validation: OK');
JS

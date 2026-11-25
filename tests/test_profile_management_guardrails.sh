#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = process.argv[2];
const source = fs.readFileSync(path.join(root, 'js/settings/SettingsProfiles.js'), 'utf8')
  .replace(/^\.pragma library\s*/m, '')
  .replace(/^\.import .*$/mg, '');
const context = {};
vm.createContext(context);
vm.runInContext(source, context, { filename: 'SettingsProfiles.js' });
const Profiles = context;
const clone = value => JSON.parse(JSON.stringify(value));
const defaults = {
  fontSize: 12, font: 'Nerd Font', colors: { accent: '#00aacc', text: '#ffffff' },
  settingsNavigationOrder: {
    groupOrder: ['appearance', 'modules', 'dashboard', 'launcher', 'general'],
    pagesByGroup: {
      appearance: ['themes', 'settingsWindow'],
      modules: ['modules', 'timers', 'player', 'mopidy', 'weather', 'cava', 'cpuRam', 'network', 'volume', 'calendar', 'notifications'],
      dashboard: ['dashboard'],
      launcher: ['launcher', 'launcherSearch', 'launcherTabs', 'launcherProjects', 'launcherActions', 'launcherAnimation', 'launcherApplications'],
      general: ['general']
    }
  }
};
function makeOwner() {
  const owner = {
    profileDefaults: clone(defaults), profileStorageFormat: 'sparse-v1',
    profiles: {}, activeProfile: '', profileList: [], profilesRevision: 0,
    resetOverrides: {}, current: clone(defaults), saveCount: 0,
    colorNames: ['accent', 'text'],
    snapshotObject() { return clone(this.current); },
    applyObject(value) { this.current = clone(value); },
    save() { this.saveCount++; },
    rebuildProfileList() {
      this.profileList = Object.keys(this.profiles).sort((a, b) => a.localeCompare(b));
      this.profilesRevision++;
    },
    expandedProfileData(name) { return Profiles.expandedProfileByName(this, name); }
  };
  return owner;
}

// Names are trimmed, while new names over the 32-character limit are rejected
// rather than truncated into a potentially colliding existing profile.
{
  const owner = makeOwner();
  assert.strictEqual(Profiles.saveProfile(owner, '  Work  '), true);
  assert.strictEqual(owner.activeProfile, 'Work');
  assert.deepStrictEqual(JSON.parse(JSON.stringify(owner.profileList)), ['Work']);
  const detachedProfileNames = Profiles.profileNames(owner);
  detachedProfileNames.push('not-a-real-profile');
  assert.strictEqual(owner.profileList.length, 1, 'profileNames returns a defensive copy');
  owner.current.fontSize = 15;
  assert.strictEqual(Profiles.saveProfile(owner, 'Work'), true, 'saving an existing name updates it');
  assert.strictEqual(owner.profileList.length, 1, 'saving an existing name must not create a duplicate');
  assert.strictEqual(owner.expandedProfileData('Work').fontSize, 15);

  const prefix = 'A'.repeat(32);
  assert.strictEqual(Profiles.saveProfile(owner, prefix), true);
  const before = clone(owner.profiles[prefix]);
  assert.strictEqual(Profiles.saveProfile(owner, prefix + '-collision'), false, 'too-long new name is rejected');
  assert.deepStrictEqual(clone(owner.profiles[prefix]), before, 'rejected long name cannot overwrite its 32-char prefix');
  assert.strictEqual(Object.keys(owner.profiles).some(name => name.length > 32), false);
  assert.strictEqual(Profiles.saveProfile(owner, '   '), false, 'blank name is rejected');
}

// A profile inherited from an older release may have a long name. Scoped and
// full saves must continue updating that exact key, never a truncated key.
{
  const owner = makeOwner();
  const legacyName = 'Legacy Profile Name Longer Than Thirty Two';
  Object.defineProperty(owner.profiles, legacyName, {
    value: Profiles.sparseProfile(owner, clone(defaults)), enumerable: true, configurable: true, writable: true
  });
  owner.profileStorageFormat = 'sparse-v1';
  owner.activeProfile = legacyName;
  owner.rebuildProfileList();
  owner.current.fontSize = 17;
  assert.strictEqual(Profiles.saveProfileScope(owner, legacyName, 'general'), true);
  assert.strictEqual(Object.prototype.hasOwnProperty.call(owner.profiles, legacyName), true);
  assert.strictEqual(Object.prototype.hasOwnProperty.call(owner.profiles, legacyName.slice(0, 32)), false);
  assert.strictEqual(owner.expandedProfileData(legacyName).fontSize, 17);
  owner.current.fontSize = 18;
  assert.strictEqual(Profiles.saveProfile(owner, legacyName), true, 'existing legacy name remains saveable');
  assert.strictEqual(owner.profileList.includes(legacyName), true);
}

// Prototype-inherited property names are not mistaken for actual profiles;
// unusual own keys still round-trip safely through save/load/delete.
{
  const owner = makeOwner();
  assert.strictEqual(Profiles.loadProfile(owner, 'toString'), false);
  assert.strictEqual(Profiles.deleteProfile(owner, 'constructor'), false);
  assert.strictEqual(Profiles.expandedProfileByName(owner, 'toString'), null);

  for (const name of ['constructor', '__proto__', 'toString']) {
    assert.strictEqual(Profiles.saveProfile(owner, name), true, `safe own-key write: ${name}`);
    assert.strictEqual(Object.prototype.hasOwnProperty.call(owner.profiles, name), true);
    assert.strictEqual(Profiles.loadProfile(owner, name), true, `own-key load: ${name}`);
  }
  assert.deepStrictEqual(JSON.parse(JSON.stringify(Object.keys(owner.profiles).sort())), ['__proto__', 'constructor', 'toString']);
  assert.strictEqual(Profiles.deleteProfile(owner, '__proto__'), true);
  assert.strictEqual(Object.prototype.hasOwnProperty.call(owner.profiles, '__proto__'), false);

  const storedProfiles = {};
  Object.defineProperty(storedProfiles, '__proto__', {
    value: Profiles.sparseProfile(owner, clone(defaults)), enumerable: true, configurable: true, writable: true
  });
  const expanded = Profiles.expandStoredSettings(owner, {
    settingsPersistenceFormat: 'profile-overrides-v1', settingsSchemaVersion: 1,
    profileStorageFormat: 'sparse-v1', profiles: storedProfiles, activeProfile: '__proto__',
    profileOverrides: {}, customThemes: {}
  });
  assert.strictEqual(Object.prototype.hasOwnProperty.call(expanded.profiles, '__proto__'), true,
    'startup migrations must preserve unusual own profile keys');
  assert.strictEqual(expanded.activeProfile, '__proto__');
}

// Deleting an inactive profile leaves the active profile intact. Deleting the
// active one clears only its identity; the live settings snapshot is retained.
{
  const owner = makeOwner();
  owner.current.fontSize = 14;
  assert.strictEqual(Profiles.saveProfile(owner, 'Active'), true);
  owner.current.fontSize = 16;
  assert.strictEqual(Profiles.saveProfile(owner, 'Other'), true);
  assert.strictEqual(Profiles.loadProfile(owner, 'Active'), true);
  assert.strictEqual(Profiles.deleteProfile(owner, 'Other'), true);
  assert.strictEqual(owner.activeProfile, 'Active');
  owner.current.fontSize = 19;
  assert.strictEqual(Profiles.deleteProfile(owner, 'Active'), true);
  assert.strictEqual(owner.activeProfile, '');
  assert.strictEqual(owner.current.fontSize, 19);
  assert.strictEqual(Profiles.profileNames(owner).length, 0);
}

const controller = fs.readFileSync(path.join(root, 'components/settings/SettingsProfileController.qml'), 'utf8');
const section = fs.readFileSync(path.join(root, 'components/settings/sections/SettingsWindowSection.qml'), 'utf8');
assert(controller.includes('Object.prototype.hasOwnProperty.call(settings.profiles, name)'), 'controller must require an own active-profile key');
assert(controller.includes('function profileNameError(name)'), 'controller exposes validation feedback to the name field');
assert(section.includes('pendingDeleteProfileName = profileCombo.currentText'), 'delete action must request confirmation first');
assert(section.includes('Подтвердить удаление профиля'), 'confirmation action must be explicit');
assert(section.includes('Отмена'), 'profile deletion must be cancellable');
console.log('profile management guardrails: normalized names, legacy compatibility, safe keys, CRUD invariants and delete confirmation: OK');
JS

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = process.argv[2];
const sectionsRoot = path.join(root, 'components/settings/sections');
function walk(dir) {
  return fs.readdirSync(dir, {withFileTypes:true}).flatMap(entry => {
    const full = path.join(dir, entry.name);
    return entry.isDirectory() ? walk(full) : (entry.name.endsWith('.qml') ? [full] : []);
  });
}
function extractBlocks(source, expression) {
  const blocks = [];
  expression.lastIndex = 0;
  let match;
  while ((match = expression.exec(source))) {
    const start = match.index;
    const open = source.indexOf('{', match.index, expression.lastIndex + 2);
    if (open < 0) continue;
    let depth = 0, quote = null, escaped = false, lineComment = false, blockComment = false;
    let end = -1;
    for (let i = open; i < source.length; i++) {
      const c = source[i], n = source[i + 1] || '';
      if (lineComment) { if (c === '\n') lineComment = false; continue; }
      if (blockComment) { if (c === '*' && n === '/') { blockComment = false; i++; } continue; }
      if (quote) {
        if (escaped) escaped = false;
        else if (c === '\\') escaped = true;
        else if (c === quote) quote = null;
        continue;
      }
      if (c === '/' && n === '/') { lineComment = true; i++; continue; }
      if (c === '/' && n === '*') { blockComment = true; i++; continue; }
      if (c === '"' || c === "'") { quote = c; continue; }
      if (c === '{') depth++;
      else if (c === '}' && --depth === 0) { end = i + 1; break; }
    }
    assert(end > 0, 'balanced SettingsGroup block');
    blocks.push({start, end, text: source.slice(start, end)});
    expression.lastIndex = start + 1; // keep scanning inside groups too, for nested SettingsGroup frames
  }
  return blocks;
}
let totalFrames = 0, selectedFrames = 0, exceptions = [], selectors = [];
for (const file of walk(sectionsRoot)) {
  const source = fs.readFileSync(file, 'utf8');
  for (const block of extractBlocks(source, /\bSettingsGroup\s*\{/g)) {
    if (!/\bshowFrame\s*:\s*true\b/.test(block.text)) continue;
    totalFrames++;
    if (/\bchangeKeys\s*:/.test(block.text)) {
      selectedFrames++;
      const selectorLine = block.text.match(/\bchangeKeys\s*:\s*\((\{.*\})\)/);
      assert(selectorLine, `${path.relative(root,file)} changeKeys selector should be a one-line object literal for static validation`);
      selectors.push({file:path.relative(root,file), spec:vm.runInNewContext('('+selectorLine[1]+')')});
      continue;
    }
    const reason =
      /\bid\s*:\s*storagePathsGroup\b/.test(block.text) ? 'app storage paths are not profile settings' :
      /\bid\s*:\s*projectSettingsCard\b/.test(block.text) ? 'launcherProjects array is tracked at its parent frame' :
      /heading\s*:\s*"Токен Gismeteo"/.test(block.text) ? 'weather token is intentionally excluded from profile markers' :
      /text\s*:\s*"Сбросить все настройки"/.test(block.text) ? 'profile action panel is not a setting group' : null;
    assert(reason, `${path.relative(root, file)} has a framed SettingsGroup without changeKeys: ${block.text.slice(0,180).replace(/\s+/g,' ')}`);
    exceptions.push({file:path.relative(root,file), reason});
  }
}
assert(totalFrames >= 70, `expected broad frame coverage, got ${totalFrames}`);
assert(selectedFrames >= 70, `too few framed groups have selectors: ${selectedFrames}/${totalFrames}`);
const group = fs.readFileSync(path.join(root,'components/settings/primitives/SettingsGroup.qml'),'utf8');
assert.strictEqual((group.match(/visible: root\.hasHeading && root\.modified/g)||[]).length, 1, 'exactly one marker beside headings');
assert(group.includes('visible: root.showFrame && root.modified && !root.hasHeading'), 'frames without an adoptable heading still show a marker');
assert(group.includes('root.settings.hasResetChanges("keys", root.changeKeys)'), 'all frame marks reuse the cached sparse override checker');

// Exercise every frame selector against the real cached-override predicate.
const settingsQml = fs.readFileSync(path.join(root,'Settings.qml'),'utf8');
const fnStart = settingsQml.indexOf('    function hasResetChanges(scope, argument) {');
const fnEnd = settingsQml.indexOf('\n    function activeProfileData()', fnStart);
assert(fnStart >= 0 && fnEnd > fnStart, 'extract hasResetChanges implementation');
const owner = {activeProfile:'Work', profiles:{Work:{}}, resetOverrides:{}};
const context = {root:owner, activeProfile:owner.activeProfile, profiles:owner.profiles};
vm.createContext(context);
vm.runInContext(settingsQml.slice(fnStart,fnEnd).trim()+'\nthis.hasResetChanges = hasResetChanges;',context,{filename:'Settings.qml#hasResetChanges'});
for (const entry of selectors) {
  const spec = entry.spec;
  owner.resetOverrides = {};
  assert.strictEqual(context.hasResetChanges('keys',spec),false, `${entry.file}: a clean frame selector remains off`);
  for (const key of (spec.keys || [])) {
    owner.resetOverrides = {[key]:'changed'};
    assert.strictEqual(context.hasResetChanges('keys',spec),true, `${entry.file}: key ${key} is detected`);
  }
  for (const prefix of (spec.prefixes || [])) {
    const probe = prefix+'__frame_indicator_test__';
    if ((spec.exclude || []).includes(probe)) continue;
    owner.resetOverrides = {[probe]:'changed'};
    assert.strictEqual(context.hasResetChanges('keys',spec),true, `${entry.file}: prefix ${prefix} is detected`);
  }
  for (const [mapName, names] of Object.entries(spec.nested || {})) {
    const probes = names.length ? names : ['__frame_indicator_test__'];
    for (const name of probes) {
      owner.resetOverrides = {[mapName]:{[name]:'changed'}};
      assert.strictEqual(context.hasResetChanges('keys',spec),true, `${entry.file}: nested ${mapName}.${name} is detected`);
    }
  }
}
console.log(`Settings frame dirty indicator coverage: ${selectedFrames}/${totalFrames} framed groups scoped; ${exceptions.length} intentional exceptions; ${selectors.length} selectors validated against cached override checker; fallback markers: OK`);
JS

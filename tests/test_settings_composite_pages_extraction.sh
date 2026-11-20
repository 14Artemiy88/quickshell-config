#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTENT="$ROOT/components/settings/SettingsPageContent.qml"
PLAYER="$ROOT/components/settings/pages/SettingsPlayerPage.qml"
MOPIDY="$ROOT/components/settings/pages/SettingsMopidyPage.qml"
fail() { echo "Settings composite pages extraction: FAIL: $*" >&2; exit 1; }

[[ -f "$PLAYER" ]] || fail 'Player page component is missing'
[[ -f "$MOPIDY" ]] || fail 'Mopidy page component is missing'
grep -Fq 'SettingsPages.SettingsPlayerPage {' "$CONTENT" || fail 'Player page is not mounted by SettingsPageContent'
grep -Fq 'SettingsPages.SettingsMopidyPage {' "$CONTENT" || fail 'Mopidy page is not mounted by SettingsPageContent'
grep -Fq 'objectName: "settings-search-page:player"' "$PLAYER" || fail 'Player stable search root is missing'
grep -Fq 'objectName: "settings-search-page:mopidy"' "$MOPIDY" || fail 'Mopidy stable search root is missing'
grep -Fq 'SettingsPlayerSection {' "$PLAYER" || fail 'Player section was not kept inside the Player page'
grep -Fq 'SettingsPlayerAnimationSection {' "$PLAYER" || fail 'Player animation section was not kept inside the Player page'
grep -Fq 'SettingsNumberField {' "$PLAYER" || fail 'Player update interval control was not moved into Player page'
for section in SettingsMopidySection SettingsMopidyTimeSection SettingsMopidyIconsSection SettingsMopidyStatusSection SettingsMopidyAnimationSection; do
    grep -Fq "MopidySettings.$section {" "$MOPIDY" || fail "$section is not owned by the Mopidy page"
done
! grep -Eq 'SettingsPlayerSection[[:space:]]*\{|MopidySettings\.SettingsMopidy(Animation|Time|Icons|Status)?Section[[:space:]]*\{' "$CONTENT" || fail 'composite page sections remain duplicated in SettingsPageContent'

ANIMATION="$ROOT/components/settings/sections/mopidy/SettingsMopidyAnimationSection.qml"
PLAYER_ANIMATION="$ROOT/components/settings/sections/SettingsPlayerAnimationSection.qml"
node - "$CONTENT" "$PLAYER" "$MOPIDY" "$ANIMATION" "$PLAYER_ANIMATION" <<'NODE'
const assert = require('assert');
const fs = require('fs');
for (const file of process.argv.slice(2)) {
  const source = fs.readFileSync(file, 'utf8');
  const stack = [];
  const pairs = { ')': '(', ']': '[', '}': '{' };
  let state = 'code', escaped = false;
  for (let i = 0; i < source.length; i++) {
    const c = source[i], n = source[i + 1];
    if (state === 'line') { if (c === '\n') state = 'code'; continue; }
    if (state === 'block') { if (c === '*' && n === '/') { state = 'code'; i++; } continue; }
    if (state === 'single' || state === 'double' || state === 'template') {
      if (escaped) { escaped = false; continue; }
      if (c === '\\') { escaped = true; continue; }
      if ((state === 'single' && c === "'") || (state === 'double' && c === '"') || (state === 'template' && c === '`')) state = 'code';
      continue;
    }
    if (c === '/' && n === '/') { state = 'line'; i++; continue; }
    if (c === '/' && n === '*') { state = 'block'; i++; continue; }
    if (c === "'") { state = 'single'; continue; }
    if (c === '"') { state = 'double'; continue; }
    if (c === '`') { state = 'template'; continue; }
    if ('([{'.includes(c)) stack.push(c);
    else if (pairs[c]) assert.strictEqual(stack.pop(), pairs[c], `${file}: unbalanced ${c}`);
  }
  assert.deepStrictEqual(stack, [], `${file}: unclosed delimiter`);
  assert.strictEqual(state, 'code', `${file}: unterminated lexical state`);
}
NODE

echo 'Settings composite pages extraction: Player/Mopidy page ownership, stable search roots and balanced QML delimiters: OK'

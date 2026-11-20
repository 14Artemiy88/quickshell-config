#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="$ROOT/js/launcher/LauncherWallpaperPicker.js"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
NAV="$ROOT/components/settings/SettingsNavigationController.qml"
UI="$ROOT/components/settings/sections/SettingsLauncherSection.qml"

node - "$MODULE" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const api = vm.runInThisContext(source + '\n({ parseQuery, displayName, isValidLocalImagePath, localFileUrl, normalizeEntries, buildResults, emptyStateMessage, screenName, screenIndex, moveGridIndex, MAX_WALLPAPERS })');
assert.deepStrictEqual(api.parseQuery('wallpaper'), { active: true, query: '', scope: 'all' }, 'bare wallpaper command opens the picker');
assert.strictEqual(api.parseQuery('wallpapers dawn').query, 'dawn', 'plural alias preserves its search term');
assert.strictEqual(api.parseQuery('wallpaper favorites sunset').scope, 'favorites', 'favorite scope is parsed before the search term');
assert.strictEqual(api.parseQuery('обои недавние лес').query, 'лес', 'Russian recent scope leaves a search term');
assert.strictEqual(api.parseQuery('обои север').query, 'север', 'Russian alias is supported');
assert.strictEqual(api.parseQuery('фон').active, false, 'ordinary фон text is not globally intercepted');
assert.strictEqual(api.parseQuery('wallpaperCustom').active, false, 'command prefix requires a token boundary');
assert.strictEqual(api.displayName('morning-view.WEBP'), 'morning-view', 'known image extension is removed from visible title');
assert.strictEqual(api.isValidLocalImagePath('/wallpapers/sunrise.jpg'), true, 'absolute supported image path is previewable');
assert.strictEqual(api.isValidLocalImagePath('/'), false, 'filesystem root is never treated as an image');
assert.strictEqual(api.isValidLocalImagePath('/wallpapers/'), false, 'directory paths are never treated as images');
assert.strictEqual(api.isValidLocalImagePath('wallpapers/sunrise.jpg'), false, 'relative paths are not passed to QQuickImage');
assert.strictEqual(api.isValidLocalImagePath('/wallpapers/readme.txt'), false, 'unsupported file types are rejected');
assert.strictEqual(api.localFileUrl('/'), '', 'empty directory path never becomes file:///');
assert.strictEqual(api.localFileUrl('/wallpapers/'), '', 'directory preview URL is suppressed');
assert.strictEqual(api.localFileUrl('/wallpapers/βeta sunrise.jpg'), 'file:///wallpapers/%CE%B2eta%20sunrise.jpg', 'valid file paths become encoded local file URLs');
const screens = [
  { name: 'DP-1', model: 'Display A' },
  { name: 'HDMI-A-1', model: 'Display B' }
];
assert.strictEqual(api.screenName(screens[1], 1), 'HDMI-A-1', 'monitor output name is used as its stable selector label');
assert.strictEqual(api.screenIndex(screens, 'hdmi-a-1'), 1, 'selected output name resolves to its Quickshell screen index');
assert.strictEqual(api.screenIndex(screens, 'missing'), -1, 'disconnected monitor names are not silently mapped to another output');
assert.strictEqual(api.moveGridIndex(4, 'left', 3, 9), 3, 'left arrow selects previous tile in the same row');
assert.strictEqual(api.moveGridIndex(4, 'right', 3, 9), 5, 'right arrow selects next tile in the same row');
assert.strictEqual(api.moveGridIndex(4, 'up', 3, 9), 1, 'up arrow selects the same column in the previous row');
assert.strictEqual(api.moveGridIndex(4, 'down', 3, 9), 7, 'down arrow selects the same column in the next row');
assert.strictEqual(api.moveGridIndex(0, 'left', 3, 9), 0, 'grid navigation does not wrap across rows');
assert.strictEqual(api.moveGridIndex(8, 'down', 3, 10), 9, 'vertical navigation clamps to the last item in a shorter final row');
const entries = api.normalizeEntries([
  { path: '/wallpapers/zebra.png', name: 'zebra.png' },
  { path: '/wallpapers/A sunrise.jpg', name: 'A sunrise.jpg' },
  { path: '/wallpapers/zebra.png', name: 'duplicate.png' },
  null,
  { path: '', name: 'empty' },
  { path: '/', name: 'filesystem-root' },
  { path: '/wallpapers/', name: 'directory' },
  { path: 'wallpapers/relative.png', name: 'relative' },
  { path: '/wallpapers/readme.txt', name: 'unsupported' },
  { path: '/wallpapers/βета.png', name: 'βета.png' }
]);
assert.deepStrictEqual(entries.map(item => item.displayName), ['A sunrise', 'zebra', 'βета'], 'catalog is deduplicated, sorted and rejects root/directory/invalid paths');
const score = (text, query) => {
  text = String(text).toLowerCase(); query = String(query).toLowerCase();
  if (!query) return 0;
  if (text === query) return 10000;
  if (text.startsWith(query)) return 9000 - text.length;
  if (text.includes(query)) return 8000 - text.indexOf(query);
  let pos = 0, result = 0;
  for (const char of query) { const at = text.indexOf(char, pos); if (at < 0) return -1; result += 100 - at; pos = at + 1; }
  return result;
};
const all = api.buildResults('', entries, score, 200);
assert.deepStrictEqual(all.map(item => item.name), ['A sunrise', 'zebra', 'βета'], 'empty query returns the full alphabetical carousel');
assert(all.every(item => item.kind === 'wallpaper' && item.path), 'each result contains an apply-ready path');
const dawn = api.buildResults('dawn', [{ path: '/w/dawn-landscape.jpg', name: 'dawn-landscape.jpg' }, { path: '/w/night.png', name: 'night.png' }], score, 200);
assert.strictEqual(dawn.length, 1, 'search filters the wallpaper catalogue');
assert.strictEqual(dawn[0].path, '/w/dawn-landscape.jpg', 'search preserves the selected local path');
assert.strictEqual(api.buildResults('no-match', entries, score, 200).length, 0, 'non-matching queries do not leak unrelated wallpapers');
assert.strictEqual(api.buildResults('', new Array(400).fill(0).map((_, i) => ({ path: `/w/${i}.png` })), score, 900).length, api.MAX_WALLPAPERS, 'result limit protects the UI from huge folders');
assert(api.emptyStateMessage(true, '', '', 0, '').includes('Загружаем'), 'loading state is explicit');
assert(api.emptyStateMessage(false, 'directory-not-found', '/missing', 0, '').includes('/missing'), 'missing directory message identifies the folder');
assert(api.emptyStateMessage(false, '', '/wallpapers', 3, 'x').includes('не найдены'), 'search empty state is distinct from an empty folder');
console.log('Wallpaper grid navigation, output selection, local catalogue normalization, sorting, search and empty states: OK');
JS

python3 - "$MODULE" "$LAUNCHER" "$CONFIG" "$DEFAULTS" "$PERSIST" "$APPLY" "$RESETS" "$NAV" "$UI" <<'PY'
from pathlib import Path
import sys
module, launcher, config, defaults, persist, apply, resets, nav, ui = [Path(p).read_text() for p in sys.argv[1:]]
assert 'LauncherWallpaperPicker.js" as LauncherWallpaperPicker' in launcher
assert 'LauncherWallpaperPicker.parseQuery(normalizedQuery)' in launcher
assert 'LauncherWallpaperPicker.buildResults(' in launcher
assert 'kind: "wallpaperPickerAction"' in launcher and 'searchField.text = ">wallpaper"' in launcher
assert 'case "wallpaper": return String(itemData.name || "")' in launcher
assert 'if (result.kind === "wallpaper")' in launcher and 'root.applyWallpaper(result.path)' in launcher
assert 'model: Quickshell.screens' in launcher and 'root.wallpaperSelectScreen(parent.modelData, parent.index)' in launcher
assert 'root.wallpaperSelectedScreenName = name' in launcher
assert 'root.wallpaperApplyPendingScreenIndex = screenIndex' in launcher
assert 'String(root.wallpaperApplyPendingScreenIndex)' in launcher
assert 'GridView {' in launcher and 'id: appList' in launcher
assert 'flow: GridView.FlowLeftToRight' in launcher, 'GridView must use the documented row-major flow enum for both wallpaper tiles and one-column app lists'
assert 'GridView.LeftToRight' not in launcher and 'GridView.TopToBottom' not in launcher, 'GridView flow constants must use their documented Flow-prefixed names'
assert 'cellWidth: root.wallpaperPickerActive && !root.wallpaperRandomMode ? width / wallpaperColumnCount : width' in launcher
assert 'property real wallpaperTileWidth: Math.max(1, width / wallpaperColumnCount - 12)' in launcher
assert 'function moveWallpaperSelection(direction)' in launcher
assert 'moveGridIndex(' in launcher
assert 'root.moveWallpaperSelection(event.key === Qt.Key_Left ? \"left\" : \"right\")' in launcher
assert 'root.wallpaperPreviewUrl(appDelegate.itemData.path)' in launcher
assert 'function wallpaperPreviewUrl(path)' in launcher
assert 'return LauncherWallpaperPicker.localFileUrl(path)' in launcher
assert 'function localFileUrl(value)' in module
assert 'if (!isValidLocalImagePath(path))' in module
assert 'property string previewUrl: appDelegate.itemData' in launcher
assert 'source: previewUrl' in launcher and 'visible: previewUrl !== ""' in launcher
assert 'Quickshell.shellDir + "/scripts/launcher_wallpapers"' in launcher
assert 'Quickshell.shellDir + "/scripts/set_wallpaper"' in launcher
assert 'function expandedWallpaperDirectory()' in launcher
assert 'return home !== "" ? home + "/" + configured : configured' in launcher, 'relative wallpaper folders resolve against HOME'
assert 'encodeURIComponent(parts[i])' in module, 'local file preview URLs encode path segments safely'
assert 'property string launcherWallpaperDirectory: ""' in config
assert 'launcherWallpaperDirectory: ""' in defaults
assert 'launcherWallpaperDirectory: String(config.launcherWallpaperDirectory || "")' in persist
assert 'Config.launcherWallpaperDirectory = String(o.launcherWallpaperDirectory || "")' in apply
assert '"launcherWallpaperDirectory"' in resets
assert 'profile.launcherWallpaperDirectory === undefined) config.launcherWallpaperDirectory = ""' in resets
assert 'launcherWallpaperDirectory' in nav
assert 'heading: "Обои рабочего стола"' in ui and 'launcherWallpaperDirectoryField' in ui
assert 'placeholderText: "~/Pictures/Wallpapers"' in ui
print('Launcher wallpaper grid navigation, monitor selector, image preview, per-output apply and profile setting integration: OK')
PY

echo 'Launcher wallpaper picker: OK'
python3 - "$LAUNCHER" <<'PYTHON'
from pathlib import Path
import re
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
pairs = {")": "(", "]": "[", "}": "{"}
stack = []
state = "code"
i = 0
line = 1
previous = ""
regex_keywords = {"return", "throw", "case", "delete", "typeof", "void", "new", "in", "of", "instanceof", "yield", "await"}
while i < len(source):
    c = source[i]
    n = source[i + 1] if i + 1 < len(source) else ""
    if c == "\n":
        line += 1
        if state == "line_comment": state = "code"
        i += 1
        continue
    if state == "line_comment":
        i += 1; continue
    if state == "block_comment":
        if c == "*" and n == "/": state = "code"; i += 2
        else: i += 1
        continue
    if state in ("single", "double", "template"):
        quote = {"single": "'", "double": '"', "template": "`"}[state]
        if c == "\\": i += 2; continue
        if c == quote: state = "code"
        i += 1; continue
    if c == "/" and n == "/": state = "line_comment"; i += 2; continue
    if c == "/" and n == "*": state = "block_comment"; i += 2; continue
    if c == "/":
        previous_word = re.search(r"([A-Za-z_$][\w$]*)\s*$", source[:i])
        word = previous_word.group(1) if previous_word else ""
        if previous in "=(:,[!&|?{};" or word in regex_keywords:
            i += 1
            in_class = False
            escaped = False
            while i < len(source):
                ch = source[i]
                if ch == "\n": line += 1
                if escaped:
                    escaped = False
                elif ch == "\\":
                    escaped = True
                elif ch == "[":
                    in_class = True
                elif ch == "]":
                    in_class = False
                elif ch == "/" and not in_class:
                    i += 1
                    while i < len(source) and source[i].isalpha(): i += 1
                    previous = "x"
                    break
                i += 1
            else:
                raise SystemExit(f"{Path(sys.argv[1]).name}: unterminated regular expression")
            continue
    if c == "'": state = "single"
    elif c == '"': state = "double"
    elif c == '`': state = "template"
    elif c in "([{": stack.append((c, line))
    elif c in ")]}":
        if not stack or stack[-1][0] != pairs[c]:
            raise SystemExit(f"Launcher.qml delimiter mismatch at line {line}: {c}")
        stack.pop()
    if not c.isspace(): previous = c
    i += 1
if state in ("single", "double", "template", "block_comment"):
    raise SystemExit(f"Launcher.qml has unterminated {state}")
if stack:
    raise SystemExit(f"Launcher.qml has unclosed {stack[-1][0]} from line {stack[-1][1]}")
print("Launcher.qml delimiter balance: OK")
PYTHON

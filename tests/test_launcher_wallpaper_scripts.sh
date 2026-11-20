#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LIST="$ROOT/scripts/launcher_wallpapers"
SET="$ROOT/scripts/set_wallpaper"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

wallpaper_dir="$TMP/Pictures/Wallpapers"
mkdir -p "$wallpaper_dir/nested" "$wallpaper_dir/folder-that-looks-like-an-image.jpg"
touch "$wallpaper_dir/A sunrise.jpg" "$wallpaper_dir/βета \"wide\".png" "$wallpaper_dir/not-an-image.txt" "$wallpaper_dir/nested/Deep blue.WEBP"

"$LIST" "$wallpaper_dir" 42 > "$TMP/catalog.json"
node - "$TMP/catalog.json" <<'JS'
const fs = require('fs'); const assert = require('assert');
const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
assert.strictEqual(data.generation, 42, 'catalog response retains request generation');
assert.strictEqual(data.error, '', 'existing directory has no error');
assert.strictEqual(data.items.length, 3, 'supported image extensions are found at the root and one subdirectory; image-looking directories are excluded');
assert(data.items.some(item => item.name === 'A sunrise.jpg'), 'spaces in filenames survive JSON encoding');
assert(data.items.some(item => item.name === 'βета "wide".png'), 'Unicode and quotes survive JSON encoding');
assert(data.items.some(item => item.name === 'Deep blue.WEBP'), 'extension matching is case-insensitive');
assert(data.items.every(item => item.path.startsWith('/')), 'catalog paths are absolute');
console.log('Wallpaper catalog script: extension filtering, JSON escaping, nested files and generation: OK');
JS

HOME="$TMP" TEST_HOME="$TMP" "$LIST" "~/Pictures/Wallpapers" 44 > "$TMP/tilde.json"
TEST_HOME="$TMP" node - "$TMP/tilde.json" <<'JS'
const fs = require('fs'); const assert = require('assert');
const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
assert.strictEqual(data.error, '', 'tilde path expands against HOME');
assert.strictEqual(data.directory, `${process.env.TEST_HOME}/Pictures/Wallpapers`, 'tilde path resolves to a canonical absolute directory');
console.log('Wallpaper catalogue tilde path expansion: OK');
JS

HOME="$TMP" TEST_HOME="$TMP" "$LIST" '$HOME/Pictures/Wallpapers' 45 > "$TMP/home-variable.json"
TEST_HOME="$TMP" node - "$TMP/home-variable.json" <<'JS'
const fs = require('fs'); const assert = require('assert');
const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
assert.strictEqual(data.error, '', '$HOME path expands without invoking a shell');
assert.strictEqual(data.directory, `${process.env.TEST_HOME}/Pictures/Wallpapers`, '$HOME resolves to canonical directory');
console.log('Wallpaper catalogue $HOME path expansion: OK');
JS

"$LIST" "$TMP/missing" 43 > "$TMP/missing.json"
node - "$TMP/missing.json" <<'JS'
const fs = require('fs'); const assert = require('assert');
const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
assert.strictEqual(data.generation, 43);
assert.strictEqual(data.error, 'directory-not-found');
assert.deepStrictEqual(data.items, []);
console.log('Wallpaper missing-directory response: OK');
JS

mkdir -p "$TMP/bin" "$TMP/empty-bin"
cat > "$TMP/bin/plasma-apply-wallpaperimage" <<'SH'
#!/usr/bin/env bash
printf 'plasma-all|%s\n' "$1" >> "$WALLPAPER_TEST_LOG"
SH
cat > "$TMP/bin/qdbus6" <<'SH'
#!/usr/bin/env bash
printf 'qdbus|%s\n' "$*" >> "$WALLPAPER_TEST_LOG"
printf 'WALLPAPER_SET_OK\n'
SH
cat > "$TMP/bin/swww" <<'SH'
#!/usr/bin/env bash
printf 'swww|%s\n' "$*" >> "$WALLPAPER_TEST_LOG"
SH
chmod +x "$TMP/bin/plasma-apply-wallpaperimage" "$TMP/bin/qdbus6" "$TMP/bin/swww"
touch "$TMP/image with spaces.jpg"

# KDE uses Plasma's per-desktop scripting API. The selected monitor index is
# explicit; plasma-apply-wallpaperimage must never be used because it changes all outputs.
WALLPAPER_TEST_LOG="$TMP/backend.log" XDG_CURRENT_DESKTOP=KDE PATH="$TMP/bin:/usr/bin:/bin" \
    bash "$SET" "$TMP/image with spaces.jpg" DP-2 1 > "$TMP/plasma.out"
grep -Fq "qdbus|org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript" "$TMP/backend.log"
grep -Fq "var targetScreenIndex = 1" "$TMP/backend.log"
grep -Fq "desktopForScreen(targetScreenIndex)" "$TMP/backend.log"
grep -Fq "targetDesktop.writeConfig('Image'" "$TMP/backend.log"
grep -Fq "print('WALLPAPER_SET_OK')" "$TMP/backend.log"

# Quotes and URL-reserved characters in filenames must remain inside the
# JavaScript string and be encoded by Plasma's script before config is written.
special_image="$TMP/image with 'quotes' #1.jpg"
touch "$special_image"
: > "$TMP/backend.log"
WALLPAPER_TEST_LOG="$TMP/backend.log" XDG_CURRENT_DESKTOP=KDE PATH="$TMP/bin:/usr/bin:/bin" \
    bash "$SET" "$special_image" DP-2 1 >/dev/null
grep -Fq "image with \\'quotes\\' #1.jpg" "$TMP/backend.log"
grep -Fq "encodeURIComponent(part)" "$TMP/backend.log"

if grep -Fq 'plasma-all|' "$TMP/backend.log"; then
    echo 'Plasma all-screen helper must not be called by per-monitor mode' >&2
    exit 1
fi

# Niri/swww receives the exact output selector, not a global all-output request.
: > "$TMP/backend.log"
WALLPAPER_TEST_LOG="$TMP/backend.log" XDG_CURRENT_DESKTOP=niri PATH="$TMP/bin:/usr/bin:/bin" \
    bash "$SET" "$TMP/image with spaces.jpg" HDMI-A-1 1
 grep -Fq "swww|img --outputs HDMI-A-1 $TMP/image with spaces.jpg" "$TMP/backend.log"

# Shell metacharacters in a filename must remain a single argv value.
tricky_parent="$TMP/image.jpg; touch $TMP"
mkdir -p "$tricky_parent"
tricky_image="$tricky_parent/selected.png"
touch "$tricky_image"
rm -f "$TMP/selected.png"
: > "$TMP/backend.log"
WALLPAPER_TEST_LOG="$TMP/backend.log" XDG_CURRENT_DESKTOP=niri PATH="$TMP/bin:/usr/bin:/bin" \
    bash "$SET" "$tricky_image" HDMI-A-1 1
grep -Fq "swww|img --outputs HDMI-A-1 $tricky_image" "$TMP/backend.log"
[[ ! -e "$TMP/selected.png" ]]

# KDE must fail safely when D-Bus tooling is unavailable instead of falling
# back to a command that overwrites every monitor.
mkdir -p "$TMP/plasma-only-bin"
cp "$TMP/bin/plasma-apply-wallpaperimage" "$TMP/plasma-only-bin/"
set +e
WALLPAPER_TEST_LOG="$TMP/backend.log" PATH="$TMP/plasma-only-bin" XDG_CURRENT_DESKTOP=KDE \
    /bin/bash "$SET" "$TMP/image with spaces.jpg" DP-2 1 2> "$TMP/no-qdbus.err"
status=$?
set -e
[[ "$status" -eq 127 ]]
grep -Fq 'refusing to change all screens' "$TMP/no-qdbus.err"
if grep -Fq 'plasma-all|' "$TMP/backend.log"; then
    echo 'Plasma must not fall back to its all-screen helper when qdbus is missing' >&2
    exit 1
fi

# Missing per-monitor backends must be reported explicitly.
set +e
PATH="$TMP/empty-bin" XDG_CURRENT_DESKTOP=niri /bin/bash "$SET" "$TMP/image with spaces.jpg" HDMI-A-1 1 2> "$TMP/no-backend.err"
status=$?
set -e
[[ "$status" -eq 127 ]]
grep -Fq 'no per-monitor backend found' "$TMP/no-backend.err"

echo 'Wallpaper per-monitor backends (Plasma D-Bus/Niri swww outputs), argv-safe paths and safe missing-backend errors: OK'

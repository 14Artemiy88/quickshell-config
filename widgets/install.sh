#!/bin/sh
set -eu
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/desktop-shell"
SOURCE_DIR=$(pwd)
mkdir -p "$TARGET"

# Preserve an existing settings file when moving from an earlier installation.
# Only files matching this shell's settings structure are considered.
if [ ! -f "$TARGET/settings.json" ]; then
    BASE="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
    for candidate in "$BASE"/*/settings.json; do
        [ -f "$candidate" ] || continue
        case "$candidate" in "$TARGET/settings.json") continue ;; esac
        if jq -e '(.modules.time? != null) and (.modules.timer? != null) and (.geometry.player? != null)' "$candidate" >/dev/null 2>&1; then
            cp "$candidate" "$TARGET/settings.json"
            printf 'Imported existing settings from %s\n' "$candidate"
            break
        fi
    done
fi

cp -a "$SOURCE_DIR"/. "$TARGET/"
rm -f "$TARGET/settings.json".bak
printf 'Installed to %s\n' "$TARGET"
printf 'Run: quickshell -c %s\n' "$TARGET"

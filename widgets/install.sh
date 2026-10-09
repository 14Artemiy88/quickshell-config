#!/bin/sh
set -eu
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/desktop-shell"
USER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell-widgets"
USER_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/quickshell-widgets"
SOURCE_DIR=$(pwd)
mkdir -p "$TARGET" "$USER_CONFIG" "$USER_DATA"

# Safely import compatible legacy data before installing code. Never overwrite
# canonical XDG files and never delete originals, so this is safe to rerun.
if [ ! -f "$USER_CONFIG/settings.json" ]; then
    BASE="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
    for candidate in "$TARGET/settings.json" "$SOURCE_DIR/settings.json" "$BASE"/*/settings.json; do
        [ -f "$candidate" ] || continue
        [ "$candidate" = "$USER_CONFIG/settings.json" ] && continue
        if jq -e 'type == "object" and (.modules.time? != null) and (.modules.timer? != null) and ((.geometry? | type) == "object")' "$candidate" >/dev/null 2>&1; then
            tmp=$(mktemp "$USER_CONFIG/.settings.json.migrate.XXXXXX")
            cp "$candidate" "$tmp"
            chmod 600 "$tmp"
            if [ ! -e "$USER_CONFIG/settings.json" ]; then
                mv -n "$tmp" "$USER_CONFIG/settings.json"
            fi
            [ ! -e "$tmp" ] || rm -f "$tmp"
            if [ -f "$USER_CONFIG/settings.json" ]; then
                printf 'Imported settings from %s\n' "$candidate"
                break
            fi
        fi
    done
fi

if [ ! -f "$USER_DATA/calendar-notes.json" ]; then
    BASE="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
    for candidate in "$TARGET/calendar-notes.json" "$SOURCE_DIR/calendar-notes.json" "$BASE"/*/calendar-notes.json; do
        [ -f "$candidate" ] || continue
        if jq -e 'type == "object"' "$candidate" >/dev/null 2>&1; then
            tmp=$(mktemp "$USER_DATA/.calendar-notes.json.migrate.XXXXXX")
            cp "$candidate" "$tmp"
            chmod 600 "$tmp"
            if [ ! -e "$USER_DATA/calendar-notes.json" ]; then
                mv -n "$tmp" "$USER_DATA/calendar-notes.json"
            fi
            [ ! -e "$tmp" ] || rm -f "$tmp"
            if [ -f "$USER_DATA/calendar-notes.json" ]; then
                printf 'Imported calendar notes from %s\n' "$candidate"
                break
            fi
        fi
    done
fi

cp -a "$SOURCE_DIR"/. "$TARGET"/
printf 'Installed code to %s\n' "$TARGET"
printf 'User settings: %s/settings.json\n' "$USER_CONFIG"
printf 'Calendar notes: %s/calendar-notes.json\n' "$USER_DATA"
printf 'Run: quickshell -c %s\n' "$TARGET"

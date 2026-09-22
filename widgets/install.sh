#!/bin/sh
set -eu
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/eww-port"
mkdir -p "$TARGET"
cp -a ./. "$TARGET/"
printf 'Installed to %s\n' "$TARGET"
printf 'Run: quickshell -c %s\n' "$TARGET"

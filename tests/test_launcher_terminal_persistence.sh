#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"

# The Translate transform is outside the Rectangle's lexical property scope;
# it must reference launcherBox explicitly to avoid ReferenceError at runtime.
grep -Fq 'y: launcherBox.entranceReady ? 0 : 10' "$LAUNCHER"

# Terminal-oriented commands must leave a shell open after the command exits,
# so one-shot programs (for example fastfetch) do not close the terminal and
# erase their output immediately.
grep -Fq 'exec foot -- zsh -ic "$1; exec zsh -i"' "$LAUNCHER"
for command in fastfetch btop htop nvim; do
    grep -Fq "\"$command\"" "$LAUNCHER"
done

echo 'launcher terminal persistence and entrance animation scope: OK'

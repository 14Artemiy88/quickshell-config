#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"
mkdir -p "$REPO/config" "$REPO/.git-test-nested"
cp "$ROOT/.gitignore" "$REPO/.gitignore"
git -C "$REPO" init -q

# Portable configuration must remain trackable at root and in nested paths.
for rel in settings.json profiles.json config/settings.json config/profiles.json; do
  ! git -C "$REPO" check-ignore -q -- "$rel" || { echo "portable file unexpectedly ignored: $rel" >&2; exit 1; }
done
# All local credentials and sidecars must be ignored at any depth.
for rel in \
  secrets.json config/secrets.json \
  .secrets.json.bak config/.secrets.json.bak \
  .settings.json.bak config/.settings.json.bak \
  .profiles.json.bak config/.profiles.json.bak \
  .settings.lock config/.settings.lock \
  .storage-paths.conf config/.storage-paths.conf \
  .migration-settings-v1 config/.migration-settings-v1 \
  settings.json.before-launcher-project-recovery-20261022-110031 config/settings.json.before-launcher-project-recovery-20261022-110031 \
  calendar-notes.json config/calendar-notes.json \
  calendar-marks.json config/calendar-marks.json; do
  git -C "$REPO" check-ignore -q -- "$rel" || { echo "local storage sidecar is not ignored: $rel" >&2; exit 1; }
done
printf 'Nested storage .gitignore rules: OK\n'

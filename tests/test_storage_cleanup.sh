#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/config" XDG_DATA_HOME="$TMP/data" XDG_STATE_HOME="$TMP/state" XDG_CACHE_HOME="$TMP/cache"
mkdir -p "$XDG_CONFIG_HOME/quickshell-widgets"
DIR="$XDG_CONFIG_HOME/quickshell-widgets"
# Five old recovery snapshots: cleanup must retain the newest three.
for n in 1 2 3 4 5; do
  printf 'snapshot-%s\n' "$n" > "$DIR/settings.json.before-launcher-project-recovery-2026010${n}-110031"
  touch -d '20 days ago' "$DIR/settings.json.before-launcher-project-recovery-2026010${n}-110031"
done
# Files that must never be touched by this cleanup.
printf '{}' > "$DIR/.settings.json.bak"
printf '{}' > "$DIR/.secrets.json.bak"
printf '{}' > "$DIR/secrets.json"
printf '{}' > "$DIR/settings.json.before-launcher-project-recovery-20261024-110031"
touch -d '20 days ago' "$DIR/.settings.json.bak" "$DIR/.secrets.json.bak" "$DIR/secrets.json"
"$ROOT/scripts/cleanup_storage" >/dev/null
count=$(find "$DIR" -maxdepth 1 -type f -name 'settings.json.before-launcher-project-recovery-*' | wc -l)
[[ "$count" -eq 3 ]] || { echo "expected 3 snapshots retained, got $count" >&2; exit 1; }
[[ -f "$DIR/settings.json.before-launcher-project-recovery-20261024-110031" ]] || { echo "recent snapshot was removed" >&2; exit 1; }
for file in .settings.json.bak .secrets.json.bak secrets.json; do [[ -f "$DIR/$file" ]] || { echo "protected file removed: $file" >&2; exit 1; }; done
# With only three snapshots, no further deletion is allowed.
"$ROOT/scripts/cleanup_storage" >/dev/null
[[ "$(find "$DIR" -maxdepth 1 -type f -name 'settings.json.before-launcher-project-recovery-*' | wc -l)" -eq 3 ]]
# Syntax and ignore rules are part of the contract.
bash -n "$ROOT/scripts/cleanup_storage"
grep -Fxq '.secrets.json*' "$ROOT/.gitignore"
grep -Fxq '/.secrets.json.bak' "$ROOT/.gitignore"
GIT_TEST="$TMP/gitignore-test"
mkdir -p "$GIT_TEST"
cp "$ROOT/.gitignore" "$GIT_TEST/.gitignore"
git -C "$GIT_TEST" init -q
touch "$GIT_TEST/settings.json" "$GIT_TEST/profiles.json" "$GIT_TEST/secrets.json"
! git -C "$GIT_TEST" check-ignore -q settings.json || { echo 'portable settings.json must not be ignored' >&2; exit 1; }
! git -C "$GIT_TEST" check-ignore -q profiles.json || { echo 'portable profiles.json must not be ignored' >&2; exit 1; }
git -C "$GIT_TEST" check-ignore -q secrets.json || { echo 'local secrets.json must be ignored' >&2; exit 1; }
printf 'Storage cleanup safety: OK\n'

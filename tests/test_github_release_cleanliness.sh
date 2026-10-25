#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECTS="$ROOT/js/settings/SettingsLauncherProjects.js"
GITIGNORE="$ROOT/.gitignore"
README="$ROOT/README.md"

# Public defaults must never reintroduce machine-local IDE or project paths.
grep -Fqx 'var DEFAULT_PROJECTS = [];' "$PROJECTS"
! grep -q '"ide":' "$PROJECTS"
! grep -q '"path":' "$PROJECTS"

# Keep one main README, and make sure setup, configuration, dependencies and tests are documented.
extra_readmes="$(find "$ROOT" -type f -iname 'readme*' ! -path "$README" -print)"
[[ -z "$extra_readmes" ]] || { printf 'Unexpected additional README files:\n%s\n' "$extra_readmes" >&2; exit 1; }
for section in '## Русский' '## English' '### Требования' '### Requirements' '### Установка и обновление' '### Install and update' '### Разработка и тесты' '### Development and tests'; do
    grep -Fq "$section" "$README" || { echo "README missing section: $section" >&2; exit 1; }
done

! grep -Fqx '/settings.json' "$GITIGNORE"
! grep -Fqx '/profiles.json' "$GITIGNORE"
grep -Fq 'secrets.json' "$GITIGNORE"
grep -Fqx '/calendar-notes.json' "$GITIGNORE"
grep -Fq 'XDG_CONFIG_HOME' "$ROOT/install.sh"

echo 'GitHub source hygiene: clean project defaults, user data ignored, one bilingual README: OK'

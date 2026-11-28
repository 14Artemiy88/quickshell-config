#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECTS="$ROOT/js/settings/SettingsLauncherProjects.js"
GITIGNORE="$ROOT/.gitignore"
README="$ROOT/README.md"

# Public defaults must never include machine-local IDE or project paths.
grep -Fqx 'var DEFAULT_PROJECTS = [];' "$PROJECTS"
! grep -q '"ide":' "$PROJECTS"
! grep -q '"path":' "$PROJECTS"

# Ship one product README and no internal design/version-history documents.
README_EN="$ROOT/README.en.md"
extra_readmes="$(find "$ROOT" -type f -iname 'readme*' ! -path "$README" ! -path "$README_EN" -print)"
[[ -z "$extra_readmes" ]] || { printf 'Unexpected additional README files:\n%s\n' "$extra_readmes" >&2; exit 1; }
[[ -f "$README_EN" ]] || { echo 'Missing English README.md companion: README.en.md' >&2; exit 1; }
[[ ! -d "$ROOT/docs" ]] || { echo 'Internal docs/ must not be shipped in the project archive' >&2; exit 1; }
for section in '### Возможности' '### Требования' '### Установка и запуск' '### Разработка и тесты'; do
    grep -Fq "$section" "$README" || { echo "Russian README missing section: $section" >&2; exit 1; }
done
for section in '### Features' '### Requirements' '### Install and update' '### Development and tests'; do
    grep -Fq "$section" "$README_EN" || { echo "English README missing section: $section" >&2; exit 1; }
done
grep -Fq '[English](README.en.md)' "$README" || { echo 'Russian README must link to the English version' >&2; exit 1; }
grep -Fq '[Русский](README.md)' "$README_EN" || { echo 'English README must link to the Russian version' >&2; exit 1; }
! grep -Fq '## English' "$README" || { echo 'English content must live in README.en.md' >&2; exit 1; }
! grep -Fq '## Русский' "$README_EN" || { echo 'Russian content must live in README.md' >&2; exit 1; }
for readme_file in "$README" "$README_EN"; do
    if grep -Eiq '^#{1,6}[[:space:]].*(v[0-9]{3,}|version[[:space:]_-]*history|release[[:space:]_-]*history|история[[:space:]]+версий|история[[:space:]]+изменений)' "$readme_file"; then
        echo 'README files must describe the product, not individual versions or release history' >&2
        exit 1
    fi
done

# The main settings/profile files are intentionally trackable for explicit
# configuration sync; private data and all runtime migration/recovery sidecars
# must be ignored by Git. Verify the actual Git pattern behavior in a temp repo.
ignore_tmp="$(mktemp -d)"
trap 'rm -rf "$ignore_tmp"' EXIT
if ! command -v git >/dev/null 2>&1; then
    echo 'git is required for the release .gitignore behavior check' >&2
    exit 1
fi
git -C "$ignore_tmp" init -q
cp "$GITIGNORE" "$ignore_tmp/.gitignore"
ignored_paths=(
    'secrets.json'
    '.secrets.json.corrupt.123'
    '.secrets.json.bak'
    '.env'
    '.env.local'
    'calendar-notes.json'
    'calendar-marks.json'
    '.migration-settings-v1'
    '.migration-calendar-notes-v1'
    '.migration-calendar-marks-v1'
    '.settings.json.migrate.ABC123'
    '.calendar-notes.json.migrate.ABC123'
    '.calendar-notes-init.ABC123'
    '.calendar-notes.ABC123'
    '.calendar-marks-init.ABC123'
    '.calendar-marks.ABC123'
    '.settings.json.corrupt.123'
    '.settings.json.bak'
    '.settings.json.backup-corrupt.123'
    '.profiles.json.corrupt.123'
    '.profiles.json.bak'
    '.settings-profile-transaction.pending'
    '.settings-transaction-restore.ABC123'
    '.settings-scrub.ABC123'
    '.storage-paths.lock'
    '.calendar-notes.lock'
    '.calendar-marks.lock'
    '.settings-backup-migrate.ABC123'
    '.profiles-backup-migrate.ABC123'
    '.storage-paths.conf.ABC123'
    'settings.json.before-launcher-project-recovery-20261124083000'
    'settings.json.qsw-backup-20261124083000-1234'
    'calendar-notes.json.qsw-backup-20261124083000-1234'
    '.settings.lock'
    '.profiles.lock'
    'nested/.migration-profile-v1'
    'nested/.settings.json.migrate.ABC123'
    'nested/secrets.json'
    'nested/calendar-notes.json'
    '__pycache__/module.cpython-313.pyc'
    '.cache/runtime-data'
    '.venv/bin/python'
    '.direnv/profile'
    'result'
    'result-1/bin/program'
    '.coverage'
    'htmlcov/index.html'
    'node_modules/package/index.js'
    'build/generated.qmlc'
    'dist/output.js'
    'local-check.log'
    'nested/another.log'
    '.mpris-art-cover.lock'
    '.mpv-track.tmp.png'
    'editor.swp'
    'staging.tmp.1234'
)
for relative_path in "${ignored_paths[@]}"; do
    mkdir -p "$ignore_tmp/$(dirname "$relative_path")"
    : > "$ignore_tmp/$relative_path"
    if ! git -C "$ignore_tmp" check-ignore -q --no-index "$relative_path"; then
        printf 'Expected path to be ignored by .gitignore: %s\n' "$relative_path" >&2
        exit 1
    fi
done
for trackable_path in settings.json profiles.json README.md README.en.md LICENSE .env.example; do
    : > "$ignore_tmp/$trackable_path"
    if git -C "$ignore_tmp" check-ignore -q --no-index "$trackable_path"; then
        printf 'Path must remain trackable: %s\n' "$trackable_path" >&2
        exit 1
    fi
done

# Avoid accumulating duplicate rules in the ignore file.
duplicates="$(grep -vE '^[[:space:]]*(#|$)' "$GITIGNORE" | sort | uniq -d || true)"
[[ -z "$duplicates" ]] || { printf 'Duplicate .gitignore rules:\n%s\n' "$duplicates" >&2; exit 1; }

# The weather token must stay separate from settings/profile sync.
grep -Fq 'secrets.json' "$GITIGNORE"
grep -Fq 'calendar-notes.json' "$GITIGNORE"
grep -Fq 'calendar-marks.json' "$GITIGNORE"
grep -Fq 'XDG_CONFIG_HOME' "$ROOT/install.sh"

echo 'GitHub source hygiene: separate linked RU/EN READMEs, no version log, migration and local data ignored, settings/profile sync preserved: OK'

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"

# Projects still use the existing fuzzy search; each visible searchable field
# now renders matching characters as themed rich text.
grep -q 'function rebuildProjectsModel()' "$LAUNCHER"
grep -q 'function highlightProjectMatch(text, query)' "$LAUNCHER"
grep -Fq 'const tokens = queryText.split(/\s+/)' "$LAUNCHER"
grep -q 'theme.accent' "$LAUNCHER"

PROJECT_BLOCK="$(sed -n '/PROJECTS — all configured repositories/,/POWER/p' "$LAUNCHER")"
[ "$(grep -c 'root.highlightProjectMatch(' <<< "$PROJECT_BLOCK")" -eq 3 ]
[ "$(grep -c 'textFormat: Text.StyledText' <<< "$PROJECT_BLOCK")" -eq 3 ]
grep -q 'modelData.name' <<< "$PROJECT_BLOCK"
grep -q 'modelData.path' <<< "$PROJECT_BLOCK"
grep -q 'projectIdeLabel(projectDelegate.modelData.ide)' <<< "$PROJECT_BLOCK"

# Highlight generation must continue escaping project-supplied text before
# inserting it into rich text markup.
grep -q 'root.escapeHtml(text\[i\])' "$LAUNCHER"
grep -q 'Only color a word when the entire token matches this field' "$LAUNCHER"

echo 'launcher project search highlighting: OK'

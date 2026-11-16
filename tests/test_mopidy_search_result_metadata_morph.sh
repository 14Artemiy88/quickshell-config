#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/mopidy/MopidyLibraryView.qml"

grep -Fq 'id: searchResultTextArea' "$FILE"
grep -Fq 'readonly property string metadataText:' "$FILE"
grep -Fq 'id: searchResultMetadataMorph' "$FILE"
grep -Fq 'height: Math.max(1, searchResultMetadataMorph.geometryY)' "$FILE"
grep -Fq 'fromGeometry: Qt.rect(0, parent.height - 6, parent.width, 0)' "$FILE"
grep -Fq 'progress: searchResultTextArea.metadataText.length > 0 ? 1 : 0' "$FILE"
grep -Fq 'visible: searchResultTextArea.metadataText.length > 0 || normalizedProgress > 0.001' "$FILE"
grep -Fq 'model: controller.searchResults' "$FILE"
printf 'Mopidy search result metadata morph: OK\n'

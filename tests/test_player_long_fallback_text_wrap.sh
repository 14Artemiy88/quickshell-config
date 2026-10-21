#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAYER="$ROOT/components/Player.qml"

grep -Fq 'id: silenceMetrics' "$PLAYER"
grep -Fq 'text: silenceText.text' "$PLAYER"
grep -Fq 'property bool needsMultiline: text.length > 0 && silenceMetrics.advanceWidth > width' "$PLAYER"
grep -Fq 'fontSizeMode: needsMultiline ? Text.FixedSize : Text.HorizontalFit' "$PLAYER"
grep -Fq 'wrapMode: needsMultiline ? Text.Wrap : Text.NoWrap' "$PLAYER"
grep -Fq 'maximumLineCount: needsMultiline ? 3 : 1' "$PLAYER"
grep -Fq 'elide: Text.ElideRight' "$PLAYER"
printf 'Player long fallback text wrapping: OK\n'

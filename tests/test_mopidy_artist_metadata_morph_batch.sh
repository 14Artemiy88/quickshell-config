#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bash "$ROOT/tests/test_mopidy_queue_artist_line_morph.sh"
bash "$ROOT/tests/test_mopidy_search_result_metadata_morph.sh"
python3 - "$ROOT/components/mopidy/MopidyQueueTrackRow.qml" "$ROOT/components/mopidy/MopidyLibraryView.qml" <<'PYCODE'
from pathlib import Path
import sys
for filename in sys.argv[1:]:
    source = Path(filename).read_text(encoding="utf-8")
    stack = []
    quote = None
    escaped = False
    line_comment = False
    block_comment = False
    pairs = {")": "(", "]": "[", "}": "{"}
    i = 0
    while i < len(source):
        ch = source[i]
        nxt = source[i + 1] if i + 1 < len(source) else ""
        if line_comment:
            if ch == "\n":
                line_comment = False
            i += 1
            continue
        if block_comment:
            if ch == "*" and nxt == "/":
                block_comment = False
                i += 2
                continue
            i += 1
            continue
        if quote:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == quote:
                quote = None
            i += 1
            continue
        if ch == "/" and nxt == "/":
            line_comment = True
            i += 2
            continue
        if ch == "/" and nxt == "*":
            block_comment = True
            i += 2
            continue
        if ch in ('"', "'", "`"):
            quote = ch
            i += 1
            continue
        if ch in "([{":
            stack.append((ch, i))
        elif ch in ")]}" :
            if not stack or stack[-1][0] != pairs[ch]:
                raise SystemExit(f"{filename}: unbalanced {ch} at offset {i}")
            stack.pop()
        i += 1
    if quote or block_comment or stack:
        raise SystemExit(f"{filename}: unterminated QML construct")
    print(Path(filename).name + ": delimiters OK")
PYCODE
printf 'Mopidy artist metadata MorphGeometry batch: OK\n'

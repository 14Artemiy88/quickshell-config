#!/bin/bash
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
echo "== QML files =="
find "$ROOT" -name '*.qml' -print0 | xargs -0 -n1 bash -c 'echo "  $0"'
echo "== Bash syntax =="
find "$ROOT/scripts" -type f ! -name '*.lua' -print0 | while IFS= read -r -d '' f; do bash -n "$f"; done
echo "bash syntax: OK"
echo "== CPU JSON smoke test =="
timeout 2s "$ROOT/scripts/cpu_stats" | head -n1 | python3 -c 'import json,sys; x=json.load(sys.stdin); assert isinstance(x["cpu"], list); assert "ram" in x; print("cpu json: OK", len(x["cpu"]), "cores")'
echo "== Checks complete =="

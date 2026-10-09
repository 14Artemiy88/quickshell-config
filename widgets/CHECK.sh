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
echo "== XDG user-data migration test =="
bash "$ROOT/tests/test_xdg_migration.sh"
echo "== Mopidy background persistence test =="
bash "$ROOT/tests/test_mopidy_background_persistence.sh"
echo "== Mopidy file filter test =="
bash "$ROOT/tests/test_mopidy_file_filter.sh"
echo "== Mopidy shared row height test =="
bash "$ROOT/tests/test_mopidy_shared_row_height.sh"
echo "== Mopidy duration alignment and folder navigation test =="
bash "$ROOT/tests/test_mopidy_alignment_folder_navigation.sh"
echo "== Mopidy tab click-to-queue test =="
bash "$ROOT/tests/test_mopidy_tab_click_to_queue.sh"
echo "== CPU graph modes test =="
bash "$ROOT/tests/test_cpu_graph_modes.sh"
echo "== CPU/RAM direction test =="
bash "$ROOT/tests/test_cpu_ram_direction.sh"
echo "== Checks complete =="

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/Mopidy.qml" "$ROOT/components/settings/sections/SettingsMopidyTimeSection.qml" <<'PYCODE'
from pathlib import Path
import sys
qml = Path(sys.argv[1]).read_text()
settings = Path(sys.argv[2]).read_text()
assert 'id: browseListView' in qml
assert 'height: Config.mopidyTrackRowHeight' in qml[qml.index('id: browseListView'):qml.index('text: "Папка пуста"')]
playlists_start = qml.index('model: root.playlists')
playlists_end = qml.index('text: "Плейлистов нет"', playlists_start)
assert 'height: Config.mopidyTrackRowHeight' in qml[playlists_start:playlists_end]
assert 'text: "Высота строки списка"' in settings
print('Mopidy shared row height: OK')
PYCODE

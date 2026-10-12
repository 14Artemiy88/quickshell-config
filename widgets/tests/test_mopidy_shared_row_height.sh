#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT/components/mopidy/Mopidy.qml" "$ROOT/components/mopidy/MopidyFileBrowser.qml" "$ROOT/components/mopidy/MopidyLibraryView.qml" "$ROOT/components/settings/sections/mopidy/SettingsMopidyTimeSection.qml" <<'PYCODE'
from pathlib import Path
import sys
qml = Path(sys.argv[1]).read_text()
browser = Path(sys.argv[2]).read_text()
library = Path(sys.argv[3]).read_text()
settings = Path(sys.argv[4]).read_text()
assert 'id: browseListView' in browser
assert 'height: Config.mopidyTrackRowHeight' in browser[browser.index('id: browseListView'):]
playlists_start = library.index('model: controller.playlists')
playlists_end = library.index('text: "Плейлистов нет"', playlists_start)
assert 'height: Config.mopidyTrackRowHeight' in library[playlists_start:playlists_end]
assert 'text: "Высота строки списка"' in settings
print('Mopidy shared row height: OK')
PYCODE

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/mopidy/Mopidy.qml"
BROWSER="$ROOT/components/mopidy/MopidyFileBrowser.qml"
LIBRARY="$ROOT/components/mopidy/MopidyLibraryView.qml"
python3 - "$FILE" "$BROWSER" "$LIBRARY" <<'PYCODE'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text(encoding='utf-8')
b = Path(sys.argv[2]).read_text(encoding='utf-8')
required_root = [
    'property bool fileFilterOpen: false',
    'property string fileFilterQuery: ""',
    'readonly property var filteredBrowseDisplayEntries:',
    'root.fileFilterOpen = true',
    'MopidyWidgets.MopidyLibraryView {',
    'controller: root',
]
required_library = [
    'MopidyWidgets.MopidyFileBrowser {',
    'controller: libraryRoot.controller',
    'Совпадений нет',
    'function focusBrowsePanel()',
    'function focusFileFilter()',
    'function clearFileFilterField()',
    'function focusSearchField()',
    'model: controller.searchResults',
]
required_browser = [
    'event.text === "/"',
    'controller.closeFileFilter(true)',
    'controller.closeFileFilter(false)',
    'property var controller',
    'controller.fileFilterOpen',
    'controller.fileFilterQuery',
    'model: controller.filteredBrowseDisplayEntries',
    'controller.closeFileFilter(true)',
    'controller.closeFileFilter(false)',
    'fileFilterField.forceActiveFocus()',
    'controller.addBrowseFolder(modelData.uri, modelData.name)',
    'controller.browseUriAt(modelData.uri, modelData.name)',
]
missing = [x for x in required_root if x not in s]
library = Path(sys.argv[3]).read_text(encoding='utf-8')
missing += [x for x in required_library if x not in library]
missing += [x for x in required_browser if x not in b]

# A normal left-click on an individual library track now enqueues it, matching
# the already-working plus button. Right-click keeps its previous add behavior.
if 'modelData.type === "track" && (mouse.button === Qt.LeftButton || mouse.button === Qt.RightButton)' not in b:
    missing.append('left/right click on track invokes addSearchResult')
if 'controller.addSearchResult(modelData.uri, modelData.name)' not in b:
    missing.append('track click is connected to addSearchResult')
if 'root.' in b:
    missing.append('no root references in extracted browser')
if 'root.' in library:
    missing.append('no root references in extracted library view')
if 'fileFilterField' in s:
    missing.append('no direct access to browser internals')
if missing:
    raise SystemExit('Mopidy file-filter/browser check failed; missing: ' + ', '.join(missing))
print('Mopidy file filter/browser component: OK')
PYCODE

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIBRARY="$ROOT/components/mopidy/MopidyLibraryView.qml"
CONTENTS="$ROOT/components/mopidy/MopidyPlaylistContents.qml"
DIALOG="$ROOT/components/mopidy/MopidyPlaylistDialog.qml"
TEXT_BUTTON="$ROOT/components/primitives/StyledTextButton.qml"
SURFACE="$ROOT/components/primitives/HoverButtonSurface.qml"
HOVER_ICON="$ROOT/components/mopidy/MopidyHoverIcon.qml"
for file in "$LIBRARY" "$CONTENTS" "$DIALOG" "$TEXT_BUTTON" "$SURFACE" "$HOVER_ICON"; do test -f "$file"; done

# Library mode tabs use the shared styled text action button.
test "$(grep -c 'Primitives.StyledTextButton {' "$LIBRARY")" -ge 3
grep -Fq 'text: "Папки"' "$LIBRARY"
grep -Fq 'text: "Плейлисты"' "$LIBRARY"
grep -Fq 'text: "Поиск"' "$LIBRARY"
grep -Fq 'onClicked: controller.showBrowse()' "$LIBRARY"
grep -Fq 'onClicked: controller.showPlaylists()' "$LIBRARY"
grep -Fq 'onClicked: controller.showSearch()' "$LIBRARY"

# Playlist create/add/rename/delete, search refresh, and dialog actions use shared primitives.
grep -Fq 'MopidyWidgets.MopidyHoverIcon {' "$LIBRARY"
grep -Fq 'controller.openCreatePlaylistDialog()' "$LIBRARY"
grep -Fq 'controller.searchLibrary()' "$LIBRARY"
grep -Fq 'controller.browseBack()' "$LIBRARY"
grep -Fq 'controller.backToPlaylists()' "$LIBRARY"
test "$(grep -c 'Primitives.HoverButtonSurface {' "$LIBRARY")" -ge 3
grep -Fq 'controller.switchPlaylist(modelData.uri, modelData.name)' "$LIBRARY"
grep -Fq 'controller.addPlaylist(modelData.uri, modelData.name)' "$LIBRARY"
grep -Fq 'controller.openDeletePlaylistFromListDialog(modelData.uri, modelData.name)' "$LIBRARY"

grep -Fq 'MopidyWidgets.MopidyHoverIcon {' "$CONTENTS"
grep -Fq 'controller.openPlaylistAddMode()' "$CONTENTS"
grep -Fq 'controller.openRenamePlaylistDialog()' "$CONTENTS"
grep -Fq 'controller.openDeletePlaylistDialog()' "$CONTENTS"
grep -Fq 'Primitives.HoverButtonSurface {' "$CONTENTS"
grep -Fq 'controller.removePlaylistItem(index, modelData.name)' "$CONTENTS"
test "$(grep -c 'Primitives.StyledTextButton {' "$DIALOG")" -eq 2
grep -Fq 'controller.closePlaylistDialog()' "$DIALOG"
grep -Fq 'controller.submitPlaylistDialog()' "$DIALOG"
grep -Fq 'enabled: !controller.playlistManageBusy' "$DIALOG"

# StyledTextButton supports the configurable Mopidy hover modes without changing defaults.
grep -Fq 'property string hoverMode: "none"' "$TEXT_BUTTON"
grep -Fq 'property color hoverColor: Config.accent' "$TEXT_BUTTON"
grep -Fq 'root.hovered && root.hoverMode === "background"' "$TEXT_BUTTON"
grep -Fq 'root.hovered && root.hoverMode === "frame"' "$TEXT_BUTTON"
grep -Fq 'root.hovered && root.hoverMode === "text"' "$TEXT_BUTTON"

# Old duplicated mouse areas for the converted actions must not creep back in.
if grep -Eq 'browseTabMouse|playlistsTabMouse|searchTabMouse|backLibraryMouse|playlistCreateMouse|playlistAddTracksMouse|playlistRenameMouse|playlistDeleteMouse|playlistCancelMouse|playlistConfirmMouse|playlistListDeleteMouse|playlistSwitchMouse|playlistAddMouse|playlistContentDeleteMouse' "$LIBRARY" "$CONTENTS" "$DIALOG"; then
    echo 'A migrated Mopidy action still uses its old local MouseArea id' >&2
    exit 1
fi

python3 - "$LIBRARY" "$CONTENTS" "$DIALOG" "$TEXT_BUTTON" <<'PYCODE'
from pathlib import Path
import sys
pairs={')':'(',']':'[','}':'{'}
for name in sys.argv[1:]:
    source=Path(name).read_text(encoding='utf-8')
    stack=[]; quote=None; escaped=False; line_comment=False; block_comment=False; i=0
    while i<len(source):
        c=source[i]; n=source[i+1] if i+1<len(source) else ''
        if line_comment:
            if c=='\n': line_comment=False
            i+=1; continue
        if block_comment:
            if c=='*' and n=='/': block_comment=False; i+=2; continue
            i+=1; continue
        if quote:
            if escaped: escaped=False
            elif c=='\\': escaped=True
            elif c==quote: quote=None
            i+=1; continue
        if c=='/' and n=='/': line_comment=True; i+=2; continue
        if c=='/' and n=='*': block_comment=True; i+=2; continue
        if c in ('"', "'", '`'): quote=c; i+=1; continue
        if c in '([{': stack.append((c,i))
        elif c in ')]}':
            if not stack or stack[-1][0]!=pairs[c]: raise SystemExit(f'{name}: unbalanced {c} at offset {i}')
            stack.pop()
        i+=1
    if stack: raise SystemExit(f'{name}: unclosed {stack[-1][0]} at offset {stack[-1][1]}')
print('Mopidy shared action button delimiters: OK')
PYCODE

echo 'Mopidy shared action buttons: OK'

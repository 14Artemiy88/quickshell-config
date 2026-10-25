#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys
root=Path(sys.argv[1])
qml=(root/'components/settings/sections/SettingsGeneralSection.qml').read_text(encoding='utf-8')
script=(root/'scripts/copy_text').read_text(encoding='utf-8')
checks={
    'storage paths has a separate General subtab': 'case 0: return ["Интерфейс", "Профили", "Хранилища"]' in (root/'components/settings/SettingsWidget.qml').read_text(encoding='utf-8'),
    'storage paths are not shown in General interface subtab': 'visible: host && host.currentOtherTab === 0 && host.currentOtherSubTab === 2' in qml,
    'paths are grouped into framed sections': all(title in qml for title in ('Настройки и профили', 'Календарь', 'Данные модулей и кэши', 'Временные данные')),
    'path groups filter entries by stable ids': 'root.storagePathEntries.filter(function(entry)' in qml and 'groupEntryIds.indexOf(entry.id)' in qml,
    'paths loaded from canonical resolver script': 'scripts/storage_paths' in qml,
    'path entries keep read-only selectable TextArea': 'text: modelData.path\n                        readOnly: true\n                        selectByMouse: true' in qml,
    'path selection uses supported TextArea properties': 'wrapMode: TextArea.WrapAnywhere' in qml and 'background: null' in qml,
    'copy button uses exact path': 'root.copyStoragePath(modelData.path)' in qml,
    'copy script invoked without shell interpolation': 'Quickshell.execDetached([Quickshell.shellDir + "/scripts/copy_text", String(path || "")])' in qml,
    'only the three meaningful JSON files can be edited': 'editable:true' in (root/'scripts/storage_paths').read_text(encoding='utf-8') and all(item in (root/'scripts/storage_paths').read_text(encoding='utf-8') for item in ('settings.json', 'profiles.json', 'calendar-notes.json', 'calendar-marks.json')),
    'path edit form delegates to safe migration command': '"set"' in qml and 'requestStoragePathMove(modelData.id, storagePathTargetField.text)' in qml,
    'path editor clears a successful draft and retains a failed draft': 'root.clearStoragePathDraft(completedId)' in qml and 'text: root.storagePathDrafts[modelData.id] || ""' in qml,
    'path editor explains backup and restart behavior': 'старый вариант сохраняется как резервная копия' in qml and 'рекомендуется перезапустить Quickshell' in qml,
    'path changes expose operation status': 'storagePathApplyMessage' in qml and 'storagePathApplyError' in qml,
    'profile file is described as independently editable': 'редактировать вручную' in (root/'scripts/storage_paths').read_text(encoding='utf-8'),
    'clipboard fallback supports common Linux utilities': all(item in script for item in ('wl-copy','xclip','xsel')),
}
group_matches = re.findall(r'title: "([^"]+)", entryIds: \[([^\]]*)\]', qml)
ids = [item for _, values in group_matches for item in re.findall(r'"([A-Za-z0-9]+)"', values)]
expected_ids = {
    "settings", "profiles", "settingsBackup", "calendarNotes", "calendarMarks",
    "configDir", "dataDir", "stateDir", "cacheDir", "weatherCache", "mopidyCovers",
    "launcherHistory", "timerRuntimeDir"
}
checks.update({
    'every resolved path belongs to exactly one frame': set(ids) == expected_ids and len(ids) == len(expected_ids),
    'all storage groups are framed with explicit headings': 'showFrame: true' in qml and 'heading: modelData.title' in qml,
    'legacy single storage frame removed': 'heading: "Пути хранения данных"' not in qml,
})
failed=[name for name,ok in checks.items() if not ok]
if failed:
    raise SystemExit('storage path UI checks failed: '+', '.join(failed))
print('settings general storage paths UI: OK')
PY
# Clipboard payload is passed as an argument, not interpolated into a command string.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/wl-copy" <<'CLIP'
#!/usr/bin/env bash
cat > "$CLIPBOARD_CAPTURE"
CLIP
chmod +x "$TMP/bin/wl-copy"
export PATH="$TMP/bin:$PATH" CLIPBOARD_CAPTURE="$TMP/captured"
value="$TMP/a path with spaces/and ; symbols"
"$ROOT/scripts/copy_text" "$value"
[[ "$(cat "$CLIPBOARD_CAPTURE")" == "$value" ]]
printf 'storage path clipboard helper: OK\n'

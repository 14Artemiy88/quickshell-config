#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
launcher = (root / "components/launcher/Launcher.qml").read_text()
assert 'rawQuery.startsWith(">")' in launcher, "action prefix must be detected only in Apps search"
assert 'rawQuery.slice(1).trim()' in launcher, "the prefix must be removed before matching"
assert 'function buildLauncherActionResults(query, fuzzyActionsEnabled, fuzzySchemesEnabled, fuzzyWallpapersEnabled)' in launcher
assert 'function launcherActionAliases(mode)' in launcher
for alias in ('"apps"', '"run"', '"windows"', '"clipboard"', '"power"', '"network"', '"packages"', '"pass"', '"projects"', '"calculator"'):
    assert alias in launcher, f"missing built-in launcher action alias: {alias}"
assert 'kind: "action"' in launcher and 'targetMode: tab.mode' in launcher
assert 'if (result.kind === "action")' in launcher
activation = launcher[launcher.index('function activateAppsSearchResult'):launcher.index('property string calculatorCopyPending')]
assert 'searchField.text = ""' in activation and 'root.setMode(result.targetMode)' in activation
assert 'root.runCommand(result.command)' in activation, "ordinary cross-search saved-command activation must remain intact"
assert 'Search apps, @ filters or > actions...' in launcher
assert 'model: root.appsUnifiedResults' in launcher
print('Launcher > action prefix and existing Apps cross-search compatibility: OK')
PY

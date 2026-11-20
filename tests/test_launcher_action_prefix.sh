#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
launcher = (root / "components/launcher/Launcher.qml").read_text()
assert 'rawQuery.startsWith(">")' in launcher, "action prefix must be detected only in Apps search"
assert 'rawQuery.slice(1).trim()' in launcher, "the > prefix must be removed before matching"
assert 'const customActionQuery = LauncherCustomActions.parseQuery(rawQuery)' in launcher, 'the dedicated : prefix must be parsed separately'
assert 'customActionQuery.query, 0, true, fuzzyActionsEnabled' in launcher, 'the : prefix must return only saved custom-action results'
action_palette = launcher[launcher.index('function buildLauncherActionResults'):launcher.index('function russianApplicationCount')]
assert 'buildCustomActionResults' not in action_palette, 'the > palette must no longer include saved custom actions'
assert 'launcherQuery.startsWith(">") || launcherQuery.startsWith(":")' in launcher, 'both Launcher-only prefixes must work from every tab'
assert 'return "Search apps, @ filters, > commands or : saved actions..."' in launcher, 'the search hint must explain the custom-action prefix'
assert 'function buildLauncherActionResults(query, fuzzyActionsEnabled, fuzzySchemesEnabled, fuzzyWallpapersEnabled)' in launcher
assert 'function launcherActionAliases(mode)' in launcher
for alias in ('"apps"', '"run"', '"windows"', '"clipboard"', '"power"', '"network"', '"packages"', '"pass"', '"projects"', '"calculator"'):
    assert alias in launcher, f"missing built-in launcher action alias: {alias}"
assert 'kind: "action"' in launcher and 'targetMode: tab.mode' in launcher
assert 'if (result.kind === "action")' in launcher
activation = launcher[launcher.index('function activateAppsSearchResult'):launcher.index('property string calculatorCopyPending')]
assert 'searchField.text = ""' in activation and 'root.setMode(result.targetMode)' in activation
assert 'root.runCommand(result.command)' in activation, "ordinary cross-search saved-command activation must remain intact"
assert 'root.buildCustomActionResults' in launcher and 'root.runCommand(result.command)' in activation, 'custom actions must run only the stored command'
assert 'model: root.appsUnifiedResults' in launcher
print('Launcher > action prefix and existing Apps cross-search compatibility: OK')
PY

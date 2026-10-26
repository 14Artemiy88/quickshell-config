#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1])
launcher=(root/'components/launcher/Launcher.qml').read_text()
config=(root/'Config.qml').read_text()
defaults=(root/'js/settings/SettingsDefaults.js').read_text()
persist=(root/'js/settings/SettingsPersistence.js').read_text()
apply=(root/'js/settings/SettingsApplySystemVisual.js').read_text()
resets=(root/'js/settings/SettingsResets.js').read_text()
settings=(root/'components/settings/sections/SettingsLauncherSection.qml').read_text()
assert 'root.mode === root.modePass' in launcher and 'root.copySelectedPass()' in launcher
assert 'searchField.clear()' not in launcher[launcher.index('function setMode(newMode)'):launcher.index('function activeListForMode')]
assert 'model: root.appsUnifiedResults' in launcher
builder=launcher[launcher.index('function buildAppsUnifiedResults'):launcher.index('AppModel {', launcher.index('function buildAppsUnifiedResults'))]
assert 'kind: "app"' in builder and 'kind: "project"' in builder and 'kind: "run"' in builder
assert 'application.entry' in builder and 'entry: appEntry' in builder, 'unwrap AppModel result wrappers before launching applications'
assert builder.index('kind: "app"') < builder.index('kind: "project"')
assert 'Config.launcherCrossSearchProjects' in builder and 'Config.launcherCrossSearchRunHistory' in builder
assert 'Config.launcherCrossSearchCalculator' in builder and 'Calculator.evaluate(query)' in builder
assert 'kind: \"calculator\"' in launcher and 'function copyCalculatorResult(value)' in launcher
assert 'function activateAppsSearchResult' in launcher and 'root.launchProject(result.project)' in launcher and 'root.runCommand(result.command)' in launcher
assert 'String(appDelegate.itemData.project && appDelegate.itemData.project.icon || "")' in launcher, 'cross-search project results should use configured project icons'
assert 'id: runCommandFallback' in launcher and 'text: ">_"' in launcher, 'cross-search saved commands should show a font-independent terminal icon'
assert 'id: projectFolderFallback' in launcher and 'project.icon || \"\"' in launcher, 'projects using the default glyph should show a font-independent folder icon'
assert 'visible: appDelegate.itemData' in launcher and 'String(source).length > 0' in launcher, 'empty QML url must not suppress project/command fallback icons'
assert 'Quickshell.iconPath(String(appDelegate.entry.icon), true)' in launcher, 'missing app theme icons must be resolved with iconPath existence checking'
for name in ('launcherCrossSearchProjects','launcherCrossSearchRunHistory','launcherCrossSearchCalculator'):
    assert name in config and name in defaults and name in persist and name in apply and name in resets and name in settings, f'{name} must be persisted, profile-resettable and configurable'
print('Launcher shared query, Pass Enter and Apps cross-search wiring: OK')
PY

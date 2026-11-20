#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
launcher = (root / "components/launcher/Launcher.qml").read_text()

aliases_match = re.search(
    r"function launcherActionAliases\(mode\)\s*\{(?P<body>.*?)\n    \}\n\n    function launcherActionDescription",
    launcher,
    re.S,
)
assert aliases_match, "launcher action aliases function must remain explicit"
aliases = aliases_match.group("body")
for mode, terms in {
    "modeApps": ("приложения", "поиск приложений"),
    "modeRun": ("shell", "командная строка", "выполнить"),
    "modeWindows": ("switch", "открытые окна"),
    "modeClipboard": ("history", "история буфера"),
    "modePower": ("shutdown", "reboot", "перезагрузка"),
    "modeNetwork": ("wifi", "wireless", "подключения"),
    "modeNix": ("nixpkgs", "поиск пакетов"),
    "modePass": ("password-store", "менеджер паролей"),
    "modeProjects": ("workspace", "репозитории"),
    "modeCalculator": ("calculate", "вычислить"),
}.items():
    assert f"case root.{mode}:" in aliases, f"missing aliases for {mode}"
    for term in terms:
        assert f'"{term}"' in aliases, f"missing alias {term!r} for {mode}"

descriptions_match = re.search(
    r"function launcherActionDescription\(mode\)\s*\{(?P<body>.*?)\n    \}\n",
    launcher,
    re.S,
)
assert descriptions_match, "launcher action descriptions function must exist"
descriptions = descriptions_match.group("body")
for mode in (
    "modeApps", "modeRun", "modeWindows", "modeClipboard", "modePower",
    "modeNetwork", "modeNix", "modePass", "modeProjects", "modeCalculator",
):
    assert f"case root.{mode}: return" in descriptions, f"missing description for {mode}"
assert 'description: root.launcherActionDescription(tab.mode)' in launcher, \
    "built-in action result must display the mode-specific description"
assert 'description: "Открыть раздел лаунчера"' not in launcher, \
    "generic descriptions must not replace the built-in action metadata"

# Saved custom actions, now selected through `:`, still dispatch only stored command records.
activation = launcher[launcher.index('function activateAppsSearchResult'):launcher.index('property string calculatorCopyPending')]
assert 'if (result.kind === "customAction")' in activation
assert 'root.runCommand(result.command)' in activation
assert 'root.runCommand(searchField.text)' not in activation
print("Launcher built-in action aliases, descriptions and safe saved-action dispatch: OK")
PY

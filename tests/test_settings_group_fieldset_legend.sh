#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
file="$root/components/settings/primitives/SettingsGroup.qml"
python3 - "$file" <<'PY'
import sys
from pathlib import Path
s = Path(sys.argv[1]).read_text()
checks = {
    "first direct Text is used only as reactive title source": "var candidate = items[0]" in s and "candidate.text === undefined" in s,
    "source is removed from layout and hidden without deleting its bindings": "candidate.parent = root" in s and "candidate.opacity = 0" in s and "candidate.width = 0" in s and "candidate.height = 0" in s,
    "visible legend is rendered by a separate Text item": "id: headingLabel" in s and "text: root.renderedHeading" in s,
    "explicit headings bypass fragile child-order inference": 'if (root.heading.trim().length > 0)' in s,
    "legend color follows configurable mini-heading color": "color: Config.settingsSubheading" in s,
    "empty and hidden headings do not reserve legend space": (
        "readonly property bool hasHeading" in s
        and 'root.renderedHeading.trim().length > 0' in s
        and 'root.headingSource.visible' in s
        and "visible: root.hasHeading" in s
        and "(root.hasHeading ? 8 : 0)" in s
    ),
    "legend width is measured separately and constrained by group width": (
        "TextMetrics {" in s
        and "headingMetrics.advanceWidth,\n                                    root.width - root.padding * 2 - 16" in s
        and "root.width - root.padding * 2 - 16" in s
        and "root.parent ? root.parent.width" not in s
    ),
    "legend overlays frame border": "y: -Math.ceil(Config.settingsUiSize(11) / 2)" in s and "headingBackground" in s,
    "legend backdrop follows visible label geometry": "x: headingLabel.x - 4" in s and "width: headingLabel.width + 8" in s,
    "legend uses frame background": "color: root.backgroundColor" in s,
    "content is offset only below a visible non-empty legend": "root.padding + (root.hasHeading ? 8 : 0)" in s,
    "existing no-frame groups remain unaffected": "if (!root.showFrame || root.headingSource || root.adoptingHeading)" in s,
}
for label, ok in checks.items():
    print(f"{'OK' if ok else 'FAIL'}: {label}")
if not all(checks.values()):
    raise SystemExit(1)
PY

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/components/settings/sections/SettingsWeatherSection.qml"
python3 - "$FILE" <<'PY'
import sys
from pathlib import Path

source = Path(sys.argv[1]).read_text()
headings = [
    "Токен Gismeteo",
    "Иконка текущей погоды",
    "Стрелка ветра",
    "Дополнительные параметры",
    "Положение элементов",
    "Размер стрелки ветра",
    "Давление",
    "Почасовой блок",
    "Дневной прогноз",
]
for heading in headings:
    explicit = f'heading: "{heading}"'
    legacy = f'text: "{heading}"'
    if source.count(explicit) != 1:
        raise SystemExit(f"Expected exactly one explicit frame heading: {heading}")
    if legacy in source:
        raise SystemExit(f"Legacy in-frame title still present: {heading}")
print(f"Weather explicit frame headings: OK ({len(headings)} headings)")
PY

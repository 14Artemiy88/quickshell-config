#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1])
source = (root / "components/settings/sections/SettingsWeatherSection.qml").read_text()

def group_for_heading(heading):
    marker = f'heading: "{heading}"'
    pos = source.find(marker)
    assert pos >= 0, f"missing frame heading: {heading}"
    start = source.rfind("SettingsGroup {", 0, pos)
    assert start >= 0, f"no SettingsGroup for heading: {heading}"
    opening = source.find("{", start)
    depth = 0
    in_string = False
    escaped = False
    quote = ""
    for index in range(opening, len(source)):
        ch = source[index]
        if in_string:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == quote:
                in_string = False
            continue
        if ch in ('"', "'"):
            in_string = True
            quote = ch
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                block = source[start:index + 1]
                assert marker in block, f"heading escaped its group: {heading}"
                return block
    raise AssertionError(f"unclosed SettingsGroup for {heading}")

token = group_for_heading("Токен Gismeteo")
refresh = group_for_heading("Время обновлений")
assert "id: token" in token and "Введите токен Gismeteo" in token
for field in ("weatherNowIntervalField", "weatherHourlyIntervalField", "weatherDailyIntervalField", "weatherRetryDelayField", "weatherManualCooldownField"):
    assert field in refresh, f"refresh frame missing {field}"
    assert field not in token, f"refresh field still in token frame: {field}"
assert "id: token" not in refresh, "token field leaked into refresh frame"
assert source.count('heading: "Время обновлений"') == 1
print("Weather General token/update interval frame split: OK")
PY

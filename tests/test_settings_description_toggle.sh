#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
PERSISTENCE="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplyCore.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
SETTINGS="$ROOT/Settings.qml"
SECTION="$ROOT/components/settings/sections/SettingsWindowSection.qml"
PRIMITIVE="$ROOT/components/settings/primitives/SettingsDescription.qml"

for file in "$CONFIG" "$DEFAULTS" "$PERSISTENCE" "$APPLY" "$RESETS" "$SETTINGS" "$SECTION" "$PRIMITIVE"; do
    test -f "$file"
done

grep -Fq 'property bool settingsShowDescriptions: true' "$CONFIG"
grep -Fq 'settingsShowDescriptions: true' "$DEFAULTS"
grep -Fq 'settingsShowDescriptions: config.settingsShowDescriptions !== false' "$PERSISTENCE"
grep -Fq 'if (o.settingsShowDescriptions !== undefined) Config.settingsShowDescriptions = o.settingsShowDescriptions !== false' "$APPLY"
grep -Fq '"settingsShowDescriptions"' "$RESETS"
grep -Fq 'settingsWindow: [' "$SETTINGS"
grep -Fq '"settingsShowDescriptions"' "$SETTINGS"
grep -Fq 'checked: Config.settingsShowDescriptions' "$SECTION"
grep -Fq 'Config.settingsShowDescriptions = checked' "$SECTION"
grep -Fq 'settingsWindowColumn.settings.save()' "$SECTION"
grep -Fq 'visible: Config.settingsShowDescriptions && root.descriptionConditionVisible' "$PRIMITIVE"
grep -Fq 'text: "Показывать поясняющие описания"' "$SECTION"

python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys
root = Path(sys.argv[1])
sections = list((root / 'components/settings/sections').rglob('*.qml'))
count = sum(p.read_text(encoding='utf-8', errors='ignore').count('SettingsDescription {') for p in sections)
assert count >= 50, f'Expected explanatory descriptions to use shared primitive, found {count}'
# Important diagnostic/status controls must remain ordinary Text, not the
# optional-description primitive hidden by the preference.
# Dynamic explanatory paragraphs also use the shared primitive, so their
# condition-dependent copy is hidden by the same preference.
for relative in (
    'components/settings/sections/SettingsDashboardSection.qml',
    'components/settings/sections/SettingsNotificationsSection.qml',
    'components/settings/sections/mopidy/SettingsMopidySection.qml',
    'components/settings/sections/mopidy/SettingsMopidyTimeSection.qml',
):
    dynamic_source = (root / relative).read_text(encoding='utf-8')
    assert 'SettingsDescription {' in dynamic_source, f'dynamic helper descriptions must use the shared primitive: {relative}'

general = (root / 'components/settings/sections/SettingsGeneralSection.qml').read_text(encoding='utf-8')
interface = (root / 'components/settings/sections/SettingsInterfaceSection.qml').read_text(encoding='utf-8')
assert 'text: root.storagePathsError' in general
assert 'text: root.storagePathApplyMessage' in general

# Descriptive copy about module scaling and corner-radius scaling must use the
# shared primitive; these were raw Text blocks and ignored the global toggle.
def object_blocks(source, type_name):
    blocks = []
    for match in re.finditer(r'\b' + re.escape(type_name) + r'\s*\{', source):
        opening = source.find('{', match.start())
        depth = 0
        quote = None
        escaped = False
        for index in range(opening, len(source)):
            char = source[index]
            if quote:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == quote:
                    quote = None
                continue
            if char in ('"', "'"):
                quote = char
            elif char == '{':
                depth += 1
            elif char == '}':
                depth -= 1
                if depth == 0:
                    blocks.append(source[match.start():index + 1])
                    break
    return blocks

scale_descriptions = (
    'Меняет размеры окон модулей и текст, не изменяя сохранённые координаты и индивидуальные размеры шрифтов.',
    '100% сохраняет текущие пропорции скруглений. Изменение масштаба применяется к существующим радиусам, не выравнивая мелкие элементы и внешние рамки в один размер.',
)
description_blocks = object_blocks(interface, 'SettingsDescription')
raw_text_blocks = object_blocks(interface, 'Text')
for description in scale_descriptions:
    assert any(description in block for block in description_blocks), f'optional description is not gated: {description[:48]}'
    assert not any(description in block for block in raw_text_blocks), f'description still bypasses the toggle: {description[:48]}'
print(f'{count} shared optional descriptions; diagnostic messages remain independent: OK')
PY

echo 'Settings explanatory-description toggle: OK'

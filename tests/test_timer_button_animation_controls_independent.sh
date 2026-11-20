#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
section = (root / 'components/settings/sections/SettingsTimersSection.qml').read_text(encoding='utf-8')
timer = (root / 'components/TimerWidget.qml').read_text(encoding='utf-8')
options = (root / 'components/TimerOptions.qml').read_text(encoding='utf-8')

# Button timing fields stay available regardless of the internal-transition profile.
assert 'Config.animationTimerMorphProfile !== "none"' not in section
for key in ('timerButtonFadeDuration', 'timerButtonSlideDuration', 'timerButtonIconFadeDuration'):
    assert f'targetProperty: "{key}"' in section, f'{key} editor missing'
assert 'heading: "Анимация кнопок таймера"' in section
assert 'label: "Стиль появления кнопок"' in section
assert 'label: "Затухание кнопок (мс)"' in section
assert 'label: "Сдвиг кнопок (мс)"' in section
assert 'label: "Появление/исчезновение иконок (мс)"' in section

# The common profile gates icon/row/button motion, but the preset style only gates preset buttons.
for morph_id in ('timerIconMorph', 'alarmIconMorph'):
    block = timer.split(f'id: {morph_id}', 1)[1].split('\n        }', 1)[0]
    assert 'Config.animationProfileIsEnabled(Config.animationTimerMorphEnabled, Config.animationTimerMorphProfile)' in block
    assert 'Config.timerButtonIconFadeDuration' in block
    assert 'Config.animationTimerVisibilityStyle' not in block, f'{morph_id} incorrectly depends on preset-button style'
assert timer.count('animationStyle: Config.animationProfileIsEnabled(Config.animationTimerMorphEnabled, Config.animationTimerMorphProfile) ? Config.animationTimerVisibilityStyle : "none"') == 2
assert timer.count('Config.animationTimerVisibilityStyle === "none" ? 0 : Config.animationDurationForProfile(') == 2
assert 'Config.timerButtonFadeDuration : Config.timerButtonSlideDuration' in timer

# The popup continues to use its independent animation settings.
assert 'Config.animationTimerOptionsVisibilityStyle' in options
assert 'Config.animationTimerOptionsDuration' in options
assert 'Config.animationTimerVisibilityStyle' not in options
print('Timer animation controls stay independent: row profile, preset style/durations, icon duration and options popup: OK')
PY

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])

def read(path):
    return (root / path).read_text(encoding='utf-8')

primitive = read('components/settings/primitives/SettingsAnimationGroup.qml')
assert 'default property alias extraContent: extraContentColumn.data' in primitive
assert 'property var settings: Settings' in primitive
assert 'property var changeKeys: null' in primitive
assert 'import "../../primitives"' in primitive
assert 'height: implicitHeight' in primitive
assert 'property bool animationsEnabled' not in primitive
assert 'property real duration: 180' in primitive
assert 'property string profile: "ease-in-out"' in primitive
assert primitive.count('SettingsCheckBox {') == 0
assert primitive.count('SettingsRow {') == 3, 'profile, custom curve and duration controls must use the shared row primitive'
assert primitive.count('SettingsNumberField {') == 2, 'duration and cubic-bezier fields must use the common number-field primitive'
assert 'model: ["X1", "Y1", "X2", "Y2"]' in primitive
assert primitive.count('SettingsComboBox {') == 1
assert 'label: root.profileLabel' in primitive
assert 'label: root.durationLabel' in primitive
assert 'controlSpacing: 8' in primitive
assert 'signal animationEnabledEdited(bool value)' not in primitive
assert 'signal durationEdited(real value)' in primitive
assert 'signal profileEdited(string value)' in primitive
assert 'root.durationEdited(value)' in primitive
assert 'root.profileEdited(selected)' in primitive and 'root.updateBezierComponent(index, value)' in primitive
assert 'root.profileEdited(selected)' in primitive and 'root.updateBezierComponent(index, value)' in primitive
assert 'function onAnimationsEnabledChanged()' not in primitive
assert 'function onProfileChanged()' in primitive
assert 'visible: root.profile !== "none" || normalizedProgress > 0.001' in primitive
assert 'fromGeometry: Qt.rect(0, 0, parent.width, 0)' in primitive
assert 'property real detailsTopInset: Math.ceil(Config.settingsUiSize(11) / 2) + 3' in primitive
assert 'toGeometry: Qt.rect(0, 0, parent.width, root.detailsTopInset + detailsGroup.implicitHeight)' in primitive
assert 'y: root.detailsTopInset' in primitive
assert 'progress: root.profile !== "none" ? 1 : 0' in primitive
assert 'animationDuration: root.profile === "none" ? 0 : Config.animationDuration(180, "appearance")' in primitive
assert 'animationEasing: Config.animationEasingType("ease-out", root.profile !== "none" ? "enter" : "exit")' in primitive
assert primitive.index('SettingsGroup {') < primitive.index('MorphGeometry {'), 'profile group must precede the animated details group'
assert primitive.index('SettingsComboBox {') < primitive.index('MorphGeometry {'), 'profile selector must stay visible above animated details'
assert 'heading: root.detailsHeading' in primitive
assert 'Длительность перехода задаётся отдельно' in primitive
assert 'Анимация внутренних переходов отключена' in primitive
assert 'SettingsGroup {' in primitive[primitive.index('MorphGeometry {'):], 'duration and module-specific controls must be inside the animated details group'
assert 'settings: root.settings' in primitive and 'changeKeys: root.changeKeys' in primitive

sections = {
    'player': read('components/settings/sections/SettingsPlayerAnimationSection.qml'),
    'weather': read('components/settings/sections/SettingsWeatherAnimationSection.qml'),
    'mopidy': read('components/settings/sections/mopidy/SettingsMopidyAnimationSection.qml'),
    'timer': read('components/settings/sections/SettingsTimersSection.qml'),
}
for name, source in sections.items():
    assert 'SettingsAnimationGroup {' in source, f'{name} does not use the shared primitive'
    assert 'onAnimationEnabledEdited:' not in source, f'{name} still exposes the removed master toggle'
    assert 'onDurationEdited:' in source, f'{name} does not write duration through the primitive'
    assert 'onProfileEdited:' in source, f'{name} does not write profile through the primitive'

# Module-specific extras are projected into the common group instead of cloning its controls.
assert 'text: "Почасовой прогноз (мс)"' in sections['weather']
assert 'visible: Config.animationWeatherMorphProfile !== \"none\"' not in sections['weather'], 'hourly duration must collapse with the shared details group'
assert 'height: visible ? 30 : 0' not in sections['weather']
assert 'text: Config.animationTimerMorphProfile === "none"' not in sections['timer']
assert 'Профиль управляет появлением и удалением строк' in sections['timer']
# The shared animation control does not take over module visibility settings.
assert 'heading: "Появление модуля"' in sections['mopidy']
assert 'heading: "Что управляется"' in sections['player']
assert 'Config.settingsShowDescriptions' in sections['player']
assert 'heading: "Что управляется"' in sections['weather']
assert 'Config.settingsShowDescriptions' in sections['weather']
# The Timer module entrance/exit style and options popup remain in their own groups.
assert 'heading: "Внутренние переходы таймера"' in sections['timer']
assert 'heading: "Иконки окна опций"' in sections['timer']
assert 'animationTimerOptionsVisibilityStyle' in sections['timer']
print('SettingsAnimationGroup primitive: shared controls, live bindings, custom content slots, module scopes and independent visibility settings: OK')
PY

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
primitive = root / "components/settings/primitives/SettingsRow.qml"
label = root / "components/settings/primitives/SettingsLabel.qml"
assert primitive.is_file(), "shared SettingsRow primitive is missing"
assert label.is_file(), "shared SettingsLabel primitive is missing"
source = primitive.read_text()
assert re.search(r"(?m)^Row\s*\{", source), "SettingsRow must remain Row-based"
assert 'default property alias controlData: controlLayout.data' in source, "control slot must remain the default content property"
assert 'SettingsLabel {' in source, "SettingsRow must use the shared SettingsLabel primitive"
assert 'text: root.label' in source, "row label is not forwarded"
assert 'readonly property string settingsSearchRowLabel: root.label' in source, "nested settings controls cannot recover their visible row label"
controller = (root / "components/settings/SettingsSearchController.qml").read_text()
assert 'function settingsSearchAncestorRowLabel(item)' in controller, "search controller does not resolve SettingsRow labels"
assert 'root.settingsSearchAncestorRowLabel(item)' in controller, "search result labels do not use the containing SettingsRow"
assert 'width: root.labelWidth' in source, "label width is not configurable"
assert 'root.width - root.labelWidth - root.spacing' in source, "control slot does not consume remaining row width"

sections = [
    "SettingsNetworkSection.qml",
    "SettingsVolumeSection.qml",
    "SettingsCpuRamSection.qml",
    "SettingsCavaSection.qml",
    "SettingsNotificationsSection.qml",
    "SettingsTimersSection.qml",
    "SettingsWeatherSection.qml",
    "SettingsPlayerSection.qml",
    "SettingsCalendarSection.qml",
    "SettingsLauncherSection.qml",
    "SettingsGeneralSection.qml",
    "SettingsWindowSection.qml",
]
sections += [
    "mopidy/SettingsMopidySection.qml",
    "mopidy/SettingsMopidyStatusSection.qml",
    "mopidy/SettingsMopidyTimeSection.qml",
    "mopidy/SettingsMopidyAnimationSection.qml",
    "mopidy/SettingsMopidyIconsSection.qml",
]
row_total = 0
for filename in sections:
    path = root / "components/settings/sections" / filename
    text = path.read_text()
    assert re.search(r'import \"(?:\.\./|\.\./\.\./)primitives\"', text), f"{filename} does not import settings primitives"
    rows = len(re.findall(r"\bSettingsRow\s*\{", text))
    old_labels = len(re.findall(r"\bSettingsLabel\s*\{", text))
    assert rows > 0, f"{filename} has no shared SettingsRow instances"
    assert old_labels == 0, f"{filename} still contains inline SettingsLabel nodes"
    row_total += rows

assert row_total == 232, f"expected 232 shared settings rows after the Networks visibility-animation controls, got {row_total}"
network = (root / "components/settings/sections/SettingsNetworkSection.qml").read_text()
assert len(re.findall(r"\bSettingsRow\s*\{", network)) == 9, "expected nine shared Network rows, including the two conditional module-animation controls"
general = (root / "components/settings/sections/SettingsGeneralSection.qml").read_text()
for label_text in [
    "Основной шрифт интерфейса", "Размер шрифта интерфейса", "LED-шрифт",
    "Радиус области блюра (0–40)", "Толщина рамки (0 = выкл.)", "Радиус скругления рамки",
]:
    assert f'label: "{label_text}"' in general, f"General SettingsRow label is missing: {label_text}"
for control_id in ["generalFontSizeField", "backgroundBlurRadiusField", "frameBorderWidthField", "frameRadiusField"]:
    assert control_id in general, f"General SettingsRow lost control {control_id}"
assert len(re.findall(r"\bSettingsRow\s*\{", general)) == 6, "expected six migrated General rows"
window = (root / "components/settings/sections/SettingsWindowSection.qml").read_text()
for label_text in [
    "Шрифт настроек", "Размер шрифта настроек", "Внутренний отступ",
    "Расстояние между элементами", "Цвет рамки совпадений поиска",
    "Толщина рамки совпадений", "Размер шрифта счётчиков", "Стиль",
]:
    assert f'label: "{label_text}"' in window, f"Settings Window SettingsRow label is missing: {label_text}"
for control_id in [
    "settingsFontSizeField", "settingsPaddingField", "settingsSpacingField",
    "settingsWindowAnimationVisibilityBox",
]:
    assert control_id in window, f"Settings Window SettingsRow lost control {control_id}"
assert len(re.findall(r"\bSettingsRow\s*\{", window)) == 8, "expected eight migrated Settings Window rows"
calendar = (root / "components/settings/sections/SettingsCalendarSection.qml").read_text()
for label_text in [
    "Предыдущий месяц", "Следующий месяц", "Месяц", "Дни недели", "Дни",
    "Вид метки", "Положение метки", "Стиль", "Раскрытие (мс)", "Исчезновение (мс)",
]:
    assert f'label: "{label_text}"' in calendar, f"Calendar SettingsRow label is missing: {label_text}"
for control_id in [
    "calendarPrevIconField", "calendarArrowSizeField", "calendarPrevXField", "calendarArrowYField",
    "calendarNextIconField", "calendarNextSizeField", "calendarNextXField",
    "calendarTitleY2Field", "calendarTitleSizeField2", "calendarWeekdayYField",
    "calendarWeekdaySizeField", "calendarDayYField", "calendarDaySizeField",
    "calendarNoteMarkerStyleBox", "calendarNoteMarkerPositionBox",
    "animationCalendarVisibilityBox", "calendarAnimationSlideField", "calendarAnimationFadeField",
]:
    assert control_id in calendar, f"Calendar SettingsRow lost control {control_id}"
assert len(re.findall(r"\bSettingsRow\s*\{", calendar)) == 10, "expected 10 migrated Calendar rows"
weather = (root / "components/settings/sections/SettingsWeatherSection.qml").read_text()
for label_text in [
    "Погода сейчас (мин)", "Погода по часам (мин)", "Погода по дням (мин)",
    "Повтор после ошибки (мин)", "Пауза между ручными обновлениями (с)",
    "Левый · температура", "Средний · иконка", "Правый · ветер",
    "Расположение", "Иконка", "Описание", "Ширина / размер текста",
    "Показывать", "Толщина обводки", "Положение Y", "Смещение X",
    "Температура", "Колонка ветра", "Скорость ветра", "Единица ветра",
    "Давление", "Единица давления", "Значение давления",
    "Количество часов", "Верхний отступ", "Время", "Количество дней",
    "День", "Дневная температура", "Ночная температура",
]:
    assert f'label: "{label_text}"' in weather, f"Weather SettingsRow label is missing: {label_text}"
for control_id in [
    "weatherNowIntervalField", "weatherHourlyIntervalField", "weatherDailyIntervalField",
    "weatherRetryDelayField", "weatherManualCooldownField", "weatherLeftBlockWidthField",
    "weatherMiddleBlockWidthField", "weatherRightBlockWidthField", "weatherLeftAlignmentCombo",
    "weatherMiddleAlignmentCombo", "weatherRightAlignmentCombo",
    "weatherIconPlacementCombo", "weatherIconXField", "weatherIconYField", "weatherIconSizeField",
    "weatherDescriptionXField", "weatherDescriptionYField", "weatherDescriptionWidthField", "weatherDescSizeField",
    "weatherShowComfortCheckBox", "weatherComfortOutlineWidthField", "weatherComfortYField", "weatherComfortOffsetXField",
    "weatherTempPositionXField", "weatherTempPositionYField", "weatherWindColumnXField", "weatherWindColumnYField",
    "weatherWindSpeedXField", "weatherWindSpeedYField", "weatherWindUnitXField", "weatherWindUnitYField",
    "weatherPressureXField", "weatherPressureYField", "weatherPressureUnitXField", "weatherPressureUnitYField",
    "weatherPressureWidthExtraField", "weatherPressureFontExtraField", "weatherPressureUnitFontExtraField",
    "whCount", "whPad", "whDayYTable", "whDaySizeTable", "whIconYTable", "whIconSizeTable",
    "whTempYTable", "whTempSizeTable", "wdCount", "wdPad", "wdDayYTable", "wdDaySizeTable",
    "wdIconYTable", "wdIconSizeTable", "wdHX", "wdHY", "wdHF", "wdLX", "wdLY", "wdLF",
]:
    assert control_id in weather, f"Weather SettingsRow lost control {control_id}"
player = (root / "components/settings/sections/SettingsPlayerSection.qml").read_text()
for label_text in [
    "Размер", "Шрифт", "Смещение по Y", "Отступ справа",
    "Размер основной строки метаданных",
    "Размер остальных строк", "Расстояние между строками",
    "Отступ метаданных по X", "Положение метаданных по Y",
    "Цвет обводки", "Прозрачность обложки (0–1)",
]:
    assert f'label: "{label_text}"' in player, f"Player SettingsRow label is missing: {label_text}"
for control_id in [
    "silenceSizeField", "silenceLongSizeField", "playerSilenceWidthField",
    "playerTimeFontSizeField", "playerTimeYField", "playerTimeRightPaddingField",
    "metaSizeField", "metaSecondarySizeField", "metaSpacingField",
    "playerMetaXPadField", "playerMetaYField", "playerTextOutlineColorField",
    "playerCoverOpacityField",
]:
    assert control_id in player, f"Player SettingsRow lost control {control_id}"
for label_text in ["Текст при отсутствии воспроизведения", "Основной шрифт плеера"]:
    assert f'label: "{label_text}"' in player, f"Player SettingsRow label is missing: {label_text}"
assert len(re.findall(r"\bSettingsRow\s*\{", player)) == 16, "expected 16 migrated Player rows"
notifications = (root / "components/settings/sections/SettingsNotificationsSection.qml").read_text()
for label_text in [
    "Обычные уведомления (с)",
    "Критические уведомления (с)",
    "Расстояние между карточками",
    "Максимальная высота превью",
    "Вертикальная привязка",
]:
    assert f'label: "{label_text}"' in notifications, f"Notifications SettingsRow label is missing: {label_text}"
timers = (root / "components/settings/sections/SettingsTimersSection.qml").read_text()
for label_text in [
    "Путь к изображению", "Ширина изображения", "Отступ изображения",
    "Цвет заголовка", "Свой цвет заголовка", "Размер заголовка",
    "Шрифт заголовка", "Расположение заголовка", "Цвет рамки окна",
    "Фон окна", "Свой цвет фона",
]:
    assert f'label: "{label_text}"' in timers, f"Timer SettingsRow label is missing: {label_text}"
timers = (root / "components/settings/sections/SettingsTimersSection.qml").read_text()
for label_text in [
    "Путь к изображению", "Ширина изображения", "Отступ изображения",
    "Цвет заголовка", "Свой цвет заголовка", "Размер заголовка",
    "Шрифт заголовка", "Расположение заголовка", "Цвет рамки окна",
    "Фон окна", "Свой цвет фона",
]:
    assert f'label: "{label_text}"' in timers, f"Timer SettingsRow label is missing: {label_text}"
for label_text in [
    "Комментарий", "Таймеры", "Стиль появления кнопок",
    "Затухание кнопок (мс)", "Сдвиг кнопок (мс)",
    "Появление/исчезновение иконок (мс)", "Стиль",
    "Анимация окна опций (мс)", "Диапазон", "От", "До",
    "Шрифт времени таймера", "Размер времени таймера",
    "Минимальная высота блока таймеров", "Шаг колеса таймера",
]:
    assert f'label: "{label_text}"' in timers, f"Timer layout/animation SettingsRow label is missing: {label_text}"
assert 'delegate: SettingsRow {' in timers, "timer preset rows do not use the shared SettingsRow primitive"
assert 'label: "Кнопка " + (index + 1)' in timers, "timer preset labels are not supplied through SettingsRow"
assert 'labelWidth: 75' in timers and 'labelColor: Config.textMuted' in timers, "timer preset label layout or color changed"
assert 'Settings.setTimerPresetDefault(presetIndex, n)' in timers, "timer preset value writer changed"
assert 'Settings.removeTimerPreset(index)' in timers, "timer preset remove action changed"
wind_row = (root / "components/settings/sections/WeatherWindDirectionSettingsRow.qml").read_text()
assert re.search(r"(?m)^SettingsRow\s*\{", wind_row), "wind direction row does not reuse SettingsRow"
assert "labelWidth: 130" in wind_row and "controlSpacing: 6" in wind_row, "wind direction row spacing/label width changed"
mopidy_labels = {
    "mopidy/SettingsMopidySection.qml": ["Наведение", "Разделитель альбома", "Шаг колеса"],
    "mopidy/SettingsMopidyStatusSection.qml": ["Текст «Очередь пуста»", "Текст «Недоступен»", "Шрифт текста", "Размер текста", "Размер длинного текста", "Ширина текста"],
    "mopidy/SettingsMopidyTimeSection.qml": ["Отображать", "Шрифт", "Положение", "Выравнивание", "Режим отображения", "Высота строки списка", "Разделитель в одну строку", "Шрифт альбома", "Шрифт названия трека", "Шрифт исполнителя", "Шрифт длительности"],
    "mopidy/SettingsMopidyAnimationSection.qml": ["Стиль"],
    "mopidy/SettingsMopidyIconsSection.qml": ["Скрывать верхнюю панель иконок", "Высота области наведения", "Отступ сверху (Y)"],
}
for filename, expected_labels in mopidy_labels.items():
    text = (root / "components/settings/sections" / filename).read_text()
    for label_text in expected_labels:
        assert f'label: "{label_text}"' in text, f"Mopidy SettingsRow label is missing in {filename}: {label_text}"
launcher = (root / "components/settings/sections/SettingsLauncherSection.qml").read_text()
launcher_labels = [
    "Вкладка по умолчанию", "Показывать счётчик RESULTS", "Vim-сочетания клавиш", "Отображать панель подсказок", "Нечёткий поиск",
    "Нечёткий поиск действий", "Нечёткий поиск тем", "Нечёткий поиск обоев",
    "Папка с изображениями", "Скругление окна", "Затемнение фона",
    "Высота элемента списка", "Скругление элементов", "Текст заголовка",
    "Шрифт заголовка", "Размер шрифта заголовка", "Положение Y заголовка",
    "Межбуквенный интервал", "Жирный заголовок", "Шрифт поиска",
    "Плейсхолдер поиска", "Размер шрифта поиска", "Высота строки", "Скругление строки",
]
for label_text in launcher_labels:
    assert f'label: "{label_text}"' in launcher, f"Launcher SettingsRow label is missing: {label_text}"
assert len(re.findall(r"\bSettingsRow\s*\{", launcher)) == 29, "expected 29 migrated Launcher rows"
for control_id in [
    "launcherDefaultModeCombo", "launcherResultCountCheckBox", "launcherFuzzySearchAppsCheckBox",
    "launcherFuzzySearchActionsCheckBox", "launcherFuzzySearchSchemesCheckBox",
    "launcherFuzzySearchWallpapersCheckBox", "launcherWallpaperDirectoryField",
    "launcherTitleTextField", "launcherTitleBoldCheckBox", "launcherSearchPlaceholderField",
]:
    assert control_id in launcher, f"Launcher SettingsRow lost control {control_id}"
assert 'fieldWidth: Math.max(80, Math.min(222, parent.width - 38))' in launcher, "Launcher font fields no longer account for the SettingsRow control slot"
assert row_total == 232, f"expected 232 shared settings rows across standard, Mopidy, Launcher, General and Settings Window sections, got {row_total}"
print(f"SettingsRow primitive: {row_total} shared rows across {len(sections)} sections: OK")
PY

node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const rootPath = process.argv[2];
const controller = fs.readFileSync(path.join(rootPath, 'components/settings/SettingsSearchController.qml'), 'utf8');

function extractFunction(source, name) {
  const start = source.indexOf(`function ${name}(`);
  assert(start >= 0, `${name} function exists`);
  const open = source.indexOf('{', start);
  let depth = 0, quote = null, escaped = false;
  for (let i = open; i < source.length; i++) {
    const ch = source[i];
    if (quote) {
      if (escaped) escaped = false;
      else if (ch === '\\') escaped = true;
      else if (ch === quote) quote = null;
      continue;
    }
    if (ch === '"' || ch === "'") { quote = ch; continue; }
    if (ch === '{') depth++;
    else if (ch === '}' && --depth === 0) return source.slice(start, i + 1);
  }
  throw new Error(`Unclosed function ${name}`);
}

const functions = [
  extractFunction(controller, 'settingsSearchAncestorRowLabel'),
  extractFunction(controller, 'settingsSearchItemLabel'),
].join('\n');
const context = { root: { settingsSearchSiblingLabel: () => '' } };
vm.createContext(context);
vm.runInContext(`${functions}\nthis.rowLabel = settingsSearchAncestorRowLabel; this.itemLabel = settingsSearchItemLabel;`, context);
context.root.settingsSearchAncestorRowLabel = context.rowLabel;

const row = { settingsSearchRowLabel: 'Интервал обновления данных', parent: null };
const rightSlot = { parent: row };
const controlLayout = { parent: rightSlot };
const control = { parent: controlLayout, label: '', settingsSearchLabel: '' };
assert.strictEqual(context.itemLabel(control), 'Интервал обновления данных', 'search label must inherit the containing SettingsRow label');
assert.strictEqual(context.itemLabel({...control, settingsSearchLabel: 'Точная поисковая метка'}), 'Точная поисковая метка', 'explicit search metadata must win over row label');
assert.strictEqual(context.itemLabel({...control, label: 'Собственная подпись'}), 'Собственная подпись', 'control label must win over row label');
console.log('SettingsRow search-label inheritance: 3/3');
JS

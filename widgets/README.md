# EWW -> Quickshell standalone port

## Настройки

Настройки сохраняются в `~/.config/quickshell-eww-port/settings.json`.

Открыть панель настроек: **правый клик по дате** в блоке часов.

В панели можно менять:
- токен Gismeteo;
- включение/выключение модулей;
- X/Y/ширину/высоту каждого модуля;
- цвета интерфейса, настроек, сетей, громкости, CPU/RAM, плеера и температур.

Изменения применяются сразу и сохраняются в JSON.

### v35
- Фон календаря снова отдельный и настраиваемый через `calendarBackground`.
- Слайдеры громкости переведены на собственную отрисовку и мышиное управление, чтобы исключить влияние стиля Qt Controls на цвета и обработку ввода.
- Добавлен `scripts/set_volume`: основной выход использует `wpctl`, затем `pactl`/`amixer`; потоковые слайдеры используют `pactl`.
- Текущее значение основной громкости читается через `wpctl`, с fallback на `pactl`/`amixer`.

Токен больше не хранится в архиве/репозитории: weather script читает его из settings.json.


### v38
- Сервис погоды создаётся только после загрузки настроек и только если включён хотя бы один погодный модуль.
- Если все погодные модули выключены, `Weather` полностью уничтожается и процессы с сетевыми запросами не запускаются.
- Каждый тип данных запрашивается только при включённом соответствующем модуле: сейчас — каждые 20 минут, почасовая и дневная погода — каждый час.
- Включение отдельного погодного модуля сразу запускает только нужный ему запрос; отключение останавливает соответствующий процесс и таймер.

### v40
- Удалена лишняя внутренняя рамка из блока даты: осталась одна рамка вокруг всего блока часов.
- Top Apps получили симметричные отступы слева и справа.
- Иконка основной погоды центрируется относительно всего блока; ветер отображается как стрелка / скорость / `м/с`.
- Погодные списки показывают и равномерно раскладывают 5 ближайших почасовых и 4 дневных значения, с верхним отступом.
- Таймерные кнопки теперь плавно скрываются, центрируются по вертикали и имеют левый отступ; активные таймеры получили верхний/правый отступ и более компактное разделение комментария и времени.
- Высота таймеров и громкости адаптируется под содержимое, а минимальные значения вынесены в `Config.qml`. Поле Height в настройках ограничивает максимум адаптивной высоты.
- Исправлено мерцание прошедших таймеров: их делегаты больше не пересоздаются каждую секунду.
- В плеере `silence` центрирован, декоративная переливающаяся полоска убрана; для DeadBeeF строки переставлены в порядок исполнитель / альбом / название, исполнитель выделяется жирным.
- CAVA стал тоньше и увеличен до 75 полос; количество полос добавлено в настройки и меняется с немедленным перезапуском CAVA.
- Для X/Y/Width/Height добавлено изменение колесом мыши с немедленным применением и сохранением.

### v39
- Тяжёлые фоновые процессы теперь привязаны к соответствующим модулям и не запускаются, когда модуль выключен.
- `cpu_stats_once`/RAM-опрос выполняются только при включённом CPU.
- Демон графика CPU запускается только при включённом графике CPU.
- CAVA не запускается без модуля CAVA.
- Плеерский polling `scripts/player` работает только при включённом плеере.
- Таймерный демон работает только при включённых таймерах.
- Опрос громкости запускается только при включённой громкости.
- Общий `system_monitor` работает только когда включён хотя бы один из модулей Top Apps / Сеть / Громкость / Networks.

### v45
- CAVA переработан без вложенных полноширинных делегатов: теперь используются только фиксированные 1px-бары для каждого индекса.
- Позиции баров округляются до целого пикселя, поэтому интервалы не должны плавать из-за дробной геометрии.
- CAVA снижен с 60 до 30 FPS, чтобы не нагружать Quickshell постоянным пересозданием/перерисовкой значений.
- Защитил разбор вывода CAVA от не-массивных строк.


## v45
CAVA restored to adaptive per-bar slot sizing from the stable v42 layout. Each bar width is now rounded to a whole pixel with a 1px minimum; CAVA remains at 30 FPS.

### v46
- Настройки разделены на вкладки: «Модули», «Цвета», «Прочие настройки».
- Координаты и размеры самого окна настроек вынесены в «Прочие настройки» и сохраняются в `settings.json`.
- Геометрия окна настроек применяется сразу; X/Y/Width/Height можно менять вводом или колесом мыши с шагом 1.
- Токен Gismeteo и количество полос CAVA перенесены во вкладку «Прочие настройки».


### v47
- В «Прочие настройки» добавлена частота обновления CAVA в FPS (1–120); при изменении CAVA автоматически перезапускается с новым значением.
- В «Прочие настройки» добавлены три сохраняемых значения кнопок таймера (в минутах). Они используются самими кнопками таймера, а изменение колесом также сохраняется.
- Цвет температуры текущей погоды отделён от общего `accent` и вынесен в `currentWeather`; он редактируется отдельно в группе «Погоды».

v48: timer presets are now a dynamic saved list. Settings can add/remove preset buttons and edit each value; the timer widget follows the saved list and the preset strip adapts/scrolls as needed.

### v49
- Таймеры: положение обратного отсчёта теперь рассчитывается от правого края блока с фиксированным правым отступом и не зависит от ширины ряда кнопок пресетов.
- Активные таймеры получили дополнительные верхний и правый отступы.
- Мини-окно действий таймера: время `time_passed` увеличено; иконки действий выровнены по центру с дополнительным левым внутренним отступом.
- Мини-окно действий таймера теперь закрывается кликом по свободному месту самого окна через сигнал `closeRequested`, который сбрасывает выбранный таймер в `TimerWidget`.

v50 timer polish:
- Timer preset buttons are positioned directly to the left of the timer counters and have higher z-order, so clicking a preset never selects the active timer underneath.
- TimerOptions closes on any click outside the mini window via a fullscreen transparent overlay.

### v51
- Таймер: кнопки пресетов возвращены в левую часть блока, как в исходном EWW; позиция активного таймера и его обратного отсчёта снова не зависит от ширины ряда пресетов.
- Мини-окно действий таймера теперь привязано к выбранному таймеру: располагается непосредственно слева от значения обратного отсчёта и выравнивается по строке выбранного таймера.
- Top Apps: усилены симметричные внешние отступы слева и справа.


## v52
- Restored the timer action mini-window to its original configurable `timerOptions` position while preserving outside-click closing via the full-screen overlay.
- Moved the timer comment (defaulting to the timer's total duration) next to the live countdown instead of the preset buttons.
- Top Apps now use explicit symmetric 8px outer gutters so the right margin is always visible.


### v56
- Timer block height now uses the saved timer `Height` as the minimum and grows automatically for additional active timers.
- Fixed TimerOptions popup visibility: the selected-timer state is now written to `shell.timerOptionsVisible` instead of a nonexistent overlay property.
- Added an explicit `timerOptionsPopup` id and routed open/close animation calls through it.

- Weather now: wind direction arrow is positioned relative to the wind-speed value and raised by 2 px; speed/unit geometry stays unchanged.

### v62
- Weather now: moved the wind-direction arrow 10 px closer to the wind-speed value without moving the speed/unit fields.

## v64
- Added player text/font settings: silence text, main player font, and metadata font.
- Persisted player text/font settings in `settings.json`.
- Player uses the configured silence text when no player is active and the configured metadata font for track information.


### v70
- Time/date block: added top/right padding to date and right padding to weekday.
- Network stats: added symmetric right internal padding for values.
- Player controls: pause/next buttons separated and vertically aligned to avoid overlap.
- Increased maximum adaptive volume window height from 500 to 650 px.

# quickshell-widgets

**Версия проекта: v582** · Набор настольных виджетов и настроек для [Quickshell](https://quickshell.org/).

[English below](#english)

## О проекте

`quickshell-widgets` — самостоятельный набор QML-виджетов для рабочего стола Linux на Quickshell. Проект включает системные индикаторы, календарь, таймеры, погоду, управление медиаплеерами и настраиваемое окно параметров.

## Возможности

- **Настраиваемая компоновка:** модули рабочего стола, положение и размеры окон, редактор раскладки и настройки внешнего вида.
- **CAVA:** верхние полоски, нижние полоски или обе половины; опциональное скрытие полосок при тишине. ЛКМ переключает воспроизведение активного плеера, ПКМ управляет отображением Mopidy.
- **Система:** время и дата, загрузка CPU, график CPU с режимами полосок «Обе половины», «Только верхние» и «Только нижние», память, громкость и сетевые показатели. Полоски CPU/RAM поддерживают четыре направления: слева направо, справа налево, сверху вниз и снизу вверх; вертикальные режимы отображают ядра CPU и RAM отдельными вертикальными индикаторами.
- **Погода:** текущие условия, почасовой и дневной прогноз; отображение комфортной температуры можно отключить отдельно. Для комфортной температуры предусмотрен контур для лучшей читаемости.
- **Календарь:** заметки для отдельных дат. ПКМ открывает редактор, ЛКМ показывает сохранённую заметку. Даты с заметками отмечаются выбранным индикатором: точкой, полоской, кольцом, значком или рамкой. Для меток доступны настройки цвета и положения.
- **Таймеры:** управление таймерами и настраиваемое окно завершения таймера.
- **Медиаплеер:** интеграция с несколькими бэкендами, информация о текущем треке и обложка альбома. Кнопка **Next** показывается только для DeaDBeeF, Mopidy и Spotify.
- **Mopidy:** очередь и плейлисты, перестановка элементов, добавление файлов из пустого плейлиста, настройка отображения исполнителя и названия трека в две строки или в одну через редактируемый разделитель, единая регулируемая высота строк треков, папок и плейлистов, переключаемое выравнивание общего времени очереди слева/справа, папки отображаются обычным начертанием независимо от жирности альбомов, жирное/курсивное начертание исполнителя, настраиваемый порядок кнопок верхней панели; в браузере файлов фильтр вызывается клавишей `/` и ищет по текущей папке; повторный клик по активной вкладке в корне («Папки», «Плейлисты» или «Поиск») закрывает браузер и возвращает очередь, а клик по «Плейлисты» из открытого плейлиста сначала возвращает к списку; цвет фона Mopidy сохраняется как строковое значение и восстанавливается при повторном запуске. Если очередь пуста и Mopidy доступен, клик по области очереди открывает браузер треков. Если Mopidy недоступен, клик по модулю запускает команду `mopidy` (без запуска второго экземпляра, если процесс уже работает). Верхнюю панель можно скрывать; доступны настройки зоны наведения, фона и вертикального отступа.
- **Обложки:** поиск локальных обложек рядом с файлом трека; для папок `CD1`/`CD2` также проверяется корень альбома. Для Mopidy предусмотрено получение изображения через API, когда локальный путь недоступен.
- **Профили и настройки:** параметры модулей и внешний вид настраиваются через UI, сохраняются в профиле и поддерживают предусмотренные проектом операции сброса.

## Установка

Требуется установленный Quickshell. Некоторые функции используют внешние программы и сервисы — например, CAVA, `playerctl`, `jq`, `curl`, PulseAudio/PipeWire-инструменты и запущенный Mopidy для соответствующих интеграций. Набор необходимых программ зависит от включённых модулей и используемых бэкендов.

Из корня проекта запустите установщик:

```sh
chmod +x install.sh
./install.sh
```

Код по умолчанию устанавливается в:

```text
~/.config/quickshell/desktop-shell
```

Пользовательские данные хранятся отдельно от кода по XDG:

- настройки и профили: `~/.config/quickshell-widgets/settings.json`;
- заметки календаря: `~/.local/share/quickshell-widgets/calendar-notes.json`;
- логи: `~/.local/state/quickshell-widgets/`;
- кэш: `~/.cache/quickshell-widgets/`.

Пути учитывают `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME` и `XDG_CACHE_HOME`. При первом запуске совместимые `settings.json` и `calendar-notes.json` из старой папки проекта или предыдущей установки Quickshell автоматически копируются в новые места, если целевые файлы ещё отсутствуют. Старые файлы не удаляются.

Запуск:

```sh
quickshell -c ~/.config/quickshell/desktop-shell
```

Если используется `XDG_CONFIG_HOME`, замените путь на соответствующий каталог конфигурации.

## Проверка

Из каталога проекта можно запустить:

```sh
./CHECK.sh
```

Это статическая проверка проекта; она не заменяет проверку виджетов в реальном сеансе Quickshell.

## Известные проблемы

- Для некоторых вариантов анимации исчезновения (`slideLeft`, `slideRight`, `slideUp`, `slideDown`) движение пока работает некорректно. Проблема отложена на более поздний этап; `fade` и отключение анимации работают.
- У скрываемой верхней панели Mopidy остаются редкие нюансы поведения при наведении и закрытии. Эта задача также временно имеет низкий приоритет.

## Сохранение пользовательских данных

Пользовательские данные хранятся отдельно от кода по XDG:

- настройки и профили: `~/.config/quickshell-widgets/settings.json`;
- заметки календаря: `~/.local/share/quickshell-widgets/calendar-notes.json`;
- логи: `~/.local/state/quickshell-widgets/`;
- кэш: `~/.cache/quickshell-widgets/`.

Каталоги учитывают абсолютные пути из `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME` и `XDG_CACHE_HOME`. Совместимые старые `settings.json` и `calendar-notes.json` автоматически копируются в новые места только при отсутствии целевых файлов. Исходники сохраняются как резервная копия. Не публикуйте личные токены или другие секреты в репозитории.

---

<a id="english"></a>

## English

`quickshell-widgets` is a standalone collection of QML desktop widgets for Linux powered by [Quickshell](https://quickshell.org/).

### Features

- **Configurable layout:** desktop modules, window geometry, layout editor and appearance settings.
- **CAVA visualizer:** upper bars only, lower bars only, or both halves; optional hiding during silence. Left-click toggles the active player, right-click controls Mopidy visibility.
- **System widgets:** clock and date, CPU and memory indicators, a CPU graph with both halves, upper-only or lower-only bar modes, volume and network information.
- **Weather:** current conditions, hourly and daily forecasts. The comfort-temperature overlay can be toggled and uses an outline for readability.
- **Calendar notes:** add or edit a note with right-click and view it with left-click. Dates with notes can be marked with a dot, bar, ring, note icon or border; marker color and placement are configurable.
- **Timers:** timer controls and a configurable timer-completion window.
- **Media player:** multiple backends, track metadata and album artwork. The **Next** button is only shown for DeaDBeeF, Mopidy and Spotify.
- **Mopidy:** queue and playlist management, item reordering, adding files from an empty playlist, a shared configurable row height for tracks, folders and playlists, configurable left/right alignment for total queue time, normal-weight folder names independent of album bold styling, custom artist/title separators with bold/italic artist styling, and a configurable top-panel icon order; the file browser supports an `/`-activated filter for the current folder. The Mopidy background color is stored as a string and restored reliably on reload. When Mopidy is available but the queue is empty, clicking the queue area opens the track browser. If Mopidy is unavailable, clicking the module attempts to start `mopidy` without starting a duplicate process. The top panel can be hidden, with settings for its hover area, background and vertical offset.
- **Artwork lookup:** looks for local cover images next to the track; for `CD1`/`CD2` folders it also checks the album root. Mopidy API artwork is used when a local path is unavailable.
- **Profiles and settings:** modules and appearance can be configured in the UI, saved to profiles and reset using the available reset actions.

### Installation

Quickshell is required. Some features rely on external tools or services, such as CAVA, `playerctl`, `jq`, `curl`, PulseAudio/PipeWire utilities, and a running Mopidy service for the relevant integrations. Exact requirements depend on enabled modules and backends.

Run the installer from the project root:

```sh
chmod +x install.sh
./install.sh
```

The default install location is:

```text
~/.config/quickshell/desktop-shell
```

The installer attempts to migrate compatible legacy settings and calendar notes into the XDG user-data directories. Existing canonical files are never overwritten, and legacy originals are retained.

Launch the shell with:

```sh
quickshell -c ~/.config/quickshell/desktop-shell
```

If you use `XDG_CONFIG_HOME`, adjust the path accordingly.

### Validation

Run the project checks from its root directory:

```sh
./CHECK.sh
```

This is a static project check and does not replace runtime testing in a live Quickshell session.

### Known issues

- Disappearance animations using `slideLeft`, `slideRight`, `slideUp` or `slideDown` are still under investigation. `fade` and disabling animations work.
- The hidden Mopidy top panel still has occasional hover/close edge cases. This issue is intentionally lower priority for now.

### User data

User data is stored separately from the installed code using XDG directories:

- settings and profiles: `~/.config/quickshell-widgets/settings.json`;
- calendar notes: `~/.local/share/quickshell-widgets/calendar-notes.json`;
- logs: `~/.local/state/quickshell-widgets/`;
- cache: `~/.cache/quickshell-widgets/`.

The paths honor `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, and `XDG_CACHE_HOME`. On first use, compatible legacy `settings.json` and `calendar-notes.json` files from the project directory or a previous Quickshell install are copied to the new locations if the destination files do not exist. Originals are kept. Do not commit personal tokens or other secrets to the repository.

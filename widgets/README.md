# quickshell-widgets

**Версия проекта: v562** · Набор настольных виджетов и настроек для [Quickshell](https://quickshell.org/).

[English below](#english)

## О проекте

`quickshell-widgets` — самостоятельный набор QML-виджетов для рабочего стола Linux на Quickshell. Проект включает системные индикаторы, календарь, таймеры, погоду, управление медиаплеерами и настраиваемое окно параметров.

## Возможности

- **Настраиваемая компоновка:** модули рабочего стола, положение и размеры окон, редактор раскладки и настройки внешнего вида.
- **CAVA:** отображение верхних полосок, нижних полосок или обеих половин.
- **Система:** время и дата, загрузка CPU, графики и индикаторы ресурсов, память, громкость и сетевые показатели.
- **Погода:** текущие условия, почасовой и дневной прогноз; отображение комфортной температуры можно отключить отдельно. Для комфортной температуры предусмотрен контур для лучшей читаемости.
- **Календарь:** заметки для отдельных дат. ПКМ открывает редактор, ЛКМ показывает сохранённую заметку. Даты с заметками отмечаются выбранным индикатором: точкой, полоской, кольцом, значком или рамкой. Для меток доступны настройки цвета и положения.
- **Таймеры:** управление таймерами и настраиваемое окно завершения таймера.
- **Медиаплеер:** интеграция с несколькими бэкендами, информация о текущем треке и обложка альбома. Кнопка **Next** показывается только для DeaDBeeF, Mopidy и Spotify.
- **Mopidy:** очередь и плейлисты, перестановка элементов, добавление файлов из пустого плейлиста, настраиваемый порядок кнопок верхней панели. Верхнюю панель можно скрывать; доступны настройки зоны наведения, фона и вертикального отступа.
- **Обложки:** поиск локальных обложек рядом с файлом трека; для папок `CD1`/`CD2` также проверяется корень альбома. Для Mopidy предусмотрено получение изображения через API, когда локальный путь недоступен.
- **Профили и настройки:** параметры модулей и внешний вид настраиваются через UI, сохраняются в профиле и поддерживают предусмотренные проектом операции сброса.

## Установка

Требуется установленный Quickshell. Некоторые функции используют внешние программы и сервисы — например, CAVA, `playerctl`, `jq`, `curl`, PulseAudio/PipeWire-инструменты и запущенный Mopidy для соответствующих интеграций. Набор необходимых программ зависит от включённых модулей и используемых бэкендов.

Из корня проекта запустите установщик:

```sh
chmod +x install.sh
./install.sh
```

По умолчанию проект устанавливается в:

```text
~/.config/quickshell/desktop-shell
```

Установщик старается перенести совместимый `settings.json` из прежней установки, если в новом каталоге настроек ещё нет.

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

Пользовательские настройки хранятся в каталоге конфигурации Quickshell. Заметки календаря сохраняются отдельно от профилей настроек. Не публикуйте личные токены или другие секреты в репозитории.

---

<a id="english"></a>

## English

`quickshell-widgets` is a standalone collection of QML desktop widgets for Linux powered by [Quickshell](https://quickshell.org/).

### Features

- **Configurable layout:** desktop modules, window geometry, layout editor and appearance settings.
- **CAVA visualizer:** upper bars only, lower bars only, or both halves.
- **System widgets:** clock and date, CPU and memory indicators, graphs, volume and network information.
- **Weather:** current conditions, hourly and daily forecasts. The comfort-temperature overlay can be toggled and uses an outline for readability.
- **Calendar notes:** add or edit a note with right-click and view it with left-click. Dates with notes can be marked with a dot, bar, ring, note icon or border; marker color and placement are configurable.
- **Timers:** timer controls and a configurable timer-completion window.
- **Media player:** multiple backends, track metadata and album artwork. The **Next** button is only shown for DeaDBeeF, Mopidy and Spotify.
- **Mopidy:** queue and playlist management, item reordering, adding files from an empty playlist, and a configurable top-panel icon order. The top panel can be hidden, with settings for its hover area, background and vertical offset.
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

If no settings file exists at the destination, the installer attempts to import a compatible `settings.json` from another Quickshell configuration directory.

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

User settings are stored in the Quickshell configuration directory. Calendar notes are kept separately from settings profiles. Do not commit personal tokens or other secrets to the repository.

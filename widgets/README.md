# Quickshell Widgets

A standalone collection of configurable Wayland desktop widgets built for [Quickshell](https://quickshell.org/).

**Русская версия ниже / Russian version below.**

---

## English

### What is it?

Quickshell Widgets is a modular desktop widget shell for Wayland. It is focused on a compact, highly configurable setup that can be arranged directly from the settings UI.

The project includes its own settings interface, profiles, theme/color editing, module positioning, animations, and per-module sizing and styling.

### Included widgets

| Widget | What it provides |
|---|---|
| Clock | Time, date, calendar integration |
| Calendar | Month view with configurable typography and navigation |
| CPU / RAM | Usage bars and numeric information |
| CPU Graph | Lightweight history graph |
| Top Apps | Top processes/applications |
| Network | Upload/download statistics |
| Network Connections | Active network connections |
| Weather | Current, hourly and daily forecasts |
| Timer / Alarm | Multiple timers, presets and alarm target |
| Player | Media information, controls, cover and progress |
| Volume | Main volume and stream volumes |
| Cava | Audio spectrum visualization |
| System Monitor | Configurable process/network/volume sources |

Individual modules can be enabled or disabled, positioned independently, resized, and styled from Settings.

### Settings

The settings UI provides:

- module enable/disable switches;
- X/Y position and width/height controls;
- borders and backgrounds per module;
- colors and theme editing;
- fonts, icons and typography;
- animation settings;
- Timer / Alarm presets and ordering;
- Player customization;
- Weather layout and update intervals;
- Profiles for saving and restoring settings.

#### Moving modules and the Settings window

**Smart Editing** moves modules with a live preview frame and supports moving across monitors.

**Smart Moving** moves the Settings window in the same way and can also cross monitors. Press `Esc` to leave the Settings moving mode.

The Clock widget uses a left click for the calendar and a right click to open Settings.

### Installation

Clone the repository and run the included installer:

```bash
git clone <repository-url>
cd quickshell-widgets
./install.sh
```

The installer copies the project to:

```text
~/.config/quickshell/desktop-shell
```

It also attempts to preserve a compatible existing `settings.json` when migrating from an earlier installation.

Start the shell with:

```bash
quickshell -c ~/.config/quickshell/desktop-shell
```

### Dependencies

The shell is designed for Wayland and requires Quickshell. Some dependencies are only needed by the modules that use them:

- `jq` — JSON processing;
- `curl` — Weather / Player data;
- `playerctl` — media player integration;
- `cava` — spectrum visualization;
- `pactl` and/or `wpctl` — volume control;
- `nmcli` — network information;
- `bc` — calculations used by monitoring scripts;
- `niri` — focused-output detection used by the shell.

A Nerd Font is recommended for the icon-based modules.


### Player backend architecture

Player metadata and controls intentionally remain separate. The two stable entrypoints (`scripts/player` and `scripts/player_pausing`) share a small backend layer under `scripts/player.d/`. Backend-specific code is isolated there, making it easier to extend the Player with additional integrations such as Mopidy without turning the main scripts into monolithic files.
Player backend selection follows the configurable priority order from the Player settings. Disabled backends are skipped, and the first available enabled backend supplies the current metadata.

### Configuration and data

The project keeps persistent settings in its `settings.json`. Most configuration is intended to be changed through the built-in Settings UI rather than by editing QML manually.

Profiles can be used to save and restore complete settings sets.

### Project structure

```text
.
├── shell.qml
├── Config.qml
├── Settings.qml
├── components/
│   ├── widgets and shared layout components
│   └── settings/
│       ├── primitives/   # reusable Settings UI controls
│       └── sections/     # module/domain-specific settings
├── services/              # Weather, System Monitor, Clock
├── scripts/               # module helper scripts
├── install.sh
└── LICENSE
```

### License

MIT License. See [LICENSE](LICENSE).

---

## Русский

### Что это?

**Quickshell Widgets** — самостоятельный набор настраиваемых виджетов рабочего стола для Wayland, работающий на [Quickshell](https://quickshell.org/).

Проект ориентирован на компактную конфигурацию с большим количеством настроек: модули можно включать и выключать, перемещать между мониторами, менять их размеры, цвета, шрифты, иконки и поведение прямо через встроенное окно настроек.

### Что входит в проект

| Модуль | Возможности |
|---|---|
| Часы | Время, дата, календарь |
| Календарь | Просмотр месяца и настраиваемая навигация |
| CPU / RAM | Полосы загрузки и числовые значения |
| График CPU | История загрузки CPU |
| Top Apps | Топ процессов/приложений |
| Сеть | Скорость загрузки и отдачи |
| Сетевые подключения | Активные сетевые подключения |
| Погода | Текущая, почасовая и дневная погода |
| Таймер / Будильник | Несколько таймеров, пресеты и цель будильника |
| Плеер | Информация о треке, управление, обложка и прогресс |
| Громкость | Общая громкость и громкость отдельных потоков |
| Cava | Визуализация аудиоспектра |
| System Monitor | Настраиваемые источники мониторинга процессов, сети и громкости |

Каждый модуль можно отдельно включать и выключать, перемещать, изменять его размер и настраивать внешний вид.

### Настройки

Во встроенном окне настроек доступны:

- включение и отключение модулей;
- координаты X/Y и размеры;
- рамка и фон каждого модуля;
- редактирование цветов и тем;
- шрифты, иконки и типографика;
- анимации;
- пресеты Таймера / Будильника и их порядок;
- настройка Плеера;
- настройка текущей, почасовой и дневной погоды;
- профили для сохранения и восстановления настроек.

#### Перемещение модулей и окна настроек

**Умное редактирование** позволяет перемещать модули с живой рамкой и переносить их между мониторами.

**Умное перемещение** работает так же для окна настроек и тоже поддерживает несколько мониторов. Для выхода из режима переноса нажмите `Esc`.

У виджета Часов **левый клик** открывает календарь, а **правый клик** — настройки.

### Установка

Склонируйте репозиторий и запустите готовый установщик:

```bash
git clone <repository-url>
cd quickshell-widgets
./install.sh
```

Установщик копирует проект в:

```text
~/.config/quickshell/desktop-shell
```

При миграции он также пытается сохранить совместимый существующий `settings.json`.

Запуск:

```bash
quickshell -c ~/.config/quickshell/desktop-shell
```

### Зависимости

Проект рассчитан на Wayland и требует Quickshell. Некоторые зависимости нужны только соответствующим модулям:

- `jq` — работа с JSON;
- `curl` — данные Погоды / Плеера;
- `playerctl` — управление медиаплеером;
- `cava` — аудиовизуализация;
- `pactl` и/или `wpctl` — управление громкостью;
- `nmcli` — информация о сети;
- `bc` — вычисления мониторинга;
- `niri` — определение активного выхода/монитора.

Для модулей с иконками рекомендуется Nerd Font.


### Архитектура Плеера

Получение метаданных и управление Плеером намеренно разделены. Два стабильных entrypoint-файла (`scripts/player` и `scripts/player_pausing`) используют общий слой backend-логики в `scripts/player.d/`. Код конкретных backend изолирован отдельно, поэтому добавление новых интеграций, например Mopidy, не превращает основные скрипты в монолитные файлы.
Порядок выбора backend настраивается отдельно в параметрах Плеера: отключённые backend пропускаются, а первый доступный включённый backend становится источником текущих метаданных.

### Настройки и данные

Сохранённые настройки находятся в `settings.json`. Основная настройка проекта предполагается через встроенное окно Settings, без необходимости вручную редактировать QML.

Профили позволяют сохранять и восстанавливать наборы настроек целиком.

### Структура проекта

```text
.
├── shell.qml
├── Config.qml
├── Settings.qml
├── components/
│   ├── виджеты и общие компоненты
│   └── settings/
│       ├── primitives/   # переиспользуемые элементы интерфейса Settings
│       └── sections/     # настройки отдельных модулей/разделов
├── services/              # Weather, System Monitor, Clock
├── scripts/
│   ├── player             # получение состояния и метаданных Плеера
│   ├── player_pausing     # управление Плеером
│   └── player.d/          # общая логика и backend-адаптеры Плеера
├── install.sh
└── LICENSE
```

### Лицензия

MIT License. Подробности — в файле [LICENSE](LICENSE).

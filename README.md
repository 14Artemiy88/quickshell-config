# quickshell-widgets

Configurable desktop widgets and a keyboard-driven launcher for **Quickshell** on Linux/Wayland. The project is written in QML/Qt Quick with Bash and JavaScript helpers. Settings, profiles, themes, and calendar notes are managed through the built-in UI; user data is stored outside the source tree.

**Current baseline: v839.** The source archive contains generic defaults; launcher project paths, IDE locations, and API keys are kept in user configuration, not in the repository.

## Русский

`quickshell-widgets` — набор виджетов рабочего стола и встроенный лаунчер для Quickshell. Проект рассчитан на Linux/Wayland; отдельные функции зависят от установленного рабочего стола и внешних утилит.

### Возможности

- Часы и настраиваемое расположение модулей.
- Мониторинг CPU/RAM, графики CPU, Top Apps и CAVA.
- Player с поддержкой доступных MPRIS-плееров, MPV, DeaDBeeF, Spotify и браузерной интеграции.
- Mopidy: управление воспроизведением, очередь, библиотека, плейлисты, поиск файлов и обложки.
- Таймеры и будильники, пресеты, комментарии и окно завершения.
- Календарь с заметками, отметками дат, навигацией по соседним месяцам и настройками анимации.
- Текущая погода, почасовой и дневной прогнозы через Gismeteo API.
- Громкость основного выхода и аудиопотоков, состояние сети и активные подключения.
- Встроенный лаунчер: Apps, Run, Windows, Clipboard, Power, Network, Packages, Pass и Projects; запуск по Enter, сохранённые команды и проекты.
- Сквозной поиск из Apps по установленным приложениям, проектам и сохранённым командам с отдельными переключателями источников; результаты показывают соответствующие иконки.
- Общая система настроек, тем, цветов, профилей и рамочных групп; развёрнутый список тем показывает палитры до выбора, а настройки виджетов редактируются через UI.

### Требования

**Базовые:** Quickshell с Qt Quick/Wayland-модулями, Bash и `jq`. Для работы скриптов также используются стандартные Linux-утилиты (`awk`, `grep`, `sed`, `flock`, `ps`, `stat` и др.). Для отдельных функций нужны `curl`, `python3`, `file` и `playerctl`.

**Дополнительные функции и их зависимости:**

| Возможность | Зависимости |
| --- | --- |
| Аудиовизуализация CAVA | `cava` |
| Сетевой виджет и вкладка Network | NetworkManager, `nmcli` |
| Player | D-Bus/MPRIS и/или `playerctl`; конкретный плеер для соответствующего backend |
| Громкость | `pactl` (PulseAudio/PipeWire) и/или `wpctl` (WirePlumber) |
| Mopidy | Работающий Mopidy-сервер с доступным HTTP JSON-RPC API; для некоторых операций также `curl`, `jq`, `python3` и `file` |
| Clipboard | `cliphist`, `wl-copy` и соответствующая Wayland-среда |
| Pass | `pass` и `wl-copy` |
| Windows в лаунчере | Niri CLI (`niri`) и Zsh, доступные в пользовательском окружении |
| Run в лаунчере | `foot` и Zsh для сохранения вывода интерактивных терминальных команд |
| Packages (Nix) | Подключение к `search.nixos.org` через HTTPS; установленный Nix нужен для работы с пакетами локально |
| Погода | Ключ Gismeteo API, указанный в настройках |

Если дополнительная утилита не установлена, соответствующая интеграция может быть недоступна; базовые виджеты не требуют установки всех перечисленных компонентов.

### Установка и обновление

Склонируйте репозиторий или распакуйте архив, затем из корня проекта выполните:

```sh
./install.sh
```

Установщик копирует код в `~/.config/quickshell/desktop-shell` (с учётом `XDG_CONFIG_HOME`) и печатает команду запуска. Он пытается перенести совместимые старые настройки и заметки, если целевые файлы ещё не существуют; исходные пользовательские данные не удаляются.

Запуск установленной конфигурации:

```sh
quickshell -c "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/desktop-shell"
```

Если в системе используется команда `qs` вместо `quickshell`, примените её с тем же аргументом `-c`. Для обновления запустите `install.sh` ещё раз. Установщик не удаляет пользовательские настройки при обновлении.

### Настройки и пользовательские данные

- Конфигурация и токен погоды: `${XDG_CONFIG_HOME:-~/.config}/quickshell-widgets/settings.json`.
- Заметки календаря: `${XDG_DATA_HOME:-~/.local/share}/quickshell-widgets/calendar-notes.json`.
- Локальные проекты лаунчера редактируются в **Настройки → Лаунчер → Проекты**.
- Публичная версия намеренно начинается с пустого списка проектов: пути к репозиториям и IDE зависят от конкретной машины. Добавьте свои записи через настройки; существующий пользовательский список в отдельном `settings.json` сохраняется.
- Новые настройки входят в общую систему профилей. Ключ погоды хранится вне исходного кода и не включается в профили.

Не добавляйте в Git пользовательский `settings.json`, токены, заметки календаря или другие приватные данные.

### Лаунчер и кейбинды Niri

Вкладка «Лаунчер» расположена перед «Окно настроек». Из UI можно настроить стартовую вкладку, отображение вкладок, их порядок, размеры, прозрачность фона, текст и оформление заголовка, а также шрифт, размер, высоту, скругление и фон строки поиска. Во вкладке Power строка поиска скрыта, поскольку список действий фиксированный. Текст, акцент и рамки лаунчера берутся из общей темы; собственный цвет фона окна настраивается отдельно в «Настройки → Лаунчер». Цвет фона окна настроек доступен в «Настройки → Окно настроек», а не в списке цветов темы.

Для привязок Niri используется IPC текущего экземпляра Quickshell. Для стандартной конфигурации пример выглядит так:

```kdl
Mod+Space { spawn "qs" "ipc" "call" "launcher" "toggle"; }
Alt+1 { spawn "qs" "ipc" "call" "launcher" "openApps"; }
Alt+2 { spawn "qs" "ipc" "call" "launcher" "openRun"; }
Alt+3 { spawn "qs" "ipc" "call" "launcher" "openWindows"; }
Alt+4 { spawn "qs" "ipc" "call" "launcher" "openClipboard"; }
Alt+5 { spawn "qs" "ipc" "call" "launcher" "openPower"; }
Alt+6 { spawn "qs" "ipc" "call" "launcher" "openNetwork"; }
Alt+7 { spawn "qs" "ipc" "call" "launcher" "openPackages"; }
Alt+8 { spawn "qs" "ipc" "call" "launcher" "openPass"; }
Alt+9 { spawn "qs" "ipc" "call" "launcher" "openProjects"; }
```

Если Quickshell запущен с нестандартным каталогом конфигурации через `-c`, указывайте этот же путь в аргументах `qs` у кейбиндов, иначе IPC может обратиться к экземпляру конфигурации по умолчанию. Пример: `spawn "qs" "-c" "/absolute/path/to/desktop-shell" "ipc" "call" "launcher" "toggle"`. Примеры выше не меняют Niri config автоматически.

Внутри лаунчера доступны переключение вкладок клавиатурой, нечёткий поиск, тематическая подсветка совпадений и управление списком проектов. Вкладка Apps может искать не только приложения, но и проекты и сохранённые команды из истории Run; включение каждого дополнительного источника настраивается отдельно. Результаты помечаются типом и имеют свою иконку. Запуск проекта передаёт путь и исполняемый файл IDE отдельными аргументами, без `eval`.

В настройках темы можно включить «Развернуть», чтобы увидеть список тем вместе с цветовыми образцами. В компактном режиме остаётся прежний выбор темы и связанная с ним логика изменений (`Changed`).

### Разработка и тесты

Запуск полного набора статических и fixture-based проверок из корня проекта:

```sh
bash CHECK.sh
```

Для тестов требуются `jq`, `curl`, `file`, Python 3 и Node.js; тесты не запускают полноценную графическую сессию Quickshell, поэтому после изменений QML дополнительно проверьте соответствующий виджет в целевом окружении. Некоторые проверки используют контролируемые Linux-процессы и `/proc`.

Основные каталоги:

- `components/` — виджеты, лаунчер и повторно используемые QML-примитивы.
- `components/settings/` — интерфейс настроек и секции модулей.
- `js/settings/` — значения по умолчанию, схема, сохранение, профили и применение настроек.
- `scripts/` — Bash-сценарии для мониторинга, плеера, Mopidy, таймеров, погоды и аудио.
- `services/` — сервисы Quickshell для часов, системного мониторинга и погоды.
- `tests/` — регрессионные тесты.
- `benchmarks/` — fixture-based микро-бенчмарки и некоторые сохранённые результаты; они измеряют отдельные пути выполнения, а не полную задержку интерфейса.

### Лицензия

MIT. См. [`LICENSE`](LICENSE).

## English

`quickshell-widgets` is a configurable set of Linux/Wayland desktop widgets and an integrated launcher for Quickshell, implemented with QML/Qt Quick, Bash, and JavaScript helpers.

### Features

- Clock and configurable widget layout.
- CPU/RAM monitoring, CPU graphs, Top Apps, and CAVA.
- Media Player supporting available MPRIS players, MPV, DeaDBeeF, Spotify, and browser integration.
- Mopidy playback controls, queue, library, playlists, file browsing, and cover art.
- Timers and alarms, presets, comments, and finish window.
- Calendar notes, date markers, adjacent-month navigation, and animation options.
- Current weather plus hourly and daily forecasts via the Gismeteo API.
- Output/stream volume, network statistics, and active connections.
- Integrated launcher tabs: Apps, Run, Windows, Clipboard, Power, Network, Packages, Pass, and Projects, including keyboard activation, saved commands, and project launching.
- Apps cross-search across installed applications, configured projects, and saved Run commands, with configurable source toggles and per-result icons.
- Shared settings, themes, color palette, profiles, and reusable framed settings groups; an expanded theme palette previews each theme before selection.

### Requirements

Core runtime: Quickshell with Qt Quick/Wayland modules, Bash, and `jq`. Shell helpers use common Linux utilities; specific features may additionally need `curl`, Python 3, `file`, and `playerctl`.

| Feature | Additional dependency |
| --- | --- |
| CAVA visualization | `cava` |
| Network widget / Network launcher tab | NetworkManager and `nmcli` |
| Media Player | D-Bus/MPRIS and/or `playerctl`; the relevant player/backend |
| Volume | `pactl` and/or `wpctl` |
| Mopidy | A running Mopidy server with reachable HTTP JSON-RPC; some operations use `curl`, `jq`, Python 3, and `file` |
| Clipboard | `cliphist`, `wl-copy`, and a Wayland session |
| Pass | `pass` and `wl-copy` |
| Launcher Windows tab | Niri CLI and Zsh available in the user environment |
| Launcher Run tab | Foot and Zsh for persistent terminal command output |
| Nix Packages tab | HTTPS access to `search.nixos.org`; local Nix tools are needed for local package operations |
| Weather | A Gismeteo API key entered in Settings |

Missing optional commands only disable the related integration; not every optional dependency is required for the core widgets.

### Install and update

Clone or extract the repository and run from its root:

```sh
./install.sh
```

The installer copies the runtime tree to `~/.config/quickshell/desktop-shell` (respecting `XDG_CONFIG_HOME`) and prints the launch command. It attempts to migrate compatible legacy settings and calendar notes only if the destination data does not already exist. The original user data is not deleted.

Start the installed configuration with:

```sh
quickshell -c "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/desktop-shell"
```

Use `qs` instead of `quickshell` if that is the executable installed on your system. Run the installer again to update; user settings are kept outside the source tree.

### Configuration and user data

- Settings and the weather key: `${XDG_CONFIG_HOME:-~/.config}/quickshell-widgets/settings.json`.
- Calendar notes: `${XDG_DATA_HOME:-~/.local/share}/quickshell-widgets/calendar-notes.json`.
- Launcher project entries are edited in **Settings → Launcher → Projects**.
- The public source starts with an empty Projects catalogue intentionally: repository and IDE paths are machine-specific. Add your entries in Settings. An existing user catalogue stored in the external settings file is preserved.
- Settings participate in the shared profile system. The weather API key stays outside the source code and is excluded from profiles.

Do not commit personal settings, API keys, calendar notes, or other private runtime data.

### Niri keybindings

The Launcher settings are placed immediately before Settings Window. Its startup tab, visible tabs, tab order, geometry, backdrop opacity, and project catalogue are configurable. Launcher text, accent, and borders use the active shared theme; the launcher window background has its own setting under Settings → Launcher. The settings-window background is configured under Settings → Settings Window rather than in the theme color editor.

Example bindings for a default Quickshell instance:

```kdl
Mod+Space { spawn "qs" "ipc" "call" "launcher" "toggle"; }
Alt+1 { spawn "qs" "ipc" "call" "launcher" "openApps"; }
Alt+2 { spawn "qs" "ipc" "call" "launcher" "openRun"; }
Alt+3 { spawn "qs" "ipc" "call" "launcher" "openWindows"; }
Alt+4 { spawn "qs" "ipc" "call" "launcher" "openClipboard"; }
Alt+5 { spawn "qs" "ipc" "call" "launcher" "openPower"; }
Alt+6 { spawn "qs" "ipc" "call" "launcher" "openNetwork"; }
Alt+7 { spawn "qs" "ipc" "call" "launcher" "openPackages"; }
Alt+8 { spawn "qs" "ipc" "call" "launcher" "openPass"; }
Alt+9 { spawn "qs" "ipc" "call" "launcher" "openProjects"; }
```

If Quickshell is launched with a non-default configuration directory (`-c`), pass that same directory to the `qs` IPC command in the binding. The examples do not edit your Niri configuration automatically.

The Apps tab can also search configured projects and saved Run commands. Each source can be toggled in launcher settings; cross-search results are labelled by type and display a corresponding icon. The Settings → Colors page has an optional expanded theme list with color previews; disable it to return to the compact selector.

### Development and tests

Run the static and fixture-based checks from the repository root:

```sh
bash CHECK.sh
```

Tests require `jq`, `curl`, `file`, Python 3, and Node.js. They do not launch a complete graphical Quickshell session, so visually verify affected QML widgets in the target environment. Some tests use Linux process and `/proc` fixtures.

Main directories: `components/` (widgets, launcher, shared QML primitives), `components/settings/` (settings UI), `js/settings/` (schema, defaults, persistence and profiles), `scripts/` (shell helpers), `services/` (Quickshell services), `tests/` (regression tests), and `benchmarks/` (fixture-based microbenchmarks and selected historical results). Microbenchmarks isolate code paths and do not represent total UI latency.

### License

MIT; see [`LICENSE`](LICENSE).

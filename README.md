# quickshell-widgets

Configurable desktop widgets, a dashboard, and a keyboard-driven launcher for **Quickshell** on Linux/Wayland. The project is written in QML/Qt Quick with JavaScript and Bash helpers.

## Русский

`quickshell-widgets` — набор модулей рабочего стола и встроенный лаунчер. Проект рассчитан на Quickshell в графической сессии Wayland; доступность отдельных интеграций зависит от рабочего стола и установленных утилит.

### Возможности

- **Уведомления:** режим DND с каталогом фактических отправителей уведомлений, независимыми правилами по desktop ID или точному имени приложения и удалением отправителя вместе с обоими правилами; исключённые приложения продолжают показывать всплывающие уведомления. История последних уведомлений открывается прямо в окне Dashboard, поддерживает удаление отдельных записей и хранится только в оперативной памяти; её размер настраивается в параметрах Notifications (1–200 записей, по умолчанию 30).
- **Виджеты рабочего стола:** часы с отдельными настройками шрифта и размеров времени, даты и дня недели, CPU/RAM и Top Apps, сетевой трафик и подключения, громкость и аудиопотоки, CAVA, календарь с заметками и метками, текущая погода и прогнозы, таймеры и будильники, Player, Mopidy и собственные уведомления.
- **Dashboard:** карточки «Сегодня», «Система», «Сеть», «Погода» и «Медиа». Видимость, порядок и размер карточек настраиваются независимо; есть адаптивная одно- и двухколоночная раскладка и встроенный режим редактирования.
- **Launcher:** приложения, Run, окна, буфер обмена, питание, сеть, пакеты, Pass, проекты и калькулятор. Поддерживаются пользовательские действия, поиск по нескольким источникам, избранные приложения, проекты, палитра команд и каталог эмодзи. В настройках **Настройки → Лаунчер → Действия → Переходы** можно независимо скрывать встроенные команды из палитры `>`; каталог сохранённых пользовательских действий открывается отдельным префиксом `:` и не смешивается с этой палитрой.
- **Общие настройки:** группы «Внешний вид», «Модули», «Dashboard», «Лаунчер» и «Общие»; вложенные страницы и подразделы можно искать и упорядочивать перетаскиванием.
- **Профили и темы:** именованные профили, сохранение и сброс отдельных разделов, встроенные и пользовательские цветовые схемы.
- **Анимации:** независимые настройки модулей, профили кривых и длительность переходов; анимации можно отключать отдельно.
- **Drag & Drop:** единый механизм изменения порядка используется в настройках, Launcher, Dashboard, Player, Timer и Mopidy, включая очередь и сохранённые плейлисты.

### Поиск и навигация в Launcher

- Встроенная палитра команд открывается префиксом `>`: например, `>dashboard`, `>overview` или `>обзор` переключают Dashboard. Пользовательские действия не смешиваются со встроенными командами и доступны через отдельный префикс `:`; каталог сохранённых пользовательских действий можно просматривать без поискового запроса.
- Нечёткий поиск пользовательских действий, цветовых схем и обоев настраивается независимо в разделе **Настройки → Лаунчер → Поиск**. Параметры **Schemes setting** и **Wallpapers setting** управляют поиском по схемам и обоям; поиск действий имеет собственный переключатель.
- Для динамической цветовой схемы доступны варианты `Fruit Salad` и `Tonal Spot`. Встроенная команда `>scheme variants` открывает выбор вариантов; краткий алиас `>variant` выполняет ту же команду.
- Дополнительная Vim-навигация включается отдельно и отключена по умолчанию (`disabled by default`). При включении `Ctrl+J`/`Ctrl+N` перемещают выбор вниз, а `Ctrl+K`/`Ctrl+P` — вверх.
- Панель клавиатурных подсказок **«Отображать панель подсказок»** отображается по умолчанию; её видимость регулируется отдельно от Vim-навигации.

### Dashboard

Карточки информационные: клик по их поверхности ничего не открывает. В заголовке панели доступны быстрый переключатель DND и кнопка истории последних уведомлений; история открывается внутри Dashboard, позволяет удалять отдельные записи и целые группы приложений (с подтверждением) и хранится только в оперативной памяти; количество записей ограничено настройкой (1–200, по умолчанию 30). Доступ к настройкам — кнопка общих настроек в правом верхнем углу. Dashboard можно открыть из Launcher командами `>dashboard`, `>overview` и `>обзор`, а также переключить через IPC:

```sh
qs -c <путь-к-конфигурации> ipc call dashboard toggle
```

### Требования

**Основные:** Quickshell с поддержкой Qt Quick/Wayland, Bash и `jq`. Для сетевых запросов и отдельных интеграций используются `curl`, `file`, Python 3 и стандартные Linux-утилиты.

Дополнительные возможности могут требовать:

| Возможность | Зависимости |
|---|---|
| CAVA | `cava` |
| Сеть | NetworkManager и `nmcli` |
| Громкость | `pactl` и/или `wpctl` |
| Player | D-Bus/MPRIS и поддерживаемый медиаплеер; `playerctl` используется некоторыми backend |
| Mopidy | Работающий Mopidy-сервер с HTTP JSON-RPC API |
| Clipboard | `cliphist`, `wl-copy` и Wayland-сессия |
| Pass | `pass`, `wl-copy` |
| Вкладка Windows в Launcher | Niri CLI (`niri`) |
| Запуск команд в терминале | `foot` и Zsh |
| Поиск пакетов Nix | Установленный Nix и доступ к `search.nixos.org` |
| Погода | API-токен Gismeteo, задаваемый в настройках |

Если необязательная утилита отсутствует, соответствующая интеграция может быть недоступна; остальные модули продолжают работать.

### Установка и запуск

Склонируйте репозиторий или распакуйте архив, затем запустите установщик из корня проекта:

```sh
./install.sh
```

Установщик копирует конфигурацию в `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/desktop-shell`, сохраняет существующие пользовательские данные и пытается импортировать совместимые старые настройки, если целевые файлы ещё не созданы.

Запуск:

```sh
quickshell -c "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/desktop-shell"
```

В некоторых сборках исполняемый файл называется `qs`; используйте его с тем же параметром `-c`. Для обновления повторно запустите `./install.sh`.

### Настройки и пользовательские данные

По умолчанию пользовательские данные хранятся отдельно от исходного кода:

| Данные | Расположение |
|---|---|
| Настройки | `${XDG_CONFIG_HOME:-~/.config}/quickshell-widgets/settings.json` |
| Профили | `profiles.json` рядом с `settings.json` |
| Секреты и токен погоды | `secrets.json` в каталоге конфигурации; файл создаётся с закрытыми правами |
| Заметки и метки календаря | `${XDG_DATA_HOME:-~/.local/share}/quickshell-widgets/` |

В разделе **Настройки → Общие → Хранилища** можно изменить расположение основных файлов настроек и данных календаря. Реестр путей, резервные копии, журналы транзакций и маркеры миграции являются локальными служебными файлами.

`settings.json` и `profiles.json` намеренно не исключены из Git: при желании их можно хранить в отдельном приватном репозитории или синхронизировать вручную. Перед добавлением проверьте содержимое и удалите локальные пути и другие персональные значения. `secrets.json`, заметки календаря, резервные копии и служебные sidecar-файлы исключены через `.gitignore`.

### Разработка и тесты

Запуск полного набора статических и fixture-based проверок:

```sh
bash CHECK.sh
```

Для тестов требуются `jq`, `curl`, `file`, Python 3, Node.js и `gawk`. Набор проверок не запускает полноценную графическую сессию Quickshell; после изменений QML дополнительно проверьте интерфейс в целевом окружении.

GitHub Actions запускает проверки при push и pull request, еженедельно и вручную через раздел **Actions**. Каждый новый `tests/*.sh` необходимо добавить в `CHECK.sh`.

Основные каталоги: `components/` — QML-виджеты и примитивы; `js/` — модели и логика; `scripts/` — Bash-интеграции; `services/` — сервисы Quickshell; `tests/` — регрессионные проверки.

### Лицензия

MIT — см. [`LICENSE`](LICENSE).

## English

`quickshell-widgets` is a modular desktop widget collection and built-in launcher for Quickshell on Linux/Wayland.

### Features

- **Desktop widgets:** clock with independent typography controls for time, date, and weekday, CPU/RAM and Top Apps, network traffic and connections, audio volume and streams, CAVA, calendar notes and marks, current weather and forecasts, timers and alarms, Player, Mopidy, and desktop notifications.
- **Dashboard:** configurable Today, System, Network, Weather, and Media cards with independent visibility, ordering, sizing, responsive columns, and an in-panel editing mode.
- **Launcher:** applications, Run, windows, clipboard, power, network, packages, Pass, projects, and calculator, plus custom actions and multi-source search. Built-in navigation entries can be independently hidden from the `>` palette. Saved custom actions use the separate `:` prefix (bare `:` lists all complete records), and the palette stays dedicated to built-in navigation.
- **Settings:** grouped navigation, searchable controls, draggable page ordering, reusable controls, and module-specific pages.
- **Profiles and themes:** named profiles, scoped Save/Reset, built-in palettes, and custom color themes.
- **Motion:** per-module animation styles, easing profiles, and durations.
- **Drag and drop:** shared reordering for Settings, Launcher, Dashboard, Player, Timer, and Mopidy queues/playlists.

### Launcher search and navigation

- The built-in command palette uses the `>` prefix. Dashboard can be opened with `>dashboard`, `>overview`, or `>обзор`. Saved custom actions use the separate `:` prefix and remain independent from built-in navigation.
- Fuzzy search for saved custom actions, color schemes, and wallpapers has independent settings in **Settings → Launcher → Search**. The action-search switch controls saved custom actions; the **Schemes setting** and **Wallpapers setting** independently control matching for color schemes and wallpapers.
- Dynamic color schemes include `Fruit Salad` and `Tonal Spot`. Use `>scheme variants` to open the variant picker; `>variant` is a shorter alias.
- Optional Vim-style navigation is disabled by default. When enabled, `Ctrl+J`/`Ctrl+N` move down and `Ctrl+K`/`Ctrl+P` move up.
- The keyboard navigation hints panel is visible by default and can be hidden independently from Vim-style navigation.

### Dashboard

Dashboard cards are informational and passive: clicking a card surface does not open another view. Open Dashboard settings with the shared Settings control in the upper-right corner. The Dashboard can also be toggled through Quickshell IPC:

```sh
qs -c <path-to-configuration> ipc call dashboard toggle
```

### Requirements

Quickshell with Qt Quick/Wayland support, Bash, and `jq` are required. Optional integrations may need `cava`, NetworkManager/`nmcli`, `pactl` or `wpctl`, MPRIS-compatible players, Mopidy, `cliphist`, `wl-copy`, `pass`, Niri, Zsh, `foot`, or Nix. Weather uses a Gismeteo API token configured in Settings.

### Install and update

Run the installer from the project directory:

```sh
./install.sh
```

It installs the shell configuration into `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/desktop-shell` and preserves existing user data. Start it with:

```sh
quickshell -c "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/desktop-shell"
```

Use `qs` instead of `quickshell` if that is the executable provided by your distribution. Run the installer again to update the installed files.

### Settings and user data

Settings and profiles are stored under `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell-widgets/`; calendar data defaults to `${XDG_DATA_HOME:-$HOME/.local/share}/quickshell-widgets/`. The weather token is kept in a separate local `secrets.json` file. Storage locations can be changed in **Settings → General → Storage**.

`settings.json` and `profiles.json` are intentionally trackable for users who explicitly want to sync configuration. Review them before committing. Secrets, calendar data, migration markers, temporary files, locks, and recovery backups are ignored by `.gitignore`.

### Development and tests

Run the static and fixture-based regression suite from the repository root:

```sh
bash CHECK.sh
```

Test dependencies: `jq`, `curl`, `file`, Python 3, Node.js, and `gawk`. The suite does not launch a graphical Quickshell session, so visually verify QML changes in the target environment. Add every new `tests/*.sh` script to `CHECK.sh`.

### License

MIT — see [`LICENSE`](LICENSE).

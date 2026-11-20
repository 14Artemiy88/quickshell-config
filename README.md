# quickshell-widgets

Configurable desktop widgets and a keyboard-driven launcher for **Quickshell** on Linux/Wayland. The project is written in QML/Qt Quick with Bash and JavaScript helpers. Settings, profiles, themes, and calendar notes are managed through the built-in UI; user data is stored outside the source tree.


## Русский

`quickshell-widgets` — набор виджетов рабочего стола и встроенный лаунчер для Quickshell. Проект рассчитан на Linux/Wayland; отдельные функции зависят от установленного рабочего стола и внешних утилит.

### Возможности

- Часы и настраиваемое расположение модулей.
- Мониторинг CPU/RAM, графики CPU, Top Apps и CAVA; CAVA обновляет общую модель полос по изменившимся значениям, чтобы не инвалидировать все делегаты на каждом аудиокадре; для него настраиваются профиль и длительность появления/скрытия графика при тишине.
- Player с поддержкой доступных MPRIS-плееров, MPV, DeaDBeeF, Spotify и браузерной интеграции; отдельная вкладка анимации управляет внутренними переходами, длительностью и профилем кривой.
- Mopidy: управление воспроизведением, очередь, библиотека, плейлисты, поиск файлов и обложки; отдельная вкладка анимации управляет внутренними переходами, длительностью и профилем кривой.
- Таймеры и будильники, пресеты, комментарии и окно завершения; профиль внутренних переходов, длительности строк, а также отдельные стиль и длительности кнопок и иконок настраиваются независимо.
- Календарь с заметками, отметками дат, навигацией по соседним месяцам и настройками анимации.
- Текущая погода, почасовой и дневной прогнозы через Gismeteo API; отдельная вкладка анимации управляет морф-переходами и плавной прокруткой почасового прогноза.
- Громкость основного выхода и аудиопотоков, состояние сети и активные подключения.
- Встроенный лаунчер: Apps, Run, Windows, Clipboard, Power, Network, Packages, Pass, Projects и Calculator; запуск по Enter, сохранённые команды и проекты. В палитре `>` доступен офлайн-каталог из 153 часто используемых эмодзи: `>emoji`, `>emoji smile` или `>emoji сердце`; `>emoji favorites` открывает только избранное, а `>emoji recent` — последние 12 использованных не избранных символов. Эти режимы понимают русские алиасы `избранное` и `недавние`; после имени режима можно добавить поисковое слово. Выбор копирует символ в буфер обмена. Эмодзи можно добавлять в избранное нажатием на звезду справа в строке или `Ctrl+Shift+F`; последние 12 использованных (не избранных) символов поднимаются к началу полного каталога, а счётчик использования сохраняется. Apps читает живую модель `DesktopEntries.applications.values`, поэтому список обновляется при изменении системного каталога. Для Apps можно закреплять избранные приложения и скрывать ненужные из обычной и метадатной выдачи; списки настраиваются в **Настройки → Лаунчер → Приложения** и сохраняются вместе с профилем. В настройке видимости вкладок скрытую вкладку можно снова включить, даже когда она осталась единственной скрытой.
- Опциональная Vim-навигация в Launcher: `Ctrl+J`/`Ctrl+N` перемещают выбор вниз, `Ctrl+K`/`Ctrl+P` — вверх. По умолчанию выключена; обычный ввод `j/k/n/p`, стрелки и существующее переключение вкладок через `Tab` не меняются. Панель подсказок навигации внизу Launcher отдельно управляется переключателем «Отображать панель подсказок» и отображается по умолчанию; её высота (0–48 px, по умолчанию 24), размер шрифта (8–18 px, по умолчанию 11) и вертикальное смещение текста Y (−48…48 px, по умолчанию 0) настраиваются в «Настройки → Лаунчер → Общее → Навигация → Панель подсказок». Переключатель видимости и параметры панели находятся в одной рамке «Панель подсказок»; при отключении плавно сворачиваются только параметры, а рамка и переключатель остаются видимыми.
- Сквозной поиск из Apps по установленным приложениям, проектам, сохранённым командам, пользовательским действиям и арифметическим выражениям; пользовательское действие ищется по названию, описанию и команде. Префикс `>` открывает каталог встроенных действий и позволяет перейти к вкладкам по запросу (`>wifi`, `>power`, `>calc`, `>projects`); пользовательские команды вынесены отдельно под префикс `:`. Сохранённые пользовательские команды запускаются отдельно через `:`. Встроенные действия показывают назначение раздела и находятся по русским и английским синонимам, например `>wireless`, `>менеджер паролей`, `>репозитории` и `>вычислить`. Каждый из 15 встроенных пунктов (10 переходов и 5 инструментов) можно независимо отключить в **Настройки → Лаунчер → Действия → Переходы** и **Инструменты**; это скрывает команду и её подкоманды из поиска `>`; сами вкладки остаются в панели вкладок, а настройки и данные инструментов сохраняются. Каталог `:` и обычный поиск Apps не меняются. Для включённого пользовательского действия обязательны название и команда, а краткое описание необязательно. Новая запись создаётся с пустыми полями: placeholders поясняют, что вводить («Название действия (обязательно)», «Краткое описание (необязательно)», «Команда для запуска (обязательно)»). При сохранении любого поля действия проверяются оба обязательных поля; незаполненное поле выделяется мягкой красной рамкой в тон кнопок удаления, а сохранение блокируется до исправления. Список учитывает скрытые вкладки. Калькулятор поддерживает скобки, унарные знаки, +, −, ×, ÷, остаток и степень.
- Общая система настроек, тем, цветов, профилей и рамочных групп; общий примитив `SettingsAnimationGroup.qml` предоставляет выбор профиля внутренних переходов (включая «Без анимации»), длительность и плавное раскрытие дополнительных параметров; модули могут добавлять к нему собственные поля; стабильные ID и метаданные страниц собраны в `SettingsPageRegistry.js`, отдельно от QML-разметки. Общий хост прокрутки, заголовка, подразделов и действий страницы вынесен в `SettingsPageHost.qml`, а декларативная сборка страниц — в `SettingsPageContent.qml`; составные страницы Player и Mopidy дополнительно выделены в `pages/SettingsPlayerPage.qml` и `pages/SettingsMopidyPage.qml`. Навигация вынесена в `SettingsNavigationController.qml`: он владеет текущим ID страницы, порядком и названиями вкладок, подразделами, маркерами изменений и сбросом страницы; `SettingsWidget` сохраняет стабильный внешний API через aliases и делегирующие методы. Компоненты страниц получают контроллер навигации и хранилище через явные свойства. Навигация, поиск, области сохранения и сбросы используют ID страниц, а не числовые индексы; числовая позиция остаётся только у подразделов внутри страницы. Глобальный поиск вынесен в `SettingsSearchController.qml`: он индексирует параметры по подписям, разделам и ключам, открывает нужную вкладку и прокручивает к настройке с подсветкой; `SettingsWidget` передаёт ему дерево страниц и визуальные элементы поиска. Развёрнутый список тем показывает палитры до выбора, а настройки виджетов редактируются через UI.
- Собственная система уведомлений на базе Quickshell: всплывающие карточки, уровни важности, прогресс-полосы по подсказке `int:value`, форматирование и ссылки, иконки и изображения из image-path/image-data, автоматическое скрытие и действия. Для появления и исчезновения карточек доступны «Нет», затухание и сдвиги с четырёх направлений; общие профили кривых и длительность настраиваются независимо от перестройки очереди. Прозрачная поверхность уведомлений остаётся подключённой к слою и уменьшается до 1×1 в простое, чтобы анимация оконного композитора не добавляла нежелательный fade. На первом этапе она заменяет Dunst; перед запуском нужно остановить Dunst, чтобы Quickshell мог занять D-Bus имя `org.freedesktop.Notifications`.

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

- Общие настройки: `${XDG_CONFIG_HOME:-~/.config}/quickshell-widgets/settings.json`; профили: `profiles.json` (по умолчанию рядом с настройками).
- Локальный токен погоды хранится отдельно в `${XDG_CONFIG_HOME:-~/.config}/quickshell-widgets/secrets.json` с правами `600`; файл секретов и его резервные копии не предназначены для GitHub.
- Заметки календаря: `${XDG_DATA_HOME:-~/.local/share}/quickshell-widgets/calendar-notes.json`.
- Локальные проекты лаунчера редактируются в **Настройки → Лаунчер → Проекты**.
- Публичная версия намеренно начинается с пустого списка проектов: пути к репозиториям и IDE зависят от конкретной машины. Добавьте свои записи через настройки; существующий пользовательский список в отдельном `settings.json` сохраняется.
- Пользовательские действия Launcher входят в профиль как единый список: список в `profileOverrides` полностью заменяет список базового профиля. Поэтому удалённая из текущих настроек запись может остаться в базовом профиле и восстановиться после сброса Launcher; чтобы закрепить текущее состояние и убрать старые записи из базы, сохраните настройки Launcher в активный профиль значком сохранения в разделе «Модули → Лаунчер». Новые настройки входят в общую систему профилей. Токен погоды не входит в профили и не сохраняется в `settings.json` или его резервной копии; старый токен автоматически переносится в `secrets.json` при первом чтении настроек.
- Последний корректный снимок настроек хранится в приватной резервной копии `.settings.json.bak`. Если `settings.json` повреждён, исходный файл сохраняется как `.settings.json.corrupt.*`, а настройки восстанавливаются из резервной копии; если её нет, создаются значения по умолчанию. Намеренное удаление самого `settings.json` по-прежнему сбрасывает настройки и не восстанавливает старую копию автоматически.
- В **Настройки → Общие → Хранилища** можно менять расположение только `settings.json`, `calendar-notes.json` и `calendar-marks.json`. Укажи абсолютный путь с исходным именем файла; перенос проверяет JSON, не перезаписывает существующее назначение и оставляет прежнюю копию с суффиксом `.qsw-backup-*`. При переносе `settings.json` его `.settings.json.bak` перемещается рядом. Реестр выбранных путей хранится в приватном `.storage-paths.conf` внутри канонического каталога конфигурации; после переноса рекомендуется перезапустить Quickshell.

Для переноса через GitHub можно в **Настройки → Общие → Хранилища** указать пути к `settings.json` и `profiles.json` внутри рабочего клона репозитория, затем добавить эти два файла в Git после проверки их содержимого. `secrets.json` остаётся в локальном каталоге конфигурации и исключён из Git. Не добавляйте резервные/повреждённые копии, токены, заметки календаря или другие приватные данные. Если секрет уже попадал в Git, удалите его из индекса и при необходимости очистите историю.

### Лаунчер и кейбинды Niri

«Лаунчер» — отдельная сворачиваемая папка навигации перед «Окно настроек». Внутри находятся страницы «Общее», «Поиск», «Вкладки», «Проекты», «Действия», «Анимация» и «Приложения»; крупные рамочные группы распределены по смысловым подвкладкам внутри страниц «Общее», «Поиск» и «Действия». На странице «Вкладки» можно редактировать названия и Nerd Font-иконки вкладок, менять их порядок и видимость. Также из UI настраиваются стартовая вкладка, размеры, скругление окна и элементов списка, прозрачность фона, текст и оформление заголовка, а также шрифт, размер, высота, скругление и фон строки поиска. Поисковый запрос сохраняется при переключении вкладок и очищается при закрытии лаунчера. Во вкладке Power строка поиска скрыта, поскольку список действий фиксированный. Текст, акцент и рамки лаунчера берутся из общей темы; собственный цвет фона окна настраивается отдельно в «Настройки → Лаунчер → Общее → Оформление». Цвет фона окна настроек доступен в «Настройки → Окно настроек», а не в списке цветов темы.

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
Alt+0 { spawn "qs" "ipc" "call" "launcher" "openCalculator"; }
```

Если Quickshell запущен с нестандартным каталогом конфигурации через `-c`, указывайте этот же путь в аргументах `qs` у кейбиндов, иначе IPC может обратиться к экземпляру конфигурации по умолчанию. Пример: `spawn "qs" "-c" "/absolute/path/to/desktop-shell" "ipc" "call" "launcher" "toggle"`. Примеры выше не меняют Niri config автоматически.

Внутри лаунчера доступны переключение вкладок клавиатурой, независимые настройки нечёткого поиска приложений, пользовательских действий, цветовых схем и обоев (Настройки → Лаунчер → Поиск; все включены по умолчанию; при выключении каждого режима остаются точные, начальные и непрерывные совпадения), тематическая подсветка совпадений и управление списком проектов. Поиск Launcher также автоматически пробует альтернативную раскладку QWERTY/ЙЦУКЕН: например, `щквукы` найдёт `orders`, а `ghbdtn` — `привет`; смешанные языковые запросы и короткие вводы не преобразуются, системная раскладка не меняется. В Apps можно уточнять поиск метаданных приложений префиксом `@`: `@i` — ID, `@c` — категории, `@d` — описание, `@e` — команда запуска из desktop-файла, `@w` — WM_CLASS/startup class, `@g` — общее имя, `@k` — ключевые слова, `@t` — только приложения, запускаемые внутри терминала (TUI/CLI-программы). После кода фильтра нужен пробел и поисковый текст, например `@c network` или `@k editor`; для `@t` текст ищется по названию приложения, а среди результатов остаются только записи с `Terminal=true`. Специальные фильтры ищут только приложения и не смешивают их с проектами, историей команд или калькулятором. Введя только `@c`, можно открыть список категорий приложений с количеством доступных приложений; выбор категории подставляет `@c <категория>` и показывает обычные результаты этого фильтра. Скрытые приложения не входят в категории и их счётчики. Вкладка Apps также может искать проекты, сохранённые команды из истории Run и результаты вычислений; включение каждого источника настраивается отдельно. В отдельной вкладке Calculator можно вводить арифметические выражения и копировать результат нажатием Enter или кликом. При пустом поле показываются последние 50 уникальных вычислений; выбор записи возвращает выражение в поле, а историю можно очистить отдельной командой. История хранится отдельно от профилей в `~/.cache/quickshell-launcher-calculator-history.json`. Выражение разбирается ограниченным арифметическим парсером, а не выполняется как код. Результаты поиска помечаются типом и имеют свою иконку. Запуск проекта передаёт путь и исполняемый файл IDE отдельными аргументами, без `eval`. Наведение на строку учитывается после реального движения курсора, поэтому перестроение списка не активирует случайно оказавшуюся под указателем строку. Префикс `>` открывает палитру встроенных действий с любой вкладки Launcher и переводит её в Apps; пользовательские действия вынесены в отдельный каталог по префиксу `:`. Встроенная команда `>emoji` открывает локальный каталог из 153 часто используемых эмодзи; добавьте поисковое слово (`>emoji smile` или `>emoji сердце`), чтобы отфильтровать символы. `>emoji favorites` (или `>emoji избранное`) показывает только избранное, а `>emoji recent` (или `>emoji недавние`) — 12 последних использованных не избранных символов; дополнительное слово после режима уточняет поиск. Enter или клик копирует выбранный эмодзи через существующий `wl-copy`; успешное копирование обновляет счётчик и недавний список. Избранное отмечается звездой справа в строке; клик по ней или `Ctrl+Shift+F` переключает закрепление. При открытии каталога избранное отображается первым, затем идут 12 последних использованных символов (кроме уже избранных), остальные сохраняют исходный порядок. Избранное и статистика хранятся отдельно от профилей в `~/.cache/quickshell-launcher-emoji-data.json`; загрузка объединяет ранние действия пользователя с данными на диске, а запись выполняется атомарно. Каталог работает офлайн и не требует дополнительной утилиты или сетевого запроса. Встроенная команда `>wallpaper` открывает плиточную сетку локальных изображений с предпросмотром; поиск после команды фильтрует файлы по имени. Стрелки влево/вправо/вверх/вниз перемещают выбор по сетке, Enter или клик устанавливает изображение на выбранный монитор. Над плитками доступны переключатели «Все», «Избранное» и «Недавние»; звезда в правом верхнем углу плитки добавляет изображение в избранное, а недавние обои хранятся отдельно для каждого монитора и записываются только после успешной установки. Команды `>wallpaper favorites` и `>wallpaper recent` открывают соответствующие списки; после них можно добавить поисковое слово. `>wallpaper random` (алиасы `>wallpaper shuffle`, `>обои случайно`) выбирает случайное подходящее изображение для выбранного монитора; повторный запуск старается не выбирать обои, которые последними были установлены на этом экране. Можно добавить поисковое слово, например `>wallpaper random forest`, чтобы ограничить случайный выбор совпадениями. Избранное и история устанавливаемых обоев сохраняются отдельно от профилей в `~/.cache/quickshell-launcher-wallpaper-data.json`; загрузка объединяет ранние действия пользователя с данными на диске, а запись выполняется атомарно. Над плитками показываются подключённые экраны; по умолчанию выбран экран, на котором открыт Launcher. В KDE используется Plasma Scripting API через `qdbus6`/`qdbus` для изменения desktop текущего экрана, в Niri/другом Wayland-сеансе — `swww img --outputs <имя-выхода>` (демон `swww-daemon` должен быть запущен). Команда `plasma-apply-wallpaperimage` не используется, поскольку она меняет обои на всех экранах. В каталог предпросмотра попадают только абсолютные пути к читаемым файлам поддерживаемых форматов; пустые пути, каталоги и неподдерживаемые файлы отбрасываются до создания QML Image. Каталог по умолчанию — `~/Pictures/Wallpapers`; изменить его можно в **Настройки → Лаунчер → Поиск → Обои → Обои рабочего стола**. Путь и список обоев не копируются в профили как отдельные файлы, в профиль сохраняется только настройка каталога. Если пер-мониторный backend не найден или экран отключён, Launcher оставляет сетку открытой и показывает ошибку; автоматического переключения на все экраны нет. В палитре `>` команда `>scheme` открывает список встроенных и пользовательских цветовых тем с шестью основными цветами в виде компактных цветных точек; после команды можно добавить поисковое слово (`>scheme nord`). Текущая тема отмечена и показывается первой без поискового запроса. Выбор применяет тему через общий `Settings.applyTheme()` и сохраняет её тем же механизмом, что и страница Colors; повторный выбор уже активной темы не сбрасывает изменённые пользователем цвета. Команда `>scheme variants` (прежний короткий псевдоним `>variant` также поддерживается) открывает восемь алгоритмов Material You (Content, Expressive, Fidelity, Fruit Salad, Monochrome, Neutral, Rainbow и Tonal Spot); поиск поддерживает названия и русские псевдонимы. Выбор алгоритма пересоздаёт `Wallpaper Dynamic` из последних обоев, установленных через Wallpaper Picker на выбранном мониторе (выбор экрана доступен прямо над списком вариантов); текущий вариант хранится в активном профиле, а при следующей команде `>scheme dynamic` используется автоматически. Пункт `Wallpaper Dynamic` или команда `>scheme dynamic` создаёт тёмную цветовую палитру из последних обоев, установленных через Wallpaper Picker на выбранном мониторе; источник можно сменить переключателем монитора над результатами. Команда использует необязательную внешнюю утилиту `matugen` (она не устанавливается автоматически). Для генерации применяется временный изолированный конфиг Matugen: `wallpaper.set = false`, выключен файловый кэш, самый доминирующий исходный цвет выбирается автоматически (`source_color_index = 0`), пользовательские шаблоны не запускаются. Обои, шаблоны и конфиг Matugen не меняются; в Quickshell передаётся только JSON-палитра. Сгенерированная палитра сохраняется как пользовательская тема `Wallpaper Dynamic`, доступная также в Settings → Colors; пользовательские независимые цвета фона настроек, прогресса плеера и полос Top Apps сохраняются. Если Matugen не установлен или для выбранного монитора нет истории установленных через picker обоев, Launcher покажет объяснение и предложит открыть Wallpaper Picker. Именованные пользовательские действия участвуют в обычном поиске Apps без префикса, а отдельный префикс `:` открывает их каталог с любой вкладки Launcher: один `:` показывает все включённые и полностью заполненные действия, `:terminal` фильтрует их по названию, описанию или команде. Они больше не смешиваются со встроенной палитрой `>`, которая отвечает за навигацию по разделам и встроенные инструменты. Нечёткое сопоставление для действий настраивается независимо от приложений; выключение сохраняет точные, начальные и непрерывные совпадения и в Apps, и в каталоге `:`. Пользовательские действия настраиваются в «Настройки → Лаунчер → Действия» (иконка, обязательные название и команда Zsh, необязательное краткое описание, включение и порядок); новые поля изначально пустые и используют placeholders с пояснениями. Пользовательская команда исполняется только после выбора сохранённой записи; введённый поисковый текст напрямую не запускается. Добавляйте только команды, которым доверяете.

В настройках темы можно включить «Развернуть», чтобы увидеть список тем вместе с цветовыми образцами. В компактном режиме остаётся прежний выбор темы и связанная с ним логика изменений (`Changed`).

### Разработка и тесты

Запуск полного набора статических и fixture-based проверок из корня проекта:

```sh
bash CHECK.sh
```

Для тестов требуются `jq`, `curl`, `file`, Python 3 и Node.js; тесты не запускают полноценную графическую сессию Quickshell, поэтому после изменений QML дополнительно проверьте соответствующий виджет в целевом окружении. Некоторые проверки используют контролируемые Linux-процессы и `/proc`.

GitHub Actions запускает `CHECK.sh` при `push` и `pull_request`, по расписанию раз в неделю и вручную через **Actions → Checks → Run workflow**. При сбое workflow прикладывает `check.log` к запуску на 7 дней. Тест `test_ci_test_coverage.sh` проверяет, что каждый `tests/*.sh` включён в `CHECK.sh`; новые тестовые файлы нужно добавлять в основной список.

Основные каталоги:

- `components/` — виджеты, лаунчер и повторно используемые QML-примитивы.
- `components/settings/` — интерфейс настроек и секции модулей; `primitives/SettingsAnimationGroup.qml` предоставляет общий блок управления внутренними анимациями модулей; `SettingsPageHost.qml` отвечает за общую рамку и прокрутку, `SettingsPageContent.qml` собирает страницы, `pages/` содержит составные страницы Player и Mopidy, `SettingsNavigationController.qml` владеет маршрутизацией и состоянием вкладок, `SettingsSearchController.qml` — глобальным поиском и переходами, а `SettingsProfileController.qml` — действиями профилей.
- `js/cava/GraphValuesModel.js` — общая модель аудиополос CAVA с выборочным обновлением изменившихся строк. `js/settings/` — значения по умолчанию, схема, реестр страниц настроек, поиск, сохранение, профили и применение настроек. Реестр `SettingsPageRegistry.js` хранит стабильные ID страниц, подписи, подразделы и области сохранения отдельно от QML-разметки; `SettingsNavigationController.qml` владеет ID текущей страницы и логикой порядка/названий вкладок, подразделами и индикаторами изменений; `SettingsWidget.qml` остаётся корневым координатором и предоставляет стабильный API дочерним компонентам. `SettingsPageHost.qml` отвечает за общий контейнер, прокрутку, заголовок, подразделы и действия с профилями; объявления секций и сборка страниц находятся в `SettingsPageContent.qml`, а `SettingsWidget` передаёт ему состояние навигации и настроек.
- `scripts/` — Bash-сценарии для мониторинга, плеера, Mopidy, таймеров, погоды и аудио.
- `services/` — сервисы Quickshell для часов, системного мониторинга и погоды.
- `tests/` — регрессионные тесты.

### Лицензия

MIT. См. [`LICENSE`](LICENSE).

## English

`quickshell-widgets` is a configurable set of Linux/Wayland desktop widgets and an integrated launcher for Quickshell, implemented with QML/Qt Quick, Bash, and JavaScript helpers.

### Features

- Clock and configurable widget layout.
- CPU/RAM monitoring, CPU graphs, Top Apps, and CAVA.
- Media Player supporting available MPRIS players, MPV, DeaDBeeF, Spotify, and browser integration; a dedicated animation subtab controls internal transitions, duration, and motion-curve profile.
- Mopidy playback controls, queue, library, playlists, file browsing, and cover art; a dedicated animation subtab controls internal transitions, duration, and motion-curve profile.
- Timers and alarms, presets, comments, and finish window; the internal-transition profile and row duration are configured independently from preset-button style/durations and icon morph duration.
- Calendar notes, date markers, adjacent-month navigation, and animation options.
- Current weather plus hourly and daily forecasts via the Gismeteo API; a dedicated animation subtab controls morph transitions and smooth hourly forecast scrolling.
- Output/stream volume, network statistics, and active connections.
- Optional Vim-style Launcher navigation: `Ctrl+J`/`Ctrl+N` move the selection down, while `Ctrl+K`/`Ctrl+P` move it up. It is disabled by default; ordinary `j/k/n/p` input, arrow keys, and existing `Tab` tab switching remain unchanged. The separate navigation hint panel is shown by default and can be hidden with **Show navigation hints** in Launcher settings. Its height (0–48 px, default 24), text size (8–18 px, default 11), and vertical text offset Y (−48 to 48 px, default 0) are configurable under **Settings → Launcher → General → Navigation → Navigation hints**. The visibility checkbox and panel controls share one **Navigation hints** frame; when the footer is disabled, only the controls smoothly collapse while the frame and checkbox remain visible.
- Integrated launcher tabs: Apps, Run, Windows, Clipboard, Power, Network, Packages, Pass, Projects, and Calculator, including keyboard activation, saved commands, and project launching.
- The `>` action palette includes a color-scheme browser (`>scheme`) for built-in and user-created themes. Theme rows reuse the six main colors from Settings → Colors, rendered as six small circular color swatches beside the theme name; the active theme is marked and sorted first for an empty query. Search accepts a term such as `>scheme nord`. Selecting a different theme calls the existing Settings theme manager and saves through the existing settings persistence path; selecting the already active theme does not reset modified colors. A `Wallpaper Dynamic` action (or `>scheme dynamic`) creates a dark palette from the most recently applied wallpaper on the selected monitor; the monitor selector above the results chooses the source output. This uses the optional external `matugen` utility, which is never installed automatically. The command runs with a temporary isolated Matugen config (`wallpaper.set = false`, caching and version checks disabled, dominant source color selected automatically with `source_color_index = 0`, and no user templates), so it does not change wallpapers, write Matugen's cache, or run configured Matugen templates; only the generated JSON palette is applied to Quickshell. The generated palette is saved as the user theme `Wallpaper Dynamic` and also appears in Settings → Colors. Independent user colors for the settings background, player progress, and Top Apps bars are preserved. If Matugen is missing or the selected output has no wallpaper history recorded by Wallpaper Picker, the launcher explains the issue and offers to open the wallpaper picker.
- The `>` action palette includes a local wallpaper tile grid (`>wallpaper`) with image previews and filename search. Arrow keys navigate in all four directions. The toolbar offers All, Favorites, and Recent views; the star in a tile's upper-right corner toggles favorites. Recent wallpaper usage is tracked separately per monitor and recorded only after a successful apply. `>wallpaper favorites` and `>wallpaper recent` open scoped lists and accept an additional search term. `>wallpaper random` (also `>wallpaper shuffle` or `>обои случайно`) chooses a random matching image for the selected monitor; it avoids immediately repeating the most recently applied image on that display when alternatives exist. Add a search term after the random mode (for example, `>wallpaper random forest`) to limit the candidate set. Favorites and recent usage are stored outside profiles in `~/.cache/quickshell-launcher-wallpaper-data.json`, with early mutations merged after async loading and atomic serialized writes. A monitor selector above the grid targets one connected display at a time; it defaults to the screen hosting the Launcher. Enter or click applies only to that display: KDE Plasma uses its desktop scripting API through `qdbus6`/`qdbus`, while Niri/other Wayland sessions use `swww img --outputs <output-name>` (the `swww-daemon` must already be running). The all-screen `plasma-apply-wallpaperimage` helper is intentionally not used. Only absolute paths to readable supported image files enter the preview model; empty paths, directories, and unsupported files are rejected before creating a QML Image. The default folder is `~/Pictures/Wallpapers`; it can be changed under **Settings → Launcher → Search → Wallpapers → Desktop wallpapers**. If no per-monitor backend is available or the selected screen is disconnected, the launcher reports an error instead of applying to every screen.
- Apps cross-search across installed applications, configured projects, saved Run commands, named custom actions, and arithmetic expressions, with configurable source toggles and per-result icons. The `>` action palette also includes an offline emoji picker (`>emoji`, `>emoji smile`, `>emoji heart` or `>emoji сердце`) with 153 commonly used entries. `>emoji favorites` (also `>emoji избранное`) filters to favourites; `>emoji recent` (also `>emoji недавние`) shows the 12 most recently copied non-favourites. A search term can follow either scope. Selecting an emoji copies it with the existing `wl-copy` integration. Emoji can be pinned with the trailing star or `Ctrl+Shift+F`; the 12 most recently copied non-favourites are promoted near the top and usage counts are tracked. Successful copies update the recent-use data. The unfiltered picker shows favourites first, then the 12 most recently copied non-favourites, followed by the rest of the catalog. Favourites and usage are stored separately from profiles in `~/.cache/quickshell-launcher-emoji-data.json`; early changes are merged with the asynchronous initial load, and writes use an atomic file replacement. Custom actions match by name, description, or command. Enabled actions require a name and Zsh command; every field commit validates both required values; missing fields receive a soft red outline matching the delete controls, and saving is blocked until they are filled. The description is optional. The separate Calculator tab supports parentheses, unary signs, +, −, ×, ÷, modulo, and exponentiation. When its search field is empty, it shows the latest 50 unique calculations; selecting an entry restores its expression, and history can be cleared explicitly. History is stored separately from profiles in `~/.cache/quickshell-launcher-calculator-history.json`.
- Shared settings, themes, color palette, profiles, and reusable framed settings groups; `SettingsAnimationGroup.qml` provides the common internal-transition profile (including “No animation”), duration, and animated expansion of additional settings, with slots for module-specific options; a stable-ID page registry backs navigation and search, while `SettingsPageHost.qml` owns the shared page scroll area, heading, subtabs, and profile actions; `SettingsPageContent.qml` owns the declarative assembly of page sections, while composite Player and Mopidy pages live in dedicated files under `components/settings/pages/`. Global settings search is owned by `SettingsSearchController.qml`: it matches labels, sections, and setting keys, then opens the correct page and highlights the target control. An expanded theme palette previews each theme before selection.
- Native Quickshell notification cards with urgency styling, progress bars from the `int:value` hint, rich text and hyperlinks, application icons, timeouts, queue scrolling, and action buttons.

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

- Shared settings: `${XDG_CONFIG_HOME:-~/.config}/quickshell-widgets/settings.json`; profiles: `profiles.json` (next to settings by default).
- The machine-local weather key is stored separately in `${XDG_CONFIG_HOME:-~/.config}/quickshell-widgets/secrets.json` with mode `600`; the secrets file and its backups are not for GitHub.
- Calendar notes: `${XDG_DATA_HOME:-~/.local/share}/quickshell-widgets/calendar-notes.json`.
- Launcher project entries are edited in **Settings → Launcher → Projects**.
- The public source starts with an empty Projects catalogue intentionally: repository and IDE paths are machine-specific. Add your entries in Settings. An existing user catalogue stored in the external settings file is preserved.
- Settings participate in the shared profile system. The weather token is excluded from profiles and is never written to `settings.json` or its backup; the legacy token is moved to `secrets.json` on the first settings read.
- The latest known-good settings snapshot is kept in the private `.settings.json.bak` file. If `settings.json` is malformed, the original bytes are preserved as `.settings.json.corrupt.*` and settings recover from the backup; if no valid backup exists, defaults are initialized. Intentionally deleting `settings.json` still resets settings rather than automatically resurrecting an old backup.

To transfer settings through GitHub, use **Settings → General → Storage** to point `settings.json` and `profiles.json` into your working repository clone, then review their contents before adding them to Git. `secrets.json` remains in the local config directory and is ignored by Git. Never commit backups/corrupt copies, API keys, calendar notes, or other private data. If a secret was already committed, remove it from the index and consider cleaning Git history as well.

### Niri keybindings

Launcher is a collapsible navigation folder placed immediately before Settings Window. It contains the General, Search, Tabs, Projects, Actions, Animation, and Applications pages. Large framed groups are organized into meaning-based subtabs on General, Search, and Actions. Its startup tab, visible tabs, tab order, geometry, window and list-item rounding, backdrop opacity, and project catalogue are configurable. The search query is preserved across tab switches and cleared when the launcher closes. The launcher title has configurable color and vertical offset; other text, accent, and borders use the active shared theme; the launcher window background has its own setting under Settings → Launcher → General → Appearance. The settings-window background is configured under Settings → Settings Window rather than in the theme color editor.

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
Alt+0 { spawn "qs" "ipc" "call" "launcher" "openCalculator"; }
```

If Quickshell is launched with a non-default configuration directory (`-c`), pass that same directory to the `qs` IPC command in the binding. The examples do not edit your Niri configuration automatically.

Fuzzy matching for Apps, saved custom actions, color schemes, and wallpapers can be configured independently under **Settings → Launcher → Search** (all four are enabled by default). Launcher search also tries the alternate US QWERTY/Russian ЙЦУКЕН key layout automatically (for example, `щквукы` can find `orders`, and `ghbdtn` can find `привет`). Mixed-language and short queries are left unchanged, and the system keyboard layout is never switched. When a mode is disabled, exact, prefix, and contiguous substring matches remain available, while gapped subsequence matches are removed. The Apps setting also applies to `@` metadata searches; the Actions setting applies to ordinary Apps search and the separate `:` saved-action catalog; the Schemes setting covers named and wallpaper-derived themes; the Wallpapers setting covers All, Favorites, and Recent wallpaper views. The Apps tab supports metadata-specific application search with the `@` prefix: `@i` searches desktop-entry IDs, `@c` categories, `@d` descriptions/comments, `@e` the desktop entry launch string, `@w` startup WM class, `@g` generic name, `@k` keywords, and `@t` only applications marked to run in a terminal. Type a space and a query after the selector, for example `@c network` or `@k editor`; `@t` searches by application name but filters results to entries with `Terminal=true` (apps intended to run inside a terminal, not terminal emulators). These special searches return application results only and do not mix in projects, Run history, or calculator results. Typing only `@c` opens a browser of installed-app categories with visible application counts; selecting one fills `@c <category>` and runs the existing metadata filter. Hidden apps are excluded from both category lists and counts. Under **Settings → Launcher → Applications**, the list intentionally stays compact while its search field is empty: only apps already marked as favorites or hidden are shown. Search installed apps by name or metadata to add them to favorites (shown first in the empty Apps list) or hide them from ordinary and metadata-filter search; an app cannot be both at once. These preferences are saved in the active profile. The Apps tab can also search configured projects, saved Run commands, named custom actions, and valid arithmetic expressions. Each cross-search source can be toggled in launcher settings; results are labelled by type and display a corresponding icon. Prefixing a query with `>` switches the launcher to Apps and opens its action palette from any tab. Built-in actions show a short purpose description and match English and Russian aliases such as `>wireless`, `>password-store`, `>repositories`, and `>calculate`. Named custom actions remain available in ordinary Apps search without a prefix and can be found by name, description, or command. The dedicated `:` prefix opens only saved, enabled custom actions from any Launcher tab: bare `:` lists all complete records, while `:terminal` filters by name, description, or command. The `>` palette stays dedicated to built-in navigation and tools and no longer mixes in user commands. Each of the 10 tab shortcuts and 5 built-in tools can be independently hidden from the `>` palette in **Settings → Launcher → Actions → Tab transitions** and **Tools**; this removes the command and its `>` subcommands; tabs remain in the normal tab strip, while tool settings and data are retained. The `:` catalog and ordinary Apps search are unaffected. The palette: built-in entries open visible launcher tabs (for example, `>wifi`, `>power`, `>calc`, or `>projects`), while custom actions are configured under **Settings → Launcher → Actions** with an icon, name, optional description, Zsh command, enabled state, and order. Enabled actions require both a name and a command; every field commit (icon, name, description, or command) validates both required values, outlines missing fields in the softer red used by delete controls, and blocks saving until they are filled. A custom command runs only after the matching saved entry is selected; raw search text is never executed. Add only commands you trust. Custom-action arrays in sparse settings overrides replace the active profile baseline; the baseline remains available for the Launcher reset action until the current Launcher settings are saved back to the active profile. The separate Calculator tab copies a valid result with Enter or a click and uses a restricted arithmetic parser rather than evaluating entered text as code. When the input is empty, it shows the latest 50 unique calculations; selecting an entry restores its expression, and history can be cleared explicitly. Calculator history is stored separately from profiles at `~/.cache/quickshell-launcher-calculator-history.json`. Hover selection is activated by actual pointer motion, not merely by a row moving under a stationary cursor. The Settings → Colors page has an optional expanded theme list with color previews; disable it to return to the compact selector.

### Development and tests

Run the static and fixture-based checks from the repository root:

```sh
bash CHECK.sh
```

Tests require `jq`, `curl`, `file`, Python 3, and Node.js. They do not launch a complete graphical Quickshell session, so visually verify affected QML widgets in the target environment. Some tests use Linux process and `/proc` fixtures.

GitHub Actions runs `CHECK.sh` on pushes and pull requests, weekly, and on demand from **Actions → Checks → Run workflow**. Failed runs upload `check.log` for 7 days. The `test_ci_test_coverage.sh` guard ensures each `tests/*.sh` script is wired into `CHECK.sh`; add every new test to the main suite.

Main directories: `components/` (widgets, launcher, shared QML primitives), `components/settings/` (settings UI, `SettingsPageHost.qml` for shared page chrome, and `SettingsPageContent.qml` for page assembly plus `pages/` for composite page components, and `SettingsSearchController.qml` for global search/index/navigation, and `SettingsProfileController.qml` for the profile UI model and action facade), `js/settings/` (schema, defaults, persistence and profiles), `scripts/` (shell helpers), `services/` (Quickshell services), `tests/` (regression tests).

### License

MIT; see [`LICENSE`](LICENSE).


### Custom notifications

The custom Quickshell notification cards render the notification image hint (`image-path`/`image-data`) as a separate bounded preview below the message, while keeping the small application icon independent. Raw filesystem paths are loaded directly and icon-theme names are checked before display so an unavailable image does not produce Quickshell’s black/magenta missing-texture tile or reserve empty preview space. They omit the summary row when a notification has an empty or whitespace-only summary. The body begins directly below the application/source label, and card height measurement excludes the empty summary. When a notification includes an integer `value` hint from 0 to 100 (for example, `notify-send -h int:value:65`), the card displays a compact accent-colored progress bar; notifications without a valid progress hint keep their previous layout. Notifications that request the server-default timeout (`expire_timeout = -1`, such as `notify-send -t -1`) use a configurable default (5 seconds initially) for low/normal urgency; critical notifications without an explicit positive timeout remain until manually dismissed. An explicit timeout of `0` always disables automatic expiry.

Notification preferences are available in **Settings → Уведомления**. The module controls normal and critical default timeouts, card position, width, screen margin, queue spacing, image-preview height, and visibility of application icons, body images, and progress bars. Preferences are profile-aware, saved to `settings.json`, and can be reset independently. The notification server itself remains active with the shell; this page configures presentation and timeout behavior rather than adding a second notification-server toggle.

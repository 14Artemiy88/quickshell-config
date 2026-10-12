# quickshell-widgets

**Версия проекта: v621** · Набор настольных виджетов и настроек для [Quickshell](https://quickshell.org/).

[English below](#english)

## О проекте

`quickshell-widgets` — самостоятельный набор QML-виджетов для рабочего стола Linux на Quickshell. Проект включает системные индикаторы, календарь, таймеры, погоду, управление медиаплеерами и настраиваемое окно параметров.

## Структура исходников

- `components/mopidy/` — основной модуль Mopidy и его QML-компоненты.
- `components/primitives/` — общие примитивы рамок, кнопок, интерактивных иконок, сегментных графиков и полос заполнения, используемые разными модулями.
- `components/settings/sections/mopidy/` — отдельные секции настроек Mopidy.
- `scripts/mopidy/` — скрипты Mopidy, включая интеграцию с медиаплеером.
- `tests/` — общие автопроверки проекта; тесты не перемещаются внутрь модулей.

## Возможности

- **Настраиваемая компоновка:** модули рабочего стола, положение и размеры окон, редактор раскладки и настройки внешнего вида.
- **CAVA:** верхние полоски, нижние полоски или обе половины; опциональное скрытие полосок при тишине. ЛКМ переключает воспроизведение активного плеера, ПКМ управляет отображением Mopidy.
- **Система:** время и дата, загрузка CPU, Top Apps с компактными списками групп одноимённых процессов, суммированием CPU/RSS и привязкой вспомогательных процессов Zen/Firefox по дереву PPID, настраиваемыми заголовками, полосами, шрифтом, межстрочным интервалом и верхним отступом, график CPU с режимами полосок «Обе половины», «Только верхние» и «Только нижние», память, громкость и сетевые показатели. Полоски CPU/RAM поддерживают четыре направления: слева направо, справа налево, сверху вниз и снизу вверх; вертикальные режимы отображают ядра CPU и RAM отдельными вертикальными индикаторами.
- **Погода:** текущие условия, почасовой и дневной прогноз; отображение комфортной температуры можно отключить отдельно. Для комфортной температуры предусмотрен контур для лучшей читаемости.
- **Календарь:** заметки для отдельных дат. ПКМ открывает редактор, ЛКМ показывает сохранённую заметку. Даты с заметками отмечаются выбранным индикатором: точкой, полоской, кольцом, значком или рамкой. Для меток доступны настройки цвета и положения.
- **Таймеры:** управление таймерами и настраиваемое окно завершения таймера.
- **Медиаплеер:** интеграция с несколькими бэкендами, информация о текущем треке и обложка альбома. Кнопка **Next** показывается только для DeaDBeeF, Mopidy и Spotify.
- **Mopidy:** очередь и плейлисты, перестановка элементов, добавление файлов из пустого плейлиста, настройка отображения исполнителя и названия трека в две строки или в одну через редактируемый разделитель, единая регулируемая высота строк треков, папок и плейлистов, переключаемое выравнивание общего времени очереди слева/справа, папки отображаются обычным начертанием независимо от жирности альбомов, жирное/курсивное начертание исполнителя, настраиваемый порядок кнопок верхней панели; в браузере файлов фильтр вызывается клавишей `/` и ищет по текущей папке; повторный клик по активной вкладке в корне («Папки», «Плейлисты» или «Поиск») закрывает браузер и возвращает очередь, а клик по «Плейлисты» из открытого плейлиста сначала возвращает к списку; цвет фона Mopidy сохраняется как строковое значение и восстанавливается при повторном запуске. Если очередь пуста и Mopidy доступен, клик по области очереди открывает браузер треков. Если Mopidy недоступен, клик по модулю запускает команду `mopidy` (без запуска второго экземпляра, если процесс уже работает). Верхнюю панель можно скрывать; доступны настройки зоны наведения, фона и вертикального отступа.
- **Обложки:** поиск локальных обложек рядом с файлом трека; для папок `CD1`/`CD2` также проверяется корень альбома. Для Mopidy предусмотрено получение изображения через API, когда локальный путь недоступен.
- **Профили и настройки:** профили хранят только значения, отличающиеся от стартовых значений приложения; вложенные объекты (цвета, геометрия и состояние модулей) также сохраняются разреженно. При загрузке профиль восстанавливается поверх defaults, а сбросы модулей работают с развёрнутым профилем. `weatherToken` хранится глобально и не дублируется в профилях. Старые полные снимки автоматически мигрируют в разреженный формат.

## Установка

Требуется установленный Quickshell. Некоторые функции используют внешние программы и сервисы — например, CAVA, `playerctl`, `jq`, `curl`, `ffmpeg`, PulseAudio/PipeWire-инструменты и запущенный Mopidy для соответствующих интеграций. Набор необходимых программ зависит от включённых модулей и используемых бэкендов.

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

## v621 — устойчивый разбор аудиопотоков в System Monitor

- `scripts/system_monitor.d/volumes.sh` распознаёт английские (`Sink Input #`, `Volume:`) и русские (`Вход аудиоприёмника №`, `Громкость:`) заголовки `pactl`. Список потоков больше не зависит только от языка вывода аудиосервера.
- Формирование JSON для потоков переведено на `jq`, чтобы кавычки, обратные слеши и управляющие символы в названиях приложений не ломали ответ.
- Добавлен `test_system_monitor_volume_parser.sh` с фиктивным `pactl`, проверяющий оба формата, сохранность ID/уровней и безопасное экранирование имён.

## v620 — единый опрос CPU и RAM в виджете системных метрик

- `CpuWidget.qml` теперь запускает один процесс `cpu_stats_once` для получения и загрузки CPU по ядрам, и процента занятой памяти, вместо двух отдельных процессов с отдельным таймерным циклом.
- `cpu_stats_once` использует `MemTotal` и `MemAvailable` из `/proc/meminfo`, как прежний `mem_stats_once`, чтобы сохранить совместимую семантику процента используемой памяти и не различаться с ней из-за формулы `free`.
- Обновления CPU и RAM применяются из одного JSON-ответа, поэтому оба набора значений относятся к одному циклу опроса. Интервал обновления и отрисовка горизонтальных/вертикальных индикаторов не менялись.
- Добавлен `test_cpu_widget_single_poll.sh`, подключённый к `CHECK.sh`; он проверяет единственный `Process` в виджете и выполняет реальный smoke test JSON-ответа сборщика.

## v619 — отдельный компонент элемента прогноза погоды

- Повторяющаяся разметка каждого элемента почасового и дневного прогноза вынесена из `WeatherList.qml` в `components/WeatherForecastItem.qml`.
- Новый компонент централизует дату/время, иконку погоды, высокую и низкую температуру и цветовую шкалу температуры. Параметры hourly/daily и существующие настройки `Config` передаются без изменения значений.
- `WeatherList.qml` по-прежнему фильтрует будущие записи, ограничивает количество элементов, задаёт отступ сверху и показывает `WeatherPlaceholder`, когда данных нет. Логика получения данных и размеры модулей не менялись.
- Добавлен `test_weather_forecast_item_component.sh`, подключённый к `CHECK.sh`; он проверяет оба режима прогноза, настройки геометрии/шрифтов и отсутствие дублирующей форматирующей логики в родителе.

## v618 — стабилизация переключения mute

- Кнопка mute задаёт явное целевое состояние через `scripts/set_mute` (`0`/`1`) вместо команды `toggle`, поэтому быстрые повторные клики не зависят от запаздывающего состояния аудиобэкенда.
- Добавлено оптимистическое ожидающее состояние mute: устаревший ответ опроса не может сразу вернуть полоску/иконку к предыдущему состоянию. При подтверждении бэкендом ожидание снимается; по тайм-ауту интерфейс снова принимает фактическое состояние.
- Убран мгновенный stop/start процесса опроса после клика. Подтверждающий опрос откладывается на 250 мс; если старый опрос ещё выполняется, следующий запуск планируется после его завершения.
- Тот же механизм ожидания применяется при снятии mute через полосу громкости. Добавлен `test_volume_mute_toggle_stability.sh`, подключённый к `CHECK.sh`; он проверяет ожидающее состояние, отсутствие toggle-гонки и команды явного mute/unmute на мокнутом `wpctl`.

## v617 — пустая полоса при mute и восстановление уровня кликом

- Полоса основной громкости отображается пустой, когда выходное устройство заглушено; сохранённое значение громкости не сбрасывается.
- Клик или перетаскивание по основной полосе при mute задаёт уровень по положению указателя и снимает mute. Колесо над этой полосой также применяет новый уровень и снимает mute.
- Добавлена явная операция `set_main_mute`, а `scripts/set_volume main VALUE unmute` последовательно устанавливает уровень и снимает mute через wpctl, pactl или amixer. Это не использует переключение mute, поэтому не возникает гонки между независимыми командами.
- Полосы отдельных аудиопотоков и кнопка mute остаются с прежним поведением. Добавлен `test_volume_mute_track_behavior.sh`, подключённый к `CHECK.sh`; тест проверяет пустую полосу при mute, обработчики клика/колеса и последовательность команд на мокнутом `wpctl`.

## v616 — громкость использует общий ProgressTrack

- Полосы основной громкости и отдельных аудиопотоков в `Volumes.qml` переведены на `components/primitives/ProgressTrack.qml`; повторяющаяся отрисовка фона и заполнения удалена.
- Сохранены геометрия треков, `volumeMainTrackOffsetY`/`volumeStreamTrackOffsetY`, цвета и радиус, а также прежние области взаимодействия: перетаскивание, изменение значения при отпускании и прокрутка колёсиком.
- Проверка `test_progress_track_primitive.sh` расширена: она теперь требует использования примитива в `Volumes.qml` и проверяет сохранность обоих `MouseArea` и их обработчиков.

## v615 — общий примитив полосы заполнения

- Добавлен `components/primitives/ProgressTrack.qml` для отрисовки фона и заполненной части полосы с ограничением значения от 0 до 100 и поддержкой четырёх направлений.
- `MetricBar.qml` использует его для горизонтальных и вертикальных индикаторов CPU/RAM, а `TopApps.qml` — для относительных полос CPU/памяти. Геометрия, цвета и настройки существующих модулей сохранены.
- Добавлен `test_progress_track_primitive.sh`, подключённый к `CHECK.sh`; тест проверяет направления заполнения, диапазон значения и использование общего рендерера вместо дублирующей отрисовки.

## v614 — общий примитив сегментных графиков

- Повторяющаяся отрисовка полос в `CpuGraph.qml` и `Cava.qml` вынесена в `components/primitives/SegmentBarGraph.qml`. Компонент поддерживает фиксированную или адаптивную ширину слота, абсолютную ширину/долю полосы и рост вверх или вниз.
- `CpuGraph` и `Cava` по-прежнему управляют своими данными, режимами, частотой обновления и настройками. Сохранены режимы «обе половины», «только верхние» и «только нижние», цвета и геометрические параметры.
- Добавлен `test_segment_bar_graph_primitive.sh`, подключённый к `CHECK.sh`; он проверяет все четыре области визуализации в каждом модуле и отсутствие дублирования `Repeater`/`Rectangle`-отрисовки.

## v613 — общий компонент строк сетевой статистики

- Повторяющаяся разметка строки загрузки и скачивания сети вынесена в `components/NetworkStatRow.qml`.
- `NetworkStat.qml` теперь задаёт только тип строки, цвет, видимость и данные из SystemMonitor; общий компонент отвечает за колонки значка/значений, их выравнивание, отступы и шрифт.
- Сохранены все существующие параметры конфигурации и отображение скорости/суммарного трафика для upload и download.
- Добавлен `test_network_stat_row_component.sh`, включённый в `CHECK.sh`, для проверки общности разметки и сохранения привязок настроек.

## v612 — надёжное обновление снимков mpv

- Захват кадра mpv вынесен в общий механизм `scripts/player.d/common.sh`, который используется и при периодическом обновлении, и при паузе/перемотке.
- Кадры сохраняются под версионированными именами, ключом для которых служит хеш пути к медиафайлу. Благодаря изменению URL QtQuick/Image загружает свежий кадр, а спецсимволы в заголовке не ломают путь к изображению.
- Периодическое обновление по-прежнему выполняется не чаще одного раза в 60 секунд. При паузе и перемотке создаётся свежий снимок принудительно.
- Снимок публикуется атомарно только после успешного создания ffmpeg; неудачная попытка не повреждает последний рабочий кадр. Захват ограничен 15 секундами, временные файлы удаляются, старые снимки очищаются, а повторные ошибки одного источника не приводят к запуску ffmpeg при каждом опросе UI.
- Добавлен `test_mpv_snapshot_capture.sh`: проверяет периодическое обновление, принудительный снимок, изоляцию кэша для разных файлов и fallback при ошибке ffmpeg. Тест включён в `CHECK.sh`.

## v611 — ширина значений Top Apps

- Колонка значений CPU/RAM больше не ограничена фиксированными 52 px. Её ширина рассчитывается по самому длинному значению в соответствующем списке и выбранному размеру шрифта.
- Убрано обрезание значения слева многоточием: значения вроде `1001.1 Mb` отображаются целиком, сохраняя правое выравнивание. Ширина имени процесса и полосы нагрузки учитывает фактическую ширину колонки.
- Добавлен `test_top_apps_value_column_width.sh`, включённый в `CHECK.sh`.

## v610 — группировка вспомогательных процессов браузера в Top Apps

- `top_apps.sh` теперь сохраняет PID и PPID для полного снимка процессов. Процессы с именем `Isolated Web Co` (усечённое Linux-имя Firefox/Zen web-content процесса) ищут ближайшего предка Zen/Firefox-family в дереве процессов и включаются в его группу.
- В результате память и CPU таких помощников суммируются с браузером, а `Isolated Web Co` не занимает отдельную строку в топе, если удалось определить владельца. Привязка выполняется по конкретной родительской цепочке, а не глобально по имени, поэтому процессы разных экземпляров браузеров не объединяются друг с другом.
- Обновлён `test_top_apps_process_grouping.sh`: добавлены отдельные деревья Zen и Firefox, проверка сумм CPU/RSS, количества процессов и отсутствия отдельной группы `Isolated Web Co`.

## v609 — группировка процессов в Top Apps

- `top_apps.sh` теперь собирает полный снимок процессов, группирует процессы с одинаковым Linux-именем (`comm`) и суммирует их CPU и resident memory до выбора топ-5. Это объединяет отдельные PID браузеров, например процессы Zen, в одну строку с общим потреблением.
- Каждая строка содержит число объединённых PID (`processCount`) и представительный PID; числовые значения и полосы рассчитываются по агрегированной нагрузке группы.
- Добавлен `test_top_apps_process_grouping.sh` с детерминированным набором процессов для проверки сумм CPU/RSS, ранжирования групп и отсутствия повторяющихся строк. Тест добавлен в `CHECK.sh`.

## v608 — настройки компоновки Top Apps

- Скрытый заголовок теперь размещён в отдельном элементе нулевой высоты с обрезкой содержимого, поэтому текст заголовка физически не рисуется за пределами строки и не сдвигает список.
- Убраны искусственные верхние пределы размера шрифта и межстрочного интервала. Размер текста больше не проходит через общий минимум `uiFontSize`; сохраняется масштабирование относительно общего размера шрифта, но без скрытого нижнего порога.
- Добавлена настройка «Отступ от верхнего края» в CPU/RAM → Top Apps. Она сохраняется в настройках/профилях и учитывается при сбросе Top Apps и CPU/RAM. Отступ безопасно ограничивается доступной высотой блока, чтобы не создавать отрицательную геометрию.
- Обновлены проверки `test_top_apps_typography_settings.sh` и `test_top_apps_display_settings.sh`.

## v607 — настройки типографики Top Apps

- В CPU/RAM → Top Apps добавлены настройки семейства шрифта (пустое значение сохраняет системный шрифт приложения), размера текста и межстрочного интервала.
- При отключении заголовков их строка теперь получает нулевую высоту: список начинается сверху внутри блока без пустого пространства. Основной размер текста возвращён к 12 px по умолчанию, как в прежнем варианте Top Apps; размер можно уменьшить в диапазоне 8–12.
- Высота строк рассчитывается по выбранному размеру текста, расстояние между строками настраивается отдельно. Параметры сохраняются в снимках настроек/профилях и восстанавливаются при сбросе Top Apps или CPU/RAM.
- Добавлен `test_top_apps_typography_settings.sh` для проверки UI, сохранения, применения, сброса и геометрии при скрытых заголовках.

## v606 — настройки отображения Top Apps

- В CPU/RAM → Top Apps добавлены независимые переключатели заголовков CPU/памяти и полос нагрузки. По умолчанию оба элемента включены, поэтому после обновления внешний вид не меняется.
- При отключении полос имя процесса получает дополнительную ширину. Значения CPU/RAM остаются видимыми.
- Параметры сохраняются в профилях, восстанавливаются при загрузке и сбрасываются вместе с настройками CPU/RAM; добавлен тест для UI, применения, сохранения и сброса.

## v605 — Top Apps в стиле системного монитора

- Панель Top Apps получила два компактных списка с заголовками CPU и «Память», пятью ведущими процессами и индикаторами относительного значения ресурса. Цвета используют существующие акцентный и RAM-цвета темы, сохраняя рамки и настройки модуля.
- Скрипт `top_apps.sh` продолжает отдавать поля `name`, `value` и `pid`, добавляет числовой `ratio` для полосок и больше не требует `bc` для форматирования RAM. Значения экранируются через `jq`, вывод остаётся корректным JSON.
- Добавлен `test_top_apps_plasma_style.sh`: проверяет структуру представления, схему JSON, диапазон индикаторов, ограничение до пяти процессов и отсутствие зависимости от `bc`; тест подключён к `CHECK.sh`.

## v604 — общие кнопки действий окна параметров таймера

- Три иконки окна параметров таймера — комментарий, обновление и переключение паузы — переведены с локальных `Text`/`MouseArea` на `Primitives.HoverIconButton`.
- Сохранены размер области нажатия, шрифт и динамический цвет значка, обычный курсор без hover-оформления, открытие/фокус комментария и вызовы скрипта таймера для остальных действий.
- Добавлен `test_timer_options_action_button_primitive.sh`, проверяющий общий компонент и сохранность маршрутизации действий; тест подключён к `CHECK.sh`.

## v603 — общие кнопки действий Mopidy

- Вкладки «Папки», «Плейлисты» и «Поиск» переведены на `Primitives.StyledTextButton`; общий примитив расширен настраиваемыми режимами hover (фон, рамка, текст), при этом режим по умолчанию не меняет прежнее поведение других кнопок.
- Кнопки создания плейлиста, добавления треков, переименования, удаления и обновления поиска используют `MopidyHoverIcon`, а кнопки добавления/переключения/удаления плейлистов и удаления треков — `HoverButtonSurface`.
- Кнопки «Отмена» и подтверждения в диалоге создания/переименования/удаления плейлиста переведены на `StyledTextButton`. Сохранены размеры, режимы наведения, disabled-состояние и вызовы контроллера.
- Добавлен `test_mopidy_shared_action_buttons.sh`, обновлена проверка переключения вкладки поиска и тест подключён к `CHECK.sh`.

## v602 — общая кнопка погоды

- Кнопка обновления/настройки в `WeatherPlaceholder.qml` переведена на `Primitives.StyledTextButton`; убрана локальная копия оформления `Button` и его `contentItem`/`background`.
- Сохранены переключение между настройкой и ручным обновлением, блокировка на время cooldown, подписи, шрифт, цвет рамки и скругление. Для отключённого состояния задаются прежние приглушённый текст и фон.
- Добавлен тест `test_weather_placeholder_shared_button.sh` и подключён к `CHECK.sh`.

## v600 — общие кнопочные примитивы плеера и громкости

- Кнопка Next в Player переведена на `Primitives.HoverIconButton`; сохранены видимость по поддерживаемым backend, размеры, смещения и команда переключения трека.
- Кнопка mute в Volumes переведена на `Primitives.HoverButtonSurface`; логика переключения mute и немедленного обновления состояния сохранена.
- Ползунки основной громкости и потоков оставлены без изменений: drag, release и wheel требуют специализированного взаимодействия.
- Статические проверки расширены на Player и Volumes.

## v601 — общие кнопки действий календарных заметок

- Пять кнопок редактора и просмотра заметок календаря (сохранить, удалить, отменить, изменить и закрыть) переведены на `Primitives.StyledTextButton`, общий примитив на базе `QtQuick.Controls.Button`.
- Общие шрифты, текст, фон, цвет нажатия, рамка и скругление описаны один раз. Сохранены размеры, подписи и обработчики действий; клавиатурное поведение `Button` осталось доступным.
- Проверка охватывает путь создания/просмотра заметки с календарной даты, сохранение и удаление, редактирование, отмену и закрытие. Новый тест подключён к `CHECK.sh`.

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
- **Profiles and settings:** profiles store only values that differ from application defaults, including sparse nested values for colors, geometry and module state. Profiles are expanded against defaults when loaded; reset actions operate on the expanded profile. `weatherToken` remains global and is not duplicated inside profiles. Existing full-snapshot profiles are automatically migrated.

### Installation

Quickshell is required. Some features rely on external tools or services, such as CAVA, `playerctl`, `jq`, `curl`, `ffmpeg`, PulseAudio/PipeWire utilities, and a running Mopidy service for the relevant integrations. Exact requirements depend on enabled modules and backends.

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

### v620 — single CPU/RAM sampling process

- `CpuWidget.qml` now uses one `cpu_stats_once` process to collect per-core CPU and memory-use percentages instead of two separate processes and polling cycles.
- `cpu_stats_once` reads `MemTotal` and `MemAvailable` from `/proc/meminfo`, matching the previous `mem_stats_once` calculation so the reported memory percentage does not change merely because the collection path changed.
- CPU and RAM are applied from the same JSON response; the polling interval and horizontal/vertical meter rendering remain unchanged.
- Added `test_cpu_widget_single_poll.sh` to `CHECK.sh`; it checks that the widget owns one process and smoke-tests the collector's JSON output.

### v619 — standalone weather forecast item

- Extracted the repeated item delegate for hourly and daily forecasts from `WeatherList.qml` into `components/WeatherForecastItem.qml`.
- The component now owns date/time, weather icon, high/low temperature text and the temperature color scale. Hourly/daily modes and existing `Config` geometry/font bindings remain unchanged.
- `WeatherList.qml` still filters future entries, limits the item count, applies top padding and displays `WeatherPlaceholder` when no data is available. Data acquisition and module dimensions were not changed.
- Added `test_weather_forecast_item_component.sh` to `CHECK.sh`; it checks both forecast modes, layout/font bindings and removal of duplicated formatting logic from the parent.

### v618 — stable mute toggling

- The mute button now sets an explicit target state through `scripts/set_mute` (`0`/`1`) instead of toggling the backend state, so rapid clicks do not depend on stale audio-backend observations.
- Added an optimistic pending mute state: stale polling responses cannot immediately revert the icon/track. The pending state clears when the backend confirms it, or times out to let the UI accept the actual backend state.
- Removed the immediate stop/start of the poll process on icon click. A confirmation poll is delayed by 250 ms; if a poll is still running, another poll is scheduled after it completes.
- The same pending-state guard is used when unmuting via the volume track. Added `test_volume_mute_toggle_stability.sh` to `CHECK.sh`, checking the pending-state guard, absence of toggle races, and explicit mute/unmute commands with a mocked `wpctl`.

### v617 — empty muted track and click-to-unmute

- The main output volume track renders empty while muted without clearing the stored volume value.
- Clicking or dragging the main track while muted sets the level from the pointer position and unmutes the sink. The mouse wheel over the main track also applies the adjusted level and unmutes.
- Added an explicit `set_main_mute` operation; `scripts/set_volume main VALUE unmute` sets the level and unmutes sequentially through wpctl, pactl or amixer, avoiding races from separate toggle commands.
- Per-stream volume tracks and the mute icon keep their existing behavior. Added `test_volume_mute_track_behavior.sh` to `CHECK.sh`, covering muted rendering, click/wheel handlers and command order with a mocked `wpctl`.

### v616 — volume bars use shared ProgressTrack

- The main volume and per-stream volume bars in `Volumes.qml` now use `components/primitives/ProgressTrack.qml`; duplicate track/fill drawing was removed.
- Preserved track geometry, `volumeMainTrackOffsetY`/`volumeStreamTrackOffsetY`, colors and radius, along with existing interaction areas for dragging, applying values on release, and mouse-wheel adjustments.
- Expanded `test_progress_track_primitive.sh` to require the shared primitive in `Volumes.qml` and verify both `MouseArea` handlers remain in place.

### v615 — shared progress track primitive

- Added `components/primitives/ProgressTrack.qml` to render track/fill pairs with values clamped to 0–100 and support for all four fill directions.
- `MetricBar.qml` now uses it for horizontal and vertical CPU/RAM gauges, and `TopApps.qml` uses it for relative CPU/memory bars. Existing geometry, colors and settings are preserved.
- Added `test_progress_track_primitive.sh` to `CHECK.sh`; it checks fill directions, value clamping and adoption of the shared renderer in place of duplicate drawing.

### v614 — shared segment bar graph primitive

- Extracted repeated bar rendering from `CpuGraph.qml` and `Cava.qml` into `components/primitives/SegmentBarGraph.qml`. It supports fixed or adaptive slots, absolute or proportional bar width, and bars growing upward or downward.
- `CpuGraph` and `Cava` retain their own data sources, display modes, update rates and configuration. Mirrored, upper-only and lower-only modes, colors and geometry settings are preserved.
- Added `test_segment_bar_graph_primitive.sh` to `CHECK.sh`; it verifies all four display regions in both modules use the shared renderer and do not duplicate `Repeater`/`Rectangle` drawing.

### v613 — shared network statistics row

- Extracted the repeated upload/download row layout into `components/NetworkStatRow.qml`.
- `NetworkStat.qml` now supplies only row-specific icon, color, visibility and SystemMonitor data; the shared component owns icon/value columns, alignment, padding and typography.
- Preserved existing Config bindings and upload/download speed and total traffic values.
- Added `test_network_stat_row_component.sh` to `CHECK.sh` to validate shared layout and retained settings bindings.

### v612 — reliable mpv frame snapshots

- Centralized mpv frame capture in `scripts/player.d/common.sh`; both periodic refreshes and pause/seek actions now use the same implementation.
- Snapshots use versioned filenames keyed by a hash of the media path. The changed URL lets QtQuick/Image load each refreshed frame, and media titles with special characters no longer affect the filename.
- Periodic refresh remains capped at once every 60 seconds; pause and seek force a fresh frame.
- Frames are atomically published only after ffmpeg succeeds. Failed capture leaves the last valid frame intact; ffmpeg is time-limited to 15 seconds, temporary files are removed, old snapshots are cleaned up, and repeated failures for the same source are throttled rather than retried on every UI poll.
- Added `test_mpv_snapshot_capture.sh` for periodic expiry, forced capture, per-source cache isolation and ffmpeg-failure fallback; wired it into `CHECK.sh`.

### v611 — Top Apps value column sizing

- CPU/RAM values are no longer constrained to a fixed 52 px column. Width is derived from the longest value in each list and the configured font size.
- Removed leading-ellipsis truncation: values such as `1001.1 Mb` remain fully visible and right-aligned. Process-name and bar widths account for the dynamic value column.
- Added `test_top_apps_value_column_width.sh` and wired it into `CHECK.sh`.

### v610 — browser helper attribution in Top Apps

- `top_apps.sh` now retains PID and PPID in the full process snapshot. Processes named `Isolated Web Co` (the truncated Linux name used by Firefox/Zen isolated web-content processes) walk their parent chain to find the nearest Zen/Firefox-family ancestor and join that browser group.
- CPU and RSS for those helpers are included in the browser totals, so `Isolated Web Co` no longer appears as a separate Top Apps row when its owner can be determined. Attribution follows each concrete parent chain rather than merging all helper processes globally, keeping separate browser instances distinct.
- Expanded `test_top_apps_process_grouping.sh` with separate Zen and Firefox process trees, aggregate CPU/RSS and process-count assertions, and a check that attributed helpers do not form a standalone group.

### v609 — Top Apps process grouping

- `top_apps.sh` now snapshots the full process list, groups processes with the same Linux process name (`comm`), and sums CPU and resident memory before selecting the top five. This combines separate browser PIDs, such as Zen processes, into one row with aggregate usage.
- Each row includes the number of grouped PIDs (`processCount`) and a representative PID; displayed values and relative bars are computed from the group total.
- Added `test_top_apps_process_grouping.sh` with deterministic process fixtures to verify CPU/RSS sums, group ranking, and unique rows. The test is included in `CHECK.sh`.

### v608 — Top Apps layout controls

- The hidden header is now a separate zero-height, clipped item, preventing header text from painting outside the collapsed row or shifting the process list.
- Removed artificial upper bounds on font size and row spacing. The configured font size no longer goes through the generic `uiFontSize` minimum clamp; it still follows the global font scale without a hidden lower threshold.
- Added a “Top edge offset” setting under CPU/RAM → Top Apps. It is persisted in settings/profile snapshots and restored by Top Apps and CPU/RAM resets. The layout safely clamps the actual padding to the available section height to prevent invalid geometry.
- Updated `test_top_apps_typography_settings.sh` and `test_top_apps_display_settings.sh`.

### v607 — Top Apps typography settings

- Added font-family (empty keeps the application system font), text-size and line-spacing settings under CPU/RAM → Top Apps.
- When headers are disabled, the header row now has zero height, so process rows start at the top of the section without a reserved blank row. The default body text size returns to 12 px, matching the earlier Top Apps view; it can be adjusted from 8 to 12.
- Row height follows the configured text size, and inter-row spacing is adjustable. The new values are persisted in settings/profile snapshots and restored by Top Apps or CPU/RAM resets.
- Added `test_top_apps_typography_settings.sh` to verify the controls, apply/persistence/reset wiring and zero-height header behavior.

### v606 — Top Apps display settings

- Added independent toggles under CPU/RAM → Top Apps for section headers and resource bars. Both default to enabled, preserving the v605 appearance after upgrade.
- When bars are hidden, process names expand into the freed space while CPU/RAM values remain visible.
- Settings are saved in profiles, restored on load, and reset with CPU/RAM settings; a regression test covers UI bindings, persistence, apply and reset paths.

## v605 — Plasma-style Top Apps view

- Top Apps now presents compact CPU and Memory sections with the five leading processes and relative resource-use bars. It uses the existing theme accent/RAM colors and retains the module frame and settings integration.
- `top_apps.sh` preserves the `name`, `value` and `pid` fields, adds numeric `ratio` values for the bars, and no longer needs `bc` to format resident memory. Process names are serialized safely through `jq`, producing valid JSON.
- Added `test_top_apps_plasma_style.sh` to check the QML structure, JSON schema, bar-ratio bounds, five-process limit and lack of a `bc` dependency; wired it into `CHECK.sh`.

### v604 — shared TimerOptions action buttons

- The TimerOptions popup's comment, refresh and pause-toggle icons now use `Primitives.HoverIconButton` instead of local `Text`/`MouseArea` implementations.
- Preserved hit-target dimensions, font and dynamic icon color, arrow cursor with no hover decoration, comment editor focus/select behavior and timer-script calls for the remaining actions.
- Added `test_timer_options_action_button_primitive.sh` to verify shared-component use and the existing action routes; wired it into `CHECK.sh`.

### v603 — shared Mopidy action buttons

- The Browse, Playlists and Search tabs now use `Primitives.StyledTextButton`; the primitive supports configurable background/frame/text hover modes while retaining its existing default behavior.
- Playlist create/add/switch/rename/delete controls and search refresh now use `MopidyHoverIcon` or `HoverButtonSurface` instead of local Rectangle/MouseArea implementations.
- Playlist dialog Cancel and confirm actions now use `StyledTextButton`, preserving dimensions, hover modes, disabled state and controller actions.
- Added `test_mopidy_shared_action_buttons.sh`, updated the search-tab check, and wired the new test into `CHECK.sh`.

### v602 — shared Weather action button

- The refresh/settings action in `WeatherPlaceholder.qml` now uses `Primitives.StyledTextButton`, removing its duplicated `Button` content and background styling.
- The settings-vs-refresh route, cooldown disabled state, labels, font, border color and radius are preserved; disabled text/background remain muted as before.
- Added `test_weather_placeholder_shared_button.sh` and wired it into `CHECK.sh`.

### v600 — shared Player and volume button primitives

- Player's Next control now uses `Primitives.HoverIconButton`, preserving backend visibility, dimensions, offsets and the next-track command.
- The Volumes mute control now uses `Primitives.HoverButtonSurface`, preserving mute toggling and the immediate state refresh.
- Main and stream volume sliders remain specialized so drag, release and wheel handling are unchanged.
- Static checks now cover Player and Volumes controls.

### v601 — shared calendar note action buttons

- The five calendar note actions (Save, Delete, Cancel, Edit and Close) now use `Primitives.StyledTextButton`, a shared component built on `QtQuick.Controls.Button`.
- Shared text, font, background, pressed color, border and radius styling is defined once. Dimensions, labels and action handlers are preserved, including standard button keyboard behavior.
- Static checks cover note creation/view entry points, save/delete, edit, cancel and close actions. The new test is wired into `CHECK.sh`.

## Known issues

- Disappearance animations using `slideLeft`, `slideRight`, `slideUp` or `slideDown` are still under investigation. `fade` and disabling animations work.
- The hidden Mopidy top panel still has occasional hover/close edge cases. This issue is intentionally lower priority for now.

### User data

User data is stored separately from the installed code using XDG directories:

- settings and profiles: `~/.config/quickshell-widgets/settings.json`;
- calendar notes: `~/.local/share/quickshell-widgets/calendar-notes.json`;
- logs: `~/.local/state/quickshell-widgets/`;
- cache: `~/.cache/quickshell-widgets/`.

The paths honor `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, and `XDG_CACHE_HOME`. On first use, compatible legacy `settings.json` and `calendar-notes.json` files from the project directory or a previous Quickshell install are copied to the new locations if the destination files do not exist. Originals are kept. Do not commit personal tokens or other secrets to the repository.


## Рефакторинг Mopidy (v586)

- В v585 верхняя панель Mopidy была вынесена в отдельный компонент `MopidyTopPanel.qml`; команды управления по-прежнему выполняются основной логикой Mopidy.
- В v586 диалог создания, переименования и удаления плейлистов вынесен в `MopidyPlaylistDialog.qml`. Состояние и операции остаются в `Mopidy.qml`, а UI взаимодействует с ними через явный `controller`. Фокус поля, выделение названия при переименовании, Enter/Escape и блокировка подтверждения во время операции сохранены.
- Эти переносы разделяют UI и управляющую логику небольшими независимыми шагами; цель — сохранить существующее поведение, а не менять UX.

## Профили и сохранённые настройки (v584)

- Профили сохраняются как разреженные изменения относительно стартовой конфигурации приложения. При загрузке значения объединяются с исходными defaults, поэтому пропущенные поля не теряются и корректно возвращаются при переключении профиля.
- Полные профили из старого формата автоматически конвертируются при первом запуске новой версии; исходные настройки перед сохранением преобразуются в каноничный JSON.
- Удалено сохранение неиспользуемого `playerControlIconSize`; актуальные размеры отдельных кнопок Player остаются независимыми.
- Старые поля `timerFinishedImageTopMargin` / `timerFinishedImageBottomMargin` и `mopidyShowMoveButtons` больше не записываются в новые снимки. При загрузке они по-прежнему поддерживаются как legacy-поля и мигрируют к актуальным параметрам.
- Исправлено сохранение пользовательских цветов окна завершения таймера как hex-строк; повреждённые старые значения нормализуются к безопасным значениям по умолчанию.
- `weatherToken` очищается от случайных пробелов/переводов строки при загрузке и сохранении.
- Для `mopidyAlbumBold` добавлено явное значение по умолчанию.


## Рефакторинг Mopidy (v587–v589)

- В v587 браузер музыкальной библиотеки вынесен в `components/mopidy/MopidyFileBrowser.qml`. Он отвечает за список папок и треков, быстрый фильтр по `/`, навигацию по родительской папке и кнопки добавления; состояние и действия продолжают принадлежать основному контроллеру и передаются через `controller`.
- Сохранены обработка Enter/Escape в фильтре, фокус браузера и поля фильтра, переходы по папкам и добавление папок/треков в очередь или плейлист.
- В v588 файлы QML модуля Mopidy сгруппированы в `components/mopidy/`, настройки Mopidy — в `components/settings/sections/mopidy/`, а скрипты Mopidy вместе с backend плеера — в `scripts/mopidy/`; импорты, тесты и пути вызова обновлены.
- В v589 интерфейс содержимого открытого плейлиста вынесен в `components/mopidy/MopidyPlaylistContents.qml`. Изменения списка по-прежнему выполняет основной контроллер Mopidy, а состояние процесса перемещения треков предоставлено через явное свойство.


## Рефакторинг очереди Mopidy (v590)

- Разметка заголовка альбома вынесена в `components/mopidy/MopidyAlbumHeader.qml`, а строки очереди — в `components/mopidy/MopidyQueueTrackRow.qml`. Оба компонента получают основной Mopidy-контроллер через явное свойство `controller`; операции воспроизведения, перемещения и удаления остаются в основном модуле.
- Список очереди, группировка альбомов, сохранение прокрутки и закреплённый заголовок оставлены в `Mopidy.qml`, так как они тесно связаны с общим состоянием очереди. Добавлена проверка новых компонентов в `CHECK.sh`.


## Рефакторинг библиотеки Mopidy (v591)

- Весь интерфейс библиотеки Mopidy — вкладки «Папки», «Плейлисты», «Поиск», содержимое открытого плейлиста и результаты поиска — вынесен в `components/mopidy/MopidyLibraryView.qml`. Основной `Mopidy.qml` теперь отвечает за состояние, вызовы backend и операции; представление получает его через `controller`.
- Для поиска и браузера добавлены явные методы фокуса/очистки на границе компонента. Это сохраняет клавиатурное управление, быстрый фильтр `/`, Enter/Escape и возврат к очереди без доступа к внутренним `id` дочернего компонента.
- `Mopidy.qml` сокращён примерно на 530 строк. Добавлена отдельная структурная проверка компонента и обновлены тесты, зависящие от расположения разметки.


## Исправление привязок контроллера Mopidy (v592)

- Исправлены самоссылочные привязки в `MopidyLibraryView.qml`: браузер файлов и содержимое плейлиста теперь получают `libraryRoot.controller` явно, включая вычисление видимости дочерних компонентов. Это устраняет обращения к состоянию библиотеки, фильтру и параметрам hover через `undefined`.
- Тесты библиотеки, фильтра и содержимого плейлиста теперь запрещают `controller: controller`, чтобы подобная регрессия не прошла статические проверки.


## Общий примитив рамки модулей (v593)

- Общая рамка модулей перенесена из `components/Frame.qml` в `components/primitives/ModuleFrame.qml`, рядом с другими переиспользуемыми QML-примитивами.
- Все модули, использовавшие общую рамку, переведены на явный импорт `Primitives.ModuleFrame`. Сохранены `moduleName`, управление рамкой/фоном через настройки и прежние значения цвета, толщины границы и радиуса.
- Функциональность рамки не менялась; добавлена проверка путей импорта и использования примитива.


## Общий примитив интерактивной иконки (v594)

- Общая отрисовка интерактивной иконки вынесена в `components/primitives/HoverIconButton.qml`: режимы наведения (фон, рамка и цвет текста), курсор, обработчик клика и подсказка теперь реализованы в одном месте.
- `MoveArrowButton.qml` и `MopidyHoverIcon.qml` сохранены как совместимые адаптеры, использующие общий примитив. Это позволяет разделять визуальный механизм и специфичные настройки модулей без изменения мест вызова.
- Добавлен тест `test_hover_icon_button_primitive.sh` и подключён к `CHECK.sh`.

## Кнопки Networks и выравнивание (v595)

- Интерактивная строка подключения вынесена в `components/NetworkConnectionButton.qml`, чтобы кнопки сетевых профилей имели отдельную, напрямую проверяемую реализацию. Строки по-прежнему переключают подключение через `nmcli` и подсвечивают активную сеть.
- Выравнено содержимое сетевых строк: единая ширина колонки значка, фиксированный промежуток, адаптивная ширина имени, вертикальное центрирование и единые внутренние отступы. Убран ручной вертикальный сдвиг значка.
- `Networks.qml` теперь использует защищённую проверку доступности данных монитора и отключает горизонтальную прокрутку.
- Проверка интерактивных кнопок расширена на Networks: тестирует обработчик подключения/отключения, hover, курсор, выравнивание и структуру нового компонента.

## Общая поверхность кнопок, включая Networks (v596)

- Добавлен `components/primitives/HoverButtonSurface.qml` — общий низкоуровневый примитив для фона, рамки, наведения, курсора, клика, подсказки и пользовательского содержимого.
- `HoverIconButton.qml` теперь использует эту поверхность, сохраняя три режима hover (фон, рамка и цвет иконки). `MopidyHoverIcon.qml` и `MoveArrowButton.qml` продолжают работать через прежний совместимый интерфейс.
- Строка подключения `NetworkConnectionButton.qml` переведена на тот же `HoverButtonSurface`: активный фон, рамка при наведении, переключение `nmcli` и выровненное содержимое сохранены. Это закрывает прежний пробел в проверке общих кнопочных примитивов — Networks теперь не только тестируется отдельно, но и использует общую реализацию.
- Проверка `test_hover_icon_button_primitive.sh` расширена: теперь она проверяет использование общего слоя иконками Mopidy/стрелок и кнопками Networks, а также отсутствие дублирующих `Rectangle`/`MouseArea` в компонентах-адаптерах.



## Пресеты таймера на общей поверхности кнопок (v597)

- `HoverButtonSurface.qml` расширен поддержкой набора принимаемых кнопок мыши, настраиваемой формы курсора и опционального события колеса. Для существующих потребителей сохранены левый клик, курсор-указатель и прежняя обработка наведения.
- Пресеты в `TimerWidget.qml` вынесены в `components/TimerPresetButton.qml` и используют общий `HoverButtonSurface`, без собственного `Rectangle`/`MouseArea`.
- Сохранены действия левого клика (добавить таймер), среднего клика (сбросить пресет), прокрутка для изменения значения и Shift-множитель 10. Визуальный стиль и курсор пресетов сохранены.
- Добавлен `test_timer_preset_button_primitive.sh` и подключён к `CHECK.sh`; тест проверяет повторное использование общей поверхности и прежние обработчики.


## Кнопки таймера и будильника на общей поверхности (v598)

- Элементы выбора часов и минут будильника вынесены в `components/TimerAlarmTimeButton.qml`. Теперь и пресеты обычного таймера, и поля времени будильника используют `HoverButtonSurface`, вместо отдельных повторяющихся сочетаний `Rectangle` и `MouseArea`.
- Сохранены исходные действия: левый клик по часу/минутам создаёт будильник на выбранное время; средний клик по минутам сбрасывает минуты в `00`; колесо часов/минут меняет соответствующую часть времени, а Shift ускоряет изменение в 10 раз. Клик по значку будильника использует ту же общую операцию установки.
- Общие операции установки и изменения целевого времени собраны в методах `TimerWidget.qml`; логика перехода на следующий день и сброса состояния ручной настройки сохранена. Специальная область наведения двух значков оставлена отдельной, поскольку она классифицирует зоны по координатам и не является обычной кнопочной поверхностью.
- Добавлен `test_timer_alarm_button_primitive.sh` и подключён к `CHECK.sh`; проверяются оба поля времени, кнопки мыши, прокрутка, общая поверхность и отсутствие дублирующей разметки в часах/минутах.


## Кнопки навигации календаря на общем примитиве (v599)

- Кнопки перехода к предыдущему и следующему месяцу в `CalendarWidget.qml` переведены на `Primitives.HoverIconButton`, чтобы отрисовка и обработка взаимодействия не дублировались через отдельные `Text` и `MouseArea`.
- В `HoverIconButton.qml` добавлена настройка `cursorShape`; для календаря явно сохранён обычный курсор, прежние размеры, шрифт, смещения и обработчики `shiftMonth(-1/1)` остаются прежними.
- Добавлен `test_calendar_navigation_button_primitive.sh`, проверяющий обе кнопки и их настройки; тест подключён к `CHECK.sh`.


## Общие кнопки действий заметок календаря (v601)

- Кнопки «Сохранить», «Удалить», «Отмена», «Изменить» и «Закрыть» вынесены на `Primitives.StyledTextButton`, построенный на `QtQuick.Controls.Button`, чтобы сохранить стандартную клавиатурную активацию.
- Повторяющееся оформление текста, фона, цвета нажатия, рамки и радиуса углов находится в `components/primitives/StyledTextButton.qml`. Размеры, подписи и маршруты действий заметок сохранены.
- Добавлен `test_calendar_note_buttons_shared_primitive.sh`: он проверяет вход из даты в создание/просмотр заметки и все основные действия редактора, и подключён к `CHECK.sh`.

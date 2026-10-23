#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

expect() {
    local file="$1" title="$2"
    if ! grep -Fq "text: \"$title\"" "$ROOT/$file" && ! grep -Fq "heading: \"$title\"" "$ROOT/$file"; then
        echo "Missing concise heading '$title' in $file" >&2
        exit 1
    fi
}
reject() {
    local file="$1" title="$2"
    if grep -Fq "text: \"$title\"" "$ROOT/$file"; then
        echo "Verbose heading still present: '$title' in $file" >&2
        exit 1
    fi
}

expect components/settings/sections/SettingsWindowSection.qml "Интерфейс настроек"
expect components/settings/sections/SettingsWindowSection.qml "Положение и размер окна"
expect components/settings/sections/SettingsWindowSection.qml "Фон и рамка окна настроек"
expect components/settings/sections/SettingsWindowSection.qml "Профили настроек"
expect components/settings/sections/SettingsGeneralSection.qml "Шрифты интерфейса"
expect components/settings/sections/SettingsGeneralSection.qml "Рамки виджетов"
expect components/settings/sections/SettingsNetworkSection.qml "Обновление данных"
expect components/settings/sections/SettingsNetworkSection.qml "Отступы сетевого блока"
expect components/settings/sections/SettingsTimersSection.qml "Минуты кнопок таймера"
expect components/settings/sections/SettingsTimersSection.qml "Оформление и показ"
expect components/settings/sections/SettingsCpuRamSection.qml "Полосы CPU и RAM"
expect components/settings/sections/SettingsCpuRamSection.qml "Список приложений"
expect components/settings/sections/SettingsWeatherSection.qml "Размер стрелки ветра"
expect components/settings/sections/SettingsWeatherSection.qml "Дневной прогноз"
expect components/settings/sections/SettingsVolumeSection.qml "Полоса и аудиопотоки"
expect components/settings/sections/mopidy/SettingsMopidyTimeSection.qml "Название и исполнитель"
expect components/settings/sections/mopidy/SettingsMopidyIconsSection.qml "Иконки"

reject components/settings/sections/SettingsWindowSection.qml "Отдельный шрифт, размер текста и внутренние отступы самого окна настроек."
reject components/settings/sections/SettingsWindowSection.qml "Координаты и размеры окна настроек"
reject components/settings/sections/SettingsWindowSection.qml "Сохраняй несколько вариантов всей конфигурации и переключайся между ними без ручной перенастройки."
reject components/settings/sections/SettingsGeneralSection.qml "Основной шрифт интерфейса, LED-шрифт и общие параметры"
reject components/settings/sections/SettingsGeneralSection.qml "Общие рамки виджетов. Толщина 0 полностью отключает рамку."
reject components/settings/sections/SettingsNetworkSection.qml "Частота обновления общих данных мониторинга"
reject components/settings/sections/SettingsNetworkSection.qml "Внешний вид и расположение сетевого трафика"
reject components/settings/sections/SettingsTimersSection.qml "Анимация появления/исчезновения"
reject components/settings/sections/SettingsCalendarSection.qml "Анимация появления/исчезновения"
reject components/settings/sections/SettingsWindowSection.qml "Анимация появления/исчезновения"
reject components/settings/sections/mopidy/SettingsMopidySection.qml "Анимация появления/исчезновения"

echo 'Concise settings headings: OK'

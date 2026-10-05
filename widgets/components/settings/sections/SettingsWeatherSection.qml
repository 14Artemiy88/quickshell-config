import "../../.."
import QtQuick
import "../primitives"

Column {
    id: weatherSection

    property var host
    property var settings: Settings

    visible: host && host.currentOtherTab === 3
    width: parent ? parent.width : 0
    spacing: 10

                Text {
                    visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 0
                    text: "Токен Gismeteo"
                    color: Config.text
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(13)
                }
                SettingsTextField {
                    visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 0
                    id: token
                    width: parent.width
                    height: 34
                    text: settings.weatherToken
                    color: Config.text
                    selectionColor: Config.accent
                    selectedTextColor: Config.black
                    placeholderText: "Введите токен Gismeteo"
                    placeholderTextColor: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(12)
                    activeFocusOnTab: true
                    background: Rectangle {
                        color: Config.settingsBackground
                        border.color: (token.activeFocus || token.pointerHovered) ? Config.accent : Config.baseColor
                        border.width: 1
                        radius: Config.radius
                    }
                    onEditingFinished: {
                        settings.weatherToken = text
                        settings.save()
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 0
                    Text { width: 210; text: "Погода сейчас (мин)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherNowIntervalField; width: 100; height: 30; value: Config.weatherNowIntervalMinutes; minimum: 1; maximum: 1440; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; targetObject: Config; targetProperty: "weatherNowIntervalMinutes"; settingsObject: settings; saveOnEdit: true }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 0
                    Text { width: 210; text: "Погода по часам (мин)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherHourlyIntervalField; width: 100; height: 30; value: Config.weatherHourlyIntervalMinutes; minimum: 1; maximum: 1440; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; targetObject: Config; targetProperty: "weatherHourlyIntervalMinutes"; settingsObject: settings; saveOnEdit: true }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 0
                    Text { width: 210; text: "Погода по дням (мин)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherDailyIntervalField; width: 100; height: 30; value: Config.weatherDailyIntervalMinutes; minimum: 1; maximum: 1440; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; targetObject: Config; targetProperty: "weatherDailyIntervalMinutes"; settingsObject: settings; saveOnEdit: true }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 0
                    Text { width: 210; text: "Повтор после ошибки (мин)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    SettingsNumberField { id: weatherRetryDelayField; width: 100; height: 30; value: Config.weatherRetryDelayMinutes; minimum: 1; maximum: 1440; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; targetObject: Config; targetProperty: "weatherRetryDelayMinutes"; settingsObject: settings; saveOnEdit: true }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 0
                    Text { width: 210; text: "Пауза между ручными обновлениями (с)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    SettingsNumberField { id: weatherManualCooldownField; width: 100; height: 30; value: Config.weatherManualRefreshCooldownSeconds; minimum: 5; maximum: 3600; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; targetObject: Config; targetProperty: "weatherManualRefreshCooldownSeconds"; settingsObject: settings; saveOnEdit: true }
                }
                Text { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; text: "Иконка текущей погоды"; color: Config.settingsSubheading; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10) }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 24; spacing: 8
                    Item { width: 210; height: 24 }
                    Text { width: 58; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    Text { width: 58; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Иконка ветра"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsTextField { id: weatherWindIconField; width: 160; height: 30; text: Config.weatherWindIcon; color: Config.text; selectionColor: Config.accent; selectedTextColor: Config.black; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (weatherWindIconField.activeFocus || weatherWindIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
                        onEditingFinished: { Config.weatherWindIcon = text; text = Config.weatherWindIcon; settings.save() }
                        Connections { target: Config; function onWeatherWindIconChanged() { weatherWindIconField.text = Config.weatherWindIcon } }
                    }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1
                    Text { width: 210; text: "Размер иконки текущей погоды"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    SettingsNumberField { id: weatherIconSizeField; width: 100; height: 30; value: Config.weatherIconSize; minimum: 16; maximum: 128; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherIconSize"; settingsObject: settings; saveOnEdit: true }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1
                    Text { width: 210; text: "Размер стрелки ветра"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    SettingsNumberField { id: weatherArrowSizeField; width: 100; height: 30; value: Config.weatherArrowSize; minimum: 8; maximum: 64; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherArrowSize"; settingsObject: settings; saveOnEdit: true }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1
                    Text { width: 210; text: "Смещение стрелки ветра по Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    SettingsNumberField { id: weatherArrowYField; width: 100; height: 30; value: Config.weatherArrowYOffset; minimum: -40; maximum: 40; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherArrowYOffset"; settingsObject: settings; saveOnEdit: true }
                }
                Row { width: parent.width; height: 30; spacing: 8
                    visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1
                    Text { width: 210; text: "Зазор стрелки до скорости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                    SettingsNumberField { id: weatherWindGapField; width: 100; height: 30; value: Config.weatherWindArrowGap; minimum: -20; maximum: 40; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherWindArrowGap"; settingsObject: settings; saveOnEdit: true }
                }
                Text {
                    visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1
                    text: "Дополнительная геометрия текущей погоды"
                    color: Config.settingsSubheading
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Y картинки текущей погоды"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherIconYField; width: 100; height: 30; value: Config.weatherIconY; minimum: -100; maximum: 100; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherIconY"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "X колонки ветра"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherWindXField; width: 100; height: 30; value: Config.weatherWindColumnX; minimum: 0; maximum: 500; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherWindColumnX"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Размер текста описания"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherDescSizeField; width: 100; height: 30; value: Config.weatherDescriptionFontSize; minimum: 6; maximum: 48; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDescriptionFontSize"; settingsObject: settings; saveOnEdit: true }
                }
                Text { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; text: "Дополнительная геометрия и типографика"; color: Config.settingsSubheading; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10) }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Температура: ширина колонки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherTempColumnWidthField; width: 100; height: 30; value: Config.weatherTempColumnWidth; minimum: 40; maximum: 200; step: 1; wheelStep: 1; compact: true; fieldWidth: 100; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherTempColumnWidth"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Температура: X / ширина"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherTempXField; width: 70; height: 30; value: Config.weatherTempX; minimum: 0; maximum: 200; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherTempX"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: weatherTempWidthField; width: 70; height: 30; value: Config.weatherTempWidth; minimum: 20; maximum: 200; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherTempWidth"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Комфорт: Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherComfortYField; width: 70; height: 30; value: Config.weatherComfortY; minimum: -20; maximum: 100; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherComfortY"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Основная температура: отступ X / Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherTempOffsetXField; width: 70; height: 30; value: Config.weatherTempOffsetX; minimum: -100; maximum: 100; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherTempOffsetX"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: weatherTempOffsetYField; width: 70; height: 30; value: Config.weatherTempOffsetY; minimum: -100; maximum: 100; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherTempOffsetY"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Температура комфорта: отступ X / Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherComfortOffsetXField; width: 70; height: 30; value: Config.weatherComfortOffsetX; minimum: -100; maximum: 100; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherComfortOffsetX"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: weatherComfortOffsetYField; width: 70; height: 30; value: Config.weatherComfortOffsetY; minimum: -100; maximum: 100; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherComfortOffsetY"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ветер: X / ширина"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherWindColumnXExtraField; width: 70; height: 30; value: Config.weatherWindColumnX; minimum: 0; maximum: 500; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherWindColumnX"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: weatherWindColumnWidthExtraField; width: 70; height: 30; value: Config.weatherWindColumnWidth; minimum: 60; maximum: 300; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherWindColumnWidth"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Стрелка: ширина / высота"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherWindArrowWidthField; width: 70; height: 30; value: Config.weatherWindArrowWidth; minimum: 8; maximum: 50; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherWindArrowWidth"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: weatherWindArrowHeightField; width: 70; height: 30; value: Config.weatherWindArrowHeight; minimum: 15; maximum: 80; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherWindArrowHeight"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Скорость ветра: X / Y / ширина"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherWindSpeedXExtraField; width: 62; height: 30; value: Config.weatherWindSpeedX; minimum: 0; maximum: 250; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherWindSpeedX"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: weatherWindSpeedYExtraField; width: 62; height: 30; value: Config.weatherWindSpeedY; minimum: -20; maximum: 80; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherWindSpeedY"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: weatherWindSpeedWidthExtraField; width: 62; height: 30; value: Config.weatherWindSpeedWidth; minimum: 20; maximum: 150; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherWindSpeedWidth"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ед. ветра: X / Y / ширина"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherWindUnitXExtraField; width: 62; height: 30; value: Config.weatherWindUnitX; minimum: 0; maximum: 300; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherWindUnitX"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: weatherWindUnitYExtraField; width: 62; height: 30; value: Config.weatherWindUnitY; minimum: -20; maximum: 80; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 11; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherWindUnitY"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: weatherWindUnitWidthExtraField; width: 62; height: 30; value: Config.weatherWindUnitWidth; minimum: 10; maximum: 120; step: 1; wheelStep: 1; compact: true; fieldWidth: 62; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherWindUnitWidth"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Давление: ширина / шрифт"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherPressureWidthExtraField; width: 70; height: 30; value: Config.weatherPressureValueWidth; minimum: 20; maximum: 180; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherPressureValueWidth"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: weatherPressureFontExtraField; width: 70; height: 30; value: Config.weatherPressureFontSize; minimum: 8; maximum: 48; step: 1; wheelStep: 1; compact: true; fieldWidth: 70; fieldFontSize: 11; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherPressureFontSize"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ед. давления: X / Y / шрифт"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: weatherPressureUnitXExtraField; width: 60; height: 30; value: Config.weatherPressureUnitX; minimum: 0; maximum: 300; step: 1; wheelStep: 1; compact: true; fieldWidth: 60; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherPressureUnitX"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: weatherPressureUnitYExtraField; width: 60; height: 30; value: Config.weatherPressureUnitY; minimum: -20; maximum: 80; step: 1; wheelStep: 1; compact: true; fieldWidth: 60; fieldFontSize: 10; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherPressureUnitY"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: weatherPressureUnitFontExtraField; width: 60; height: 30; value: Config.weatherPressureUnitFontSize; minimum: 6; maximum: 30; step: 1; wheelStep: 1; compact: true; fieldWidth: 60; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherPressureUnitFontSize"; settingsObject: settings; saveOnEdit: true }
                }
                Text { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 2; text: "Почасовой блок"; color: Config.settingsSubheading; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10) }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Количество часов"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: whCount; width: 58; height: 30; value: Config.weatherHourlyCount; minimum: 1; maximum: 12; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyCount"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Верхний отступ"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: whPad; width: 58; height: 30; value: Config.weatherHourlyTopPadding; minimum: 0; maximum: 40; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyTopPadding"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 2; width: parent.width; height: 24; spacing: 8
                    Item { width: 210; height: 24 }
                    Text { width: 58; y: 4; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    Text { width: 58; y: 4; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Время"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: whDayYTable; width: 58; height: 30; value: Config.weatherHourlyDayY; minimum: 0; maximum: 120; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyDayY"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: whDaySizeTable; width: 58; height: 30; value: Config.weatherHourlyDayFontSize; minimum: 6; maximum: 32; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyDayFontSize"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Иконка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: whIconYTable; width: 58; height: 30; value: Config.weatherHourlyIconY; minimum: 0; maximum: 120; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyIconY"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: whIconSizeTable; width: 58; height: 30; value: Config.weatherHourlyIconWidth; minimum: 16; maximum: 90; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyIconWidth"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Температура"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: whTempYTable; width: 58; height: 30; value: Config.weatherHourlyTempY; minimum: 0; maximum: 150; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyTempY"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: whTempSizeTable; width: 58; height: 30; value: Config.weatherHourlyTempFontSize; minimum: 6; maximum: 32; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherHourlyTempFontSize"; settingsObject: settings; saveOnEdit: true }
                }
                Text { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 3; text: "Дневной блок — максимум 4 колонки"; color: Config.settingsSubheading; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10) }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Количество дней"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: wdCount; width: 58; height: 30; value: Config.weatherDailyCount; minimum: 1; maximum: 4; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyCount"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Верхний отступ"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: wdPad; width: 58; height: 30; value: Config.weatherDailyTopPadding; minimum: 0; maximum: 40; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyTopPadding"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 3; width: parent.width; height: 24; spacing: 8
                    Item { width: 210; height: 24 }
                    Text { width: 58; y: 4; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    Text { width: 58; y: 4; text: "Размер"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "День"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: wdDayYTable; width: 58; height: 30; value: Config.weatherDailyDayY; minimum: 0; maximum: 120; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyDayY"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: wdDaySizeTable; width: 58; height: 30; value: Config.weatherDailyDayFontSize; minimum: 6; maximum: 32; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyDayFontSize"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Иконка"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: wdIconYTable; width: 58; height: 30; value: Config.weatherDailyIconY; minimum: 0; maximum: 120; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyIconY"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: wdIconSizeTable; width: 58; height: 30; value: Config.weatherDailyIconWidth; minimum: 16; maximum: 90; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyIconWidth"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 3; width: parent.width; height: 24; spacing: 8
                    Item { width: 210; height: 24 }
                    Text { width: 58; y: 4; text: "X"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    Text { width: 58; y: 4; text: "Y"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    Text { width: 58; y: 4; text: "Шрифт"; color: Config.textMuted; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Дневная температура"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: wdHX; width: 58; height: 30; value: Config.weatherDailyHighTempX; minimum: -100; maximum: 100; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherDailyHighTempX"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: wdHY; width: 58; height: 30; value: Config.weatherDailyHighTempY; minimum: 0; maximum: 150; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyHighTempY"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: wdHF; width: 58; height: 30; value: Config.weatherDailyHighTempFontSize; minimum: 6; maximum: 32; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyHighTempFontSize"; settingsObject: settings; saveOnEdit: true }
                }
                Row { visible: host.currentOtherTab === 3 && host.currentOtherSubTab === 3; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ночная температура"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField { id: wdLX; width: 58; height: 30; value: Config.weatherDailyLowTempX; minimum: -100; maximum: 100; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhFormattedNumbersOnly; targetObject: Config; targetProperty: "weatherDailyLowTempX"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: wdLY; width: 58; height: 30; value: Config.weatherDailyLowTempY; minimum: 0; maximum: 180; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyLowTempY"; settingsObject: settings; saveOnEdit: true }
                    SettingsNumberField { id: wdLF; width: 58; height: 30; value: Config.weatherDailyLowTempFontSize; minimum: 6; maximum: 32; step: 1; wheelStep: 1; compact: true; fieldWidth: 58; fieldFontSize: 10; inputMethodHints: Qt.ImhDigitsOnly; targetObject: Config; targetProperty: "weatherDailyLowTempFontSize"; settingsObject: settings; saveOnEdit: true }
                }
}

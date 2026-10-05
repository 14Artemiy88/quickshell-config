import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentOtherTab === 6
    width: parent ? parent.width : 0
    spacing: 10

                Text {
                    visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1
                    text: "Сеть"
                    color: Config.accent
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(14)
                }

                Text {
                    visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1
                    text: "Отображение сетевого трафика и общий интервал system monitor"
                    color: Config.textMuted
                    font.family: Config.settingsFont
                    font.pixelSize: Config.settingsUiSize(10)
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Row {
                    visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1
                    width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Интервал обновления данных (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField {
    id: networkIntervalField
    width: 100
    height: 30
    value: Config.systemMonitorInterval
    minimum: 200
    maximum: 10000
    step: 100
    wheelStep: 100
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "systemMonitorInterval"
    settingsObject: root.settings
    saveOnEdit: true
}
                }

                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Отступ блока слева/справа"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField {
    id: networkPaddingField
    width: 100
    height: 30
    value: Config.networkHorizontalPadding
    minimum: 0
    maximum: 40
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "networkHorizontalPadding"
    settingsObject: root.settings
    saveOnEdit: true
}
                }
                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Отступ иконки слева"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField {
    id: networkIconPaddingField
    width: 100
    height: 30
    value: Config.networkIconLeftPadding
    minimum: 0
    maximum: 40
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "networkIconLeftPadding"
    settingsObject: root.settings
    saveOnEdit: true
}
                }
                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Ширина колонки иконки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField {
    id: networkIconColumnWidthField
    width: 100
    height: 30
    value: Config.networkIconColumnWidth
    minimum: 16
    maximum: 80
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "networkIconColumnWidth"
    settingsObject: root.settings
    saveOnEdit: true
}
                }

                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    SettingsCheckBox { width: 210; height: 30; text: "Показывать Upload"; checked: Config.networkShowUpload; onToggled: { Config.networkShowUpload=checked; settings.save() } }
                }
                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    SettingsCheckBox { width: 210; height: 30; text: "Показывать Download"; checked: Config.networkShowDownload; onToggled: { Config.networkShowDownload=checked; settings.save() } }
                }

                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Высота строки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField {
    id: networkRowHeightField
    width: 100
    height: 30
    value: Config.networkRowHeight
    minimum: 12
    maximum: 60
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "networkRowHeight"
    settingsObject: root.settings
    saveOnEdit: true
}
                }
                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Расстояние между строками"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField {
    id: networkRowSpacingField
    width: 100
    height: 30
    value: Config.networkRowSpacing
    minimum: 0
    maximum: 30
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "networkRowSpacing"
    settingsObject: root.settings
    saveOnEdit: true
}
                }
                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Размер иконки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField {
    id: networkIconSizeField
    width: 100
    height: 30
    value: Config.networkIconSize
    minimum: 8
    maximum: 40
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "networkIconSize"
    settingsObject: root.settings
    saveOnEdit: true
}
                }
                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Размер текста"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField {
    id: networkFontSizeField
    width: 100
    height: 30
    value: Config.networkValueFontSize
    minimum: 8
    maximum: 32
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "networkValueFontSize"
    settingsObject: root.settings
    saveOnEdit: true
}
                }
                Row { visible: host.currentOtherTab === 6 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
                    Text { width: 210; text: "Отступ значений справа"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
                    SettingsNumberField {
    id: networkRightPaddingField
    width: 100
    height: 30
    value: Config.networkRightPadding
    minimum: 0
    maximum: 40
    step: 1
    wheelStep: 1
    decimals: 0
    compact: true
    fieldWidth: 100
    fieldFontSize: 11
    inputMethodHints: Qt.ImhDigitsOnly
    targetObject: Config
    targetProperty: "networkRightPadding"
    settingsObject: root.settings
    saveOnEdit: true
}
                }
}

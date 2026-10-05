import QtQuick
import QtQuick.Controls
import "../../.."
import "../primitives"

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentOtherTab === 7
    width: parent ? parent.width : 0
    spacing: 10

// -------------------- Volume --------------------
Text { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; text: "Иконки громкости"; color: Config.settingsSubheading; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(10) }
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Громкость"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeIconField; width: 100; height: 30; text: Config.volumeIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (volumeIconField.activeFocus || volumeIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } onEditingFinished: { Config.volumeIcon=text; settings.save() } Connections { target: Config; function onVolumeIconChanged(){volumeIconField.text=Config.volumeIcon} } }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Без звука"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: volumeMutedIconField; width: 100; height: 30; text: Config.volumeMutedIcon; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(12); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; background: Rectangle { color: Config.settingsBackground; border.color: (volumeMutedIconField.activeFocus || volumeMutedIconField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 } onEditingFinished: { Config.volumeMutedIcon=text; settings.save() } Connections { target: Config; function onVolumeMutedIconChanged(){volumeMutedIconField.text=Config.volumeMutedIcon} } }
}

Text {
    visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0
    text: "Громкость"
    color: Config.accent
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(14)
}
Text {
    visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0
    text: "Основная полоса и дополнительные аудиопотоки"
    color: Config.settingsSubheading
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(10)
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Интервал опроса громкости (мс)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeUpdateField
        label: ""
        value: Config.volumeUpdateInterval
        minimum: 50
        maximum: 5000
        step: 10
        wheelStep: 10
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeUpdateInterval"
        settingsObject: settings
        saveOnEdit: true
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Высота основной строки"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeMainRowHeightField
        label: ""
        value: Config.volumeMainRowHeight
        minimum: 20
        maximum: 80
        step: 1
        wheelStep: 1
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeMainRowHeight"
        settingsObject: settings
        saveOnEdit: true
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Высота строк потоков"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeStreamRowHeightField
        label: ""
        value: Config.volumeStreamRowHeight
        minimum: 12
        maximum: 60
        step: 1
        wheelStep: 1
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeStreamRowHeight"
        settingsObject: settings
        saveOnEdit: true
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Расстояние между потоками"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeStreamSpacingField
        label: ""
        value: Config.volumeStreamSpacing
        minimum: 0
        maximum: 20
        step: 1
        wheelStep: 1
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeStreamSpacing"
        settingsObject: settings
        saveOnEdit: true
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 0; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Отступ блока слева/справа"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeHorizontalPaddingField
        label: ""
        value: Config.volumeHorizontalPadding
        minimum: 0
        maximum: 40
        step: 1
        wheelStep: 1
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeHorizontalPadding"
        settingsObject: settings
        saveOnEdit: true
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Отступ блока сверху/снизу"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeVerticalPaddingField
        label: ""
        value: Config.volumeVerticalPadding
        minimum: 0
        maximum: 40
        step: 1
        wheelStep: 1
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeVerticalPadding"
        settingsObject: settings
        saveOnEdit: true
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Ширина основной полосы"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeMainTrackWidthField
        label: ""
        value: Config.volumeMainTrackWidth
        minimum: 40
        maximum: 1000
        step: 1
        wheelStep: 1
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeMainTrackWidth"
        settingsObject: settings
        saveOnEdit: true
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Высота полосы громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeMainTrackHeightField
        label: ""
        value: Config.volumeMainTrackHeight
        minimum: 1
        maximum: 30
        step: 1
        wheelStep: 1
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeMainTrackHeight"
        settingsObject: settings
        saveOnEdit: true
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Высота полос потоков"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeStreamTrackHeightField
        label: ""
        value: Config.volumeStreamTrackHeight
        minimum: 1
        maximum: 20
        step: 1
        wheelStep: 1
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeStreamTrackHeight"
        settingsObject: settings
        saveOnEdit: true
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Смещение основной полосы Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeMainTrackOffsetField
        label: ""
        value: Config.volumeMainTrackOffsetY
        minimum: -30
        maximum: 30
        step: 1
        wheelStep: 1
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeMainTrackOffsetY"
        settingsObject: settings
        saveOnEdit: true
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
    SettingsCheckBox { width: 210; height: 30; text: "Показывать дополнительные потоки"; checked: Config.volumeShowStreams; onToggled: { Config.volumeShowStreams=checked; settings.save() } }
}

Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Смещение полос потоков Y"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeStreamTrackOffsetField
        label: ""
        value: Config.volumeStreamTrackOffsetY
        minimum: -20
        maximum: 20
        step: 1
        wheelStep: 1
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeStreamTrackOffsetY"
        settingsObject: settings
        saveOnEdit: true
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Ширина иконки громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeMainIconWidthField
        label: ""
        value: Config.volumeMainIconWidth
        minimum: 16
        maximum: 80
        step: 1
        wheelStep: 1
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeMainIconWidth"
        settingsObject: settings
        saveOnEdit: true
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Размер текста потоков"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeStreamLabelFontField
        label: ""
        value: Config.volumeStreamLabelFontSize
        minimum: 8
        maximum: 32
        step: 1
        wheelStep: 1
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeStreamLabelFontSize"
        settingsObject: settings
        saveOnEdit: true
    }
}
Row { visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 2; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Радиус полос громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeTrackRadiusField
        label: ""
        value: Config.volumeTrackRadius
        minimum: 0
        maximum: 20
        step: 1
        wheelStep: 1
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeTrackRadius"
        settingsObject: settings
        saveOnEdit: true
    }
}

Text {
    visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 3
    text: "Адаптивные блоки"
    color: Config.accent
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(12)
}

Text {
    visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 3
    text: "Высота блока автоматически растёт по содержимому в пределах этих ограничений."
    color: Config.textMuted
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(9)
    wrapMode: Text.WordWrap
    width: parent.width
}

Row { width: parent.width; height: 30; spacing: 8
    visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 3
    Text { width: 210; text: "Минимальная высота громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeMinHeightField
        label: ""
        value: Config.volumeMinHeight
        minimum: 30
        maximum: 1000
        step: 1
        wheelStep: 1
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeMinHeight"
        settingsObject: settings
        saveOnEdit: true
    }
}

Row { width: parent.width; height: 30; spacing: 8
    visible: host.currentOtherTab === 7 && host.currentOtherSubTab === 3
    Text { width: 210; text: "Максимальная высота громкости"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsNumberField {
        id: volumeMaxHeightField
        label: ""
        value: Config.volumeMaxHeight
        minimum: 100
        maximum: 2000
        step: 1
        wheelStep: 1
        labelWidth: 0
        fieldWidth: 100
        compact: true
        targetObject: Config
        targetProperty: "volumeMaxHeight"
        settingsObject: settings
        saveOnEdit: true
    }
}

}

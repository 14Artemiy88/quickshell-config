import QtQuick
import QtQuick.Controls
import "../.."

Column {
    id: root

    property var host
    property var settings: Settings

    visible: host && host.currentOtherTab === 4
    width: parent ? parent.width : 0
    spacing: 10

Text {
    visible: host.currentOtherTab === 4 && host.currentOtherSubTab === 0
    text: "CAVA"
    color: Config.accent
    font.family: Config.settingsFont
    font.pixelSize: Config.settingsUiSize(14)
}

Row {
    visible: host.currentOtherTab === 4 && host.currentOtherSubTab === 0
    width: parent.width
    height: 30
    spacing: 8

    Text {
        width: 210
        text: "Количество полос CAVA"
        color: Config.text
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
        verticalAlignment: Text.AlignVCenter
    }

    SettingsTextField {
        id: cavaBarsField
        width: 100
        height: 30
        text: String(Config.cavaBars)
        color: Config.text
        selectionColor: Config.accent
        selectedTextColor: Config.black
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
        horizontalAlignment: Text.AlignHCenter
        activeFocusOnTab: true
        inputMethodHints: Qt.ImhDigitsOnly
        background: Rectangle {
            color: Config.settingsBackground
            border.color: (cavaBarsField.activeFocus || cavaBarsField.pointerHovered) ? Config.accent : Config.baseColor
            border.width: 1
            radius: 4
        }
        function applyValue() {
            var n = Number(text)
            if (!isFinite(n)) {
                text = String(Config.cavaBars)
                return
            }
            n = Math.max(8, Math.min(120, Math.round(n)))
            Config.cavaBars = n
            text = String(n)
            settings.save()
        }
        onEditingFinished: applyValue()

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: wheel => {
                var n = Math.max(8, Math.min(120, Number(Config.cavaBars) + host.wheelDelta(wheel, 1)))
                Config.cavaBars = n
                cavaBarsField.text = String(n)
                settings.save()
                wheel.accepted = true
            }
        }
    }
}

Row {
    visible: host.currentOtherTab === 4 && host.currentOtherSubTab === 0
    width: parent.width
    height: 30
    spacing: 8

    Text {
        width: 210
        text: "Частота обновления CAVA (FPS)"
        color: Config.text
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
        verticalAlignment: Text.AlignVCenter
    }

    SettingsTextField {
        id: cavaFramerateField
        width: 100
        height: 30
        text: String(Config.cavaFramerate)
        color: Config.text
        selectionColor: Config.accent
        selectedTextColor: Config.black
        font.family: Config.settingsFont
        font.pixelSize: Config.settingsUiSize(11)
        horizontalAlignment: Text.AlignHCenter
        activeFocusOnTab: true
        inputMethodHints: Qt.ImhDigitsOnly
        background: Rectangle {
            color: Config.settingsBackground
            border.color: (cavaFramerateField.activeFocus || cavaFramerateField.pointerHovered) ? Config.accent : Config.baseColor
            border.width: 1
            radius: 4
        }
        function applyValue() {
            var n = Number(text)
            if (!isFinite(n)) { text = String(Config.cavaFramerate); return }
            n = Math.max(1, Math.min(120, Math.round(n)))
            Config.cavaFramerate = n
            text = String(n)
            settings.save()
        }
        onEditingFinished: applyValue()
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: wheel => {
                var n = Math.max(1, Math.min(120, Number(Config.cavaFramerate) + host.wheelDelta(wheel, 1)))
                Config.cavaFramerate = n
                cavaFramerateField.text = String(n)
                settings.save()
                wheel.accepted = true
            }
        }
        Connections {
            target: Config
            function onCavaFramerateChanged() { cavaFramerateField.text = String(Config.cavaFramerate) }
        }
    }
}

Row { visible: host.currentOtherTab === 4 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Зазор между слотами CAVA"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: cavaRowSpacingField; width: 100; height: 30; text: String(Config.cavaRowSpacing); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhDigitsOnly; background: Rectangle { color: Config.settingsBackground; border.color: (cavaRowSpacingField.activeFocus || cavaRowSpacingField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.cavaRowSpacing;n=Math.max(0,Math.min(20,Math.round(n)));Config.cavaRowSpacing=n;text=String(n);settings.save()}
        onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{cavaRowSpacingField.applyValue(Config.cavaRowSpacing+host.wheelDelta(wheel, 1));wheel.accepted=true}} Connections{target:Config;function onCavaRowSpacingChanged(){cavaRowSpacingField.text=String(Config.cavaRowSpacing)}}
    }
}
Row { visible: host.currentOtherTab === 4 && host.currentOtherSubTab === 1; width: parent.width; height: 30; spacing: 8
    Text { width: 210; text: "Ширина полоски (% слота)"; color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); verticalAlignment: Text.AlignVCenter }
    SettingsTextField { id: cavaBarWidthRatioField; width: 100; height: 30; text: Number(Config.cavaBarWidthRatio).toFixed(2); color: Config.text; font.family: Config.settingsFont; font.pixelSize: Config.settingsUiSize(11); horizontalAlignment: Text.AlignHCenter; activeFocusOnTab: true; inputMethodHints: Qt.ImhNone; background: Rectangle { color: Config.settingsBackground; border.color: (cavaBarWidthRatioField.activeFocus || cavaBarWidthRatioField.pointerHovered) ? Config.accent : Config.baseColor; border.width: 1; radius: 4 }
        function applyValue(v){var n=Number(v);if(!isFinite(n))n=Config.cavaBarWidthRatio;n=Math.max(0.05,Math.min(1,n));Config.cavaBarWidthRatio=n;text=Number(n).toFixed(2);settings.save()}
        onEditingFinished:applyValue(text);MouseArea{anchors.fill:parent;acceptedButtons:Qt.NoButton;onWheel:wheel=>{cavaBarWidthRatioField.applyValue(Config.cavaBarWidthRatio+host.wheelDelta(wheel, 0.05));wheel.accepted=true}} Connections{target:Config;function onCavaBarWidthRatioChanged(){cavaBarWidthRatioField.text=Number(Config.cavaBarWidthRatio).toFixed(2)}}
    }
}
}

import QtQuick

import "../../.."

Item {
    id: root

    property string label: ""
    property real value: 0
    property real minimum: -Infinity
    property real maximum: Infinity
    property real step: 1
    property real wheelStep: root.step
    property int shiftWheelMultiplier: 10
    property int decimals: 0
    property int labelWidth: 210
    property int fieldWidth: 100
    property int inputMethodHints: Qt.ImhDigitsOnly
    property bool compact: false
    property int fieldFontSize: 11
    property var targetObject: null
    property string targetProperty: ""
    property var settingsObject: null
    property bool saveOnEdit: false
    property var valueWriter: null
    property bool pointerHovered: field.pointerHovered

    signal valueEdited(real value)

    width: root.compact
        ? root.fieldWidth
        : (parent ? parent.width : root.labelWidth + 8 + root.fieldWidth)
    height: 30

    function clampValue(raw, fallback) {
        var n = Number(raw)
        if (!isFinite(n))
            n = Number(fallback)
        if (!isFinite(n))
            n = 0

        n = Math.max(
            root.minimum,
            Math.min(root.maximum, n)
        )

        if (root.decimals > 0) {
            var factor = Math.pow(10, root.decimals)
            n = Math.round(n * factor) / factor
        } else {
            n = Math.round(n)
        }

        return n
    }

    function formatValue(raw) {
        var n = Number(raw)
        if (!isFinite(n))
            n = 0

        return root.decimals > 0
            ? n.toFixed(root.decimals)
            : String(Math.round(n))
    }

    function currentFallback() {
        if (root.targetObject && root.targetProperty !== "") {
            var targetValue = Number(
                root.targetObject[root.targetProperty]
            )
            if (isFinite(targetValue))
                return targetValue
        }

        var currentValue = Number(field.text)
        return isFinite(currentValue) ? currentValue : root.value
    }

    function commit(raw) {
        var n = root.clampValue(
            raw,
            root.currentFallback()
        )

        if (root.valueWriter) {
            root.valueWriter(n)
        } else if (root.targetObject && root.targetProperty !== "") {
            root.targetObject[root.targetProperty] = n
        } else {
            root.value = n
        }

        field.text = root.formatValue(n)
        root.valueEdited(n)

        if (
            root.saveOnEdit &&
            root.settingsObject &&
            root.settingsObject.save
        ) {
            root.settingsObject.save()
        }
    }

    function commitFromWheel(direction, multiplier) {
        var current = Number(field.text)
        if (!isFinite(current))
            current = root.currentFallback()

        root.commit(
            current +
            direction *
            root.wheelStep *
            multiplier
        )
    }

    Row {
        anchors.fill: parent
        spacing: 8

        Text {
            width: root.compact ? 0 : root.labelWidth
            visible: !root.compact
            text: root.label
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(root.fieldFontSize)
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        SettingsInputField {
            id: field

            width: root.fieldWidth
            height: 30
            text: root.formatValue(root.value)
            color: Config.text
            font.family: Config.settingsFont
            font.pixelSize: Config.settingsUiSize(root.fieldFontSize)
            horizontalAlignment: Text.AlignHCenter
            activeFocusOnTab: true
            inputMethodHints: root.inputMethodHints

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton

                onWheel: wheel => {
                    var direction = wheel.angleDelta.y > 0 ? 1 : -1
                    var multiplier =
                        (wheel.modifiers & Qt.ShiftModifier)
                        ? root.shiftWheelMultiplier
                        : 1

                    root.commitFromWheel(
                        direction,
                        multiplier
                    )

                    wheel.accepted = true
                }
            }

            onEditingFinished: root.commit(text)
        }
    }

    Connections {
        target: root

        function onValueChanged() {
            field.text = root.formatValue(root.value)
        }
    }
}

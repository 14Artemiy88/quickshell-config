import QtQuick
import "../../.."

// Shared two-column settings row: a consistent label and one or more controls.
// Control objects are placed in the right-hand slot through the default alias.
Row {
    id: root

    property string label: ""
    // Exposes the visual row label to nested searchable controls without
    // turning this layout container into a search result itself.
    readonly property string settingsSearchRowLabel: root.label
    property real labelWidth: 210
    property real labelFontSize: 11
    // Keep the legacy 30px label box centered inside taller rows.
    property real labelHeight: 30
    property int labelElide: Text.ElideNone
    property color labelColor: Config.text
    property real controlSpacing: 0

    default property alias controlData: controlLayout.data

    Item {
        width: root.labelWidth
        height: root.height

        SettingsLabel {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: root.labelHeight
            text: root.label
            settingsFontSize: root.labelFontSize
            color: root.labelColor
            elide: root.labelElide
        }
    }

    Item {
        width: Math.max(0, root.width - root.labelWidth - root.spacing)
        height: root.height

        Row {
            id: controlLayout
            width: parent.width
            height: parent.height
            spacing: root.controlSpacing
        }
    }
}

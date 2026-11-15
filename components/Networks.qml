import QtQuick
import QtQuick.Controls
import "primitives" as Primitives
import "../js/networks/NetworkLayout.js" as NetworkLayout
import ".."

Primitives.ModuleFrame {
    id: root
    moduleName: "networks"
    property var monitor
    property int maxContentHeight: 171
    property int rowHeight: 32
    property int rowSpacing: 4
    property int horizontalPadding: 8
    property int verticalPadding: 8
    property int emptyStateHeight: 32

    readonly property var networkModel: root.monitor?.data?.network ?? []
    readonly property int networkCount: Array.isArray(root.networkModel) ? root.networkModel.length : 0
    readonly property int contentDrivenHeight: NetworkLayout.panelHeight(
        root.networkCount,
        root.maxContentHeight,
        root.rowHeight,
        root.rowSpacing,
        root.verticalPadding,
        root.emptyStateHeight
    )

    implicitHeight: root.contentDrivenHeight
    clip: true

    ScrollView {
        id: networkScroll
        anchors.fill: parent
        leftPadding: root.horizontalPadding
        rightPadding: root.horizontalPadding
        topPadding: root.verticalPadding
        bottomPadding: root.verticalPadding
        clip: true
        contentWidth: availableWidth
        contentHeight: networkColumn.implicitHeight
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: networkColumn.implicitHeight > availableHeight + 1
            ? ScrollBar.AsNeeded
            : ScrollBar.AlwaysOff

        Column {
            id: networkColumn
            width: networkScroll.availableWidth
            spacing: root.rowSpacing

            Repeater {
                model: root.networkModel

                delegate: NetworkConnectionButton {
                    width: networkColumn.width
                    height: root.rowHeight
                    implicitHeight: root.rowHeight
                    network: modelData
                }
            }

            Text {
                visible: root.networkCount === 0
                width: networkColumn.width
                height: visible ? root.emptyStateHeight : 0
                text: "Нет сохранённых подключений"
                color: Config.textDisabled
                font.family: Config.settingsFont
                font.pixelSize: Config.uiFontSize(12)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }
}

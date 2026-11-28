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
    // Keep the existing regular layout as the visual baseline. Compact and
    // wide modes only adjust density and add useful state context when there
    // is enough horizontal room.
    property int rowHeight: 32
    property int rowSpacing: 4
    property int horizontalPadding: 8
    property int verticalPadding: 8
    property int emptyStateHeight: 32

    readonly property int effectiveRowHeight: root.compactPresentation ? 30
        : root.widePresentation ? 34 : root.rowHeight
    readonly property int effectiveRowSpacing: root.compactPresentation ? 3
        : root.widePresentation ? 6 : root.rowSpacing
    readonly property int effectiveHorizontalPadding: root.compactPresentation ? 6
        : root.widePresentation ? 12 : root.horizontalPadding
    readonly property int effectiveVerticalPadding: root.compactPresentation ? 6
        : root.widePresentation ? 10 : root.verticalPadding
    readonly property int effectiveEmptyStateHeight: root.compactPresentation ? 30
        : root.widePresentation ? 34 : root.emptyStateHeight

    readonly property int networkCount: networkRows.count
    readonly property int contentDrivenHeight: NetworkLayout.panelHeight(
        root.networkCount,
        root.maxContentHeight,
        root.effectiveRowHeight,
        root.effectiveRowSpacing,
        root.effectiveVerticalPadding,
        root.effectiveEmptyStateHeight
    )

    function findNetworkRow(name) {
        for (let i = 0; i < networkRows.count; i++) {
            if (networkRows.get(i).name === name)
                return i;
        }
        return -1;
    }

    // SystemMonitor replaces its complete JSON object on every polling cycle.
    // Keep a persistent ListModel and diff by connection name so unchanged
    // delegates retain their identity instead of replaying entry animations.
    function syncNetworkRows() {
        const incoming = root.monitor && root.monitor.data && Array.isArray(root.monitor.data.network)
            ? root.monitor.data.network : [];
        const incomingByName = Object.create(null);

        for (let i = 0; i < incoming.length; i++) {
            const item = incoming[i];
            const name = item && item.name !== undefined ? String(item.name) : "";
            if (!name)
                continue;

            const type = item.type !== undefined ? String(item.type) : "";
            const status = item.status === "on" ? "on" : "off";
            incomingByName[name] = true;

            const existingIndex = root.findNetworkRow(name);
            if (existingIndex < 0) {
                networkRows.append({
                    name: name,
                    type: type,
                    status: status,
                    removing: false
                });
                continue;
            }

            const existing = networkRows.get(existingIndex);
            if (existing.removing)
                networkRows.setProperty(existingIndex, "removing", false);
            if (existing.type !== type)
                networkRows.setProperty(existingIndex, "type", type);
            if (existing.status !== status)
                networkRows.setProperty(existingIndex, "status", status);
        }

        // Do not destroy a removed delegate immediately. Keep the last known
        // row snapshot in this UI-owned ListModel while the delegate runs its
        // own exit animation and reports completion.
        for (let i = networkRows.count - 1; i >= 0; i--) {
            const existing = networkRows.get(i);
            if (!incomingByName[existing.name] && !existing.removing) {
                // The source no longer contains the connection. Keep a full
                // snapshot in this UI-owned model until the delegate finishes
                // its explicit exit animation and signals removalFinished.
                networkRows.setProperty(i, "removing", true);
            }
        }
    }

    function finishNetworkRowRemoval(name) {
        const index = root.findNetworkRow(name);
        if (index >= 0 && networkRows.get(index).removing)
            networkRows.remove(index);
    }

    readonly property bool internalAnimationsEnabled: Config.animationNetworkMorphProfile !== "none"
    readonly property int internalAnimationDuration: root.internalAnimationsEnabled ? Config.animationNetworkMorphDuration : 0

    implicitHeight: root.contentDrivenHeight
    Behavior on implicitHeight {
        enabled: root.internalAnimationDuration > 0
        NumberAnimation {
            duration: root.internalAnimationDuration
            easing.type: Config.animationEasingType(Config.animationNetworkMorphProfile, root.contentDrivenHeight > root.implicitHeight ? "enter" : "exit")
            easing.bezierCurve: Config.animationBezierCurve(Config.animationNetworkMorphProfile, root.contentDrivenHeight > root.implicitHeight ? "enter" : "exit")
        }
    }
    clip: true

    Component.onCompleted: Qt.callLater(root.syncNetworkRows)
    onMonitorChanged: Qt.callLater(root.syncNetworkRows)

    ListModel {
        id: networkRows
    }

    Connections {
        target: root.monitor
        function onDataChanged() { root.syncNetworkRows() }
    }

    ScrollView {
        id: networkScroll
        anchors.fill: parent
        leftPadding: root.effectiveHorizontalPadding
        rightPadding: root.effectiveHorizontalPadding
        topPadding: root.effectiveVerticalPadding
        bottomPadding: root.effectiveVerticalPadding
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
            spacing: root.effectiveRowSpacing

            move: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: root.internalAnimationDuration
                    easing.type: Config.animationEasingType(Config.animationNetworkMorphProfile, root.contentDrivenHeight > root.implicitHeight ? "enter" : "exit")
                    easing.bezierCurve: Config.animationBezierCurve(Config.animationNetworkMorphProfile, root.contentDrivenHeight > root.implicitHeight ? "enter" : "exit")
                }
            }

            Repeater {
                model: networkRows

                delegate: NetworkConnectionButton {
                    width: networkColumn.width
                    height: root.effectiveRowHeight
                    implicitHeight: root.effectiveRowHeight
                    rowHeight: root.effectiveRowHeight
                    presentationMode: root.presentationMode
                    onRemovalFinished: function(networkName) {
                        root.finishNetworkRowRemoval(networkName);
                    }
                }
            }

            Text {
                visible: root.networkCount === 0
                width: networkColumn.width
                height: visible ? root.effectiveEmptyStateHeight : 0
                text: "Нет сохранённых подключений"
                color: Config.textDisabled
                font.family: Config.settingsFontFamily
                font.pixelSize: Config.uiFontSize(12)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
    }
}

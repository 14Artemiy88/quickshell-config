import QtQuick
import Quickshell
import ".."
import "primitives" as Primitives

Item {
    id: root

    required property string name
    required property string type
    required property string status
    required property bool removing
    property real rowProgress: 0
    property bool removalSignalSent: false
    property bool transitionInitialized: false
    property int rowHeight: 32
    property string presentationMode: "regular"
    readonly property bool compactPresentation: root.presentationMode === "compact"
    readonly property bool widePresentation: root.presentationMode === "wide"
    readonly property bool active: root.status === "on"
    readonly property bool hovered: buttonSurface.hovered
    readonly property string rowAnimationProfile: Config.animationNetworkMorphProfile
    readonly property int rowTransitionDuration: rowAnimationProfile === "none" ? 0 : Config.animationNetworkMorphDuration

    signal removalFinished(string networkName)

    implicitWidth: 280
    implicitHeight: 32

    function toggleConnection() {
        if (!root.name)
            return;
        Quickshell.execDetached([
            "nmcli", "--ask", "con",
            root.active ? "down" : "up",
            root.name
        ]);
    }

    // The ListModel retains the row snapshot while this delegate owns its
    // render progress. This prevents a not-yet-created delegate from leaving
    // the model with a permanently collapsed rowProgress role.
    function finishExitTransition() {
        if (!root.removing || root.removalSignalSent)
            return;
        root.rowProgress = 0;
        root.removalSignalSent = true;
        root.removalFinished(root.name);
    }

    function startEntryTransition() {
        exitAnimation.stop();
        entryAnimation.stop();
        root.removalSignalSent = false;
        if (root.rowTransitionDuration <= 0) {
            root.rowProgress = 1;
            return;
        }
        if (root.rowProgress >= 0.999) {
            root.rowProgress = 1;
            return;
        }
        entryAnimation.start();
    }

    function startExitTransition() {
        entryAnimation.stop();
        exitAnimation.stop();
        if (root.rowTransitionDuration <= 0 || root.rowProgress <= 0.001) {
            root.finishExitTransition();
            return;
        }
        exitAnimation.start();
    }

    onRemovingChanged: {
        if (!root.transitionInitialized)
            return;
        if (root.removing)
            root.startExitTransition();
        else
            root.startEntryTransition();
    }

    Component.onCompleted: {
        root.transitionInitialized = true;
        if (root.removing) {
            // A tombstone that reached the Repeater before delegate creation
            // still receives a complete, visible exit lifecycle.
            root.rowProgress = 1;
            root.startExitTransition();
        } else {
            root.rowProgress = 0;
            root.startEntryTransition();
        }
    }

    NumberAnimation {
        id: entryAnimation
        target: root
        property: "rowProgress"
        to: 1
        duration: root.rowTransitionDuration
        easing.type: Config.animationEasingType(root.rowAnimationProfile, "enter")
        easing.bezierCurve: Config.animationBezierCurve(root.rowAnimationProfile, "enter")
    }

    NumberAnimation {
        id: exitAnimation
        target: root
        property: "rowProgress"
        to: 0
        duration: root.rowTransitionDuration
        easing.type: Config.animationEasingType(root.rowAnimationProfile, "exit")
        easing.bezierCurve: Config.animationBezierCurve(root.rowAnimationProfile, "exit")
        onFinished: root.finishExitTransition()
    }

    Primitives.MorphGeometry {
        id: networkRowMorph
        // Keep the delegate slot stable while its visible content expands
        // from / collapses toward the vertical center line in each mode.
        fromGeometry: Qt.rect(0, parent.height / 2, parent.width, 0)
        toGeometry: Qt.rect(0, 0, parent.width, parent.height)
        progress: root.rowProgress
        // The persistent ListModel role is animated by the rowProgress Behavior
        // above; this primitive only renders the resulting geometry.
        animationDuration: 0
        clip: true

        // Keep the row content at its natural mode-specific height. Only the
        // MorphGeometry viewport changes size, clipping content from its center line.
        // This gives a true geometric collapse/expand instead of fading or
        // scaling the button surface itself.
        Item {
            id: rowContent
            width: parent.width
            height: root.rowHeight
            y: (networkRowMorph.height - height) / 2

            Primitives.HoverButtonSurface {
                id: buttonSurface
                anchors.fill: parent
                interactionEnabled: !root.removing
                backgroundColor: root.active ? Config.activeNetworkBackground : Config.transparent
                borderColor: Config.transparent
                borderWidth: 1
                hoverBorderEnabled: true
                hoverBorderColor: Config.accent
                hoverBorderWidth: 1
                cornerRadius: 7
                onClicked: root.toggleConnection()

                Row {
                    id: rowLayout
                    anchors.fill: parent
                    anchors.leftMargin: root.compactPresentation ? 6 : root.widePresentation ? 12 : 8
                    anchors.rightMargin: root.compactPresentation ? 6 : root.widePresentation ? 12 : 8
                    spacing: root.widePresentation ? 8 : 0

                    Row {
                        id: connectionIdentity
                        width: Math.max(0, rowLayout.width - rowStatus.width - (root.widePresentation ? rowLayout.spacing : 0))
                        height: parent.height
                        spacing: root.compactPresentation ? 4 : 7

                        Text {
                            id: typeIcon
                            width: root.compactPresentation ? 22 : 27
                            height: parent.height
                            text: root.type
                            color: root.active ? Config.accent : Config.textDisabled
                            font.pixelSize: Config.uiFontSize(root.compactPresentation ? 18 : 20)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            width: Math.max(0, parent.width - typeIcon.width - parent.spacing)
                            height: parent.height
                            text: root.name
                            color: root.active ? Config.textMuted : Config.textDisabled
                            font.pixelSize: Config.uiFontSize(root.compactPresentation ? 13 : 14)
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        id: rowStatus
                        readonly property bool hasStatusLabel: root.widePresentation
                        width: hasStatusLabel ? implicitWidth : 0
                        height: parent.height
                        visible: hasStatusLabel
                        text: root.active ? "Подключено" : "Отключено"
                        color: root.active ? Config.accent : Config.textDisabled
                        font.pixelSize: Config.uiFontSize(11)
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}

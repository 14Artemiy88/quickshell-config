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
    readonly property bool active: root.status === "on"
    readonly property bool hovered: buttonSurface.hovered
    readonly property int rowTransitionDuration: Config.animationDuration(220, "appearance")

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
        easing.type: Config.animationEasingType("standard", "enter")
    }

    NumberAnimation {
        id: exitAnimation
        target: root
        property: "rowProgress"
        to: 0
        duration: root.rowTransitionDuration
        easing.type: Config.animationEasingType("standard", "exit")
        onFinished: root.finishExitTransition()
    }

    Primitives.MorphGeometry {
        id: networkRowMorph
        // Keep the delegate's 32px slot stable while its visible content
        // expands from / collapses toward the vertical center line.
        fromGeometry: Qt.rect(0, parent.height / 2, parent.width, 0)
        toGeometry: Qt.rect(0, 0, parent.width, parent.height)
        progress: root.rowProgress
        // The persistent ListModel role is animated by the rowProgress Behavior
        // above; this primitive only renders the resulting geometry.
        animationDuration: 0
        clip: true

        // Keep the row content at its natural 32px height. Only the MorphGeometry
        // viewport changes size, clipping the fixed content from its center line.
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
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 7

                    Text {
                        id: typeIcon
                        width: 27
                        height: parent.height
                        text: root.type
                        color: root.active ? Config.accent : Config.textDisabled
                        font.pixelSize: Config.uiFontSize(20)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        width: Math.max(0, parent.width - typeIcon.width - parent.spacing)
                        height: parent.height
                        text: root.name
                        color: root.active ? Config.textMuted : Config.textDisabled
                        font.pixelSize: Config.uiFontSize(14)
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}

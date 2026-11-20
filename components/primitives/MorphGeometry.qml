import QtQuick
import "../.."

// Reusable geometry interpolator for shared-element morph transitions.
// Animate only `progress` from 0 (fromGeometry) to 1 (toGeometry).
// Position, size and corner radius stay synchronized on the same progress value.
Item {
    id: root

    property rect fromGeometry: Qt.rect(0, 0, 0, 0)
    property rect toGeometry: Qt.rect(0, 0, 0, 0)
    property real progress: 0
    property real fromRadius: 0
    property real toRadius: fromRadius
    property color surfaceColor: "transparent"
    property bool surfaceVisible: false
    property int animationDuration: 0
    property string animationProfile: "standard"
    property string animationPhase: "enter"
    property int animationEasing: Config.animationEasingType(root.animationProfile, root.animationPhase)
    property var animationBezierCurve: Config.animationBezierCurve(root.animationProfile, root.animationPhase)

    readonly property real normalizedProgress: Math.max(0, Math.min(1, Number(progress) || 0))
    readonly property real geometryX: fromGeometry.x + (toGeometry.x - fromGeometry.x) * normalizedProgress
    readonly property real geometryY: fromGeometry.y + (toGeometry.y - fromGeometry.y) * normalizedProgress
    readonly property real geometryWidth: Math.max(0, fromGeometry.width + (toGeometry.width - fromGeometry.width) * normalizedProgress)
    readonly property real geometryHeight: Math.max(0, fromGeometry.height + (toGeometry.height - fromGeometry.height) * normalizedProgress)
    readonly property real geometryRadius: Math.max(0, fromRadius + (toRadius - fromRadius) * normalizedProgress)

    x: geometryX
    y: geometryY
    width: geometryWidth
    height: geometryHeight

    Behavior on progress {
        enabled: root.animationDuration > 0
        NumberAnimation {
            duration: root.animationDuration
            easing.type: root.animationEasing
            easing.bezierCurve: root.animationBezierCurve
        }
    }

    default property alias contentData: contentHost.data

    Rectangle {
        anchors.fill: parent
        color: root.surfaceVisible ? root.surfaceColor : "transparent"
        radius: root.geometryRadius
        visible: root.surfaceVisible
        antialiasing: true
    }

    Item {
        id: contentHost
        anchors.fill: parent
    }
}

import QtQuick
import "../.."

Item {
    id: root
    property bool shown: true
    property string animationStyle: "fade"
    property int duration: Config.animationDuration(250, "appearance")
    readonly property bool running: showTransition.running || hideTransition.running

    default property alias contentData: contentHost.data

    Item {
        id: exitHost
        anchors.fill: parent
        x: 0
        y: 0

        Item {
            id: contentHost
            anchors.fill: parent
        visible: true
        enabled: root.shown

        transform: Translate {
            id: contentTransform
            x: 0
            y: 0
        }
        }
    }

    function hiddenX() {
        if (root.animationStyle === "slideLeft") return -root.width
        if (root.animationStyle === "slideRight") return root.width
        return 0
    }

    function hiddenY() {
        if (root.animationStyle === "slideUp") return -root.height
        if (root.animationStyle === "slideDown") return root.height
        return 0
    }

    function usesOpacity() {
        return root.animationStyle === "fade"
    }

    function usesHorizontalSlide() {
        return root.animationStyle === "slideLeft" || root.animationStyle === "slideRight"
    }

    function usesVerticalSlide() {
        return root.animationStyle === "slideUp" || root.animationStyle === "slideDown"
    }

    function animationAllowed() {
        return Config.animationsEnabled && Config.animationAppearanceEnabled && root.animationStyle !== "none" && root.duration > 0
    }

    function applyImmediate(visible) {
        showTransition.stop()
        hideTransition.stop()
        contentHost.visible = visible
        contentHost.enabled = visible
        exitHost.x = 0
        exitHost.y = 0
        contentTransform.x = visible ? 0 : hiddenX()
        contentTransform.y = visible ? 0 : hiddenY()
        contentHost.opacity = (visible || !usesOpacity()) ? 1 : 0
    }

    function startTransition() {
        var wasVisible = contentHost.visible
        showTransition.stop()
        hideTransition.stop()

        if (!animationAllowed()) {
            applyImmediate(root.shown)
            return
        }

        if (root.shown) {
            contentHost.visible = true
            contentHost.enabled = true
            exitHost.x = 0
            exitHost.y = 0
            if (!wasVisible) {
                contentTransform.x = hiddenX()
                contentTransform.y = hiddenY()
                contentHost.opacity = usesOpacity() ? 0 : 1
            }
            showTransition.start()
        } else {
            contentHost.visible = true
            contentHost.enabled = false
            exitHost.x = 0
            exitHost.y = 0
            hideTransition.start()
        }
    }

    ParallelAnimation {
        id: showTransition
        NumberAnimation {
            target: contentHost
            property: "opacity"
            to: 1
            duration: root.usesOpacity() ? root.duration : 0
            easing.type: Config.easingType()
        }
        NumberAnimation {
            target: contentTransform
            property: "x"
            to: 0
            duration: root.usesHorizontalSlide() ? root.duration : 0
            easing.type: Config.easingType()
        }
        NumberAnimation {
            target: contentTransform
            property: "y"
            to: 0
            duration: root.usesVerticalSlide() ? root.duration : 0
            easing.type: Config.easingType()
        }
        onFinished: {
            if (root.shown) {
                contentHost.visible = true
                contentHost.enabled = true
                contentTransform.x = 0
                contentTransform.y = 0
                if (root.usesOpacity()) contentHost.opacity = 1
            }
        }
    }

    ParallelAnimation {
        id: hideTransition
        NumberAnimation {
            target: contentHost
            property: "opacity"
            to: 0
            duration: root.usesOpacity() ? root.duration : 0
            easing.type: Config.easingType()
        }
        NumberAnimation {
            target: exitHost
            property: "x"
            to: root.hiddenX()
            duration: root.usesHorizontalSlide() ? root.duration : 0
            easing.type: Config.easingType()
        }
        NumberAnimation {
            target: exitHost
            property: "y"
            to: root.hiddenY()
            duration: root.usesVerticalSlide() ? root.duration : 0
            easing.type: Config.easingType()
        }
        onFinished: {
            if (!root.shown) {
                contentHost.visible = false
                contentHost.enabled = false
                exitHost.x = 0
                exitHost.y = 0
            }
        }
    }

    onShownChanged: startTransition()
    onAnimationStyleChanged: startTransition()
    onDurationChanged: startTransition()
    onWidthChanged: {
        if (!root.shown && !root.running) applyImmediate(false)
    }
    onHeightChanged: {
        if (!root.shown && !root.running) applyImmediate(false)
    }
    Component.onCompleted: {
        applyImmediate(root.shown)
    }
}

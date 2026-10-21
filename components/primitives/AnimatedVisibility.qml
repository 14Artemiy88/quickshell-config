import QtQuick
import "../.."

Item {
    id: root
    property bool shown: true
    property string animationStyle: "fade"
    property int duration: Config.animationDuration(250, "appearance")
    // Freeze style/duration for each in-flight transition. Settings can change
    // while a window is moving; applying new animation types mid-flight would
    // otherwise switch opacity/translation targets halfway through.
    property string activeAnimationStyle: "fade"
    property int activeDuration: 250
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
        if (root.activeAnimationStyle === "slideLeft") return -root.width
        if (root.activeAnimationStyle === "slideRight") return root.width
        return 0
    }

    function hiddenY() {
        if (root.activeAnimationStyle === "slideUp") return -root.height
        if (root.activeAnimationStyle === "slideDown") return root.height
        return 0
    }

    function usesOpacity() {
        return root.activeAnimationStyle === "fade"
    }

    function usesHorizontalSlide() {
        return root.activeAnimationStyle === "slideLeft" || root.activeAnimationStyle === "slideRight"
    }

    function usesVerticalSlide() {
        return root.activeAnimationStyle === "slideUp" || root.activeAnimationStyle === "slideDown"
    }

    function animationAllowed() {
        return Config.animationsEnabled && Config.animationAppearanceEnabled && root.activeAnimationStyle !== "none" && root.activeDuration > 0
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

    function handleAnimationStyleChange() {
        // Keep the active style until the current transition ends. The new style
        // is applied to the next transition without an opacity/position jump.
        if (root.running) return
        activeAnimationStyle = root.animationStyle
        activeDuration = root.duration
        applyImmediate(root.shown)
    }

    function handleDurationChange() {
        // Positive duration changes apply to the next transition. If animation
        // was disabled (or set to zero) while moving, settle immediately so the
        // window does not keep animating against the user's new preference.
        if (root.running) {
            if (root.duration <= 0 || !Config.animationsEnabled || !Config.animationAppearanceEnabled)
                applyImmediate(root.shown)
            return
        }
        activeDuration = root.duration
    }

    function handleAnimationAvailabilityChange() {
        // Do not rely only on the duration binding to notice a global toggle.
        // Some consumers may provide a fixed/custom duration. Turning animation
        // off must stop an already-running transition immediately in either case.
        if (root.running && (!Config.animationsEnabled || !Config.animationAppearanceEnabled))
            applyImmediate(root.shown)
    }

    Connections {
        target: Config
        function onAnimationsEnabledChanged() {
            root.handleAnimationAvailabilityChange()
        }
        function onAnimationAppearanceEnabledChanged() {
            root.handleAnimationAvailabilityChange()
        }
    }

    function startTransition() {
        var wasRunning = root.running
        var wasVisible = contentHost.visible
        if (!wasRunning) {
            activeAnimationStyle = root.animationStyle
            activeDuration = root.duration
        }
        showTransition.stop()
        hideTransition.stop()

        // Style or duration settings can change while the component is fully
        // hidden. Do not resurrect its content just to animate another exit.
        // This also refreshes the hidden endpoint after size/direction changes.
        if (!root.shown && !wasVisible) {
            applyImmediate(false)
            return
        }

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
            duration: root.usesOpacity() ? root.activeDuration : 0
            easing.type: Config.easingType()
        }
        NumberAnimation {
            target: contentTransform
            property: "x"
            to: 0
            duration: root.usesHorizontalSlide() ? root.activeDuration : 0
            easing.type: Config.easingType()
        }
        NumberAnimation {
            target: contentTransform
            property: "y"
            to: 0
            duration: root.usesVerticalSlide() ? root.activeDuration : 0
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
        // Slide transitions must keep the content opaque. A zero-duration
        // opacity animation to 0 used to make slide-out disappear instantly,
        // even though the host's position was meant to animate. Fade alone
        // owns opacity; slides animate the same Translate transform as entry.
        NumberAnimation {
            target: contentHost
            property: "opacity"
            to: root.usesOpacity() ? 0 : 1
            duration: root.usesOpacity() ? root.activeDuration : 0
            easing.type: Config.easingType()
        }
        NumberAnimation {
            target: contentTransform
            property: "x"
            to: root.hiddenX()
            duration: root.usesHorizontalSlide() ? root.activeDuration : 0
            easing.type: Config.easingType()
        }
        NumberAnimation {
            target: contentTransform
            property: "y"
            to: root.hiddenY()
            duration: root.usesVerticalSlide() ? root.activeDuration : 0
            easing.type: Config.easingType()
        }
        onFinished: {
            if (!root.shown) {
                contentHost.visible = false
                contentHost.enabled = false
                // Keep the translate at the hidden endpoint so the next show
                // starts from the same off-screen position. exitHost remains
                // anchored to the wrapper and is never the animated target.
                contentTransform.x = root.hiddenX()
                contentTransform.y = root.hiddenY()
                contentHost.opacity = root.usesOpacity() ? 0 : 1
                exitHost.x = 0
                exitHost.y = 0
            }
        }
    }

    onShownChanged: startTransition()
    onAnimationStyleChanged: handleAnimationStyleChange()
    onDurationChanged: handleDurationChange()
    onWidthChanged: {
        if (!root.shown && !root.running) {
            activeAnimationStyle = root.animationStyle
            activeDuration = root.duration
            applyImmediate(false)
        }
    }
    onHeightChanged: {
        if (!root.shown && !root.running) {
            activeAnimationStyle = root.animationStyle
            activeDuration = root.duration
            applyImmediate(false)
        }
    }
    Component.onCompleted: {
        activeAnimationStyle = root.animationStyle
        activeDuration = root.duration
        applyImmediate(root.shown)
    }
}

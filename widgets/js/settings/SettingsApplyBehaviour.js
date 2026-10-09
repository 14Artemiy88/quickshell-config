.pragma library

function apply(Config, o) {
        // General behaviour / update intervals
        if (o.animationsEnabled !== undefined) Config.animationsEnabled = !!o.animationsEnabled
        if (o.animationSpeed !== undefined) {
            var as = Number(o.animationSpeed)
            if (isFinite(as)) Config.animationSpeed = Math.max(0.25, Math.min(4.0, as))
        }
        if (o.animationEasing !== undefined) Config.animationEasing = String(o.animationEasing)
        var allowedVisibilityStyles = ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
        var legacyAnimationStyle = o.animationVisibilityStyle !== undefined ? String(o.animationVisibilityStyle) : ""
        if (allowedVisibilityStyles.indexOf(legacyAnimationStyle) < 0) legacyAnimationStyle = ""
        var animationStyleKeys = [
            "animationCalendarVisibilityStyle",
            "animationMopidyVisibilityStyle",
            "animationTimerVisibilityStyle",
            "animationSettingsVisibilityStyle"
        ]
        for (var ask = 0; ask < animationStyleKeys.length; ++ask) {
            var styleKey = animationStyleKeys[ask]
            var styleValue = o[styleKey] !== undefined ? String(o[styleKey]) : legacyAnimationStyle
            if (allowedVisibilityStyles.indexOf(styleValue) >= 0) Config[styleKey] = styleValue
        }
        if (o.animationAppearanceEnabled !== undefined) Config.animationAppearanceEnabled = !!o.animationAppearanceEnabled
        if (o.animationMovementEnabled !== undefined) Config.animationMovementEnabled = !!o.animationMovementEnabled
        if (o.animationSizeEnabled !== undefined) Config.animationSizeEnabled = !!o.animationSizeEnabled
        if (o.animationExpansionEnabled !== undefined) Config.animationExpansionEnabled = !!o.animationExpansionEnabled
        var animationNumberFields = [
            ["animationTimerOptionsDuration", 0, 5000],
            ["animationCalendarSlideDuration", 0, 5000],
            ["animationCalendarFadeDuration", 0, 5000]
        ]
        for (var af = 0; af < animationNumberFields.length; ++af) {
            var aname = animationNumberFields[af][0]
            if (o[aname] !== undefined) {
                var av = Number(o[aname])
                if (isFinite(av)) Config[aname] = Math.max(animationNumberFields[af][1], Math.min(animationNumberFields[af][2], Math.round(av)))
            }
        }
        if (o.systemMonitorInterval !== undefined) {
            var smi = Number(o.systemMonitorInterval)
            if (isFinite(smi)) Config.systemMonitorInterval = Math.max(200, Math.min(10000, Math.round(smi)))
        }
        if (o.cpuUpdateInterval !== undefined) {
            var cui = Number(o.cpuUpdateInterval)
            if (isFinite(cui)) Config.cpuUpdateInterval = Math.max(200, Math.min(10000, Math.round(cui)))
        }
        if (o.playerUpdateInterval !== undefined) {
            var pui = Number(o.playerUpdateInterval)
            if (isFinite(pui)) Config.playerUpdateInterval = Math.max(200, Math.min(10000, Math.round(pui)))
        }
        if (o.weatherNowIntervalMinutes !== undefined) {
            var wni = Number(o.weatherNowIntervalMinutes)
            if (isFinite(wni)) Config.weatherNowIntervalMinutes = Math.max(1, Math.min(1440, Math.round(wni)))
        }
        if (o.weatherHourlyIntervalMinutes !== undefined) {
            var whi = Number(o.weatherHourlyIntervalMinutes)
            if (isFinite(whi)) Config.weatherHourlyIntervalMinutes = Math.max(1, Math.min(1440, Math.round(whi)))
        }
        if (o.weatherDailyIntervalMinutes !== undefined) {
            var wdi = Number(o.weatherDailyIntervalMinutes)
            if (isFinite(wdi)) Config.weatherDailyIntervalMinutes = Math.max(1, Math.min(1440, Math.round(wdi)))
        }
        if (o.weatherRetryDelayMinutes !== undefined) {
            var wrd = Number(o.weatherRetryDelayMinutes)
            if (isFinite(wrd)) Config.weatherRetryDelayMinutes = Math.max(1, Math.min(1440, Math.round(wrd)))
        }
        if (o.weatherManualRefreshCooldownSeconds !== undefined) {
            var wrc = Number(o.weatherManualRefreshCooldownSeconds)
            if (isFinite(wrc)) Config.weatherManualRefreshCooldownSeconds = Math.max(5, Math.min(3600, Math.round(wrc)))
        }

        if (o.timerRowSpacing !== undefined) {
            var trs = Number(o.timerRowSpacing)
            if (isFinite(trs)) Config.timerRowSpacing = Math.max(0, Math.min(50, Math.round(trs)))
        }
        if (o.timerMinHeight !== undefined) {
            var tmh = Number(o.timerMinHeight)
            if (isFinite(tmh)) Config.timerMinHeight = Math.max(30, Math.min(1000, Math.round(tmh)))
        }
        if (o.volumeMinHeight !== undefined) {
            var vmh = Number(o.volumeMinHeight)
            if (isFinite(vmh)) Config.volumeMinHeight = Math.max(30, Math.min(1000, Math.round(vmh)))
        }
        if (o.volumeMaxHeight !== undefined) {
            var vxh = Number(o.volumeMaxHeight)
            if (isFinite(vxh)) Config.volumeMaxHeight = Math.max(100, Math.min(2000, Math.round(vxh)))
        }


}

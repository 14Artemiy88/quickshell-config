.pragma library

function applyMorphProfile(Config, o, key) {
    if (o[key] === undefined) return
    var normalized = Config.normalizeAnimationProfile(o[key])
    if (normalized !== "") Config[key] = normalized
}

function apply(Config, o) {
        // General behaviour / update intervals
        var allowedVisibilityStyles = ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
        var legacyAnimationStyle = o.animationVisibilityStyle !== undefined ? String(o.animationVisibilityStyle) : ""
        if (allowedVisibilityStyles.indexOf(legacyAnimationStyle) < 0) legacyAnimationStyle = ""
        var allowedDashboardVisibilityStyles = ["auto", "none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
        if (o.animationDashboardVisibilityStyle !== undefined) {
            var dashboardVisibilityStyle = String(o.animationDashboardVisibilityStyle)
            if (allowedDashboardVisibilityStyles.indexOf(dashboardVisibilityStyle) >= 0)
                Config.animationDashboardVisibilityStyle = dashboardVisibilityStyle
        }
        var dashboardVisibilityDuration = Number(o.animationDashboardVisibilityDuration)
        if (o.animationDashboardVisibilityDuration !== undefined && isFinite(dashboardVisibilityDuration))
            Config.animationDashboardVisibilityDuration = Math.max(0, Math.min(5000, Math.round(dashboardVisibilityDuration)))

        var animationStyleKeys = [
            "animationCalendarVisibilityStyle",
            "animationMopidyVisibilityStyle",
            "animationNetworkVisibilityStyle",
            "animationTimerVisibilityStyle",
            "animationTimerOptionsVisibilityStyle",
            "animationSettingsVisibilityStyle",
            "animationVolumeStreamsVisibilityStyle"
        ]
        for (var ask = 0; ask < animationStyleKeys.length; ++ask) {
            var styleKey = animationStyleKeys[ask]
            var styleValue = o[styleKey] !== undefined ? String(o[styleKey]) : legacyAnimationStyle
            // Before the options popup gained an independent animation setting,
            // it shared animationTimerVisibilityStyle. Preserve that behavior
            // for existing settings files and profiles on their first load.
            if (styleKey === "animationTimerOptionsVisibilityStyle"
                    && o[styleKey] === undefined
                    && o.animationTimerVisibilityStyle !== undefined)
                styleValue = String(o.animationTimerVisibilityStyle)
            if (allowedVisibilityStyles.indexOf(styleValue) >= 0) Config[styleKey] = styleValue
        }
        var visibilityProfileKeys = [
            "animationDashboardVisibilityProfile",
            "animationCalendarVisibilityProfile",
            "animationMopidyVisibilityProfile",
            "animationNetworkVisibilityProfile",
            "animationTimerVisibilityProfile",
            "animationTimerOptionsVisibilityProfile",
            "animationSettingsVisibilityProfile",
            "animationVolumeStreamsVisibilityProfile",
            "animationNotificationsVisibilityProfile"
        ]
        for (var vpk = 0; vpk < visibilityProfileKeys.length; ++vpk)
            applyMorphProfile(Config, o, visibilityProfileKeys[vpk])
        // The old Volume "none" style is now represented by the shared
        // animation profile. Keep the directional style focused on fade/slide.
        if (o.animationVolumeMorphProfile !== undefined) {
            applyMorphProfile(Config, o, "animationVolumeMorphProfile")
        } else if (String(o.animationVolumeStreamsVisibilityStyle !== undefined
                ? o.animationVolumeStreamsVisibilityStyle : legacyAnimationStyle) === "none") {
            Config.animationVolumeMorphProfile = "none"
        }
        if (String(o.animationVolumeStreamsVisibilityStyle !== undefined
                ? o.animationVolumeStreamsVisibilityStyle : legacyAnimationStyle) === "none")
            Config.animationVolumeStreamsVisibilityStyle = "fade"
        // The old master checkbox is accepted only as a one-time migration
        // input. New UI state is represented exclusively by the profile.
        var legacyMopidyMorphEnabled = o.animationMopidyMorphEnabled
        Config.animationMopidyMorphEnabled = true
        if (o.animationMopidyMorphDuration !== undefined) {
            var mopidyMorphDuration = Number(o.animationMopidyMorphDuration)
            if (isFinite(mopidyMorphDuration))
                Config.animationMopidyMorphDuration = Math.max(0, Math.min(5000, Math.round(mopidyMorphDuration)))
        }
        applyMorphProfile(Config, o, "animationMopidyMorphProfile")
        if (legacyMopidyMorphEnabled === false)
            Config.animationMopidyMorphProfile = "none"
        var legacyPlayerMorphEnabled = o.animationPlayerMorphEnabled
        Config.animationPlayerMorphEnabled = true
        if (o.animationPlayerMorphDuration !== undefined) {
            var playerMorphDuration = Number(o.animationPlayerMorphDuration)
            if (isFinite(playerMorphDuration))
                Config.animationPlayerMorphDuration = Math.max(0, Math.min(5000, Math.round(playerMorphDuration)))
        }
        applyMorphProfile(Config, o, "animationPlayerMorphProfile")
        if (legacyPlayerMorphEnabled === false)
            Config.animationPlayerMorphProfile = "none"
        applyMorphProfile(Config, o, "animationPlayerOsdMorphProfile")
        applyMorphProfile(Config, o, "animationVolumeOsdMorphProfile")
        applyMorphProfile(Config, o, "animationNotificationsDndOsdMorphProfile")
        if (o.notificationsDndOsdEnabled !== undefined)
            Config.notificationsDndOsdEnabled = !!o.notificationsDndOsdEnabled
        if (o.osdIntegrateWithNotifications !== undefined)
            Config.osdIntegrateWithNotifications = o.osdIntegrateWithNotifications === true
        if (o.notificationsDndOsdHideDelay !== undefined) {
            var notificationsDndOsdHideDelay = Number(o.notificationsDndOsdHideDelay)
            if (isFinite(notificationsDndOsdHideDelay)) Config.notificationsDndOsdHideDelay = Math.max(500, Math.min(10000, Math.round(notificationsDndOsdHideDelay)))
        }
        if (o.volumeOsdEnabled !== undefined)
            Config.volumeOsdEnabled = !!o.volumeOsdEnabled
        if (o.volumeOsdHideDelay !== undefined) {
            var vod = Number(o.volumeOsdHideDelay)
            if (isFinite(vod)) Config.volumeOsdHideDelay = Math.max(250, Math.min(10000, Math.round(vod)))
        }
        if (o.playerOsdEnabled !== undefined)
            Config.playerOsdEnabled = !!o.playerOsdEnabled
        if (o.playerOsdHideDelay !== undefined) {
            var pod = Number(o.playerOsdHideDelay)
            if (isFinite(pod)) Config.playerOsdHideDelay = Math.max(500, Math.min(15000, Math.round(pod)))
        }
        var legacyWeatherMorphEnabled = o.animationWeatherMorphEnabled
        Config.animationWeatherMorphEnabled = true
        var weatherMorphDuration = Number(o.animationWeatherMorphDuration)
        if (o.animationWeatherMorphDuration !== undefined && isFinite(weatherMorphDuration))
            Config.animationWeatherMorphDuration = Math.max(0, Math.min(5000, Math.round(weatherMorphDuration)))
        var weatherHourlyDuration = Number(o.animationWeatherHourlyDuration)
        if (o.animationWeatherHourlyDuration !== undefined && isFinite(weatherHourlyDuration))
            Config.animationWeatherHourlyDuration = Math.max(0, Math.min(5000, Math.round(weatherHourlyDuration)))
        applyMorphProfile(Config, o, "animationWeatherMorphProfile")
        if (legacyWeatherMorphEnabled === false)
            Config.animationWeatherMorphProfile = "none"
        var legacyTimerMorphEnabled = o.animationTimerMorphEnabled
        Config.animationTimerMorphEnabled = true
        var timerMorphDuration = Number(o.animationTimerMorphDuration)
        if (o.animationTimerMorphDuration !== undefined && isFinite(timerMorphDuration))
            Config.animationTimerMorphDuration = Math.max(0, Math.min(5000, Math.round(timerMorphDuration)))
        applyMorphProfile(Config, o, "animationTimerMorphProfile")
        if (legacyTimerMorphEnabled === false)
            Config.animationTimerMorphProfile = "none"
        var networkMorphDuration = Number(o.animationNetworkMorphDuration)
        if (o.animationNetworkMorphDuration !== undefined && isFinite(networkMorphDuration))
            Config.animationNetworkMorphDuration = Math.max(0, Math.min(5000, Math.round(networkMorphDuration)))
        applyMorphProfile(Config, o, "animationNetworkMorphProfile")
        var cavaMorphDuration = Number(o.animationCavaMorphDuration)
        if (o.animationCavaMorphDuration !== undefined && isFinite(cavaMorphDuration))
            Config.animationCavaMorphDuration = Math.max(0, Math.min(5000, Math.round(cavaMorphDuration)))
        applyMorphProfile(Config, o, "animationCavaMorphProfile")
        var calendarMorphDuration = Number(o.animationCalendarMorphDuration)
        if (o.animationCalendarMorphDuration !== undefined && isFinite(calendarMorphDuration))
            Config.animationCalendarMorphDuration = Math.max(0, Math.min(5000, Math.round(calendarMorphDuration)))
        applyMorphProfile(Config, o, "animationCalendarMorphProfile")
        var cpuMorphDuration = Number(o.animationCpuMorphDuration)
        if (o.animationCpuMorphDuration !== undefined && isFinite(cpuMorphDuration))
            Config.animationCpuMorphDuration = Math.max(0, Math.min(260, Math.round(cpuMorphDuration)))
        applyMorphProfile(Config, o, "animationCpuMorphProfile")
        var notificationsMorphDuration = Number(o.animationNotificationsMorphDuration)
        if (o.animationNotificationsMorphDuration !== undefined && isFinite(notificationsMorphDuration))
            Config.animationNotificationsMorphDuration = Math.max(0, Math.min(5000, Math.round(notificationsMorphDuration)))
        applyMorphProfile(Config, o, "animationNotificationsMorphProfile")
        var allowedNotificationsVisibilityStyles = ["none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"]
        if (o.animationNotificationsVisibilityStyle !== undefined) {
            var notificationsVisibilityStyle = String(o.animationNotificationsVisibilityStyle)
            if (allowedNotificationsVisibilityStyles.indexOf(notificationsVisibilityStyle) >= 0)
                Config.animationNotificationsVisibilityStyle = notificationsVisibilityStyle
        }
        var launcherMorphDuration = Number(o.animationLauncherMorphDuration)
        if (o.animationLauncherMorphDuration !== undefined && isFinite(launcherMorphDuration))
            Config.animationLauncherMorphDuration = Math.max(0, Math.min(5000, Math.round(launcherMorphDuration)))
        applyMorphProfile(Config, o, "animationLauncherMorphProfile")
        var animationNumberFields = [
            ["animationTimerOptionsDuration", 0, 5000],
            ["animationNetworkVisibilityDuration", 0, 5000],
            ["animationCalendarSlideDuration", 0, 5000],
            ["animationCalendarFadeDuration", 0, 5000],
            ["volumeStreamsAnimationDuration", 0, 5000],
            ["playerOsdAnimationDuration", 0, 5000],
            ["volumeOsdAnimationDuration", 0, 5000],
            ["notificationsDndOsdAnimationDuration", 0, 1500]
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
        if (o.playerOsdEnabled !== undefined)
            Config.playerOsdEnabled = !!o.playerOsdEnabled
        if (o.playerOsdHideDelay !== undefined) {
            var pod = Number(o.playerOsdHideDelay)
            if (isFinite(pod)) Config.playerOsdHideDelay = Math.max(500, Math.min(15000, Math.round(pod)))
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

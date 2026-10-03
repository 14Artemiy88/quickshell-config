.pragma library

function applyObject(owner, Config, o, moduleNames, defaultModuleFrames, defaultModuleBackgrounds, colorNames) {
        if (!o) return
        if (o.weatherToken !== undefined) owner.weatherToken = String(o.weatherToken)
        if (o.font !== undefined) Config.font = String(o.font)
        if (o.fontSize !== undefined) {
            var fs = Number(o.fontSize)
            if (isFinite(fs)) Config.fontSize = Math.max(6, Math.min(32, Math.round(fs)))
        }
        if (o.settingsFont !== undefined) Config.settingsFont = String(o.settingsFont)
        if (o.settingsFontSize !== undefined) {
            var sfs = Number(o.settingsFontSize)
            if (isFinite(sfs)) Config.settingsFontSize = Math.max(6, Math.min(32, Math.round(sfs)))
        }
        if (o.settingsPadding !== undefined) {
            var sp = Number(o.settingsPadding)
            if (isFinite(sp)) Config.settingsPadding = Math.max(0, Math.min(40, Math.round(sp)))
        }
        if (o.settingsSpacing !== undefined) {
            var ss = Number(o.settingsSpacing)
            if (isFinite(ss)) Config.settingsSpacing = Math.max(0, Math.min(40, Math.round(ss)))
        }
        if (o.ledFont !== undefined) Config.ledFont = String(o.ledFont)
        if (o.playerFont !== undefined) Config.playerFont = String(o.playerFont)
        if (o.playerMetaFont !== undefined) Config.playerMetaFont = String(o.playerMetaFont)
        if (o.playerSilenceText !== undefined) Config.playerSilenceText = String(o.playerSilenceText)
        if (o.playerTextOutlineEnabled !== undefined) Config.playerTextOutlineEnabled = !!o.playerTextOutlineEnabled
        if (o.playerTextOutlineColor !== undefined) Config.playerTextOutlineColor = String(o.playerTextOutlineColor)
        if (o.playerPlayingIcon !== undefined) Config.playerPlayingIcon = String(o.playerPlayingIcon)
        if (o.playerPausedIcon !== undefined) Config.playerPausedIcon = String(o.playerPausedIcon)
        if (o.playerNextIcon !== undefined) Config.playerNextIcon = String(o.playerNextIcon)

        // Timer icon order. Older settings had no order field and used timer-left.
        // Migrate those settings once to alarm-left by swapping the saved X positions.
        var legacyTimerIconOrder = o.timerIconOrder === undefined
        if (o.timerIconOrder !== undefined) {
            var timerIconOrderValue = String(o.timerIconOrder)
            Config.timerIconOrder = timerIconOrderValue === "timer-left" ? "timer-left" : "alarm-left"
        } else {
            Config.timerIconOrder = "alarm-left"
        }
        if (o.timerIcon !== undefined) Config.timerIcon = String(o.timerIcon)
        if (o.timerAlarmIcon !== undefined) Config.timerAlarmIcon = String(o.timerAlarmIcon)
        if (o.timerFinishedImageEnabled !== undefined) Config.timerFinishedImageEnabled = !!o.timerFinishedImageEnabled
        if (o.timerFinishedImagePath !== undefined) Config.timerFinishedImagePath = String(o.timerFinishedImagePath)
        if (o.timerFinishedBorderUsesTimerColor !== undefined) Config.timerFinishedBorderUsesTimerColor = !!o.timerFinishedBorderUsesTimerColor
        if (o.timerFinishedBackgroundUsesTimerColor !== undefined) Config.timerFinishedBackgroundUsesTimerColor = !!o.timerFinishedBackgroundUsesTimerColor
        if (o.timerFinishedBackgroundColor !== undefined) Config.timerFinishedBackgroundColor = String(o.timerFinishedBackgroundColor)
        if (o.timerFinishedImageWidth !== undefined) { var tiw = Number(o.timerFinishedImageWidth); if (isFinite(tiw)) Config.timerFinishedImageWidth = Math.max(50, Math.min(1200, Math.round(tiw))) }
        if (o.timerFinishedImageMargin !== undefined) { var tim = Number(o.timerFinishedImageMargin); if (isFinite(tim)) { tim = Math.max(0, Math.min(100, Math.round(tim))); Config.timerFinishedImageMargin = tim; Config.timerFinishedImageTopMargin = tim; Config.timerFinishedImageBottomMargin = tim } }
        else {
            var legacyTim = o.timerFinishedImageTopMargin !== undefined ? Number(o.timerFinishedImageTopMargin) : (o.timerFinishedImageBottomMargin !== undefined ? Number(o.timerFinishedImageBottomMargin) : NaN)
            if (isFinite(legacyTim)) { legacyTim = Math.max(0, Math.min(100, Math.round(legacyTim))); Config.timerFinishedImageMargin = legacyTim; Config.timerFinishedImageTopMargin = legacyTim; Config.timerFinishedImageBottomMargin = legacyTim }
        }
        if (o.timerFinishedTitleUsesTimerColor !== undefined) Config.timerFinishedTitleUsesTimerColor = !!o.timerFinishedTitleUsesTimerColor
        if (o.timerFinishedTitleColor !== undefined) Config.timerFinishedTitleColor = String(o.timerFinishedTitleColor)
        if (o.timerFinishedTitleFontSize !== undefined) { var ttfs = Number(o.timerFinishedTitleFontSize); if (isFinite(ttfs)) Config.timerFinishedTitleFontSize = Math.max(8, Math.min(72, Math.round(ttfs))) }
        if (o.timerFinishedTitleFont !== undefined) Config.timerFinishedTitleFont = String(o.timerFinishedTitleFont)
        if (o.timerFinishedTitleAlignment !== undefined) { var tta = Number(o.timerFinishedTitleAlignment); if (isFinite(tta)) Config.timerFinishedTitleAlignment = Math.max(0, Math.min(2, Math.round(tta))) }
        if (o.playerPlayingIconY !== undefined) Config.playerPlayingIconY = Number(o.playerPlayingIconY)
        if (o.playerPausedIconY !== undefined) Config.playerPausedIconY = Number(o.playerPausedIconY)
        if (o.playerNextIconY !== undefined) Config.playerNextIconY = Number(o.playerNextIconY)

        // General behaviour / update intervals
        if (o.animationsEnabled !== undefined) Config.animationsEnabled = !!o.animationsEnabled
        if (o.animationSpeed !== undefined) {
            var as = Number(o.animationSpeed)
            if (isFinite(as)) Config.animationSpeed = Math.max(0.25, Math.min(4.0, as))
        }
        if (o.animationEasing !== undefined) Config.animationEasing = String(o.animationEasing)
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

        // CPU / RAM tuning
        var cpuNumberFields = [
            ["cpuBarThickness", 1, 30], ["cpuBarWidth", 40, 1000],
            ["cpuRowHeight", 10, 60], ["cpuRowSpacing", 0, 30],
            ["cpuLabelLeftPadding", 0, 40], ["cpuBarLeftOffset", 0, 200],
            ["cpuBarRadius", 0, 40], ["cpuGraphSegmentSlotWidth", 1, 20],
            ["cpuGraphBarWidth", 1, 10]
        ]
        for (var cf = 0; cf < cpuNumberFields.length; ++cf) {
            var cname = cpuNumberFields[cf][0]
            if (o[cname] !== undefined) {
                var cv = Number(o[cname])
                if (isFinite(cv)) Config[cname] = Math.max(cpuNumberFields[cf][1], Math.min(cpuNumberFields[cf][2], Math.round(cv)))
            }
        }
        if (o.cpuShowRam !== undefined) Config.cpuShowRam = !!o.cpuShowRam

        // Network display tuning
        var networkNumberFields = [
            ["networkRowHeight", 12, 60], ["networkRowSpacing", 0, 30],
            ["networkIconSize", 8, 40], ["networkValueFontSize", 8, 32],
            ["networkRightPadding", 0, 40], ["networkHorizontalPadding", 0, 40],
            ["networkIconLeftPadding", 0, 40], ["networkIconColumnWidth", 16, 80]
        ]
        for (var nf = 0; nf < networkNumberFields.length; ++nf) {
            var nname = networkNumberFields[nf][0]
            if (o[nname] !== undefined) {
                var nv = Number(o[nname])
                if (isFinite(nv)) Config[nname] = Math.max(networkNumberFields[nf][1], Math.min(networkNumberFields[nf][2], Math.round(nv)))
            }
        }
        if (o.networkShowUpload !== undefined) Config.networkShowUpload = !!o.networkShowUpload
        if (o.networkShowDownload !== undefined) Config.networkShowDownload = !!o.networkShowDownload

        // Volume tuning
        var volumeNumberFields = [
            ["volumeUpdateInterval", 50, 5000], ["volumeMainRowHeight", 20, 80],
            ["volumeStreamRowHeight", 12, 60], ["volumeStreamSpacing", 0, 20],
            ["volumeHorizontalPadding", 0, 40], ["volumeVerticalPadding", 0, 40],
            ["volumeMainTrackWidth", 40, 1000], ["volumeMainTrackHeight", 1, 30],
            ["volumeStreamTrackHeight", 1, 20], ["volumeMainTrackOffsetY", -30, 30],
            ["volumeStreamTrackOffsetY", -20, 20], ["volumeMainIconWidth", 16, 80],
            ["volumeStreamLabelFontSize", 8, 32], ["volumeTrackRadius", 0, 20]
        ]
        for (var vf = 0; vf < volumeNumberFields.length; ++vf) {
            var vname = volumeNumberFields[vf][0]
            if (o[vname] !== undefined) {
                var vv = Number(o[vname])
                if (isFinite(vv)) Config[vname] = Math.max(volumeNumberFields[vf][1], Math.min(volumeNumberFields[vf][2], Math.round(vv)))
            }
        }
        if (o.volumeShowStreams !== undefined) Config.volumeShowStreams = !!o.volumeShowStreams
        if (o.volumeIcon !== undefined) Config.volumeIcon = String(o.volumeIcon)
        if (o.volumeMutedIcon !== undefined) Config.volumeMutedIcon = String(o.volumeMutedIcon)

        // Calendar tuning
        if (o.calendarPreviousIcon !== undefined) Config.calendarPreviousIcon = String(o.calendarPreviousIcon)
        if (o.calendarNextIcon !== undefined) Config.calendarNextIcon = String(o.calendarNextIcon)
        if (o.calendarTitleFont !== undefined) Config.calendarTitleFont = String(o.calendarTitleFont)
        if (o.calendarWeekdayFont !== undefined) Config.calendarWeekdayFont = String(o.calendarWeekdayFont)
        if (o.calendarDayFont !== undefined) Config.calendarDayFont = String(o.calendarDayFont)
        var calendarNumberFields = [
            ["calendarPreviousSize", 8, 64], ["calendarNextSize", 8, 64], ["calendarArrowY", -20, 20],
            ["calendarPreviousX", -20, 20], ["calendarNextX", -20, 20],
            ["calendarTitleFontSize", 8, 48], ["calendarTitleY", -20, 20], ["calendarWeekdayY", -20, 20],
            ["calendarWeekdayFontSize", 8, 32], ["calendarDayY", -20, 20], ["calendarDayFontSize", 8, 32]
        ]
        for (var clf = 0; clf < calendarNumberFields.length; ++clf) {
            var clname = calendarNumberFields[clf][0]
            if (o[clname] !== undefined) {
                var clv = Number(o[clname])
                if (isFinite(clv)) Config[clname] = Math.max(calendarNumberFields[clf][1], Math.min(calendarNumberFields[clf][2], Math.round(clv)))
            }
        }

        // Timer tuning
        var timerNumberFields = [
            ["timerWheelStep", 1, 60], ["timerCommentWidth", 40, 300],
            ["timerCommentMaxLength", 1, 30], ["timerCommentGap", 0, 40], ["timerRowSpacing", 0, 50],
            ["timerIconSize", 8, 64], ["timerIconX", -100, 100], ["timerIconY", -100, 100],
            ["timerAlarmIconSize", 8, 64], ["timerAlarmIconX", -100, 100], ["timerAlarmIconY", -100, 100],
            ["timerRowTopMargin", 0, 50], ["timerRowRightMargin", 0, 50],
            ["timerButtonFadeDuration", 0, 5000], ["timerButtonSlideDuration", 0, 5000],
            ["timerButtonIconFadeDuration", 0, 5000]
        ]
        for (var tf = 0; tf < timerNumberFields.length; ++tf) {
            var tname = timerNumberFields[tf][0]
            if (o[tname] !== undefined) {
                var tv = Number(o[tname])
                if (isFinite(tv)) Config[tname] = Math.max(timerNumberFields[tf][1], Math.min(timerNumberFields[tf][2], Math.round(tv)))
            }
        }
        if (legacyTimerIconOrder && o.timerIconX !== undefined && o.timerAlarmIconX !== undefined) {
            var legacyTimerX = Number(o.timerIconX)
            var legacyAlarmX = Number(o.timerAlarmIconX)
            if (isFinite(legacyTimerX) && isFinite(legacyAlarmX)) {
                Config.timerIconX = legacyAlarmX
                Config.timerAlarmIconX = legacyTimerX
            }
        }

        // Player tuning
        var playerNumberFields = [
            ["playerSilenceFontSize", 8, 100], ["playerSilenceLongFontSize", 8, 100],
            ["playerMetaFontSize", 8, 48], ["playerMetaSecondaryFontSize", 8, 48],
            ["playerMetaLineSpacing", 0, 100], ["playerControlIconSize", 8, 64],
            ["playerPlayingIconSize", 8, 64], ["playerPausedIconSize", 8, 64], ["playerNextIconSize", 8, 64],
            ["playerPlayingIconY", -100, 100], ["playerPausedIconY", -100, 100], ["playerNextIconY", -100, 100],
            ["playerMetadataXPadding", 0, 100], ["playerMetadataY", 0, 100], ["playerProgressY", 0, 100],
            ["playerProgressTrackHeight", 1, 20], ["playerControlTopMargin", 0, 100],
            ["playerControlGap", 0, 100], ["playerTimeFontSize", 8, 48],
            ["playerTimeRightPadding", 0, 100], ["playerSilenceWidth", 100, 600],
            ["playerProgressTrackOffsetY", -10, 20]
        ]
        for (var pf = 0; pf < playerNumberFields.length; ++pf) {
            var pname = playerNumberFields[pf][0]
            if (o[pname] !== undefined) {
                var pv = Number(o[pname])
                if (isFinite(pv)) Config[pname] = Math.max(playerNumberFields[pf][1], Math.min(playerNumberFields[pf][2], Math.round(pv)))
            }
        }
        if (o.playerBoldArtist !== undefined) Config.playerBoldArtist = !!o.playerBoldArtist
        if (o.playerShowProgress !== undefined) Config.playerShowProgress = !!o.playerShowProgress
        if (o.playerBlurEnabled !== undefined) Config.playerBlurEnabled = !!o.playerBlurEnabled
        if (o.playerBlurRadius !== undefined) {
            var pbr = Number(o.playerBlurRadius)
            if (isFinite(pbr)) Config.playerBlurRadius = Math.max(0, Math.min(40, Math.round(pbr)))
        }
        if (o.playerCoverOpacity !== undefined) {
            var pco = Number(o.playerCoverOpacity)
            if (isFinite(pco)) Config.playerCoverOpacity = Math.max(0, Math.min(1, pco))
        }

        // Weather tuning
        var weatherNumberFields = [
            ["weatherIconSize", 16, 128], ["weatherArrowSize", 8, 64],
            ["weatherArrowYOffset", -40, 40], ["weatherWindArrowGap", -20, 40],
            ["weatherHourlyCount", 1, 12], ["weatherDailyCount", 1, 4],
            ["weatherIconY", -100, 100],
            ["weatherWindColumnX", 0, 500], ["weatherWindSpeedFontSize", 8, 64],
            ["weatherWindUnitFontSize", 6, 48], ["weatherPressureY", 0, 100],
            ["weatherDescriptionY", 0, 120], ["weatherDescriptionFontSize", 6, 48],
            ["weatherTempFontSize", 12, 96], ["weatherComfortFontSize", 8, 72],
            ["weatherTempColumnWidth", 40, 200], ["weatherTempX", 0, 200], ["weatherTempWidth", 20, 200],
            ["weatherTempOffsetX", -100, 100], ["weatherTempOffsetY", -100, 100],
            ["weatherComfortY", -20, 100], ["weatherComfortOffsetX", -100, 100], ["weatherComfortOffsetY", -100, 100], ["weatherComfortHeight", 10, 100], ["weatherWindColumnWidth", 60, 300],
            ["weatherWindArrowWidth", 8, 50], ["weatherWindArrowHeight", 15, 80],
            ["weatherWindSpeedX", 0, 250], ["weatherWindSpeedY", -20, 80], ["weatherWindSpeedWidth", 20, 150],
            ["weatherWindUnitX", 0, 300], ["weatherWindUnitY", -20, 80], ["weatherWindUnitWidth", 10, 120],
            ["weatherPressureValueWidth", 20, 180], ["weatherPressureFontSize", 8, 48],
            ["weatherPressureUnitX", 0, 300], ["weatherPressureUnitY", -20, 80], ["weatherPressureUnitFontSize", 6, 30],
            ["weatherDescriptionHeight", 8, 40],
            ["weatherHourlyTopPadding", 0, 40], ["weatherHourlyDayY", 0, 120], ["weatherHourlyDayFontSize", 6, 32],
            ["weatherHourlyIconWidth", 16, 90], ["weatherHourlyIconY", 0, 120],
            ["weatherHourlyTempY", 0, 150], ["weatherHourlyTempHeight", 10, 50], ["weatherHourlyTempFontSize", 6, 32],
            ["weatherDailyTopPadding", 0, 40], ["weatherDailyDayY", 0, 120], ["weatherDailyDayFontSize", 6, 32],
            ["weatherDailyIconWidth", 16, 90], ["weatherDailyIconY", 0, 120],
            ["weatherDailyHighTempX", -100, 100], ["weatherDailyHighTempY", 0, 150], ["weatherDailyHighTempFontSize", 6, 32],
            ["weatherDailyLowTempX", -100, 100], ["weatherDailyLowTempY", 0, 180], ["weatherDailyLowTempFontSize", 6, 32]
        ]
        for (var wf = 0; wf < weatherNumberFields.length; ++wf) {
            var wname = weatherNumberFields[wf][0]
            if (o[wname] !== undefined) {
                var wv = Number(o[wname])
                if (isFinite(wv)) Config[wname] = Math.max(weatherNumberFields[wf][1], Math.min(weatherNumberFields[wf][2], Math.round(wv)))
            }
        }

        // Backward-compatible migration from the old shared hourly/daily list geometry.
        var weatherListMigration = [
            ["weatherHourlyTopPadding", "weatherListTopPadding"], ["weatherHourlyDayY", "weatherListDayY"], ["weatherDailyTopPadding", "weatherListTopPadding"], ["weatherDailyDayY", "weatherListDayY"],
            ["weatherHourlyDayFontSize", "weatherListDayFontSize"], ["weatherDailyDayFontSize", "weatherListDayFontSize"],
            ["weatherHourlyIconWidth", "weatherListIconWidth"], ["weatherDailyIconWidth", "weatherListIconWidth"],
            ["weatherHourlyIconY", "weatherListIconY"], ["weatherDailyIconY", "weatherListIconY"],
            ["weatherHourlyTempY", "weatherListHourlyTempY"], ["weatherDailyHighTempY", "weatherListDailyTempY"],
            ["weatherHourlyTempFontSize", "weatherListHourlyTempFontSize"], ["weatherDailyHighTempFontSize", "weatherListDailyTempFontSize"],
            ["weatherDailyLowTempY", "weatherListLowTempY"], ["weatherDailyLowTempFontSize", "weatherListLowTempFontSize"]
        ]
        for (var wm = 0; wm < weatherListMigration.length; ++wm) {
            var target = weatherListMigration[wm][0], legacy = weatherListMigration[wm][1]
            if (o[target] === undefined && o[legacy] !== undefined) {
                var mv = Number(o[legacy])
                if (isFinite(mv)) Config[target] = Math.round(mv)
            }
        }
        if (o.weatherWindIcon !== undefined) Config.weatherWindIcon = String(o.weatherWindIcon)

        Config.weatherDailyCount = Math.max(1, Math.min(4, Config.weatherDailyCount))

        if (o.cavaBars !== undefined) Config.cavaBars = Math.max(8, Number(o.cavaBars) || Config.cavaBars)
        if (o.cavaFramerate !== undefined) Config.cavaFramerate = Math.max(1, Math.min(120, Math.round(Number(o.cavaFramerate) || Config.cavaFramerate)))
        if (o.cavaRowSpacing !== undefined) Config.cavaRowSpacing = Math.max(0, Math.min(20, Math.round(Number(o.cavaRowSpacing) || Config.cavaRowSpacing)))
        if (o.cavaBarWidthRatio !== undefined) { var cbwr=Number(o.cavaBarWidthRatio); if (isFinite(cbwr)) Config.cavaBarWidthRatio=Math.max(0.05,Math.min(1,cbwr)) }
        if (o.frameBorderWidth !== undefined) {
            var bw = Number(o.frameBorderWidth)
            if (isFinite(bw)) Config.frameBorderWidth = Math.max(0, Math.min(20, Math.round(bw)))
        }
        if (o.frameRadius !== undefined) {
            var fr = Number(o.frameRadius)
            if (isFinite(fr)) Config.frameRadius = Math.max(0, Math.min(50, Math.round(fr)))
        }
        var presetSource = o.timerPresetDefaults instanceof Array ? o.timerPresetDefaults : o.timerPresets
        if (presetSource instanceof Array) {
            var presets = []
            for (var p = 0; p < presetSource.length; ++p) {
                var value = Number(presetSource[p])
                if (isFinite(value)) presets.push(Math.max(0, Math.round(value)))
            }
            owner.timerPresetDefaults = presets
            owner.timerPresets = presets.slice()
        }
        var modules = o.modules || {}
        for (var i=0; i<moduleNames.length; ++i) if (modules[moduleNames[i]] !== undefined) owner[moduleNames[i]] = !!modules[moduleNames[i]]
        var frames = Object.assign({}, defaultModuleFrames)
        var savedFrames = o.moduleFrames || {}
        for (var fi=0; fi<moduleNames.length; ++fi) if (savedFrames[moduleNames[fi]] !== undefined) frames[moduleNames[fi]] = !!savedFrames[moduleNames[fi]]
        owner.moduleFrames = frames
        var backgrounds = Object.assign({}, defaultModuleBackgrounds)
        var savedBackgrounds = o.moduleBackgrounds || {}
        for (var bi=0; bi<moduleNames.length; ++bi) if (savedBackgrounds[moduleNames[bi]] !== undefined) backgrounds[moduleNames[bi]] = !!savedBackgrounds[moduleNames[bi]]
        owner.moduleBackgrounds = backgrounds
        if (o.geometry) {
            var g = Object.assign({}, owner.geometry)
            for (var k in o.geometry) if (o.geometry[k] && o.geometry[k].length === 4) g[k] = o.geometry[k].map(Number)
            owner.geometry = g
        }
        if (o.settingsGeometry && o.settingsGeometry.length === 4) {
            owner.settingsGeometry = o.settingsGeometry.map(Number)
        }
        if (o.settingsMonitorName !== undefined && String(o.settingsMonitorName).trim() !== "") {
            owner.settingsMonitorName = String(o.settingsMonitorName)
        }
        var colors = o.colors || {}
        for (var j=0; j<colorNames.length; ++j) {
            var name = colorNames[j]
            if (colors[name] !== undefined) Config[name] = colors[name]
        }
        if (o.profiles !== undefined && o.profiles && typeof o.profiles === "object") {
            owner.profiles = o.profiles
            owner.rebuildProfileList()
        }
        if (o.customThemes !== undefined && o.customThemes && typeof o.customThemes === "object")
            owner.customThemes = o.customThemes
        if (o.activeProfile !== undefined) owner.activeProfile = String(o.activeProfile)
        if (o.activeTheme !== undefined) owner.activeTheme = String(o.activeTheme)
        owner.rebuildProfileList()
        owner.loaded = true
        owner.themeStateRevision++
        owner.changed()

}

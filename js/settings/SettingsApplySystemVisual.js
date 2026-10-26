.pragma library

.import "SettingsLauncherProjects.js" as LauncherProjects
.import "SettingsSchema.js" as Schema

function apply(Config, o) {
        // Launcher module enable flag.
        if (o.launcherEnabled !== undefined) Config.launcherEnabled = !!o.launcherEnabled

        // Launcher geometry and opacity.
        var launcherNumberFields = [
            ["launcherWidth", 500, 1400],
            ["launcherHeight", 400, 1200],
            ["launcherItemHeight", 36, 110],
            ["launcherItemRadius", 0, 30],
            ["launcherRadius", 0, 40],
            ["launcherTitleFontSize", 6, 40],
            ["launcherTitleY", -40, 40],
            ["launcherTitleLetterSpacing", 0, 12],
            ["launcherSearchFontSize", 8, 40],
            ["launcherSearchHeight", 36, 100],
            ["launcherSearchRadius", 0, 36]
        ]
        for (var lf = 0; lf < launcherNumberFields.length; ++lf) {
            var launcherName = launcherNumberFields[lf][0]
            if (o[launcherName] !== undefined) {
                var launcherValue = Number(o[launcherName])
                if (isFinite(launcherValue))
                    Config[launcherName] = Math.max(launcherNumberFields[lf][1], Math.min(launcherNumberFields[lf][2], Math.round(launcherValue)))
            }
        }
        if (o.launcherBackdropOpacity !== undefined) {
            var launcherOpacity = Number(o.launcherBackdropOpacity)
            if (isFinite(launcherOpacity))
                Config.launcherBackdropOpacity = Math.max(0, Math.min(0.95, launcherOpacity))
        }
        if (o.launcherBackground !== undefined)
            Config.launcherBackground = Schema.normalizeSavedColor(o.launcherBackground, String(Config.launcherBackground))
        if (o.launcherTitleText !== undefined)
            Config.launcherTitleText = String(o.launcherTitleText).replace(/[\r\n\t]/g, " ").trim().slice(0, 64) || "LAUNCHER"
        if (o.launcherTitleFont !== undefined)
            Config.launcherTitleFont = String(o.launcherTitleFont).replace(/[\r\n\t]/g, " ").trim().slice(0, 128)
        if (o.launcherTitleColor !== undefined)
            Config.launcherTitleColor = Schema.normalizeSavedColor(o.launcherTitleColor, String(Config.launcherTitleColor))
        if (o.launcherTitleBold !== undefined)
            Config.launcherTitleBold = !!o.launcherTitleBold
        if (o.launcherSearchFont !== undefined)
            Config.launcherSearchFont = String(o.launcherSearchFont).replace(/[\r\n\t]/g, " ").trim().slice(0, 128)
        if (o.launcherSearchPlaceholder !== undefined)
            Config.launcherSearchPlaceholder = String(o.launcherSearchPlaceholder).replace(/[\r\n\t]/g, " ").trim().slice(0, 128)
        if (o.launcherSearchBackground !== undefined)
            Config.launcherSearchBackground = Schema.normalizeSavedColor(o.launcherSearchBackground, String(Config.launcherSearchBackground))
        if (o.launcherDefaultMode !== undefined) {
            var launcherMode = Number(o.launcherDefaultMode)
            Config.launcherDefaultMode = isFinite(launcherMode)
                    ? Math.max(0, Math.min(9, Math.round(launcherMode))) : 0
        }
        if (o.launcherShowResultCount !== undefined)
            Config.launcherShowResultCount = !!o.launcherShowResultCount
        if (o.launcherCrossSearchProjects !== undefined)
            Config.launcherCrossSearchProjects = !!o.launcherCrossSearchProjects
        if (o.launcherCrossSearchRunHistory !== undefined)
            Config.launcherCrossSearchRunHistory = !!o.launcherCrossSearchRunHistory
        if (o.launcherCrossSearchCalculator !== undefined)
            Config.launcherCrossSearchCalculator = !!o.launcherCrossSearchCalculator
        if (o.launcherTabOrder instanceof Array) {
            var validLauncherOrder = []
            for (var lto = 0; lto < o.launcherTabOrder.length; ++lto) {
                var tabId = Number(o.launcherTabOrder[lto])
                if (isFinite(tabId) && Math.floor(tabId) === tabId && tabId >= 0 && tabId <= 9 && validLauncherOrder.indexOf(tabId) < 0)
                    validLauncherOrder.push(tabId)
            }
            for (var lta = 0; lta < 10; ++lta) {
                if (validLauncherOrder.indexOf(lta) < 0) validLauncherOrder.push(lta)
            }
            Config.launcherTabOrder = validLauncherOrder
        }
        if (o.launcherTabVisible instanceof Array) {
            var validLauncherVisibility = []
            for (var ltv = 0; ltv < 10; ++ltv)
                validLauncherVisibility.push(o.launcherTabVisible[ltv] === undefined ? true : !!o.launcherTabVisible[ltv])
            Config.launcherTabVisible = validLauncherVisibility
        }
        var defaultLauncherTabLabels = ["Apps", "Run", "Windows", "Clipboard", "Power", "Network", "Packages", "Pass", "Projects", "Calculator"]
        var defaultLauncherTabIcons = ["󰀻", "", "󰖯", "󰅇", "", "󰖩", "󱄅", "󰌋", "", "󰃬"]
        var sourceLauncherLabels = o.launcherTabLabels instanceof Array ? o.launcherTabLabels : defaultLauncherTabLabels
        var validLauncherLabels = []
        for (var ltl = 0; ltl < defaultLauncherTabLabels.length; ++ltl) {
            var label = sourceLauncherLabels[ltl] === undefined
                    ? defaultLauncherTabLabels[ltl]
                    : String(sourceLauncherLabels[ltl]).replace(/[\r\n\t]/g, " ").trim().slice(0, 32)
            validLauncherLabels.push(label || defaultLauncherTabLabels[ltl])
        }
        Config.launcherTabLabels = validLauncherLabels

        var sourceLauncherIcons = o.launcherTabIcons instanceof Array ? o.launcherTabIcons : defaultLauncherTabIcons
        var validLauncherIcons = []
        for (var lti = 0; lti < defaultLauncherTabIcons.length; ++lti) {
            var icon = sourceLauncherIcons[lti] === undefined
                    ? defaultLauncherTabIcons[lti]
                    : String(sourceLauncherIcons[lti]).replace(/[\r\n\t]/g, " ").slice(0, 16)
            validLauncherIcons.push(icon)
        }
        Config.launcherTabIcons = validLauncherIcons
        if (o.launcherProjects instanceof Array)
            Config.launcherProjects = LauncherProjects.normalize(o.launcherProjects)

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
        if (o.cpuBarDirection !== undefined) { var cbd = String(o.cpuBarDirection); Config.cpuBarDirection = ["leftToRight", "rightToLeft", "topToBottom", "bottomToTop"].indexOf(cbd) >= 0 ? cbd : "leftToRight" }
        if (o.cpuGraphMode !== undefined) { var cgm = String(o.cpuGraphMode); Config.cpuGraphMode = ["both", "top", "bottom"].indexOf(cgm) >= 0 ? cgm : "both" }
        if (o.cpuShowRam !== undefined) Config.cpuShowRam = !!o.cpuShowRam
        if (o.topAppsShowHeaders !== undefined) Config.topAppsShowHeaders = !!o.topAppsShowHeaders
        var topAppsHeaderTextFields = [
            ["topAppsCpuHeaderTitle", 64], ["topAppsCpuHeaderSubtitle", 64],
            ["topAppsRamHeaderTitle", 64], ["topAppsRamHeaderSubtitle", 64]
        ]
        for (var thf = 0; thf < topAppsHeaderTextFields.length; ++thf) {
            var thname = topAppsHeaderTextFields[thf][0]
            if (o[thname] !== undefined) Config[thname] = String(o[thname]).replace(/[\r\n\t]/g, " ").trim().slice(0, topAppsHeaderTextFields[thf][1])
        }
        if (o.topAppsShowBars !== undefined) Config.topAppsShowBars = !!o.topAppsShowBars
        if (o.topAppsShowSystemRemainder !== undefined) Config.topAppsShowSystemRemainder = !!o.topAppsShowSystemRemainder
        if (o.topAppsSystemRemainderLabel !== undefined) { var remainderLabel = String(o.topAppsSystemRemainderLabel).replace(/[\r\n\t]/g, " ").trim().slice(0, 64); Config.topAppsSystemRemainderLabel = remainderLabel || "Система/прочее" }
        if (o.topAppsFont !== undefined) Config.topAppsFont = String(o.topAppsFont).slice(0, 128)
        // User-tuned Top Apps typography/layout: keep lower bounds that prevent invalid sizes, but no artificial upper bounds.
        var topAppsNumberFields = [
            ["topAppsFontSize", 1, Infinity], ["topAppsRowSpacing", 0, Infinity],
            ["topAppsTopOffset", 0, Infinity], ["topAppsHeaderTitleFontSize", 6, 32],
            ["topAppsHeaderSubtitleFontSize", 6, 32], ["topAppsBarX", 45, 240],
            ["topAppsBarY", -10, 10], ["topAppsBarHeight", 1, 30], ["topAppsBarWidth", 1, 300]
        ]
        for (var taf = 0; taf < topAppsNumberFields.length; ++taf) {
            var taname = topAppsNumberFields[taf][0]
            if (o[taname] !== undefined) {
                var tav = Number(o[taname])
                if (isFinite(tav)) Config[taname] = Math.max(topAppsNumberFields[taf][1], Math.min(topAppsNumberFields[taf][2], Math.round(tav)))
            }
        }

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
        if (o.calendarPastDaysColorEnabled !== undefined) Config.calendarPastDaysColorEnabled = !!o.calendarPastDaysColorEnabled
        if (o.calendarAlwaysVisible !== undefined) Config.calendarAlwaysVisible = !!o.calendarAlwaysVisible
        if (o.calendarAdjacentDaysColor !== undefined) {
            var adjacentDaysColor = String(o.calendarAdjacentDaysColor)
            Config.calendarAdjacentDaysColor = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(adjacentDaysColor) ? adjacentDaysColor : "#777777"
        }
        if (o.calendarWeekendColor !== undefined) {
            var weekendColor = String(o.calendarWeekendColor)
            Config.calendarWeekendColor = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(weekendColor) ? weekendColor : "#d98282"
        }
        if (o.calendarPastDaysColor !== undefined) {
            var pastDaysColor = String(o.calendarPastDaysColor)
            Config.calendarPastDaysColor = /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(pastDaysColor) ? pastDaysColor : "#888888"
        }
        if (o.calendarNoteMarkerStyle !== undefined) {
            var noteMarkerStyle = String(o.calendarNoteMarkerStyle)
            Config.calendarNoteMarkerStyle = ["dot", "line", "ring", "note", "frame"].indexOf(noteMarkerStyle) >= 0 ? noteMarkerStyle : "dot"
        }
        if (o.calendarNoteMarkerPosition !== undefined) {
            var noteMarkerPosition = String(o.calendarNoteMarkerPosition)
            Config.calendarNoteMarkerPosition = ["topLeft", "topCenter", "topRight", "leftCenter", "rightCenter", "bottomLeft", "bottomCenter", "bottomRight"].indexOf(noteMarkerPosition) >= 0 ? noteMarkerPosition : "bottomCenter"
        }
        if (o.calendarNoteFrameColor !== undefined) {
            var noteMarkerColor = String(o.calendarNoteFrameColor)
            Config.calendarNoteFrameColor = /^#[0-9a-fA-F]{6,8}$/.test(noteMarkerColor) ? noteMarkerColor : "#00cccc"
        }
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


}

.pragma library

function apply(Config, o) {
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


}

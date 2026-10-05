.pragma library

function apply(Config, o) {
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

}

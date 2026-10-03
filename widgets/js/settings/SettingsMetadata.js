.pragma library

var moduleNames = ["time","calendar","cpu","cpuGraph","topApps","networkStat","weatherNow","weatherHourly","weatherDaily","timer","volumes","player","cava","networks"]

var moduleLabels = ({time:"Часы",cpu:"CPU",cpuGraph:"График CPU",topApps:"Top Apps",networkStat:"Сеть",weatherNow:"Погода сейчас",weatherHourly:"Погода по часам",weatherDaily:"Погода по дням",timer:"Таймеры",volumes:"Громкость",player:"Плеер",cava:"CAVA",networks:"Networks",calendar:"Календарь"})

var colorNames = ["baseColor","accent","currentWeather","background","text","textMuted","textDim","textDisabled","calendarBackground","settingsBackground","settingsBorder","settingsSubheading","playerOverlay","playerProgressTrack","playerProgressFill","activeNetworkBackground","volumeTrack","volumeFill","cpu1","cpu2","cpu3","cpu4","cpu5","cpu6","cpu7","cpu8","ram","metricTrack","ramTrack","networkUpload","networkDownload","tempHot","tempWarm","tempMild","tempCool","tempZero","tempCold","tempVeryCold","tempFreezing"]

var defaultWeatherToken = ""
var defaultTimerPresetDefaults = [5, 7, 15]
var defaultGeometry = {"time":[3,6,315,58],"cpu":[5,70,315,170],"cpuGraph":[5,245,315,78],"topApps":[5,329,315,198],"networkStat":[5,527,313,55],"weatherNow":[3,587,315,80],"weatherHourly":[5,672,314,106],"weatherDaily":[5,784,314,117],"timer":[3,907,316,50],"timerOptions":[325,888,90,95],"calendar":[5,65,316,286],"volumes":[331,72,275,152],"player":[330,380,300,200],"cava":[330,588,300,80],"networks":[330,675,300,171]}
var defaultSettingsGeometry = [615,71,656,850]
var defaultModules = {"time":true,"cpu":true,"cpuGraph":true,"topApps":true,"networkStat":true,"weatherNow":true,"weatherHourly":true,"weatherDaily":true,"timer":true,"volumes":true,"player":true,"cava":true,"networks":true,"calendar":true}
var defaultModuleFrames = {"time":true,"calendar":true,"cpu":true,"cpuGraph":true,"topApps":true,"networkStat":true,"weatherNow":true,"weatherHourly":true,"weatherDaily":true,"timer":true,"volumes":true,"player":true,"cava":true,"networks":true}
var defaultModuleBackgrounds = {"time":true,"calendar":true,"cpu":true,"cpuGraph":true,"topApps":true,"networkStat":true,"weatherNow":true,"weatherHourly":true,"weatherDaily":true,"timer":true,"volumes":true,"player":true,"cava":true,"networks":true}

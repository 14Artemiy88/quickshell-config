pragma Singleton
import QtQuick

QtObject {
    // Core palette
    property color baseColor: "#006666"
    property color accent: "#00cccc"
    property color currentWeather: "#00cccc"
    property color background: "#4d000000"
    property color text: "#ffffff"
    property color textMuted: "#dddddd"
    property color textDim: "#cccccc"
    property color textDisabled: "#999999"
    property color black: "#000000"
    property color transparent: "transparent"

    // Surfaces / overlays
    property color playerOverlay: "#18000000"
    property color playerProgressTrack: "#33ffffff"
    property color activeNetworkBackground: "#1a323232"
    property color calendarBackground: "#cc000000"
    property color volumeTrack: "#99006666"
    property color volumeFill: "#006666"
    property color settingsBackground: "#e6000000"
    property color settingsBorder: "#00cccc"

    // Adaptive module minimum heights
    property int timerMinHeight: 72
    property int volumeMinHeight: 85
    property int volumeMaxHeight: 1200
    property int cavaBars: 75
    property int cavaFramerate: 30

    // CPU / system metrics
    property color cpu1: "#ffb4bb"
    property color cpu2: "#ffe0ba"
    property color cpu3: "#fffebb"
    property color cpu4: "#baffc9"
    property color cpu5: "#bae1ff"
    property color cpu6: "#aedfdb"
    property color cpu7: "#75c8cc"
    property color cpu8: "#ead1f5"
    property color ram: "#3daee9"
    property color metricTrack: "#4d006666"
    property color ramTrack: "#4d3daee9"
    property color networkUpload: "#baffc9"
    property color networkDownload: "#ffb4bb"

    // Weather temperature palette
    property color tempHot: "#ff8989"
    property color tempWarm: "#ffb4bb"
    property color tempMild: "#ffe0ba"
    property color tempCool: "#fce3c4"
    property color tempZero: "#ffffff"
    property color tempCold: "#bae1ff"
    property color tempVeryCold: "#0ad1f3"
    property color tempFreezing: "#3c82e2"

    property string font: "JetBrainsMono Nerd Font"
    property string ledFont: "LED"
    property string playerFont: "HARDBOR"
    property string playerMetaFont: "Ubuntu Mono Nerd Font"
    property string playerSilenceText: "silence"
    // Outer frame appearance
    property int frameBorderWidth: 1
    property int frameRadius: 7

    // Legacy/general corner radius used by small controls
    property int radius: 7
    property string monitorName: "LCD195VXM+"
    property string monitorNameMode: "name-or-model"
}

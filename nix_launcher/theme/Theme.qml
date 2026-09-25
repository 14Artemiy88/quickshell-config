
import QtQuick

QtObject {
    // Global surfaces
    readonly property color backdrop: "#000000"
    readonly property color transparent: "#00000000"
    readonly property real backdropOpacity: 0.55
    readonly property color background: "#141414"
    readonly property color panel: "#181818"
    readonly property color panelElevated: "#1e1e1e"
    readonly property color surface: "#222222"
    readonly property color surfaceAlt: "#242424"
    readonly property color item: "#202020"
    readonly property color itemSelected: "#252b2b"
    readonly property color itemHover: "#202525"
    readonly property color clipboardImage: "#343434"
    readonly property color clipboardText: "#292929"

    // Borders
    readonly property color border: "#303030"
    readonly property color borderSubtle: "#282828"
    readonly property color borderAccent: "#00cccc"
    readonly property color borderStrong: "#666666"
    readonly property color borderFocused: "#777777"

    // Text
    readonly property color text: "#eeeeee"
    readonly property color textWhite: "#ffffff"
    readonly property color textMuted: "#aaaaaa"
    readonly property color textSecondary: "#999999"
    readonly property color textDim: "#888888"
    readonly property color textDisabled: "#777777"
    readonly property color textVeryDim: "#666666"
    readonly property color textClipboard: "#dddddd"

    // Mode selector
    readonly property color modeSelected: "#252b2b"
    readonly property color modeNormal: "#1b1b1b"
    readonly property color modeSelectedText: "#ffffff"
    readonly property color modeNormalText: "#888888"
    readonly property color selectedText: "#ffffff"
    readonly property color selectedSubtext: "#9adede"

    // Main shell
    readonly property color barBackground: "#cc181818"
    readonly property color verticalBarBackground: "#00f81818"
    readonly property color accent: "#00cccc"
    readonly property color nonAccent: "#cccccc"
    readonly property color inactive: "#777777"
    readonly property string fontFamily: "LED"
    readonly property color hover: "#313244"
    readonly property color networkSignal: "#88ff88"
    readonly property color batteryEmpty: "#ff0000"
    readonly property color batteryCharging: "#006600"
    readonly property color batteryDischarging: "#006666"
}

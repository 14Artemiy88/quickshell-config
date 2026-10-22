
import QtQuick
import "../../.."

QtObject {
    // Global surfaces
    readonly property color backdrop: Config.black
    readonly property color transparent: "#00000000"
    readonly property real backdropOpacity: Config.launcherBackdropOpacity
    readonly property color background: Config.settingsBackground
    readonly property color launcherBackground: Config.launcherBackground
    readonly property color panel: Config.calendarBackground
    readonly property color panelElevated: Config.settingsBackground
    readonly property color surface: "#00000000"
    readonly property color surfaceAlt: Config.background
    readonly property color item: "#00000000"
    readonly property color itemSelected: "#00000000"
    readonly property color itemHover: Config.background
    readonly property color clipboardImage: Config.calendarBackground
    readonly property color clipboardText: Config.background

    // Borders
    readonly property color border: Config.baseColor
    readonly property color borderSubtle: Config.background
    readonly property color borderAccent: Config.accent
    readonly property color borderStrong: Config.settingsBorder
    readonly property color borderFocused: Config.accent

    // Text
    readonly property color text: Config.text
    readonly property color textWhite: Config.text
    readonly property color textMuted: Config.textMuted
    readonly property color textSecondary: Config.textMuted
    readonly property color textDim: Config.textDim
    readonly property color textDisabled: Config.textDisabled
    readonly property color textVeryDim: Config.textDisabled
    readonly property color textClipboard: Config.textMuted

    // Mode selector
    readonly property color modeSelected: "#00000000"
    readonly property color modeNormal: "#00000000"
    readonly property color modeSelectedText: Config.text
    readonly property color modeNormalText: Config.textMuted
    readonly property color selectedText: Config.text
    readonly property color selectedSubtext: Config.currentWeather

    // Main shell
    readonly property color barBackground: Config.settingsBackground
    readonly property color verticalBarBackground: Config.background
    readonly property color accent: Config.accent
    readonly property color nonAccent: Config.textDim
    readonly property color inactive: Config.textDisabled
    readonly property string fontFamily: Config.ledFont
    readonly property string iconFontFamily: "Symbols Nerd Font Mono"
    readonly property color hover: Config.baseColor
    readonly property color networkSignal: Config.networkUpload
    readonly property color batteryEmpty: Config.tempHot
    readonly property color batteryCharging: Config.networkUpload
    readonly property color batteryDischarging: Config.accent
}

pragma Singleton

import QtQuick
import "../../launcher/theme"

QtObject {
    // Theme is a regular QML type, so it must be declared as a property.
    // A bare `Theme {}` child is invalid inside QtObject because QtObject
    // has no default child-object property.
    readonly property var theme: Theme {}

    // Kept for compatibility with modules that still use Config.
    readonly property color accentColor: theme.accent
    readonly property color nonAccentColor: theme.nonAccent
    readonly property color inactiveColor: theme.inactive
    readonly property string font: theme.fontFamily
}

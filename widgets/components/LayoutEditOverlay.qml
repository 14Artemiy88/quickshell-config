import QtQuick
import ".."

Item {
    // Layout editing is handled by the dedicated full-screen editor window
    // in shell.qml. Keeping this component as a harmless no-op preserves
    // compatibility with any existing imports without creating nested drag
    // feedback inside the widgets themselves.
    visible: false
}

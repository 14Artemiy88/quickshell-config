//@ pragma UseQApplication

import Niri 0.1
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import "./launcher/"
import "./modules/common/"
import "./modules/horizontal/"
import "./modules/vertical/"

ShellRoot {
    id: root

    Niri {
        id: niri
        Component.onCompleted: connect()

        onConnected: console.info("Connected to niri")
        onErrorOccurred: function (error) {
            console.error("Niri error:", error);
        }
    }

    Launcher {
        id: launcher
        visible: false
        niriBackend: niri
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            launcher.toggleLauncher()
        }

        function show(): void {
            launcher.showLauncher()
        }

        function hide(): void {
            launcher.hideLauncher()
        }
    }

    LazyLoader {
        active: true
        component: Bar {}
    }
    LazyLoader {
        active: true
        component: Networks {}
    }
    LazyLoader {
        active: true
        component: VBar {}
    }
}

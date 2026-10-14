import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root
    readonly property bool enabled: Settings.loaded && (Settings.topAppsCpu || Settings.topAppsRam || Settings.networkStat || Settings.volumes || Settings.networks)

    property var data: ({
        top_apps: { cpu: [], mem: [] },
        net_stat: { down: "0 B", up: "0 B", speed_down: "0 B/s", speed_up: "0 B/s" },
        volumes: [],
        network: []
    })

    Process {
        id: proc
        command: [
            "bash",
            Quickshell.shellDir + "/scripts/system_monitor",
            (Settings.topAppsCpu || Settings.topAppsRam) ? "1" : "0",
            Settings.networkStat ? "1" : "0",
            Settings.volumes ? "1" : "0",
            Settings.networks ? "1" : "0",
            Settings.topAppsCpu ? "1" : "0",
            Settings.topAppsRam ? "1" : "0",
            Config.topAppsShowSystemRemainder ? "1" : "0",
            Config.topAppsSystemRemainderLabel
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.data = JSON.parse(this.text) } catch (e) { console.warn("system_monitor:", e) }
                proc.running = false
            }
        }
    }

    Timer {
        interval: Config.systemMonitorInterval
        running: root.enabled
        triggeredOnStart: true
        repeat: true
        onTriggered: if (root.enabled && !proc.running) proc.running = true
    }

    Connections {
        target: Settings
        function onTopAppsCpuChanged() { root.syncProcess() }
        function onTopAppsRamChanged() { root.syncProcess() }
        function onNetworkStatChanged() { root.syncProcess() }
        function onVolumesChanged() { root.syncProcess() }
        function onNetworksChanged() { root.syncProcess() }
        function onLoadedChanged() { root.syncProcess() }
    }

    Connections {
        target: Config
        function onTopAppsShowSystemRemainderChanged() { root.syncProcess() }
        function onTopAppsSystemRemainderLabelChanged() { root.syncProcess() }
    }

    function syncProcess() {
        if (root.enabled && !proc.running)
            proc.running = true
        else if (!root.enabled && proc.running)
            proc.running = false
    }
}

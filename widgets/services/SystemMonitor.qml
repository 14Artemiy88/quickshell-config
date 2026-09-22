import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root
    readonly property bool enabled: Settings.loaded && (Settings.topApps || Settings.networkStat || Settings.volumes || Settings.networks)

    property var data: ({
        top_apps: { cpu: [], mem: [] },
        net_stat: { down: "0 B", up: "0 B", speed_down: "0 B", speed_up: "0 B" },
        volumes: [],
        current_volume: 0,
        network: []
    })

    Process {
        id: proc
        command: ["bash", Quickshell.shellDir + "/scripts/system_monitor"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.data = JSON.parse(this.text) } catch (e) { console.warn("system_monitor:", e) }
                proc.running = false
            }
        }
    }

    Timer {
        interval: 1000
        running: root.enabled
        triggeredOnStart: true
        repeat: true
        onTriggered: if (root.enabled && !proc.running) proc.running = true
    }

    Connections {
        target: Settings
        function onTopAppsChanged() { root.syncProcess() }
        function onNetworkStatChanged() { root.syncProcess() }
        function onVolumesChanged() { root.syncProcess() }
        function onNetworksChanged() { root.syncProcess() }
        function onLoadedChanged() { root.syncProcess() }
    }

    function syncProcess() {
        if (root.enabled && !proc.running)
            proc.running = true
        else if (!root.enabled && proc.running)
            proc.running = false
    }
}

#!/usr/bin/env bash
set -euo pipefail
widget="$(dirname "$0")/../components/settings/SettingsWidget.qml"
network="$(dirname "$0")/../components/settings/sections/SettingsNetworkSection.qml"
cpu="$(dirname "$0")/../components/settings/sections/SettingsCpuRamSection.qml"
# Shared update intervals should be edited in their owning section, not duplicated in the widget host.
! grep -Fq 'label: "System Monitor (мс) — общие данные"' "$widget"
! grep -Fq 'label: "CPU (мс)"' "$widget"
grep -Fq 'targetProperty: "systemMonitorInterval"' "$network"
grep -Fq 'targetProperty: "cpuUpdateInterval"' "$cpu"
# Player's own refresh interval remains in the Player tab.
grep -Fq 'label: "Плеер (мс)"' "$widget"
echo 'duplicate update interval controls: OK'

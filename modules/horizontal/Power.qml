import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

import qs.modules.common

Rectangle {
    readonly property var borderRadius: 5
    readonly property var batteryBarWidth: 36
    readonly property var batteryLow: 40
    readonly property var batteryCrit: 20
    readonly property var batterySuspend: 5

    property var chargeState: UPower.displayDevice.state
    property bool isCharging: chargeState == UPowerDeviceState.Charging
    property bool isPluggedIn: isCharging || chargeState == UPowerDeviceState.PendingCharge
    property real percentage: UPower.displayDevice?.percentage ?? 1
    readonly property bool allowAutomaticSuspend: Config.data.battery.automaticSuspend

    property bool available: UPower.displayDevice.isLaptopBattery
    property bool isLow: available && (percentage <= batteryLow / 100)
    property bool isCritical: available && (percentage <= batteryCrit / 100)
    property bool isSuspending: available && (percentage <= batterySuspend / 100)

    property bool isLowAndNotCharging: isLow && !isCharging
    property bool isCriticalAndNotCharging: isCritical && !isCharging
    property bool isSuspendingAndNotCharging: allowAutomaticSuspend && isSuspending && !isCharging

    property real energyRate: UPower.displayDevice.changeRate
    property real timeToEmpty: UPower.displayDevice.timeToEmpty
    property real timeToFull: UPower.displayDevice.timeToFull

    property string chsrgePercent: Math.round(UPower.displayDevice.percentage * 100) + "%"

    onIsLowAndNotChargingChanged: {
        if (available && isLowAndNotCharging)
            // Quickshell.execDetached(["notify-send", "Low battery", "Consider plugging in your device", "-u", "critical", "-a", "Shell"]);
            Quickshell.execDetached(["sh", "-c", `dunstify "Батарея: ` + chsrgePercent + `"  -h int:value:` + chsrgePercent]);
    }

    onIsCriticalAndNotChargingChanged: {
        if (available && isCriticalAndNotCharging)
            // Quickshell.execDetached(["notify-send", "Critically low battery", "Please charge!\nAutomatic suspend triggers at %1".arg(Config.data.power.battery.suspend), "-u", "critical", "-a", "Shell"]);
            Quickshell.execDetached(["sh", "-c", `dunstify -u critical "Батарея: ` + chsrgePercent + `"  -h int:value:` + chsrgePercent]);
    }

    onIsSuspendingAndNotChargingChanged: {
        if (available && isSuspendingAndNotCharging) {
            Quickshell.execDetached(["sh", "-c", `systemctl suspend || loginctl suspend`]);
        }
    }

    anchors.top: parent.top
    anchors.topMargin: -7
    implicitWidth: 40

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 0
            topMargin: 10
        }
        color: "#ff0000"
        // border.color: "#999999"
        // border.width: 1
        width: batteryBarWidth
        height: 3
        radius: borderRadius
    }
    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 0
            topMargin: 10
        }
        color: isCharging ? "#006600" : "#006666"
        width: batteryBarWidth * UPower.displayDevice.percentage
        height: 3
        radius: borderRadius
    }

    Text {
        id: powerDisplay
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 2
            topMargin: -2
        }
        text: chsrgePercent
        color: Config.nonAccentColor
        font.family: Config.font
        font.pixelSize: 14
        Component.onCompleted: {
            parent.width = powerDisplay.contentWidth;
        }
    }
    Text {
        id: flash

        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 26
            topMargin: -4
        }
        text: isCharging ? "󰉁" : ""
        color: Config.nonAccentColor
        font.pixelSize: 12
        Component.onCompleted: {
            parent.width = powerDisplay.contentWidth;
        }
    }
}

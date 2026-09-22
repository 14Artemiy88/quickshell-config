import QtQuick
import ".."
import Quickshell

Frame {
    id: root
    width: 315
    height: 80
    property var weather: ({})
    property var weatherService: null

    function windAngle(scale) {
        const n = Number(scale || 0)
        return n > 0 ? ((n - 1) * 45 - 45) : 0
    }

    Item {
        x: 0
        y: 0
        width: 100
        height: parent.height

        Text {
            x: 10
            y: 0
            width: 90
            height: 55
            text: root.weather.temperature?.air?.C ?? ""
            color: Config.currentWeather
            font.family: Config.ledFont
            font.pixelSize: 55
            lineHeight: 55
            lineHeightMode: Text.FixedHeight
            verticalAlignment: Text.AlignTop
        }

        Text {
            x: 10
            y: 39
            width: 90
            height: 35
            text: root.weather.temperature?.comfort?.C !== root.weather.temperature?.air?.C
                  ? (root.weather.temperature?.comfort?.C ?? "") : ""
            color: Config.textMuted
            font.family: Config.ledFont
            font.pixelSize: 35
            lineHeight: 35
            lineHeightMode: Text.FixedHeight
            verticalAlignment: Text.AlignTop
        }
    }

    // The icon is centered against the full weather block, not the remaining
    // space between the temperature and wind/pressure columns.
    Image {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 13
        width: 55
        height: 53
        fillMode: Image.PreserveAspectFit
        source: root.weather.icon
                ? (Quickshell.shellDir + "/assets/gismeteo/new_png/" + root.weather.icon + ".png")
                : ""
    }

    Item {
        x: 180
        y: 0
        width: 120
        height: parent.height

        Item {
            x: 0
            y: 0
            width: 120
            height: 40

            // Arrow, speed, unit: < 0 м/с
            Text {
                id: windArrow
                // Keep the speed position unchanged; place the arrow directly against
                // the speed field, keeping the speed position unchanged.
                x: 40
                y: -6
                width: 17
                height: 35
                text: root.weather.wind?.direction?.scale_8 > 0 ? "\uF124" : ""
                color: Config.text
                font.family: Config.font
                font.pixelSize: 22
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                transformOrigin: Item.Center
                rotation: root.windAngle(root.weather.wind?.direction?.scale_8)
            }

            Text {
                x: 36
                y: 4
                width: 47
                height: 25
                text: root.weather.wind?.speed?.m_s ?? ""
                color: Config.text
                font.family: Config.ledFont
                font.pixelSize: 25
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignTop
            }

            Text {
                x: 86
                y: 9
                width: 34
                height: 18
                text: "м/с"
                color: Config.text
                font.family: Config.ledFont
                font.pixelSize: 15
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignTop
            }
        }

        Item {
            x: 0
            y: 33
            width: 120
            height: 25

            Text {
                x: 0
                y: 0
                width: 74
                height: 20
                text: root.weather.pressure?.mm_hg_atm ?? ""
                color: Config.text
                font.family: Config.ledFont
                font.pixelSize: 20
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignTop
            }

            Text {
                x: 74
                y: 9
                width: 46
                height: 12
                text: "MM.PT.CT"
                color: Config.text
                font.family: Config.ledFont
                font.pixelSize: 10
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignTop
            }
        }

        Text {
            x: 0
            y: 58
            width: 120
            height: 16
            text: root.weather.description?.full ?? ""
            color: Config.text
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignTop
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: {
            if (mouse.button === Qt.RightButton && root.weatherService)
                root.weatherService.manualRefresh()
        }
    }

}

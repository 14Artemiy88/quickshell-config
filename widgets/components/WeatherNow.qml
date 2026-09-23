import QtQuick
import ".."
import Quickshell

Frame {
    id: root
    width: 315
    height: 80
    property var weather: ({})
    property var weatherService: null
    property bool hasData: weather && Object.keys(weather).length > 0
    property string statusMessage: weatherService ? weatherService.nowStatusMessage : "Погода недоступна"

    function windAngle(scale) {
        const n = Number(scale || 0)
        return n > 0 ? ((n - 1) * 45 - 45) : 0
    }

    Item {
        x: 0
        y: 0
        width: Config.weatherTempColumnWidth
        height: parent.height

        Text {
            x: Config.weatherTempX
            y: 0
            width: Config.weatherTempWidth
            height: 55
            text: root.weather.temperature?.air?.C ?? ""
            color: Config.currentWeather
            font.family: Config.ledFont
            font.pixelSize: Config.weatherTempFontSize
            lineHeight: 55
            lineHeightMode: Text.FixedHeight
            verticalAlignment: Text.AlignTop
        }

        Text {
            x: Config.weatherTempX
            y: Config.weatherComfortY
            width: Config.weatherTempWidth
            height: Config.weatherComfortHeight
            text: root.weather.temperature?.comfort?.C !== root.weather.temperature?.air?.C
                  ? (root.weather.temperature?.comfort?.C ?? "") : ""
            color: Config.textMuted
            font.family: Config.ledFont
            font.pixelSize: Config.weatherComfortFontSize
            lineHeight: Config.weatherComfortHeight
            lineHeightMode: Text.FixedHeight
            verticalAlignment: Text.AlignTop
        }
    }

    Image {
        visible: root.hasData
        anchors.horizontalCenter: parent.horizontalCenter
        y: Config.weatherIconY
        width: Config.weatherIconSize
        height: Config.weatherIconSize
        fillMode: Image.PreserveAspectFit
        source: root.weather.icon
                ? (Quickshell.shellDir + "/assets/gismeteo/new_png/" + root.weather.icon + ".png")
                : ""
    }

    Item {
        x: Config.weatherWindColumnX
        y: 0
        width: Config.weatherWindColumnWidth
        height: parent.height
        visible: root.hasData

        Item {
            x: 0
            y: 0
            width: Config.weatherWindColumnWidth
            height: 40

            Text {
                id: windArrow
                x: windSpeed.x - width + Config.weatherWindArrowGap
                y: Config.weatherArrowYOffset
                width: Config.weatherWindArrowWidth
                height: Config.weatherWindArrowHeight
                text: root.weather.wind?.direction?.scale_8 > 0 ? "\uF124" : ""
                color: Config.text
                font.family: Config.font
                font.pixelSize: Config.weatherArrowSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                transformOrigin: Item.Center
                rotation: root.windAngle(root.weather.wind?.direction?.scale_8)
            }

            Text {
                id: windSpeed
                x: Config.weatherWindSpeedX
                y: Config.weatherWindSpeedY
                width: Config.weatherWindSpeedWidth
                height: 25
                text: root.weather.wind?.speed?.m_s ?? ""
                color: Config.text
                font.family: Config.ledFont
                font.pixelSize: Config.weatherWindSpeedFontSize
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignTop
            }

            Text {
                x: Config.weatherWindUnitX
                y: Config.weatherWindUnitY
                width: Config.weatherWindUnitWidth
                height: 18
                text: "м/с"
                color: Config.text
                font.family: Config.ledFont
                font.pixelSize: Config.weatherWindUnitFontSize
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignTop
            }
        }

        Item {
            x: 0
            y: Config.weatherPressureY
            width: Config.weatherWindColumnWidth
            height: 25

            Text {
                x: 0
                y: 0
                width: Config.weatherPressureValueWidth
                height: 20
                text: root.weather.pressure?.mm_hg_atm ?? ""
                color: Config.text
                font.family: Config.ledFont
                font.pixelSize: Config.weatherPressureFontSize
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignTop
            }

            Text {
                x: Config.weatherPressureUnitX
                y: Config.weatherPressureUnitY
                width: Math.max(1, Config.weatherWindColumnWidth - Config.weatherPressureUnitX)
                height: 12
                text: "MM.PT.CT"
                color: Config.text
                font.family: Config.ledFont
                font.pixelSize: Config.weatherPressureUnitFontSize
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignTop
            }
        }

        Text {
            x: 0
            y: Config.weatherDescriptionY
            width: Config.weatherWindColumnWidth
            height: Config.weatherDescriptionHeight
            text: root.weather.description?.full ?? ""
            color: Config.text
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignTop
            font.pixelSize: Config.uiFontSize(Config.weatherDescriptionFontSize)
            elide: Text.ElideRight
        }
    }

    WeatherPlaceholder {
        visible: !root.hasData
        message: root.statusMessage
        weatherService: root.weatherService
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

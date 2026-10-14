import QtQuick
import "primitives" as Primitives
import ".."
import Quickshell

Primitives.ModuleFrame {
    id: root
    moduleName: "weatherNow"
    width: 315
    height: 80
    property var weather: ({})
    property var weatherService: null
    property bool hasData: weather && Object.keys(weather).length > 0
    property string statusMessage: weatherService ? weatherService.nowStatusMessage : "Погода недоступна"
    signal settingsRequested()

    function windDirectionKey(scale) {
        const n = Math.round(Number(scale || 0))
        switch (n) {
        case 1: return "N"
        case 2: return "NE"
        case 3: return "E"
        case 4: return "SE"
        case 5: return "S"
        case 6: return "SW"
        case 7: return "W"
        case 8: return "NW"
        default: return "Calm"
        }
    }

    function windIcon(scale) {
        return Config["weatherWind" + windDirectionKey(scale) + "Icon"] || ""
    }

    function windFont(scale) {
        return Config["weatherWind" + windDirectionKey(scale) + "Font"] || Config.font
    }

    Item {
        x: 0
        y: 0
        width: Config.weatherTempColumnWidth
        height: parent.height

        Text {
            x: Config.weatherTempX + Config.weatherTempOffsetX
            y: Config.weatherTempOffsetY
            width: Config.weatherTempWidth
            height: 55
            text: root.weather.temperature?.air?.C ?? ""
            color: Config.currentWeather
            font.family: Config.ledFont
            font.pixelSize: Config.weatherTempFontSize
            lineHeight: 55
            lineHeightMode: Text.FixedHeight
            verticalAlignment: Text.AlignTop
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            visible: Config.weatherShowComfort
            x: Config.weatherTempX + Config.weatherComfortOffsetX
            y: Config.weatherComfortY + Config.weatherComfortOffsetY
            width: Config.weatherTempWidth
            height: Config.weatherComfortHeight
            text: root.weather.temperature?.comfort?.C !== root.weather.temperature?.air?.C
                  ? (root.weather.temperature?.comfort?.C ?? "") : ""
            color: Config.textMuted
            style: Text.Outline
            styleColor: Config.background
            font.family: Config.ledFont
            font.pixelSize: Config.weatherComfortFontSize
            lineHeight: Config.weatherComfortHeight
            lineHeightMode: Text.FixedHeight
            verticalAlignment: Text.AlignTop
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Image {
        visible: root.hasData
        x: (Config.weatherTempColumnWidth + Config.weatherWindColumnX - width) / 2
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
                text: root.windIcon(root.weather.wind?.direction?.scale_8)
                color: Config.text
                font.family: root.windFont(root.weather.wind?.direction?.scale_8)
                font.pixelSize: Config.weatherArrowSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
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
        onSettingsRequested: root.settingsRequested()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton && root.weatherService)
                root.weatherService.manualRefresh()
        }
    }
}

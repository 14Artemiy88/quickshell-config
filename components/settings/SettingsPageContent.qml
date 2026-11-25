import QtQuick
import "../.."
import "sections"
import "pages" as SettingsPages

// Owns the declarative assembly of every settings page. Navigation state,
// search, profile handling and routing remain in SettingsWidget and are
// provided explicitly through host/settings properties.
Item {
    id: root

    property var host: null
    property var settings: Settings

    function resetScroll() {
        if (modulesSectionSettingsSection) modulesSectionSettingsSection.resetScroll()
        if (colorsSectionSettingsSection) colorsSectionSettingsSection.resetScroll()
        if (otherSettingsArea) otherSettingsArea.resetScroll()
    }

        SettingsModulesSection {
            id: modulesSectionSettingsSection
            objectName: "settings-search-page:modules"
            host: root.host
            settings: root.settings
        }

        SettingsColorsSection {
            id: colorsSectionSettingsSection
            objectName: "settings-search-page:themes"
            host: root.host
            settings: root.settings
        }

        SettingsPageHost {
            id: otherSettingsArea
            host: root.host
            settings: root.settings
            visible: root.host.currentPageId !== "modules" && root.host.currentPageId !== "themes"
            width: parent.width
            height: parent.height

            SettingsTimeSection {
                id: timeSectionSettingsSection
                objectName: "settings-search-page:time"
                host: root.host
                settings: root.settings
            }

            SettingsDashboardSection {
                id: dashboardSectionSettingsSection
                objectName: "settings-search-page:dashboard"
                host: root.host
                settings: root.settings
            }

            SettingsCalendarSection {
                id: calendarSectionSettingsSection
                objectName: "settings-search-page:calendar"
                host: root.host
                settings: root.settings
            }

            SettingsWeatherSection {
                id: weatherSectionSettingsSection
                objectName: "settings-search-page:weather"
                host: root.host
                settings: root.settings
            }
            SettingsWeatherAnimationSection {
                host: root.host
                settings: root.settings
            }

            SettingsGeneralSection {
                id: generalSectionSettingsSection
                objectName: "settings-search-page:general"
                host: root.host
                settings: root.settings
            }

            SettingsPages.SettingsPlayerPage {
                host: root.host
                settings: root.settings
            }
            SettingsPages.SettingsMopidyPage {
                host: root.host
                settings: root.settings
            }
            SettingsCavaSection {
                id: cavaSectionSettingsSection
                objectName: "settings-search-page:cava"
                host: root.host
                settings: root.settings
            }
            SettingsCpuRamSection {
                id: cpuRamSectionSettingsSection
                objectName: "settings-search-page:cpuRam"
                host: root.host
                settings: root.settings
            }
            SettingsNetworkSection {
                id: networkSectionSettingsSection
                objectName: "settings-search-page:network"
                host: root.host
                settings: root.settings
            }
            SettingsVolumeSection {
                id: volumeSectionSettingsSection
                objectName: "settings-search-page:volume"
                host: root.host
                settings: root.settings
            }
            SettingsTimersSection {
                id: timersSectionSettingsSection
                objectName: "settings-search-page:timers"
                visible: root.host.currentPageId === "timers"
                width: parent.width
                host: root.host
                settings: root.settings
            }
            SettingsLauncherSection {
                id: launcherSectionSettingsSection
                objectName: "settings-search-page:launcher"
                host: root.host
                settings: root.settings
            }
            SettingsWindowSection {
                id: settingsWindowSectionSettingsSection
                objectName: "settings-search-page:settingsWindow"
                host: root.host
                settings: root.settings
            }
            SettingsNotificationsSection {
                id: notificationsSectionSettingsSection
                objectName: "settings-search-page:notifications"
                host: root.host
                settings: root.settings
            }
        }
}

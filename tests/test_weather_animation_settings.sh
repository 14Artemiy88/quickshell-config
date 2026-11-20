#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1])
def read(path): return (root/path).read_text(encoding='utf-8')

config=read('Config.qml')
defaults=read('js/settings/SettingsDefaults.js')
persistence=read('js/settings/SettingsPersistence.js')
apply=read('js/settings/SettingsApplyBehaviour.js')
profiles=read('js/settings/SettingsProfiles.js')
resets=read('js/settings/SettingsResets.js')
settings=read('Settings.qml')
registry=read('js/settings/SettingsPageRegistry.js')
navigation=read('components/settings/SettingsNavigationController.qml')
page=read('components/settings/SettingsPageContent.qml')
section=read('components/settings/sections/SettingsWeatherAnimationSection.qml')
weather_now=read('components/WeatherNow.qml')
placeholder=read('components/WeatherPlaceholder.qml')
forecast=read('components/WeatherForecastItem.qml')
weather_list=read('components/WeatherList.qml')

keys=(
    'animationWeatherMorphEnabled',
    'animationWeatherMorphDuration',
    'animationWeatherHourlyDuration',
    'animationWeatherMorphProfile',
)
expected=(
    'property bool animationWeatherMorphEnabled: true',
    'property int animationWeatherMorphDuration: 180',
    'property int animationWeatherHourlyDuration: 220',
    'property string animationWeatherMorphProfile: "expressive"',
)
for token,key in zip(expected,keys):
    assert token in config, f'missing Config property: {token}'
    assert f'{key}: ' in defaults, f'missing profile default: {key}'
    if key != 'animationWeatherMorphEnabled':
        assert f'{key}: config.{key}' in persistence, f'{key} missing from persistence snapshot'
    assert f'"{key}"' in resets, f'{key} missing from Weather reset'

assert 'animationWeatherMorphEnabled: config.animationWeatherMorphEnabled' not in persistence
assert 'animationWeatherMorphEnabled' in persistence[persistence.index('var managedKeys'):]
assert 'var legacyWeatherMorphEnabled = o.animationWeatherMorphEnabled' in apply
assert 'Config.animationWeatherMorphEnabled = true' in apply
assert 'if (legacyWeatherMorphEnabled === false)' in apply and 'Config.animationWeatherMorphProfile = "none"' in apply
assert 'Math.max(0, Math.min(5000, Math.round(weatherMorphDuration)))' in apply
assert 'Math.max(0, Math.min(5000, Math.round(weatherHourlyDuration)))' in apply
assert 'var allowedWeatherMorphProfiles = ["none", "standard", "spatial", "effects", "expressive"]' in apply
assert 'weather: ["weather", "animationWeather"]' in profiles
assert 'weatherNow: ["weather", "animationWeather"]' in profiles
assert 'weather: ["weather", "animationWeather"]' in settings
assert 'weatherNow: ["weather", "animationWeather"]' in settings

assert '{ id: "weather", saveScope: "weather", subTabs: ["Общие", "Сейчас", "По часам", "По дням", "Анимация"] }' in registry
assert '{ keys: ["animationWeatherMorphDuration", "animationWeatherHourlyDuration", "animationWeatherMorphProfile"] }' in navigation
assert 'SettingsWeatherAnimationSection {' in page
assert 'currentPageSubTabIndex === 4' in section
assert 'import \"../../..\"' in section
assert 'SettingsAnimationGroup {' in section
assert 'animationsEnabled:' not in section
assert 'duration: Config.animationWeatherMorphDuration' in section
assert 'profile: Config.animationWeatherMorphProfile' in section
assert 'onAnimationEnabledEdited:' not in section and 'onDurationEdited:' in section and 'onProfileEdited:' in section
assert 'targetProperty: "animationWeatherHourlyDuration"' in section

assert 'visible: Config.animationWeatherMorphProfile !== \"none\"' not in section, 'hourly duration visibility belongs to the shared animated details group'

# All seven existing MorphGeometry transitions use module settings. Forecast
# image rendering remains direct and the hourly strip retains its 220 ms default.
assert weather_now.count('animationDuration: Config.animationDurationForProfile(Config.animationWeatherMorphEnabled, Config.animationWeatherMorphProfile, Config.animationWeatherMorphDuration, \"appearance\")') == 3
assert weather_now.count('animationProfile: Config.animationWeatherMorphProfile') == 3
assert 'animationDuration: Config.animationDurationForProfile(Config.animationWeatherMorphEnabled, Config.animationWeatherMorphProfile, Config.animationWeatherMorphDuration, \"appearance\")' in placeholder
assert 'animationProfile: Config.animationWeatherMorphProfile' in placeholder
assert forecast.count('animationDuration: root.forecastMorphDuration') == 2
assert forecast.count('animationProfile: Config.animationWeatherMorphProfile') == 2
assert 'readonly property int forecastMorphDuration: Config.animationDurationForProfile(Config.animationWeatherMorphEnabled, Config.animationWeatherMorphProfile, Config.animationWeatherMorphDuration, \"appearance\")' in forecast
assert 'readonly property int hourlyMorphDuration: Config.animationDurationForProfile(Config.animationWeatherMorphEnabled, Config.animationWeatherMorphProfile, Config.animationWeatherHourlyDuration, \"appearance\")' in weather_list
assert weather_list.count('animationProfile: Config.animationWeatherMorphProfile') == 1
assert 'easing.type: Config.animationEasingType(Config.animationWeatherMorphProfile, root.hourlyMorphPhase)' in weather_list
assert 'easing.bezierCurve: Config.animationBezierCurve(Config.animationWeatherMorphProfile, root.hourlyMorphPhase)' in weather_list
assert 'Image {' in forecast and 'MorphGeometry' not in forecast[forecast.index('Image {'):forecast.index('Primitives.MorphGeometry {')]
assert 'animationDuration: Config.animationDuration(180, "appearance")' not in weather_now+placeholder+forecast
assert 'animationDuration: Config.animationDuration(220, "appearance")' not in weather_list
print('Weather animation settings: defaults, persistence, profile scopes, reset, UI routing, all live morphs and hourly scroll: OK')
PY

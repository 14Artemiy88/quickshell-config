#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
NAV="$ROOT/components/settings/SettingsNavigation.qml"
CONTENT="$ROOT/components/settings/SettingsPageContent.qml"
CONTROLLER="$ROOT/components/settings/SettingsSearchController.qml"
PLAYER_PAGE="$ROOT/components/settings/pages/SettingsPlayerPage.qml"
MOPIDY_PAGE="$ROOT/components/settings/pages/SettingsMopidyPage.qml"
fail() { echo "Settings search UI: FAIL: $*" >&2; exit 1; }

for page in modules themes general timers weather cava cpuRam network volume calendar launcher notifications settingsWindow; do
    grep -Fq "settings-search-page:$page" "$CONTENT" || fail "page $page is missing from the search index tree"
done
grep -Fq 'settings-search-page:player' "$PLAYER_PAGE" || fail 'player page root is missing from the search index tree'
grep -Fq 'settings-search-page:mopidy' "$MOPIDY_PAGE" || fail 'Mopidy page root is missing from the search index tree' 

for primitive in SettingsNumberField SettingsColorField SettingsFontField SettingsCheckBox SettingsComboBox SettingsTextField; do
    file="$ROOT/components/settings/primitives/$primitive.qml"
    grep -Fq 'property bool settingsSearchable: true' "$file" || fail "$primitive is not searchable"
    grep -Fq 'property string settingsSearchId:' "$file" || fail "$primitive has no stable-id override"
    grep -Fq 'property string settingsSearchLabel:' "$file" || fail "$primitive has no explicit search label"
done

grep -Fq 'placeholderText: "Поиск настроек…"' "$NAV" || fail 'global search field is missing'
grep -Fq 'settingsSearchLabel: "Лаунчер · "' "$ROOT/components/settings/sections/SettingsModulesSection.qml" || fail 'launcher coordinates have no human-readable search labels'
grep -Fq 'settingsSearchId: "module." + moduleRow.moduleName + ".geometry."' "$ROOT/components/settings/sections/SettingsModulesSection.qml" || fail 'module geometry controls have no stable dynamic IDs'
grep -Fq 'settingsSearchLabel: "Блюр "' "$ROOT/components/settings/sections/SettingsModulesSection.qml" || fail 'module blur controls are not indexed'
grep -Fq 'SettingsSearchController {' "$WIDGET" || fail 'dedicated search controller is not mounted'
grep -Fq 'function rebuildSettingsSearchIndex()' "$CONTROLLER" || fail 'search index builder is missing'
grep -Fq 'navigationGroupLabel: navigationGroupLabel' "$CONTROLLER" || fail 'search index does not retain the navigation group label'
grep -Fq 'SettingsSearch.search(root.settingsSearchIndex, root.settingsSearchQuery, root.settingsSearchIndex.length)' "$CONTROLLER" || fail 'in-place search does not retain a broad match set'
grep -Fq 'function settingsSearchSubTabHasMatches(pageId, subTabIndex)' "$CONTROLLER" || fail 'subtab breadcrumb highlighting is missing'
grep -Fq 'function applySettingsSearchHighlights()' "$CONTROLLER" || fail 'matching controls and ancestor sections are not outlined'
grep -Fq 'settingsSearchMatched: root.host.settingsSearchPageHasMatches(parent.modelData.id)' "$NAV" || fail 'matching page tabs are not outlined'
grep -Fq 'settingsSearchMatched: root.host && root.host.settingsSearchSubTabHasMatches(root.host.currentPageId, index)' "$ROOT/components/settings/SettingsPageHost.qml" || fail 'matching page subtabs are not outlined'
grep -Fq 'settingsSearchHighlighted: false' "$ROOT/components/settings/primitives/SettingsGroup.qml" || fail 'section frames cannot receive search outlines'
grep -Fq 'SettingsSearchHighlight {' "$ROOT/components/settings/primitives/SettingsGroup.qml" || fail 'section frames do not host the shared search-highlight primitive'
grep -Fq 'highlighted: root.settingsSearchHighlighted' "$ROOT/components/settings/primitives/SettingsGroup.qml" || fail 'section frames do not forward their search-match state'
grep -Fq 'Config.settingsSearchHighlightColor' "$ROOT/components/settings/primitives/SettingsSearchHighlight.qml" || fail 'shared section outlines do not use the configurable highlight color'
! grep -Fq 'settingsSearchPopup' "$WIDGET" || fail 'separate popup results window still exists'
grep -Fq 'clearButtonEnabled: text.length > 0' "$NAV" || fail 'search field cannot clear its active query'
grep -Fq 'property bool clearButtonEnabled: false' "$ROOT/components/settings/primitives/SettingsInputField.qml" || fail 'SettingsInputField does not expose the optional clear-button API'
grep -Fq 'visible: root.clearButtonEnabled && root.text.length > 0' "$ROOT/components/settings/primitives/SettingsInputField.qml" || fail 'SettingsInputField clear button is not connected to its enabled state and text'
grep -Fq 'settingsSearchHighlightColor' "$ROOT/components/settings/sections/SettingsWindowSection.qml" || fail 'search outline color is not configurable in Settings Window'

echo 'Settings global search: searchable primitives, in-place path/control outlines, clickable subtabs and configurable highlight color: OK'

#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
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

grep -Fq 'placeholderText: "Поиск настроек…"' "$WIDGET" || fail 'global search field is missing'
grep -Fq 'settingsSearchLabel: "Лаунчер · "' "$ROOT/components/settings/sections/SettingsModulesSection.qml" || fail 'launcher coordinates have no human-readable search labels'
grep -Fq 'settingsSearchId: "module." + moduleRow.moduleName + ".geometry."' "$ROOT/components/settings/sections/SettingsModulesSection.qml" || fail 'module geometry controls have no stable dynamic IDs'
grep -Fq 'settingsSearchLabel: "Блюр "' "$ROOT/components/settings/sections/SettingsModulesSection.qml" || fail 'module blur controls are not indexed'
grep -Fq 'SettingsSearchController {' "$WIDGET" || fail 'dedicated search controller is not mounted'
grep -Fq 'function rebuildSettingsSearchIndex()' "$CONTROLLER" || fail 'search index builder is missing'
grep -Fq 'navigationGroupLabel: navigationGroupLabel' "$CONTROLLER" || fail 'search results do not retain the navigation group label'
grep -Fq 'modelData.navigationGroupLabel + " › " + modelData.pageLabel' "$WIDGET" || fail 'search results do not display the group/page breadcrumb'
grep -Fq 'ScrollBar.vertical: SettingsScrollBar' "$WIDGET" || fail 'expanded search results have no scroll indicator'
grep -Fq 'SettingsSearch.search(root.settingsSearchIndex' "$CONTROLLER" || fail 'search helper is not used'
grep -Fq 'root.settingsSearchQuery, 40' "$CONTROLLER" || fail 'search result cap does not include deeper module settings'
grep -Fq 'function trySettingsSearchSubTab(entry)' "$CONTROLLER" || fail 'automatic subtab discovery is missing'
grep -Fq 'function findSettingsSearchFlickable(target)' "$CONTROLLER" || fail 'scroll-container discovery is missing'
grep -Fq 'function showSettingsSearchHighlight(target)' "$CONTROLLER" || fail 'target highlight is missing'
grep -Fq 'SettingsSearch.humanizeKey(targetKey || explicitId)' "$CONTROLLER" || fail 'stable setting keys are not used as label fallback'
grep -Fq 'Keys.onPressed: event => root.handleSettingsSearchKey(event)' "$WIDGET" || fail 'keyboard navigation is missing'
grep -Fq 'root.searchInput.text = ""' "$CONTROLLER" || fail 'search query is not cleared after navigation'

# Search is navigation-only and must not write to the settings store.
NAV_BLOCK="$(sed -n '/function openSettingsSearchResult(entry)/,/function trySettingsSearchSubTab(entry)/p' "$CONTROLLER")"
if grep -Eq 'settings\.save\(|settings\.reset|Config\.[A-Za-z0-9_]+[[:space:]]*=' <<< "$NAV_BLOCK"; then
    fail 'search navigation mutates or saves settings'
fi

echo 'Settings global search: searchable primitive metadata, controller-owned index/navigation, all pages and target highlight: OK'

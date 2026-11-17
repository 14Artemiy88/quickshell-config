#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
fail() { echo "Settings search UI: FAIL: $*" >&2; exit 1; }

for page in modules themes general timers player mopidy weather cava cpuRam network volume calendar launcher notifications settingsWindow; do
    grep -Fq "settings-search-page:$page" "$WIDGET" || fail "page $page is missing from the search index tree"
done

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
grep -Fq 'function rebuildSettingsSearchIndex()' "$WIDGET" || fail 'search index builder is missing'
grep -Fq 'SettingsSearch.search(root.settingsSearchIndex' "$WIDGET" || fail 'search helper is not used'
grep -Fq 'function trySettingsSearchSubTab(entry)' "$WIDGET" || fail 'automatic subtab discovery is missing'
grep -Fq 'function findSettingsSearchFlickable(target)' "$WIDGET" || fail 'scroll-container discovery is missing'
grep -Fq 'function showSettingsSearchHighlight(target)' "$WIDGET" || fail 'target highlight is missing'
grep -Fq 'SettingsSearch.humanizeKey(targetKey || explicitId)' "$WIDGET" || fail 'stable setting keys are not used as label fallback'
grep -Fq 'Keys.onPressed: event => root.handleSettingsSearchKey(event)' "$WIDGET" || fail 'keyboard navigation is missing'
grep -Fq 'settingsSearchInput.text = ""' "$WIDGET" || fail 'search query is not cleared after navigation'

# Search is navigation-only and must not write to the settings store.
NAV_BLOCK="$(sed -n '/function openSettingsSearchResult(entry)/,/function trySettingsSearchSubTab(entry)/p' "$WIDGET")"
if grep -Eq 'settings\.save\(|settings\.reset|Config\.[A-Za-z0-9_]+[[:space:]]*=' <<< "$NAV_BLOCK"; then
    fail 'search navigation mutates or saves settings'
fi

echo 'Settings global search: searchable primitive metadata, all pages, navigation-only routing and target highlight: OK'

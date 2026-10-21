#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/Config.qml"
DEFAULTS="$ROOT/js/settings/SettingsDefaults.js"
PERSIST="$ROOT/js/settings/SettingsPersistence.js"
APPLY="$ROOT/js/settings/SettingsApplySystemVisual.js"
RESETS="$ROOT/js/settings/SettingsResets.js"
SETTINGS="$ROOT/Settings.qml"
SECTION="$ROOT/components/settings/sections/SettingsLauncherSection.qml"
WIDGET="$ROOT/components/settings/SettingsWidget.qml"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
SHELL="$ROOT/shell.qml"
PROJECTS="$ROOT/js/settings/SettingsLauncherProjects.js"

# Public defaults must not expose machine-specific project names or absolute IDE paths.
grep -q 'property var launcherProjects: LauncherProjects.defaults()' "$CONFIG"
grep -q 'launcherProjects: LauncherProjects.defaults()' "$DEFAULTS"
grep -Fq 'var DEFAULT_PROJECTS = [];' "$PROJECTS"
! grep -q '"ide":' "$PROJECTS"
! grep -q '"path":' "$PROJECTS"
grep -q 'function add(source)' "$PROJECTS"
grep -q 'function remove(source, index)' "$PROJECTS"
grep -q 'function move(source, index, delta)' "$PROJECTS"

# Project catalog is part of the common snapshot/profile and reset pipeline.
grep -q 'launcherProjects: JSON.parse(JSON.stringify(config.launcherProjects' "$PERSIST"
grep -q 'Config.launcherProjects = LauncherProjects.normalize(o.launcherProjects)' "$APPLY"
grep -q '"launcherProjects"' "$RESETS"
grep -q 'function updateLauncherProject(index, field, value)' "$SETTINGS"
grep -q 'function addLauncherProject()' "$SETTINGS"
grep -q 'function removeLauncherProject(index)' "$SETTINGS"
grep -q 'function moveLauncherProject(index, delta)' "$SETTINGS"

# Settings subtab supports icon/name/path/IDE, add/remove and movement.
grep -Fq 'case 11: return ["Общее", "Вкладки", "Проекты"]' "$WIDGET"
grep -q 'currentOtherSubTab === 2' "$SECTION"
grep -q 'placeholderText: "Иконка"' "$SECTION"
grep -q 'placeholderText: "Название"' "$SECTION"
grep -q 'placeholderText: "Путь к проекту' "$SECTION"
grep -q 'placeholderText: "IDE:' "$SECTION"
grep -q 'onClicked: root.settings.addLauncherProject()' "$SECTION"
grep -q 'onClicked: root.settings.removeLauncherProject' "$SECTION"
grep -q 'onClicked: root.settings.moveLauncherProject' "$SECTION"

# Single flat launcher tab, keyboard interaction, selection, search and safe argv execution.
grep -q 'readonly property int modeProjects: 8' "$LAUNCHER"
grep -q 'label: "Projects", mode: root.modeProjects' "$LAUNCHER"
grep -q 'function rebuildProjectsModel()' "$LAUNCHER"
grep -q 'function launchProject(project)' "$LAUNCHER"
grep -q 'Quickshell.execDetached(\[ide, path\])' "$LAUNCHER"
grep -q 'root.mode === root.modeProjects' "$LAUNCHER"
grep -q 'case "projects": return root.modeProjects' "$LAUNCHER"
grep -q 'function openProjects(): void' "$SHELL"
! grep -q 'fuzzel' "$LAUNCHER"

echo 'launcher projects tab and editable project catalog: OK'

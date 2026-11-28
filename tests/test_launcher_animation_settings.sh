#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
need() { grep -Fq -- "$2" "$1" || { echo "missing '$2' in $1" >&2; exit 1; }; }

need "$ROOT/Config.qml" 'property int animationLauncherMorphDuration: 120'
need "$ROOT/Config.qml" 'property string animationLauncherMorphProfile: "ease-in-out"'
need "$ROOT/js/settings/SettingsDefaults.js" 'animationLauncherMorphDuration: 120'
need "$ROOT/js/settings/SettingsDefaults.js" 'animationLauncherMorphProfile: "ease-in-out"'
need "$ROOT/js/settings/SettingsPersistence.js" 'animationLauncherMorphDuration: config.animationLauncherMorphDuration'
need "$ROOT/js/settings/SettingsPersistence.js" 'animationLauncherMorphProfile: config.animationLauncherMorphProfile'
need "$ROOT/js/settings/SettingsApplyBehaviour.js" 'applyMorphProfile(Config, o, "animationLauncherMorphProfile")'
need "$ROOT/js/settings/SettingsApplyBehaviour.js" 'Config.animationLauncherMorphDuration = Math.max(0, Math.min(5000, Math.round(launcherMorphDuration)))'
need "$ROOT/js/settings/SettingsPageRegistry.js" '{ id: "launcherAnimation", saveScope: "launcher", subTabs: [] }'
need "$ROOT/components/settings/SettingsNavigationController.qml" 'function launcherPageHasChanges(pageId)'
need "$ROOT/components/settings/SettingsNavigationController.qml" 'launcherAnimation: { keys: ["animationLauncherMorphDuration", "animationLauncherMorphProfile"] }'
need "$ROOT/components/settings/sections/SettingsLauncherSection.qml" 'SettingsAnimationGroup {'
need "$ROOT/components/settings/sections/SettingsLauncherSection.qml" 'currentPageId === "launcherAnimation"'
need "$ROOT/components/settings/sections/SettingsLauncherSection.qml" 'profile: Config.animationLauncherMorphProfile'
need "$ROOT/components/settings/sections/SettingsLauncherSection.qml" 'duration: Config.animationLauncherMorphDuration'
need "$ROOT/components/settings/sections/SettingsLauncherSection.qml" 'onDurationEdited: function(value)'
need "$ROOT/components/settings/sections/SettingsLauncherSection.qml" 'onProfileEdited: function(value)'
if grep -Eq '^[[:space:]]*(durationEdited|profileEdited):[[:space:]]*function' "$ROOT/components/settings/sections/SettingsLauncherSection.qml"; then
    echo 'Launcher animation signals must use QML onSignal handler syntax' >&2
    exit 1
fi
need "$ROOT/js/settings/SettingsProfiles.js" 'launcher: ["launcher", "animationLauncher"]'
need "$ROOT/js/settings/SettingsProfiles.js" 'return startsWithAny(root, ["launcher", "animationLauncher"])'
need "$ROOT/js/settings/SettingsResets.js" '"animationLauncherMorphDuration", "animationLauncherMorphProfile"'
need "$ROOT/components/launcher/Launcher.qml" 'Config.animationDurationForProfile('
need "$ROOT/components/launcher/Launcher.qml" 'Config.animationEasingType('
need "$ROOT/components/launcher/Launcher.qml" 'Config.animationBezierCurve('
need "$ROOT/components/launcher/Launcher.qml" 'readonly property int selectedModeTabIndex:'
need "$ROOT/components/launcher/Launcher.qml" 'id: modeSelectionFrame'
need "$ROOT/components/launcher/Launcher.qml" 'Behavior on x {'
need "$ROOT/components/launcher/Launcher.qml" 'highlight: launcherSelectionHighlight'
need "$ROOT/components/launcher/Launcher.qml" 'highlightFollowsCurrentItem: false'
need "$ROOT/components/launcher/Launcher.qml" 'readonly property var selectedDelegate: GridView.view ? GridView.view.currentItem'
need "$ROOT/components/launcher/Launcher.qml" 'ListView.view ? ListView.view.currentItem : null)'
need "$ROOT/components/launcher/Launcher.qml" 'Behavior on y {'
need "$ROOT/components/launcher/Launcher.qml" 'Behavior on x {'
if grep -Eq 'highlight(Move|Resize)Duration:' "$ROOT/components/launcher/Launcher.qml"; then
    echo 'Launcher selection frame must use its own geometry animation, not ListView-managed highlight timing' >&2
    exit 1
fi
need "$ROOT/components/launcher/Launcher.qml" 'modelData.isFocused && !ListView.isCurrentItem ? 1 : 0'
need "$ROOT/components/launcher/Launcher.qml" 'modelData.isFocused && !ListView.isCurrentItem ? 1 : 0'
list_highlight_count=$(grep -c 'highlight: launcherSelectionHighlight' "$ROOT/components/launcher/Launcher.qml")
[ "$list_highlight_count" -eq 10 ] || { echo "expected 10 launcher list highlights, found $list_highlight_count" >&2; exit 1; }
manual_highlight_count=$(grep -c 'highlightFollowsCurrentItem: false' "$ROOT/components/launcher/Launcher.qml")
[ "$manual_highlight_count" -eq 10 ] || { echo "expected 10 manually animated launcher highlights, found $manual_highlight_count" >&2; exit 1; }
need "$ROOT/components/launcher/Launcher.qml" 'NumberAnimation { duration: Config.animationDuration(180, "size"); easing.type: Easing.OutCubic }'
need "$ROOT/components/launcher/Launcher.qml" 'NumberAnimation { duration: Config.animationDuration(140, "appearance"); easing.type: Easing.OutCubic }'

# All existing item-level hover/selection behaviors must use the module-local profile.
if grep -Eq 'Config\.animationDuration\((110|120), "(size|appearance)"\)' "$ROOT/components/launcher/Launcher.qml"; then
    echo 'legacy item interaction animation duration remains in Launcher.qml' >&2
    exit 1
fi
# Ensure no-animation is supported by the same shared profile helper, and the
# launcher window entrance remains independent from this new internal profile.
need "$ROOT/Config.qml" 'function animationDurationForProfile(enabled, profile, baseMs, category)'
need "$ROOT/components/launcher/Launcher.qml" 'property bool entranceReady: false'
need "$ROOT/components/launcher/Launcher.qml" 'duration: Config.animationDuration(180, "movement")'
need "$ROOT/CHECK.sh" 'test_launcher_animation_settings.sh'
echo 'Launcher animation settings, internal interactions, persistence, reset and independent window entrance passed'

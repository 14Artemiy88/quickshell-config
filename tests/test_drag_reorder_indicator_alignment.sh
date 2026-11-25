#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMPONENT="$ROOT/components/primitives/DragReorderHandle.qml"

python3 - "$ROOT" "$COMPONENT" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
component_path = Path(sys.argv[2])
source = component_path.read_text()

# The insertion marker must be rendered inside a non-layout overlay host.
# A Repeater's parent is often a Column; parenting the marker there makes the
# positioner append it at the bottom and fight our manual coordinates.
for token in (
    'property Item dropIndicatorHost: null',
    'root.dropIndicatorHost !== null',
    'var pointer = host.mapFromItem(null, sceneX, sceneY)',
    'candidate.mapToItem(root.dropIndicatorHost, 0, 0)',
    'parent: root.dropIndicatorHost',
    'x: root.dropIndicatorX',
    'y: root.dropIndicatorY',
    'width: root.dropIndicatorWidth',
    'visible: dragHandler.active && root.dragSourceIndex >= 0',
    'Behavior on y',
    'NumberAnimation { duration: 160; easing.type: Easing.OutCubic }',
    'root.setDropTarget(root.itemIndex, false)',
    'root.updateDropTargetAfterMovement(centroid.scenePosition.x, centroid.scenePosition.y)',
    'pointerInsideSourceRow(sceneX, sceneY)',
    'root.dragPointerLeftSourceRow = true',
    'function insertionSlotGeometry(destination)',
    'var spacing = root.listLayoutSpacing()',
    'root.insertionSlotGeometry(destination)',
    'y: centerY - 1',
    'var layout = list ? list.parent : null',
):
    assert token in source, f'drop indicator is missing shared slot coordinates: {token}'
for obsolete in ('root.dropTargetItem', 'root.dropAfter', 'bestAfter'):
    assert obsolete not in source, f'old row-half indicator state must be removed: {obsolete}'

# Every migrated list declares an explicit visual target. This makes the
# indicator sibling mapping predictable for simple rows and framed cards.
expected_targets = {
    'components/settings/sections/SettingsLauncherSection.qml': (
        'launcherTabRow', 'projectSettingsCard', 'customActionCard'),
    'components/settings/sections/SettingsPlayerSection.qml': ('playerPriorityRow',),
    'components/settings/sections/SettingsTimersSection.qml': (
        'timerIconOrderRow', 'timerOptionsActionIconRow'),
    'components/settings/sections/SettingsDashboardSection.qml': ('cardSettings',),
    'components/settings/sections/mopidy/SettingsMopidyIconsSection.qml': ('mopidyTopIconOrderRow',),
}
for relative, target_ids in expected_targets.items():
    text = (root / relative).read_text()
    for target_id in target_ids:
        marker = f'property Item reorderTargetItem: {target_id}'
        assert marker in text, f'{relative}: missing explicit reorder target {target_id}'

hosts = {
    'components/settings/sections/SettingsLauncherSection.qml': (
        'launcherTabsSettingsGroup', 'launcherProjectsSettingsGroup', 'launcherActionsSettingsGroup'),
    'components/settings/sections/SettingsPlayerSection.qml': ('playerPrioritySettingsGroup',),
    'components/settings/sections/SettingsTimersSection.qml': (
        'timerIconOrderSettingsGroup', 'timerOptionsActionIconSettingsGroup'),
    'components/settings/sections/SettingsDashboardSection.qml': ('dashboardCardsSettingsGroup',),
    'components/settings/sections/mopidy/SettingsMopidyIconsSection.qml': ('mopidyTopIconOrderSettingsGroup',),
}
for relative, ids in hosts.items():
    text = (root / relative).read_text()
    for host_id in ids:
        assert f'id: {host_id}' in text, f'{relative}: missing non-layout overlay host {host_id}'
        assert f'dropIndicatorHost: {host_id}' in text, f'{relative}: handle does not use {host_id}'

assert 'property Item dropIndicatorHost: null' in source
assert 'readonly property Item dropIndicatorHost:' not in source
assert 'parent: root.dropIndicatorHost' in source
assert 'readonly property Item dropIndicatorHost: root.listRepeater && root.listRepeater.parent' not in source
assert 'parent: root.dropIndicatorHost ? root.dropIndicatorHost : root' in source
assert 'id: sourceDropHighlight' not in source
assert 'id: dropIndicator' in source
assert 'height: root.dropIndicatorHeight' in source
assert 'radius: root.dropIndicatorRadius' in source
assert 'color: root.dropIndicatorFill' in source
assert 'border.width: root.dropIndicatorBorderWidth' in source
assert 'Behavior on height' in source
assert 'Behavior on radius' in source
assert 'Behavior on color' in source
assert 'Behavior on border.width' in source
assert 'ColorAnimation { duration: 160; easing.type: Easing.OutCubic }' in source
assert 'visible: dragHandler.active && root.dragSourceIndex >= 0' in source
assert 'root.dropTargetKind = "source"' in source
assert 'root.dropTargetKind = "slot"' in source
settings_group = (root / 'components/settings/primitives/SettingsGroup.qml').read_text()
assert settings_group.lstrip().startswith('import QtQuick')
assert '\nItem {\n    id: root' in settings_group, 'SettingsGroup overlay host must remain a plain Item'
assert 'default property alias contentData: contentColumn.data' in settings_group
assert 'root.dropSlotHysteresis' not in source, 'pointer target must not depend on approach history'
print('Drag reorder gap-centered indicator geometry and overlay-host alignment: OK')
PY

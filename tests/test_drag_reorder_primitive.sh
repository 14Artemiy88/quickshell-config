#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMPONENT="$ROOT/components/primitives/DragReorderHandle.qml"
HELPER="$ROOT/js/utils/DragReorder.js"
for file in "$COMPONENT" "$HELPER"; do test -f "$file"; done

node - "$HELPER" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const api = vm.runInThisContext('(function(){' + source + '; return { validIndex, destinationIndex, insertionSlotAnchor, sourceAdjacentNoopDestination, insertionGapCenter, nearestInsertionSlot, pointerInsideSourceRow, move }; })()');
const order = ['a', 'b', 'c', 'd'];
assert.deepStrictEqual(api.move(order, 0, 3), ['b', 'c', 'd', 'a'], 'dragging first to last preserves every item');
assert.deepStrictEqual(api.move(order, 3, 0), ['d', 'a', 'b', 'c'], 'dragging last to first is symmetric');
assert.deepStrictEqual(api.move(order, 2, 2), order, 'dropping at the current position is a no-op');
const crossRealmArray = require('vm').runInNewContext('[\"left\",\"middle\",\"right\"]');
assert.deepStrictEqual(Array.from(api.move(crossRealmArray, 0, 2)), ['middle', 'right', 'left'], 'move supports arrays from a different JavaScript realm');
for (let count = 2; count <= 12; count += 1) {
  for (let source = 0; source < count; source += 1) {
    assert.strictEqual(api.sourceAdjacentNoopDestination(source, count, 'before'), source,
      'the gap directly above the dragged row resolves to its original index');
    assert.strictEqual(api.sourceAdjacentNoopDestination(source, count, 'after'), source,
      'the gap directly below the dragged row resolves to the same original index');
  }
}
assert.strictEqual(api.sourceAdjacentNoopDestination(-1, 4, 'before'), -1,
  'invalid dragged indices cannot create source aliases');
assert.deepStrictEqual(api.move(order, -1, 2), order, 'invalid source index is ignored');
assert.deepStrictEqual(api.move(order, 1, 4), order, 'invalid destination index is ignored');
assert.strictEqual(api.destinationIndex(0, 2, true, 4), 2, 'dropping on the lower half of a later item places source after it');
assert.strictEqual(api.destinationIndex(0, 2, false, 4), 1, 'dropping on the upper half of a later item places source before it');
assert.strictEqual(api.destinationIndex(3, 0, false, 4), 0, 'dropping on the upper half of an earlier item places source before it');
assert.strictEqual(api.destinationIndex(3, 0, true, 4), 1, 'dropping on the lower half of an earlier item places source after it');
assert.strictEqual(api.destinationIndex(0, 0, true, 4), 0, 'legacy row-half helper keeps self as a no-op');

// Every final order has exactly one visual insertion slot. The dragged row's
// own slot remains present so a user can deliberately drop it back in place.
for (let count = 2; count <= 9; count += 1) {
  for (let source = 0; source < count; source += 1) {
    const anchors = [];
    for (let destination = 0; destination < count; destination += 1) {
      const slot = api.insertionSlotAnchor(source, destination, count);
      assert(slot.index >= 0 && slot.index < count, 'slot anchor stays within the original list');
      anchors.push(`${slot.index}:${slot.afterLast}`);
      if (destination === source) {
        if (source + 1 < count) {
          assert.strictEqual(slot.index, source + 1, 'current-position slot anchors after the source row');
          assert.strictEqual(slot.afterLast, false, 'current-position marker uses the next row boundary');
        } else {
          assert.strictEqual(slot.index, source, 'last source slot anchors to the final row');
          assert.strictEqual(slot.afterLast, true, 'last source marker sits at the bottom insertion boundary');
        }
      }
    }
    assert.strictEqual(new Set(anchors).size, count,
      `source ${source} in ${count} items has one unique visual slot per destination`);
  }
}

assert.strictEqual(api.nearestInsertionSlot([10, 40, 70], 24), 0, 'nearest slot is selected by line coordinate');
assert.strictEqual(api.nearestInsertionSlot([10, 40, 70], 55), 1, 'pointer between slots selects one stable neighbour');
assert.strictEqual(api.nearestInsertionSlot([10, 40, 70], 25), 0, 'ties resolve deterministically to the earlier slot');
assert.strictEqual(api.nearestInsertionSlot([10, 40, 70], 50), 1, 'large pointer movement can cross multiple slots');
assert.strictEqual(api.nearestInsertionSlot([10, 40, 70], 25), 0,
  'the same exact pointer coordinate resolves identically without path-dependent hysteresis');
assert.strictEqual(api.nearestInsertionSlot([10, 40, 70], 25.01), 1,
  'crossing the true midpoint selects the next visual gap');
assert.strictEqual(api.nearestInsertionSlot([], 10), -1, 'empty slot list has no target');

// Insertion markers occupy the real spacing between delegates instead of
// sitting inside a row rectangle. Include different row sizes and spacings.
for (const [previousBottom, nextTop, spacing, expected] of [
  [52, 57, 5, 54.5],
  [88, 96, 8, 92],
  [31, 35, 4, 33],
]) {
  const center = api.insertionGapCenter(previousBottom, nextTop, spacing, 'between');
  assert.strictEqual(center, expected, 'between-row marker is centered in the measured gap');
  assert(center - 1 >= previousBottom && center + 1 <= nextTop,
    'two-pixel marker remains fully inside the gap and outside both rows');
}
assert.strictEqual(api.insertionGapCenter(NaN, 20, 6, 'before'), 17,
  'first slot is centered in the spacing before the first row');
assert.strictEqual(api.insertionGapCenter(80, NaN, 6, 'after'), 83,
  'last slot is centered in the spacing after the last row');
// Exhaustively verify all source/destination pairs against variable row
// heights. Every indicator rectangle must fit wholly in its actual gap.
for (let count = 2; count <= 12; count += 1) {
  const spacing = 4 + (count % 4);
  const tops = [];
  const heights = [];
  let cursor = 24;
  for (let row = 0; row < count; row += 1) {
    tops.push(cursor);
    heights.push(22 + ((row * 11 + count) % 31));
    cursor += heights[row] + spacing;
  }
  for (let source = 0; source < count; source += 1) {
    const positions = [];
    for (let destination = 0; destination < count; destination += 1) {
      const anchor = api.insertionSlotAnchor(source, destination, count);
      let center;
      let gapStart;
      let gapEnd;
      if (anchor.afterLast) {
        gapStart = tops[anchor.index] + heights[anchor.index];
        gapEnd = gapStart + spacing;
        center = api.insertionGapCenter(gapStart, NaN, spacing, 'after');
      } else if (anchor.index > 0) {
        gapStart = tops[anchor.index - 1] + heights[anchor.index - 1];
        gapEnd = tops[anchor.index];
        center = api.insertionGapCenter(gapStart, gapEnd, spacing, 'between');
      } else {
        gapEnd = tops[0];
        gapStart = gapEnd - spacing;
        center = api.insertionGapCenter(NaN, gapEnd, spacing, 'before');
      }
      assert(center - 1 >= gapStart && center + 1 <= gapEnd,
        `source ${source}, destination ${destination}: marker stays between rows`);
      positions.push(center);
    }
    assert.strictEqual(new Set(positions).size, count,
      `source ${source} in ${count} rows has distinct gap centers for every destination`);
  }
}
assert.strictEqual(api.pointerInsideSourceRow(100, 32, 116, 5), true, 'pointer within source row stays in the source dead-zone');
assert.strictEqual(api.pointerInsideSourceRow(100, 32, 95, 5), true, 'small top padding prevents premature target switching');
assert.strictEqual(api.pointerInsideSourceRow(100, 32, 88, 5), false, 'leaving above source row unlocks destination updates');
assert.strictEqual(api.pointerInsideSourceRow(100, 32, 138, 5), false, 'leaving below source row unlocks destination updates');
JS

python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
component = (root / 'components/primitives/DragReorderHandle.qml').read_text()
assert 'for (var destination = 0; destination < root.itemCount(); ++destination)' in component
assert 'if (i === root.dragSourceIndex)' not in component, 'the source row must remain a visible insertion target'
assert 'root.setDropTarget(bestIndex, true, selectedKind)' in component
assert 'visible: dragHandler.active && root.dragSourceIndex >= 0' in component, 'drag overlay hosts stay visible while a source is active'
assert 'root.dropTargetKind = "source"' in component, 'current row is selected as the no-op target'
assert 'root.dropTargetKind = "slot"' in component, 'ordinary gap remains the insertion target'
assert 'if (from >= 0 && to >= 0 && from !== to)' in component, 'dropping at the current slot must remain a no-op'
assert 'function sourceAdjacentGapGeometry(edge)' in component
assert 'function sourceRowHighlightGeometry()' in component
assert 'DragReorder.sourceAdjacentNoopDestination(' in component
assert 'root.sourceAdjacentGapGeometry("before")' in component
assert 'id: sourceDropHighlight' not in component, 'one shared shape must morph between frame and line'
assert 'height: root.dropIndicatorHeight' in component
assert 'root.dropIndicatorHeight = sourceGeometry.height' in component
assert 'root.dropIndicatorHeight = 2' in component
for token in ('DragHandler {', 'centroid.scenePosition.x', 'centroid.scenePosition.y',
              'listRepeater.itemAt(index)', 'DragReorder.insertionSlotAnchor',
              'DragReorder.nearestInsertionSlot', 'DragReorder.insertionGapCenter', 'host.mapFromItem(null, sceneX, sceneY)',
              'candidate.mapToItem(root.dropIndicatorHost, 0, 0)', 'dropIndicator', 'Keys.onPressed', 'Qt.AltModifier',
              'root.dropIndex >= 0', 'Accessible.role: Accessible.Button', 'reorderRequested(from, to)',
              'function insertionSlotGeometry(destination)', 'layout.spacing',
              'y: centerY - 1', 'nearestInsertionSlot(slotPositions, pointer.y)'):
    assert token in component, f'Missing shared drag-reorder behavior: {token}'

migrations = {
    'components/settings/sections/SettingsLauncherSection.qml': (
        'launcherTabsRepeater', 'launcherProjectsRepeater', 'launcherCustomActionsRepeater'),
    'components/settings/sections/SettingsPlayerSection.qml': ('playerPriorityRepeater',),
    'components/settings/sections/SettingsTimersSection.qml': ('timerIconOrderRepeater', 'timerOptionsActionIconsRepeater'),
    'components/settings/sections/SettingsDashboardSection.qml': ('dashboardSettingsCardsRepeater',),
    'components/settings/sections/SettingsWindowSection.qml': ('settingsNavigationGroupsOrderRepeater', 'settingsNavigationPagesOrderRepeater'),
    'components/settings/sections/mopidy/SettingsMopidyIconsSection.qml': ('mopidyTopIconOrderRepeater',),
}
for relative, repeaters in migrations.items():
    source = (root / relative).read_text()
    assert 'DragReorderHandle {' in source, f'{relative} has no shared reorder handle'
    for repeater in repeaters:
        assert f'listRepeater: {repeater}' in source, f'{relative} is missing drop target {repeater}'

for relative in migrations:
    source = (root / relative).read_text()
    assert 'MoveArrowButton {' not in source, f'{relative} still contains old reorder arrows'

dashboard_settings = (root / 'components/settings/sections/SettingsDashboardSection.qml').read_text()
assert 'property Item reorderTargetItem: cardSettings' in dashboard_settings, \
    'Dashboard sorting must treat the full card settings entry as one item'

# Mopidy's live queue and playlist rows now use the same shared drag handle;
# their asynchronous backend mutations are verified by dedicated shell tests.
queue = (root / 'components/mopidy/MopidyQueueTrackRow.qml').read_text()
playlist = (root / 'components/mopidy/MopidyPlaylistContents.qml').read_text()
assert 'Primitives.DragReorderHandle {' in queue
assert 'reorderAdapter: controller.queueReorderAdapter' in queue
assert 'controller.moveTrack(Number(itemData.track.tlid), toIndex)' in queue
assert 'Primitives.DragReorderHandle {' in playlist
assert 'reorderAdapter: playlistReorderAdapter' in playlist
assert 'controller.movePlaylistItem(fromIndex, toIndex' in playlist
assert 'Primitives.MoveArrowButton {' not in queue + playlist
PY

echo 'Shared drag reorder primitive and local list migrations: OK'

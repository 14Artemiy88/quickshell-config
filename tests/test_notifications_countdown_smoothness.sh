#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
qml = (root / "components/notifications/Notifications.qml").read_text(encoding="utf-8")
helper = (root / "js/notifications/NotificationTimeout.js").read_text(encoding="utf-8")
assert "interval: Config.notificationsShowTimeoutIndicator ? 16 : 100" in qml, "indicator should use a 16 ms display-cadence tick only when enabled"
assert "card.visibleTimeoutLastTick = running ? Date.now() : 0" in qml, "pause/resume must reset the elapsed-time origin"
assert "visibleTimeoutLastTick = 0" in qml.split("onNotificationChanged:", 1)[1].split("ListView.onAdd:", 1)[0], "reused delegates must not carry elapsed time from the previous notification"
assert "NotificationTimeout.elapsedDelta(card.visibleTimeoutLastTick, tickNow)" in qml, "elapsed time must be based on measured tick timestamps"
assert "card.visibleTimeoutElapsed += tickElapsed" in qml, "the accumulator must use measured time"
assert "card.visibleTimeoutElapsed += interval" not in qml, "fixed-interval accumulation drifts when the event loop is delayed"
assert "function elapsedDelta(previousTick, currentTick)" in helper, "timestamp delta helper is missing"
print("notification countdown smoothness source contract: OK")
PY
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(root + '/js/notifications/NotificationTimeout.js', 'utf8').replace(/^\.pragma library\s*/m, '');
const context = {};
vm.createContext(context);
vm.runInContext(source + '\nthis.elapsedDeltaForTest = elapsedDelta;', context);
const cases = [
  [1000, 1016, 16],
  [1000, 1033, 33],
  [1000, 1200, 200],
  [1000, 1000, 0],
  [0, 1016, 0],
  [-1, 1016, 0],
  [1016, 1000, 0],
  ['bad', 1016, 0],
  [1000, NaN, 0],
  [1000, Infinity, 0]
];
for (const [previous, current, expected] of cases) {
  const actual = context.elapsedDeltaForTest(previous, current);
  if (actual !== expected)
    throw new Error(`elapsedDelta(${String(previous)}, ${String(current)}) = ${actual}, expected ${expected}`);
}
console.log('notification countdown measured elapsed-time boundaries: OK');
JS

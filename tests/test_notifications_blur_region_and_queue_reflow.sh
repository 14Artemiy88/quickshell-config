#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
source = (Path(sys.argv[1]) / "components/notifications/Notifications.qml").read_text(encoding="utf-8")

blur_start = source.index("BackgroundEffect.blurRegion: Region {")
blur_end = source.index("\n        }", blur_start)
blur = source[blur_start:blur_end]
assert "Settings.moduleBlurEnabled.notifications === true" in blur
assert "? notificationList" in blur, "active notifications must keep their blur region"
assert "root.notificationBlurRegionActive" in blur, "blur should follow the active-notification lifecycle"
assert "activeNotificationExitCount > 0" not in blur, "exit-only delegates must not retain the blur region"
assert "root.layoutEditMode ? layoutEditPreview : null" in blur, "preview may be blurred only while layout editing"
assert " : null" in blur, "idle Notifications must expose no blur region"
assert " : layoutEditPreview" not in blur, "idle state must not retain the hidden layout preview as a blur target"

list_start = source.index("ListView {\n                id: notificationList")
displaced_start = source.index("displaced: Transition {", list_start)
displaced_end = source.index("\n                }", source.index("NumberAnimation {", displaced_start))
displaced = source[displaced_start:displaced_end]
assert 'property: "y"' in displaced
assert "duration: root.notificationCardVisibilityDuration" in displaced, (
    "queue reflow must use the effective visibility duration, so per-card style 'none' disables residual slides"
)
assert "duration: root.notificationTransitionDuration" not in displaced, (
    "profile duration alone ignores a per-card visibility style of 'none'"
)
assert "readonly property int notificationCardVisibilityDuration:" in source
assert "NotificationAnimation.visibilityDuration(" in source
blur_active_start = source.index("readonly property bool notificationBlurRegionActive:")
blur_active_end = source.index("\n    readonly property int layoutPreviewHeight", blur_active_start)
blur_active = source[blur_active_start:blur_active_end]
assert "visibleNotificationCount > 0" in blur_active
assert "activeNotificationExitCount" not in blur_active, "exit retention must not extend blur lifetime"
assert "visibleNotificationCount" in blur_active, "DND-suppressed notifications must not keep a visible blur region"
print("notification blur follows tracked model and clears when the final notification leaves; queue reflow follows effective visibility animation: OK")
PY
node - "$ROOT" <<'JS'
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
const source = fs.readFileSync(root + '/js/notifications/NotificationAnimation.js', 'utf8')
  .replace(/^\.pragma library\s*/m, '');
const context = {};
vm.createContext(context);
vm.runInContext(source + '\nthis.api = { effectiveStyle, visibilityDuration, shouldAnimate };', context);
const api = context.api;
for (const profile of ['standard', 'spatial', 'effects', 'expressive']) {
  const style = api.effectiveStyle(profile, 'none');
  const duration = api.visibilityDuration(style, 180);
  if (style !== 'none' || duration !== 0 || api.shouldAnimate(style, duration))
    throw new Error('none style must disable both card and queue motion for ' + profile);
}
const style = api.effectiveStyle('expressive', 'slideDown');
if (api.visibilityDuration(style, 180) !== 180 || !api.shouldAnimate(style, 180))
  throw new Error('enabled slide style should retain queue reflow duration');
console.log('notification animation none/enabled duration contract: OK');
JS

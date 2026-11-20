#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
DYNAMIC="$ROOT/js/launcher/LauncherDynamicScheme.js"

python3 - "$LAUNCHER" "$DYNAMIC" <<'PYTEST'
from pathlib import Path
import sys
launcher = Path(sys.argv[1]).read_text()
dynamic = Path(sys.argv[2]).read_text()

assert 'dynamicSchemeProcessing' not in launcher and 'dynamicSchemeProcessing' not in dynamic, \
    'processing must never appear as a Launcher result kind'
assert 'if (busy)\n        return []' in dynamic, \
    'dynamic scheme query returns no transient status row while processing'
assert 'if (root.dynamicSchemeBusy)\n                return []' in launcher, \
    'variant query returns no transient status row while processing'

progress = launcher[launcher.index('id: dynamicSchemeProgressNotificationProcess'):launcher.index('id: dynamicSchemeSuccessNotificationProcess')]
success = launcher[launcher.index('id: dynamicSchemeSuccessNotificationProcess'):launcher.index('// Failures replace the in-progress toast')]
error = launcher[launcher.index('// Failures replace the in-progress toast'):launcher.index('id: dynamicSchemeCopyErrorProcess')]
assert '"--print-id"' in progress and '"Создаётся цветовая схема…"' in progress, \
    'generation starts with a persistent progress notification and captures its ID'
assert '"--replace-id=" + String(root.dynamicSchemeProgressNotificationId)' in success, \
    'success notification replaces the progress notification'
assert '"Цветовая схема создана"' in success, \
    'success notification uses project terminology'
assert '"--replace-id=" + String(root.dynamicSchemeProgressNotificationId)' in error, \
    'error notification replaces the same progress notification'
assert '--action=copy-error=Копировать ошибку' in error, \
    'error notification retains the copy-error action'
assert 'root.dynamicSchemeNotificationCopyPayload = root.dynamicSchemeNotificationBody' in launcher, \
    'copy payload is snapshotted when the error is reported'
assert 'root.dynamicSchemeNotificationCopyPayload' in launcher[launcher.index('id: dynamicSchemeCopyErrorProcess'):], \
    'copy action uses the saved error rather than a later notification body'
assert 'function finishDynamicSchemeProgressNotificationWhenReady()' in launcher, \
    'notification replacement waits until the progress ID is captured'
assert 'function finishPendingDynamicSchemeNotificationUpdate()' in launcher, \
    'early Matugen completion is queued until the notification ID is ready'
assert 'root.queueDynamicSchemeNotificationUpdate("success")' in launcher
assert 'root.queueDynamicSchemeNotificationUpdate("error")' in launcher
assert 'dynamicSchemeNotificationPendingUpdate' in launcher
assert 'root.hideLauncher()' in launcher[launcher.index('function finishDynamicScheme(exitCode)'):launcher.index('function setWallpaperScope')], \
    'successful scheme application keeps the existing Launcher close behavior'
print('Dynamic scheme progress/success/error notifications replace one ID; Launcher status rows are absent: OK')
PYTEST

echo 'Launcher dynamic scheme notification lifecycle: OK'

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
README="$ROOT/README.md"
NOTIFICATIONS="$ROOT/components/notifications/Notifications.qml"
SETTINGS="$ROOT/components/settings/sections/SettingsNotificationsSection.qml"
CONFIG="$ROOT/Config.qml"
PERSISTENCE="$ROOT/js/settings/SettingsPersistence.js"

fail() { echo "FAIL: $*" >&2; exit 1; }

# Keep discovery rooted in actual Quickshell notification events.
grep -Fq 'root.recordNotificationSender(notification)' "$NOTIFICATIONS" || fail 'incoming NotificationServer events must populate the sender catalog'
grep -Fq 'Config.notificationsSeenSenders || []' "$SETTINGS" || fail 'DND UI must consume the runtime-observed catalog'
grep -Fq 'property var notificationsSeenSenders: []' "$CONFIG" || fail 'sender catalog must start empty on process startup'
! grep -Fq 'notificationsSeenSenders' "$PERSISTENCE" || fail 'sender catalog must remain runtime-only'

# KDE historical data was assessed but intentionally not made a hard dependency.
! grep -R -Fq 'org.kde.notificationmanager' "$ROOT"/components "$ROOT"/shell.qml || fail 'do not add a hard QML dependency on KDE NotificationManager'
! grep -R -Fq 'knownApplications' "$ROOT"/components "$ROOT"/js || fail 'do not merge Plasma knownApplications into the current sender catalog'

grep -Fq 'knownApplications' "$README" || fail 'README must preserve the KDE knownApplications review decision'
grep -Fq 'forgetKnownApplication()' "$README" || fail 'README must warn against deleting Plasma notification settings via forgetKnownApplication'
grep -Fq 'единственным источником новых записей DND' "$README" || fail 'README must state the runtime source-of-truth decision'

echo 'DND sender source policy: Quickshell runtime catalog remains authoritative; Plasma knownApplications is documented but not merged: OK'

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'NODE'
const fs = require('fs');
const path = require('path');
const assert = require('assert');
const rootDir = process.argv[2];
const source = fs.readFileSync(path.join(rootDir, 'components/notifications/Notifications.qml'), 'utf8');
const match = source.match(/function formatNotificationTag\(tag, linkStyle\) \{([\s\S]*?)\n    \}/);
assert(match, 'notification tag formatter must remain available');
const format = new Function('root', 'tag', 'linkStyle', match[1]);
const root = {
  safeNotificationColor: value => String(value || '').trim(),
  escapeNotificationAttribute: value => String(value || '')
};
const iconFont = format(root, '<span font_family="Arrows">', '');
assert.strictEqual(iconFont, '<span>', 'sender-supplied icon font must not override inherited notification typography');
const mixed = format(root, '<span foreground="red" font_family="Arrows">', '');
assert.strictEqual(mixed, '<span style="color: red;">', 'safe emphasis/color markup remains while font family is ignored');
assert.strictEqual(format(root, '<tt>', ''), '<span style="font-family: monospace;">', 'explicit code-style tt markup remains monospace');
assert.ok(source.includes('Config.resolveFontFamily(Config.notificationsBodyFont)'), 'visible body text resolves blank overrides to the system family');
assert.ok(source.includes('Config.resolveFontFamily(Config.notificationsBodyFont)'), 'body measure text shares the same system-family fallback');
assert.ok(!/const familyMatch =/.test(source), 'arbitrary incoming font-family parsing must stay disabled');
console.log('Notification body inherits configured/system family; only explicit tt remains monospace: OK');
NODE

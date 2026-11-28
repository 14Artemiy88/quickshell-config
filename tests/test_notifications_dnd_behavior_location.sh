#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const root = process.argv[2];
const read = p => fs.readFileSync(root + '/' + p, 'utf8');
const section = read('components/settings/sections/SettingsNotificationsSection.qml');
const registry = read('js/settings/SettingsPageRegistry.js');
const navigation = read('components/settings/SettingsNavigationController.qml');
const dndStart = section.indexOf('SettingsGroup {\n        visible: root.dndPage');
const behaviorHeading = section.indexOf('heading: \"Режим Не беспокоить\"');
const behaviorStart = section.lastIndexOf('SettingsGroup {', behaviorHeading);
const behaviorEnd = section.indexOf('SettingsGroup {', behaviorHeading);
assert(behaviorStart >= 0 && behaviorEnd > behaviorStart && dndStart >= 0, 'both Notifications and DND page groups exist');
const behavior = section.slice(behaviorStart, behaviorEnd);
const dnd = section.slice(dndStart, behaviorStart);
assert(behavior.includes('notificationsDoNotDisturbCheck'), 'DND master checkbox is on Notifications page');
assert(behavior.includes('settingsSearchSubTabIndex: 0'), 'DND master checkbox routes to Behavior');
assert(behavior.includes('notificationsDoNotDisturb = checked') && behavior.includes('root.settings.save()'), 'DND continues to save immediately');
assert(!dnd.includes('notificationsDoNotDisturbCheck'), 'DND master checkbox is absent from rules/history page');
assert(dnd.includes('root.dndSubTab === 0') && dnd.includes('Правила приложений'), 'first DND page tab shows app rules');
assert(dnd.includes('root.dndSubTab === 1') && dnd.includes('История уведомлений'), 'second DND page tab shows history');
assert(registry.includes('defaultLabel: "Правила и история"') && registry.includes('subTabs: ["Приложения", "История"]'), 'DND sidebar page is relabeled and reduced to two tabs');
assert(navigation.includes('notificationsDoNotDisturb') && navigation.includes('notificationSubTabCount = pageId === "notificationsDnd" ? 2 : 4'), 'dirty-state mapping includes DND in Behavior and two DND page tabs');
console.log('DND master toggle is placed in Notifications > Behavior; rules and history remain independent: OK');
JS

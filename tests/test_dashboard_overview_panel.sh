#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DASH="$ROOT/components/Dashboard.qml"
SHELL="$ROOT/shell.qml"
README="$ROOT/README.md"
fail() { echo "Dashboard overview panel: FAIL: $*" >&2; exit 1; }
[ -f "$DASH" ] || fail 'Dashboard.qml is missing'
python3 - "$DASH" "$SHELL" "$README" <<'PY'
from pathlib import Path
import sys

dash = Path(sys.argv[1]).read_text()
shell = Path(sys.argv[2]).read_text()
readme = Path(sys.argv[3]).read_text()

required_dashboard = [
    'PanelWindow {',
    'WlrLayershell.layer: WlrLayer.Overlay',
    'visible: Settings.loaded && (root.open || root.keepWindowDuringClose)',
    'property bool keepWindowDuringClose: false',
    'id: closeWindowTimer',
    'interval: Config.animationDuration(300, "appearance") + 24',
    'onTriggered: root.keepWindowDuringClose = false',
    'readonly property real targetHeight:',
    'Math.min(600, Math.max(420, cards.implicitHeight + 280))',
    'exclusionMode: ExclusionMode.Ignore',
    'mask: Region { item: root.open ? fullInputRegion : null }',
    'focusable: root.open',
    'WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None',
    'sequence: "Esc"',
    'root.clock.time',
    'root.cpuSource.stats.cpu',
    'readonly property var ramCapacity:',
    'readonly property var systemUptime:',
    'readonly property var dashboardTopResourceApp:',
    'Settings.topAppsCpu',
    'if (Settings.topAppsCpu)',
    'if (Settings.topAppsRam)',
    'root.monitorSource.data.top_apps',
    'root.cpuSource.stats.uptime_seconds',
    'text: \"Лог. CPU: \" + infoCard.cpuCoreCount',
    'horizontalAlignment: Text.AlignRight',
    'function russianCountUnit(value, one, few, many)',
    'else if (days > 0 && minutes > 0)',
    'return root.systemUptime.text !== "" ? root.systemUptime.text : "Данные модуля CPU"',
    'details.push(infoCard.systemUptimeAccessibleText)',
    'details.push(infoCard.topResourceAppAccessibleText)',
    'root.monitorSource.data.net_stat',
    'readonly property var networkConnectionNames:',
    'String(connection.status || "").trim() !== "on"',
    'var device = String(connection.device || "").trim()',
    'var icon = String(connection.type || "").trim()',
    'var kind = String(connection.kind || "").trim()',
    'names[j].name === name && names[j].device === device',
    'device: device',
    'icon: icon',
    'kind: kind',
    'item.icon + " " + label',
    'item.name + " (" + item.device + ")"',
    'var heading = names.length === 1',
    '"Подключения (" + names.length + ")"',
    'return heading + " · " + visibleNames.join(" · ")',
    'function networkConnectionTypeLabel(connectionType)',
    'var typeLabel = root.networkConnectionTypeLabel(item.kind)',
    'details.push("тип " + typeLabel)',
    'details.push("устройство " + item.device)',
    'var heading = names.length === 1',
    '? "Активное сетевое подключение"',
    '"Активные сетевые подключения (" + names.length + ")"',
    'return heading + ": " + descriptions.join("; ")',
    'readonly property string networkConnectionText:',
    'readonly property string networkConnectionAccessibleText:',
    'property string systemUptimeAccessibleText: ""',
    'root.weatherSource.now',
    'root.playerSource.player',
    'launcherRequested()',
    'calendarRequested()',
    'settingsRequested()',
    'MouseArea {\n            anchors.fill: parent\n            onClicked: root.closeRequested()',
    'title: modelData.label',
    'property var orderedCards: DashboardCards.orderedVisible(Config.dashboardCardOrder, Config.dashboardVisibleCards)',
    'DashboardCards.resolveDashboardLayout(',
    'DashboardCards.clampScrollPosition(',
    'property string navigationCardId: ""',
    'function scheduleDashboardLayoutSync()',
    'function restoreNavigationCardFocus()',
    'onOrderedCardsChanged: root.scheduleDashboardLayoutSync()',
    'onLayoutStateChanged: root.scheduleDashboardLayoutSync()',
    'onContentHeightChanged: root.scheduleDashboardLayoutSync()',
    'delegate: InfoCard',
    'property bool wideLead: false',
    'wideLead: true',
    'columns: infoCard.wideLead ? 2 : 1',
    'columnSpacing: infoCard.wideLead ? DashboardCards.WIDE_LEAD_GROUP_GAP : 0',
]
for item in required_dashboard:
    assert item in dash, f'Dashboard is missing expected feature: {item}'
assert dash.count('usedGiB.toFixed(1)') == 2 and dash.count('totalGiB.toFixed(1)') == 2, 'RAM and swap capacity values must retain decimal-point formatting'
assert 'values.push(value.toFixed(2))' in dash, 'system load averages must retain decimal-point formatting'
assert 'cpuName === systemRemainderLabel' in dash and 'displayedPercent <= 0' in dash, 'Dashboard must hide the aggregate remainder and zero-rounded top CPU rows'
assert 'Array.isArray(topApps.mem)' in dash and 'memoryRatio <= 0' in dash and 'Number(memoryValueMatch[1]) <= 0' in dash, 'Dashboard may fall back to a positive Top Apps RAM leader when no CPU leader is available'
assert 'text: "Топ RAM · " + memoryName + " · " + memoryValue' in dash and 'Приложение с наибольшим использованием оперативной памяти: ' in dash, 'RAM fallback must expose an explicit visible and accessible memory label'
assert 'var cpuProcessCount = Number(cpuItem.processCount)' in dash and 'количество процессов в группе — ' in dash, 'screen-reader CPU leader description must include grouped process count when more than one process is grouped'
assert dash.count('return ({ text: "", label: "", name: "", processCount: "", value: "", accessible: "" })') == 2, 'empty Top Apps states must define every string field consumed by InfoCard'
assert 'var cpuDisplayProcessCount = hasCpuProcessGroup ? \"×\" + cpuProcessCount : \"\"' in dash and 'name: cpuName' in dash and 'processCount: cpuDisplayProcessCount' in dash, 'visible CPU process-group count must be passed independently from the elided application name'
assert 'var memoryProcessCount = Number(memoryItem.processCount)' in dash and 'var memoryUnitAccessible = memoryValueMatch[3] === \"Gb\" ? \"гигабайта\"' in dash and 'memoryValueMatch[3] === \"Mb\" ? \"мегабайта\" : \"килобайта\"' in dash and 'memoryValueMatch[1] + \" \"' in dash and 'оперативной памяти, ' in dash and 'var memorySharePercent = (memoryRatio * 100).toFixed(1)' in dash and 'value: memoryValue + \" · \" + memorySharePercent + \"%\"' in dash and 'процента от общего объёма физической памяти' in dash and 'memoryGroupDescription' in dash, 'RAM fallback must show memory size and capacity share while the screen-reader text also announces full units and grouped process count'
assert 'var memoryDisplayProcessCount = hasMemoryProcessGroup ? \"×\" + memoryProcessCount : \"\"' in dash and 'name: memoryName' in dash and 'processCount: memoryDisplayProcessCount' in dash, 'visible RAM process-group count must be passed independently from the elided application name'
resource_start = dash.index('readonly property var dashboardTopResourceApp:')
resource_end = dash.index('readonly property var systemUptime:', resource_start)
resource_logic = dash[resource_start:resource_end]
assert resource_logic.index('if (Settings.topAppsCpu)') < resource_logic.index('if (Settings.topAppsRam)'), 'CPU ranking must remain preferred before the RAM fallback'
assert 'accessible: "Средняя системная нагрузка: за 1 минуту — " + values[0]' in dash and '"; за 5 минут — " + values[1]' in dash and '"; за 15 минут — " + values[2]' in dash, 'screen-reader load averages must explicitly associate each value with its 1/5/15-minute interval'
assert 'values.push(value.toFixed(2).replace(".", ","))' not in dash, 'system load averages must not switch to decimal commas'
assert 'function cardPrimaryText(cardId)' in dash and 'function cardSecondaryText(cardId)' in dash, 'ordered card delegates keep the per-card text mapping'
assert dash.count('networkConnectionText: modelData.id === "network" ? root.networkConnectionText : ""') == 3 and 'networkConnectionText: horizontalLeadSlot.modelData.id === "network" ? root.networkConnectionText : ""' in dash and 'model: cards.horizontalLeadCards' in dash, 'all vertical and horizontal card renderers must receive the active connection name'
assert dash.count('systemUptimeAccessibleText: modelData.id === "system" ? root.systemUptime.accessible : ""') == 3 and 'systemUptimeAccessibleText: horizontalLeadSlot.modelData.id === "system" ? root.systemUptime.accessible : ""' in dash and 'model: cards.horizontalLeadCards' in dash, 'all vertical and horizontal card renderers must receive the system uptime description'
assert dash.count('topResourceAppText: modelData.id === "system" ? root.dashboardTopResourceApp.text : ""') == 3 and 'topResourceAppText: horizontalLeadSlot.modelData.id === "system" ? root.dashboardTopResourceApp.text : ""' in dash and 'model: cards.horizontalLeadCards' in dash, 'all vertical and horizontal card renderers must receive the shared top resource application summary'
assert dash.count('String(root.dashboardTopResourceApp.processCount || "")') == 4, 'all card delegates must always assign a string to the process-count InfoCard property'
system_expanded_start = dash.index('GridLayout {\n                visible: infoCard.expanded && infoCard.cardId === "system"')
system_expanded_end = dash.index('            // Network expansion shows both live rate', system_expanded_start)
system_expanded_block = dash[system_expanded_start:system_expanded_end]
assert system_expanded_block.index('UsageMeter {') < system_expanded_block.index('visible: infoCard.cpuCoreCount > 0'), 'wide System lead must keep usage meters in the first content group'
assert system_expanded_block.count('ColumnLayout {') == 2 and 'columns: infoCard.wideLead ? 2 : 1' in system_expanded_block, 'expanded System details must switch to two intentional columns only for the wide Bento lead'
assert 'columnSpacing: infoCard.wideLead ? DashboardCards.WIDE_LEAD_GROUP_GAP : 0' in system_expanded_block, 'wide System must use the shared content-group gutter'
assert 'Layout.alignment: infoCard.wideLead ? Qt.AlignVCenter : Qt.AlignTop' in system_expanded_block, 'wide lead content groups must stay vertically balanced while normal cards retain top alignment'
weather_start = dash.index('GridLayout {\n                visible: infoCard.expanded && infoCard.cardId === "weather"')
weather_end = dash.index('            // Wide Media lead separates track identity', weather_start)
weather_block = dash[weather_start:weather_end]
network_start = dash.index('// Network expansion shows both live rate')
network_end = dash.index('// Weather keeps the current sample intact', network_start)
network_block = dash[network_start:network_end]
assert 'spacing: infoCard.wideLead ? DashboardCards.WIDE_LEAD_GROUP_GAP : 12' in network_block, 'wide Network lead must use the shared compact column gutter'
assert network_block.count('spacing: infoCard.wideLead ? 6 : 4') == 2, 'wide Network direction groups must gain balanced internal breathing room without changing normal cards'
assert 'infoCard.primaryText.replace("↓", "").trim()' in network_block and 'infoCard.secondaryText.replace("↑", "").trim()' in network_block, 'wide Network must preserve distinct download and upload metrics'
assert 'columns: infoCard.wideLead ? 2 : 1' in weather_block, 'expanded Weather must use two content columns only in the wide Bento lead'
assert 'columnSpacing: infoCard.wideLead ? DashboardCards.WIDE_LEAD_GROUP_GAP : 0' in weather_block, 'wide Weather must use the shared content-group gutter'
assert weather_block.count('ColumnLayout {') == 2, 'Weather must separate primary conditions from supporting details into two groups'
assert weather_block.index('text: infoCard.primaryText') < weather_block.index('text: "Ощущается " + infoCard.comfortText'), 'wide Weather lead must keep temperature and conditions in the primary group'
assert 'text: "Давление " + infoCard.pressureText + " мм рт. ст."' in weather_block, 'wide Weather supporting group must retain pressure'
assert weather_block.count('Layout.alignment: infoCard.wideLead ? Qt.AlignVCenter : Qt.AlignTop') == 2, 'wide Weather groups must be vertically balanced while normal cards retain top alignment'
assert 'columns: infoCard.wideLead ? 1 : 2' in weather_block, 'wide Weather supporting metrics must stack at full width while normal cards retain their side-by-side row'
media_start = dash.index('GridLayout {\n                visible: infoCard.expanded && infoCard.cardId === "media"')
media_end = dash.index('            Rectangle {\n                Layout.fillWidth: true\n                height: 1', media_start)
media_block = dash[media_start:media_end]
assert 'columns: infoCard.wideLead ? 2 : 1' in media_block, 'expanded Media must use two content columns only in the wide Bento lead'
assert 'columnSpacing: DashboardCards.WIDE_LEAD_GROUP_GAP' in media_block, 'wide Media must use the shared content-group gutter'
assert media_block.count('ColumnLayout {') == 2 and media_block.count('Layout.alignment: infoCard.wideLead ? Qt.AlignVCenter : Qt.AlignTop') == 2, 'wide Media groups must be vertically balanced while normal cards retain top alignment'
assert media_block.index('text: infoCard.primaryText') < media_block.index('text: infoCard.secondaryText'), 'Media track title must precede artist in the left group'
assert 'visible: infoCard.wideLead && infoCard.tertiaryText.trim() !== ""' in media_block and 'visible: !infoCard.wideLead && infoCard.tertiaryText.trim() !== ""' in media_block, 'album metadata must appear above progress in wide layout and after progress in normal layout'
assert 'visible: infoCard.mediaProgressPercent >= 0' in media_block and 'infoCard.mediaRemainingTime !== ""' in media_block, 'Media progress and remaining-time fallback must retain their validity guards'
assert dash.count('topResourceAppAccessibleText: modelData.id === "system" ? root.dashboardTopResourceApp.accessible : ""') == 3 and 'topResourceAppAccessibleText: horizontalLeadSlot.modelData.id === "system" ? root.dashboardTopResourceApp.accessible : ""' in dash and 'model: cards.horizontalLeadCards' in dash, 'all vertical and horizontal card renderers must receive the top resource application accessible description'
assert dash.count('topResourceAppLabel: modelData.id === "system" ? root.dashboardTopResourceApp.label : ""') == 3 and 'topResourceAppLabel: horizontalLeadSlot.modelData.id === "system" ? root.dashboardTopResourceApp.label : ""' in dash and dash.count('topResourceAppName: modelData.id === "system" ? root.dashboardTopResourceApp.name : ""') == 3 and 'topResourceAppName: horizontalLeadSlot.modelData.id === "system" ? root.dashboardTopResourceApp.name : ""' in dash and dash.count('topResourceAppProcessCount: modelData.id === "system" ? String(root.dashboardTopResourceApp.processCount || "") : ""') == 3 and 'topResourceAppProcessCount: horizontalLeadSlot.modelData.id === "system" ? String(root.dashboardTopResourceApp.processCount || "") : ""' in dash and dash.count('topResourceAppValue: modelData.id === "system" ? root.dashboardTopResourceApp.value : ""') == 3 and 'topResourceAppValue: horizontalLeadSlot.modelData.id === "system" ? root.dashboardTopResourceApp.value : ""' in dash, 'all card renderers must receive label, elidable name, independent process count and protected value'
uptime_start = dash.index('readonly property var systemUptime:')
uptime_end = dash.index('readonly property var networkData:', uptime_start)
uptime_logic = dash[uptime_start:uptime_end]
assert uptime_logic.count('spoken.push(root.russianCountUnit(minutes, "минута", "минуты", "минут"))') == 2, 'screen-reader uptime must retain remaining minutes both below and above one day'
core_summary_marker = dash.index('visible: infoCard.cpuCoreCount > 0')
core_summary_start = dash.rfind('RowLayout {', 0, core_summary_marker)
core_summary_end = dash.index('visible: infoCard.swapCapacityText', core_summary_marker)
core_summary_block = dash[core_summary_start:core_summary_end]
assert 'text: "Лог. CPU: " + infoCard.cpuCoreCount' in core_summary_block, 'logical CPU count must remain visible'
cpu_count_text_start = core_summary_block.index('text: "Лог. CPU: " + infoCard.cpuCoreCount')
cpu_count_block_start = core_summary_block.rfind('                    Text {', 0, cpu_count_text_start)
cpu_count_block = core_summary_block[cpu_count_block_start:cpu_count_text_start]
assert 'Layout.fillWidth: false' in cpu_count_block and 'Layout.preferredWidth: implicitWidth' in cpu_count_block, 'logical CPU count label must keep its natural width so the peak value can use the remaining row space'
assert 'text: "Пик CPU" +' in core_summary_block and 'Layout.fillWidth: true' in core_summary_block, 'hottest-core peak must identify CPU and receive the remaining row width'
assert 'infoCard.cpuCorePeakId !== "" ? " " + infoCard.cpuCorePeakId : ""' in core_summary_block, 'known logical CPU id must follow the explicit CPU label'
assert ': "одного CPU"' not in core_summary_block, 'missing CPU id must not be described as a single CPU'
assert 'details.push("Количество логических CPU " + infoCard.cpuCoreCount)' in dash, 'screen-reader wording must retain the full logical CPU description'
assert '"Максимальная загрузка логического процессора " + infoCard.cpuCorePeakId' in dash, 'screen-reader peak wording must identify the numbered logical processor'
assert '"Максимальная загрузка наиболее загруженного логического процессора: "' in dash, 'screen-reader peak wording must identify a logical processor when its id is unavailable'
assert 'text: "Пик CPU" +' in core_summary_block and 'horizontalAlignment: Text.AlignRight' in core_summary_block, 'hottest-core peak must share the compact summary row with an explicit CPU label'
assert 'visible: infoCard.topResourceAppText !== \"\"' in dash and 'text: infoCard.topResourceAppName' in dash and 'text: infoCard.topResourceAppProcessCount' in dash and 'visible: infoCard.topResourceAppProcessCount !== \"\"' in dash and 'text: infoCard.topResourceAppValue' in dash and 'elide: Text.ElideRight' in dash, 'top resource row must keep the group count and metric in independent slots while eliding only the app name'
connection_text_start = dash.index('visible: infoCard.expanded && infoCard.cardId === "network"\n                         && infoCard.networkConnectionText !== ""')
connection_text_end = dash.index('            // Weather keeps the current sample intact', connection_text_start)
connection_text_block = dash[connection_text_start:connection_text_end]
assert 'wrapMode: Text.WrapAtWordBoundaryOrAnywhere' in connection_text_block and 'maximumLineCount: 2' in connection_text_block, 'active connection names must wrap at word boundaries or within long unbroken names before eliding'
assert 'textFormat: Text.PlainText' in connection_text_block, 'connection names must not be interpreted as rich text'
assert 'visible: Settings.loaded\n' not in dash, 'Dashboard must not keep a fullscreen window visible while closed'

# The overview must consume shared models rather than creating parallel polling.
assert 'Process {' not in dash, 'Dashboard starts its own external polling process'
assert dash.count('Timer {') == 1 and 'id: closeWindowTimer' in dash and 'repeat: false' in dash, 'Dashboard may only have its one-shot close-transition timer'
dashboard_code = '\n'.join(line.split('//', 1)[0] for line in dash.splitlines())
assert 'cpu_stats_once' not in dashboard_code and 'scripts/player' not in dashboard_code and 'scripts/weather' not in dashboard_code, 'Dashboard bypasses an existing shared source'

required_shell = [
    'property bool dashboardVisible: false',
    'target: "dashboard"',
    'function toggle(): void { shell.dashboardVisible = !shell.dashboardVisible }',
    'function show(): void { shell.dashboardVisible = true }',
    'function hide(): void { shell.dashboardVisible = false }',
    'clock: clock',
    'cpuSource: cpuWidget',
    'playerSource: playerWidget',
    'weatherSource: weatherLoader.item',
    'monitorSource: monitor',
    'id: cpuWidget; anchors.fill: parent',
    'shell.dashboardVisible || ((shell.calendarVisible || Config.calendarAlwaysVisible)',
]
for item in required_shell:
    assert item in shell, f'shell.qml is missing Dashboard wiring: {item}'

assert 'qs -c <путь-к-конфигурации> ipc call dashboard toggle' in readme, 'README lacks the documented IPC entry point'
assert 'Hyprland' not in dash and 'hyprctl' not in dash, 'Dashboard contains a compositor-specific dependency'
print('Dashboard overview panel, shared data sources, IPC, focus, and documentation: OK')
PY

echo 'dashboard overview panel: OK'

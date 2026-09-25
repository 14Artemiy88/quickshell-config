import QtQuick
import QtQuick.Controls
import Quickshell

PanelWindow {
    id: rootWindow

    readonly property color colorBase: "#cc181818"
    readonly property color colorText: "#cccdd6f4"
    readonly property color colorSubtext: "#6c7086"
    readonly property color color00cccc: "#00cccc"
    readonly property color colorcc00cccc: "#aa00cccc"
    readonly property color color3300cccc: "#3300cccc"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore

    color: "transparent"
    aboveWindows: true
    focusable: true

    Keys.onEscapePressed: Qt.quit()

    onVisibleChanged: {
        if (visible) {
            searchField.text = "";
            searchField.forceActiveFocus();
        }
    }

    readonly property string goland: "/media/artemiy/3fe68576-1a13-42fc-94c3-a6e34f218cf4/GoLand/bin/goland"
    readonly property string phpstorm: "/media/artemiy/3fe68576-1a13-42fc-94c3-a6e34f218cf4/PhpStorm/bin/phpstorm"

    readonly property var allProjects: [
        {icon: "󱢴", name: "SL", path: "~/WORK/sima-land-ru", ide: phpstorm},
        {icon: "", name: "Ilium", path: "~/WORK/ilium", ide: goland},
        {icon: "", name: "Mobilium", path: "~/WORK/mobilium", ide: goland},
        {icon: "", name: "Inspiration", path: "~/WORK/inspiration", ide: goland},
        {icon: "", name: "Orders", path: "~/WORK/orders", ide: goland},
        {icon: "", name: "Orders Files", path: "~/WORK/order-files", ide: goland},
        {icon: "", name: "Order", path: "~/WORK/order", ide: goland},
        {icon: "", name: "Cart", path: "~/WORK/cart", ide: goland},
        {icon: "", name: "Router", path: "~/WORK/router", ide: goland},
        {icon: "", name: "Layout", path: "~/WORK/layout", ide: goland},
        {icon: "", name: "Shipments", path: "~/WORK/shipments", ide: goland},
        {icon: "", name: "Steward", path: "~/WORK/steward", ide: goland},
        {icon: "󱅲", name: "_proto Cart", path: "~/WORK/_proto/cart", ide: goland},
        {icon: "󱅲", name: "_proto Orders", path: "~/WORK/_proto/orders", ide: goland},
        {icon: "󱅲", name: "_proto Order Files", path: "~/WORK/_proto/order-files", ide: goland},
        {icon: "󱅲", name: "_proto Promocode", path: "~/WORK/_proto/promocode", ide: goland},
        {icon: "󱅲", name: "_proto Router", path: "~/WORK/_proto/router", ide: goland},
        {icon: "󱂛", name: "_spec Cart Api", path: "~/WORK/_spec/cart-api", ide: goland},
        {icon: "󱂛", name: "_spec Orders Api", path: "~/WORK/_spec/orders-api", ide: goland},
        {icon: "󱂛", name: "_spec Illium API", path: "~/WORK/_spec/illium", ide: goland},
        {icon: "󱂛", name: "_spec Inspiration Ilium Api", path: "~/WORK/_spec/inspiration-ilium-api", ide: goland},
        {icon: "", name: "Event Schema (esb)", path: "~/WORK/event-schema", ide: goland},
        {icon: "", name: "Deploy Templates", path: "~/WORK/deploy-templates", ide: goland},
        {icon: "", name: "Pipeline Templates", path: "~/WORK/pipeline-templates", ide: goland},
        {icon: "", name: "Events (планирование)", path: "~/WORK/events", ide: goland},
        {icon: "󰆼", name: "Database", path: "~/WORK/database", ide: goland},
        {icon: "󰆼", name: "Setenvphp", path: "~/WORK/setenvphp", ide: goland},
        {icon: "󱍕", name: "EWW", path: "~/.config/eww", ide: goland},
        {icon: "", name: "TermPaint", path: "~/Apps/termPaint", ide: goland},
        {icon: "", name: "Trening", path: "~/Apps/tren", ide: goland},
        {icon: "󱗿", name: "Dotfiles", path: "/media/artemiy/3fe68576-1a13-42fc-94c3-a6e34f218cf4/Dotfiles", ide: goland},
        {icon: "󰊗", name: "MY Rim Mod", path: "/media/artemiy/3fe68576-1a13-42fc-94c3-a6e34f218cf4/MY_rim_mod", ide: goland}
    ]

    // Сюда будет записываться текст поиска ТОЛЬКО после паузы в наборе
    property string debouncedQuery: ""

    // Таймер задержки (дебаунс)
    Timer {
        id: debounceTimer
        interval: 250 // Задержка в миллисекундах. 250мс — идеальный баланс между отзывчивостью и стабильностью
        repeat: false
        onTriggered: {
            // Как только пользователь замолчал на 250мс, обновляем переменную поиска
            rootWindow.debouncedQuery = searchField.text.trim();
        }
    }

    function launchProject(currentItem) {
        if (!currentItem) return;

        if (currentItem.targetAppObj) {
            currentItem.targetAppObj.execute();
        }
        // ИСПРАВЛЕНО: Запуск "слепых" консольных команд через системный шелл Bash
        else if (currentItem.targetIde === "") {
            Quickshell.execDetached(["bash", "-c", currentItem.targetPath]);
        }
        else {
            let fullPath = currentItem.targetPath.replace("~", Quickshell.env("HOME"));
            Quickshell.execDetached([currentItem.targetIde, fullPath]);
        }
        
        Qt.quit();
    }

    readonly property var activeProjects: {
        let list = [];

        // а отложенную переменную debouncedQuery из таймера
        let query = rootWindow.debouncedQuery;

        if (query === "") {
            return list;
        }

        let lowerQuery = query.toLowerCase();

        // --- ИНТЕГРАЦИЯ ИСТОРИИ БУФЕРА ОБМЕНА ---
        // D-Bus метод для KDE Plasma 6
        if (query.toLowerCase() === "cb" || query.toLowerCase().indexOf("cb ") === 0) {
            try {
                // В Plasma 6 Klipper хранит историю как массив объектов.
                // Чтобы получить актуальный список, мы просим Klipper отдать массив top-записей
                let process = Quickshell.exec(["qdbus6", "org.kde.klipper", "/klipper", "org.kde.klipper.getClipboardHistoryItems"]);
                let rawHistory = process.stdout.text();

                if (rawHistory.length > 0) {
                    let lines = rawHistory.split("\n");
                    let limit = Math.min(lines.length, 10);

                    for (let i = 0; i < limit; i++) {
                        let line = lines[i].trim();
                        if (line.length === 0) continue;

                        // Очищаем от системных префиксов D-Bus, если они есть
                        let cleanText = line.replace(/^\d+\.\s+/, "");
                        let shortDisplay = cleanText.length > 50 ? cleanText.substring(0, 50) + "..." : cleanText;

                        list.push({
                            icon: "  ",
                            name: shortDisplay,
                            path: cleanText,
                            ide: "",
                            sysAppObj: null,
                            isCalcResult: false,
                            isClipboardItem: true
                        });
                    }
                    return list;
                }
            } catch(e) {
                // Если метод верхнего уровня не сработал, пробуем прочитать через wl-paste/cliphist
                try {
                    let backupProcess = Quickshell.exec(["cliphist", "list"]);
                    let backupText = backupProcess.stdout.text();
                    if (backupText.length > 0) {
                        let bLines = backupText.split("\n");
                        let bLimit = Math.min(bLines.length, 10);
                        for (let j = 0; j < bLimit; j++) {
                            let bLine = bLines[j].trim();
                            if (bLine.length === 0) continue;
                            list.push({
                                icon: "  ",
                                name: bLine.substring(0, 50),
                                path: bLine,
                                ide: "",
                                sysAppObj: null,
                                isCalcResult: false,
                                isClipboardItem: true
                            });
                        }
                        return list;
                    }
                } catch(err) {}
            }
        }

        // --- ИНТЕГРАЦИЯ КАЛЬКУЛЯТОРА ---
        let mathRegex = /^[0-9+\-*/().\s^!]+$/;
        if (mathRegex.test(query) && query.match(/[0-9]/)) {
            try {
                let preparedQuery = query.replace(/\^/g, "**");
                let factorialFunc = function(n) {
                    if (n < 0) return NaN;
                    let res = 1;
                    for (let i = 2; i <= n; i++) res *= i;
                    return res;
                };
                preparedQuery = preparedQuery.replace(/(\d+)\!/g, function(match, num) {
                    return "factorialFunc(" + num + ")";
                });

                let calcFunc = new Function("factorialFunc", "with(Math) { return " + preparedQuery + "; }");
                let result = calcFunc(factorialFunc);

                if (result !== undefined && !isNaN(result)) {
                    list.push({
                        icon: " ",
                        name: "󰇼  " + result,
                        path: "",
                        ide: "",
                        sysAppObj: null,
                        isCalcResult: true,
                        isClipboardItem: false
                    });
                }
            } catch(e) {}
        }

        let filteredProjects = allProjects.filter(function(p) {
            return p.name.toLowerCase().indexOf(lowerQuery) !== -1;
        });
        list = [...list, ...filteredProjects];

        let sysApps = DesktopEntries.applications.values;
        for (let i = 0; i < sysApps.length; i++) {
            let app = sysApps[i];
            if (app.noDisplay) continue;

            let appName = app.name.toLowerCase();
            let genericName = app.genericName ? app.genericName.toLowerCase() : "";

            if (appName.indexOf(lowerQuery) !== -1 || genericName.indexOf(lowerQuery) !== -1) {
                list.push({
                    icon: app.icon ? app.icon : "",
                    name: app.name,
                    path: "",
                    ide: "",
                    sysAppObj: app,
                    isCalcResult: false,
                    isClipboardItem: false
                });
            }
        }

        if (list.length === 0) {
            list = [{
                icon: "",
                name: query,
                path: "",
                ide: "",
                sysAppObj: null,
                isCalcResult: false,
                isClipboardItem: false
            }];
        }

        return list;
    }


    onActiveProjectsChanged: {
        projectsListView.currentIndex = 0;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Qt.quit()
    }

    Rectangle {
        id: container
        width: 600
        height: Math.min(96 + projectsListView.contentHeight, 500)
        radius: 12
        color: rootWindow.colorBase
        border.color: rootWindow.colorcc00cccc
        border.width: 1
        anchors.centerIn: parent

        Behavior on height {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            preventStealing: true
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            TextField {
                id: searchField
                width: parent.width
                height: 40
                focus: true
                placeholderText: ""
                color: rootWindow.colorText
                font.pointSize: 12

                // При изменении текста сбрасываем таймер и запускаем заново.
                // Если текст стерли в ноль — очищаем поиск мгновенно без задержки.
                onTextChanged: text.trim() === "" ? (debounceTimer.stop(), rootWindow.debouncedQuery = "") : debounceTimer.restart()

                leftPadding: 12
                rightPadding: 12
                topPadding: 8
                bottomPadding: 8

                background: Rectangle {
                    color: "transparent"
                    radius: 6
                    border.color: rootWindow.colorcc00cccc
                    border.width: 1
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        Qt.quit();
                        event.accepted = true;
                    }
                    if (event.key === Qt.Key_Down) {
                        projectsListView.incrementCurrentIndex();
                        event.accepted = true;
                    }
                    if (event.key === Qt.Key_Up) {
                        projectsListView.decrementCurrentIndex();
                        event.accepted = true;
                    }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        // ПРИНУДИТЕЛЬНО: применяем текст и останавливаем таймер дебаунса,
                        // чтобы модель activeProjects мгновенно обновилась до вызова запуска
                        debounceTimer.stop();
                        rootWindow.debouncedQuery = searchField.text.trim();

                        let currentItem = projectsListView.currentItem;
                        if (currentItem) {
                            rootWindow.launchProject(currentItem);
                        }
                        event.accepted = true;
                    }
                }
            }

            ListView {
                id: projectsListView
                width: parent.width

                // Высчитываем высоту списка как остаток от текущей высоты контейнера
                height: container.height - searchField.height - 56
                clip: true

                model: rootWindow.activeProjects
                currentIndex: 0

                delegate: ItemDelegate {
                    id: itemDelegate
                    width: projectsListView.width
                    height: 42

                    property string targetIde: modelData.ide
                    property string targetPath: modelData.path
                    property var targetAppObj: modelData.sysAppObj ? modelData.sysAppObj : null
                    property bool isCalcResult: modelData.isCalcResult ? modelData.isCalcResult : false
                    property bool isClipboardItem: modelData.isClipboardItem ? modelData.isClipboardItem : false

                    background: Rectangle {
                        color: index === projectsListView.currentIndex ? rootWindow.color3300cccc : "transparent"
                        radius: 6
                        border.color: "transparent"
                        border.width: 1
                    }
                    contentItem: Row {
                        spacing: 15
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12

                        Image {
                            visible: modelData.icon.length > 2
                            source: visible ? "image://icon/" + modelData.icon : ""
                            sourceSize.width: 20
                            sourceSize.height: 20
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            visible: modelData.icon.length <= 2
                            text: modelData.icon
                            color: rootWindow.colorcc00cccc
                            font.pointSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.name
                            color: index === projectsListView.currentIndex ? rootWindow.color00cccc : rootWindow.colorText
                            font.pointSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.path
                            color: rootWindow.colorSubtext
                            font.pointSize: 10
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: projectsListView.currentIndex = index
                        onClicked: rootWindow.launchProject(itemDelegate)
                    }
                }
            }
        }
    }
}

.pragma library

var builtinThemeNames = ["14 Theme", "Catppuccin Mocha", "Tokyo Night", "Dracula", "Nord", "Gruvbox Dark", "One Dark", "Amber", "Purple", "Ice", "Mono"]

var palettes = {
            "14 Theme": {
                baseColor: "#006666", accent: "#00cccc", currentWeather: "#00cccc", background: "#4d000000",
                text: "#ffffff", textMuted: "#dddddd", textDim: "#cccccc", textDisabled: "#999999", black: "#000000",
                calendarBackground: "#cc000000", settingsBackground: "#e6000000", settingsBorder: "#00cccc",
                playerOverlay: "#18000000", playerProgressTrack: "#33ffffff", playerProgressFill: "#00cccc", activeNetworkBackground: "#1a323232",
                volumeTrack: "#99006666", volumeFill: "#006666", networkUpload: "#baffc9", networkDownload: "#ffb4bb",
                cpu1: "#ffb4bb", cpu2: "#ffe0ba", cpu3: "#fffebb", cpu4: "#baffc9", cpu5: "#bae1ff", cpu6: "#aedfdb", cpu7: "#75c8cc", cpu8: "#ead1f5", ram: "#3daee9", metricTrack: "#4d006666", ramTrack: "#4d3daee9",
                tempHot: "#ff8989", tempWarm: "#ffb4bb", tempMild: "#ffe0ba", tempCool: "#fce3c4", tempZero: "#ffffff", tempCold: "#bae1ff", tempVeryCold: "#0ad1f3", tempFreezing: "#3c82e2"
            },
            "Catppuccin Mocha": {
                baseColor: "#585b70", accent: "#89b4fa", currentWeather: "#74c7ec", background: "#4d1e1e2e", text: "#cdd6f4", textMuted: "#bac2de", textDim: "#a6adc8", textDisabled: "#6c7086", black: "#11111b",
                calendarBackground: "#cc181825", settingsBackground: "#e61e1e2e", settingsBorder: "#89b4fa", playerOverlay: "#262c2c3a", playerProgressTrack: "#33585b70", playerProgressFill: "#89b4fa", activeNetworkBackground: "#1a313244", volumeTrack: "#99585b70", volumeFill: "#89b4fa", networkUpload: "#a6e3a1", networkDownload: "#f38ba8",
                cpu1: "#f38ba8", cpu2: "#fab387", cpu3: "#f9e2af", cpu4: "#a6e3a1", cpu5: "#89dceb", cpu6: "#94e2d5", cpu7: "#74c7ec", cpu8: "#cba6f7", ram: "#89b4fa", metricTrack: "#4d45475a", ramTrack: "#4d89b4fa", tempHot: "#f38ba8", tempWarm: "#eba0ac", tempMild: "#fab387", tempCool: "#89dceb", tempZero: "#cdd6f4", tempCold: "#74c7ec", tempVeryCold: "#89b4fa", tempFreezing: "#7287fd"
            },
            "Tokyo Night": {
                baseColor: "#3b4261", accent: "#7aa2f7", currentWeather: "#7dcfff", background: "#4d16161e", text: "#c0caf5", textMuted: "#a9b1d6", textDim: "#9aa5ce", textDisabled: "#565f89", black: "#15161e",
                calendarBackground: "#cc1a1b26", settingsBackground: "#e61a1b26", settingsBorder: "#7aa2f7", playerOverlay: "#26242a3d", playerProgressTrack: "#334147bb", playerProgressFill: "#7aa2f7", activeNetworkBackground: "#1a24283b", volumeTrack: "#993b4261", volumeFill: "#7aa2f7", networkUpload: "#9ece6a", networkDownload: "#f7768e",
                cpu1: "#f7768e", cpu2: "#ff9e64", cpu3: "#e0af68", cpu4: "#9ece6a", cpu5: "#7dcfff", cpu6: "#73daca", cpu7: "#2ac3de", cpu8: "#bb9af7", ram: "#7aa2f7", metricTrack: "#4d3b4261", ramTrack: "#4d7aa2f7", tempHot: "#f7768e", tempWarm: "#ff9e64", tempMild: "#e0af68", tempCool: "#7dcfff", tempZero: "#c0caf5", tempCold: "#7aa2f7", tempVeryCold: "#2ac3de", tempFreezing: "#5d7bd2"
            },
            "Dracula": {
                baseColor: "#6272a4", accent: "#bd93f9", currentWeather: "#8be9fd", background: "#4d282a36", text: "#f8f8f2", textMuted: "#d6d6cf", textDim: "#bfbfb7", textDisabled: "#6272a4", black: "#282a36",
                calendarBackground: "#cc21222c", settingsBackground: "#e621222c", settingsBorder: "#bd93f9", playerOverlay: "#26282a36", playerProgressTrack: "#336272a4", playerProgressFill: "#bd93f9", activeNetworkBackground: "#1a343746", volumeTrack: "#996272a4", volumeFill: "#bd93f9", networkUpload: "#50fa7b", networkDownload: "#ff5555",
                cpu1: "#ff79c6", cpu2: "#ffb86c", cpu3: "#f1fa8c", cpu4: "#50fa7b", cpu5: "#8be9fd", cpu6: "#8be9fd", cpu7: "#bd93f9", cpu8: "#ff79c6", ram: "#8be9fd", metricTrack: "#4d6272a4", ramTrack: "#4d8be9fd", tempHot: "#ff5555", tempWarm: "#ff79c6", tempMild: "#ffb86c", tempCool: "#8be9fd", tempZero: "#f8f8f2", tempCold: "#6272a4", tempVeryCold: "#8be9fd", tempFreezing: "#6c63ff"
            },
            "Nord": {
                baseColor: "#4c566a", accent: "#88c0d0", currentWeather: "#8fbcbb", background: "#4d2e3440", text: "#eceff4", textMuted: "#d8dee9", textDim: "#c4cad4", textDisabled: "#616e82", black: "#2e3440",
                calendarBackground: "#cc2e3440", settingsBackground: "#e62e3440", settingsBorder: "#88c0d0", playerOverlay: "#262e3440", playerProgressTrack: "#334c566a", playerProgressFill: "#88c0d0", activeNetworkBackground: "#1a3b4450", volumeTrack: "#994c566a", volumeFill: "#88c0d0", networkUpload: "#a3be8c", networkDownload: "#bf616a",
                cpu1: "#bf616a", cpu2: "#d08770", cpu3: "#ebcb8b", cpu4: "#a3be8c", cpu5: "#88c0d0", cpu6: "#8fbcbb", cpu7: "#5e81ac", cpu8: "#b48ead", ram: "#81a1c1", metricTrack: "#4d4c566a", ramTrack: "#4d81a1c1", tempHot: "#bf616a", tempWarm: "#d08770", tempMild: "#ebcb8b", tempCool: "#8fbcbb", tempZero: "#eceff4", tempCold: "#81a1c1", tempVeryCold: "#88c0d0", tempFreezing: "#5e81ac"
            },
            "Gruvbox Dark": {
                baseColor: "#665c54", accent: "#fabd2f", currentWeather: "#83a598", background: "#4d1d2021", text: "#ebdbb2", textMuted: "#d5c4a1", textDim: "#bdae93", textDisabled: "#7c6f64", black: "#1d2021",
                calendarBackground: "#cc282828", settingsBackground: "#e61d2021", settingsBorder: "#fabd2f", playerOverlay: "#26232220", playerProgressTrack: "#33665c54", playerProgressFill: "#fabd2f", activeNetworkBackground: "#1a3c3836", volumeTrack: "#99665c54", volumeFill: "#fabd2f", networkUpload: "#b8bb26", networkDownload: "#fb4934",
                cpu1: "#fb4934", cpu2: "#fe8019", cpu3: "#fabd2f", cpu4: "#b8bb26", cpu5: "#83a598", cpu6: "#8ec07c", cpu7: "#458588", cpu8: "#d3869b", ram: "#83a598", metricTrack: "#4d665c54", ramTrack: "#4d83a598", tempHot: "#fb4934", tempWarm: "#fe8019", tempMild: "#fabd2f", tempCool: "#83a598", tempZero: "#ebdbb2", tempCold: "#83a598", tempVeryCold: "#8ec07c", tempFreezing: "#458588"
            },
            "One Dark": {
                baseColor: "#4b5263", accent: "#61afef", currentWeather: "#56b6c2", background: "#4d21252b", text: "#abb2bf", textMuted: "#9da5b4", textDim: "#828997", textDisabled: "#5c6370", black: "#282c34",
                calendarBackground: "#cc282c34", settingsBackground: "#e621252b", settingsBorder: "#61afef", playerOverlay: "#2621252b", playerProgressTrack: "#334b5263", playerProgressFill: "#61afef", activeNetworkBackground: "#1a354052", volumeTrack: "#994b5263", volumeFill: "#61afef", networkUpload: "#98c379", networkDownload: "#e06c75",
                cpu1: "#e06c75", cpu2: "#d19a66", cpu3: "#e5c07b", cpu4: "#98c379", cpu5: "#56b6c2", cpu6: "#61afef", cpu7: "#528bff", cpu8: "#c678dd", ram: "#61afef", metricTrack: "#4d4b5263", ramTrack: "#4d61afef", tempHot: "#e06c75", tempWarm: "#d19a66", tempMild: "#e5c07b", tempCool: "#56b6c2", tempZero: "#abb2bf", tempCold: "#61afef", tempVeryCold: "#56b6c2", tempFreezing: "#528bff"
            },
            Amber: {
                baseColor: "#704800", accent: "#ffb52e", currentWeather: "#ffd166", background: "#4d0a0800",
                text: "#fff6e0", textMuted: "#e0d1b5", textDim: "#c7b895", textDisabled: "#8e826c", black: "#000000",
                calendarBackground: "#cc100c06", settingsBackground: "#e60e0a05", settingsBorder: "#ffb52e",
                playerOverlay: "#28160a00", playerProgressTrack: "#33fff0c2", activeNetworkBackground: "#1a3a2b10",
                volumeTrack: "#99704b00", volumeFill: "#ffb52e", networkUpload: "#a7f3d0", networkDownload: "#ffb4b4",
                cpu1: "#ffb4b4", cpu2: "#ffd8a8", cpu3: "#fff1a8", cpu4: "#c6f6d5", cpu5: "#bde3ff", cpu6: "#c6e8df", cpu7: "#87c9c4", cpu8: "#e7cff3", ram: "#5eb3e7", metricTrack: "#4d704b00", ramTrack: "#4d5eb3e7",
                tempHot: "#ff6b57", tempWarm: "#ff9f66", tempMild: "#ffd166", tempCool: "#f5d6a1", tempZero: "#fff6e0", tempCold: "#a8d8ff", tempVeryCold: "#72d2ef", tempFreezing: "#5e93d9"
            },
            Purple: {
                baseColor: "#5b3f7a", accent: "#c77dff", currentWeather: "#e0aaff", background: "#4d08050d",
                text: "#f7f0ff", textMuted: "#d8cae6", textDim: "#c2b2d6", textDisabled: "#8e809b", black: "#000000",
                calendarBackground: "#cc0d0714", settingsBackground: "#e60b0610", settingsBorder: "#c77dff",
                playerOverlay: "#2613072e", playerProgressTrack: "#33e5cfff", activeNetworkBackground: "#1a352040",
                volumeTrack: "#995b3f7a", volumeFill: "#c77dff", networkUpload: "#b7efc5", networkDownload: "#ffb4cf",
                cpu1: "#ffb4c9", cpu2: "#ffd0b7", cpu3: "#fff5b7", cpu4: "#bfeecb", cpu5: "#c1ddff", cpu6: "#b9dcd7", cpu7: "#7cc9c9", cpu8: "#dcb7ff", ram: "#6fb9ef", metricTrack: "#4d5b3f7a", ramTrack: "#4d6fb9ef",
                tempHot: "#ff7a8f", tempWarm: "#ffb0c2", tempMild: "#ffd3a8", tempCool: "#e9d5ff", tempZero: "#f7f0ff", tempCold: "#b9d8ff", tempVeryCold: "#86dbf4", tempFreezing: "#7e9ee8"
            },
            Ice: {
                baseColor: "#2a5f78", accent: "#5ee7ff", currentWeather: "#9be7ff", background: "#4d001018",
                text: "#f1fbff", textMuted: "#cbe4eb", textDim: "#b8d2db", textDisabled: "#76909a", black: "#000000",
                calendarBackground: "#cc00131a", settingsBackground: "#e6001620", settingsBorder: "#5ee7ff",
                playerOverlay: "#1820363d", playerProgressTrack: "#334ee7ff", activeNetworkBackground: "#1a183945",
                volumeTrack: "#992a5f78", volumeFill: "#5ee7ff", networkUpload: "#b7f0d2", networkDownload: "#ffb8c8",
                cpu1: "#ffb8c8", cpu2: "#ffe0b8", cpu3: "#fffbb8", cpu4: "#b8ffd0", cpu5: "#b8ddff", cpu6: "#b8e4df", cpu7: "#77d7df", cpu8: "#e2ccff", ram: "#69d6ff", metricTrack: "#4d2a5f78", ramTrack: "#4d69d6ff",
                tempHot: "#ff8b8b", tempWarm: "#ffb8c8", tempMild: "#ffe0b8", tempCool: "#c9edff", tempZero: "#f1fbff", tempCold: "#a9dcff", tempVeryCold: "#5ee7ff", tempFreezing: "#5d9de8"
            },
            Mono: {
                baseColor: "#777777", accent: "#dddddd", currentWeather: "#ffffff", background: "#55000000",
                text: "#ffffff", textMuted: "#cccccc", textDim: "#aaaaaa", textDisabled: "#777777", black: "#000000",
                calendarBackground: "#cc000000", settingsBackground: "#e6000000", settingsBorder: "#dddddd",
                playerOverlay: "#22000000", playerProgressTrack: "#33ffffff", activeNetworkBackground: "#1a2d2d2d",
                volumeTrack: "#99555555", volumeFill: "#dddddd", networkUpload: "#bbbbbb", networkDownload: "#eeeeee",
                cpu1: "#d0d0d0", cpu2: "#c6c6c6", cpu3: "#bcbcbc", cpu4: "#d8d8d8", cpu5: "#b2b2b2", cpu6: "#cacaca", cpu7: "#a0a0a0", cpu8: "#e0e0e0", ram: "#b8b8b8", metricTrack: "#4d555555", ramTrack: "#4d888888",
                tempHot: "#ffffff", tempWarm: "#eeeeee", tempMild: "#dddddd", tempCool: "#cccccc", tempZero: "#bbbbbb", tempCold: "#aaaaaa", tempVeryCold: "#999999", tempFreezing: "#888888"
            }
        }

var descriptions = {
    "14 Theme": "Основная бирюзовая тема",
    "Catppuccin Mocha": "Catppuccin Mocha",
    "Tokyo Night": "Tokyo Night",
    "Dracula": "Dracula",
    "Nord": "Nord",
    "Gruvbox Dark": "Gruvbox Dark",
    "One Dark": "One Dark",
    Amber: "Тёплая янтарная палитра",
    Purple: "Фиолетовая палитра",
    Ice: "Холодная сине-бирюзовая палитра",
    Mono: "Нейтральная монохромная палитра"
}

function palette(name, customThemes) {
    var n = String(name)
    if (customThemes && customThemes[n] !== undefined)
        return customThemes[n]
    return palettes[n] || palettes["14 Theme"]
}

function description(name) {
    return descriptions[name] || "Готовая цветовая тема"
}

function preview(name, customThemes) {
    var p = palette(String(name), customThemes)
    return [p.baseColor, p.accent, p.background, p.currentWeather, p.volumeFill, p.ram]
}

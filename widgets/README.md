# Quickshell Desktop Widgets

A modular desktop widget suite for [Quickshell](https://quickshell.outfoxxed.me/) with a unified graphical configuration interface.

The project provides customizable widgets for system monitoring, media, weather, networking and everyday desktop information. Positions, sizes, colors, fonts and widget-specific options can be configured without editing QML files manually.

## Features

- Clock and date
- Calendar
- CPU and RAM monitoring
- CPU usage graph
- Network statistics
- Network manager
- Volume control
- Media player
- CAVA visualizer
- Weather and forecasts
- Timers
- Top applications

### Configuration

- Enable or disable individual widgets
- Configure position and size
- Customize colors and fonts
- Widget-specific settings
- Theme management
- Profiles
- Reset settings to defaults
- Interactive layout editing

### Themes

The configuration interface includes built-in themes and support for custom themes.

Colors can be edited directly from the settings. Modified themes can be saved under a custom name or used to overwrite an existing theme.

## Screenshots

Add screenshots here:

```text
screenshots/
├── desktop.png
├── settings.png
└── themes.png
```

## Requirements

- Linux
- Quickshell
- `jq`
- `curl`
- `nmcli`
- `playerctl`
- `cava`
- `mpv`
- `ffmpeg`
- `lua`

Some dependencies are only required for specific widgets.

## Installation

Clone the repository:

```bash
git clone <repository-url>
cd <repository-directory>
```

Run the installer:

```bash
chmod +x install.sh
./install.sh
```

Then start the shell with Quickshell:

```bash
quickshell -c ~/.config/quickshell/desktop-shell
```

## Configuration

The settings interface is used to configure the shell. Configuration is stored in `settings.json`.

Most settings can be changed directly through the graphical configuration interface.

## Development

Run the project checks with:

```bash
./CHECK.sh
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

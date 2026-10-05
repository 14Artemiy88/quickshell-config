# Quickshell Widgets

Standalone Quickshell widget/configuration project.

## Current checkpoint

**v387** — release-candidate cleanup after the v385 module-frame fix and v386 audit.

## Layout

```text
components/
├── settings/
│   ├── SettingsWidget.qml
│   ├── primitives/     # reusable Settings UI controls
│   └── sections/       # settings sections for individual modules/categories
├── Frame.qml
├── WidgetWindow.qml
└── ...                 # runtime widget modules

js/settings/            # persistence, profiles, themes, apply logic
services/               # background/data services
scripts/                # runtime helper scripts
```

### Settings primitives

Reusable controls live under `components/settings/primitives/`:
`SettingsTextField`, `SettingsNumberField`, `SettingsColorField`, `SettingsButton`,
`SettingsCheckBox`, `SettingsTab`, `SettingsSubTab`, `SettingsGroup`, and related
building blocks.

### Settings sections

Module/category-specific settings live under `components/settings/sections/`.
This keeps reusable controls separate from the sections that compose them.

## Validation

Run:

```bash
./CHECK.sh
```

The check covers QML structure, Bash syntax, and the CPU JSON smoke test.

## Install

Use the included `install.sh` for the project-specific installation flow.

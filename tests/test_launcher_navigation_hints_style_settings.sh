#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
read = lambda p: (root / p).read_text(encoding="utf-8")
config = read("Config.qml")
defaults = read("js/settings/SettingsDefaults.js")
apply = read("js/settings/SettingsApplySystemVisual.js")
persist = read("js/settings/SettingsPersistence.js")
resets = read("js/settings/SettingsResets.js")
nav = read("components/settings/SettingsNavigationController.qml")
settings = read("components/settings/sections/SettingsLauncherSection.qml")
launcher = read("components/launcher/Launcher.qml")

for key, default in (("launcherNavigationHintsHeight", 24), ("launcherNavigationHintsFontSize", 11), ("launcherNavigationHintsTextY", 0)):
    assert f"property int {key}: {default}" in config, f"Config default for {key} changed"
    assert f"{key}: {default}" in defaults, f"new profile default for {key} changed"
    assert f"{key}: config.{key}" in persist, f"{key} is not persisted"
    assert f'"{key}"' in resets, f"{key} is not restored by Launcher reset"
    assert key in nav, f"Settings dirty-state navigation does not track {key}"
    assert f'value: Config.{key}' in settings and f'targetProperty: "{key}"' in settings, f"Settings control for {key} is not connected"
    assert key in apply, f"profile application does not clamp {key}"

assert 'heading: "Панель подсказок"' in settings, "dedicated framed settings group is missing"
assert 'label: "Отображать панель подсказок"' in settings, "visibility checkbox is not inside the panel settings group"
panel_group_start = settings.rfind('    SettingsGroup {', 0, settings.index('heading: "Панель подсказок"'))
panel_group_end = settings.index('    SettingsGroup {', settings.index('heading: "Панель подсказок"'))
panel_group = settings[panel_group_start:panel_group_end]
keyboard_group_start = settings.rfind('    SettingsGroup {', 0, settings.index('heading: "Клавиатурная навигация"'))
keyboard_group_end = settings.index('    SettingsGroup {', settings.index('heading: "Клавиатурная навигация"'))
keyboard_group = settings[keyboard_group_start:keyboard_group_end]
assert 'changeKeys: ({ keys: ["launcherVimKeybinds"] })' in keyboard_group, "keyboard navigation frame tracks only Vim keybind changes"
assert 'launcherShowNavigationHints' not in keyboard_group, "panel visibility must not dirty the keyboard navigation frame"
assert 'label: "Отображать панель подсказок"' in panel_group and 'label: "Высота панели"' in panel_group and 'label: "Размер шрифта"' in panel_group and 'label: "Смещение текста по Y"' in panel_group, "checkbox and all panel controls must share one frame"
assert 'changeKeys: ({ keys: ["launcherShowNavigationHints", "launcherNavigationHintsHeight", "launcherNavigationHintsFontSize", "launcherNavigationHintsTextY"] })' in panel_group, "panel frame dirty state must cover all panel options"
assert 'label: "Высота панели"' in panel_group and 'minimum: 0' in panel_group and 'maximum: 48' in panel_group, "panel height must allow zero and have no positive lower bound"
assert 'label: "Размер шрифта"' in panel_group and 'minimum: 8' in panel_group and 'maximum: 18' in panel_group, "font size range is missing"
assert 'label: "Смещение текста по Y"' in panel_group and 'minimum: -48' in panel_group and 'maximum: 48' in panel_group, "hint text Y offset range is missing"
assert 'id: launcherNavigationHintsControlsClip' in panel_group and 'height: Config.launcherShowNavigationHints ? launcherNavigationHintsControls.implicitHeight : 0' in panel_group, "only the panel controls should collapse when hints are hidden"
assert 'opacity: Config.launcherShowNavigationHints ? 1 : 0' in panel_group and 'Behavior on height' in panel_group and 'Behavior on opacity' in panel_group, "panel controls must animate inside their persistent frame"
assert 'visible: root.host && root.host.currentPageId === "launcher" && root.host.currentPageSubTabIndex === 1' in panel_group, "the complete panel frame is tied to the Navigation subtab, not the checkbox state"
assert 'Layout.preferredHeight: Config.launcherNavigationHintsHeight' in launcher, "footer height does not follow the setting"
assert 'Layout.minimumHeight: 0' in launcher, "footer must have no implicit minimum height"
assert 'Layout.maximumHeight: Config.launcherNavigationHintsHeight' not in launcher, "footer must retain enough implicit height for larger hint text"
footer = launcher.split('visible: Config.launcherShowNavigationHints', 1)[1].split('\n            }', 1)[0]
assert footer.count('font.pixelSize: Config.uiFontSize(Config.launcherNavigationHintsFontSize)') == 7, "all seven hint labels must use the configured text size"
assert 'profile.launcherNavigationHintsHeight === undefined' in resets and '? 24 :' in resets, "legacy profiles receive the default panel height"
assert 'profile.launcherNavigationHintsFontSize === undefined' in resets and '? 11 :' in resets, "legacy profiles receive the default font size"
assert 'profile.launcherNavigationHintsTextY === undefined' in resets and '? 0 :' in resets, "legacy profiles receive the default text offset"
assert 'transform: Translate { y: Config.launcherNavigationHintsTextY }' in footer and footer.count('transform: Translate { y: Config.launcherNavigationHintsTextY }') == 7, "all seven hint labels use the vertical offset"
print("Launcher navigation hint panel height/font settings, defaults, persistence, profile reset and footer bindings: OK")
PY

node - "$ROOT/js/settings/SettingsApplySystemVisual.js" <<'JS'
const fs = require('fs');
const vm = require('vm');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '').replace(/^\.import .*$/gm, '');
const Config = { launcherNavigationHintsHeight: 24, launcherNavigationHintsFontSize: 11, launcherNavigationHintsTextY: 0 };
const context = { Config, Math, Number, String, Boolean, isFinite, console };
vm.runInNewContext(source + '\nthis.applyVisual = apply;', context);
context.applyVisual(Config, { launcherNavigationHintsHeight: 99, launcherNavigationHintsFontSize: 2, launcherNavigationHintsTextY: -99 });
if (Config.launcherNavigationHintsHeight !== 48 || Config.launcherNavigationHintsFontSize !== 8 || Config.launcherNavigationHintsTextY !== -48)
  throw new Error('Launcher hint settings did not clamp oversized/undersized profile values');
context.applyVisual(Config, { launcherNavigationHintsHeight: 0, launcherNavigationHintsFontSize: 15, launcherNavigationHintsTextY: 12 });
if (Config.launcherNavigationHintsHeight !== 0 || Config.launcherNavigationHintsFontSize !== 15 || Config.launcherNavigationHintsTextY !== 12)
  throw new Error('Launcher hint settings did not preserve valid values');
console.log('Launcher hint settings profile clamping and zero-height support: OK');
JS

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
config = (root / "Config.qml").read_text(encoding="utf-8")
defaults = (root / "js/settings/SettingsDefaults.js").read_text(encoding="utf-8")
persistence = (root / "js/settings/SettingsPersistence.js").read_text(encoding="utf-8")
apply = (root / "js/settings/SettingsApplyBehaviour.js").read_text(encoding="utf-8")
profiles = (root / "js/settings/SettingsProfiles.js").read_text(encoding="utf-8")
resets = (root / "js/settings/SettingsResets.js").read_text(encoding="utf-8")
settings = (root / "Settings.qml").read_text(encoding="utf-8")
page = (root / "components/settings/sections/SettingsDashboardSection.qml").read_text(encoding="utf-8")
registry = (root / "js/settings/SettingsPageRegistry.js").read_text(encoding="utf-8")
dashboard = (root / "components/Dashboard.qml").read_text(encoding="utf-8")
helper = (root / "js/dashboard/DashboardAnimation.js").read_text(encoding="utf-8")
assert 'property string animationDashboardVisibilityStyle: "auto"' in config
assert 'property int animationDashboardVisibilityDuration: 300' in config
assert 'animationDashboardVisibilityStyle: "auto"' in defaults
assert 'animationDashboardVisibilityDuration: 300' in defaults
assert 'animationDashboardVisibilityStyle: config.animationDashboardVisibilityStyle' in persistence
assert 'animationDashboardVisibilityDuration: config.animationDashboardVisibilityDuration' in persistence
assert '"auto", "none", "fade", "slideLeft", "slideRight", "slideUp", "slideDown"' in apply
assert 'Math.max(0, Math.min(5000, Math.round(dashboardVisibilityDuration)))' in apply
assert 'animationDashboardVisibilityStyle' in profiles and 'animationDashboardVisibilityDuration' in profiles
assert 'animationDashboardVisibilityStyle' in resets and 'animationDashboardVisibilityDuration' in resets
assert 'config.animationDashboardVisibilityStyle = owner.defaultConfig.animationDashboardVisibilityStyle !== undefined' in resets
assert 'config.animationDashboardVisibilityDuration = owner.defaultConfig.animationDashboardVisibilityDuration !== undefined' in resets
assert 'animationDashboardVisibilityStyle' in settings and 'animationDashboardVisibilityDuration' in settings
assert 'heading: "Появление Dashboard"' in page
assert 'settingsSearchId: "dashboard-visibility-animation-direction"' in page
assert 'settingsSearchId: "dashboard-visibility-animation-duration"' in page
assert 'settingsSearchId: "dashboard-visibility-animation-direction"' in page
assert 'description: "Состав, порядок, видимость, размеры и анимация панели Dashboard."' in registry
assert 'DashboardAnimation.resolveVisibilityStyle(' in dashboard
assert 'DashboardAnimation.hiddenX(visibilityStyle' in dashboard
assert 'DashboardAnimation.hiddenY(visibilityStyle' in dashboard
assert 'duration: drawer.visibilityDuration' in dashboard
assert 'interval: DashboardAnimation.transitionDuration(drawer.visibilityStyle, Config.animationDashboardVisibilityDuration) + 24' in dashboard
assert 'property bool visibilityAnimationReady: false' in dashboard
assert 'id: visibilityAnimationReadyTimer' in dashboard
assert 'interval: 16' in dashboard
assert 'DashboardAnimation.geometryReady(' in dashboard
assert 'root.visibilityAnimationReady = true' in dashboard
assert 'root.visibilityAnimationReady = false' in dashboard
assert 'root.visibilityAnimationReady && (root.open || root.keepWindowDuringClose)' in dashboard
assert 'root.open && root.visibilityAnimationReady' in dashboard
assert 'if (!root.visible || !root.screen || !DashboardAnimation.geometryReady(' in dashboard
assert 'root.screen.width, root.screen.height' in dashboard
assert 'enabled: !root.layoutEditMode && root.visibilityAnimationReady && (root.open || root.keepWindowDuringClose)' in dashboard
assert 'function resolveVisibilityStyle' in helper
print("Dashboard visibility animation: UI, defaults, duration, profile save/reset and runtime wiring: OK")
PY
node - "$ROOT" <<'JS'
const assert = require('assert');
const fs = require('fs');
const vm = require('vm');
const root = process.argv[2];
function loadLibrary(relative, exportsSource) {
  const source = fs.readFileSync(root + '/' + relative, 'utf8').replace(/^\.pragma library\s*/m, '');
  const context = {};
  vm.createContext(context);
  vm.runInContext(source + '\n' + exportsSource, context);
  return context;
}
const animation = loadLibrary('js/dashboard/DashboardAnimation.js', `
  this.normalize = normalizeVisibilityStyle;
  this.resolve = resolveVisibilityStyle;
  this.hiddenX = hiddenX;
  this.hiddenY = hiddenY;
  this.duration = normalizeDuration;
  this.geometryReady = geometryReady;
  this.fade = usesFade;
`);
assert.strictEqual(animation.resolve('auto', 16, 560, 1920), 'slideLeft', 'left-aligned Dashboard enters from the left');
assert.strictEqual(animation.resolve('auto', 1344, 560, 1920), 'slideRight', 'right-aligned Dashboard preserves the historical right-side entry');
assert.strictEqual(animation.resolve('auto', 680, 560, 1920), 'slideLeft', 'center tie resolves deterministically');
for (const style of ['none', 'fade', 'slideLeft', 'slideRight', 'slideUp', 'slideDown'])
  assert.strictEqual(animation.resolve(style, 16, 560, 1920), style, `${style} remains manually selectable`);
assert.strictEqual(animation.hiddenX('slideLeft', 16, 560, 1920, 16), -576, 'left slide hides fully beyond the left edge');
assert.strictEqual(animation.hiddenX('slideRight', 1344, 560, 1920, 16), 1936, 'right slide hides fully beyond the right edge');
assert.strictEqual(animation.hiddenY('slideUp', 16, 400, 1080, 16), -416, 'up slide hides fully above the monitor');
assert.strictEqual(animation.hiddenY('slideDown', 100, 400, 1080, 16), 1096, 'down slide hides fully below the monitor');
assert.strictEqual(animation.hiddenX('fade', 16, 560, 1920, 16), 16, 'fade does not move the panel');
assert.strictEqual(animation.fade('fade'), true);
assert.strictEqual(animation.fade('none'), true);
assert.strictEqual(animation.fade('slideLeft'), false);
assert.strictEqual(animation.normalize('bad-value'), 'auto');
assert.strictEqual(animation.duration(-1), 0);
assert.strictEqual(animation.duration(125.6), 126);
assert.strictEqual(animation.duration(6000), 5000);
assert.strictEqual(animation.transitionDuration('none', 300), 0, 'none exits immediately');
assert.strictEqual(animation.transitionDuration('auto', 300), 300, 'auto keeps the configured transition duration');
assert.strictEqual(animation.geometryReady(1920, 1080, 560, 600, 1920, 1080), true, 'host, target screen and drawer geometry are ready');
assert.strictEqual(animation.geometryReady(1, 1080, 1, 600, 1920, 1080), false, 'transient 1px host and drawer sizes are not ready');
assert.strictEqual(animation.geometryReady(1920, 1080, 560, 1200, 1920, 1080), false, 'drawer cannot exceed host height');
assert.strictEqual(animation.geometryReady(0, 0, 560, 420, 1920, 1080), false, 'unresolved host geometry is not ready');
assert.strictEqual(animation.geometryReady(1600, 900, 560, 600, 1920, 1080), false, 'stale dimensions from the previous monitor are not ready');
assert.strictEqual(animation.geometryReady(1920, 1080, 560, 600, 0, 0), false, 'missing selected screen geometry is not ready');

const behaviour = loadLibrary('js/settings/SettingsApplyBehaviour.js', 'this.applyForTest = apply;');
const cfg = {};
behaviour.applyForTest(cfg, {animationDashboardVisibilityStyle:'slideUp', animationDashboardVisibilityDuration:6200});
assert.strictEqual(cfg.animationDashboardVisibilityStyle, 'slideUp');
assert.strictEqual(cfg.animationDashboardVisibilityDuration, 5000);
behaviour.applyForTest(cfg, {animationDashboardVisibilityStyle:'invalid', animationDashboardVisibilityDuration:-50});
assert.strictEqual(cfg.animationDashboardVisibilityStyle, 'slideUp', 'invalid style must not replace current value');
assert.strictEqual(cfg.animationDashboardVisibilityDuration, 0, 'duration is clamped at zero');

const profiles = loadLibrary('js/settings/SettingsProfiles.js', 'this.pathMatches = profileSavePathMatches;');
assert.strictEqual(profiles.pathMatches(null, 'dashboard', null, ['animationDashboardVisibilityStyle']), true, 'Dashboard page scope saves style');
assert.strictEqual(profiles.pathMatches(null, 'dashboard', null, ['animationDashboardVisibilityDuration']), true, 'Dashboard page scope saves duration');
assert.strictEqual(profiles.pathMatches(null, 'dashboardModule', 'dashboard', ['animationDashboardVisibilityStyle']), true, 'Dashboard module row scope saves style');
assert.strictEqual(profiles.pathMatches(null, 'dashboardModule', 'dashboard', ['animationDashboardVisibilityDuration']), true, 'Dashboard module row scope saves duration');

const resets = loadLibrary('js/settings/SettingsResets.js', 'this.resetDashboardForTest = resetDashboardSettings;');
function makeOwner(profile) {
  return {
    activeProfile: 'Default', profiles: {Default: profile},
    defaultConfig: {dashboardVisibleCards:['today','system','network','weather','media'], dashboardCardOrder:['today','system','network','weather','media'], dashboardColumnsMode:'auto', dashboardCardSizes:{today:'compact',system:'compact',network:'compact',weather:'compact',media:'compact'}, animationDashboardVisibilityStyle:'auto', animationDashboardVisibilityDuration:300},
    saveCount:0, save(){this.saveCount++;}, resetUnavailable(){throw new Error('profile should be active');}
  };
}
const legacyOwner = makeOwner({dashboardVisibleCards:['today','system','network','weather','media']});
const legacyConfig = {animationDashboardVisibilityStyle:'slideLeft',animationDashboardVisibilityDuration:900};
resets.resetDashboardForTest(legacyOwner, legacyConfig, false);
assert.strictEqual(legacyConfig.animationDashboardVisibilityStyle, 'auto', 'legacy profile reset restores auto direction');
assert.strictEqual(legacyConfig.animationDashboardVisibilityDuration, 300, 'legacy profile reset restores default duration');
const modernOwner = makeOwner({dashboardVisibleCards:['today','system','network','weather','media'], animationDashboardVisibilityStyle:'slideUp', animationDashboardVisibilityDuration:650});
const modernConfig = {};
resets.resetDashboardForTest(modernOwner, modernConfig, false);
assert.strictEqual(modernConfig.animationDashboardVisibilityStyle, 'slideUp', 'saved profile direction is restored');
assert.strictEqual(modernConfig.animationDashboardVisibilityDuration, 650, 'saved profile duration is restored');
console.log('Dashboard animation placement, startup geometry gate, transitions, validation, profile scope and legacy resets: PASS');
JS

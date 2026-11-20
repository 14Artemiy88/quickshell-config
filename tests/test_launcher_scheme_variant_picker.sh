#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="$ROOT/js/launcher/LauncherSchemeVariantPicker.js"
LAUNCHER="$ROOT/components/launcher/Launcher.qml"
SCRIPT="$ROOT/scripts/launcher_dynamic_scheme"

node - "$MODULE" <<'JS'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const api = vm.runInThisContext(source + '\n({ DEFAULT_VARIANT, variants, normalizeVariant, parseQuery, buildResults, isVariant })');
assert.strictEqual(api.DEFAULT_VARIANT, 'scheme-tonal-spot');
assert.strictEqual(api.variants.length, 8, 'Matugen variant list contains all eight documented Material You schemes');
for (const variant of api.variants) {
  assert.strictEqual(api.normalizeVariant(variant.id), variant.id);
  assert.strictEqual(api.isVariant(variant.id), true);
}
assert.strictEqual(api.normalizeVariant('tonal spot'), 'scheme-tonal-spot');
assert.strictEqual(api.normalizeVariant('монохром'), 'scheme-monochrome');
assert.strictEqual(api.normalizeVariant('unknown'), '');
for (const command of ['variant', 'variants', 'scheme-variant', 'style', 'вариант', 'варианты', 'стиль']) {
  assert.deepStrictEqual(api.parseQuery(command), { active: true, query: '' });
  assert.strictEqual(api.parseQuery(`${command} expressive`).query, 'expressive');
}
assert.deepStrictEqual(api.parseQuery('scheme variants'), { active: true, query: '' }, 'canonical nested command opens the variant picker');
assert.strictEqual(api.parseQuery('scheme variants expressive').query, 'expressive', 'canonical nested command preserves search text');
assert.strictEqual(api.parseQuery('scheme variant tonal').query, 'tonal', 'singular nested command is accepted as an alias');
assert.strictEqual(api.parseQuery('scheme nord').active, false, 'ordinary theme search remains owned by the scheme picker');
assert.strictEqual(api.parseQuery('variant-dynamic').active, false, 'variant command requires token boundary');
const score = (text, query) => String(text).toLowerCase().includes(String(query).toLowerCase()) ? 100 : -1;
let rows = api.buildResults('', 'scheme-monochrome', score, 100);
assert.strictEqual(rows.length, 8);
assert.strictEqual(rows[0].variant, 'scheme-monochrome', 'active variant is first without a query');
assert.strictEqual(rows[0].isActive, true);
rows = api.buildResults('fruit', 'scheme-tonal-spot', score, 100);
assert.strictEqual(rows.length, 1);
assert.strictEqual(rows[0].variant, 'scheme-fruit-salad');
rows = api.buildResults('монохром', 'scheme-tonal-spot', score, 100);
assert.strictEqual(rows[0].variant, 'scheme-monochrome', 'Russian aliases are searchable');
rows = api.buildResults('not-a-variant', 'scheme-tonal-spot', score, 100);
assert.strictEqual(rows.length, 0);
console.log('Scheme variant aliases, eight Material You types, active ordering and search: OK');
JS

python3 - "$LAUNCHER" "$SCRIPT" <<'PY'
from pathlib import Path
import sys
launcher = Path(sys.argv[1]).read_text()
script = Path(sys.argv[2]).read_text()
assert 'LauncherSchemeVariantPicker.js" as LauncherSchemeVariantPicker' in launcher
assert 'LauncherSchemeVariantPicker.parseQuery(normalizedQuery)' in launcher
assert 'kind: "schemeVariantPickerAction"' in launcher
assert 'kind: "schemeVariantError"' not in launcher, 'failed variants are reported by notification, not inserted into the result list'
assert 'root.selectDynamicSchemeVariant(result.variant)' in launcher
assert 'readonly property bool schemeVariantPickerActive' in launcher
assert 'root.wallpaperPickerActive || root.dynamicSchemePickerActive || root.schemeVariantPickerActive' in launcher, 'monitor toolbar is visible in Scheme variants mode'
assert 'model: Quickshell.screens' in launcher and 'root.wallpaperSelectScreen(parent.modelData, parent.index)' in launcher, 'variant picker reuses the Wallpaper Picker monitor selector'
assert 'root.wallpaperSelectedScreenName' in launcher and 'latestWallpaperForScreen(root.wallpaperPickerData, root.wallpaperSelectedScreenName)' in launcher, 'variant selection reads the selected monitor wallpaper history'
assert 'searchField.text = ">scheme variants"' in launcher, 'the canonical nested Scheme variants command is used by Launcher navigation'
assert 'Обои для ' in launcher, 'variant picker identifies the selected wallpaper source monitor'
assert 'dynamicSchemeProcessing' not in launcher, 'processing status must not be inserted into Launcher results'
assert 'if (root.dynamicSchemeBusy)\n                return []' in launcher, 'variant palette hides transient rows while Matugen is running'
assert 'Создаётся цветовая схема…' in launcher and 'Цветовая схема создана' in launcher, 'progress and success are sent as notifications'
assert '--print-id' in launcher and '--replace-id=' in launcher, 'progress notification is updated in place after completion'
assert 'root.queueDynamicSchemeNotificationUpdate("success")' in launcher, 'success notification waits for the progress notification ID'
assert 'root.queueDynamicSchemeNotificationUpdate("error")' in launcher, 'error notification replaces progress state too'
assert '--action=copy-error=Копировать ошибку' in launcher, 'error replacement keeps its copy action'
assert 'root.generateDynamicScheme(source.path, source.screenName, selectedVariant)' in launcher
assert 'root.dynamicSchemePendingVariant' in launcher
assert 'Config.launcherDynamicSchemeVariant = root.dynamicSchemePendingVariant' in launcher
assert 'Settings.activeTheme' in launcher and 'LauncherDynamicScheme.GENERATED_THEME_NAME' in launcher
assert 'Even when the variant is already active, regenerate it from the' in launcher, 'same variant can regenerate from another monitor source'
assert 'root.dynamicSchemePendingVariant\n        ]' in launcher, 'Matugen Process receives the selected type'
assert '-m dark -t "$variant" --json hex --dry-run' in script
assert 'matugen -c \"$config_file\" image \"$image_path\"' in script
assert '--old-json-output' not in script, 'Matugen native JSON is parsed directly for v3/v4 compatibility'
for variant in ['scheme-content', 'scheme-expressive', 'scheme-fidelity', 'scheme-fruit-salad', 'scheme-monochrome', 'scheme-neutral', 'scheme-rainbow', 'scheme-tonal-spot']:
    assert variant in script
assert 'Unsupported Matugen scheme variant' in script
print('Launcher variant mode, current selection, safe apply and Matugen CLI wiring: OK')
PY

echo 'Launcher scheme variant picker: OK'

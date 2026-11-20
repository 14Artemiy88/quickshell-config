#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HELPER="$ROOT/js/cava/GraphValuesModel.js"
CAVA="$ROOT/components/Cava.qml"
PRIMITIVE="$ROOT/components/primitives/SegmentBarGraph.qml"
for file in "$HELPER" "$CAVA" "$PRIMITIVE"; do test -f "$file"; done

node - "$HELPER" "$CAVA" "$PRIMITIVE" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const [helperPath, cavaPath, primitivePath] = process.argv.slice(2);
const helperSource = fs.readFileSync(helperPath, 'utf8').replace(/^\.pragma library\s*/, '');
const context = {};
vm.runInNewContext(helperSource, context, { filename: 'GraphValuesModel.js' });

class MockListModel {
  constructor() { this.rows = []; this.writes = []; }
  get count() { return this.rows.length; }
  get(index) { return this.rows[index]; }
  append(row) { this.rows.push({ ...row }); }
  remove(index) { this.rows.splice(index, 1); }
  setProperty(index, role, value) {
    this.rows[index][role] = value;
    this.writes.push({ index, role, value });
  }
}
const model = new MockListModel();
let result = context.sync(model, [0, 12, 24, 36, 48], 5);
assert.strictEqual(result.peak, 48, 'peak must be computed during the same pass');
assert.strictEqual(result.changedCount, 4, 'initial frame should update only non-zero rows');
assert.strictEqual(model.count, 5, 'model must have one stable row per configured bar');
assert.deepStrictEqual(model.writes.map(x => x.index), [1, 2, 3, 4], 'initial role updates must be scoped to changed rows');
model.writes = [];

result = context.sync(model, [0, 12, 24, 36, 48], 5);
assert.strictEqual(result.changedCount, 0, 'identical frame should perform zero row updates');
assert.deepStrictEqual(model.writes, [], 'identical audio frame should not notify delegates');

result = context.sync(model, [0, 15, 24, 0, 48], 5);
assert.strictEqual(result.peak, 48, 'peak must remain exact');
assert.strictEqual(result.changedCount, 2, 'only the two changed samples should update');
assert.deepStrictEqual(model.writes.map(x => x.index), [1, 3], 'updates must be scoped to changed bar rows');

result = context.sync(model, [0, NaN, -5, 0, 101], 5);
assert.strictEqual(result.peak, 101, 'peak detection preserves original non-negative comparison behavior');
assert.strictEqual(result.changedCount, 3, 'invalid and negative samples are normalized while unchanged rows stay quiet');
assert.deepStrictEqual(model.rows.map(x => x.value), [0, 0, -5, 0, 101]);

result = context.sync(model, [8, 9], 3);
assert.strictEqual(model.count, 3, 'short frames must zero-fill remaining configured slots');
assert.deepStrictEqual(model.rows.map(x => x.value), [8, 9, 0]);
assert.strictEqual(result.peak, 9);
result = context.sync(model, [7, 8, 9, 10], 2);
assert.strictEqual(model.count, 2, 'bar-count changes must resize the shared model');
assert.deepStrictEqual(model.rows.map(x => x.value), [7, 8]);
assert.strictEqual(result.peak, 10, 'peak scan must cover unexpected extra input values too');

const cava = fs.readFileSync(cavaPath, 'utf8');
const primitive = fs.readFileSync(primitivePath, 'utf8');
assert(cava.includes('import "../js/cava/GraphValuesModel.js" as CavaGraphValuesModel'), 'CAVA must use tested incremental model helper');
assert(cava.includes('ListModel { id: cavaValuesModel }'), 'CAVA must own one shared model');
assert(cava.includes('CavaGraphValuesModel.sync(cavaValuesModel, samples, Config.cavaBars)'), 'CAVA must sync the shared model');
assert.strictEqual((cava.match(/valuesModel: cavaValuesModel/g) || []).length, 4, 'all four render regions must share the same model');
assert(!cava.includes('values: root.values'), 'graph delegates must not bind to the whole-array property');
assert(primitive.includes('model: root.valuesModel'), 'the renderer must subscribe to ListModel roles');
assert(primitive.includes('required property real value'), 'each delegate must consume only its role value');
assert(primitive.includes('root.barHeightFor(value, parent.height)'), 'height binding must be row-local');
console.log('CAVA incremental value model: unchanged rows skipped; shared mirrored model and role-local bindings: OK');
NODE

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CPU graph data validation: FAIL: $*" >&2; exit 1; }
helper="$ROOT/js/cpuGraphData.js"
widget="$ROOT/components/CpuGraph.qml"
[[ -f "$helper" && -f "$widget" ]] || fail "graph data helper or widget is missing"
grep -Fq 'import "../js/cpuGraphData.js" as CpuGraphData' "$widget" || fail "CpuGraph does not import the normalizer"
grep -Fq 'CpuGraphData.normalizeHistory(parsed, 51)' "$widget" || fail "incoming history is not normalized"
grep -Fq 'if (normalized !== null)' "$widget" || fail "malformed arrays would replace the last good sample"

node - "$helper" <<'NODE'
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[2], 'utf8').replace(/^\.pragma library\s*/, '');
const context = {};
vm.runInNewContext(source, context, {filename: 'cpuGraphData.js'});
const normalize = context.normalizeHistory;
assert.strictEqual(typeof normalize, 'function');
const valid = Array.from({length: 51}, (_, i) => i % 101);
assert.deepStrictEqual(Array.from(normalize(valid, 51)), valid, 'valid history must be preserved');
assert.strictEqual(normalize(valid.slice(0, 50), 51), null, 'short history must be rejected');
assert.strictEqual(normalize({}, 51), null, 'non-array JSON must be rejected');
assert.strictEqual(normalize(valid, 0), null, 'invalid expected length must be rejected');
const corrupt = valid.slice();
corrupt[0] = -15;
corrupt[1] = 145;
corrupt[2] = '55';
corrupt[3] = null;
corrupt[4] = NaN;
corrupt[5] = Infinity;
const clean = Array.from(normalize(corrupt, 51));
assert.strictEqual(clean[0], 0, 'negative samples must be clamped');
assert.strictEqual(clean[1], 100, 'samples above 100 must be clamped');
assert.strictEqual(clean[2], 0, 'string samples must be rejected safely');
assert.strictEqual(clean[3], 0, 'null samples must be rejected safely');
assert.strictEqual(clean[4], 0, 'NaN samples must be rejected safely');
assert.strictEqual(clean[5], 0, 'infinite samples must be rejected safely');
assert.strictEqual(clean.length, 51, 'normalized history must preserve exact length');
console.log('CPU graph data validation: OK');
NODE

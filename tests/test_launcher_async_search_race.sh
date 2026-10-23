#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
s = (root / "components/launcher/Launcher.qml").read_text()

def section(start, end):
    a = s.index(start)
    b = s.index(end, a)
    return s[a:b]

# Generation is invalidated on tab changes, immediate query edits, and close.
assert "property int nixSearchGeneration: 0" in s
hide = section("function hideLauncher()", "function toggleLauncher()")
assert "root.nixSearchGeneration += 1" in hide
assert "nixSearchTimer.stop()" in hide and "nixSearchProcess.running = false" in hide
set_mode = section("function setMode(newMode)", "function activeListForMode(")
assert "root.nixSearchGeneration += 1" in set_mode
assert "nixSearchTimer.stop()" in set_mode
schedule = section("function scheduleNixSearch()", "function nixSearchUrl(")
assert "root.nixSearchGeneration += 1" in schedule and "nixSearchTimer.restart()" in schedule

# Every process result carries the identity of the query that produced it.
start = s.index("function searchNixPackages()")
end = s.index("function finishNixSearch(output)", start)
search = s[start:end]
assert "const requestGeneration = root.nixSearchGeneration" in search
assert "String(requestGeneration)" in search
assert "request_id=$2" in search
assert "__SCHEMA__WILDCARD\\\\n__REQUEST__%s" in search, "success response must include request id"
assert "__SCHEMA__ERROR\\\\n__REQUEST__%s" in search, "error response must include request id"

# Out-of-order/missing-token responses must be rejected before touching results.
finish = section("function finishNixSearch(output)", "function addSelectedNixPackage(")
assert 'const requestMarker = "\\n__REQUEST__"' in finish
assert "requestMarkerIndex < 0" in finish
assert "completedGeneration !== root.nixSearchGeneration" in finish
assert finish.index("completedGeneration !== root.nixSearchGeneration") < finish.index("root.nixResults = unique")
assert "if (root.mode !== root.modeNix)" in finish

# Model the marker rule: a response from an old query can't commit over a new one.
def response_is_current(output, generation):
    marker = "\n__REQUEST__"
    idx = output.rfind(marker)
    if idx < 0:
        return False
    try:
        returned = int(output[idx + len(marker):].strip())
    except ValueError:
        return False
    return returned == generation

assert response_is_current('{"hits":{}}\n__SCHEMA__WILDCARD\n__REQUEST__9', 9)
assert not response_is_current('{"hits":{}}\n__SCHEMA__WILDCARD\n__REQUEST__8', 9)
assert not response_is_current('{"hits":{}}\n__SCHEMA__WILDCARD', 9)
print("Launcher async Nix search ignores stale/out-of-order responses: OK")
PY

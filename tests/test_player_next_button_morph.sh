#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLAYER="$ROOT/components/Player.qml"
python3 - "$PLAYER" <<'PYCODE'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding='utf-8')
start = source.index('Primitives.MorphGeometry {\n        id: playerNextMorph')
end = source.index('property real pendingSeekPercent', start)
block = source[start:end]
checks = {
    'shared MorphGeometry wrapper': 'id: playerNextMorph' in block,
    'fixed target geometry': 'root.effectivePlayerNextIconSize + 2' in block,
    'small inset start geometry': 'Math.max(0, root.effectivePlayerNextIconSize),' in block,
    'supported backends are unchanged': 'deadbeef' in source and 'mopidy' in source and 'spotify' in source,
    'exit remains visible through transition': 'root.playerNextSupported || normalizedProgress > 0.001' in block,
    'button interaction is gated by backend support': 'interactionEnabled: root.playerNextSupported' in block,
    'existing next action is preserved': '"next", root.player.player || ""' in block,
    'opacity and scale share morph progress': 'opacity: playerNextMorph.normalizedProgress' in block and 'scale: 0.96 + 0.04 * playerNextMorph.normalizedProgress' in block,
    'initialized after component creation': 'root.playerNextMorphProgress = root.playerNextSupported ? 1 : 0' in source,
}
failed = [name for name, passed in checks.items() if not passed]
if failed:
    raise SystemExit('Player Next Morph failed: ' + ', '.join(failed))
print('Player Next Morph: backend lifecycle, action route and fixed geometry: OK')
PYCODE

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import re, sys
root=Path(sys.argv[1]); p=(root/'components/settings/sections/SettingsPlayerSection.qml').read_text()
def groups_for(tab):
    blocks=[]
    for m in re.finditer(r'SettingsGroup\s*\{',p):
        start=m.start(); op=p.find('{',m.start()); d=0; q=None; esc=False
        for i in range(op,len(p)):
            c=p[i]
            if q:
                if esc: esc=False
                elif c=='\\': esc=True
                elif c==q: q=None
                continue
            if c in ('"', "'"): q=c
            elif c=='{': d+=1
            elif c=='}':
                d-=1
                if d==0:
                    b=p[start:i+1]
                    if f'host.currentOtherSubTab === {tab}' in b: blocks.append(b)
                    break
    return blocks
progress='\n'.join(groups_for(5)); cover='\n'.join(groups_for(6))
assert 'targetProperty: "playerProgressTrack"' in progress and 'targetProperty: "playerProgressFill"' in progress
assert 'playerCoverOpacityField' not in progress and 'playerCoverOpacityField' in cover
print('Player progress colors and cover-opacity placement: OK')
PY

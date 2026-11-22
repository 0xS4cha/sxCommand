#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
ffdec="${FFDEC:?set FFDEC to the path of JPEXS ffdec-cli.jar}"
work="$(mktemp -d)"
class="__Packages/com/rockstargames/gtav/levelDesign/MINIMAP_LOADER.as"

java -jar "$ffdec" -export script "$work/base" "$root/gfx/base/MINIMAP_LOADER.gfx" > /dev/null
mkdir -p "$work/build/$(dirname "$class")"
mkdir -p "$work/build/frame_1"
python3 - "$work/base/scripts" "$root/gfx/src/sx_engine.as" "$work/build" "$class" <<'PY'
import sys
base, engine, out, cls = sys.argv[1:]
source = open(f'{base}/{cls}').read().rstrip()
assert source.endswith('}'), 'unexpected class layout'
source = source[:-1].rstrip() + '\n\n' + open(engine).read() + '}\n'
for old, new in (('class com.rockstargames.gtav.levelDesign.MINIMAP_LOADER ', 'class com.rockstargames.gtav.levelDesign.SX_COMMAND_LOADER '), ('function MINIMAP_LOADER(', 'function SX_COMMAND_LOADER(')):
    assert source.count(old) == 1, old
    source = source.replace(old, new)
open(f'{out}/{cls}', 'w').write(source)
frame = open(f'{base}/frame_1/DoAction.as').read()
assert 'levelDesign.MINIMAP_LOADER(' in frame, 'unexpected frame script'
open(f'{out}/frame_1/DoAction.as', 'w').write(frame.replace('levelDesign.MINIMAP_LOADER(', 'levelDesign.SX_COMMAND_LOADER('))
PY
java -jar "$ffdec" -onerror abort -importScript "$root/gfx/base/MINIMAP_LOADER.gfx" "$root/core/SX_COMMAND.gfx" "$work/build"
rm -rf "$work"
echo "built core/SX_COMMAND.gfx"

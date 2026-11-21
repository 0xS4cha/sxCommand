#!/usr/bin/env bash
# Rebuilds core/SX_COMMAND.gfx from the base minimap overlay and gfx/src/sx_engine.as.
# usage: FFDEC=/path/to/ffdec-cli.jar ./gfx/build.sh
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
ffdec="${FFDEC:?set FFDEC to the path of JPEXS ffdec-cli.jar}"
work="$(mktemp -d)"
class="__Packages/com/rockstargames/gtav/levelDesign/MINIMAP_LOADER.as"

java -jar "$ffdec" -export script "$work/base" "$root/gfx/base/MINIMAP_LOADER.gfx" > /dev/null
mkdir -p "$work/build/$(dirname "$class")"
python3 - "$work/base/scripts/$class" "$root/gfx/src/sx_engine.as" "$work/build/$class" <<'PY'
import sys
base, engine, out = sys.argv[1:]
source = open(base).read().rstrip()
assert source.endswith('}'), 'unexpected class layout'
open(out, 'w').write(source[:-1].rstrip() + '\n\n' + open(engine).read() + '}\n')
PY
java -jar "$ffdec" -onerror abort -importScript "$root/gfx/base/MINIMAP_LOADER.gfx" "$root/core/SX_COMMAND.gfx" "$work/build"
rm -rf "$work"
echo "built core/SX_COMMAND.gfx"

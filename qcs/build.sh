#!/usr/bin/env bash
# Assembles the two paste-ready QCS scripts from the shared core.
# Output: qcs/scripts/XAUUSD_Smart_Entry_Main.lua and ..._Panel.lua
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p scripts

build () {
    local out="$1" header="$2" view="$3"
    {
        echo "$header"
        echo "-- Generated from qcs/src (core.lua + $view). Edit the sources, then run qcs/build.sh."
        cat src/core.lua
        cat "src/$view"
    } > "scripts/$out"
    echo "built scripts/$out ($(wc -l < "scripts/$out") lines)"
}

build "XAUUSD_Smart_Entry_Main.lua" \
  'instrument { name = "XAUUSD Smart Entry V2", short_name = "XAU-SE2", overlay = true }' \
  "view_main.lua"

build "XAUUSD_Smart_Entry_Panel.lua" \
  'instrument { name = "XAUUSD Smart Entry V2 Panel", short_name = "XAU-SE2 Score", overlay = false }' \
  "view_panel.lua"

# Compact = the Main script with layout-only compression (same code, fewer lines)
if command -v lua5.3 >/dev/null 2>&1; then
    lua5.3 tools/compact.lua scripts/XAUUSD_Smart_Entry_Main.lua scripts/XAUUSD_Smart_Entry_Compact.lua
    # Mini = Compact with whitespace removed (fits the V1 size: <= 24,790 characters)
    lua5.3 tools/minify.lua scripts/XAUUSD_Smart_Entry_Compact.lua scripts/XAUUSD_Smart_Entry_Mini.lua
else
    echo "lua5.3 not found: Compact script not regenerated" >&2
fi

if command -v luac5.3 >/dev/null 2>&1; then
    for f in scripts/*.lua; do luac5.3 -p "$f" && echo "syntax OK: $f"; done
else
    echo "luac5.3 not found: syntax check skipped" >&2
fi

# Optional: qcs/build.sh --test  -> also run the offline test suite (needs lua5.3)
if [ "${1:-}" = "--test" ]; then
    cd ..
    lua5.3 qcs/test/run_tests.lua
fi

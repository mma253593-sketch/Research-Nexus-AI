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
  'instrument { name = "XAUUSD Smart Entry V3 Fast", short_name = "XAU-SE3", overlay = true }' \
  "view_main.lua"

build "XAUUSD_Smart_Entry_Panel.lua" \
  'instrument { name = "XAUUSD Smart Entry V3 Panel", short_name = "XAU-SE3 Panel", overlay = false }' \
  "view_panel.lua"

# V1.1 = V1 (user's preferred engine) with the RSI-score and pivot fixes, in qcs/v1
build_v1 () {
    local out="$1" header="$2" view="$3"
    {
        echo "$header"
        echo "-- Generated from qcs/v1/src (core.lua + $view). Edit the sources, then run qcs/build.sh."
        cat v1/src/core.lua
        cat "v1/src/$view"
    } > "v1/scripts/$out"
    echo "built v1/scripts/$out ($(wc -l < "v1/scripts/$out") lines)"
}
mkdir -p v1/scripts
build_v1 "XAUUSD_Smart_Entry_V1_1_Main.lua" \
  'instrument { name = "XAUUSD Smart Entry V1.1", short_name = "XAU-SE1.1", overlay = true }' \
  "view_main.lua"
build_v1 "XAUUSD_Smart_Entry_V1_1_Panel.lua" \
  'instrument { name = "XAUUSD Smart Entry V1.1 Panel", short_name = "XAU-SE1.1 Score", overlay = false }' \
  "view_panel.lua"

# Compact = the Main script with layout-only compression (same code, fewer lines)
if command -v lua5.3 >/dev/null 2>&1; then
    lua5.3 tools/compact.lua scripts/XAUUSD_Smart_Entry_Main.lua scripts/XAUUSD_Smart_Entry_Compact.lua
    # Mini = Compact with whitespace removed (fits the V1 size: <= 24,790 characters)
    lua5.3 tools/minify.lua scripts/XAUUSD_Smart_Entry_Compact.lua scripts/XAUUSD_Smart_Entry_Mini.lua
    lua5.3 tools/compact.lua v1/scripts/XAUUSD_Smart_Entry_V1_1_Main.lua v1/scripts/XAUUSD_Smart_Entry_V1_1_Compact.lua
    lua5.3 tools/minify.lua v1/scripts/XAUUSD_Smart_Entry_V1_1_Compact.lua v1/scripts/XAUUSD_Smart_Entry_V1_1_Mini.lua
else
    echo "lua5.3 not found: Compact script not regenerated" >&2
fi

if command -v luac5.3 >/dev/null 2>&1; then
    for f in scripts/*.lua v1/scripts/*.lua; do luac5.3 -p "$f" && echo "syntax OK: $f"; done
else
    echo "luac5.3 not found: syntax check skipped" >&2
fi

# Optional: qcs/build.sh --test  -> also run the offline test suite (needs lua5.3)
if [ "${1:-}" = "--test" ]; then
    cd ..
    lua5.3 qcs/test/run_tests.lua
    lua5.3 qcs/test/run_tests_v1.lua
fi

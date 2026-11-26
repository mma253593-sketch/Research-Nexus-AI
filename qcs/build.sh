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
  'instrument { name = "XAUUSD Smart Entry", short_name = "XAU-SE", overlay = true }' \
  "view_main.lua"

build "XAUUSD_Smart_Entry_Panel.lua" \
  'instrument { name = "XAUUSD Smart Entry Panel", short_name = "XAU-SE Score", overlay = false }' \
  "view_panel.lua"

if command -v luac5.3 >/dev/null 2>&1; then
    for f in scripts/*.lua; do luac5.3 -p "$f" && echo "syntax OK: $f"; done
fi

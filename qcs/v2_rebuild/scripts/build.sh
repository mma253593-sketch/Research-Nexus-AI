#!/usr/bin/env bash
# XAUUSD Smart Entry V2.0 — isolated build + verification.
# Does not touch qcs/build.sh, qcs/v1, qcs/src, qcs/scripts or qcs/archive/v2.
#
#   qcs/v2_rebuild/scripts/build.sh          # syntax check + bundle
#   qcs/v2_rebuild/scripts/build.sh --test   # + full test suite + protected-path check
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
LUA="${LUA:-lua5.3}"; LUAC="${LUAC:-luac5.3}"
command -v "$LUA" >/dev/null || { echo "error: $LUA not found (Lua 5.3 required)" >&2; exit 1; }
command -v "$LUAC" >/dev/null || { echo "error: $LUAC not found" >&2; exit 1; }

echo "== syntax check (sources)"
for f in "$HERE"/src/*.lua "$HERE"/src/qcs/*.lua "$HERE"/config/*.lua "$HERE"/test/*.lua "$HERE"/eval/*.lua "$HERE"/scripts/*.lua; do
    "$LUAC" -p "$f"
done
echo "ok"

echo "== bundle"
mkdir -p "$HERE/dist"
"$LUA" "$HERE/scripts/build.lua"
for f in "$HERE"/dist/*.lua; do "$LUAC" -p "$f"; echo "syntax OK: dist/$(basename "$f")"; done

if [ "${1:-}" = "--test" ]; then
    echo "== tests"
    "$LUA" "$HERE/test/run_all.lua"
    echo "== protected components unchanged"
    if git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
        if git -C "$REPO" status --porcelain -- qcs/v1 qcs/src qcs/scripts qcs/archive/v2 qcs/build.sh | grep -q .; then
            git -C "$REPO" status --short -- qcs/v1 qcs/src qcs/scripts qcs/archive/v2 qcs/build.sh
            echo "error: protected QCS components were modified" >&2; exit 1
        fi
        echo "ok (qcs/v1, qcs/src, qcs/scripts, qcs/archive/v2, qcs/build.sh)"
    else
        echo "not a git checkout: protected-path check skipped"
    fi
fi

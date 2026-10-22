#!/bin/bash
# apply-droidspaces.sh - wire the Droidspaces kernel fragment into a crDroid tree.
#
# What it does (idempotent):
#   1. copies kernel/droidspaces-nabu.config into the kernel tree's config dir
#   2. appends it to TARGET_KERNEL_CONFIG in device/xiaomi/nabu/BoardConfig.mk
#   3. prints the resulting TARGET_KERNEL_CONFIG so the change is visible
#
# Usage: apply-droidspaces.sh --tree /path/to/crdroid [--fragment PATH]
#
# Bash compatible with 3.2+. ASCII only.

set -euo pipefail

TREE=""
FRAGMENT="$(cd "$(dirname "$0")/.." && pwd)/kernel/droidspaces-nabu.config"

while [ $# -gt 0 ]; do
    case "$1" in
        --tree)     TREE="$2"; shift 2 ;;
        --fragment) FRAGMENT="$2"; shift 2 ;;
        -h|--help)  sed -n '2,12p' "$0"; exit 0 ;;
        *) echo "unknown arg: $1" >&2; exit 64 ;;
    esac
done

[ -n "$TREE" ] || { echo "ERROR: --tree is required" >&2; exit 64; }
[ -f "$FRAGMENT" ] || { echo "ERROR: fragment not found: $FRAGMENT" >&2; exit 1; }

KDIR="$TREE/kernel/xiaomi/nabu"
BOARD="$TREE/device/xiaomi/nabu/BoardConfig.mk"
DEST_DIR="$KDIR/arch/arm64/configs/vendor/xiaomi"
DEST="$DEST_DIR/droidspaces.config"

[ -d "$KDIR" ] || { echo "ERROR: kernel tree missing: $KDIR" >&2; exit 1; }
[ -f "$BOARD" ] || { echo "ERROR: BoardConfig missing: $BOARD" >&2; exit 1; }

echo "== kernel version =="
awk -F' = ' '/^VERSION = /{v=$2} /^PATCHLEVEL = /{p=$2} /^SUBLEVEL = /{s=$2} END{printf "  %s.%s.%s\n", v, p, s}' "$KDIR/Makefile"

echo "== install fragment =="
mkdir -p "$DEST_DIR"
cp "$FRAGMENT" "$DEST"
echo "  $DEST"

echo "== patch BoardConfig.mk =="
TREE="$TREE" python3 - "$BOARD" <<'PY'
import os, sys

board = sys.argv[1]
src = open(board, encoding="utf-8").read()

if "droidspaces.config" in src:
    print("  already wired, nothing to do")
    sys.exit(0)

anchor = "vendor/xiaomi/nabu.config"
if anchor not in src:
    sys.exit("  ERROR: anchor '%s' not found in BoardConfig.mk" % anchor)

out = []
patched = False
for line in src.splitlines(True):
    if not patched and anchor in line:
        stripped = line.rstrip("\n")
        if stripped.rstrip().endswith("\\"):
            out.append(line)
            indent = line[: len(line) - len(line.lstrip())]
            out.append("%svendor/xiaomi/droidspaces.config\n" % indent)
        else:
            indent = line[: len(line) - len(line.lstrip())]
            out.append("%s%s \\\n" % (indent, anchor))
            out.append("%svendor/xiaomi/droidspaces.config\n" % indent)
        patched = True
    else:
        out.append(line)

if not patched:
    sys.exit("  ERROR: anchor line not rewritten")

open(board, "w", encoding="utf-8").write("".join(out))
print("  added vendor/xiaomi/droidspaces.config to TARGET_KERNEL_CONFIG")
PY

echo "== resulting config list =="
sed -n '/^TARGET_KERNEL_CONFIG/,/^$/p' "$BOARD" | sed 's/^/  /'

if ! grep -q 'droidspaces.config' "$BOARD"; then
    echo "ERROR: patch did not take effect" >&2
    exit 1
fi
echo "== ok =="

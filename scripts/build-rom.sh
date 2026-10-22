#!/bin/bash
# build-rom.sh - sync crDroid and build the nabu ROM.
#
# Designed to run on a persistent self-hosted runner: the tree and ccache live
# outside the workspace, so repeat runs are incremental instead of 2 hours.
#
# Environment:
#   CRDROID_TREE    source tree root            (default: $HOME/crdroid)
#   CRDROID_BRANCH  manifest branch             (default: 17.0)
#   VARIANT         userdebug | user | eng      (default: userdebug)
#   JOBS            ninja parallelism           (default: nproc)
#   CCACHE_DIR      ccache dir                  (default: $HOME/.ccache)
#   MIN_FREE_GB     abort below this much free  (default: 120)
#
# Writes to $GITHUB_OUTPUT when running under Actions: zip, size, sha256.
#
# Bash compatible with 3.2+. ASCII only.

set -euo pipefail

TREE="${CRDROID_TREE:-$HOME/crdroid}"
BRANCH="${CRDROID_BRANCH:-17.0}"
VARIANT="${VARIANT:-userdebug}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 8)}"
export CCACHE_DIR="${CCACHE_DIR:-$HOME/.ccache}"
MIN_FREE_GB="${MIN_FREE_GB:-120}"

log() { printf '\n== %s ==\n' "$1"; }
die() { printf '\nERROR: %s\n' "$1" >&2; exit 1; }

# ---------- guard ----------
log "environment"
printf 'host:    %s\n' "$(uname -srm)"
printf 'cpu:     %s\n' "$JOBS"
printf 'mem:     %s GB\n' "$(awk '/MemTotal/ {printf "%d", $2/1048576}' /proc/meminfo)"
printf 'tree:    %s\n' "$TREE"
printf 'branch:  %s\n' "$BRANCH"
printf 'variant: %s\n' "$VARIANT"

mkdir -p "$TREE"
FREE_GB=$(df -Pk "$TREE" | awk 'NR==2 {printf "%d", $4/1024/1024}')
printf 'free:    %s GB\n' "$FREE_GB"
if [ "$FREE_GB" -lt "$MIN_FREE_GB" ]; then
    die "only ${FREE_GB} GB free under $TREE, need at least ${MIN_FREE_GB} GB.
GitHub-hosted runners have 14 GB - they cannot build AOSP.
Use a self-hosted runner with >= 400 GB (see README)."
fi

command -v repo >/dev/null 2>&1 || die "repo not found - run scripts/setup-host.sh first"

# ---------- sync ----------
cd "$TREE"
if [ ! -d .repo ]; then
    log "repo init -b $BRANCH"
    repo init -u https://github.com/crdroidandroid/android.git \
        -b "$BRANCH" --git-lfs --no-clone-bundle
else
    log "tree exists, incremental sync"
fi

sync_with_retry() {
    n=1
    while [ "$n" -le 3 ]; do
        log "repo sync (attempt $n/3)"
        if repo sync -c -j"$JOBS" --no-clone-bundle; then
            return 0
        fi
        echo "sync failed, retrying with --force-sync"
        repo sync -c -j"$JOBS" --force-sync --no-tags --no-clone-bundle && return 0
        n=$((n + 1))
        sleep 20
    done
    return 1
}
sync_with_retry || die "repo sync failed after 3 attempts"

[ -f device/xiaomi/nabu/BoardConfig.mk ] || die "device/xiaomi/nabu missing.
roomservice pulls it during breakfast; try:
  . build/envsetup.sh && breakfast nabu"
[ -f kernel/xiaomi/nabu/Makefile ] || die "kernel/xiaomi/nabu missing"
[ -d vendor/xiaomi/nabu ] || die "vendor/xiaomi/nabu missing (gitlab blobs)"

log "device tree versions"
for p in device/xiaomi/nabu kernel/xiaomi/nabu hardware/xiaomi vendor/xiaomi/nabu; do
    [ -d "$p/.git" ] || [ -f "$p/.git" ] || continue
    printf '  %-22s %-8s %s\n' "$p" \
        "$(git -C "$p" rev-parse --abbrev-ref HEAD 2>/dev/null)" \
        "$(git -C "$p" rev-parse --short HEAD 2>/dev/null)"
done
printf '  kernel version: %s\n' \
    "$(awk -F' = ' '/^VERSION = /{v=$2} /^PATCHLEVEL = /{p=$2} /^SUBLEVEL = /{s=$2} END{print v"."p"."s}' kernel/xiaomi/nabu/Makefile)"

# ---------- build ----------
export USE_CCACHE=1
export CCACHE_EXEC="$(command -v ccache)"
mkdir -p "$CCACHE_DIR"
ccache -M "${CCACHE_SIZE:-20G}" >/dev/null 2>&1 || true
printf '\nccache dir: %s\n' "$CCACHE_DIR"
ccache -s | head -4 || true

log "brunch nabu $VARIANT (jobs=$JOBS)"
# shellcheck disable=SC1091
. build/envsetup.sh >/dev/null
export MAKEFLAGS="-j$JOBS"
set +e
brunch nabu "$VARIANT" 2>&1 | tee "$TREE/brunch.log"
RC=${PIPESTATUS[0]}
set -e

if [ "$RC" -ne 0 ]; then
    printf '\nlast errors:\n'
    grep -nE 'error:|FAILED:|ninja: build stopped|No space left' "$TREE/brunch.log" | tail -25 || true
    die "build failed (rc=$RC)"
fi

# ---------- collect ----------
ZIP=$(ls -t out/target/product/nabu/crDroidAndroid-*.zip 2>/dev/null | head -1)
[ -n "$ZIP" ] || die "build succeeded but no zip under out/target/product/nabu/"

SIZE=$(wc -c < "$ZIP" | tr -d ' ')
SHA=$(sha256sum "$ZIP" | awk '{print $1}')

log "result"
printf 'zip:    %s\n' "$ZIP"
printf 'size:   %s bytes (%s MiB)\n' "$SIZE" "$((SIZE / 1048576))"
printf 'sha256: %s\n' "$SHA"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
    {
        echo "zip=$ZIP"
        echo "size=$SIZE"
        echo "sha256=$SHA"
        echo "name=$(basename "$ZIP")"
    } >> "$GITHUB_OUTPUT"
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
        echo "### crDroid nabu build"
        echo
        echo "| item | value |"
        echo "|---|---|"
        echo "| branch | $BRANCH |"
        echo "| variant | $VARIANT |"
        echo "| file | \`$(basename "$ZIP")\` |"
        echo "| size | $((SIZE / 1048576)) MiB |"
        echo "| sha256 | \`$SHA\` |"
    } >> "$GITHUB_STEP_SUMMARY"
fi

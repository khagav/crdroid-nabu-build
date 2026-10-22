#!/bin/bash
# setup-host.sh - install everything needed to build crDroid (Android 17) for nabu.
#
# Idempotent: safe to run on every job. Targets Ubuntu 22.04 / 24.04.
# Requires passwordless sudo (true on GitHub runners, configure it on your own box).
#
# Usage: setup-host.sh
#
# Bash compatible with 3.2+. ASCII only.

set -euo pipefail

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi
fi

log() { printf '\n== %s ==\n' "$1"; }

log "apt: base packages"
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get update -qq

BASE_PKGS="bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs \
gnupg gperf imagemagick lib32ncurses-dev lib32readline-dev lib32z1-dev liblz4-tool \
libncurses-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync \
schedtool squashfs-tools xsltproc zip zlib1g-dev unzip python3 openjdk-21-jdk-headless"

# shellcheck disable=SC2086
$SUDO apt-get install -y -qq $BASE_PKGS

# libwxgtk: package name moved between 22.04 and 24.04; try both, do not fail the job.
if ! $SUDO apt-get install -y -qq libwxgtk3.2-dev 2>/dev/null; then
    $SUDO apt-get install -y -qq libwxgtk3.0-gtk3-dev 2>/dev/null || \
        echo "WARN: no libwxgtk dev package found (only needed by some host tools)"
fi

log "repo launcher"
mkdir -p "$HOME/bin"
if ! command -v repo >/dev/null 2>&1; then
    curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$HOME/bin/repo"
    chmod a+x "$HOME/bin/repo"
fi
export PATH="$HOME/bin:$PATH"
grep -q 'HOME/bin' "$HOME/.bashrc" 2>/dev/null || \
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
repo version | head -1

log "gh cli (used to publish release assets)"
if ! command -v gh >/dev/null 2>&1; then
    $SUDO apt-get install -y -qq gh 2>/dev/null || {
        GH_VER="2.63.2"
        TMP="$(mktemp -d)"
        if curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VER}/gh_${GH_VER}_linux_amd64.tar.gz" \
            | tar -xz -C "$TMP" 2>/dev/null; then
            $SUDO install -m 755 "$TMP/gh_${GH_VER}_linux_amd64/bin/gh" /usr/local/bin/gh
        else
            echo "WARN: gh not installed; release upload will use curl fallback"
        fi
        rm -rf "$TMP"
    }
fi
command -v gh >/dev/null 2>&1 && gh --version | head -1 || true

log "ccache"
ccache -M "${CCACHE_SIZE:-20G}" >/dev/null 2>&1 || true
ccache -s | head -6 || true

log "toolchain sanity"
printf 'gcc:    %s\n' "$(gcc --version | head -1)"
printf 'python: %s\n' "$(python3 --version)"
printf 'make:   %s\n' "$(make --version | head -1)"
printf 'java:   %s\n' "$(java -version 2>&1 | head -1)"

log "done"

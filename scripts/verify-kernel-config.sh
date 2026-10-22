#!/bin/bash
# verify-kernel-config.sh - prove the built kernel actually has what Droidspaces
# needs. Reads the .config that came out of the build, not the fragment.
#
# Usage: verify-kernel-config.sh --tree /path/to/crdroid [--config PATH]
#
# Exit: 0 = every required option is set, 1 = something required is missing,
#       2 = .config not found
#
# Bash compatible with 3.2+. ASCII only.

set -uo pipefail

TREE=""
CFG=""

while [ $# -gt 0 ]; do
    case "$1" in
        --tree)   TREE="$2"; shift 2 ;;
        --config) CFG="$2"; shift 2 ;;
        -h|--help) sed -n '2,11p' "$0"; exit 0 ;;
        *) echo "unknown arg: $1" >&2; exit 64 ;;
    esac
done

if [ -z "$CFG" ]; then
    [ -n "$TREE" ] || { echo "ERROR: give --tree or --config" >&2; exit 64; }
    for cand in \
        "$TREE/out/target/product/nabu/obj/KERNEL_OBJ/.config" \
        "$TREE/out/target/product/nabu/obj/KERNEL_OBJ/../../KERNEL_OBJ/.config"
    do
        [ -f "$cand" ] && CFG="$cand" && break
    done
    if [ -z "$CFG" ]; then
        CFG="$(find "$TREE/out" -name .config -path '*KERNEL_OBJ*' 2>/dev/null | head -1)"
    fi
fi

if [ -z "$CFG" ] || [ ! -f "$CFG" ]; then
    echo "no kernel .config found - build the kernel first" >&2
    exit 2
fi

echo "config: $CFG"
echo "kernel: $(awk -F' = ' '/^VERSION = /{v=$2} /^PATCHLEVEL = /{p=$2} /^SUBLEVEL = /{s=$2} END{print v"."p"."s}' \
    "$(dirname "$CFG")/../../../Makefile" 2>/dev/null || echo unknown)"
echo

REQUIRED="NAMESPACES PID_NS UTS_NS IPC_NS NET_NS SECCOMP CGROUPS MEMCG DEVTMPFS OVERLAY_FS SYSVIPC"
RECOMMENDED="SECCOMP_FILTER CGROUP_DEVICE CGROUP_PIDS CFS_BANDWIDTH POSIX_MQUEUE USER_NS VETH BRIDGE BRIDGE_NETFILTER NF_NAT NF_TABLES NETFILTER_XT_TARGET_MASQUERADE MACVLAN TMPFS_XATTR"

is_set() {
    grep -qE "^CONFIG_$1=y" "$CFG"
}

MISS_REQ=0
MISS_REC=0
ROWS=""

echo "--- required ---"
for o in $REQUIRED; do
    if is_set "$o"; then
        printf '  [ OK ] CONFIG_%s=y\n' "$o"
        ROWS="${ROWS}| \`CONFIG_${o}\` | required | OK |\n"
    else
        printf '  [MISS] CONFIG_%s\n' "$o"
        ROWS="${ROWS}| \`CONFIG_${o}\` | required | **missing** |\n"
        MISS_REQ=$((MISS_REQ + 1))
    fi
done

echo "--- recommended ---"
for o in $RECOMMENDED; do
    if is_set "$o"; then
        printf '  [ OK ] CONFIG_%s=y\n' "$o"
        ROWS="${ROWS}| \`CONFIG_${o}\` | recommended | OK |\n"
    else
        printf '  [warn] CONFIG_%s not set\n' "$o"
        ROWS="${ROWS}| \`CONFIG_${o}\` | recommended | not set |\n"
        MISS_REC=$((MISS_REC + 1))
    fi
done

echo
if grep -qE '^CONFIG_ANDROID_PARANOID_NETWORK=y' "$CFG"; then
    echo "  [warn] CONFIG_ANDROID_PARANOID_NETWORK=y - containers may have no internet"
    echo "         (needs the container gid in AID_INET, or rebuild with it off)"
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
        echo "### Droidspaces kernel check"
        echo
        echo "$MISS_REQ required missing, $MISS_REC recommended missing"
        echo
        echo "| option | class | state |"
        echo "|---|---|---|"
        printf '%b' "$ROWS"
    } >> "$GITHUB_STEP_SUMMARY"
fi

echo
if [ "$MISS_REQ" -gt 0 ]; then
    echo "RESULT: $MISS_REQ required option(s) missing - Droidspaces will not run"
    exit 1
fi
echo "RESULT: all required options present ($MISS_REC recommended missing)"
exit 0

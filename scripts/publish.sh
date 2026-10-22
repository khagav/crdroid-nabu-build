#!/bin/bash
# publish.sh - attach a file to a GitHub Release, creating the release if needed.
#
# Works with gh when available, otherwise falls back to the REST API via curl.
# Needed because a crDroid zip is ~1.4 GB and Actions *artifact* storage on the
# Free plan is only 500 MB - release assets (2 GB/file) are the right place.
#
# Usage: publish.sh --file PATH --tag TAG --title TITLE [--notes TEXT]
#
# Requires: GH_TOKEN, GH_REPO (owner/name)
#
# Bash compatible with 3.2+. ASCII only.

set -euo pipefail

FILE=""; TAG=""; TITLE=""; NOTES=""
while [ $# -gt 0 ]; do
    case "$1" in
        --file)  FILE="$2"; shift 2 ;;
        --tag)   TAG="$2"; shift 2 ;;
        --title) TITLE="$2"; shift 2 ;;
        --notes) NOTES="$2"; shift 2 ;;
        -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
        *) echo "unknown arg: $1" >&2; exit 64 ;;
    esac
done

: "${GH_TOKEN:?GH_TOKEN is required}"
: "${GH_REPO:?GH_REPO is required (owner/name)}"
[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "ERROR: --file not found: $FILE" >&2; exit 1; }
[ -n "$TAG" ] || { echo "ERROR: --tag is required" >&2; exit 1; }
[ -n "$TITLE" ] || TITLE="$TAG"

NAME="$(basename "$FILE")"
SIZE=$(wc -c < "$FILE" | tr -d ' ')
echo "publishing $NAME ($((SIZE / 1048576)) MiB) -> release $TAG of $GH_REPO"

if command -v gh >/dev/null 2>&1; then
    echo "using gh"
    if ! gh release view "$TAG" >/dev/null 2>&1; then
        gh release create "$TAG" --title "$TITLE" --notes "${NOTES:-Automated build.}"
    fi
    gh release upload "$TAG" "$FILE" --clobber
else
    echo "gh not found, using REST API"
    API="https://api.github.com/repos/$GH_REPO/releases"
    REL_ID=$(curl -fsSL -H "Authorization: Bearer $GH_TOKEN" "$API/tags/$TAG" 2>/dev/null \
        | python3 -c 'import sys,json;print(json.load(sys.stdin).get("id",""))' 2>/dev/null || true)

    if [ -z "${REL_ID:-}" ]; then
        REL_ID=$(python3 - "$TAG" "$TITLE" "$NOTES" <<'PY' | curl -fsSL -X POST \
            -H "Authorization: Bearer $GH_TOKEN" \
            -H "Accept: application/vnd.github+json" \
            --data-binary @- "$API" \
            | python3 -c 'import sys,json;print(json.load(sys.stdin)["id"])'
import json, os, sys
tag, title, notes = sys.argv[1], sys.argv[2], sys.argv[3]
print(json.dumps({"tag_name": tag, "name": title, "body": notes or "Automated build."}))
PY
        )
    fi

    echo "release id: $REL_ID"
    curl -fsSL -X POST \
        -H "Authorization: Bearer $GH_TOKEN" \
        -H "Content-Type: application/octet-stream" \
        --data-binary @"$FILE" \
        "https://uploads.github.com/repos/$GH_REPO/releases/$REL_ID/assets?name=$NAME" \
        > /dev/null
fi

echo "done: https://github.com/$GH_REPO/releases/tag/$TAG"

#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

IMAGE=${IMAGE:-ghcr.io/pasturestack/node-agent-base:v0.3.5}

SHARE_MNT_BIN="${SHARE_MNT_BIN:-}"
if [ -z "$SHARE_MNT_BIN" ] || [ ! -f "$SHARE_MNT_BIN" ]; then
    echo "Set SHARE_MNT_BIN to the reviewed mount-propagation binary path before building $IMAGE" >&2
    exit 1
fi

R_BIN="${R_BIN:-}"
if [ -z "$R_BIN" ] || [ ! -f "$R_BIN" ]; then
    echo "Set R_BIN to a reviewed local copy of the legacy network helper before building $IMAGE" >&2
    exit 1
fi

tmpdir=$(mktemp -d)
cleanup() {
    rm -rf "$tmpdir"
}
trap cleanup EXIT

cp Dockerfile pasturestack-entrypoint.sh "$tmpdir"/
cp "$SHARE_MNT_BIN" "$tmpdir/share-mnt"
cp "$R_BIN" "$tmpdir/r"
cp ../server/bin/update-platform-ssl "$tmpdir/update-platform-ssl"

echo "Building $IMAGE"
docker build -t "$IMAGE" "$tmpdir"
echo "Built $IMAGE"

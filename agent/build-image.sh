#!/bin/bash
set -euo pipefail

cd $(dirname $0)

if [ -z "${IMAGE:-}" ]; then
    IMAGE=$(awk -F= '/^ENV RANCHER_AGENT_IMAGE=/ { print $2; exit }' Dockerfile)
fi

tmpdir=$(mktemp -d)
cleanup() {
    rm -rf "$tmpdir"
}
trap cleanup EXIT

cp Dockerfile register.py resolve_url.py run.sh loglevel "$tmpdir"/

echo Building $IMAGE
docker build -t "${IMAGE}" "$tmpdir"

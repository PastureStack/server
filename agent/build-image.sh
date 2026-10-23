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

cp Dockerfile control_plane_url.py register.py resolve_url.py run.sh loglevel "$tmpdir"/

echo Building $IMAGE
docker build --build-arg "VCS_REF=$(git rev-parse HEAD)" -t "${IMAGE}" "$tmpdir"

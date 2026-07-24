#!/usr/bin/env bash
set -euo pipefail

server_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "${server_dir}/.." && pwd)
cd "$repo_root"

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Refusing to build a release image from tracked, uncommitted changes" >&2
    exit 1
fi

revision=${PASTURESTACK_SERVER_REVISION:-$(git rev-parse HEAD)}
if [[ ! "$revision" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Invalid PastureStack Server revision: ${revision}" >&2
    exit 1
fi

image=${IMAGE:-pasturestack-validation/server:v1.6.276}

docker buildx build \
    --provenance=false \
    --load \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --tag "$image" \
    --file server/Dockerfile.runtime-hotfix \
    server

test "$(docker image inspect "$image" --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = v1.6.276
test "$(docker image inspect "$image" --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = "$revision"

printf 'SERVER_RUNTIME_HOTFIX_IMAGE_OK image=%s revision=%s\n' "$image" "$revision"

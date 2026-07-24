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

: "${PASTURESTACK_ARTIFACT_BASE_URL:=https://github.com/PastureStack/server/releases/download/v1.6.277}"
export PASTURESTACK_ARTIFACT_BASE_URL

source_date_epoch=${SOURCE_DATE_EPOCH:-$(git show -s --format=%ct "$revision")}
if [[ ! "$source_date_epoch" =~ ^[0-9]+$ ]]; then
    echo "Invalid SOURCE_DATE_EPOCH: ${source_date_epoch}" >&2
    exit 1
fi
export SOURCE_DATE_EPOCH="$source_date_epoch"

image=${IMAGE:-pasturestack-validation/server:v1.6.277}

docker buildx build \
    --provenance=false \
    --load \
    --network=host \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}" \
    --secret id=rc16_artifact_base_url,env=PASTURESTACK_ARTIFACT_BASE_URL \
    --tag "$image" \
    --file server/Dockerfile.runtime-hotfix \
    server

test "$(docker image inspect "$image" --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = v1.6.277
test "$(docker image inspect "$image" --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = "$revision"

printf 'SERVER_RUNTIME_HOTFIX_IMAGE_OK image=%s revision=%s source_date_epoch=%s\n' \
    "$image" "$revision" "$source_date_epoch"

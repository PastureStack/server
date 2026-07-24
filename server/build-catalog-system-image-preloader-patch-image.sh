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

source_date_epoch=${SOURCE_DATE_EPOCH:-$(git show -s --format=%ct "$revision")}
if [[ ! "$source_date_epoch" =~ ^[0-9]+$ ]]; then
    echo "Invalid SOURCE_DATE_EPOCH: ${source_date_epoch}" >&2
    exit 1
fi
export SOURCE_DATE_EPOCH="$source_date_epoch"

image=${IMAGE:-pasturestack-validation/server:v1.6.282}

docker buildx build \
    --provenance=false \
    --load \
    --network=host \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --tag "$image" \
    --file server/Dockerfile.catalog-system-image-preloader-patch \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.282
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.281
test "$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}' |
    grep -Fxc \
        'PASTURESTACK_CATALOG_COMMIT=3cfb447d7564cf9bada4bac2e15ce3dd6b221615')" = 1
test "$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}' |
    grep -Fxc \
        'PASTURESTACK_WEB_CONSOLE_COMMIT=2dd5e5b0154ddbb8e41ef2887fa786b93e74827b')" = 1

printf 'SERVER_CATALOG_SYSTEM_IMAGE_PRELOADER_PATCH_IMAGE_OK image=%s revision=%s source_date_epoch=%s\n' \
    "$image" "$revision" "$source_date_epoch"

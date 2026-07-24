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

image=${IMAGE:-pasturestack-validation/server:v1.6.279}

docker buildx build \
    --provenance=false \
    --load \
    --network=host \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}" \
    --tag "$image" \
    --file server/Dockerfile.catalog-ui-patch \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.279
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}' |
    grep -Fxc \
        'PASTURESTACK_CATALOG_COMMIT=f28c1d4d03b19cd7d8cd273573f8eb2a8da0ddda')" = 1
test "$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}' |
    grep -Fxc \
        'PASTURESTACK_WEB_CONSOLE_COMMIT=2dd5e5b0154ddbb8e41ef2887fa786b93e74827b')" = 1

printf 'SERVER_CATALOG_UI_PATCH_IMAGE_OK image=%s revision=%s source_date_epoch=%s\n' \
    "$image" "$revision" "$source_date_epoch"

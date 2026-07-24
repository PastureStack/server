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

image=${IMAGE:-pasturestack-validation/server:v1.6.289}
catalog_commit=3de2103927bbd7c61604428bb951af90288c20ce
catalog_json="{\"catalogs\":{\"pasturestack\":{\"url\":\"https://github.com/PastureStack/catalog-templates.git\",\"branch\":\"main\",\"pinnedCommit\":\"${catalog_commit}\"}}}"

docker buildx build \
    --provenance=false \
    --load \
    --network=host \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --tag "$image" \
    --file server/Dockerfile.catalog-secret-volume-patch \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.289
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.288
image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
test "$(grep -Fxc "CATTLE_RANCHER_SERVER_VERSION=v1.6.289" \
    <<<"$image_environment")" = 1
test "$(grep -Fxc "PASTURESTACK_CATALOG_COMMIT=${catalog_commit}" \
    <<<"$image_environment")" = 1
test "$(grep -Fxc "DEFAULT_CATTLE_CATALOG_URL=${catalog_json}" \
    <<<"$image_environment")" = 1
test "$(grep -Fxc "CATTLE_CATALOG_URL=${catalog_json}" \
    <<<"$image_environment")" = 1
docker run --rm --entrypoint bash "$image" \
    -n /usr/bin/catalog-service
docker run --rm --entrypoint test "$image" \
    -x /usr/local/lib/pasturestack/service-wrapper

printf 'SERVER_CATALOG_SECRET_VOLUME_PATCH_IMAGE_OK image=%s revision=%s catalog_commit=%s source_date_epoch=%s\n' \
    "$image" "$revision" "$catalog_commit" "$source_date_epoch"

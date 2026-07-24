#!/usr/bin/env bash
set -euo pipefail

server_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "${server_dir}/.." && pwd)
cd "$repo_root"

if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
    echo "Refusing to build a release image from an uncommitted worktree" >&2
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

image=${IMAGE:-pasturestack-validation/server:v1.6.297}
catalog_commit=a44fbf3649165347a4b780159bf5daa92812a53a
web_console_commit=840da39d9d6f3ca35a56c7574ebcb49783d7c3e6
web_console_sha256=e92d0252f38b157767d2e293bed9577c410a9cd5de67cb28b6d98848dd086d53
catalog_json="{\"catalogs\":{\"pasturestack\":{\"url\":\"https://github.com/PastureStack/catalog-templates.git\",\"branch\":\"main\",\"pinnedCommit\":\"${catalog_commit}\"}}}"

docker buildx build \
    --provenance=false \
    --load \
    --network=host \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --tag "$image" \
    --file server/Dockerfile.catalog-card-brand-patch \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.297
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.296
image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
test "$(grep -Fxc "CATTLE_RANCHER_SERVER_VERSION=v1.6.297" \
    <<<"$image_environment")" = 1
test "$(grep -Fxc "PASTURESTACK_CATALOG_COMMIT=${catalog_commit}" \
    <<<"$image_environment")" = 1
test "$(grep -Fxc "PASTURESTACK_WEB_CONSOLE_COMMIT=${web_console_commit}" \
    <<<"$image_environment")" = 1
test "$(grep -Fxc \
    'PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.10' \
    <<<"$image_environment")" = 1
test "$(grep -Fxc \
    "PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256=${web_console_sha256}" \
    <<<"$image_environment")" = 1
test "$(grep -Fxc "DEFAULT_CATTLE_CATALOG_URL=${catalog_json}" \
    <<<"$image_environment")" = 1
test "$(grep -Fxc "CATTLE_CATALOG_URL=${catalog_json}" \
    <<<"$image_environment")" = 1

docker run --rm --entrypoint bash "$image" -lc '
    set -euo pipefail
    test -f /usr/share/cattle/war/translations/zh-tw.json
    test "$(find /usr/share/cattle/war/assets \
        -maxdepth 1 -type f -name "ui-*.js" | wc -l)" -eq 1
    ui_entry=$(find /usr/share/cattle/war/assets \
        -maxdepth 1 -type f -name "ui-*.js" -print -quit)
    grep -F "catalogDisplayName" "$ui_entry" >/dev/null
    grep -F "catalogBrandBadge" "$ui_entry" >/dev/null
    grep -F "1.6.56-pasturestack.10" \
        /usr/share/cattle/war/index.html >/dev/null
    grep -F "\"upstreamFirstParty\":\"PastureStack\"" \
        /usr/share/cattle/war/translations/zh-tw.json >/dev/null
    grep -F "\"upstreamFirstParty\":\"上游第一方範本\"" \
        /usr/share/cattle/war/translations/zh-tw.json >/dev/null
    grep -F "\"childSidekicks\":\"相關容器\"" \
        /usr/share/cattle/war/translations/zh-tw.json >/dev/null
'

printf 'SERVER_CATALOG_CARD_BRAND_PATCH_IMAGE_OK image=%s revision=%s catalog_commit=%s web_console_commit=%s source_date_epoch=%s\n' \
    "$image" "$revision" "$catalog_commit" "$web_console_commit" "$source_date_epoch"

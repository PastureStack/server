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

image=${IMAGE:-pasturestack-validation/server:v1.6.293}
catalog_commit=30caa02cfef52e26dc65cfceba5c36b3150283f2
orchestration_commit=e9fe2a2c1d328f547a4d5bb34f370515e5e5e572
web_console_commit=bce877cc526774dbbd11c4856aac43275868ed10
catalog_json="{\"catalogs\":{\"pasturestack\":{\"url\":\"https://github.com/PastureStack/catalog-templates.git\",\"branch\":\"main\",\"pinnedCommit\":\"${catalog_commit}\"}}}"

docker buildx build \
    --provenance=false \
    --load \
    --network=host \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --tag "$image" \
    --file server/Dockerfile.catalog-completion-patch \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.293
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.292
image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
test "$(grep -Fxc "CATTLE_RANCHER_SERVER_VERSION=v1.6.293" \
    <<<"$image_environment")" = 1
test "$(grep -Fxc "PASTURESTACK_CATALOG_COMMIT=${catalog_commit}" \
    <<<"$image_environment")" = 1
test "$(grep -Fxc "PASTURESTACK_ORCHESTRATION_COMMIT=${orchestration_commit}" \
    <<<"$image_environment")" = 1
test "$(grep -Fxc "PASTURESTACK_WEB_CONSOLE_COMMIT=${web_console_commit}" \
    <<<"$image_environment")" = 1
test "$(grep -Fxc \
    'PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.7' \
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
    grep -F "io.pasturestack.catalog." "$ui_entry" >/dev/null
    grep -F "question." "$ui_entry" >/dev/null
    grep -F "readme." "$ui_entry" >/dev/null
    grep -F "max-height:145px" \
        /usr/share/cattle/war/assets/ui-light.css >/dev/null
    grep -F "1.6.56-pasturestack.7" \
        /usr/share/cattle/war/index.html >/dev/null
    api_jar=$(find /usr/share/cattle/war/WEB-INF/lib \
        -maxdepth 1 -type f \
        -name "cattle-framework-api-[0-9]*.jar" -print -quit)
    test -n "$api_jar"
    javap -classpath "$api_jar" -verbose \
        io.cattle.platform.api.servlet.IndexFile \
        | grep -F "no-store, no-cache, must-revalidate, max-age=0" >/dev/null
'

printf 'SERVER_CATALOG_COMPLETION_PATCH_IMAGE_OK image=%s revision=%s catalog_commit=%s orchestration_commit=%s web_console_commit=%s source_date_epoch=%s\n' \
    "$image" "$revision" "$catalog_commit" "$orchestration_commit" "$web_console_commit" "$source_date_epoch"

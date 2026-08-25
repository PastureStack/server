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

image=${IMAGE:-pasturestack-validation/server:v1.6.305}
supported_docker_range='~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || v29.4.1 || v29.7.2'

docker buildx build \
    --provenance=false \
    --load \
    --network=host \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}" \
    --tag "$image" \
    --file server/Dockerfile.docker-host-support-patch \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.305
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.304

image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
for marker in \
    CATTLE_RANCHER_SERVER_VERSION=v1.6.305 \
    PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27 \
    PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.16 \
    PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1; do
    test "$(grep -Fxc "$marker" <<<"$image_environment")" = 1
done

docker run --rm \
  --entrypoint bash \
  --env "EXPECTED_SUPPORTED_DOCKER_RANGE=${supported_docker_range}" \
  "$image" -lc '
    set -euo pipefail
    app_config_jar=$(find /usr/share/cattle/war/WEB-INF/lib \
      -maxdepth 1 -type f -name "cattle-app-config-*.jar" -print -quit)
    test -n "${app_config_jar}"
    unzip -p "${app_config_jar}" \
      META-INF/cattle/api-server/defaults.properties \
      | grep -Fx "supported.docker.range=${EXPECTED_SUPPORTED_DOCKER_RANGE}"
    unzip -p "${app_config_jar}" \
      META-INF/cattle/api-server/defaults.properties \
      | grep -Fx "newest.docker.version=v29.7.2"
    test -x /usr/bin/pasturestack-console-broker
    test -f /usr/share/cattle/war/translations/zh-tw.json
    grep -F "table-column-scroll-host-overflowing" \
      /usr/share/cattle/war/assets/ui-light.css >/dev/null
'

printf 'SERVER_DOCKER_HOST_SUPPORT_PATCH_IMAGE_OK image=%s revision=%s newest=29.7.2 exact_modern_versions=24.0.9,29.4.1,29.7.2\n' \
    "$image" "$revision"

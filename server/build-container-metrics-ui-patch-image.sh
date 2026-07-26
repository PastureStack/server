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

web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-v1.6.56-pasturestack.17}
web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.56-pasturestack.17.tar.gz}
web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:?WEB_CONSOLE_ARTIFACT_SHA256 is required}
web_console_commit=${WEB_CONSOLE_COMMIT:?WEB_CONSOLE_COMMIT is required}
image=${IMAGE:-pasturestack-validation/server:v1.6.306}

docker buildx build \
    --provenance=false \
    --load \
    --network=host \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --build-arg "WEB_CONSOLE_RELEASE_TAG=${web_console_release_tag}" \
    --build-arg "WEB_CONSOLE_ARTIFACT=${web_console_artifact}" \
    --build-arg "WEB_CONSOLE_ARTIFACT_SHA256=${web_console_artifact_sha256}" \
    --build-arg "WEB_CONSOLE_COMMIT=${web_console_commit}" \
    --tag "$image" \
    --file server/Dockerfile.container-metrics-ui-patch \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.306
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.305

image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
for marker in \
    CATTLE_RANCHER_SERVER_VERSION=v1.6.306 \
    PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27 \
    PASTURESTACK_WEB_CONSOLE_COMMIT="${web_console_commit}" \
    PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.17 \
    PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256="${web_console_artifact_sha256}" \
    PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1; do
    test "$(grep -Fxc "$marker" <<<"$image_environment")" = 1
done

docker run --rm --entrypoint bash "$image" -lc '
    set -euo pipefail
    ui_entry=$(find /usr/share/cattle/war/assets \
      -maxdepth 1 -type f -name "ui-*.js" -print -quit)
    test -n "${ui_entry}"
    test "$(find /usr/share/cattle/war/assets \
      -maxdepth 1 -type f -name "ui-*.js" | wc -l)" -eq 1
    test "$(find /usr/share/cattle/war/assets \
      -maxdepth 1 -type f -name "vendor-*.js" | wc -l)" -eq 1
    for marker in \
      statsTableCount \
      statsSortRevision \
      setVisibleStatsInstances \
      cpuRms \
      memoryRms \
      networkRms \
      storageRms; do
      grep -F "${marker}" "${ui_entry}" >/dev/null
    done
    grep -F ".sortable-table-page-size" \
      /usr/share/cattle/war/assets/ui-light.css >/dev/null
    grep -F ".console-workspace-dock-item:focus-visible" \
      /usr/share/cattle/war/assets/ui-light.css >/dev/null
    grep -F ".console-workspace-dock-item.active{color:#fff;background:rgba(255,255,255,.1);border-color:rgba(255,255,255,.32);box-shadow:none;transform:none}" \
      /usr/share/cattle/war/assets/ui-light.css >/dev/null
    grep -F "\"cpuRms\":\"CPU（均方根）\"" \
      /usr/share/cattle/war/translations/zh-tw.json >/dev/null
    grep -F "\"memoryRms\":\"記憶體（均方根）\"" \
      /usr/share/cattle/war/translations/zh-tw.json >/dev/null
    grep -F "\"networkRms\":\"網路（均方根）\"" \
      /usr/share/cattle/war/translations/zh-tw.json >/dev/null
    grep -F "\"storageRms\":\"儲存（均方根）\"" \
      /usr/share/cattle/war/translations/zh-tw.json >/dev/null
    grep -F "\"rowsPerPage\":\"每頁顯示\"" \
      /usr/share/cattle/war/translations/zh-tw.json >/dev/null
    app_config_jar=$(find /usr/share/cattle/war/WEB-INF/lib \
      -maxdepth 1 -type f -name "cattle-app-config-*.jar" -print -quit)
    test -n "${app_config_jar}"
    unzip -p "${app_config_jar}" \
      META-INF/cattle/api-server/defaults.properties \
      | grep -Fx "newest.docker.version=v29.6.2"
'

printf 'SERVER_CONTAINER_METRICS_UI_PATCH_IMAGE_OK image=%s revision=%s web_console_commit=%s\n' \
    "$image" "$revision" "$web_console_commit"

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

web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-v1.6.56-pasturestack.21}
web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.56-pasturestack.21.tar.gz}
web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:?WEB_CONSOLE_ARTIFACT_SHA256 is required}
web_console_commit=${WEB_CONSOLE_COMMIT:?WEB_CONSOLE_COMMIT is required}
image=${IMAGE:-pasturestack-validation/server:v1.6.310}

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
    --file server/Dockerfile.storage-bulk-remove-ui-patch \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.310
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.309

image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
for marker in \
    CATTLE_RANCHER_SERVER_VERSION=v1.6.310 \
    PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27 \
    PASTURESTACK_WEB_CONSOLE_COMMIT="${web_console_commit}" \
    PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.21 \
    PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256="${web_console_artifact_sha256}" \
    PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1; do
    test "$(grep -Fxc "$marker" <<<"$image_environment")" = 1
done

docker run --rm --entrypoint bash "$image" -lc '
    set -euo pipefail
    ui_entry=$(find /usr/share/cattle/war/assets \
      -maxdepth 1 -type f -name "ui-*.js" -print -quit)
    vendor_entry=$(find /usr/share/cattle/war/assets \
      -maxdepth 1 -type f -name "vendor-*.js" -print -quit)
    test -n "${ui_entry}"
    test -n "${vendor_entry}"
    test "$(find /usr/share/cattle/war/assets \
      -maxdepth 1 -type f -name "ui-*.js" | wc -l)" -eq 1
    test "$(find /usr/share/cattle/war/assets \
      -maxdepth 1 -type f -name "vendor-*.js" | wc -l)" -eq 1
    for marker in \
      statsTableCount \
      statsSortRevision \
      setVisibleStatsInstances \
      HOST_CONTAINER_COLUMNS \
      columnSelector \
      showImageColumn \
      showCommandColumn \
      cpuRms \
      memoryRms \
      networkRms \
      storageRms \
      storageTableCount \
      confirm-remove-selected-volumes \
      filterVolumesByState \
      isBulkRemovableVolume \
      runWithConcurrency; do
      grep -F "${marker}" "${ui_entry}" >/dev/null
    done
    grep -F "hostContainerColumnsV2" "${ui_entry}" >/dev/null
    grep -F "serviceContainerColumnsV2" "${ui_entry}" >/dev/null
    test "$(grep -Fo "translationKey:\"containersPage.table.image\",columnRole:\"image\",defaultHidden:!0" "${ui_entry}" | wc -l)" -eq 2
    test "$(grep -Fo "translationKey:\"containersPage.table.command\",columnRole:\"command\",defaultHidden:!0" "${ui_entry}" | wc -l)" -eq 2
    grep -F "createTextNode(\" / \")" "${ui_entry}" >/dev/null
    column_selector_offset=$(grep -Fbo "sortable-table-column-selector" "${vendor_entry}" | head -n 1 | cut -d: -f1)
    page_size_offset=$(grep -Fbo "sortable-table-page-size" "${vendor_entry}" | head -n 1 | cut -d: -f1)
    search_offset=$(grep -Fbo "sortable-table-search" "${vendor_entry}" | head -n 1 | cut -d: -f1)
    test "${column_selector_offset}" -lt "${page_size_offset}"
    test "${page_size_offset}" -lt "${search_offset}"
    grep -F ".sortable-table-filter-controls" \
      /usr/share/cattle/war/assets/ui-light.css >/dev/null
    grep -F ".sortable-table-page-size" \
      /usr/share/cattle/war/assets/ui-light.css >/dev/null
    grep -F ".sortable-table-column-selector" \
      /usr/share/cattle/war/assets/ui-light.css >/dev/null
    grep -F ".console-workspace-dock-item:focus-visible" \
      /usr/share/cattle/war/assets/ui-light.css >/dev/null
    grep -F ".console-workspace-dock-item.active{color:#fff;background:rgba(255,255,255,.1);border-color:rgba(255,255,255,.32);box-shadow:none;transform:none}" \
      /usr/share/cattle/war/assets/ui-light.css >/dev/null
    for marker in \
      selectionFilter \
      selectionChanged \
      selectablePagedContent \
      allPageSizeValue; do
      grep -F "${marker}" "${vendor_entry}" >/dev/null
    done
    grep -F ".storage-bulk-toolbar" \
      /usr/share/cattle/war/assets/ui-light.css >/dev/null
    grep -F ".storage-state-filter" \
      /usr/share/cattle/war/assets/ui-light.css >/dev/null
    grep -F ".volume-bulk-remove-modal" \
      /usr/share/cattle/war/assets/ui-light.css >/dev/null
    test "$(find /usr/share/cattle/war/translations \
      -maxdepth 1 -type f -name "*.json" | wc -l)" -eq 13
    for marker in \
      "\"cpuRms\":\"CPU\"" \
      "\"memoryRms\":\"RAM\"" \
      "\"networkRms\":\"網路\"" \
      "\"storageRms\":\"儲存\"" \
      "\"image\":\"容器映像\"" \
      "\"ipAddress\":\"IP 位址\"" \
      "\"command\":\"命令\"" \
      "\"rowsPerPage\":\"每頁顯示\"" \
      "\"label\":\"篩選\"" \
      "\"removable\":\"可勾選移除\"" \
      "\"selected\":\"已選 {count} 個\"" \
      "\"action\":\"移除所選項目（{count}）\"" \
      "\"title\":\"移除所選儲存項目\"" \
      "\"selectableHint\":\"只有已卸離、沒有作用中掛載且系統提供移除操作的項目可以勾選。\""; do
      grep -F "${marker}" \
        /usr/share/cattle/war/translations/zh-tw.json >/dev/null
    done
    for forbidden in \
      confirm-clean-unused-volumes \
      cleanupClassification \
      promptCleanup \
      "沒有可安全清理的項目"; do
      ! grep -R -F "${forbidden}" \
        /usr/share/cattle/war >/dev/null
    done
    combined_zh="映像""（命令）"
    combined_en="Image ""(Command)"
    ! grep -R -F "${combined_zh}" \
      /usr/share/cattle/war/translations >/dev/null
    ! grep -R -F "${combined_en}" \
      /usr/share/cattle/war/translations >/dev/null
    app_config_jar=$(find /usr/share/cattle/war/WEB-INF/lib \
      -maxdepth 1 -type f -name "cattle-app-config-*.jar" -print -quit)
    test -n "${app_config_jar}"
    unzip -p "${app_config_jar}" \
      META-INF/cattle/api-server/defaults.properties \
      | grep -Fx "newest.docker.version=v29.6.2"
'

printf 'SERVER_STORAGE_BULK_REMOVE_UI_PATCH_IMAGE_OK image=%s revision=%s web_console_commit=%s\n' \
    "$image" "$revision" "$web_console_commit"

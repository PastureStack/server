#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.container-metrics-ui-patch
build_script=server/build-container-metrics-ui-patch-image.sh

for path in "$dockerfile" "$build_script"; do
    test -f "$path"
done

require_marker()
{
    local file=$1
    local marker=$2
    local code=$3
    if ! grep -Fq -- "$marker" "$file"; then
        printf '%s file=%s marker=%s\n' "$code" "$file" "$marker" >&2
        exit 1
    fi
}

require_marker "$dockerfile" \
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.307' \
    SERVER_CONTAINER_METRICS_UI_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.308"' \
    SERVER_CONTAINER_METRICS_UI_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.308' \
    SERVER_CONTAINER_METRICS_UI_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.19' \
    SERVER_CONTAINER_METRICS_UI_PACKAGE_MISSING
require_marker "$dockerfile" \
    "grep -F 'statsSortRevision'" \
    SERVER_CONTAINER_METRICS_UI_SORT_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F 'setVisibleStatsInstances'" \
    SERVER_CONTAINER_METRICS_UI_VISIBLE_PAGE_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F 'HOST_CONTAINER_COLUMNS'" \
    SERVER_CONTAINER_METRICS_UI_COLUMN_ORDER_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F 'hostContainerColumnsV2'" \
    SERVER_CONTAINER_METRICS_UI_HOST_COLUMN_DEFAULT_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F 'serviceContainerColumnsV2'" \
    SERVER_CONTAINER_METRICS_UI_SERVICE_COLUMN_DEFAULT_GATE_MISSING
require_marker "$dockerfile" \
    'translationKey:"containersPage.table.image",columnRole:"image",defaultHidden:!0' \
    SERVER_CONTAINER_METRICS_UI_IMAGE_DEFAULT_GATE_MISSING
require_marker "$dockerfile" \
    'translationKey:"containersPage.table.command",columnRole:"command",defaultHidden:!0' \
    SERVER_CONTAINER_METRICS_UI_COMMAND_DEFAULT_GATE_MISSING
require_marker "$dockerfile" \
    'createTextNode(" / ")' \
    SERVER_CONTAINER_METRICS_UI_COMPACT_PAGE_SUMMARY_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F 'columnSelector'" \
    SERVER_CONTAINER_METRICS_UI_COLUMN_SELECTOR_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F 'showImageColumn'" \
    SERVER_CONTAINER_METRICS_UI_IMAGE_COLUMN_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F 'showCommandColumn'" \
    SERVER_CONTAINER_METRICS_UI_COMMAND_COLUMN_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '.sortable-table-column-selector'" \
    SERVER_CONTAINER_METRICS_UI_COLUMN_SELECTOR_STYLE_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '.sortable-table-filter-controls'" \
    SERVER_CONTAINER_METRICS_UI_FILTER_LAYOUT_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '.console-workspace-dock-item:focus-visible'" \
    SERVER_CONTAINER_METRICS_UI_FOCUS_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '.console-workspace-dock-item.active{color:#fff;background:rgba(255,255,255,.1);border-color:rgba(255,255,255,.32);box-shadow:none;transform:none}'" \
    SERVER_CONTAINER_METRICS_UI_ACTIVE_STATE_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '\"rowsPerPage\":\"每頁顯示\"'" \
    SERVER_CONTAINER_METRICS_UI_LOCALE_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '\"cpuRms\":\"CPU\"'" \
    SERVER_CONTAINER_METRICS_UI_CPU_LABEL_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '\"memoryRms\":\"RAM\"'" \
    SERVER_CONTAINER_METRICS_UI_RAM_LABEL_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '\"networkRms\":\"網路\"'" \
    SERVER_CONTAINER_METRICS_UI_NETWORK_LABEL_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '\"storageRms\":\"儲存\"'" \
    SERVER_CONTAINER_METRICS_UI_STORAGE_LABEL_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '\"image\":\"容器映像\"'" \
    SERVER_CONTAINER_METRICS_UI_IMAGE_LABEL_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '\"ipAddress\":\"IP 位址\"'" \
    SERVER_CONTAINER_METRICS_UI_IP_LABEL_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '\"command\":\"命令\"'" \
    SERVER_CONTAINER_METRICS_UI_COMMAND_LABEL_GATE_MISSING
require_marker "$build_script" \
    'WEB_CONSOLE_ARTIFACT_SHA256 is required' \
    SERVER_CONTAINER_METRICS_UI_HASH_REQUIRED_MISSING
require_marker "$build_script" \
    'PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27' \
    SERVER_CONTAINER_METRICS_UI_DOCKER_POLICY_REGRESSION_MISSING
require_marker "$build_script" \
    'PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1' \
    SERVER_CONTAINER_METRICS_UI_CATALOG_REGRESSION_MISSING

digest_coordinate='@''sha256:'
if grep -Fq "$digest_coordinate" "$dockerfile" "$build_script"; then
    echo 'SERVER_CONTAINER_METRICS_UI_DIGEST_QUALIFIED_RUNTIME_COORDINATE' >&2
    exit 1
fi

if grep -RInE 'C:\\Users\\|10[.]0[.]0[.]125' "$dockerfile" "$build_script"; then
    echo 'SERVER_CONTAINER_METRICS_UI_PRIVATE_MARKER' >&2
    exit 1
fi

bash -n "$build_script"

printf 'SERVER_CONTAINER_METRICS_UI_PATCH_OK release=v1.6.308 web_console=1.6.56-pasturestack.19 base=v1.6.307 locales=13 runtime_digest_coordinates=0\n'

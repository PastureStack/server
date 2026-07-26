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
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.305' \
    SERVER_CONTAINER_METRICS_UI_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.306"' \
    SERVER_CONTAINER_METRICS_UI_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.306' \
    SERVER_CONTAINER_METRICS_UI_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.17' \
    SERVER_CONTAINER_METRICS_UI_PACKAGE_MISSING
require_marker "$dockerfile" \
    "grep -F 'statsSortRevision'" \
    SERVER_CONTAINER_METRICS_UI_SORT_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F 'setVisibleStatsInstances'" \
    SERVER_CONTAINER_METRICS_UI_VISIBLE_PAGE_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '.console-workspace-dock-item:focus-visible'" \
    SERVER_CONTAINER_METRICS_UI_FOCUS_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '.console-workspace-dock-item.active{color:#fff;background:rgba(255,255,255,.1);border-color:rgba(255,255,255,.32);box-shadow:none;transform:none}'" \
    SERVER_CONTAINER_METRICS_UI_ACTIVE_STATE_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '\"rowsPerPage\":\"每頁顯示\"'" \
    SERVER_CONTAINER_METRICS_UI_LOCALE_GATE_MISSING
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

printf 'SERVER_CONTAINER_METRICS_UI_PATCH_OK release=v1.6.306 web_console=1.6.56-pasturestack.17 base=v1.6.305 runtime_digest_coordinates=0\n'

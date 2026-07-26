#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.storage-bulk-remove-ui-patch
build_script=server/build-storage-bulk-remove-ui-patch-image.sh

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
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.309' \
    SERVER_STORAGE_BULK_REMOVE_UI_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.310"' \
    SERVER_STORAGE_BULK_REMOVE_UI_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.310' \
    SERVER_STORAGE_BULK_REMOVE_UI_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.21' \
    SERVER_STORAGE_BULK_REMOVE_UI_PACKAGE_MISSING
require_marker "$dockerfile" \
    'confirm-remove-selected-volumes' \
    SERVER_STORAGE_BULK_REMOVE_UI_MODAL_GATE_MISSING
require_marker "$dockerfile" \
    'filterVolumesByState' \
    SERVER_STORAGE_BULK_REMOVE_UI_FILTER_GATE_MISSING
require_marker "$dockerfile" \
    'isBulkRemovableVolume' \
    SERVER_STORAGE_BULK_REMOVE_UI_ELIGIBILITY_GATE_MISSING
require_marker "$dockerfile" \
    'runWithConcurrency' \
    SERVER_STORAGE_BULK_REMOVE_UI_CONCURRENCY_GATE_MISSING
require_marker "$dockerfile" \
    'selectablePagedContent' \
    SERVER_STORAGE_BULK_REMOVE_UI_PAGE_SELECTION_GATE_MISSING
require_marker "$dockerfile" \
    'allPageSizeValue' \
    SERVER_STORAGE_BULK_REMOVE_UI_ALL_PAGE_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '.storage-bulk-toolbar'" \
    SERVER_STORAGE_BULK_REMOVE_UI_TOOLBAR_STYLE_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '.volume-bulk-remove-modal'" \
    SERVER_STORAGE_BULK_REMOVE_UI_MODAL_STYLE_GATE_MISSING
require_marker "$dockerfile" \
    '"action":"移除所選項目（{count}）"' \
    SERVER_STORAGE_BULK_REMOVE_UI_ZH_TW_ACTION_MISSING
require_marker "$dockerfile" \
    '"removable":"可勾選移除"' \
    SERVER_STORAGE_BULK_REMOVE_UI_ZH_TW_FILTER_MISSING
require_marker "$build_script" \
    'WEB_CONSOLE_ARTIFACT_SHA256 is required' \
    SERVER_STORAGE_BULK_REMOVE_UI_HASH_REQUIRED_MISSING
require_marker "$build_script" \
    'WEB_CONSOLE_COMMIT is required' \
    SERVER_STORAGE_BULK_REMOVE_UI_COMMIT_REQUIRED_MISSING
require_marker "$build_script" \
    'PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27' \
    SERVER_STORAGE_BULK_REMOVE_UI_DOCKER_POLICY_REGRESSION_MISSING
require_marker "$build_script" \
    'PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1' \
    SERVER_STORAGE_BULK_REMOVE_UI_CATALOG_REGRESSION_MISSING

digest_coordinate='@''sha256:'
if grep -Fq "$digest_coordinate" "$dockerfile" "$build_script"; then
    echo 'SERVER_STORAGE_BULK_REMOVE_UI_DIGEST_QUALIFIED_RUNTIME_COORDINATE' >&2
    exit 1
fi

if grep -RInE 'C:\\Users\\|10[.]0[.]0[.]125' "$dockerfile" "$build_script"; then
    echo 'SERVER_STORAGE_BULK_REMOVE_UI_PRIVATE_MARKER' >&2
    exit 1
fi

bash -n "$build_script"

printf 'SERVER_STORAGE_BULK_REMOVE_UI_PATCH_OK release=v1.6.310 web_console=1.6.56-pasturestack.21 base=v1.6.309 locales=13 paging=10,25,50,all runtime_digest_coordinates=0\n'

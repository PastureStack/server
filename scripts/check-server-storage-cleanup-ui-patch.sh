#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.storage-cleanup-ui-patch
build_script=server/build-storage-cleanup-ui-patch-image.sh

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
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.308' \
    SERVER_STORAGE_CLEANUP_UI_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.309"' \
    SERVER_STORAGE_CLEANUP_UI_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.309' \
    SERVER_STORAGE_CLEANUP_UI_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.20' \
    SERVER_STORAGE_CLEANUP_UI_PACKAGE_MISSING
require_marker "$dockerfile" \
    'confirm-clean-unused-volumes' \
    SERVER_STORAGE_CLEANUP_UI_MODAL_GATE_MISSING
require_marker "$dockerfile" \
    'cleanupClassification' \
    SERVER_STORAGE_CLEANUP_UI_CLASSIFICATION_GATE_MISSING
require_marker "$dockerfile" \
    'promptCleanup' \
    SERVER_STORAGE_CLEANUP_UI_ACTION_GATE_MISSING
require_marker "$dockerfile" \
    'runWithConcurrency' \
    SERVER_STORAGE_CLEANUP_UI_CONCURRENCY_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '.storage-cleanup-toolbar'" \
    SERVER_STORAGE_CLEANUP_UI_TOOLBAR_STYLE_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '.unused-volume-cleanup-modal'" \
    SERVER_STORAGE_CLEANUP_UI_MODAL_STYLE_GATE_MISSING
require_marker "$dockerfile" \
    '"action":"清理未使用項目（{count}）"' \
    SERVER_STORAGE_CLEANUP_UI_ZH_TW_ACTION_MISSING
require_marker "$dockerfile" \
    '"none":"沒有可安全清理的項目"' \
    SERVER_STORAGE_CLEANUP_UI_ZH_TW_EMPTY_STATE_MISSING
require_marker "$build_script" \
    'WEB_CONSOLE_ARTIFACT_SHA256 is required' \
    SERVER_STORAGE_CLEANUP_UI_HASH_REQUIRED_MISSING
require_marker "$build_script" \
    'WEB_CONSOLE_COMMIT is required' \
    SERVER_STORAGE_CLEANUP_UI_COMMIT_REQUIRED_MISSING
require_marker "$build_script" \
    'PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27' \
    SERVER_STORAGE_CLEANUP_UI_DOCKER_POLICY_REGRESSION_MISSING
require_marker "$build_script" \
    'PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1' \
    SERVER_STORAGE_CLEANUP_UI_CATALOG_REGRESSION_MISSING

digest_coordinate='@''sha256:'
if grep -Fq "$digest_coordinate" "$dockerfile" "$build_script"; then
    echo 'SERVER_STORAGE_CLEANUP_UI_DIGEST_QUALIFIED_RUNTIME_COORDINATE' >&2
    exit 1
fi

if grep -RInE 'C:\\Users\\|10[.]0[.]0[.]125' "$dockerfile" "$build_script"; then
    echo 'SERVER_STORAGE_CLEANUP_UI_PRIVATE_MARKER' >&2
    exit 1
fi

bash -n "$build_script"

printf 'SERVER_STORAGE_CLEANUP_UI_PATCH_OK release=v1.6.309 web_console=1.6.56-pasturestack.20 base=v1.6.308 locales=13 runtime_digest_coordinates=0\n'

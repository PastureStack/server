#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.docker-host-support-patch
build_script=server/build-docker-host-support-patch-image.sh
supported='~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || v29.4.1 || v29.7.2'

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
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.304' \
    SERVER_DOCKER_SUPPORT_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    "ARG SUPPORTED_DOCKER_RANGE=\"${supported}\"" \
    SERVER_DOCKER_SUPPORT_RANGE_MISSING
require_marker "$dockerfile" \
    'ARG NEWEST_DOCKER_VERSION=v29.7.2' \
    SERVER_DOCKER_SUPPORT_NEWEST_MISSING
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.305"' \
    SERVER_DOCKER_SUPPORT_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.305' \
    SERVER_DOCKER_SUPPORT_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27' \
    SERVER_DOCKER_SUPPORT_POLICY_MARKER_MISSING
require_marker "$dockerfile" \
    'jar --update \' \
    SERVER_DOCKER_SUPPORT_CONFIG_PATCH_MISSING
require_marker "$build_script" \
    'PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.16' \
    SERVER_DOCKER_SUPPORT_UI_REGRESSION_GATE_MISSING
require_marker "$build_script" \
    'PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1' \
    SERVER_DOCKER_SUPPORT_CATALOG_REGRESSION_GATE_MISSING

if grep -Eq 'SUPPORTED_DOCKER_RANGE=.*(~v24|~v29|v2[5-8][.])' "$dockerfile"; then
    echo 'SERVER_DOCKER_SUPPORT_BROAD_UNTESTED_RANGE' >&2
    exit 1
fi

if grep -Fq '@sha256:' "$dockerfile"; then
    echo 'SERVER_DOCKER_SUPPORT_DIGEST_QUALIFIED_RUNTIME_COORDINATE' >&2
    exit 1
fi

bash -n "$build_script"

printf 'SERVER_DOCKER_HOST_SUPPORT_PATCH_OK release=v1.6.305 newest=29.7.2 exact_modern_versions=24.0.9,29.4.1,29.7.2 broad_25_to_28=0 runtime_digest_coordinates=0\n'

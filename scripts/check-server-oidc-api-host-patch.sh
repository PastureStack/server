#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.oidc-api-host-patch
build_script=server/build-oidc-api-host-patch-image.sh
release_doc=docs/releases/server-1.6.314.md

for path in "$dockerfile" "$build_script" "$release_doc"; do
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
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.313' \
    SERVER_OIDC_API_HOST_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.314"' \
    SERVER_OIDC_API_HOST_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.314' \
    SERVER_OIDC_API_HOST_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.26' \
    SERVER_OIDC_API_HOST_WEB_VERSION_MISSING
require_marker "$dockerfile" \
    'ensureApiHost' \
    SERVER_OIDC_API_HOST_RUNTIME_MARKER_MISSING
require_marker "$dockerfile" \
    'ARG SOURCE_DATE_EPOCH' \
    SERVER_OIDC_API_HOST_SOURCE_DATE_EPOCH_MISSING
require_marker "$dockerfile" \
    'web_root="$(readlink -f /usr/share/cattle/war)"' \
    SERVER_OIDC_API_HOST_DOCUMENT_ROOT_NORMALIZATION_MISSING
require_marker "$build_script" \
    'WEB_CONSOLE_ARTIFACT_SHA256 is required' \
    SERVER_OIDC_API_HOST_HASH_REQUIRED_MISSING
require_marker "$build_script" \
    'WEB_CONSOLE_COMMIT is required' \
    SERVER_OIDC_API_HOST_COMMIT_REQUIRED_MISSING
require_marker "$build_script" \
    'PASTURESTACK_BUILD_NO_CACHE' \
    SERVER_OIDC_API_HOST_CLEAN_BUILD_OPTION_MISSING
require_marker "$build_script" \
    '--build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}"' \
    SERVER_OIDC_API_HOST_REPRODUCIBLE_EPOCH_MISSING
require_marker "$build_script" \
    'PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27' \
    SERVER_OIDC_API_HOST_DOCKER_POLICY_REGRESSION_MISSING
require_marker "$build_script" \
    'PASTURESTACK_AUTHENTICATION_SERVICE_VERSION=0.2.1' \
    SERVER_OIDC_API_HOST_AUTH_REGRESSION_MISSING
require_marker "$build_script" \
    'PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1' \
    SERVER_OIDC_API_HOST_CATALOG_REGRESSION_MISSING
require_marker "$release_doc" \
    'canonical `api.host`' \
    SERVER_OIDC_API_HOST_RELEASE_BEHAVIOR_MISSING

test "$(grep -Fc 'curl -fsSL' "$dockerfile")" -eq 1
for flag in \
    '--retry 5' \
    '--retry-all-errors' \
    '--retry-delay 2' \
    '--connect-timeout 10' \
    '--max-time 300'; do
    test "$(grep -Fc -- "$flag" "$dockerfile")" -eq 1
done

digest_coordinate='@''sha256:'
if grep -Fq "$digest_coordinate" "$dockerfile" "$build_script"; then
    echo 'SERVER_OIDC_API_HOST_DIGEST_QUALIFIED_RUNTIME_COORDINATE' >&2
    exit 1
fi

if grep -RInE 'C:\\Users\\|10[.]0[.]0[.]125|@gmail[.]com' \
    "$dockerfile" "$build_script" "$release_doc"; then
    echo 'SERVER_OIDC_API_HOST_PRIVATE_MARKER' >&2
    exit 1
fi

bash -n "$build_script"

printf 'SERVER_OIDC_API_HOST_PATCH_OK release=v1.6.314 web_console=1.6.56-pasturestack.26 base=v1.6.313 locales=13 canonical_api_host=1 runtime_digest_coordinates=0\n'

#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.openid-connect-patch
build_script=server/build-openid-connect-patch-image.sh
release_doc=docs/releases/server-1.6.313.md

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
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.312' \
    SERVER_OPENID_CONNECT_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.313"' \
    SERVER_OPENID_CONNECT_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.313' \
    SERVER_OPENID_CONNECT_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_AUTHENTICATION_SERVICE_VERSION=0.2.1' \
    SERVER_OPENID_CONNECT_AUTH_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.25' \
    SERVER_OPENID_CONNECT_UI_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG SOURCE_DATE_EPOCH' \
    SERVER_OPENID_CONNECT_SOURCE_DATE_EPOCH_MISSING
test "$(grep -Fc 'touch -h -d "@${SOURCE_DATE_EPOCH}"' "$dockerfile")" -eq 2 || {
    echo 'SERVER_OPENID_CONNECT_TIMESTAMP_NORMALIZATION_MISSING' >&2
    exit 1
}
require_marker "$dockerfile" \
    'web_root="$(readlink -f /usr/share/cattle/war)"' \
    SERVER_OPENID_CONNECT_DOCUMENT_ROOT_NORMALIZATION_MISSING
require_marker "$dockerfile" \
    'https://github.com/PastureStack/authentication-service/releases/download/' \
    SERVER_OPENID_CONNECT_AUTH_RELEASE_MISSING
require_marker "$dockerfile" \
    'https://github.com/PastureStack/web-console/releases/download/' \
    SERVER_OPENID_CONNECT_UI_RELEASE_MISSING
require_marker "$dockerfile" \
    'authentication_target=/usr/bin/authentication-service.real' \
    SERVER_OPENID_CONNECT_WRAPPED_BINARY_TARGET_MISSING
require_marker "$dockerfile" \
    'AUTHENTICATION_SERVICE_ARTIFACT_SHA256' \
    SERVER_OPENID_CONNECT_AUTH_HASH_MISSING
require_marker "$dockerfile" \
    'WEB_CONSOLE_ARTIFACT_SHA256' \
    SERVER_OPENID_CONNECT_UI_HASH_MISSING
require_marker "$dockerfile" \
    'test "$(find /usr/share/cattle/war/translations' \
    SERVER_OPENID_CONNECT_LOCALE_COUNT_GATE_MISSING
require_marker "$dockerfile" \
    'redirectUrl' \
    SERVER_OPENID_CONNECT_PREPARE_ENDPOINT_MARKER_MISSING
require_marker "$dockerfile" \
    'testlogin' \
    SERVER_OPENID_CONNECT_TEST_ENDPOINT_MARKER_MISSING
require_marker "$dockerfile" \
    'localauthconfig' \
    SERVER_OPENID_CONNECT_RECOVERY_MARKER_MISSING
require_marker "$dockerfile" \
    '"save":"驗證設定"' \
    SERVER_OPENID_CONNECT_ZH_TW_VALIDATE_MISSING
require_marker "$build_script" \
    'AUTHENTICATION_SERVICE_ARTIFACT_SHA256 is required' \
    SERVER_OPENID_CONNECT_AUTH_HASH_REQUIRED_MISSING
require_marker "$build_script" \
    'AUTHENTICATION_SERVICE_COMMIT is required' \
    SERVER_OPENID_CONNECT_AUTH_COMMIT_REQUIRED_MISSING
require_marker "$build_script" \
    'WEB_CONSOLE_ARTIFACT_SHA256 is required' \
    SERVER_OPENID_CONNECT_UI_HASH_REQUIRED_MISSING
require_marker "$build_script" \
    'WEB_CONSOLE_COMMIT is required' \
    SERVER_OPENID_CONNECT_UI_COMMIT_REQUIRED_MISSING
require_marker "$build_script" \
    'PASTURESTACK_BUILD_NO_CACHE' \
    SERVER_OPENID_CONNECT_CLEAN_BUILD_OPTION_MISSING
require_marker "$build_script" \
    '--build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}"' \
    SERVER_OPENID_CONNECT_REPRODUCIBLE_EPOCH_MISSING
require_marker "$build_script" \
    'PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27' \
    SERVER_OPENID_CONNECT_DOCKER_POLICY_REGRESSION_MISSING
require_marker "$build_script" \
    'PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1' \
    SERVER_OPENID_CONNECT_CATALOG_REGRESSION_MISSING
require_marker "$release_doc" \
    'test-before-enable' \
    SERVER_OPENID_CONNECT_RELEASE_RECOVERY_MISSING

test "$(grep -Fc 'curl -fsSL' "$dockerfile")" -eq 2
for flag in \
    'curl -fsSL' \
    '--retry 5' \
    '--retry-all-errors' \
    '--retry-delay 2' \
    '--connect-timeout 10' \
    '--max-time 300'; do
    test "$(grep -Fc -- "$flag" "$dockerfile")" -eq 2 || {
        printf 'SERVER_OPENID_CONNECT_CURL_POLICY_MISMATCH file=%s marker=%s\n' \
            "$dockerfile" "$flag" >&2
        exit 1
    }
done

digest_coordinate='@''sha256:'
if grep -Fq "$digest_coordinate" "$dockerfile" "$build_script"; then
    echo 'SERVER_OPENID_CONNECT_DIGEST_QUALIFIED_RUNTIME_COORDINATE' >&2
    exit 1
fi

if grep -RInE 'C:\\Users\\|10[.]0[.]0[.]125|@gmail[.]com' \
    "$dockerfile" "$build_script" "$release_doc"; then
    echo 'SERVER_OPENID_CONNECT_PRIVATE_MARKER' >&2
    exit 1
fi

bash -n "$build_script"

printf 'SERVER_OPENID_CONNECT_PATCH_OK release=v1.6.313 authentication_service=0.2.1 web_console=1.6.56-pasturestack.25 base=v1.6.312 locales=13 runtime_digest_coordinates=0\n'

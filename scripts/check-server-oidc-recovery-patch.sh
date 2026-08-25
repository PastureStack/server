#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.oidc-recovery-patch
build_script=server/build-oidc-recovery-patch-image.sh
release_doc=docs/releases/server-1.6.315.md

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
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.314' \
    SERVER_OIDC_RECOVERY_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.315"' \
    SERVER_OIDC_RECOVERY_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_AUTHENTICATION_SERVICE_VERSION=0.2.3' \
    SERVER_OIDC_RECOVERY_AUTH_VERSION_MISSING
require_marker "$dockerfile" \
    "grep -aF 'go1.27.0'" \
    SERVER_OIDC_RECOVERY_AUTH_TOOLCHAIN_GATE_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.27' \
    SERVER_OIDC_RECOVERY_WEB_VERSION_MISSING
require_marker "$dockerfile" 'activateWithCodeFlow' SERVER_OIDC_RECOVERY_STAGED_FLOW_MISSING
require_marker "$dockerfile" 'suspendSession' SERVER_OIDC_RECOVERY_SESSION_SUSPEND_MISSING
require_marker "$dockerfile" 'restoreSession' SERVER_OIDC_RECOVERY_SESSION_RESTORE_MISSING
require_marker "$dockerfile" 'ensureApiHost' SERVER_OIDC_RECOVERY_API_HOST_REGRESSION
require_marker "$dockerfile" 'ARG SOURCE_DATE_EPOCH' SERVER_OIDC_RECOVERY_EPOCH_MISSING
require_marker "$dockerfile" \
    'web_root="$(readlink -f /usr/share/cattle/war)"' \
    SERVER_OIDC_RECOVERY_DOCUMENT_ROOT_NORMALIZATION_MISSING
require_marker "$build_script" \
    'AUTHENTICATION_SERVICE_ARTIFACT_SHA256 is required' \
    SERVER_OIDC_RECOVERY_AUTH_HASH_REQUIRED_MISSING
require_marker "$build_script" \
    'WEB_CONSOLE_ARTIFACT_SHA256 is required' \
    SERVER_OIDC_RECOVERY_WEB_HASH_REQUIRED_MISSING
require_marker "$build_script" 'PASTURESTACK_BUILD_NO_CACHE' SERVER_OIDC_RECOVERY_NO_CACHE_MISSING
require_marker "$build_script" \
    'PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27' \
    SERVER_OIDC_RECOVERY_DOCKER_POLICY_REGRESSION
require_marker "$build_script" \
    'PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1' \
    SERVER_OIDC_RECOVERY_CATALOG_REGRESSION
require_marker "$release_doc" \
    'active platform provider is canonical' \
    SERVER_OIDC_RECOVERY_ACTIVE_PROVIDER_BEHAVIOR_MISSING
require_marker "$release_doc" \
    'global security remains disabled' \
    SERVER_OIDC_RECOVERY_STAGED_ACTIVATION_BEHAVIOR_MISSING

test "$(grep -Fc 'curl -fsSL' "$dockerfile")" -eq 2
for flag in '--retry 5' '--retry-all-errors' '--retry-delay 2' '--connect-timeout 10' '--max-time 300'; do
    test "$(grep -Fc -- "$flag" "$dockerfile")" -eq 2
done

digest_coordinate='@''sha256:'
if grep -Fq "$digest_coordinate" "$dockerfile" "$build_script"; then
    echo 'SERVER_OIDC_RECOVERY_DIGEST_QUALIFIED_RUNTIME_COORDINATE' >&2
    exit 1
fi
if grep -RInE 'C:\\Users\\|10[.]0[.]0[.]125|@gmail[.]com' \
    "$dockerfile" "$build_script" "$release_doc"; then
    echo 'SERVER_OIDC_RECOVERY_PRIVATE_MARKER' >&2
    exit 1
fi

bash -n "$build_script"

printf 'SERVER_OIDC_RECOVERY_PATCH_OK release=v1.6.315 authentication_service=0.2.3 web_console=1.6.56-pasturestack.27 base=v1.6.314 locales=13 runtime_digest_coordinates=0\n'

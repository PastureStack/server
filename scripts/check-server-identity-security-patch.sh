#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.identity-security-patch
build_script=server/build-identity-security-patch-image.sh
release_doc=docs/releases/server-1.6.316.md

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
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.315' \
    SERVER_IDENTITY_SECURITY_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.316"' \
    SERVER_IDENTITY_SECURITY_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_CATTLE_VERSION=v0.183.270' \
    SERVER_IDENTITY_SECURITY_ENGINE_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_AUTHENTICATION_SERVICE_VERSION=0.2.4' \
    SERVER_IDENTITY_SECURITY_AUTH_VERSION_MISSING
require_marker "$dockerfile" \
    "grep -aF 'go1.26.5'" \
    SERVER_IDENTITY_SECURITY_AUTH_TOOLCHAIN_GATE_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.28' \
    SERVER_IDENTITY_SECURITY_WEB_VERSION_MISSING
require_marker "$dockerfile" 'AuthIdentityLinkResourceManager.class' \
    SERVER_IDENTITY_SECURITY_ACCOUNT_LINK_MISSING
require_marker "$dockerfile" 'switchToLocal' \
    SERVER_IDENTITY_SECURITY_LOCAL_SWITCH_MISSING
require_marker "$dockerfile" 'recoveryIdentities' \
    SERVER_IDENTITY_SECURITY_RECOVERY_IDENTITY_SCOPE_MISSING
require_marker "$dockerfile" 'linkMatchesProvider' \
    SERVER_IDENTITY_SECURITY_ACTIVE_PROVIDER_LINK_SCOPE_MISSING
require_marker "$dockerfile" 'makeSingularStringIfCan' \
    SERVER_IDENTITY_SECURITY_ACCOUNT_FILTER_PARSER_MISSING
require_marker "$dockerfile" '"collectionFilters"' \
    SERVER_IDENTITY_SECURITY_ACCOUNT_FILTER_SCHEMA_MISSING
require_marker "$dockerfile" 'cattle-framework-auditing-0.183.270.jar' \
    SERVER_IDENTITY_SECURITY_AUDITING_ARCHIVE_MISSING
require_marker "$dockerfile" 'auditIdentity' \
    SERVER_IDENTITY_SECURITY_AUDIT_IDENTITY_BOUNDARY_MISSING
require_marker "$dockerfile" 'discardPermissions' \
    SERVER_IDENTITY_SECURITY_PERMISSION_DISCARD_MISSING
require_marker "$dockerfile" 'MfaResourceManager.class' \
    SERVER_IDENTITY_SECURITY_MFA_MISSING
require_marker "$dockerfile" 'WebAuthnService.class' \
    SERVER_IDENTITY_SECURITY_WEBAUTHN_MISSING
require_marker "$dockerfile" 'webauthn4j-core-0.31.8.RELEASE.jar' \
    SERVER_IDENTITY_SECURITY_WEBAUTHN_LIBRARY_MISSING
require_marker "$dockerfile" 'jakarta.mail-api-2.1.5.jar' \
    SERVER_IDENTITY_SECURITY_MAIL_API_MISSING
require_marker "$dockerfile" 'angus-mail-2.0.5.jar' \
    SERVER_IDENTITY_SECURITY_MAIL_RUNTIME_MISSING
require_marker "$dockerfile" 'ARG SOURCE_DATE_EPOCH' \
    SERVER_IDENTITY_SECURITY_EPOCH_MISSING
require_marker "$dockerfile" \
    'web_root="$(readlink -f /usr/share/cattle/war)"' \
    SERVER_IDENTITY_SECURITY_DOCUMENT_ROOT_NORMALIZATION_MISSING
require_marker "$dockerfile" \
    'mkdir -p /usr/share/cattle/war/assets;' \
    SERVER_IDENTITY_SECURITY_ASSET_DIRECTORY_BOOTSTRAP_MISSING
require_marker "$dockerfile" \
    'COPY patches/db/core-124.xml /tmp/pasturestack-server-overlays/db/core-124.xml' \
    SERVER_IDENTITY_SECURITY_DATABASE_OVERLAY_MISSING
require_marker "$dockerfile" \
    'COPY patches/PatchV1GlobalSubscribe.java /tmp/pasturestack-server-overlays/PatchV1GlobalSubscribe.java' \
    SERVER_IDENTITY_SECURITY_SUBSCRIBE_OVERLAY_MISSING
require_marker "$dockerfile" \
    'PatchV1GlobalSubscribe verify; \' \
    SERVER_IDENTITY_SECURITY_FROZEN_SCHEMA_COMPILE_MISSING
require_marker "$dockerfile" \
    '        schema/v1/superadmin.ser \' \
    SERVER_IDENTITY_SECURITY_FROZEN_SCHEMA_ROLE_SET_MISSING
require_marker "$dockerfile" \
    "grep -F 'pasturestack-catalog-pinned-commit'" \
    SERVER_IDENTITY_SECURITY_CATALOG_SCHEMA_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '\"subscribe\": \"cr\"'" \
    SERVER_IDENTITY_SECURITY_SERVICE_AUTH_GATE_MISSING
require_marker "$build_script" \
    'ORCHESTRATION_ENGINE_ARTIFACT_SHA256 is required' \
    SERVER_IDENTITY_SECURITY_ENGINE_HASH_REQUIRED_MISSING
require_marker "$build_script" \
    'AUTHENTICATION_SERVICE_ARTIFACT_SHA256 is required' \
    SERVER_IDENTITY_SECURITY_AUTH_HASH_REQUIRED_MISSING
require_marker "$build_script" \
    'WEB_CONSOLE_ARTIFACT_SHA256 is required' \
    SERVER_IDENTITY_SECURITY_WEB_HASH_REQUIRED_MISSING
require_marker "$build_script" \
    'PASTURESTACK_ALLOW_LOOPBACK_ARTIFACTS' \
    SERVER_IDENTITY_SECURITY_ISOLATED_CANDIDATE_PATH_MISSING
require_marker "$build_script" \
    'PASTURESTACK_BUILD_NO_CACHE' \
    SERVER_IDENTITY_SECURITY_NO_CACHE_MISSING
require_marker "$build_script" \
    'PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27' \
    SERVER_IDENTITY_SECURITY_DOCKER_POLICY_REGRESSION
require_marker "$build_script" \
    'PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1' \
    SERVER_IDENTITY_SECURITY_CATALOG_REGRESSION
require_marker "$release_doc" \
    'stable authorization principal' \
    SERVER_IDENTITY_SECURITY_ACCOUNT_MODEL_MISSING
require_marker "$release_doc" \
    'issuer and subject' \
    SERVER_IDENTITY_SECURITY_MATCHING_RULE_MISSING
require_marker "$release_doc" \
    'discard its direct permissions' \
    SERVER_IDENTITY_SECURITY_DISPOSITION_MISSING
require_marker "$release_doc" \
    'Email recovery is not an MFA factor' \
    SERVER_IDENTITY_SECURITY_EMAIL_BOUNDARY_MISSING
require_marker "$release_doc" \
    'can be filtered by the exact' \
    SERVER_IDENTITY_SECURITY_ACCOUNT_FILTER_DOCUMENTATION_MISSING

test "$(grep -Fc 'curl -fsSL' "$dockerfile")" -eq 3
test "$(grep -Fc -- '--retry 5' "$dockerfile")" -eq 3
test "$(grep -Fc -- '--retry-all-errors' "$dockerfile")" -eq 3
test "$(grep -Fc -- '--retry-delay 2' "$dockerfile")" -eq 3
test "$(grep -Fc -- '--connect-timeout 10' "$dockerfile")" -eq 3

digest_coordinate='@''sha256:'
if grep -Fq "$digest_coordinate" "$dockerfile" "$build_script"; then
    echo 'SERVER_IDENTITY_SECURITY_DIGEST_QUALIFIED_RUNTIME_COORDINATE' >&2
    exit 1
fi
if grep -RInE 'C:\\Users\\|10[.]0[.]0[.]125|@gmail[.]com' \
    "$dockerfile" "$build_script" "$release_doc"; then
    echo 'SERVER_IDENTITY_SECURITY_PRIVATE_MARKER' >&2
    exit 1
fi

bash -n "$build_script"

printf 'SERVER_IDENTITY_SECURITY_PATCH_OK release=v1.6.316 engine=0.183.270 authentication_service=0.2.4 web_console=1.6.56-pasturestack.28 base=v1.6.315 locales=13 runtime_digest_coordinates=0\n'

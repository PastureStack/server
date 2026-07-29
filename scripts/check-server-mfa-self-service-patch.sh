#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.mfa-self-service-patch
build_script=server/build-mfa-self-service-patch-image.sh
release_doc=docs/releases/server-1.6.317.md

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
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.316' \
    SERVER_MFA_SELF_SERVICE_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.317"' \
    SERVER_MFA_SELF_SERVICE_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_CATTLE_VERSION=v0.183.271' \
    SERVER_MFA_SELF_SERVICE_ENGINE_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_AUTHENTICATION_SERVICE_VERSION=0.2.4' \
    SERVER_MFA_SELF_SERVICE_AUTH_VERSION_MISSING
require_marker "$dockerfile" \
    "grep -aF 'go1.26.5'" \
    SERVER_MFA_SELF_SERVICE_AUTH_TOOLCHAIN_GATE_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.29' \
    SERVER_MFA_SELF_SERVICE_WEB_VERSION_MISSING
require_marker "$dockerfile" 'AuthIdentityLinkResourceManager.class' \
    SERVER_MFA_SELF_SERVICE_ACCOUNT_LINK_MISSING
require_marker "$dockerfile" 'switchToLocal' \
    SERVER_MFA_SELF_SERVICE_LOCAL_SWITCH_MISSING
require_marker "$dockerfile" 'recoveryIdentities' \
    SERVER_MFA_SELF_SERVICE_RECOVERY_IDENTITY_SCOPE_MISSING
require_marker "$dockerfile" 'linkMatchesProvider' \
    SERVER_MFA_SELF_SERVICE_ACTIVE_PROVIDER_LINK_SCOPE_MISSING
require_marker "$dockerfile" 'makeSingularStringIfCan' \
    SERVER_MFA_SELF_SERVICE_ACCOUNT_FILTER_PARSER_MISSING
require_marker "$dockerfile" '"collectionFilters"' \
    SERVER_MFA_SELF_SERVICE_ACCOUNT_FILTER_SCHEMA_MISSING
require_marker "$dockerfile" 'cattle-framework-auditing-0.183.271.jar' \
    SERVER_MFA_SELF_SERVICE_AUDITING_ARCHIVE_MISSING
require_marker "$dockerfile" 'auditIdentity' \
    SERVER_MFA_SELF_SERVICE_AUDIT_IDENTITY_BOUNDARY_MISSING
require_marker "$dockerfile" 'discardPermissions' \
    SERVER_MFA_SELF_SERVICE_PERMISSION_DISCARD_MISSING
require_marker "$dockerfile" 'MfaResourceManager.class' \
    SERVER_MFA_SELF_SERVICE_MFA_MISSING
require_marker "$dockerfile" 'MfaAccountHolderRequired' \
    SERVER_MFA_SELF_SERVICE_ACCOUNT_HOLDER_BOUNDARY_MISSING
require_marker "$dockerfile" '"recoveryEmailEnrollmentAvailable"' \
    SERVER_MFA_SELF_SERVICE_RECOVERY_EMAIL_SCHEMA_MISSING
require_marker "$dockerfile" 'WebAuthnService.class' \
    SERVER_MFA_SELF_SERVICE_WEBAUTHN_MISSING
require_marker "$dockerfile" 'webauthn4j-core-0.31.8.RELEASE.jar' \
    SERVER_MFA_SELF_SERVICE_WEBAUTHN_LIBRARY_MISSING
require_marker "$dockerfile" 'jakarta.mail-api-2.1.5.jar' \
    SERVER_MFA_SELF_SERVICE_MAIL_API_MISSING
require_marker "$dockerfile" 'angus-mail-2.0.5.jar' \
    SERVER_MFA_SELF_SERVICE_MAIL_RUNTIME_MISSING
require_marker "$dockerfile" 'ARG SOURCE_DATE_EPOCH' \
    SERVER_MFA_SELF_SERVICE_EPOCH_MISSING
require_marker "$dockerfile" \
    'web_root="$(readlink -f /usr/share/cattle/war)"' \
    SERVER_MFA_SELF_SERVICE_DOCUMENT_ROOT_NORMALIZATION_MISSING
require_marker "$dockerfile" \
    'mkdir -p /usr/share/cattle/war/assets;' \
    SERVER_MFA_SELF_SERVICE_ASSET_DIRECTORY_BOOTSTRAP_MISSING
require_marker "$dockerfile" \
    'COPY patches/db/core-124.xml /tmp/pasturestack-server-overlays/db/core-124.xml' \
    SERVER_MFA_SELF_SERVICE_DATABASE_OVERLAY_MISSING
require_marker "$dockerfile" \
    'COPY patches/PatchV1GlobalSubscribe.java /tmp/pasturestack-server-overlays/PatchV1GlobalSubscribe.java' \
    SERVER_MFA_SELF_SERVICE_SUBSCRIBE_OVERLAY_MISSING
require_marker "$dockerfile" \
    'PatchV1GlobalSubscribe verify; \' \
    SERVER_MFA_SELF_SERVICE_FROZEN_SCHEMA_COMPILE_MISSING
require_marker "$dockerfile" \
    '        schema/v1/superadmin.ser \' \
    SERVER_MFA_SELF_SERVICE_FROZEN_SCHEMA_ROLE_SET_MISSING
require_marker "$dockerfile" \
    "grep -F 'pasturestack-catalog-pinned-commit'" \
    SERVER_MFA_SELF_SERVICE_CATALOG_SCHEMA_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '\"subscribe\": \"cr\"'" \
    SERVER_MFA_SELF_SERVICE_SERVICE_AUTH_GATE_MISSING
require_marker "$dockerfile" 'account-security' \
    SERVER_MFA_SELF_SERVICE_ROUTE_MARKER_MISSING
require_marker "$dockerfile" 'mfa-self-service-summary' \
    SERVER_MFA_SELF_SERVICE_UI_MARKER_MISSING
require_marker "$dockerfile" '"manageMine":"管理我的登入安全性"' \
    SERVER_MFA_SELF_SERVICE_ZH_TW_MARKER_MISSING
require_marker "$build_script" \
    'ORCHESTRATION_ENGINE_ARTIFACT_SHA256 is required' \
    SERVER_MFA_SELF_SERVICE_ENGINE_HASH_REQUIRED_MISSING
require_marker "$build_script" \
    'AUTHENTICATION_SERVICE_ARTIFACT_SHA256 is required' \
    SERVER_MFA_SELF_SERVICE_AUTH_HASH_REQUIRED_MISSING
require_marker "$build_script" \
    'WEB_CONSOLE_ARTIFACT_SHA256 is required' \
    SERVER_MFA_SELF_SERVICE_WEB_HASH_REQUIRED_MISSING
require_marker "$build_script" \
    'PASTURESTACK_ALLOW_LOOPBACK_ARTIFACTS' \
    SERVER_MFA_SELF_SERVICE_ISOLATED_CANDIDATE_PATH_MISSING
require_marker "$build_script" \
    'PASTURESTACK_BUILD_NO_CACHE' \
    SERVER_MFA_SELF_SERVICE_NO_CACHE_MISSING
require_marker "$build_script" \
    'PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27' \
    SERVER_MFA_SELF_SERVICE_DOCKER_POLICY_REGRESSION
require_marker "$build_script" \
    'PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1' \
    SERVER_MFA_SELF_SERVICE_CATALOG_REGRESSION
require_marker "$build_script" 'MfaAccountHolderRequired' \
    SERVER_MFA_SELF_SERVICE_IMAGE_ACCOUNT_HOLDER_GATE_MISSING
require_marker "$build_script" 'mfa-self-service-summary' \
    SERVER_MFA_SELF_SERVICE_IMAGE_UI_GATE_MISSING
require_marker "$release_doc" \
    'stable authorization principal' \
    SERVER_MFA_SELF_SERVICE_ACCOUNT_MODEL_MISSING
require_marker "$release_doc" \
    'issuer and subject' \
    SERVER_MFA_SELF_SERVICE_MATCHING_RULE_MISSING
require_marker "$release_doc" \
    'discard its direct permissions' \
    SERVER_MFA_SELF_SERVICE_DISPOSITION_MISSING
require_marker "$release_doc" \
    'Email recovery is not an MFA factor' \
    SERVER_MFA_SELF_SERVICE_EMAIL_BOUNDARY_MISSING
require_marker "$release_doc" \
    '/account/security' \
    SERVER_MFA_SELF_SERVICE_ROUTE_DOCUMENTATION_MISSING
require_marker "$release_doc" \
    'MfaAccountHolderRequired' \
    SERVER_MFA_SELF_SERVICE_AUTHORIZATION_DOCUMENTATION_MISSING
require_marker "$release_doc" \
    'begin a real TOTP enrollment' \
    SERVER_MFA_SELF_SERVICE_BROWSER_ACCEPTANCE_MISSING

test "$(grep -Fc 'curl -fsSL' "$dockerfile")" -eq 3
test "$(grep -Fc -- '--retry 5' "$dockerfile")" -eq 3
test "$(grep -Fc -- '--retry-all-errors' "$dockerfile")" -eq 3
test "$(grep -Fc -- '--retry-delay 2' "$dockerfile")" -eq 3
test "$(grep -Fc -- '--connect-timeout 10' "$dockerfile")" -eq 3

digest_coordinate='@''sha256:'
if grep -Fq "$digest_coordinate" "$dockerfile" "$build_script"; then
    echo 'SERVER_MFA_SELF_SERVICE_DIGEST_QUALIFIED_RUNTIME_COORDINATE' >&2
    exit 1
fi
if grep -RInE 'C:\\Users\\|10[.]0[.]0[.]125|@gmail[.]com' \
    "$dockerfile" "$build_script" "$release_doc"; then
    echo 'SERVER_MFA_SELF_SERVICE_PRIVATE_MARKER' >&2
    exit 1
fi

bash -n "$build_script"

printf 'SERVER_MFA_SELF_SERVICE_PATCH_OK release=v1.6.317 engine=0.183.271 authentication_service=0.2.4 web_console=1.6.56-pasturestack.29 base=v1.6.316 locales=13 runtime_digest_coordinates=0\n'

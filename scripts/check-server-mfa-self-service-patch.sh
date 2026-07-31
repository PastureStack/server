#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.mfa-self-service-patch
build_script=server/build-mfa-self-service-patch-image.sh
release_doc=docs/releases/server-1.6.320.md

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
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.319' \
    SERVER_MFA_SELF_SERVICE_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.320"' \
    SERVER_MFA_SELF_SERVICE_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_CATTLE_VERSION=v0.183.272' \
    SERVER_MFA_SELF_SERVICE_ENGINE_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_AUTHENTICATION_SERVICE_VERSION=0.2.5' \
    SERVER_MFA_SELF_SERVICE_AUTH_VERSION_MISSING
require_marker "$dockerfile" \
    "grep -aF 'go1.26.5'" \
    SERVER_MFA_SELF_SERVICE_AUTH_TOOLCHAIN_GATE_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.32' \
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
require_marker "$dockerfile" 'cattle-framework-auditing-0.183.272.jar' \
    SERVER_MFA_SELF_SERVICE_AUDITING_ARCHIVE_MISSING
require_marker "$dockerfile" 'auditIdentity' \
    SERVER_MFA_SELF_SERVICE_AUDIT_IDENTITY_BOUNDARY_MISSING
require_marker "$dockerfile" 'discardPermissions' \
    SERVER_MFA_SELF_SERVICE_PERMISSION_DISCARD_MISSING
require_marker "$dockerfile" 'MfaResourceManager.class' \
    SERVER_MFA_SELF_SERVICE_MFA_MISSING
require_marker "$dockerfile" 'MfaAccountHolderRequired' \
    SERVER_MFA_SELF_SERVICE_ACCOUNT_HOLDER_BOUNDARY_MISSING
require_marker "$dockerfile" 'MfaAttemptService.class' \
    SERVER_MFA_ATTEMPT_THROTTLE_MISSING
require_marker "$dockerfile" 'MfaTemporarilyLocked' \
    SERVER_MFA_ACCOUNT_LOCKOUT_MISSING
require_marker "$dockerfile" 'LocalAdministratorMfaRequired' \
    SERVER_LOCAL_ADMINISTRATOR_MFA_GATE_MISSING
require_marker "$dockerfile" 'api.auth.local.recovery.mfa.ready' \
    SERVER_LOCAL_RECOVERY_READINESS_MISSING
require_marker "$dockerfile" 'securityConfirmationTtlSeconds' \
    SERVER_MFA_STEP_UP_TTL_MISSING
require_marker "$dockerfile" 'federatedMfaMode' \
    SERVER_FEDERATED_MFA_POLICY_MISSING
require_marker "$dockerfile" 'beginSecurityConfirmation' \
    SERVER_MFA_STEP_UP_OPERATION_SCHEMA_MISSING
require_marker "$dockerfile" 'webAuthnOptions' \
    SERVER_MFA_STEP_UP_PASSKEY_SCHEMA_MISSING
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
    'new_web_root_name="${engine_hash}-${PASTURESTACK_SERVER_REVISION}"' \
    SERVER_MFA_SELF_SERVICE_SAME_ENGINE_ROOT_ISOLATION_MISSING
require_marker "$dockerfile" \
    'ln -s "${new_web_root_name}" /usr/share/cattle/war' \
    SERVER_MFA_SELF_SERVICE_REVISION_ROOT_LINK_MISSING
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
    "grep -F 'db/core-125.xml'" \
    SERVER_MFA_CREDENTIAL_SECRET_CHANGELOG_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F 'pasturestack-credential-secret-value-mediumtext'" \
    SERVER_MFA_CREDENTIAL_SECRET_MIGRATION_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F 'MEDIUMTEXT(16777215)'" \
    SERVER_MFA_CREDENTIAL_SECRET_CAPACITY_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '\"subscribe\": \"cr\"'" \
    SERVER_MFA_SELF_SERVICE_SERVICE_AUTH_GATE_MISSING
require_marker "$dockerfile" 'account-security' \
    SERVER_MFA_SELF_SERVICE_ROUTE_MARKER_MISSING
require_marker "$dockerfile" 'mfa-self-service-summary' \
    SERVER_MFA_SELF_SERVICE_UI_MARKER_MISSING
require_marker "$dockerfile" 'mfa-system-settings' \
    SERVER_MFA_SELF_SERVICE_GLOBAL_SETTINGS_UI_MARKER_MISSING
require_marker "$dockerfile" 'showMfaRecoveryOptions' \
    SERVER_MFA_RECOVERY_UI_BOUNDARY_MISSING
require_marker "$dockerfile" '"manageMine":"管理我的登入安全性"' \
    SERVER_MFA_SELF_SERVICE_ZH_TW_MARKER_MISSING
require_marker "$dockerfile" \
    '"systemManaged":"SMTP 寄信服務由系統管理員集中設定，全系統共用。您的帳號不會儲存 SMTP 伺服器、寄件者或密碼。"' \
    SERVER_MFA_SELF_SERVICE_ZH_TW_SMTP_SCOPE_MISSING
require_marker "$dockerfile" \
    '"show":"無法使用驗證器或通行金鑰？"' \
    SERVER_MFA_RECOVERY_ZH_TW_BOUNDARY_MISSING
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
require_marker "$build_script" 'mfa-system-settings' \
    SERVER_MFA_SELF_SERVICE_IMAGE_GLOBAL_SETTINGS_GATE_MISSING
require_marker "$build_script" 'MfaTemporarilyLocked' \
    SERVER_MFA_IMAGE_ACCOUNT_LOCKOUT_GATE_MISSING
require_marker "$build_script" 'LocalAdministratorMfaRequired' \
    SERVER_MFA_IMAGE_LOCAL_ADMINISTRATOR_GATE_MISSING
require_marker "$build_script" 'pasturestack-credential-secret-value-mediumtext' \
    SERVER_MFA_IMAGE_CREDENTIAL_SECRET_MIGRATION_GATE_MISSING
require_marker "$build_script" 'showMfaRecoveryOptions' \
    SERVER_MFA_IMAGE_RECOVERY_UI_GATE_MISSING
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
require_marker "$release_doc" \
    'one system-wide SMTP delivery configuration' \
    SERVER_MFA_SELF_SERVICE_SMTP_SCOPE_MISSING
require_marker "$release_doc" \
    'SystemAdministratorRequired' \
    SERVER_MFA_SELF_SERVICE_SMTP_AUTHORIZATION_MISSING
require_marker "$release_doc" \
    'always completes platform MFA' \
    SERVER_MFA_LOCAL_RECOVERY_DOCUMENTATION_MISSING
require_marker "$release_doc" \
    'one-use security confirmation' \
    SERVER_MFA_STEP_UP_DOCUMENTATION_MISSING
require_marker "$release_doc" \
    'fresh signed amr, acr, and auth_time' \
    SERVER_MFA_FEDERATED_TRUST_DOCUMENTATION_MISSING
require_marker "$release_doc" \
    'does not shrink the column or discard a pending credential' \
    SERVER_MFA_DATABASE_ROLLBACK_DOCUMENTATION_MISSING
require_marker "$release_doc" \
    'preserves pre-migration credential rows' \
    SERVER_MFA_DATABASE_MIGRATION_ACCEPTANCE_MISSING
require_marker "$release_doc" \
    'Cannot use your authenticator or passkey?' \
    SERVER_MFA_RECOVERY_UI_DOCUMENTATION_MISSING
require_marker "$release_doc" \
    '336d48b1104593d4fc28311944824b9b421fe4dd' \
    SERVER_MFA_ENGINE_SOURCE_COORDINATE_MISSING
require_marker "$release_doc" \
    '95073ce4ed95c0d23c675e012fc6c62b6889a09cd449c5db5a79bd8c42aea388' \
    SERVER_MFA_ENGINE_ARTIFACT_COORDINATE_MISSING
require_marker "$release_doc" \
    '62726c0b03b64848ff9d0e1d8ff5e965007efe61' \
    SERVER_MFA_AUTH_SOURCE_COORDINATE_MISSING
require_marker "$release_doc" \
    '109e293092260d788acb3d7fcf4d78cccdf72c268d1728f263efc4075a69241c' \
    SERVER_MFA_AUTH_ARTIFACT_COORDINATE_MISSING
require_marker "$release_doc" \
    'd7c6293865a9b723be345024e442a74b2412d9c1' \
    SERVER_MFA_WEB_SOURCE_COORDINATE_MISSING
require_marker "$release_doc" \
    '56e2d089da5c52573c4fd458542ba110f558cb25b18d3846a5e3c8cdef8572e2' \
    SERVER_MFA_WEB_ARTIFACT_COORDINATE_MISSING

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

printf 'SERVER_MFA_SELF_SERVICE_PATCH_OK release=v1.6.320 engine=0.183.272 authentication_service=0.2.5 web_console=1.6.56-pasturestack.32 base=v1.6.319 locales=13 runtime_digest_coordinates=0\n'

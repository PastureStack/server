#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.api-explorer-patch
release_dockerfile=server/Dockerfile.web-compose-release
core_dockerfile=server/Dockerfile
build_script=server/build-api-explorer-patch-image.sh
publish_workflow=.github/workflows/publish-current-server.yml
cattle_script=server/artifacts/cattle.sh
coreutils_patch=server/patches/coreutils-CVE-2026-56391.patch
runtime_vex=server/security/openvex.json
runtime_vendor_pending=server/security/vendor-pending.json
vendor_pending_validator=scripts/validate-vendor-pending-findings.sh
release_notes=docs/releases/server-1.6.438.md
previous_release_notes=docs/releases/server-1.6.462.md
last_release_notes=docs/releases/server-1.6.463.md
prior_release_notes=docs/releases/server-1.6.466.md
current_release_notes=docs/releases/server-1.6.471.md
host_api_repair=server/artifacts/repair-host-api-sha256.sh
host_api_check=scripts/check-server-host-api-package.sh
mfa_policy_smoke=scripts/test-mfa-policy-api.py

for path in "$dockerfile" "$release_dockerfile" "$core_dockerfile" "$build_script" "$publish_workflow" "$cattle_script" \
    "$coreutils_patch" "$runtime_vex" "$runtime_vendor_pending" \
    "$vendor_pending_validator" \
    "$release_notes" "$previous_release_notes" "$last_release_notes" "$prior_release_notes" "$current_release_notes" "$host_api_repair" "$host_api_check" \
    "$mfa_policy_smoke"; do
    test -f "$path"
done

bash -n "$host_api_repair" "$host_api_check"

if grep -Eq '__WEB_CONSOLE_|__ORCHESTRATION_ENGINE_' "$release_dockerfile" "$build_script"; then
    echo 'SERVER_COMPONENT_RELEASE_COORDINATES_PENDING' >&2
    exit 1
fi

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

for mfa_policy_contract_marker in \
    "check('oidc-project-member-schema-options'" \
    "verify_session_bound_token('/v1', normal_token, normal_session" \
    "verify_session_bound_token('/v2-beta', v2_login['jwt'], v2_session" \
    "assert isinstance(issued_token, str) and issued_token" \
    "'authProvider': 'mfa'" \
    "'clientSessionId': v2_session" \
    "check('v2-mfa-session-generation-preserved'" \
    "check(label + '-mismatched-delete-preserves-token'" \
    "check(label + '-matching-delete-revokes-token'" \
    "check(label + '-repeated-delete-is-idempotent'"; do
    require_marker "$mfa_policy_smoke" "$mfa_policy_contract_marker" \
        SERVER_MFA_POLICY_RUNTIME_CONTRACT_MISSING
done

require_marker "$release_dockerfile" \
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.460@sha256:c855af8aea232dacc5bb6df68e2271d482c68b53c43ab0c108ec19118f5ab403' \
    SERVER_INCREMENTAL_RELEASE_BASE_MISSING
require_marker "$release_dockerfile" \
    'org.opencontainers.image.version="v1.6.471"' \
    SERVER_INCREMENTAL_RELEASE_VERSION_MISSING
require_marker "$release_dockerfile" \
    'org.opencontainers.image.base.name="ghcr.io/pasturestack/server:v1.6.460"' \
    SERVER_INCREMENTAL_RELEASE_BASE_NAME_MISSING
require_marker "$release_dockerfile" \
    'org.opencontainers.image.base.digest="sha256:c855af8aea232dacc5bb6df68e2271d482c68b53c43ab0c108ec19118f5ab403"' \
    SERVER_INCREMENTAL_RELEASE_BASE_DIGEST_MISSING
require_marker "$release_dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.471' \
    SERVER_INCREMENTAL_RELEASE_RUNTIME_VERSION_MISSING
require_marker "$release_dockerfile" \
    'COPY --from=release_artifacts /out/host-api-0.38.4.tar.gz /usr/share/cattle/artifacts/host-api-0.38.4.tar.gz' \
    SERVER_HOST_API_SHA256_PACKAGE_MISSING
require_marker "$release_dockerfile" \
    'repair-host-api-sha256' \
    SERVER_HOST_API_REPAIR_MISSING
require_marker "$publish_workflow" \
    'bash source/scripts/check-server-host-api-package.sh' \
    SERVER_HOST_API_RELEASE_CHECK_MISSING
require_marker "$release_dockerfile" \
    'ARG WEB_CONSOLE_RELEASE_TAG=1.6.136' \
    SERVER_INCREMENTAL_WEB_CONSOLE_VERSION_MISSING
require_marker "$release_dockerfile" \
    'ARG WEB_CONSOLE_ARTIFACT=web-console-1.6.136.tar.gz' \
    SERVER_INCREMENTAL_WEB_CONSOLE_ARTIFACT_MISSING
require_marker "$release_dockerfile" \
    'ARG WEB_CONSOLE_ARTIFACT_SHA256=a799de25353c1dd0452191681f628514dc83346e6d561028dd5a1ff71863cf62' \
    SERVER_INCREMENTAL_WEB_CONSOLE_HASH_MISSING
require_marker "$release_dockerfile" \
    'ARG WEB_CONSOLE_COMMIT=f7ae5e18db876b829876d0ef1849d584849bcd84' \
    SERVER_INCREMENTAL_WEB_CONSOLE_COMMIT_MISSING
require_marker "$release_dockerfile" \
    "grep -aF 'hostsPage.permissionDenied'" \
    SERVER_INCREMENTAL_WEB_CONSOLE_PERMISSION_MARKER_MISSING
require_marker "$release_dockerfile" \
    '"hostsPage.permissionDenied":"您沒有權限在此環境中新增主機。"' \
    SERVER_INCREMENTAL_WEB_CONSOLE_ZH_TW_PERMISSION_MESSAGE_MISSING
require_marker "$build_script" \
    'web_console_commit=${WEB_CONSOLE_COMMIT:-f7ae5e18db876b829876d0ef1849d584849bcd84}' \
    SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_COMMIT_MISSING
require_marker "$build_script" \
    'web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-1.6.136}' \
    SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_VERSION_MISSING
require_marker "$build_script" \
    'web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.136.tar.gz}' \
    SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_ARTIFACT_MISSING
require_marker "$build_script" \
    'web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:-a799de25353c1dd0452191681f628514dc83346e6d561028dd5a1ff71863cf62}' \
    SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_HASH_MISSING
require_marker "$build_script" \
    'hostsPage.permissionDenied' \
    SERVER_INCREMENTAL_WEB_CONSOLE_RUNTIME_PERMISSION_GATE_MISSING
if grep -Fq 'ffb000508cb08a149e34633121aec25f4dab022967c1f4cdf917260061f0dace' \
    "$release_dockerfile" "$build_script"; then
    echo SERVER_INCREMENTAL_WEB_CONSOLE_STALE_HASH >&2
    exit 1
fi
for release_proxy_marker in \
    'ARG WEBSOCKET_PROXY_VERSION=0.23.14' \
    'ARG WEBSOCKET_PROXY_COMMIT=3b5788bdc52f4edab0097a3d97afccf138c64089' \
    'ARG WEBSOCKET_PROXY_ARCHIVE_SHA256=c55108c3dbfd8e6579fc768a1988920db83c6f605ca1284b60edf92ae8d0160e' \
    'ARG WEBSOCKET_PROXY_BINARY_SHA256=efd0c78779a620b4b0f74a10eb3f3edd8886e8d23f22dc4624d8e9971085a26d' \
    'tar --no-same-owner --no-same-permissions -xJf "${websocket_archive}"' \
    'COPY --from=release_artifacts --chmod=0755 /out/websocket-proxy/websocket-proxy /usr/bin/websocket-proxy.real' \
    '/usr/bin/websocket-proxy.real --help 2>&1 | grep -F -- '\''-platform-public-origin'\'''; do
    require_marker "$release_dockerfile" "$release_proxy_marker" \
        SERVER_INCREMENTAL_WEBSOCKET_PROXY_REPLACEMENT_MISSING
done
require_marker "$release_dockerfile" \
    'ARG COMPOSE_EXECUTOR_VERSION=0.14.36' \
    SERVER_INCREMENTAL_COMPOSE_VERSION_MISSING
require_marker "$release_dockerfile" \
    'ARG COMPOSE_EXECUTOR_BINARY_SHA256=1f542ee2dd76c7af06bc5f056c381d7e77aecaeac40f8d897df6df24a9902c0d' \
    SERVER_INCREMENTAL_COMPOSE_HASH_MISSING
require_marker "$release_dockerfile" \
    'tar --no-same-owner --no-same-permissions -xzf "${web_archive}"' \
    SERVER_INCREMENTAL_WEB_CONSOLE_SAFE_EXTRACTION_MISSING
require_marker "$release_dockerfile" \
    'COPY --from=release_artifacts /out/web-console/ /tmp/pasturestack-web-console/' \
    SERVER_INCREMENTAL_WEB_CONSOLE_COPY_MISSING
require_marker "$release_dockerfile" \
    'COPY --from=release_artifacts --chmod=0755 /out/compose-executor /usr/bin/compose-executor.real' \
    SERVER_INCREMENTAL_COMPOSE_COPY_MISSING
require_marker "$release_dockerfile" \
    'COPY --from=console_broker_build --chmod=0755 /out/pasturestack-console-broker /usr/bin/pasturestack-console-broker' \
    SERVER_INCREMENTAL_CONSOLE_BROKER_COPY_MISSING
require_marker "$release_dockerfile" \
    'go test ./...' \
    SERVER_INCREMENTAL_CONSOLE_BROKER_TEST_MISSING
require_marker server/console-broker/broker.go \
    'headers.Set("Origin", sessionDialOrigin(target))' \
    SERVER_CONSOLE_BROKER_INTERNAL_ORIGIN_BINDING_MISSING
require_marker server/console-broker/broker_test.go \
    'TestSessionCreationRebindsBrowserOriginToInternalDialOrigin' \
    SERVER_CONSOLE_BROKER_INTERNAL_ORIGIN_TEST_MISSING
require_marker server/console-broker/broker.go \
    'status != http.StatusUnauthorized || attempt == b.config.SessionDialAttempts' \
    SERVER_CONSOLE_BROKER_BACKEND_RETRY_BOUNDARY_MISSING
require_marker server/console-broker/broker_test.go \
    'TestSessionCreationRetriesBackendRegistrationRace' \
    SERVER_CONSOLE_BROKER_BACKEND_RETRY_TEST_MISSING
require_marker server/console-broker/broker_test.go \
    'TestSessionCreationBackendRetryIsBounded' \
    SERVER_CONSOLE_BROKER_BACKEND_RETRY_LIMIT_TEST_MISSING
for broker_cache_marker in \
    'isPlatformAPIPath(response.Request.URL.Path)' \
    'response.Header.Set("Cache-Control", "private, no-store")' \
    'response.Header.Set("Pragma", "no-cache")' \
    'response.Header.Set("Expires", "0")' \
    'response.Header.Del("Age")'; do
    require_marker server/console-broker/broker.go "$broker_cache_marker" \
        SERVER_CONSOLE_BROKER_PRIVATE_CACHE_POLICY_MISSING
done
require_marker server/console-broker/broker_test.go \
    'TestPlatformAPIResponsesCannotBeSharedCached' \
    SERVER_CONSOLE_BROKER_PRIVATE_CACHE_POLICY_TEST_MISSING
require_marker server/console-broker/broker_test.go \
    'TestStaticAssetCachePolicyIsPreserved' \
    SERVER_CONSOLE_BROKER_STATIC_CACHE_POLICY_TEST_MISSING
require_marker "$release_dockerfile" \
    'test "${compose_version_output}" = "pasturestack-compose version ${COMPOSE_EXECUTOR_VERSION}"' \
    SERVER_INCREMENTAL_COMPOSE_VERSION_GATE_MISSING
require_marker "$release_dockerfile" \
    'footer .footer-dropdown .dropdown-menu' \
    SERVER_INCREMENTAL_FOOTER_MENU_GATE_MISSING
require_marker "$release_dockerfile" \
    '.form-resources .resource-host-guidance' \
    SERVER_INCREMENTAL_RESOURCE_GUIDANCE_GATE_MISSING
require_marker "$release_dockerfile" \
    '"formResources.addUlimit":"新增限制"' \
    SERVER_INCREMENTAL_TRANSLATION_GATE_MISSING
require_marker "$release_dockerfile" \
    '"viewEditProject.error.projectUnavailable":"找不到此環境' \
    SERVER_ENVIRONMENT_ACCESS_TRANSLATION_GATE_MISSING
require_marker "$release_dockerfile" \
    '"viewEditProject.error.membersNotSaved":"成員變更未完成' \
    SERVER_ENVIRONMENT_MEMBER_SAVE_TRANSLATION_GATE_MISSING
require_marker "$release_dockerfile" \
    '"viewEditProject.error.loadFailed":"暫時無法載入環境資料' \
    SERVER_ENVIRONMENT_LOAD_FAILURE_TRANSLATION_GATE_MISSING
require_marker "$release_dockerfile" \
    '"viewEditProject.error.projectFailed":"環境設定未儲存：伺服器暫時無法處理' \
    SERVER_ENVIRONMENT_SAVE_FAILURE_TRANSLATION_GATE_MISSING
require_marker "$release_dockerfile" \
    '"resourceLoadError.stackUnavailable":"找不到此應用堆疊' \
    SERVER_STACK_ACCESS_TRANSLATION_GATE_MISSING
require_marker "$release_dockerfile" \
    '"resourceLoadError.accountsUnavailable":"無法載入帳號資料' \
    SERVER_ACCOUNT_ACCESS_TRANSLATION_GATE_MISSING
require_marker "$build_script" \
    'viewEditProject.error.projectUnavailable' \
    SERVER_ENVIRONMENT_ACCESS_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'viewEditProject.error.membersNotSaved' \
    SERVER_ENVIRONMENT_MEMBER_SAVE_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'viewEditProject.error.loadFailed' \
    SERVER_ENVIRONMENT_LOAD_FAILURE_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'viewEditProject.error.projectFailed' \
    SERVER_ENVIRONMENT_SAVE_FAILURE_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'inputIdentity.error.forbidden' \
    SERVER_IDENTITY_SEARCH_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'resourceLoadError.stackUnavailable' \
    SERVER_STACK_ACCESS_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    '--file server/Dockerfile.web-compose-release' \
    SERVER_INCREMENTAL_RELEASE_BUILD_PATH_MISSING
require_marker "$build_script" \
    'image=${IMAGE:-pasturestack-validation/server:v1.6.471}' \
    SERVER_INCREMENTAL_RELEASE_BUILD_VERSION_MISSING
require_marker "$build_script" \
    'CATTLE_RANCHER_SERVER_VERSION=v1.6.471' \
    SERVER_INCREMENTAL_RELEASE_BUILD_RUNTIME_VERSION_MISSING
for release_engine_marker in \
    'ARG ORCHESTRATION_ENGINE_RELEASE_TAG=v0.183.323' \
    'ARG ORCHESTRATION_ENGINE_ARTIFACT=cattle.jar' \
    'ARG ORCHESTRATION_ENGINE_ARTIFACT_SHA256=ac5644352ee053dcfd6bf930a106c1d439af66f3d0f44c2da2cd961b6de1a0dc' \
    'ARG ORCHESTRATION_ENGINE_COMMIT=5dd2bc06ee644efa0732cbeb11a65edbae3b445e' \
    'COPY --from=release_artifacts /out/orchestration-engine.jar /tmp/orchestration-engine.jar' \
    "grep -Fx 'Implementation-Version: 0.183.323'" \
    'freemarker-2\.3\.35\.jar' \
    'ENV CATTLE_CATTLE_VERSION=v0.183.323' \
    'schema/token/token-auth.json' \
    '"token.clientSessionId": "cro"' \
    'for frozen_token_schema in base superadmin token' \
    'schema/v1/${frozen_token_schema}.ser' \
    'META-INF/cattle/iaas-api/defaults.properties' \
    'auth.service.external.id.types=github_user,github_org,github_team,shibboleth_user,shibboleth_group,ldap_user,ldap_group,oidc_user,oidc_group' \
    'schema/base/projectMember.json' \
    'for oidc_type in oidc_user oidc_group' \
    'ENV PASTURESTACK_ORCHESTRATION_ENGINE_COMMIT=${ORCHESTRATION_ENGINE_COMMIT}' \
    'ENV PASTURESTACK_ORCHESTRATION_ENGINE_ARTIFACT_SHA256=${ORCHESTRATION_ENGINE_ARTIFACT_SHA256}'; do
    require_marker "$release_dockerfile" "$release_engine_marker" \
        SERVER_INCREMENTAL_ENGINE_REPLACEMENT_MISSING
done
for release_engine_build_marker in \
    'orchestration_engine_release_tag=${ORCHESTRATION_ENGINE_RELEASE_TAG:-v0.183.323}' \
    'orchestration_engine_artifact=${ORCHESTRATION_ENGINE_ARTIFACT:-cattle.jar}' \
    'orchestration_engine_artifact_sha256=${ORCHESTRATION_ENGINE_ARTIFACT_SHA256:-ac5644352ee053dcfd6bf930a106c1d439af66f3d0f44c2da2cd961b6de1a0dc}' \
    'orchestration_engine_commit=${ORCHESTRATION_ENGINE_COMMIT:-5dd2bc06ee644efa0732cbeb11a65edbae3b445e}' \
    'CATTLE_CATTLE_VERSION=v0.183.323' \
    'cattle-resources-0.183.323.jar'; do
    require_marker "$build_script" "$release_engine_build_marker" \
        SERVER_INCREMENTAL_ENGINE_BUILD_COORDINATE_MISSING
done
if grep -Fq 'ARG ORCHESTRATION_ENGINE_ARTIFACT_SHA256=8483db0b4f2fe71ce527ba97bfb3caea14096ec356124ecef9aa1e7853c8553e' "$release_dockerfile" \
    || grep -Fq 'ARG ORCHESTRATION_ENGINE_COMMIT=268469153c299987bd42e288dd68bb62af91002e' "$release_dockerfile" \
    || grep -Fq 'orchestration_engine_artifact_sha256=${ORCHESTRATION_ENGINE_ARTIFACT_SHA256:-8483db0b4f2fe71ce527ba97bfb3caea14096ec356124ecef9aa1e7853c8553e}' "$build_script" \
    || grep -Fq 'orchestration_engine_commit=${ORCHESTRATION_ENGINE_COMMIT:-268469153c299987bd42e288dd68bb62af91002e}' "$build_script"; then
    echo 'SERVER_ENGINE_0_183_321_COORDINATES_PENDING' >&2
    exit 1
fi
for release_auth_marker in \
    'ARG AUTHENTICATION_SERVICE_RELEASE_BASE_URL=https://github.com/PastureStack/authentication-service/releases/download' \
    'ARG AUTHENTICATION_SERVICE_VERSION=0.4.42' \
    'ARG AUTHENTICATION_SERVICE_COMMIT=5589ef8fda68ae56e1afd64096965d452ee8a17e' \
    'ARG AUTHENTICATION_SERVICE_ARCHIVE_SHA256=f14d22036a0a88d6a8d669700506bba680fc7605bbca2b337e345c5cd71500fb' \
    'ARG AUTHENTICATION_SERVICE_BINARY_SHA256=feaabe4bba85cbe119c98a79a27abb4510401fc051f34d02aa7b48d69bdbe746' \
    'Authentication Service archive may not contain links' \
    'COPY --from=release_artifacts --chmod=0755 /out/authentication-service/authentication-service /usr/bin/authentication-service.real' \
    'ENV PASTURESTACK_AUTHENTICATION_SERVICE_COMMIT=${AUTHENTICATION_SERVICE_COMMIT}' \
    'grep -aF "${marker}" /usr/bin/authentication-service.real'; do
    require_marker "$release_dockerfile" "$release_auth_marker" \
        SERVER_INCREMENTAL_AUTHENTICATION_SERVICE_REPLACEMENT_MISSING
done
for release_auth_build_marker in \
    'authentication_service_version=${AUTHENTICATION_SERVICE_VERSION:-0.4.42}' \
    'authentication_service_commit=${AUTHENTICATION_SERVICE_COMMIT:-5589ef8fda68ae56e1afd64096965d452ee8a17e}' \
    'authentication_service_archive_sha256=${AUTHENTICATION_SERVICE_ARCHIVE_SHA256:-f14d22036a0a88d6a8d669700506bba680fc7605bbca2b337e345c5cd71500fb}' \
    'authentication_service_binary_sha256=${AUTHENTICATION_SERVICE_BINARY_SHA256:-feaabe4bba85cbe119c98a79a27abb4510401fc051f34d02aa7b48d69bdbe746}' \
    '--build-arg "AUTHENTICATION_SERVICE_VERSION=${authentication_service_version}"' \
    'PASTURESTACK_AUTHENTICATION_SERVICE_COMMIT="${authentication_service_commit}"' \
    'feaabe4bba85cbe119c98a79a27abb4510401fc051f34d02aa7b48d69bdbe746  /usr/bin/authentication-service.real' \
    '/usr/bin/authentication-service.real --version | grep -F "0.4.42"'; do
    require_marker "$build_script" "$release_auth_build_marker" \
        SERVER_INCREMENTAL_AUTHENTICATION_SERVICE_BUILD_GATE_MISSING
done
for oidc_policy_contract_marker in \
    'oidcAccessPolicyUpdate' \
    '"requestDigest"' \
    'LocalRecoveryRequired' \
    'MfaConfirmationRequired' \
    'InvalidAllowedIdentity'; do
    require_marker "$release_dockerfile" "$oidc_policy_contract_marker" \
        SERVER_INCREMENTAL_OIDC_POLICY_CONTRACT_MISSING
    require_marker "$build_script" "$oidc_policy_contract_marker" \
        SERVER_INCREMENTAL_OIDC_POLICY_RUNTIME_GATE_MISSING
done
require_marker "$release_dockerfile" \
    'supported.docker.range=~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || >=v29.4.1 <=v29.7.2 || v29.8.0' \
    SERVER_INCREMENTAL_ENGINE_DOCKER_RANGE_MISSING
require_marker "$release_dockerfile" \
    'newest.docker.version=v29.8.0' \
    SERVER_INCREMENTAL_ENGINE_NEWEST_DOCKER_MISSING
require_marker "$build_script" \
    "supported_docker_range='~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || >=v29.4.1 <=v29.7.2 || v29.8.0'" \
    SERVER_INCREMENTAL_BUILD_DOCKER_RANGE_MISSING
require_marker "$build_script" \
    'newest_docker_version=v29.8.0' \
    SERVER_INCREMENTAL_BUILD_NEWEST_DOCKER_MISSING
require_marker "$release_dockerfile" \
    'if [ "${new_web_root}" != "${old_web_root}" ]; then' \
    SERVER_INCREMENTAL_ENGINE_ROOT_REUSE_BRANCH_MISSING
require_marker "$release_dockerfile" \
    'test -d "${new_web_root}/WEB-INF/lib"' \
    SERVER_INCREMENTAL_ENGINE_ROOT_REUSE_VALIDATION_MISSING
if grep -Fq -- 'test "${new_web_root}" != "${old_web_root}"' "$release_dockerfile"; then
    echo 'SERVER_INCREMENTAL_ENGINE_ROOT_REUSE_BLOCKED' >&2
    exit 1
fi

for release_vsphere_marker in \
    'ARG VSPHERE_CLI_BUNDLE_VERSION=0.55.2' \
    'ARG VSPHERE_CLI_BUNDLE_COMMIT=c4b27e87aa0dacce432a2c6108ee0752319e6d5b' \
    'ARG VSPHERE_CLI_BUNDLE_ARCHIVE_SHA256=bebcc1c0275072ac40b5bc9b80f914c40a7f0431fffebc2c06fe34a34c33a57c' \
    'ARG GOVC_BINARY_SHA256=f8c7d82a614655c83ee119e3f170a302a9b35d9ca7efd13bbc226df2d68e5d31' \
    'COPY --from=release_artifacts --chmod=0755 /out/vsphere-cli-bundle/govc /usr/bin/govc' \
    'ENV PASTURESTACK_VSPHERE_CLI_BUNDLE_VERSION=${VSPHERE_CLI_BUNDLE_VERSION}' \
    'ENV PASTURESTACK_GOVC_BINARY_SHA256=${GOVC_BINARY_SHA256}'; do
    require_marker "$release_dockerfile" "$release_vsphere_marker" \
        SERVER_INCREMENTAL_VSPHERE_REPLACEMENT_MISSING
done
require_marker "$build_script" \
    '[[ "$orchestration_engine_release_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]' \
    SERVER_INCREMENTAL_ENGINE_NUMERIC_TAG_GATE_MISSING
require_marker "$build_script" \
    '[[ "$vsphere_cli_bundle_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]' \
    SERVER_INCREMENTAL_VSPHERE_NUMERIC_VERSION_GATE_MISSING

require_marker "$dockerfile" \
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.364@sha256:98ace6dd822f883f2f161f8e7c3191d45cc1f1aef6d2cb6de281cfb1d93237e5' \
    SERVER_API_EXPLORER_PATCH_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'ARG UBUNTU_SNAPSHOT=20260910T100000Z' \
    SERVER_API_EXPLORER_PATCH_UBUNTU_SNAPSHOT_NOT_CURRENT
for bootstrap_dockerfile in "$dockerfile" "$core_dockerfile"; do
    require_marker "$bootstrap_dockerfile" \
        'https://security.ubuntu.com/ubuntu/pool/main/c/ca-certificates/ca-certificates_20260601~26.04.1_all.deb' \
        SERVER_CA_CERTIFICATES_OFFICIAL_BOOTSTRAP_SOURCE_MISSING
    require_marker "$bootstrap_dockerfile" \
        'ADD --checksum=sha256:6077d27c6b6f8b23590cb01ff877ed8c804a67a5442cc32b5a33da10d2bd0e90' \
        SERVER_CA_CERTIFICATES_BOOTSTRAP_HASH_MISSING
done
if grep -Fq 'https://launchpad.net/ubuntu/+archive/primary/+files/' \
    "$dockerfile" "$core_dockerfile"; then
    echo 'SERVER_CA_CERTIFICATES_MUTABLE_BOOTSTRAP_SOURCE_BLOCKED' >&2
    exit 1
fi
if grep -Fq '/pool/main/c/ca-certificates/ca-certificates_20260601~26.04.1_all.deb' \
    "$dockerfile" "$core_dockerfile" && \
   grep -Fq 'https://snapshot.ubuntu.com/ubuntu/' \
    "$dockerfile" "$core_dockerfile"; then
    if grep -F 'https://snapshot.ubuntu.com/ubuntu/' \
        "$dockerfile" "$core_dockerfile" | \
       grep -Fq '/pool/main/c/ca-certificates/'; then
        echo 'SERVER_CA_CERTIFICATES_SNAPSHOT_POOL_BOOTSTRAP_BLOCKED' >&2
        exit 1
    fi
fi
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.428"' \
    SERVER_API_EXPLORER_PATCH_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.428' \
    SERVER_API_EXPLORER_PATCH_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG SUPPORTED_DOCKER_RANGE="~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || >=v29.4.1 <=v29.7.2"' \
    SERVER_DOCKER_29_COMPATIBILITY_RANGE_MISSING
require_marker "$dockerfile" \
    'jar --update --file "${app_config_jar}" --date="${source_date_iso}"' \
    SERVER_DOCKER_SUPPORT_RUNTIME_PATCH_MISSING
require_marker "$build_script" \
    "supported_docker_range='~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || >=v29.4.1 <=v29.7.2 || v29.8.0'" \
    SERVER_DOCKER_SUPPORT_IMAGE_GATE_MISSING
require_marker "$build_script" \
    'newest_docker_version=v29.8.0' \
    SERVER_DOCKER_SUPPORT_IMAGE_GATE_MISSING
require_marker "$dockerfile" \
    'ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE=ghcr.io/pasturestack/load-balancer-service:v0.9.27' \
    SERVER_API_EXPLORER_PATCH_LB_IMAGE_MISSING
require_marker "$dockerfile" \
    'ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE_UUID=docker:ghcr.io/pasturestack/load-balancer-service:v0.9.27' \
    SERVER_API_EXPLORER_PATCH_LB_IMAGE_UUID_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_API_UI_VERSION=1.1.18' \
    SERVER_API_EXPLORER_PATCH_API_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG API_EXPLORER_ARTIFACT_SHA256=92b718c46163018ea40c008ac552911f0eb610647377725405f4046dcd411f2c' \
    SERVER_API_EXPLORER_PATCH_HASH_MISSING
require_marker "$dockerfile" \
    'ARG API_EXPLORER_COMMIT=3b1c39e8a116f58649d94233a384a0362c02b43e' \
    SERVER_API_EXPLORER_PATCH_COMMIT_MISSING
require_marker "$dockerfile" \
    'ARG ORCHESTRATION_ENGINE_RELEASE_TAG=v0.183.298' \
    SERVER_ORCHESTRATION_RELEASE_TAG_MISSING
require_marker "$dockerfile" \
    'ARG ORCHESTRATION_ENGINE_ARTIFACT=orchestration-engine-0.183.298.jar' \
    SERVER_ORCHESTRATION_RELEASE_ARTIFACT_MISSING
require_marker "$dockerfile" \
    'ARG ORCHESTRATION_ENGINE_ARTIFACT_SHA256=cf7cd9c9948cabe242d6e9659f4fa60cdf645ef775b855b9876b765a9386b7f1' \
    SERVER_ORCHESTRATION_RELEASE_HASH_MISSING
require_marker "$dockerfile" \
    'ARG ORCHESTRATION_ENGINE_COMMIT=f95ac014dba0931c62aa5ae3d8cc25f5c5921285' \
    SERVER_ORCHESTRATION_RELEASE_COMMIT_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_CATTLE_VERSION=v0.183.298' \
    SERVER_ORCHESTRATION_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'grep -Fx '\''Implementation-Version: 0.183.298'\'' >/dev/null' \
    SERVER_ORCHESTRATION_MANIFEST_GATE_MISSING
require_marker "$dockerfile" \
    'WEB-INF/lib/hazelcast-5\.7\.4\.jar' \
    SERVER_DISTRIBUTED_CACHE_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    '6b768e6cff9e5281e77ad14e609b69bac6856ecd4469af827f566be95553644c  /tmp/hazelcast.jar' \
    SERVER_DISTRIBUTED_CACHE_RUNTIME_HASH_GATE_MISSING
require_marker "$build_script" \
    'image_orchestration' \
    SERVER_ORCHESTRATION_IMAGE_HASH_GATE_MISSING
require_marker "$dockerfile" \
    'COPY patches/db/core-124.xml /tmp/pasturestack-server-overlays/db/core-124.xml' \
    SERVER_CATALOG_PINNED_COMMIT_OVERLAY_MISSING
require_marker "$dockerfile" \
    'java -cp ".:${new_web_root}/WEB-INF/lib/*" PatchV1GlobalSubscribe verify' \
    SERVER_GLOBAL_SUBSCRIBE_SCHEMA_OVERLAY_MISSING
for hardware_schema_dockerfile in "$dockerfile" "$release_dockerfile"; do
    require_marker "$hardware_schema_dockerfile" \
        'java -cp ".:${new_web_root}/WEB-INF/lib/*" PatchV1GlobalSubscribe verify-hardware' \
        SERVER_FROZEN_V1_HARDWARE_SCHEMA_GATE_MISSING
done
require_marker server/patches/PatchV1GlobalSubscribe.java \
    'FROZEN_V1_HARDWARE_SCHEMAS_OK' \
    SERVER_FROZEN_V1_HARDWARE_SCHEMA_VALIDATOR_MISSING
require_marker "$dockerfile" \
    'test "$(readlink -f /usr/share/cattle/war)" = "${new_web_root}"' \
    SERVER_ORCHESTRATION_EXPLODED_ROOT_BINDING_MISSING
require_marker "$dockerfile" \
    'web_console_stage=/tmp/pasturestack-web-console' \
    SERVER_WEB_CONSOLE_PRESERVATION_STAGE_MISSING
require_marker "$dockerfile" \
    'cp -a "${old_web_root}/${static_path}" "${web_console_stage}/${static_path}"' \
    SERVER_WEB_CONSOLE_PRESERVATION_COPY_MISSING
require_marker "$dockerfile" \
    'test -z "$(find "${web_console_stage}" -type l -print -quit)"' \
    SERVER_WEB_CONSOLE_PRESERVATION_SYMLINK_GATE_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_RELEASE_TAG=1.6.116' \
    SERVER_WEB_CONSOLE_RELEASE_TAG_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_ARTIFACT=web-console-1.6.116.tar.gz' \
    SERVER_WEB_CONSOLE_RELEASE_ARTIFACT_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_ARTIFACT_SHA256=c48a5921476b7f543f56bb12908c75ac76ae5d441aa86a7bbf70b2c98d4faf41' \
    SERVER_WEB_CONSOLE_RELEASE_HASH_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_COMMIT=7c2300ec5342d416382e5bf9442db493e8a648b4' \
    SERVER_WEB_CONSOLE_RELEASE_COMMIT_MISSING
require_marker "$dockerfile" \
    'tar --no-same-owner --no-same-permissions -xzf "${archive}" -C "${stage}"' \
    SERVER_WEB_CONSOLE_SAFE_EXTRACTION_MISSING
require_marker "$dockerfile" \
    'grep -aF "${marker}" "${ui_entry}"' \
    SERVER_WEB_CONSOLE_AUDIT_FILTER_MARKER_GATE_MISSING
require_marker "$dockerfile" \
    'ui/utils/bootstrap-runtime' \
    SERVER_WEB_CONSOLE_BOOTSTRAP_MODULE_GATE_MISSING
require_marker "$dockerfile" \
    'window.bootstrap=' \
    SERVER_WEB_CONSOLE_BOOTSTRAP_GLOBAL_GATE_MISSING
require_marker "$dockerfile" \
    'ember-basic-dropdown-wormhole' \
    SERVER_WEB_CONSOLE_DROPDOWN_DESTINATION_GATE_MISSING
require_marker "$dockerfile" \
    'basic-dropdown-wormhole' \
    SERVER_WEB_CONSOLE_DROPDOWN_COMPONENT_GATE_MISSING
require_marker "$dockerfile" \
    'audit-date-picker' \
    SERVER_WEB_CONSOLE_AUDIT_CALENDAR_GATE_MISSING
require_marker "$dockerfile" \
    'service-log-filter-panel' \
    SERVER_WEB_CONSOLE_SERVICE_LOG_FILTER_GATE_MISSING
require_marker "$dockerfile" \
    'service.instance.restart' \
    SERVER_WEB_CONSOLE_SERVICE_RESTART_EVENT_GATE_MISSING
require_marker "$dockerfile" \
    'footer .footer-dropdown .dropdown-menu' \
    SERVER_WEB_CONSOLE_FOOTER_MENU_BOUNDARY_GATE_MISSING
require_marker "$dockerfile" \
    '.form-resources .resource-host-guidance' \
    SERVER_WEB_CONSOLE_RESOURCE_GUIDANCE_GATE_MISSING
require_marker "$dockerfile" \
    '"formResources.addUlimit":"新增限制"' \
    SERVER_WEB_CONSOLE_ADD_ULIMIT_TRANSLATION_GATE_MISSING
require_marker "$build_script" \
    'grep -F "\"formResources.addUlimit\":\"新增限制\""' \
    SERVER_WEB_CONSOLE_BUILD_ADD_ULIMIT_TRANSLATION_GATE_MISSING
require_marker "$build_script" \
    'pasturestack-compose version ${PASTURESTACK_COMPOSE_EXECUTOR_VERSION}' \
    SERVER_COMPOSE_EXECUTOR_CONTAINER_VERSION_GATE_MISSING
require_marker "$dockerfile" \
    'table.audit-log-results-table[data-resizable-columns=true]:not(.table-column-measuring) > thead > th.audit-log-auth-ip-heading' \
    SERVER_WEB_CONSOLE_AUDIT_AUTH_IP_HEADER_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '篩選稽核日誌'" \
    SERVER_WEB_CONSOLE_ZH_TW_FILTER_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '篩選服務日誌'" \
    SERVER_WEB_CONSOLE_ZH_TW_SERVICE_FILTER_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '開始時間必須早於結束時間'" \
    SERVER_WEB_CONSOLE_ZH_TW_RANGE_GATE_MISSING
require_marker "$dockerfile" \
    'for locale in de-de fa-ir fil-ph fr-fr hu-hu ja-jp ko-kr pt-br ru-ru uk-ua zh-hans zh-tw' \
    SERVER_WEB_CONSOLE_ALL_LOCALE_FILTER_GATE_MISSING
require_marker "$dockerfile" \
    '"auditLogsPage.filterBuilder.title":"Filter audit logs"' \
    SERVER_WEB_CONSOLE_ENGLISH_FILTER_REJECTION_MISSING
require_marker "$dockerfile" \
    '"auditLogsPage.filterBuilder.timeDialog.calendar.today":"Today"' \
    SERVER_WEB_CONSOLE_LOCALIZED_CALENDAR_GATE_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=${WEB_CONSOLE_RELEASE_TAG}' \
    SERVER_WEB_CONSOLE_RUNTIME_VERSION_MISSING
require_marker "$build_script" \
    'PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256="${web_console_artifact_sha256}"' \
    SERVER_WEB_CONSOLE_RUNTIME_HASH_GATE_MISSING
require_marker "$build_script" \
    'test "$(cat "${web_root}/VERSION.txt")" = "1.6.136"' \
    SERVER_WEB_CONSOLE_RUNTIME_VERSION_GATE_MISSING
require_marker "$build_script" \
    'grep -aF "dropdown-menu project-menu" "${ui_entry}"' \
    SERVER_WEB_CONSOLE_SWITCHER_MARKUP_GATE_MISSING
require_marker "$build_script" \
    '! grep -aF "dropdown-menu-end project-menu" "${ui_entry}"' \
    SERVER_WEB_CONSOLE_STALE_SWITCHER_ANCHOR_GATE_MISSING
require_marker "$build_script" \
    'max-width: calc(100vw - 68px);' \
    SERVER_WEB_CONSOLE_SWITCHER_VIEWPORT_GATE_MISSING
require_marker "$build_script" \
    'overflow-wrap: anywhere;' \
    SERVER_WEB_CONSOLE_SWITCHER_WRAP_GATE_MISSING
require_marker "$build_script" \
    'grep -Fx "  left: 0;"' \
    SERVER_WEB_CONSOLE_LTR_SWITCHER_ANCHOR_GATE_MISSING
require_marker "$build_script" \
    'grep -Fx "  right: 0;"' \
    SERVER_WEB_CONSOLE_RTL_SWITCHER_ANCHOR_GATE_MISSING
require_marker "$build_script" \
    'html[dir=rtl] .fail-whale .error {' \
    SERVER_WEB_CONSOLE_RTL_FAIL_DIRECTION_GATE_MISSING
require_marker "$build_script" \
    'test "$(/usr/bin/compose-executor.real --version)" =' \
    SERVER_COMPOSE_EXECUTOR_RUNTIME_VERSION_GATE_MISSING
require_marker "$build_script" \
    'grep -F "開始時間必須早於結束時間"' \
    SERVER_WEB_CONSOLE_RUNTIME_ZH_TW_RANGE_GATE_MISSING
require_marker "$build_script" \
    'for locale in de-de fa-ir fil-ph fr-fr hu-hu ja-jp ko-kr pt-br ru-ru uk-ua zh-hans zh-tw' \
    SERVER_WEB_CONSOLE_RUNTIME_ALL_LOCALE_FILTER_GATE_MISSING
require_marker "$build_script" \
    'auditLogsPage.filterBuilder.title\":\"Filter audit logs' \
    SERVER_WEB_CONSOLE_RUNTIME_ENGLISH_FILTER_REJECTION_MISSING
require_marker "$build_script" \
    'grep -aF "ui/utils/bootstrap-runtime" "${ui_entry}"' \
    SERVER_WEB_CONSOLE_RUNTIME_MODULE_GATE_MISSING
require_marker "$build_script" \
    'grep -aF "window.bootstrap=" "${ui_entry}"' \
    SERVER_WEB_CONSOLE_RUNTIME_GLOBAL_GATE_MISSING
if grep -F 'grep -aF "bs.collapse"' "$build_script" >/dev/null; then
    echo SERVER_WEB_CONSOLE_DORMANT_VENDOR_RUNTIME_GATE_PRESENT
    exit 1
fi
require_marker "$build_script" \
    'grep -F "pasturestack-catalog-pinned-commit"' \
    SERVER_CATALOG_PINNED_COMMIT_IMAGE_GATE_MISSING
require_marker "$release_dockerfile" \
    'ENV PASTURESTACK_CATALOG_COMMIT=e082033ba3c12b5f5cfcae93ff1d6f50d5440d07' \
    SERVER_CATALOG_VERSION_LABEL_COMMIT_MISSING
require_marker "$release_dockerfile" \
    '"pinnedCommit":"e082033ba3c12b5f5cfcae93ff1d6f50d5440d07"' \
    SERVER_CATALOG_VERSION_LABEL_URL_MISSING
require_marker "$build_script" \
    'PASTURESTACK_CATALOG_COMMIT=e082033ba3c12b5f5cfcae93ff1d6f50d5440d07' \
    SERVER_CATALOG_VERSION_LABEL_IMAGE_GATE_MISSING
for previous_release_marker in \
    '# Server v1.6.462' \
    '`5cba85d3ab954c416b86910f760f987ec2bfc526`' \
    '`a278904a10ce757510ed516507bd3926b02bab42a52a27bd153ff5e94e2998aa`' \
    '`222552c4b1fad095a5b55756cdca8e02b088ba04`' \
    '`74ac55939399873eeb9ab0813ca193e373ccf2bdde3e3d884d5491b4d0b7608e`' \
    '`082af08ce90d7cb9b043452c177c8f60a0c36d52f0797e24baaa37d7c1e087b4`' \
    '`5589ef8fda68ae56e1afd64096965d452ee8a17e`' \
    '`f14d22036a0a88d6a8d669700506bba680fc7605bbca2b337e345c5cd71500fb`' \
    '`feaabe4bba85cbe119c98a79a27abb4510401fc051f34d02aa7b48d69bdbe746`' \
    '`e082033ba3c12b5f5cfcae93ff1d6f50d5440d07`' \
    '## Atomic shared Default membership' \
    '## Zero-environment and account administration' \
    '## Permission-matrix boundary' \
    '## Immutable component coordinates' \
    '## Verification and SBOM identity' \
    '100-iteration deterministic lock barrier' \
    'exact sets' \
    'canonical OCI purl' \
    'display-only' \
    '`noaccess`' \
    '536 passing browser tests'; do
    require_marker "$previous_release_notes" "$previous_release_marker" \
        SERVER_PREVIOUS_RELEASE_NOTES_IDENTITY_MISSING
done
for current_release_marker in \
    '# Server v1.6.471' \
    'Orchestration Engine `v0.183.323`' \
    'Web Console' \
    '`1.6.136`' \
    'left-to-right and right-to-left' \
    'Persian `/fail`' \
    'fresh' \
    'A 403 or 404 falls back' \
    '401 and 5xx' \
    'stale cached records cannot keep a revoked environment visible' \
    'preserves the active environment and loaded schema' \
    'permitted direct URL still works' \
    'former selection until reinitialization' \
    'Server checks project membership on each request' \
    'Rollback selects the preserved'; do
    require_marker "$current_release_notes" "$current_release_marker" \
        SERVER_CURRENT_RELEASE_NOTES_IDENTITY_MISSING
done
for current_readme_marker in \
    'Server [`v1.6.471`](https://github.com/PastureStack/server/releases/tag/v1.6.471)' \
    'Authentication Service `0.4.42`, and Web Console `1.6.136`' \
    'left-to-right and right-to-left' \
    'Persian failure-page direction' \
    'revoked entries disappear after refresh' \
    'An already open view updates on' \
    '[v1.6.471 notes](docs/releases/server-1.6.471.md)' \
    'ghcr.io/pasturestack/server:v1.6.471'; do
    require_marker README.md "$current_readme_marker" \
        SERVER_CURRENT_README_IDENTITY_MISSING
done
require_marker docs/README.md \
    '[Server v1.6.471](releases/server-1.6.471.md)' \
    SERVER_CURRENT_DOC_INDEX_MISSING
require_marker docs/hosts/README.md \
    'PastureStack Server `v1.6.471` recognizes' \
    SERVER_CURRENT_HOST_DOC_MISSING
require_marker docs/performance/README.md \
    'image: ghcr.io/pasturestack/server:v1.6.471' \
    SERVER_CURRENT_PERFORMANCE_DOC_MISSING
for current_compatibility_marker in \
    'The current `v1.6.471` assembly consumes Orchestration Engine `v0.183.323`' \
    'Engine `v0.183.321` excludes inactive or removed project-member rows' \
    'Engine `v0.183.320` checks project-member collection requests' \
    'Engine `v0.183.319` makes shared-Default reconciliation atomic.' \
    'single `adminProject` Default' \
    'effective per-project schema' \
    'local administrator recovery path' \
    'Web Console package `1.6.136`' \
    'Web Console `1.6.135` requests the full active environment collection' \
    'Web Console `1.6.136` bounds the environment-switcher menu' \
    'revalidates a stored environment selection' \
    '404 falls back to an available environment' \
    '401 and 5xx errors remain visible' \
    'cached records cannot keep a revoked environment' \
    'preserves the active environment and its loaded schema' \
    'a permitted direct URL still works' \
    'membership on each request' \
    'Web Console `1.6.133` applies the active project' \
    'shared-Default reconciliation atomic' \
    'valid empty state' \
    'Authentication Service `v0.4.42`' \
    'RSVP-based adapter' \
    'standard `Authorization: Bearer` value' \
    'schema creation' \
    'stable deduplicated order' \
    '`unrestricted` is represented with an empty allowlist' \
    'Legacy provider settings are imported only'; do
    require_marker COMPATIBILITY.md "$current_compatibility_marker" \
        SERVER_CURRENT_COMPATIBILITY_CONTRACT_MISSING
done
require_marker "$dockerfile" \
    'COPY --chmod=0755 patches/websocket-proxy-wrapper.sh /usr/bin/websocket-proxy' \
    SERVER_WEBSOCKET_PROXY_ROUTING_WRAPPER_INSTALL_MISSING
require_marker "$build_script" \
    'websocket_wrapper_sha256=$(sha256sum server/patches/websocket-proxy-wrapper.sh' \
    SERVER_WEBSOCKET_PROXY_ROUTING_WRAPPER_HASH_GATE_MISSING
require_marker "$dockerfile" \
    'ARG GO_BUILDER_IMAGE=golang:1.27.0-bookworm@sha256:ded31c68586d2e49e760acc2e65a884b23d032e9bbbed0ae0c55abd3fcaf4452' \
    SERVER_RUNTIME_GO_BUILDER_NOT_CURRENT
require_marker "$dockerfile" \
    'ENV PASTURESTACK_RUNTIME_GO_VERSION=1.27.0' \
    SERVER_RUNTIME_GO_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_UBUNTU_SECURITY_REFRESH=2026-09-10' \
    SERVER_UBUNTU_SECURITY_REFRESH_MISSING
require_marker "$dockerfile" \
    'ARG UBUNTU_SECURITY_IMAGE=ubuntu:26.04@sha256:2260313b31c8c011cd2eebe728008efac1b3982be73eb71348ea2648d2c0e09b' \
    SERVER_UBUNTU_SECURITY_IMAGE_NOT_PINNED
require_marker "$dockerfile" \
    'ARG GLIBC_PACKAGE_VERSION=2.43-2ubuntu2.4' \
    SERVER_GLIBC_PACKAGE_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG PERL_PACKAGE_VERSION=5.40.1-7ubuntu0.3' \
    SERVER_PERL_PACKAGE_VERSION_MISSING
require_marker "$dockerfile" \
    'COPY --from=ubuntu_security_packages /out/tar /usr/bin/tar' \
    SERVER_UBUNTU_SECURITY_BOOTSTRAP_TAR_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_GLIBC_CVE_2026_18374_FIX=not-in-execute-path' \
    SERVER_GLIBC_FIX_AUTHORITY_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_GLIBC_PACKAGE_VERSION=${GLIBC_PACKAGE_VERSION}' \
    SERVER_GLIBC_IMAGE_VERSION_ENV_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_PERL_PACKAGE_VERSION=${PERL_PACKAGE_VERSION}' \
    SERVER_PERL_IMAGE_VERSION_ENV_MISSING
for official_package_marker in \
    '"curl=${CURL_PACKAGE_VERSION}"' \
    '"libcurl3t64-gnutls=${CURL_PACKAGE_VERSION}"' \
    '"libcurl4t64=${CURL_PACKAGE_VERSION}"' \
    '"libc6=${GLIBC_PACKAGE_VERSION}"' \
    '"libc-bin=${GLIBC_PACKAGE_VERSION}"' \
    '"libc-gconv-modules-extra=${GLIBC_PACKAGE_VERSION}"' \
    '"libperl5.40=${PERL_PACKAGE_VERSION}"' \
    '"perl=${PERL_PACKAGE_VERSION}"' \
    '"perl-base=${PERL_PACKAGE_VERSION}"' \
    '"perl-modules-5.40=${PERL_PACKAGE_VERSION}"'; do
    require_marker "$dockerfile" "$official_package_marker" \
        SERVER_UBUNTU_OFFICIAL_SECURITY_PACKAGE_GATE_MISSING
done
for security_dockerfile in "$dockerfile"; do
    require_marker "$security_dockerfile" \
        'ARG UBUNTU_SNAPSHOT=20260910T100000Z' \
        SERVER_UBUNTU_SECURITY_SNAPSHOT_MISSING
    require_marker "$security_dockerfile" \
        'ARG CURL_PACKAGE_VERSION=8.18.0-1ubuntu2.5' \
        SERVER_UBUNTU_CURL_PACKAGE_VERSION_MISSING
    require_marker "$security_dockerfile" \
        'ARG GLIBC_PACKAGE_VERSION=2.43-2ubuntu2.4' \
        SERVER_UBUNTU_GLIBC_PACKAGE_VERSION_MISSING
    require_marker "$security_dockerfile" \
        'ARG PERL_PACKAGE_VERSION=5.40.1-7ubuntu0.3' \
        SERVER_UBUNTU_PERL_PACKAGE_VERSION_MISSING
    require_marker "$security_dockerfile" \
        'ENV PASTURESTACK_CURL_PACKAGE_VERSION=${CURL_PACKAGE_VERSION}' \
        SERVER_CURL_IMAGE_VERSION_ENV_MISSING
    require_marker "$security_dockerfile" \
        'ENV PASTURESTACK_GLIBC_CVE_2026_18374_FIX=not-in-execute-path' \
        SERVER_GLIBC_EXECUTION_PATH_AUTHORITY_MISSING
    require_marker "$security_dockerfile" \
        'dpkg -i packages/*.deb' \
        SERVER_UBUNTU_SECURITY_FINAL_INSTALL_MISSING
done
if grep -Eq 'ubuntu_security_packages|pasturestack-ubuntu-security|UBUNTU_SNAPSHOT' \
    "$release_dockerfile"; then
    echo 'SERVER_INCREMENTAL_RELEASE_REBUILDS_UNCHANGED_UBUNTU_PACKAGES' >&2
    exit 1
fi
for release_curl_security_marker in \
    'FROM ${UBUNTU_SECURITY_IMAGE} AS curl_security_packages' \
    'ARG UBUNTU_CURL_SNAPSHOT=20260926T000000Z' \
    'ARG CURL_PACKAGE_VERSION=8.18.0-1ubuntu2.7' \
    'Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg' \
    'Acquire::AllowInsecureRepositories "false"' \
    'APT::Get::AllowUnauthenticated "false"' \
    'COPY --from=curl_security_packages /out/ /tmp/pasturestack-curl-security/' \
    'sha256sum -c SHA256SUMS' \
    'dpkg -i packages/*.deb' \
    'test "$(dpkg-query -W -f=' \
    'ENV PASTURESTACK_CURL_SECURITY_SNAPSHOT=${UBUNTU_CURL_SNAPSHOT}'; do
    require_marker "$release_dockerfile" "$release_curl_security_marker" \
        SERVER_INCREMENTAL_CURL_SECURITY_REFRESH_MISSING
done
require_marker "$build_script" \
    'PASTURESTACK_CURL_SECURITY_SNAPSHOT=20260926T000000Z' \
    SERVER_CURL_IMAGE_SNAPSHOT_GATE_MISSING
require_marker "$build_script" \
    'PASTURESTACK_CURL_PACKAGE_VERSION=8.18.0-1ubuntu2.7' \
    SERVER_CURL_IMAGE_VERSION_GATE_MISSING
require_marker "$build_script" \
    'PASTURESTACK_GLIBC_PACKAGE_VERSION=2.43-2ubuntu2.4' \
    SERVER_GLIBC_IMAGE_VERSION_GATE_MISSING
require_marker "$build_script" \
    'PASTURESTACK_PERL_PACKAGE_VERSION=5.40.1-7ubuntu0.3' \
    SERVER_PERL_IMAGE_VERSION_GATE_MISSING
for runtime_reachability_marker in \
    '/usr/share/cattle/cattle.sh' \
    '/usr/share/cattle/cattle.jar' \
    '/service/mysql/run' \
    'pack_ip_mreq_source|Storable|SX_HOOK|,ccs=' \
    'A Server runtime entrypoint reaches a reviewed Perl or glibc fopen mode vulnerability'; do
    require_marker "$build_script" "$runtime_reachability_marker" \
        SERVER_RUNTIME_REACHABILITY_GATE_MISSING
done
require_marker "$release_notes" \
    'CVE-2026-8932' \
    SERVER_RELEASE_NOTES_CURL_FIX_MISSING
require_marker "$release_notes" \
    '2.43-2ubuntu2.4' \
    SERVER_RELEASE_NOTES_GLIBC_FIX_MISSING
require_marker "$release_notes" \
    'needing evaluation for Resolute' \
    SERVER_RELEASE_NOTES_GLIBC_APPLICABILITY_BOUNDARY_MISSING
require_marker "$dockerfile" \
    'coreutils-from-gnu coreutils-from-uutils- rust-coreutils-' \
    SERVER_GNU_COREUTILS_SWITCH_MISSING
require_marker "$dockerfile" \
    '! dpkg-query -W rust-coreutils' \
    SERVER_RUST_COREUTILS_ABSENCE_GATE_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_COREUTILS_PROVIDER=gnu' \
    SERVER_COREUTILS_PROVIDER_IDENTITY_MISSING
require_marker "$dockerfile" \
    'ARG COREUTILS_SHA256=2033b8a3049c06bff49a9e3cea72bdf4683bcd0cbeb975211dd56dbaf8b736ae' \
    SERVER_COREUTILS_SOURCE_HASH_MISSING
require_marker "$dockerfile" \
    'https://ftp.gnu.org/gnu/coreutils/coreutils-${COREUTILS_VERSION}.tar.gz' \
    SERVER_COREUTILS_PRIMARY_SOURCE_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_COREUTILS_UNIQ_VERSION=9.11' \
    SERVER_COREUTILS_UNIQ_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG COREUTILS_UNIQ_FIX_COMMIT=d64e35a8a4c0e4608321433e0d84d917e4e36371' \
    SERVER_COREUTILS_UNIQ_FIX_COMMIT_MISSING
require_marker "$dockerfile" \
    'ARG COREUTILS_UNIQ_PATCH_SHA256=7c0a1b74325caf05fe0021b26dcde6b19560ea04388f18386cacc4e8bb436efd' \
    SERVER_COREUTILS_UNIQ_FIX_HASH_MISSING
require_marker "$dockerfile" \
    'git apply --check --no-index /src/coreutils-CVE-2026-56391.patch' \
    SERVER_COREUTILS_UNIQ_FIX_APPLICATION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_COREUTILS_UNIQ_FIX=d64e35a8a4c0e4608321433e0d84d917e4e36371' \
    SERVER_COREUTILS_UNIQ_FIX_IDENTITY_MISSING
test "$(sha256sum "$coreutils_patch" | awk '{print $1}')" = \
    7c0a1b74325caf05fe0021b26dcde6b19560ea04388f18386cacc4e8bb436efd
require_marker "$coreutils_patch" \
    'Upstream-Commit: d64e35a8a4c0e4608321433e0d84d917e4e36371' \
    SERVER_COREUTILS_UNIQ_PATCH_PROVENANCE_MISSING
require_marker "$release_notes" \
    'd64e35a8a4c0e4608321433e0d84d917e4e36371' \
    SERVER_RELEASE_NOTES_UNIQ_FIX_MISSING
require_marker "$release_notes" \
    'unmatched vulnerability at any severity remains a release blocker.' \
    SERVER_RELEASE_NOTES_VEX_BOUNDARY_MISSING
require_marker "$release_notes" \
    'CVE-2026-75803' \
    SERVER_RELEASE_NOTES_OPENSSL_FIX_MISSING
require_marker "$release_notes" \
    'CVE-2026-53910' \
    SERVER_RELEASE_NOTES_DIFF3_CLOSURE_MISSING
require_marker "$dockerfile" \
    'ARG NODE_AGENT_VERSION=0.13.27' \
    SERVER_HARDWARE_AGENT_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG NODE_AGENT_LINUX_ARTIFACT_SHA256=0cbf93ef6f90db8c5f6b8cf7d63c99f452b8fc43e93097a21cdb5bcc3007d475' \
    SERVER_HARDWARE_AGENT_LINUX_HASH_MISSING
require_marker "$dockerfile" \
    'ARG NODE_AGENT_WINDOWS_ARTIFACT_SHA256=b6a56f8833c31bc224b7baf20ceb1a252c027021efbe6265c1906f8478d7c2fa' \
    SERVER_HARDWARE_AGENT_WINDOWS_HASH_MISSING
require_marker "$dockerfile" \
    'export CATTLE_AGENT_PACKAGE_PYTHON_AGENT_URL=/usr/share/cattle/artifacts/${agent_linux}' \
    SERVER_HARDWARE_AGENT_EFFECTIVE_URL_MISSING
require_marker server/build-api-explorer-patch-image.sh \
    'test "$CATTLE_AGENT_PACKAGE_PYTHON_AGENT_URL" = /usr/share/cattle/artifacts/node-agent-0.13.27.tar.gz' \
    SERVER_HARDWARE_AGENT_EFFECTIVE_URL_NOT_VERIFIED
require_marker "$dockerfile" \
    'ARG ZLIB_SHA256=bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16' \
    SERVER_ZLIB_SOURCE_HASH_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_ZLIB_VERSION=1.3.2' \
    SERVER_ZLIB_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG OPENSSL_VERSION=3.5.8' \
    SERVER_OPENSSL_SOURCE_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG OPENSSL_SHA256=a8f84a39918ec6415ce765d9b429d313ba97b8143169c172e734b9514464f5b2' \
    SERVER_OPENSSL_SOURCE_HASH_MISSING
require_marker "$dockerfile" \
    'make test TESTS=test_evp_extra' \
    SERVER_OPENSSL_TARGETED_TEST_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_OPENSSL_VERSION=3.5.8' \
    SERVER_OPENSSL_RUNTIME_IDENTITY_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_DIFF3_HARDENING=removed' \
    SERVER_DIFF3_REMOVAL_IDENTITY_MISSING
require_marker "$build_script" \
    'openssl version | grep -F "OpenSSL 3.5.8 25 Aug 2026"' \
    SERVER_OPENSSL_IMAGE_VERSION_GATE_MISSING
require_marker "$build_script" \
    'test "$(openssl version -d)" = "OPENSSLDIR: \"/usr/lib/ssl\""' \
    SERVER_OPENSSL_IMAGE_OPENSSLDIR_GATE_MISSING
require_marker "$build_script" \
    'test "$(openssl version -e)" = "ENGINESDIR: \"/usr/lib/x86_64-linux-gnu/engines-3\""' \
    SERVER_OPENSSL_IMAGE_ENGINESDIR_GATE_MISSING
require_marker "$build_script" \
    'test "$(openssl version -m)" = "MODULESDIR: \"/usr/lib/x86_64-linux-gnu/ossl-modules\""' \
    SERVER_OPENSSL_IMAGE_MODULESDIR_GATE_MISSING
require_marker "$build_script" \
    'ldd /usr/bin/curl | grep -F "/usr/lib/x86_64-linux-gnu/libssl.so.3"' \
    SERVER_OPENSSL_CURL_LINKAGE_GATE_MISSING
require_marker "$dockerfile" \
    'version_at_least openssl 3.5.5-1ubuntu3.4' \
    SERVER_OPENSSL_FIXED_VERSION_GATE_MISSING
for fixed_package_gate in \
    'version_at_least gnu-coreutils 9.7-3ubuntu2.1' \
    'version_at_least bsdutils 1:2.41.3-3ubuntu2.2' \
    'version_at_least libblkid1 2.41.3-3ubuntu2.2' \
    'version_at_least libmount1 2.41.3-3ubuntu2.2' \
    'version_at_least libsmartcols1 2.41.3-3ubuntu2.2' \
    'version_at_least libuuid1 2.41.3-3ubuntu2.2' \
    'version_at_least login 1:4.16.0-2+really2.41.3-3ubuntu2.2' \
    'version_at_least mount 2.41.3-3ubuntu2.2' \
    'version_at_least util-linux 2.41.3-3ubuntu2.2'; do
    require_marker "$dockerfile" "$fixed_package_gate" \
        SERVER_UBUNTU_FIXED_VERSION_GATE_MISSING
    require_marker "$build_script" "$fixed_package_gate" \
        SERVER_UBUNTU_RUNTIME_VERSION_GATE_MISSING
done
require_marker "$dockerfile" \
    'ENV PASTURESTACK_SSH_CLIENT_HARDENING=client-removed' \
    SERVER_SSH_CLIENT_REMOVAL_IDENTITY_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_PRIVILEGED_MOUNT_HELPERS=removed' \
    SERVER_MOUNT_HELPER_REMOVAL_IDENTITY_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_CONTAINER_SOURCE_BUILD_MODE=removed' \
    SERVER_SOURCE_BUILD_MODE_REMOVAL_IDENTITY_MISSING
for removed_path in \
    /usr/bin/eu-readelf \
    /usr/bin/eu-strip \
    /usr/bin/diff3 \
    /usr/bin/getfattr \
    /usr/bin/gpgv \
    /usr/bin/p11-kit \
    /usr/bin/setfattr \
    /usr/bin/unexpand \
    /usr/lib/git-core/git-http-push \
    /usr/lib/x86_64-linux-gnu/libexpat.so.1 \
    /usr/lib/x86_64-linux-gnu/libexpat.so.1.11.2 \
    /usr/libexec/p11-kit/p11-kit-server \
    /etc/login.defs \
    /etc/subgid \
    /etc/subuid; do
    require_marker "$dockerfile" "$removed_path" \
        SERVER_RUNTIME_VULNERABLE_PATH_REMOVAL_MISSING
    require_marker "$build_script" "$removed_path" \
        SERVER_RUNTIME_VULNERABLE_PATH_VALIDATION_MISSING
done
require_marker "$build_script" \
    'find /usr/bin /usr/sbin /usr/share/cattle -xdev -type f -perm /0111 -print0' \
    SERVER_RUNTIME_LIBGCRYPT_EXECUTABLE_AUDIT_MISSING
require_marker "$build_script" \
    'find /run -xdev -type s -path "*p11-kit*"' \
    SERVER_RUNTIME_P11_KIT_SOCKET_AUDIT_MISSING
require_marker "$dockerfile" \
    '/usr/lib/systemd/systemd-journald' \
    SERVER_JOURNALD_REMOVAL_GATE_MISSING
require_marker "$dockerfile" \
    '/usr/share/cattle/install_cattle_binaries' \
    SERVER_RUNTIME_INSTALLER_REMOVAL_GATE_MISSING
require_marker "$cattle_script" \
    'CATTLE_MASTER source-build mode has been removed' \
    SERVER_SOURCE_BUILD_MODE_REJECTION_MISSING
require_marker "$dockerfile" \
    "git --version | grep -Fx 'git version 2.53.0'" \
    SERVER_CATALOG_GIT_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'test "$(git --version)" = "git version 2.53.0"' \
    SERVER_CATALOG_GIT_IMAGE_VALIDATION_MISSING
require_marker "$dockerfile" \
    "! ldconfig -p | grep -F 'libexpat.so'" \
    SERVER_RUNTIME_EXPAT_LINKER_GATE_MISSING
require_marker "$build_script" \
    '! ldconfig -p | grep -Fq "libexpat.so"' \
    SERVER_RUNTIME_EXPAT_IMAGE_VALIDATION_MISSING
if grep -Eq '(^|[[:space:]])(git clone|git -C|apt-get install|tar xzf)([[:space:]]|$)' "$cattle_script"; then
    echo 'SERVER_SOURCE_BUILD_TOOLING_REMAINS' >&2
    exit 1
fi
while IFS='|' read -r marker code; do
    require_marker "$dockerfile" "$marker" "$code"
done <<'EOF'
ARG AUTHENTICATION_SERVICE_VERSION=0.4.42|SERVER_AUTHENTICATION_SERVICE_VERSION_MISSING
ARG AUTHENTICATION_SERVICE_BINARY_SHA256=feaabe4bba85cbe119c98a79a27abb4510401fc051f34d02aa7b48d69bdbe746|SERVER_AUTHENTICATION_SERVICE_HASH_MISSING
ARG CATALOG_SERVICE_VERSION=0.20.11|SERVER_CATALOG_SERVICE_VERSION_MISSING
ARG CATALOG_SERVICE_BINARY_SHA256=ccfc75831678df31f58b327b3177da6f40d31603ab329af7bdf700a8513ea329|SERVER_CATALOG_SERVICE_HASH_MISSING
ARG COMPOSE_EXECUTOR_VERSION=0.14.36|SERVER_COMPOSE_EXECUTOR_VERSION_MISSING
ARG COMPOSE_EXECUTOR_BINARY_SHA256=1f542ee2dd76c7af06bc5f056c381d7e77aecaeac40f8d897df6df24a9902c0d|SERVER_COMPOSE_EXECUTOR_HASH_MISSING
ARG HOST_PROVISIONER_VERSION=0.39.7|SERVER_HOST_PROVISIONER_VERSION_MISSING
ARG HOST_PROVISIONER_BINARY_SHA256=bce26b98133d3f5d4ecaddba26179ed8e14e5b260b38dee5f9e4383cbfbc855a|SERVER_HOST_PROVISIONER_HASH_MISSING
ARG SECRET_DELIVERY_API_VERSION=0.3.1|SERVER_SECRET_DELIVERY_API_VERSION_MISSING
ARG SECRET_DELIVERY_API_BINARY_SHA256=fbdd12862e1cfe3c957f492ae81c4c1c5658357502bd322febbbe209496929be|SERVER_SECRET_DELIVERY_API_HASH_MISSING
ARG USAGE_TELEMETRY_AGENT_VERSION=0.4.1|SERVER_USAGE_TELEMETRY_AGENT_VERSION_MISSING
ARG USAGE_TELEMETRY_AGENT_BINARY_SHA256=f18ed969b8b5959293fdbcd55d2e28846372ab87c9348fbb315a9a490bf85ad4|SERVER_USAGE_TELEMETRY_AGENT_HASH_MISSING
ARG WEBHOOK_AUTOMATION_SERVICE_VERSION=0.10.1|SERVER_WEBHOOK_AUTOMATION_SERVICE_VERSION_MISSING
ARG WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256=07e807c3f66e7e75e7a45073eabbd041a74b5727e315aee96f00e5b6a801ccc5|SERVER_WEBHOOK_AUTOMATION_SERVICE_HASH_MISSING
ARG WEBSOCKET_PROXY_VERSION=0.23.14|SERVER_WEBSOCKET_PROXY_VERSION_MISSING
ARG WEBSOCKET_PROXY_COMMIT=3b5788bdc52f4edab0097a3d97afccf138c64089|SERVER_WEBSOCKET_PROXY_COMMIT_MISSING
ARG WEBSOCKET_PROXY_ARCHIVE_SHA256=c55108c3dbfd8e6579fc768a1988920db83c6f605ca1284b60edf92ae8d0160e|SERVER_WEBSOCKET_PROXY_ARCHIVE_HASH_MISSING
ARG WEBSOCKET_PROXY_BINARY_SHA256=efd0c78779a620b4b0f74a10eb3f3edd8886e8d23f22dc4624d8e9971085a26d|SERVER_WEBSOCKET_PROXY_HASH_MISSING
ARG VSPHERE_CLI_BUNDLE_VERSION=0.55.2|SERVER_VSPHERE_CLI_BUNDLE_VERSION_MISSING
ARG VSPHERE_CLI_BUNDLE_COMMIT=c4b27e87aa0dacce432a2c6108ee0752319e6d5b|SERVER_VSPHERE_CLI_BUNDLE_COMMIT_MISSING
ARG VSPHERE_CLI_BUNDLE_ARCHIVE_SHA256=bebcc1c0275072ac40b5bc9b80f914c40a7f0431fffebc2c06fe34a34c33a57c|SERVER_VSPHERE_CLI_BUNDLE_ARCHIVE_HASH_MISSING
ARG GOVC_BINARY_SHA256=f8c7d82a614655c83ee119e3f170a302a9b35d9ca7efd13bbc226df2d68e5d31|SERVER_GOVC_HASH_MISSING
EOF
require_marker "$dockerfile" \
    'tar --no-same-owner --no-same-permissions -xzf' \
    SERVER_API_EXPLORER_PATCH_SAFE_EXTRACTION_MISSING
require_marker "$dockerfile" \
    'test ! -e "${stage}/js/bootstrap.js"' \
    SERVER_API_EXPLORER_PATCH_BOOTSTRAP_JS_REJECTION_MISSING
require_marker "$dockerfile" \
    'pasturestack:modal:shown' \
    SERVER_API_EXPLORER_PATCH_MODAL_GATE_MISSING
require_marker "$dockerfile" \
    'data-pasturestack-toggle' \
    SERVER_API_EXPLORER_PATCH_DROPDOWN_GATE_MISSING
require_marker "$dockerfile" \
    'licenses/inherited-vendor/LICENSE-async-0.9.0' \
    SERVER_API_EXPLORER_PATCH_LEGAL_GATE_MISSING
require_marker "$build_script" \
    'runtime_go=1.27.0' \
    SERVER_RUNTIME_GO_GATE_MISSING
require_marker "$build_script" \
    'orchestration_updated=1' \
    SERVER_ORCHESTRATION_UPDATE_GATE_MISSING
require_marker "$build_script" \
    'wrappers_pinned=1' \
    SERVER_WRAPPER_REGRESSION_GATE_MISSING
require_marker "$build_script" \
    'launcher_wrapper_sha256=57b6422dc4a51d4c5448306a4efad182517ed1622bba1257df3c270c5c23ee47' \
    SERVER_WRAPPER_HASH_GATE_MISSING
require_marker "$build_script" \
    'audit_log_filters=1' \
    SERVER_API_EXPLORER_PATCH_WEB_CONSOLE_REGRESSION_GATE_MISSING

require_marker "$dockerfile" \
    'org.opencontainers.image.base.digest="sha256:98ace6dd822f883f2f161f8e7c3191d45cc1f1aef6d2cb6de281cfb1d93237e5"' \
    SERVER_API_EXPLORER_PATCH_BASE_DIGEST_MISSING
require_marker "$build_script" \
    'ghcr.io/pasturestack/server:v1.6.460@sha256:c855af8aea232dacc5bb6df68e2271d482c68b53c43ab0c108ec19118f5ab403' \
    SERVER_API_EXPLORER_PATCH_BUILD_BASE_DIGEST_MISSING

if grep -RInE '(^|[^[:alnum:]])[A-Za-z]:\\Users\\|/home/[^/[:space:]]+/|(^|[^[:digit:]])10[.][[:digit:]]{1,3}[.][[:digit:]]{1,3}[.][[:digit:]]{1,3}([^[:digit:]]|$)|[[:alnum:]._%+-]+@[[:alnum:].-]+[.][[:alpha:]]{2,}' \
    "$dockerfile" "$build_script"; then
    echo 'SERVER_API_EXPLORER_PATCH_PRIVATE_MARKER' >&2
    exit 1
fi

bash -n "$build_script"
bash -n "$vendor_pending_validator"
python3 - "$mfa_policy_smoke" <<'PY'
import ast
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
PY

for oidc_policy_smoke_marker in \
    "policy_purpose = 'oidcAccessPolicyUpdate'" \
    "'operation': 'consumeSecurityConfirmation'" \
    "'bound-policy-confirmation-consumed'" \
    "'bound-policy-confirmation-replay-rejected'" \
    "'oidc-source-change-stable-recovery-error'" \
    "recovery_required['code'] == 'LocalRecoveryRequired'" \
    "'oidc-invalid-principal-stable-error'" \
    "invalid_identity['code'] == 'InvalidAllowedIdentity'"; do
    require_marker "$mfa_policy_smoke" "$oidc_policy_smoke_marker" \
        SERVER_OIDC_POLICY_API_SMOKE_MISSING
done

jq -e '
  .["@context"] == "https://openvex.dev/ns/v0.2.0"
  and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.471"
  and (.statements | length) == 51
  and ([.statements[].vulnerability.name] | length == (unique | length))
  and ([.statements[] | select(.status == "fixed") | .vulnerability.name] | sort)
      == ["CVE-2024-52005","CVE-2026-12087","CVE-2026-13221","CVE-2026-18798","CVE-2026-27171","CVE-2026-56391","CVE-2026-57432","CVE-2026-57433","CVE-2026-75803","CVE-2026-8932"]
  and ([.statements[] | select(.status == "not_affected") | .vulnerability.name] | sort)
      == ["CVE-2024-2236","CVE-2024-56433","CVE-2025-1352","CVE-2025-1376","CVE-2025-66382","CVE-2026-13757","CVE-2026-18374","CVE-2026-18477","CVE-2026-18508","CVE-2026-27456","CVE-2026-3184","CVE-2026-32776","CVE-2026-32777","CVE-2026-32778","CVE-2026-40228","CVE-2026-41080","CVE-2026-45186","CVE-2026-50219","CVE-2026-53910","CVE-2026-54371","CVE-2026-56131","CVE-2026-56132","CVE-2026-56392","CVE-2026-56403","CVE-2026-56404","CVE-2026-56405","CVE-2026-56406","CVE-2026-56407","CVE-2026-56408","CVE-2026-56409","CVE-2026-56410","CVE-2026-56411","CVE-2026-56412","CVE-2026-56855","CVE-2026-57062","CVE-2026-66046","CVE-2026-72522","CVE-2026-76641","CVE-2026-76957","CVE-2026-78662","GO-2026-5932"]
  and ([.statements[] | select(.status == "under_investigation") | .vulnerability.name] | sort)
      == []
  and all(.statements[]; (.products | length) > 0)
  and all(.statements[].products[]; (.["@id"] | startswith("pkg:") and (contains("*") | not)))
  and all(.statements[] | select(.status == "not_affected");
          (.justification | type) == "string" and (.impact_statement | length) > 20)
' "$runtime_vex" >/dev/null

vendor_pending_fixture=$(mktemp)
trap 'rm -f "$vendor_pending_fixture"' EXIT
jq -r '
  . as $root
  | .findings[] as $finding
  | $finding.packages[]
  | [$finding.severity, $finding.vulnerabilityId, .name, .installedVersion,
     "", $root.policy.trivyTarget]
  | @tsv
' "$runtime_vendor_pending" | LC_ALL=C sort -u >"$vendor_pending_fixture"
bash "$vendor_pending_validator" "$runtime_vendor_pending" \
    "$vendor_pending_fixture" v1.6.471 >/dev/null
rm -f "$vendor_pending_fixture"
trap - EXIT

for marker in \
    'release_tag:' \
    '.features["containerd-snapshotter"] = true' \
    "grep -F 'io.containerd.snapshotter.v1'" \
    'PASTURESTACK_BUILD_NO_CACHE=1 IMAGE="$LAYERED_CANDIDATE_IMAGE"' \
    'SERVER_LAYERED_BUILD_OK base_layers=%s source_layers=%s maximum=32 base=v1.6.460' \
    'python3 source/scripts/flatten-server-image.py' \
    'SERVER_IMAGE_FLATTEN_OK' \
    'SERVER_REGISTRY_LAYER_OK release=%s layers=1' \
    'PROXY_PLATFORM_PUBLIC_ORIGIN=https://stack.example.test' \
    'https://stack.example.test/v2-beta/schemas' \
    'assert_public_proxy_contract before-restart' \
    'first_contract_attempts="$public_proxy_contract_attempts"' \
    'assert_public_proxy_contract after-restart' \
    'restart_contract_attempts="$public_proxy_contract_attempts"' \
    'for private_api_attempt in $(seq 1 60); do' \
    '"$response_code" =~ ^(200|401|403)$' \
    'Private API contract did not converge during ${phase}' \
    'attempts=%s' \
    'reverse-proxy-before-restart.txt' \
    'reverse-proxy-after-restart.txt' \
    'docker restart "$CANDIDATE_NAME"' \
    'python3 source/scripts/test-mfa-policy-api.py' \
    'mfa-policy-api-smoke.txt' \
    'ghcr.io/aquasecurity/trivy:0.74.0@sha256:62b1e65e8869bc4b4c6aa4fa2b21595256c7c2f6018a9d9ad61caf87187c1969' \
    'server.openvex.json' \
    'server.vendor-pending.json' \
    'validate-vendor-pending-findings.sh' \
    'server-security-scan-raw.json' \
    '--vex /evidence/server.openvex.json' \
    'server-vulnerabilities-raw.tsv' \
    'server-vulnerabilities-unresolved.tsv' \
    'vendor-pending-summary.txt' \
    'SERVER_SECURITY_GATE_OK untracked=0 vendor_pending=%s critical_high=0 fixed_available=0 secrets=0' \
    'server-secrets.tsv' \
    'server.cdx.json' \
    'image_purl="pkg:oci/server@sha256%3A${digest_sha256}?repository_url=ghcr.io%2Fpasturestack%2Fserver&tag=${RELEASE_TAG}"' \
    '.metadata.component.type == "container"' \
    '.metadata.component.name == "ghcr.io/pasturestack/server"' \
    '.metadata.component.version == $release' \
    '.metadata.component.purl == $purl' \
    '.metadata.component["bom-ref"] == $purl' \
    '(.metadata.component.hashes | length) == 1' \
    '.metadata.component.hashes[0].alg == "SHA-256"' \
    '.metadata.component.hashes[0].content == $digest' \
    '([.dependencies[]? | select(.ref == $purl)] | length) == 1' \
    'sbom-identity.txt' \
    'SERVER_SBOM_IDENTITY_OK release=%s image=%s digest=%s purl=%s' \
    'test -s "$release_notes"' \
    'actions/attest@1e69f48acb82d1966a394da916b4c1698aa569d6 # v4.2.2' \
    'gh release create "$RELEASE_TAG"'; do
    require_marker "$publish_workflow" "$marker" \
        SERVER_CURRENT_PUBLISH_WORKFLOW_GATE_MISSING
done

if grep -Fq '="$(assert_public_proxy_contract' "$publish_workflow"; then
    printf '%s file=%s\n' SERVER_CURRENT_PUBLISH_WORKFLOW_PROXY_CONTRACT_COMMAND_SUBSTITUTION "$publish_workflow" >&2
    exit 1
fi

release_upload_block=$(sed -n '/gh release create "\$RELEASE_TAG"/,/^$/p' "$publish_workflow")
if grep -Fq '"$evidence/server-secrets.tsv"' <<<"$release_upload_block"; then
    printf '%s file=%s\n' SERVER_CURRENT_PUBLISH_WORKFLOW_EMPTY_SECRET_ASSET_UPLOAD "$publish_workflow" >&2
    exit 1
fi

release_checksum_block=$(sed -n '/^[[:space:]]*sha256sum \\/,/^[[:space:]]*>SHA256SUMS/p' "$publish_workflow")
if grep -Fq 'server-secrets.tsv' <<<"$release_checksum_block"; then
    printf '%s file=%s\n' SERVER_CURRENT_PUBLISH_WORKFLOW_EMPTY_SECRET_CHECKSUM_ENTRY "$publish_workflow" >&2
    exit 1
fi
for release_readback_contract in \
    'release-assets-expected.tsv' \
    'release-assets-published.tsv' \
    '.assets[] | [.name, .digest] | @tsv' \
    'diff -u'; do
    if ! grep -Fq "$release_readback_contract" "$publish_workflow"; then
        printf '%s token=%s file=%s\n' \
            SERVER_CURRENT_PUBLISH_WORKFLOW_RELEASE_READBACK_MISSING \
            "$release_readback_contract" "$publish_workflow" >&2
        exit 1
    fi
done

printf 'SERVER_API_EXPLORER_PATCH_OK release=v1.6.471 base=v1.6.460 engine=0.183.323 web_console=1.6.136 authentication_service=0.4.42 curl=8.18.0-1ubuntu2.7 freemarker=2.3.35 artifact_scan=required vendor_pending=exact-set role_matrix=qa-required locale_layout=qa-required\n'

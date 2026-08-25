#!/usr/bin/env bash
set -euo pipefail

server_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "${server_dir}/.." && pwd)
cd "$repo_root"

if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
    echo "Refusing to build a release image from an uncommitted worktree" >&2
    exit 1
fi

revision=${PASTURESTACK_SERVER_REVISION:-$(git rev-parse HEAD)}
source_date_epoch=${SOURCE_DATE_EPOCH:-$(git show -s --format=%ct HEAD)}

orchestration_engine_release_base_url=${ORCHESTRATION_ENGINE_RELEASE_BASE_URL:-https://github.com/PastureStack/orchestration-engine/releases/download}
orchestration_engine_release_tag=${ORCHESTRATION_ENGINE_RELEASE_TAG:-v0.183.273}
orchestration_engine_artifact=${ORCHESTRATION_ENGINE_ARTIFACT:-orchestration-engine-0.183.273.jar}
orchestration_engine_artifact_sha256=${ORCHESTRATION_ENGINE_ARTIFACT_SHA256:?ORCHESTRATION_ENGINE_ARTIFACT_SHA256 is required}
orchestration_engine_commit=${ORCHESTRATION_ENGINE_COMMIT:?ORCHESTRATION_ENGINE_COMMIT is required}

vsphere_cli_bundle_release_base_url=${VSPHERE_CLI_BUNDLE_RELEASE_BASE_URL:-https://github.com/PastureStack/vsphere-cli-bundle/releases/download}
vsphere_cli_bundle_release_tag=${VSPHERE_CLI_BUNDLE_RELEASE_TAG:-v0.55.1-pasturestack.1}
vsphere_cli_bundle_artifact=${VSPHERE_CLI_BUNDLE_ARTIFACT:-vsphere-cli-bundle-0.55.1-pasturestack.1-linux-amd64.tar.xz}
vsphere_cli_bundle_artifact_sha256=${VSPHERE_CLI_BUNDLE_ARTIFACT_SHA256:?VSPHERE_CLI_BUNDLE_ARTIFACT_SHA256 is required}
vsphere_cli_bundle_commit=${VSPHERE_CLI_BUNDLE_COMMIT:?VSPHERE_CLI_BUNDLE_COMMIT is required}
govmomi_source_commit=${GOVMOMI_SOURCE_COMMIT:-a668d9c60399552ea96782b8751c956720a0b8fb}
govc_binary_sha256=${GOVC_BINARY_SHA256:-4a4766667d710148cdab058f2aba65c5ff3e886758bb4a0cd021e05034b96fb2}

authentication_service_release_base_url=${AUTHENTICATION_SERVICE_RELEASE_BASE_URL:-https://github.com/PastureStack/authentication-service/releases/download}
authentication_service_release_tag=${AUTHENTICATION_SERVICE_RELEASE_TAG:-v0.2.5}
authentication_service_artifact=${AUTHENTICATION_SERVICE_ARTIFACT:-authentication-service-0.2.5-linux-amd64.tar.xz}
authentication_service_artifact_sha256=${AUTHENTICATION_SERVICE_ARTIFACT_SHA256:?AUTHENTICATION_SERVICE_ARTIFACT_SHA256 is required}
authentication_service_commit=${AUTHENTICATION_SERVICE_COMMIT:?AUTHENTICATION_SERVICE_COMMIT is required}

web_console_release_base_url=${WEB_CONSOLE_RELEASE_BASE_URL:-https://github.com/PastureStack/web-console/releases/download}
web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-v1.6.56-pasturestack.36}
web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.56-pasturestack.36.tar.gz}
web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:?WEB_CONSOLE_ARTIFACT_SHA256 is required}
web_console_commit=${WEB_CONSOLE_COMMIT:?WEB_CONSOLE_COMMIT is required}

image=${IMAGE:-pasturestack-validation/server:v1.6.324}
build_options=()

if [[ ! "$revision" =~ ^[0-9a-f]{40}$ ]] ||
   [[ ! "$source_date_epoch" =~ ^[0-9]+$ ]]; then
    echo "Invalid Server revision or source date epoch" >&2
    exit 1
fi
for commit in \
    "$orchestration_engine_commit" \
    "$vsphere_cli_bundle_commit" \
    "$govmomi_source_commit" \
    "$authentication_service_commit" \
    "$web_console_commit"; do
    [[ "$commit" =~ ^[0-9a-f]{40}$ ]] || {
        echo "Invalid source commit: $commit" >&2
        exit 1
    }
done
for digest in \
    "$orchestration_engine_artifact_sha256" \
    "$vsphere_cli_bundle_artifact_sha256" \
    "$govc_binary_sha256" \
    "$authentication_service_artifact_sha256" \
    "$web_console_artifact_sha256"; do
    [[ "$digest" =~ ^[0-9a-f]{64}$ ]] || {
        echo "Invalid artifact SHA-256: $digest" >&2
        exit 1
    }
done
for tag in \
    "$orchestration_engine_release_tag" \
    "$vsphere_cli_bundle_release_tag" \
    "$authentication_service_release_tag" \
    "$web_console_release_tag"; do
    [[ "$tag" =~ ^v[0-9][0-9A-Za-z.-]*$ ]] || {
        echo "Invalid release tag: $tag" >&2
        exit 1
    }
done
for artifact in \
    "$orchestration_engine_artifact" \
    "$vsphere_cli_bundle_artifact" \
    "$authentication_service_artifact" \
    "$web_console_artifact"; do
    [[ "$artifact" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]] || {
        echo "Invalid release artifact name: $artifact" >&2
        exit 1
    }
done
for base_url in \
    "$orchestration_engine_release_base_url" \
    "$vsphere_cli_bundle_release_base_url" \
    "$authentication_service_release_base_url" \
    "$web_console_release_base_url"; do
    case "$base_url" in
        https://*) ;;
        http://127.0.0.1:*|http://localhost:*)
            [[ ${PASTURESTACK_ALLOW_LOOPBACK_ARTIFACTS:-0} == 1 ]] || {
                echo "Loopback artifact sources require PASTURESTACK_ALLOW_LOOPBACK_ARTIFACTS=1" >&2
                exit 1
            }
            ;;
        *)
            echo "Artifact source must use HTTPS or an explicitly allowed loopback address" >&2
            exit 1
            ;;
    esac
done
if [[ ${PASTURESTACK_BUILD_NO_CACHE:-0} == 1 ]]; then
    build_options+=(--no-cache)
fi

docker buildx build \
    "${build_options[@]}" \
    --provenance=false \
    --load \
    --network=host \
    --build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}" \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --build-arg "ORCHESTRATION_ENGINE_RELEASE_BASE_URL=${orchestration_engine_release_base_url}" \
    --build-arg "ORCHESTRATION_ENGINE_RELEASE_TAG=${orchestration_engine_release_tag}" \
    --build-arg "ORCHESTRATION_ENGINE_ARTIFACT=${orchestration_engine_artifact}" \
    --build-arg "ORCHESTRATION_ENGINE_ARTIFACT_SHA256=${orchestration_engine_artifact_sha256}" \
    --build-arg "ORCHESTRATION_ENGINE_COMMIT=${orchestration_engine_commit}" \
    --build-arg "VSPHERE_CLI_BUNDLE_RELEASE_BASE_URL=${vsphere_cli_bundle_release_base_url}" \
    --build-arg "VSPHERE_CLI_BUNDLE_RELEASE_TAG=${vsphere_cli_bundle_release_tag}" \
    --build-arg "VSPHERE_CLI_BUNDLE_ARTIFACT=${vsphere_cli_bundle_artifact}" \
    --build-arg "VSPHERE_CLI_BUNDLE_ARTIFACT_SHA256=${vsphere_cli_bundle_artifact_sha256}" \
    --build-arg "VSPHERE_CLI_BUNDLE_COMMIT=${vsphere_cli_bundle_commit}" \
    --build-arg "GOVMOMI_SOURCE_COMMIT=${govmomi_source_commit}" \
    --build-arg "GOVC_BINARY_SHA256=${govc_binary_sha256}" \
    --build-arg "AUTHENTICATION_SERVICE_RELEASE_BASE_URL=${authentication_service_release_base_url}" \
    --build-arg "AUTHENTICATION_SERVICE_RELEASE_TAG=${authentication_service_release_tag}" \
    --build-arg "AUTHENTICATION_SERVICE_ARTIFACT=${authentication_service_artifact}" \
    --build-arg "AUTHENTICATION_SERVICE_ARTIFACT_SHA256=${authentication_service_artifact_sha256}" \
    --build-arg "AUTHENTICATION_SERVICE_COMMIT=${authentication_service_commit}" \
    --build-arg "WEB_CONSOLE_RELEASE_BASE_URL=${web_console_release_base_url}" \
    --build-arg "WEB_CONSOLE_RELEASE_TAG=${web_console_release_tag}" \
    --build-arg "WEB_CONSOLE_ARTIFACT=${web_console_artifact}" \
    --build-arg "WEB_CONSOLE_ARTIFACT_SHA256=${web_console_artifact_sha256}" \
    --build-arg "WEB_CONSOLE_COMMIT=${web_console_commit}" \
    --tag "$image" \
    --file server/Dockerfile.mfa-self-service-patch \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.324
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.319

image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
for marker in \
    CATTLE_RANCHER_SERVER_VERSION=v1.6.324 \
    CATTLE_CATTLE_VERSION=v0.183.273 \
    PASTURESTACK_ORCHESTRATION_ENGINE_COMMIT="${orchestration_engine_commit}" \
    PASTURESTACK_ORCHESTRATION_ENGINE_ARTIFACT_SHA256="${orchestration_engine_artifact_sha256}" \
    PASTURESTACK_VSPHERE_CLI_BUNDLE_VERSION=0.55.1-pasturestack.1 \
    PASTURESTACK_VSPHERE_CLI_BUNDLE_COMMIT="${vsphere_cli_bundle_commit}" \
    PASTURESTACK_VSPHERE_CLI_BUNDLE_ARTIFACT_SHA256="${vsphere_cli_bundle_artifact_sha256}" \
    PASTURESTACK_GOVMOMI_SOURCE_COMMIT="${govmomi_source_commit}" \
    PASTURESTACK_GOVC_BINARY_SHA256="${govc_binary_sha256}" \
    PASTURESTACK_AUTHENTICATION_SERVICE_VERSION=0.2.5 \
    PASTURESTACK_AUTHENTICATION_SERVICE_COMMIT="${authentication_service_commit}" \
    PASTURESTACK_AUTHENTICATION_SERVICE_ARTIFACT_SHA256="${authentication_service_artifact_sha256}" \
    PASTURESTACK_WEB_CONSOLE_COMMIT="${web_console_commit}" \
    PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.36 \
    PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256="${web_console_artifact_sha256}" \
    PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27 \
    PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1; do
    test "$(grep -Fxc "$marker" <<<"$image_environment")" = 1
done

docker run --rm --entrypoint bash "$image" -lc '
    set -euo pipefail
    unzip -p /usr/share/cattle/cattle.jar META-INF/MANIFEST.MF |
      tr -d "\r" |
      grep -Fx "Implementation-Version: 0.183.273" >/dev/null
    auth_logic=$(find /usr/share/cattle/war/WEB-INF/lib \
      -maxdepth 1 -type f -name "cattle-iaas-auth-logic-0.183.273.jar" -print -quit)
    test -n "${auth_logic}"
    unzip -p "${auth_logic}" \
      io/cattle/platform/iaas/api/auth/mfa/MfaResourceManager.class |
      grep -aF "MfaAccountHolderRequired" >/dev/null
    unzip -p "${auth_logic}" \
      io/cattle/platform/iaas/api/auth/mfa/MfaAttemptService.class |
      grep -aF "MfaTemporarilyLocked" >/dev/null
    unzip -p "${auth_logic}" \
      io/cattle/platform/iaas/api/auth/identity/AuthIdentityLinkResourceManager.class |
      grep -aF "LocalAdministratorMfaRequired" >/dev/null
    unzip -p "${auth_logic}" \
      io/cattle/platform/iaas/api/auth/integration/local/LocalAuthConstants.class |
      grep -aF "api.auth.local.recovery.mfa.ready" >/dev/null
    resources_jar=$(find /usr/share/cattle/war/WEB-INF/lib \
      -maxdepth 1 -type f -name "cattle-resources-0.183.273.jar" -print -quit)
    test -n "${resources_jar}"
    unzip -p "${resources_jar}" schema/base/mfaStatus.json |
      grep -F "\"recoveryEmailEnrollmentAvailable\"" >/dev/null
    for marker in \
      federatedMfaMode \
      lockoutSeconds \
      localAdministratorRecoveryConfigured \
      localAdministratorRecoveryEnabled \
      localAdministratorRecoveryMfaReady \
      localAdministratorRecoveryRequired \
      localAdministratorRecoveryStatus \
      maximumFederatedAuthenticationAgeSeconds \
      maximumFailedAttempts \
      passkeyCounterPolicy \
      securityConfirmation \
      securityConfirmationTtlSeconds \
      securityEmailLocale \
      trustedAuthenticationContexts \
      trustedAuthenticationMethods; do
      unzip -p "${resources_jar}" schema/base/mfaSettings.json |
        grep -F "\"${marker}\"" >/dev/null
    done
    test "$(/usr/bin/govc version)" = "govc 0.55.1-pasturestack.1"
    /usr/bin/govc version -l | grep -Fx "Build Commit: a668d9c60399" >/dev/null
    /usr/bin/govc version -l | grep -Fx "Build Date: 2026-07-07T14:02:15Z" >/dev/null
    echo "4a4766667d710148cdab058f2aba65c5ff3e886758bb4a0cd021e05034b96fb2  /usr/bin/govc" |
      sha256sum -c -
    grep -F "Pinned source commit: a668d9c60399552ea96782b8751c956720a0b8fb" \
      /usr/share/licenses/pasturestack/vsphere-cli-bundle/vsphere-cli-bundle-SOURCES.txt >/dev/null
    grep -F "Security dependency: golang.org/x/text v0.39.0" \
      /usr/share/licenses/pasturestack/vsphere-cli-bundle/vsphere-cli-bundle-SOURCES.txt >/dev/null
    unzip -p "${resources_jar}" schema/base/mfaSettings.json |
      grep -F "\"collectionMethods\": [ \"GET\" ]" >/dev/null
    unzip -p "${resources_jar}" schema/base/mfaSettings.json |
      grep -F "\"resourceMethods\": [ \"GET\", \"PUT\" ]" >/dev/null
    unzip -p "${resources_jar}" db/changelog.xml |
      grep -F "db/core-125.xml" >/dev/null
    unzip -p "${resources_jar}" db/core-125.xml |
      grep -F "pasturestack-credential-secret-value-mediumtext" >/dev/null
    unzip -p "${resources_jar}" db/core-125.xml |
      grep -F "MEDIUMTEXT(16777215)" >/dev/null
    for marker in \
      beginSecurityConfirmation \
      confirmSecurityConfirmation \
      method \
      methods \
      recoveryCode \
      securityConfirmation \
      webAuthnOptions; do
      unzip -p "${resources_jar}" schema/base/mfaOperation.json |
        grep -F "\"${marker}\"" >/dev/null
    done
    test -x /usr/bin/authentication-service
    test -x /usr/bin/authentication-service.real
    grep -F "RC16_WRAPPER_REAL_DIR" /usr/bin/authentication-service >/dev/null
    /usr/bin/authentication-service.real --version | grep -F "0.2.5" >/dev/null
    grep -aF "go1.27.0" /usr/bin/authentication-service.real >/dev/null
    for marker in \
      authenticated_at \
      authentication_context \
      authentication_issuer \
      authentication_methods; do
      grep -aF "${marker}" /usr/bin/authentication-service.real >/dev/null
    done
    test -s /usr/share/cattle/war/favicon.ico
    grep -F "href=\"/favicon.ico\"" /usr/share/cattle/war/index.html >/dev/null
    grep -F 'pasturestack-favicon.svg' /usr/share/cattle/war/index.html >/dev/null
    ui_entry=$(find /usr/share/cattle/war/assets \
      -maxdepth 1 -type f -name "ui-*.js" -print -quit)
    vendor_entry=$(find /usr/share/cattle/war/assets \
      -maxdepth 1 -type f -name "vendor-*.js" -print -quit)
    test -n "${ui_entry}"
    test -n "${vendor_entry}"
    grep -aF "bs.collapse" "${vendor_entry}" >/dev/null
    grep -aF "bs.dropdown" "${vendor_entry}" >/dev/null
    if grep -aEq "bs\\.(button|tooltip|popover)|data-loading-text" \
      "${vendor_entry}"; then
      echo "Vulnerable Bootstrap runtime plugin found in Server image" >&2
      exit 1
    fi
    test "$(find /usr/share/cattle/war/translations \
      -maxdepth 1 -type f -name "*.json" | wc -l)" -eq 13
    for stylesheet in \
      vendor.css \
      vendor.rtl.css \
      ui-light.css \
      ui-light.rtl.css \
      ui-dark.css \
      ui-dark.rtl.css; do
      test -s "/usr/share/cattle/war/assets/${stylesheet}"
    done
    for marker in \
      account-security \
      activateWithCodeFlow \
      authIdentityOperation \
      discardPermissions \
      mfaSettings \
      mfa-system-settings \
      mfa-self-service-summary \
      recoveryMfaMethods \
      showMfaRecoveryOptions \
      providerSwitchCode \
      recoveryCode \
      smtpEnabled \
      switchToLocal \
      transferPermissions \
      webauthn; do
      grep -F "${marker}" "${ui_entry}" >/dev/null
    done
    grep -F \
      "\"systemManaged\":\"SMTP 寄信服務由系統管理員集中設定，全系統共用。您的帳號不會儲存 SMTP 伺服器、寄件者或密碼。\"" \
      /usr/share/cattle/war/translations/zh-tw.json >/dev/null
    grep -F \
      "\"show\":\"無法使用驗證器或通行金鑰？\"" \
      /usr/share/cattle/war/translations/zh-tw.json >/dev/null
'

printf 'SERVER_MFA_SELF_SERVICE_PATCH_IMAGE_OK image=%s revision=%s engine_commit=%s vsphere_cli_bundle_commit=%s authentication_service_commit=%s web_console_commit=%s\n' \
    "$image" "$revision" "$orchestration_engine_commit" \
    "$vsphere_cli_bundle_commit" "$authentication_service_commit" "$web_console_commit"

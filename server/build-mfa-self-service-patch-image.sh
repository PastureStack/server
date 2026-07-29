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
orchestration_engine_release_tag=${ORCHESTRATION_ENGINE_RELEASE_TAG:-v0.183.271}
orchestration_engine_artifact=${ORCHESTRATION_ENGINE_ARTIFACT:-orchestration-engine-0.183.271.jar}
orchestration_engine_artifact_sha256=${ORCHESTRATION_ENGINE_ARTIFACT_SHA256:?ORCHESTRATION_ENGINE_ARTIFACT_SHA256 is required}
orchestration_engine_commit=${ORCHESTRATION_ENGINE_COMMIT:?ORCHESTRATION_ENGINE_COMMIT is required}

authentication_service_release_base_url=${AUTHENTICATION_SERVICE_RELEASE_BASE_URL:-https://github.com/PastureStack/authentication-service/releases/download}
authentication_service_release_tag=${AUTHENTICATION_SERVICE_RELEASE_TAG:-v0.2.4}
authentication_service_artifact=${AUTHENTICATION_SERVICE_ARTIFACT:-authentication-service-0.2.4-linux-amd64.tar.xz}
authentication_service_artifact_sha256=${AUTHENTICATION_SERVICE_ARTIFACT_SHA256:?AUTHENTICATION_SERVICE_ARTIFACT_SHA256 is required}
authentication_service_commit=${AUTHENTICATION_SERVICE_COMMIT:?AUTHENTICATION_SERVICE_COMMIT is required}

web_console_release_base_url=${WEB_CONSOLE_RELEASE_BASE_URL:-https://github.com/PastureStack/web-console/releases/download}
web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-v1.6.56-pasturestack.29}
web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.56-pasturestack.29.tar.gz}
web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:?WEB_CONSOLE_ARTIFACT_SHA256 is required}
web_console_commit=${WEB_CONSOLE_COMMIT:?WEB_CONSOLE_COMMIT is required}

image=${IMAGE:-pasturestack-validation/server:v1.6.317}
build_options=()

if [[ ! "$revision" =~ ^[0-9a-f]{40}$ ]] ||
   [[ ! "$source_date_epoch" =~ ^[0-9]+$ ]]; then
    echo "Invalid Server revision or source date epoch" >&2
    exit 1
fi
for commit in \
    "$orchestration_engine_commit" \
    "$authentication_service_commit" \
    "$web_console_commit"; do
    [[ "$commit" =~ ^[0-9a-f]{40}$ ]] || {
        echo "Invalid source commit: $commit" >&2
        exit 1
    }
done
for digest in \
    "$orchestration_engine_artifact_sha256" \
    "$authentication_service_artifact_sha256" \
    "$web_console_artifact_sha256"; do
    [[ "$digest" =~ ^[0-9a-f]{64}$ ]] || {
        echo "Invalid artifact SHA-256: $digest" >&2
        exit 1
    }
done
for tag in \
    "$orchestration_engine_release_tag" \
    "$authentication_service_release_tag" \
    "$web_console_release_tag"; do
    [[ "$tag" =~ ^v[0-9][0-9A-Za-z.-]*$ ]] || {
        echo "Invalid release tag: $tag" >&2
        exit 1
    }
done
for artifact in \
    "$orchestration_engine_artifact" \
    "$authentication_service_artifact" \
    "$web_console_artifact"; do
    [[ "$artifact" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]] || {
        echo "Invalid release artifact name: $artifact" >&2
        exit 1
    }
done
for base_url in \
    "$orchestration_engine_release_base_url" \
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
    v1.6.317
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.316

image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
for marker in \
    CATTLE_RANCHER_SERVER_VERSION=v1.6.317 \
    CATTLE_CATTLE_VERSION=v0.183.271 \
    PASTURESTACK_ORCHESTRATION_ENGINE_COMMIT="${orchestration_engine_commit}" \
    PASTURESTACK_ORCHESTRATION_ENGINE_ARTIFACT_SHA256="${orchestration_engine_artifact_sha256}" \
    PASTURESTACK_AUTHENTICATION_SERVICE_VERSION=0.2.4 \
    PASTURESTACK_AUTHENTICATION_SERVICE_COMMIT="${authentication_service_commit}" \
    PASTURESTACK_AUTHENTICATION_SERVICE_ARTIFACT_SHA256="${authentication_service_artifact_sha256}" \
    PASTURESTACK_WEB_CONSOLE_COMMIT="${web_console_commit}" \
    PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.29 \
    PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256="${web_console_artifact_sha256}" \
    PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27 \
    PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1; do
    test "$(grep -Fxc "$marker" <<<"$image_environment")" = 1
done

docker run --rm --entrypoint bash "$image" -lc '
    set -euo pipefail
    unzip -p /usr/share/cattle/cattle.jar META-INF/MANIFEST.MF |
      tr -d "\r" |
      grep -Fx "Implementation-Version: 0.183.271" >/dev/null
    auth_logic=$(find /usr/share/cattle/war/WEB-INF/lib \
      -maxdepth 1 -type f -name "cattle-iaas-auth-logic-0.183.271.jar" -print -quit)
    test -n "${auth_logic}"
    unzip -p "${auth_logic}" \
      io/cattle/platform/iaas/api/auth/mfa/MfaResourceManager.class |
      grep -aF "MfaAccountHolderRequired" >/dev/null
    resources_jar=$(find /usr/share/cattle/war/WEB-INF/lib \
      -maxdepth 1 -type f -name "cattle-resources-0.183.271.jar" -print -quit)
    test -n "${resources_jar}"
    unzip -p "${resources_jar}" schema/base/mfaStatus.json |
      grep -F "\"recoveryEmailEnrollmentAvailable\"" >/dev/null
    test -x /usr/bin/authentication-service
    test -x /usr/bin/authentication-service.real
    grep -F "RC16_WRAPPER_REAL_DIR" /usr/bin/authentication-service >/dev/null
    /usr/bin/authentication-service.real --version | grep -F "0.2.4" >/dev/null
    grep -aF "go1.26.5" /usr/bin/authentication-service.real >/dev/null
    ui_entry=$(find /usr/share/cattle/war/assets \
      -maxdepth 1 -type f -name "ui-*.js" -print -quit)
    test -n "${ui_entry}"
    test "$(find /usr/share/cattle/war/translations \
      -maxdepth 1 -type f -name "*.json" | wc -l)" -eq 13
    for marker in \
      account-security \
      activateWithCodeFlow \
      authIdentityOperation \
      discardPermissions \
      mfaSettings \
      mfa-self-service-summary \
      providerSwitchCode \
      recoveryCode \
      smtpEnabled \
      switchToLocal \
      transferPermissions \
      webauthn; do
      grep -F "${marker}" "${ui_entry}" >/dev/null
    done
'

printf 'SERVER_MFA_SELF_SERVICE_PATCH_IMAGE_OK image=%s revision=%s engine_commit=%s authentication_service_commit=%s web_console_commit=%s\n' \
    "$image" "$revision" "$orchestration_engine_commit" \
    "$authentication_service_commit" "$web_console_commit"

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
if [[ ! "$revision" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Invalid PastureStack Server revision: ${revision}" >&2
    exit 1
fi
source_date_epoch=${SOURCE_DATE_EPOCH:-$(git show -s --format=%ct HEAD)}
if [[ ! "$source_date_epoch" =~ ^[0-9]+$ ]]; then
    echo "Invalid source date epoch: ${source_date_epoch}" >&2
    exit 1
fi

authentication_service_release_tag=${AUTHENTICATION_SERVICE_RELEASE_TAG:-v0.2.1}
authentication_service_artifact=${AUTHENTICATION_SERVICE_ARTIFACT:-authentication-service-0.2.1-linux-amd64.tar.xz}
authentication_service_artifact_sha256=${AUTHENTICATION_SERVICE_ARTIFACT_SHA256:?AUTHENTICATION_SERVICE_ARTIFACT_SHA256 is required}
authentication_service_commit=${AUTHENTICATION_SERVICE_COMMIT:?AUTHENTICATION_SERVICE_COMMIT is required}
web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-v1.6.56-pasturestack.25}
web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.56-pasturestack.25.tar.gz}
web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:?WEB_CONSOLE_ARTIFACT_SHA256 is required}
web_console_commit=${WEB_CONSOLE_COMMIT:?WEB_CONSOLE_COMMIT is required}
image=${IMAGE:-pasturestack-validation/server:v1.6.313}
build_options=()
if [[ ${PASTURESTACK_BUILD_NO_CACHE:-0} == 1 ]]; then
    build_options+=(--no-cache)
fi

for commit in "$authentication_service_commit" "$web_console_commit"; do
    if [[ ! "$commit" =~ ^[0-9a-f]{40}$ ]]; then
        echo "Invalid source commit: ${commit}" >&2
        exit 1
    fi
done
for digest in "$authentication_service_artifact_sha256" "$web_console_artifact_sha256"; do
    if [[ ! "$digest" =~ ^[0-9a-f]{64}$ ]]; then
        echo "Invalid artifact SHA-256: ${digest}" >&2
        exit 1
    fi
done

docker buildx build \
    "${build_options[@]}" \
    --provenance=false \
    --load \
    --network=host \
    --build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}" \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --build-arg "AUTHENTICATION_SERVICE_RELEASE_TAG=${authentication_service_release_tag}" \
    --build-arg "AUTHENTICATION_SERVICE_ARTIFACT=${authentication_service_artifact}" \
    --build-arg "AUTHENTICATION_SERVICE_ARTIFACT_SHA256=${authentication_service_artifact_sha256}" \
    --build-arg "AUTHENTICATION_SERVICE_COMMIT=${authentication_service_commit}" \
    --build-arg "WEB_CONSOLE_RELEASE_TAG=${web_console_release_tag}" \
    --build-arg "WEB_CONSOLE_ARTIFACT=${web_console_artifact}" \
    --build-arg "WEB_CONSOLE_ARTIFACT_SHA256=${web_console_artifact_sha256}" \
    --build-arg "WEB_CONSOLE_COMMIT=${web_console_commit}" \
    --tag "$image" \
    --file server/Dockerfile.openid-connect-patch \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.313
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.312

image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
for marker in \
    CATTLE_RANCHER_SERVER_VERSION=v1.6.313 \
    PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27 \
    PASTURESTACK_AUTHENTICATION_SERVICE_VERSION=0.2.1 \
    PASTURESTACK_AUTHENTICATION_SERVICE_COMMIT="${authentication_service_commit}" \
    PASTURESTACK_AUTHENTICATION_SERVICE_ARTIFACT_SHA256="${authentication_service_artifact_sha256}" \
    PASTURESTACK_WEB_CONSOLE_COMMIT="${web_console_commit}" \
    PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.25 \
    PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256="${web_console_artifact_sha256}" \
    PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1; do
    test "$(grep -Fxc "$marker" <<<"$image_environment")" = 1
done

docker run --rm --entrypoint bash "$image" -lc '
    set -euo pipefail
    test -x /usr/bin/authentication-service
    test -x /usr/bin/authentication-service.real
    grep -F "RC16_WRAPPER_REAL_DIR" /usr/bin/authentication-service >/dev/null
    /usr/bin/authentication-service.real --version | grep -F "0.2.1" >/dev/null

    ui_entry=$(find /usr/share/cattle/war/assets \
      -maxdepth 1 -type f -name "ui-*.js" -print -quit)
    test -n "${ui_entry}"
    test "$(find /usr/share/cattle/war/translations \
      -maxdepth 1 -type f -name "*.json" | wc -l)" -eq 13
    for marker in \
      oidcconfig \
      oidc-auth \
      redirectUrl \
      testlogin \
      authorizationCode \
      code_challenge_method \
      S256 \
      pasturestackOidcAuth \
      codeVerifier \
      codeChallenge \
      acceptLogin \
      localauthconfig \
      clientSecretSet; do
      grep -F "${marker}" "${ui_entry}" >/dev/null
    done
    for retained_marker in \
      statsTableCount \
      storageTableCount \
      selectedVolumeCount \
      isBulkRemovableVolume \
      runWithConcurrency \
      consoleWorkspace; do
      grep -F "${retained_marker}" "${ui_entry}" >/dev/null
    done
    for marker in \
      "\"defaultProviderName\":\"OpenID Connect\"" \
      "\"save\":\"驗證設定\"" \
      "\"action\":\"測試透過 {providerName} 登入\"" \
      "\"activateAction\":\"啟用 {providerName} 並登入\"" \
      "\"label\":\"探索文件網址\"" \
      "\"label\":\"用戶端 ID\"" \
      "\"label\":\"用戶端密鑰\"" \
      "\"label\":\"信任的 CA 憑證\"" \
      "\"success\":\"已成功透過 {providerName} 測試登入，使用者為 {identity}。\"" \
      "\"activationRolledBack\":\"最後登入失敗（{error}）。系統已還原先前的身分驗證設定，並保留原有的管理員工作階段。\"" \
      "\"oidc\":\"OpenID Connect\""; do
      grep -F "${marker}" \
        /usr/share/cattle/war/translations/zh-tw.json >/dev/null
    done
'

printf 'SERVER_OPENID_CONNECT_PATCH_IMAGE_OK image=%s revision=%s authentication_service_commit=%s web_console_commit=%s\n' \
    "$image" "$revision" "$authentication_service_commit" "$web_console_commit"

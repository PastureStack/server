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

web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-v1.6.56-pasturestack.26}
web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.56-pasturestack.26.tar.gz}
web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:?WEB_CONSOLE_ARTIFACT_SHA256 is required}
web_console_commit=${WEB_CONSOLE_COMMIT:?WEB_CONSOLE_COMMIT is required}
image=${IMAGE:-pasturestack-validation/server:v1.6.314}
build_options=()
if [[ ${PASTURESTACK_BUILD_NO_CACHE:-0} == 1 ]]; then
    build_options+=(--no-cache)
fi

if [[ ! "$web_console_commit" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Invalid Web Console source commit: ${web_console_commit}" >&2
    exit 1
fi
if [[ ! "$web_console_artifact_sha256" =~ ^[0-9a-f]{64}$ ]]; then
    echo "Invalid Web Console artifact SHA-256: ${web_console_artifact_sha256}" >&2
    exit 1
fi

docker buildx build \
    "${build_options[@]}" \
    --provenance=false \
    --load \
    --network=host \
    --build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}" \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --build-arg "WEB_CONSOLE_RELEASE_TAG=${web_console_release_tag}" \
    --build-arg "WEB_CONSOLE_ARTIFACT=${web_console_artifact}" \
    --build-arg "WEB_CONSOLE_ARTIFACT_SHA256=${web_console_artifact_sha256}" \
    --build-arg "WEB_CONSOLE_COMMIT=${web_console_commit}" \
    --tag "$image" \
    --file server/Dockerfile.oidc-api-host-patch \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.314
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.313

image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
for marker in \
    CATTLE_RANCHER_SERVER_VERSION=v1.6.314 \
    PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27 \
    PASTURESTACK_AUTHENTICATION_SERVICE_VERSION=0.2.1 \
    PASTURESTACK_WEB_CONSOLE_COMMIT="${web_console_commit}" \
    PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.26 \
    PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256="${web_console_artifact_sha256}" \
    PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1; do
    test "$(grep -Fxc "$marker" <<<"$image_environment")" = 1
done

docker run --rm --entrypoint bash "$image" -lc '
    set -euo pipefail
    /usr/bin/authentication-service.real --version | grep -F "0.2.1" >/dev/null
    ui_entry=$(find /usr/share/cattle/war/assets \
      -maxdepth 1 -type f -name "ui-*.js" -print -quit)
    test -n "${ui_entry}"
    test "$(find /usr/share/cattle/war/translations \
      -maxdepth 1 -type f -name "*.json" | wc -l)" -eq 13
    for marker in \
      ensureApiHost \
      oidcconfig \
      redirectUrl \
      testlogin \
      pasturestackOidcAuth \
      oidcAuthorizationTransaction \
      localauthconfig \
      statsTableCount \
      storageTableCount \
      consoleWorkspace; do
      grep -F "${marker}" "${ui_entry}" >/dev/null
    done
    for marker in \
      "\"save\":\"驗證設定\"" \
      "\"label\":\"重新導向 URI\"" \
      "\"action\":\"測試透過 {providerName} 登入\"" \
      "\"activationRolledBack\":\"最後登入失敗（{error}）。系統已還原先前的身分驗證設定，並保留原有的管理員工作階段。\""; do
      grep -F "${marker}" \
        /usr/share/cattle/war/translations/zh-tw.json >/dev/null
    done
'

printf 'SERVER_OIDC_API_HOST_PATCH_IMAGE_OK image=%s revision=%s web_console_commit=%s\n' \
    "$image" "$revision" "$web_console_commit"

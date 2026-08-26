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
base_image=${BASE_IMAGE:-ghcr.io/pasturestack/server:v1.6.358@sha256:14064cb8a91c2ff058e620ca11b3342de422d1bbc34e43ed82f5712801637fa7}
api_explorer_release_base_url=${API_EXPLORER_RELEASE_BASE_URL:-https://github.com/PastureStack/api-explorer/releases/download}
api_explorer_release_tag=${API_EXPLORER_RELEASE_TAG:-v1.1.17}
api_explorer_artifact=${API_EXPLORER_ARTIFACT:-api-explorer-1.1.17.tar.gz}
api_explorer_artifact_sha256=${API_EXPLORER_ARTIFACT_SHA256:-6dc1bfd64f520444efe370bb8141fa3bcc36fa0008617e508375b781ecf30fc3}
api_explorer_commit=${API_EXPLORER_COMMIT:-94e617e0f8950ea80bdb46aaf181f463bae2cea9}
image=${IMAGE:-pasturestack-validation/server:v1.6.359}
build_options=()

[[ "$revision" =~ ^[0-9a-f]{40}$ ]]
[[ "$source_date_epoch" =~ ^[0-9]+$ ]]
[[ "$api_explorer_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$api_explorer_artifact_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$api_explorer_release_tag" =~ ^v[0-9][0-9A-Za-z.-]*$ ]]
[[ "$api_explorer_artifact" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]
[[ "$base_image" == ghcr.io/pasturestack/server:v1.6.358@sha256:14064cb8a91c2ff058e620ca11b3342de422d1bbc34e43ed82f5712801637fa7 ]]
case "$api_explorer_release_base_url" in
    https://*) ;;
    http://127.0.0.1:*|http://localhost:*)
        [[ ${PASTURESTACK_ALLOW_LOOPBACK_ARTIFACTS:-0} == 1 ]]
        ;;
    *)
        echo "API Explorer artifact source must use HTTPS or an explicitly allowed loopback address" >&2
        exit 1
        ;;
esac
if [[ ${PASTURESTACK_BUILD_NO_CACHE:-0} == 1 ]]; then
    build_options+=(--no-cache)
fi

docker buildx build \
    "${build_options[@]}" \
    --provenance=false \
    --load \
    --network=host \
    --build-arg "BASE_IMAGE=${base_image}" \
    --build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}" \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --build-arg "API_EXPLORER_RELEASE_BASE_URL=${api_explorer_release_base_url}" \
    --build-arg "API_EXPLORER_RELEASE_TAG=${api_explorer_release_tag}" \
    --build-arg "API_EXPLORER_ARTIFACT=${api_explorer_artifact}" \
    --build-arg "API_EXPLORER_ARTIFACT_SHA256=${api_explorer_artifact_sha256}" \
    --build-arg "API_EXPLORER_COMMIT=${api_explorer_commit}" \
    --tag "$image" \
    --file server/Dockerfile.api-explorer-patch \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.359
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.358

image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
for marker in \
    CATTLE_RANCHER_SERVER_VERSION=v1.6.359 \
    CATTLE_API_UI_VERSION=1.1.17 \
    PASTURESTACK_API_EXPLORER_PACKAGE=1.1.17 \
    PASTURESTACK_API_EXPLORER_COMMIT="${api_explorer_commit}" \
    PASTURESTACK_API_EXPLORER_ARTIFACT_SHA256="${api_explorer_artifact_sha256}" \
    CATTLE_CATTLE_VERSION=v0.183.281 \
    PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.70 \
    PASTURESTACK_AUTHENTICATION_SERVICE_VERSION=0.4.35 \
    PASTURESTACK_VSPHERE_CLI_BUNDLE_VERSION=0.55.1-pasturestack.1 \
    PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27 \
    PASTURESTACK_CATALOG_COMMIT=c3a8e9876a74dbf98ce16ae504b947c5d80582c1; do
    test "$(grep -Fxc "$marker" <<<"$image_environment")" = 1
done

critical_paths=(
    /usr/share/cattle/cattle.jar
    /usr/bin/authentication-service.real
    /usr/bin/catalog-service.real
    /usr/bin/govc
    /usr/bin/websocket-proxy.real
)
base_critical=$(docker run --rm --entrypoint sha256sum "$base_image" \
    "${critical_paths[@]}")
image_critical=$(docker run --rm --entrypoint sha256sum "$image" \
    "${critical_paths[@]}")
test "$base_critical" = "$image_critical"

web_console_hashes()
{
    local candidate=$1
    docker run --rm --entrypoint bash "$candidate" -lc '
        set -euo pipefail
        web_root=$(readlink -f /usr/share/cattle/war)
        {
            find "${web_root}/assets" "${web_root}/translations" -type f -print0
            printf "%s\0" "${web_root}/index.html" "${web_root}/favicon.ico"
        } | sort -z | xargs -0 sha256sum
    '
}
test "$(web_console_hashes "$base_image")" = "$(web_console_hashes "$image")"

docker run --rm --entrypoint bash "$image" -lc '
    set -euo pipefail
    api_dir=/usr/share/cattle/war/api-ui
    test -d "${api_dir}"
    test -s "${api_dir}/ui.min.js"
    test -s "${api_dir}/ui.min.css"
    test -s "${api_dir}/fonts/bootstrap-icons.woff"
    test -s "${api_dir}/fonts/bootstrap-icons.woff2"
    test -s "${api_dir}/licenses/LICENSE.txt"
    test -s "${api_dir}/licenses/THIRD-PARTY-NOTICES.md"
    test -s "${api_dir}/licenses/bootstrap-5.3.8/LICENSE"
    test -s "${api_dir}/licenses/bootstrap-icons-1.13.1/LICENSE"
    test -s "${api_dir}/licenses/jquery-4.0.0/LICENSE.txt"
    test -s "${api_dir}/licenses/handlebars-4.7.9/LICENSE"
    test ! -e "${api_dir}/js/bootstrap.js"
    test "$(find "${api_dir}" -type f -name "*.map" | wc -l)" -eq 0
    grep -F '"'"'"version": "1.1.17"'"'"' "${api_dir}/version.json" >/dev/null
    grep -F '"'"'"commit": "94e617e"'"'"' "${api_dir}/version.json" >/dev/null
    for marker in \
        PastureStackUi \
        pasturestack:modal:shown \
        pasturestack:modal:hidden \
        data-pasturestack-toggle; do
        grep -aF "${marker}" "${api_dir}/ui.js" >/dev/null
    done
    if grep -aEq '"'"'Bootstrap v3\.4\.1|bs\.(button|tooltip|popover|modal|dropdown)|data-loading-text|data-toggle="dropdown"'"'"' \
        "${api_dir}/ui.js"; then
        echo "Rejected Bootstrap executable surface found in Server image" >&2
        exit 1
    fi
    grep -E "Bootstrap +v5\\.3\\.8" "${api_dir}/ui.css" >/dev/null
    grep -F "url(\"./fonts/bootstrap-icons.woff2" "${api_dir}/ui.css" >/dev/null
    if grep -F "Bootstrap v3." "${api_dir}/ui.css"; then
        echo "Rejected EOL Bootstrap 3 stylesheet in Server image" >&2
        exit 1
    fi
    test "$(find /usr/share/cattle/war/translations -maxdepth 1 -type f -name "*.json" | wc -l)" -eq 13
    ui_entry=$(find /usr/share/cattle/war/assets -maxdepth 1 -type f -name "ui-*.js" -print -quit)
    vendor_entry=$(find /usr/share/cattle/war/assets -maxdepth 1 -type f -name "vendor-*.js" -print -quit)
    test -n "${ui_entry}"
    test -n "${vendor_entry}"
    grep -aF "bs.collapse" "${vendor_entry}" >/dev/null
    grep -aF "bs.dropdown" "${vendor_entry}" >/dev/null
    grep -F '"'"'"systemManaged":"SMTP 寄信服務由系統管理員集中設定，全系統共用。您的帳號不會儲存 SMTP 伺服器、寄件者或密碼。"'"'"' \
        /usr/share/cattle/war/translations/zh-tw.json >/dev/null
    unzip -p /usr/share/cattle/cattle.jar META-INF/MANIFEST.MF |
        tr -d "\r" |
        grep -Fx "Implementation-Version: 0.183.273" >/dev/null
    test "$(/usr/bin/govc version)" = "govc 0.55.1-pasturestack.1"
    /usr/bin/authentication-service.real --version | grep -F "0.2.5" >/dev/null
'

printf 'SERVER_API_EXPLORER_PATCH_IMAGE_OK image=%s revision=%s base=%s api_explorer_commit=%s artifact_sha256=%s bootstrap_javascript=0 critical_runtime_unchanged=1 web_console_unchanged=1\n' \
    "$image" "$revision" "$base_image" "$api_explorer_commit" \
    "$api_explorer_artifact_sha256"

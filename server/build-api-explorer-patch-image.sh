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
base_image=${BASE_IMAGE:-ghcr.io/pasturestack/server:v1.6.363@sha256:c534993b0735c84ed570def216cfc44912532594aa5a270d060cfa9fcccc2bd7}
api_explorer_release_base_url=${API_EXPLORER_RELEASE_BASE_URL:-https://github.com/PastureStack/api-explorer/releases/download}
api_explorer_release_tag=${API_EXPLORER_RELEASE_TAG:-v1.1.17}
api_explorer_artifact=${API_EXPLORER_ARTIFACT:-api-explorer-1.1.17.tar.gz}
api_explorer_artifact_sha256=${API_EXPLORER_ARTIFACT_SHA256:-6dc1bfd64f520444efe370bb8141fa3bcc36fa0008617e508375b781ecf30fc3}
api_explorer_commit=${API_EXPLORER_COMMIT:-94e617e0f8950ea80bdb46aaf181f463bae2cea9}
image=${IMAGE:-pasturestack-validation/server:v1.6.364}
build_options=()

[[ "$revision" =~ ^[0-9a-f]{40}$ ]]
[[ "$source_date_epoch" =~ ^[0-9]+$ ]]
[[ "$api_explorer_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$api_explorer_artifact_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$api_explorer_release_tag" =~ ^v[0-9][0-9A-Za-z.-]*$ ]]
[[ "$api_explorer_artifact" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]
[[ "$base_image" == ghcr.io/pasturestack/server:v1.6.363@sha256:c534993b0735c84ed570def216cfc44912532594aa5a270d060cfa9fcccc2bd7 ]]
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
    v1.6.364
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.363

image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
for marker in \
    CATTLE_RANCHER_SERVER_VERSION=v1.6.364 \
    CATTLE_API_UI_VERSION=1.1.17 \
    PASTURESTACK_RUNTIME_GO_VERSION=1.27.0 \
    PASTURESTACK_UBUNTU_SECURITY_REFRESH=2026-08-26 \
    PASTURESTACK_COREUTILS_PROVIDER=gnu \
    PASTURESTACK_SSH_CLIENT_HARDENING=x11-gssapi-disabled \
    PASTURESTACK_PRIVILEGED_MOUNT_HELPERS=setuid-disabled \
    PASTURESTACK_CONSOLE_BROKER_GO_VERSION=1.27.0 \
    PASTURESTACK_API_EXPLORER_PACKAGE=1.1.17 \
    PASTURESTACK_API_EXPLORER_COMMIT="${api_explorer_commit}" \
    PASTURESTACK_API_EXPLORER_ARTIFACT_SHA256="${api_explorer_artifact_sha256}" \
    CATTLE_CATTLE_VERSION=v0.183.281 \
    PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.70 \
    PASTURESTACK_AUTHENTICATION_SERVICE_VERSION=0.4.36 \
    PASTURESTACK_CATALOG_SERVICE_VERSION=0.20.11 \
    PASTURESTACK_COMPOSE_EXECUTOR_VERSION=0.14.34 \
    PASTURESTACK_HOST_PROVISIONER_VERSION=0.39.6 \
    PASTURESTACK_SECRET_DELIVERY_API_VERSION=0.3.1 \
    PASTURESTACK_USAGE_TELEMETRY_AGENT_VERSION=0.4.1 \
    PASTURESTACK_WEBHOOK_AUTOMATION_SERVICE_VERSION=0.10.1 \
    PASTURESTACK_WEBSOCKET_PROXY_VERSION=0.23.13 \
    PASTURESTACK_VSPHERE_CLI_BUNDLE_VERSION=0.55.1-pasturestack.2 \
    PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27 \
    PASTURESTACK_CATALOG_COMMIT=bc446236c16f1170eb9130b4901af3d57dd82db4; do
    test "$(grep -Fxc "$marker" <<<"$image_environment")" = 1
done

base_orchestration=$(docker run --rm --entrypoint sha256sum "$base_image" \
    /usr/share/cattle/cattle.jar)
image_orchestration=$(docker run --rm --entrypoint sha256sum "$image" \
    /usr/share/cattle/cattle.jar)
test "$base_orchestration" = "$image_orchestration"

wrapper_paths=(
    /usr/bin/authentication-service
    /usr/bin/catalog-service
    /usr/bin/compose-executor
    /usr/bin/host-provisioner
    /usr/bin/websocket-proxy
)
base_wrappers=$(docker run --rm --entrypoint sha256sum "$base_image" \
    "${wrapper_paths[@]}")
image_wrappers=$(docker run --rm --entrypoint sha256sum "$image" \
    "${wrapper_paths[@]}")
test "$base_wrappers" = "$image_wrappers"

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
        grep -Fx "Implementation-Version: 0.183.281" >/dev/null
    cat <<'"'"'EOF'"'"' | sha256sum -c -
33c59675901c459feb478e55f731420bd2f5f3c3f27e0f6c7b4659207d025d7b  /usr/bin/authentication-service.real
ccfc75831678df31f58b327b3177da6f40d31603ab329af7bdf700a8513ea329  /usr/bin/catalog-service.real
e5c517bc7beb6857c12a7df1ffee93d87499107e12ddeca758297b930f0bb4d1  /usr/bin/catalog-service-sqlite
e429714b321db8c1a47c727bb241b3de41b74facdfb61af144237d46f3f2c47b  /usr/bin/compose-executor.real
1d06bde76920e9738da0365e9fd0ef1eac3a414785bede06b8d8665bf25a2710  /usr/bin/host-provisioner.real
fbdd12862e1cfe3c957f492ae81c4c1c5658357502bd322febbbe209496929be  /usr/bin/secret-delivery-api
f18ed969b8b5959293fdbcd55d2e28846372ab87c9348fbb315a9a490bf85ad4  /usr/bin/usage-telemetry-agent
07e807c3f66e7e75e7a45073eabbd041a74b5727e315aee96f00e5b6a801ccc5  /usr/bin/webhook-automation-service
8e24dc052faf54603c95d9187ca63b25435482ad9046825d3676ae522439c949  /usr/bin/websocket-proxy.real
a42b0649c723b76a2208467c821ff1a9b713b2c8c5ab762808c1d193bd112287  /usr/bin/govc
EOF
    for binary in \
        /usr/bin/authentication-service.real \
        /usr/bin/catalog-service.real \
        /usr/bin/catalog-service-sqlite \
        /usr/bin/compose-executor.real \
        /usr/bin/host-provisioner.real \
        /usr/bin/secret-delivery-api \
        /usr/bin/usage-telemetry-agent \
        /usr/bin/webhook-automation-service \
        /usr/bin/websocket-proxy.real \
        /usr/bin/govc \
        /usr/bin/pasturestack-console-broker; do
        test -x "${binary}"
        grep -aF "go1.27.0" "${binary}" >/dev/null
    done
    /usr/bin/authentication-service.real --version | grep -F "0.4.36" >/dev/null
    /usr/bin/catalog-service.real --version | grep -F "v0.20.11" >/dev/null
    /usr/bin/secret-delivery-api --version | grep -F "v0.3.1" >/dev/null
    /usr/bin/usage-telemetry-agent --version | grep -F "0.4.1" >/dev/null
    /usr/bin/webhook-automation-service --version | grep -F "0.10.1" >/dev/null
    test "$(/usr/bin/govc version)" = "govc 0.55.1-pasturestack.2"
    version_at_least()
    {
        local package=$1 minimum=$2 installed
        installed=$(dpkg-query -W -f='"'"'${Version}'"'"' "$package")
        dpkg --compare-versions "$installed" ge "$minimum"
    }
    version_at_least curl 8.18.0-1ubuntu2.4
    version_at_least libcurl4t64 8.18.0-1ubuntu2.4
    version_at_least libc6 2.43-2ubuntu2.3
    version_at_least systemd 259.5-0ubuntu3.4
    version_at_least libsystemd0 259.5-0ubuntu3.4
    version_at_least libudev1 259.5-0ubuntu3.4
    dpkg-query -W coreutils-from-gnu >/dev/null
    ! dpkg-query -W coreutils-from-uutils >/dev/null 2>&1
    ! dpkg-query -W rust-coreutils >/dev/null 2>&1
    ls --version | grep -Fq "GNU coreutils"
'

printf 'SERVER_API_EXPLORER_PATCH_IMAGE_OK image=%s revision=%s base=%s api_explorer_commit=%s artifact_sha256=%s bootstrap_javascript=0 runtime_go=1.27.0 ubuntu_security_refresh=2026-08-26 coreutils_provider=gnu rust_coreutils=absent orchestration_unchanged=1 wrappers_unchanged=1 web_console_unchanged=1\n' \
    "$image" "$revision" "$base_image" "$api_explorer_commit" \
    "$api_explorer_artifact_sha256"

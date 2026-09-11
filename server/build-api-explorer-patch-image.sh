#!/usr/bin/env bash
set -Eeuo pipefail

trap 'status=$?; printf "SERVER_IMAGE_BUILD_FAILED line=%s exit=%s command=%q\n" \
    "$LINENO" "$status" "$BASH_COMMAND" >&2; exit "$status"' ERR

server_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "${server_dir}/.." && pwd)
cd "$repo_root"

if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
    echo "Refusing to build a release image from an uncommitted worktree" >&2
    exit 1
fi

revision=${PASTURESTACK_SERVER_REVISION:-$(git rev-parse HEAD)}
source_date_epoch=${SOURCE_DATE_EPOCH:-$(git show -s --format=%ct HEAD)}
base_image=${BASE_IMAGE:-ghcr.io/pasturestack/server:v1.6.411@sha256:32190f9becc8462171f597789b55b4abfba7dbd30c9e152e165a5e3067d8dadb}
orchestration_engine_release_base_url=${ORCHESTRATION_ENGINE_RELEASE_BASE_URL:-https://github.com/PastureStack/orchestration-engine/releases/download}
orchestration_engine_release_tag=${ORCHESTRATION_ENGINE_RELEASE_TAG:-v0.183.297}
orchestration_engine_artifact=${ORCHESTRATION_ENGINE_ARTIFACT:-orchestration-engine-0.183.297.jar}
orchestration_engine_artifact_sha256=${ORCHESTRATION_ENGINE_ARTIFACT_SHA256:-22d126442aab342f6f94d88fc3706c50008d1e437ce86cea8f32dda81c896fb7}
orchestration_engine_commit=${ORCHESTRATION_ENGINE_COMMIT:-9beb27e228d65dc89166f681b81478addbcfc887}
api_explorer_release_base_url=${API_EXPLORER_RELEASE_BASE_URL:-https://github.com/PastureStack/api-explorer/releases/download}
api_explorer_release_tag=${API_EXPLORER_RELEASE_TAG:-v1.1.18}
api_explorer_artifact=${API_EXPLORER_ARTIFACT:-api-explorer-1.1.18.tar.gz}
api_explorer_artifact_sha256=${API_EXPLORER_ARTIFACT_SHA256:-92b718c46163018ea40c008ac552911f0eb610647377725405f4046dcd411f2c}
api_explorer_commit=${API_EXPLORER_COMMIT:-3b1c39e8a116f58649d94233a384a0362c02b43e}
web_console_release_base_url=${WEB_CONSOLE_RELEASE_BASE_URL:-https://github.com/PastureStack/web-console/releases/download}
web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-1.6.115}
web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.115.tar.gz}
web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:-a89ba273de9369665cfb223722b4bc24e692221ba66f8d489aa8a862aeed5599}
web_console_commit=${WEB_CONSOLE_COMMIT:-25dd612a380a56b5af002fbda96b8427cc6dc6a9}
websocket_proxy_release_base_url=${WEBSOCKET_PROXY_RELEASE_BASE_URL:-https://github.com/PastureStack/websocket-proxy/releases/download}
websocket_proxy_version=${WEBSOCKET_PROXY_VERSION:-0.23.14}
websocket_proxy_commit=${WEBSOCKET_PROXY_COMMIT:-3b5788bdc52f4edab0097a3d97afccf138c64089}
websocket_proxy_archive_sha256=${WEBSOCKET_PROXY_ARCHIVE_SHA256:-c55108c3dbfd8e6579fc768a1988920db83c6f605ca1284b60edf92ae8d0160e}
websocket_proxy_binary_sha256=${WEBSOCKET_PROXY_BINARY_SHA256:-efd0c78779a620b4b0f74a10eb3f3edd8886e8d23f22dc4624d8e9971085a26d}
compose_executor_version=${COMPOSE_EXECUTOR_VERSION:-0.14.36}
compose_executor_commit=${COMPOSE_EXECUTOR_COMMIT:-e85545a1bc34cb5c42db62ff90dd82b7ff9f5838}
compose_executor_archive_sha256=${COMPOSE_EXECUTOR_ARCHIVE_SHA256:-47e2ba1686c1b136c7edcac530495c3e29c351e947f0b4d08ebe68d33f98cf66}
compose_executor_binary_sha256=${COMPOSE_EXECUTOR_BINARY_SHA256:-1f542ee2dd76c7af06bc5f056c381d7e77aecaeac40f8d897df6df24a9902c0d}
vsphere_cli_bundle_version=${VSPHERE_CLI_BUNDLE_VERSION:-0.55.2}
vsphere_cli_bundle_commit=${VSPHERE_CLI_BUNDLE_COMMIT:-c4b27e87aa0dacce432a2c6108ee0752319e6d5b}
vsphere_cli_bundle_archive_sha256=${VSPHERE_CLI_BUNDLE_ARCHIVE_SHA256:-bebcc1c0275072ac40b5bc9b80f914c40a7f0431fffebc2c06fe34a34c33a57c}
govc_binary_sha256=${GOVC_BINARY_SHA256:-f8c7d82a614655c83ee119e3f170a302a9b35d9ca7efd13bbc226df2d68e5d31}
supported_docker_range='~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || >=v29.4.1 <=v29.7.2'
newest_docker_version=v29.7.2
image=${IMAGE:-pasturestack-validation/server:v1.6.427}
build_options=()

[[ "$revision" =~ ^[0-9a-f]{40}$ ]]
[[ "$source_date_epoch" =~ ^[0-9]+$ ]]
[[ "$orchestration_engine_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$orchestration_engine_artifact_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$orchestration_engine_release_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$orchestration_engine_artifact" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]
[[ "$api_explorer_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$api_explorer_artifact_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$api_explorer_release_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$api_explorer_artifact" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]
[[ "$web_console_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$web_console_artifact_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$web_console_release_tag" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$web_console_artifact" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]
[[ "$websocket_proxy_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$websocket_proxy_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$websocket_proxy_archive_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$websocket_proxy_binary_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$compose_executor_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$compose_executor_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$compose_executor_archive_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$compose_executor_binary_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$vsphere_cli_bundle_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$vsphere_cli_bundle_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$vsphere_cli_bundle_archive_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$govc_binary_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$base_image" == ghcr.io/pasturestack/server:v1.6.411@sha256:32190f9becc8462171f597789b55b4abfba7dbd30c9e152e165a5e3067d8dadb ]]
for release_base_url in "$orchestration_engine_release_base_url" "$api_explorer_release_base_url" "$web_console_release_base_url" "$websocket_proxy_release_base_url"; do
case "$release_base_url" in
    https://*) ;;
    http://127.0.0.1:*|http://localhost:*)
        [[ ${PASTURESTACK_ALLOW_LOOPBACK_ARTIFACTS:-0} == 1 ]]
        ;;
    *)
        echo "Release artifact source must use HTTPS or an explicitly allowed loopback address" >&2
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
    --build-arg "BASE_IMAGE=${base_image}" \
    --build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}" \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --build-arg "ORCHESTRATION_ENGINE_RELEASE_BASE_URL=${orchestration_engine_release_base_url}" \
    --build-arg "ORCHESTRATION_ENGINE_RELEASE_TAG=${orchestration_engine_release_tag}" \
    --build-arg "ORCHESTRATION_ENGINE_ARTIFACT=${orchestration_engine_artifact}" \
    --build-arg "ORCHESTRATION_ENGINE_ARTIFACT_SHA256=${orchestration_engine_artifact_sha256}" \
    --build-arg "ORCHESTRATION_ENGINE_COMMIT=${orchestration_engine_commit}" \
    --build-arg "API_EXPLORER_RELEASE_BASE_URL=${api_explorer_release_base_url}" \
    --build-arg "API_EXPLORER_RELEASE_TAG=${api_explorer_release_tag}" \
    --build-arg "API_EXPLORER_ARTIFACT=${api_explorer_artifact}" \
    --build-arg "API_EXPLORER_ARTIFACT_SHA256=${api_explorer_artifact_sha256}" \
    --build-arg "API_EXPLORER_COMMIT=${api_explorer_commit}" \
    --build-arg "WEB_CONSOLE_RELEASE_BASE_URL=${web_console_release_base_url}" \
    --build-arg "WEB_CONSOLE_RELEASE_TAG=${web_console_release_tag}" \
    --build-arg "WEB_CONSOLE_ARTIFACT=${web_console_artifact}" \
    --build-arg "WEB_CONSOLE_ARTIFACT_SHA256=${web_console_artifact_sha256}" \
    --build-arg "WEB_CONSOLE_COMMIT=${web_console_commit}" \
    --build-arg "WEBSOCKET_PROXY_RELEASE_BASE_URL=${websocket_proxy_release_base_url}" \
    --build-arg "WEBSOCKET_PROXY_VERSION=${websocket_proxy_version}" \
    --build-arg "WEBSOCKET_PROXY_COMMIT=${websocket_proxy_commit}" \
    --build-arg "WEBSOCKET_PROXY_ARCHIVE_SHA256=${websocket_proxy_archive_sha256}" \
    --build-arg "WEBSOCKET_PROXY_BINARY_SHA256=${websocket_proxy_binary_sha256}" \
    --build-arg "COMPOSE_EXECUTOR_VERSION=${compose_executor_version}" \
    --build-arg "COMPOSE_EXECUTOR_COMMIT=${compose_executor_commit}" \
    --build-arg "COMPOSE_EXECUTOR_ARCHIVE_SHA256=${compose_executor_archive_sha256}" \
    --build-arg "COMPOSE_EXECUTOR_BINARY_SHA256=${compose_executor_binary_sha256}" \
    --build-arg "VSPHERE_CLI_BUNDLE_VERSION=${vsphere_cli_bundle_version}" \
    --build-arg "VSPHERE_CLI_BUNDLE_COMMIT=${vsphere_cli_bundle_commit}" \
    --build-arg "VSPHERE_CLI_BUNDLE_ARCHIVE_SHA256=${vsphere_cli_bundle_archive_sha256}" \
    --build-arg "GOVC_BINARY_SHA256=${govc_binary_sha256}" \
    --build-arg "SUPPORTED_DOCKER_RANGE=${supported_docker_range}" \
    --build-arg "NEWEST_DOCKER_VERSION=${newest_docker_version}" \
    --tag "$image" \
    --file server/Dockerfile.web-compose-release \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.427
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.411
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.digest"}}')" = \
    sha256:32190f9becc8462171f597789b55b4abfba7dbd30c9e152e165a5e3067d8dadb

image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
for marker in \
    CATTLE_RANCHER_SERVER_VERSION=v1.6.427 \
    CATTLE_API_UI_VERSION=1.1.18 \
    CATTLE_CATTLE_VERSION=v0.183.297 \
    RC16_GO_AGENT_VERSION=0.13.27 \
    RC16_WINDOWS_AGENT_VERSION=0.13.27 \
    RC16_AGENT_PACKAGE_URL=/usr/share/cattle/artifacts/node-agent-0.13.27.tar.gz \
    PASTURESTACK_NODE_AGENT_VERSION=0.13.27 \
    PASTURESTACK_NODE_AGENT_COMMIT=d78a0817214bb21e3537730e68e12ebb74cbdaca \
    PASTURESTACK_ORCHESTRATION_ENGINE_COMMIT="${orchestration_engine_commit}" \
    PASTURESTACK_ORCHESTRATION_ENGINE_ARTIFACT_SHA256="${orchestration_engine_artifact_sha256}" \
    PASTURESTACK_RUNTIME_GO_VERSION=1.27.0 \
    PASTURESTACK_UBUNTU_SECURITY_REFRESH=2026-09-10 \
    PASTURESTACK_CURL_PACKAGE_VERSION=8.18.0-1ubuntu2.5 \
    PASTURESTACK_GLIBC_CVE_2026_18374_FIX=not-in-execute-path \
    PASTURESTACK_GLIBC_PACKAGE_VERSION=2.43-2ubuntu2.4 \
    PASTURESTACK_PERL_PACKAGE_VERSION=5.40.1-7ubuntu0.3 \
    PASTURESTACK_COREUTILS_PROVIDER=gnu \
    PASTURESTACK_COREUTILS_UNIQ_VERSION=9.11 \
    PASTURESTACK_COREUTILS_UNIQ_FIX=d64e35a8a4c0e4608321433e0d84d917e4e36371 \
    PASTURESTACK_ZLIB_VERSION=1.3.2 \
    PASTURESTACK_OPENSSL_VERSION=3.5.8 \
    PASTURESTACK_DIFF3_HARDENING=removed \
    PASTURESTACK_SSH_CLIENT_HARDENING=client-removed \
    PASTURESTACK_PRIVILEGED_MOUNT_HELPERS=removed \
    PASTURESTACK_RUNTIME_USER_MAPPING=removed \
    PASTURESTACK_GPG_VERIFIER=removed \
    PASTURESTACK_CONTAINER_SOURCE_BUILD_MODE=removed \
    PASTURESTACK_CONSOLE_BROKER_GO_VERSION=1.27.0 \
    PASTURESTACK_API_EXPLORER_PACKAGE=1.1.18 \
    PASTURESTACK_API_EXPLORER_COMMIT="${api_explorer_commit}" \
    PASTURESTACK_API_EXPLORER_ARTIFACT_SHA256="${api_explorer_artifact_sha256}" \
    PASTURESTACK_WEB_CONSOLE_PACKAGE="${web_console_release_tag}" \
    PASTURESTACK_WEB_CONSOLE_COMMIT="${web_console_commit}" \
    PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256="${web_console_artifact_sha256}" \
    PASTURESTACK_AUTHENTICATION_SERVICE_VERSION=0.4.36 \
    PASTURESTACK_CATALOG_SERVICE_VERSION=0.20.11 \
    PASTURESTACK_COMPOSE_EXECUTOR_VERSION="${compose_executor_version}" \
    PASTURESTACK_COMPOSE_EXECUTOR_COMMIT="${compose_executor_commit}" \
    PASTURESTACK_COMPOSE_EXECUTOR_ARCHIVE_SHA256="${compose_executor_archive_sha256}" \
    PASTURESTACK_COMPOSE_EXECUTOR_BINARY_SHA256="${compose_executor_binary_sha256}" \
    PASTURESTACK_HOST_PROVISIONER_VERSION=0.39.7 \
    PASTURESTACK_SECRET_DELIVERY_API_VERSION=0.3.1 \
    PASTURESTACK_USAGE_TELEMETRY_AGENT_VERSION=0.4.1 \
    PASTURESTACK_WEBHOOK_AUTOMATION_SERVICE_VERSION=0.10.1 \
    PASTURESTACK_WEBSOCKET_PROXY_VERSION="${websocket_proxy_version}" \
    PASTURESTACK_WEBSOCKET_PROXY_COMMIT="${websocket_proxy_commit}" \
    PASTURESTACK_WEBSOCKET_PROXY_ARCHIVE_SHA256="${websocket_proxy_archive_sha256}" \
    PASTURESTACK_WEBSOCKET_PROXY_BINARY_SHA256="${websocket_proxy_binary_sha256}" \
    PASTURESTACK_VSPHERE_CLI_BUNDLE_VERSION="${vsphere_cli_bundle_version}" \
    PASTURESTACK_VSPHERE_CLI_BUNDLE_COMMIT="${vsphere_cli_bundle_commit}" \
    PASTURESTACK_VSPHERE_CLI_BUNDLE_ARCHIVE_SHA256="${vsphere_cli_bundle_archive_sha256}" \
    PASTURESTACK_GOVC_BINARY_SHA256="${govc_binary_sha256}" \
    PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-08-28 \
    PASTURESTACK_CATALOG_COMMIT=02df5f7df9eebe640590d93b1506543d2367e355 \
    'DEFAULT_CATTLE_CATALOG_URL={"catalogs":{"pasturestack":{"url":"https://github.com/PastureStack/catalog-templates.git","branch":"main","pinnedCommit":"02df5f7df9eebe640590d93b1506543d2367e355"}}}' \
    'CATTLE_CATALOG_URL={"catalogs":{"pasturestack":{"url":"https://github.com/PastureStack/catalog-templates.git","branch":"main","pinnedCommit":"02df5f7df9eebe640590d93b1506543d2367e355"}}}'; do
    test "$(grep -Fxc "$marker" <<<"$image_environment")" = 1
done

docker run --rm --entrypoint bash "$image" -lc '
    set -euo pipefail
    for package in libc6 libc-bin libc-gconv-modules-extra; do
        test "$(dpkg-query -W -f='"'"'${Version}'"'"' "${package}")" = "2.43-2ubuntu2.4"
    done
    for package in libperl5.40 perl perl-base perl-modules-5.40; do
        test "$(dpkg-query -W -f='"'"'${Version}'"'"' "${package}")" = "5.40.1-7ubuntu0.3"
    done
    active_entrypoints=(
        /usr/bin/entry
        /usr/share/cattle/cattle.sh
        /usr/share/cattle/cattle.jar
        /service/cattle/run
        /service/mysql/run
        /service/console-broker/run
        /service/graphite_exporter/run
        /usr/bin/authentication-service
        /usr/bin/catalog-service
        /usr/bin/compose-executor
        /usr/bin/host-provisioner
        /usr/bin/websocket-proxy
    )
    for entrypoint in "${active_entrypoints[@]}"; do
        test -f "${entrypoint}"
    done
    if grep -a -n -E '"'"'(^#!.*perl|/usr/bin/perl|/usr/bin/env[[:space:]]+perl|(^|[[:space:]])perl([[:space:]]|$)|pack_ip_mreq_source|Storable|SX_HOOK|,ccs=)'"'"' \
        "${active_entrypoints[@]}"; then
        echo "A Server runtime entrypoint reaches a reviewed Perl or glibc fopen mode vulnerability" >&2
        exit 1
    fi
'

docker run --rm --entrypoint sh "$image" -eu -c '
    printf "%s\n" \
      "0cbf93ef6f90db8c5f6b8cf7d63c99f452b8fc43e93097a21cdb5bcc3007d475  /usr/share/cattle/artifacts/node-agent-0.13.27.tar.gz" \
      "b6a56f8833c31bc224b7baf20ceb1a252c027021efbe6265c1906f8478d7c2fa  /usr/share/cattle/artifacts/node-agent-0.13.27-windows-amd64.zip" | sha256sum -c -
    test "$(readlink /usr/share/cattle/artifacts/go-agent.tar.gz)" = node-agent-0.13.27.tar.gz
    . /usr/share/cattle/env_vars
    test "$CATTLE_AGENT_PACKAGE_PYTHON_AGENT_URL" = /usr/share/cattle/artifacts/node-agent-0.13.27.tar.gz
    test "$CATTLE_AGENT_PACKAGE_WINDOWS_AGENT_URL" = /usr/share/cattle/artifacts/node-agent-0.13.27-windows-amd64.zip
'

image_orchestration=$(docker run --rm --entrypoint sha256sum "$image" \
    /usr/share/cattle/cattle.jar)
test "$image_orchestration" = \
    "${orchestration_engine_artifact_sha256}  /usr/share/cattle/cattle.jar"

docker run --rm --entrypoint bash "$image" -lc '
    set -euo pipefail
    engine_hash=$(sha256sum /usr/share/cattle/cattle.jar | awk "{print \$1}")
    web_root=$(readlink -f /usr/share/cattle/war)
    test "${web_root}" = "/usr/share/cattle/${engine_hash}"
    resources_jar=$(find "${web_root}/WEB-INF/lib" -maxdepth 1 -type f \
        -name "cattle-resources-0.183.297.jar" -print -quit)
    test -n "${resources_jar}"
    unzip -p "${resources_jar}" db/core-124.xml |
        grep -F "pasturestack-catalog-pinned-commit" >/dev/null
    unzip -p "${resources_jar}" schema/service/service-auth.json |
        grep -F "\"subscribe\": \"cr\"" >/dev/null
    unzip -p "${resources_jar}" db/core-125.xml |
        grep -F "pasturestack-credential-secret-value-mediumtext" >/dev/null
    app_config_jar=$(find "${web_root}/WEB-INF/lib" -maxdepth 1 -type f \
        -name "cattle-app-config-*.jar" -print -quit)
    test -n "${app_config_jar}"
    unzip -p "${app_config_jar}" META-INF/cattle/api-server/defaults.properties |
        grep -Fx "supported.docker.range=~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || >=v29.4.1 <=v29.7.2" >/dev/null
    unzip -p "${app_config_jar}" META-INF/cattle/api-server/defaults.properties |
        grep -Fx "newest.docker.version=v29.7.2" >/dev/null
'

wrapper_paths=(
    /usr/bin/authentication-service
    /usr/bin/catalog-service
    /usr/bin/compose-executor
    /usr/bin/host-provisioner
)
launcher_wrapper_sha256=57b6422dc4a51d4c5448306a4efad182517ed1622bba1257df3c270c5c23ee47
image_wrappers=$(docker run --rm --entrypoint sha256sum "$image" \
    "${wrapper_paths[@]}")
expected_image_wrappers=$(
    for wrapper_path in "${wrapper_paths[@]}"; do
        printf '%s  %s\n' "$launcher_wrapper_sha256" "$wrapper_path"
    done
)
if [[ "$image_wrappers" != "$expected_image_wrappers" ]]; then
    printf 'SERVER_LAUNCHER_WRAPPER_INVALID expected_sha256=%s\n%s\n' \
        "$launcher_wrapper_sha256" "$image_wrappers" >&2
    exit 1
fi

websocket_wrapper_sha256=$(sha256sum server/patches/websocket-proxy-wrapper.sh | awk '{print $1}')
test "$(docker run --rm --entrypoint sha256sum "$image" /usr/bin/websocket-proxy)" = \
    "${websocket_wrapper_sha256}  /usr/bin/websocket-proxy"
docker run --rm --entrypoint bash "$image" -lc 'test -x /usr/bin/websocket-proxy'

docker run --rm --entrypoint bash "$image" -lc '
    set -euo pipefail
    web_root=$(readlink -f /usr/share/cattle/war)
    test "$(cat "${web_root}/VERSION.txt")" = "1.6.115"
    test "$(find "${web_root}/translations" -maxdepth 1 -type f -name "*.json" | wc -l)" -eq 13
    test ! -e "${web_root}/translations/none.json"
    test -z "$(find "${web_root}" -type f -name "*.map" -print -quit)"
    ui_entry=$(find "${web_root}/assets" -maxdepth 1 -type f -name "ui-*.js" -print -quit)
    test -n "${ui_entry}"
    for marker in \
        audit-log-filter-panel \
        service-log-filter-panel \
        service.instance.restart \
        created_gte \
        created_lte \
        authenticatedAsAccountId \
        interactionChannel \
        eventTypeOperator \
        descriptionOperator \
        audit-date-picker \
        openDateCalendar \
        data-bs-display \
        basic-dropdown-wormhole \
        _notlike; do
        grep -aF "${marker}" "${ui_entry}" >/dev/null
    done
    grep -aF "ember-basic-dropdown-wormhole" "${web_root}"/assets/*.js >/dev/null
    for theme_asset in ui-light.css ui-light.rtl.css ui-dark.css ui-dark.rtl.css; do
        grep -F ".audit-log-filter-panel" "${web_root}/assets/${theme_asset}" >/dev/null
        grep -F ".audit-log-filter-primary-grid" "${web_root}/assets/${theme_asset}" >/dev/null
        grep -F ".audit-log-filter-condition" "${web_root}/assets/${theme_asset}" >/dev/null
        grep -F ".audit-date-calendar" "${web_root}/assets/${theme_asset}" >/dev/null
        grep -F "footer .footer-dropdown .dropdown-menu" "${web_root}/assets/${theme_asset}" >/dev/null
        grep -F ".form-resources .resource-host-guidance" "${web_root}/assets/${theme_asset}" >/dev/null
        grep -F ".form-resources .resource-advanced-content.resource-advanced-grid" "${web_root}/assets/${theme_asset}" >/dev/null
        grep -F "table.audit-log-results-table[data-resizable-columns=true]:not(.table-column-measuring) > thead > th.audit-log-auth-ip-heading" "${web_root}/assets/${theme_asset}" >/dev/null
        grep -F -A 6 "table.audit-log-results-table[data-resizable-columns=true]:not(.table-column-measuring) > thead > th.audit-log-auth-ip-heading" "${web_root}/assets/${theme_asset}" | grep -F "white-space: normal;" >/dev/null
    done
    grep -F "篩選稽核日誌" "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"formResources.addUlimit\":\"新增限制\"" \
        "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "篩選服務日誌" "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "開始時間必須早於結束時間" "${web_root}/translations/zh-tw.json" >/dev/null
    for locale in de-de fa-ir fil-ph fr-fr hu-hu ja-jp ko-kr pt-br ru-ru uk-ua zh-hans zh-tw; do
        locale_file="${web_root}/translations/${locale}.json"
        grep -F "\"auditLogsPage.filterBuilder.title\":" "${locale_file}" >/dev/null
        grep -F "\"auditLogsPage.filterBuilder.timeDialog.calendar.today\":" "${locale_file}" >/dev/null
        ! grep -F "\"auditLogsPage.filterBuilder.title\":\"Filter audit logs\"" "${locale_file}" >/dev/null
        ! grep -F "\"auditLogsPage.filterBuilder.timeDialog.calendar.today\":\"Today\"" "${locale_file}" >/dev/null
    done
    grep -F "\"auditLogsPage.filterBuilder.timeDialog.calendar.today\":\"Today\"" "${web_root}/translations/en-us.json" >/dev/null
'

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
    grep -F '"'"'"version": "1.1.18"'"'"' "${api_dir}/version.json" >/dev/null
    grep -F '"'"'"commit": "3b1c39e"'"'"' "${api_dir}/version.json" >/dev/null
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
    test -n "${ui_entry}"
    grep -aF "ui/utils/bootstrap-runtime" "${ui_entry}" >/dev/null
    grep -aF "window.bootstrap=" "${ui_entry}" >/dev/null
    grep -F '"'"'"authPage.mfa.email.systemManaged":"SMTP 寄信服務由系統管理員集中設定，全系統共用。您的帳號不會儲存 SMTP 伺服器、寄件者或密碼。"'"'"' \
        /usr/share/cattle/war/translations/zh-tw.json >/dev/null
    unzip -p /usr/share/cattle/cattle.jar META-INF/MANIFEST.MF |
        tr -d "\r" |
        grep -Fx "Implementation-Version: 0.183.297" >/dev/null
    hazelcast_entry=$(unzip -Z1 /usr/share/cattle/cattle.jar |
        grep -E "^WEB-INF/lib/hazelcast-[^/]+[.]jar$")
    test "${hazelcast_entry}" = "WEB-INF/lib/hazelcast-5.7.4.jar"
    unzip -p /usr/share/cattle/cattle.jar "${hazelcast_entry}" >/tmp/hazelcast.jar
    echo "6b768e6cff9e5281e77ad14e609b69bac6856ecd4469af827f566be95553644c  /tmp/hazelcast.jar" |
        sha256sum -c -
    rm -f /tmp/hazelcast.jar
    cat <<'"'"'EOF'"'"' | sha256sum -c -
33c59675901c459feb478e55f731420bd2f5f3c3f27e0f6c7b4659207d025d7b  /usr/bin/authentication-service.real
ccfc75831678df31f58b327b3177da6f40d31603ab329af7bdf700a8513ea329  /usr/bin/catalog-service.real
e5c517bc7beb6857c12a7df1ffee93d87499107e12ddeca758297b930f0bb4d1  /usr/bin/catalog-service-sqlite
1f542ee2dd76c7af06bc5f056c381d7e77aecaeac40f8d897df6df24a9902c0d  /usr/bin/compose-executor.real
bce26b98133d3f5d4ecaddba26179ed8e14e5b260b38dee5f9e4383cbfbc855a  /usr/bin/host-provisioner.real
fbdd12862e1cfe3c957f492ae81c4c1c5658357502bd322febbbe209496929be  /usr/bin/secret-delivery-api
f18ed969b8b5959293fdbcd55d2e28846372ab87c9348fbb315a9a490bf85ad4  /usr/bin/usage-telemetry-agent
07e807c3f66e7e75e7a45073eabbd041a74b5727e315aee96f00e5b6a801ccc5  /usr/bin/webhook-automation-service
efd0c78779a620b4b0f74a10eb3f3edd8886e8d23f22dc4624d8e9971085a26d  /usr/bin/websocket-proxy.real
f8c7d82a614655c83ee119e3f170a302a9b35d9ca7efd13bbc226df2d68e5d31  /usr/bin/govc
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
    test "$(/usr/bin/compose-executor.real --version)" = \
        "pasturestack-compose version ${PASTURESTACK_COMPOSE_EXECUTOR_VERSION}"
    for ssh_binary in /usr/bin/host-provisioner.real /usr/bin/compose-executor.real; do
        grep -aF "$(printf "dep\tgolang.org/x/crypto\tv0.56.0\t")" "${ssh_binary}" >/dev/null
    done
    /usr/bin/catalog-service.real --version | grep -F "v0.20.11" >/dev/null
    /usr/bin/secret-delivery-api --version | grep -F "v0.3.1" >/dev/null
    /usr/bin/usage-telemetry-agent --version | grep -F "0.4.1" >/dev/null
    /usr/bin/webhook-automation-service --version | grep -F "0.10.1" >/dev/null
    test "$(/usr/bin/govc version)" = "govc 0.55.2"
    version_at_least()
    {
        local package=$1 minimum=$2 installed
        installed=$(dpkg-query -W -f='"'"'${Version}'"'"' "$package")
        dpkg --compare-versions "$installed" ge "$minimum"
    }
    package_is_installed()
    {
        local status
        status=$(dpkg-query -W -f='"'"'${db:Status-Status}'"'"' "$1" 2>/dev/null || true)
        test "$status" = installed
    }
    for curl_package in curl libcurl3t64-gnutls libcurl4t64; do
        test "$(dpkg-query -W -f='"'"'${Version}'"'"' "${curl_package}")" = \
            "8.18.0-1ubuntu2.5"
    done
    for glibc_package in libc6 libc-bin libc-gconv-modules-extra; do
        test "$(dpkg-query -W -f='"'"'${Version}'"'"' "${glibc_package}")" = \
            "2.43-2ubuntu2.4"
    done
    for perl_package in libperl5.40 perl perl-base perl-modules-5.40; do
        test "$(dpkg-query -W -f='"'"'${Version}'"'"' "${perl_package}")" = \
            "5.40.1-7ubuntu0.3"
    done
    version_at_least libssh2-1t64 1.11.1-1ubuntu0.26.04.4
    version_at_least systemd 259.5-0ubuntu3.4
    version_at_least libsystemd0 259.5-0ubuntu3.4
    version_at_least libudev1 259.5-0ubuntu3.4
    version_at_least gnu-coreutils 9.7-3ubuntu2.1
    version_at_least bsdutils 1:2.41.3-3ubuntu2.2
    version_at_least libblkid1 2.41.3-3ubuntu2.2
    version_at_least libmount1 2.41.3-3ubuntu2.2
    version_at_least libsmartcols1 2.41.3-3ubuntu2.2
    version_at_least libuuid1 2.41.3-3ubuntu2.2
    version_at_least login 1:4.16.0-2+really2.41.3-3ubuntu2.2
    version_at_least mount 2.41.3-3ubuntu2.2
    version_at_least util-linux 2.41.3-3ubuntu2.2
    version_at_least git 1:2.53.0-1ubuntu1
    version_at_least git-man 1:2.53.0-1ubuntu1
    version_at_least libexpat1 2.7.4-1
    package_is_installed coreutils-from-gnu
    ! package_is_installed coreutils-from-uutils
    ! package_is_installed rust-coreutils
    ls --version | grep -Fq "GNU coreutils"
    test "$(git --version)" = "git version 2.53.0"
    uniq --version | grep -Fq "uniq (GNU coreutils) 9.11"
    longline="$(printf "\360\237\230\200"; head -c 255 /dev/zero | tr "\000" A)"
    printf "%s\n%s\n" "${longline}" "${longline}" >/tmp/uniq-input
    printf "%s\n" "${longline}" >/tmp/uniq-expected
    LC_ALL=C.UTF-8 uniq -w256 /tmp/uniq-input >/tmp/uniq-output
    cmp /tmp/uniq-expected /tmp/uniq-output
    grep -aF "1.3.2" /usr/lib/x86_64-linux-gnu/libz.so.1.3.2 >/dev/null
    ldd /usr/sbin/mariadbd | grep -F "/usr/lib/x86_64-linux-gnu/libz.so.1" >/dev/null
    openssl version | grep -F "OpenSSL 3.5.8 25 Aug 2026" >/dev/null
    test "$(openssl version -d)" = "OPENSSLDIR: \"/usr/lib/ssl\""
    test "$(openssl version -e)" = "ENGINESDIR: \"/usr/lib/x86_64-linux-gnu/engines-3\""
    test "$(openssl version -m)" = "MODULESDIR: \"/usr/lib/x86_64-linux-gnu/ossl-modules\""
    openssl list -providers -provider legacy | grep -F "OpenSSL Legacy Provider" >/dev/null
    ldd /usr/bin/curl | grep -F "/usr/lib/x86_64-linux-gnu/libssl.so.3" >/dev/null
    ldd /usr/bin/curl | grep -F "/usr/lib/x86_64-linux-gnu/libcrypto.so.3" >/dev/null
    ldd /usr/sbin/mariadbd | grep -F "/usr/lib/x86_64-linux-gnu/libssl.so.3" >/dev/null
    ldd /usr/sbin/mariadbd | grep -F "/usr/lib/x86_64-linux-gnu/libcrypto.so.3" >/dev/null
    for removed_package in fontconfig keychain libfontconfig1 openssh-client; do
        ! package_is_installed "${removed_package}"
    done
    for removed_path in \
        /usr/bin/gpgv \
        /usr/bin/gpgsm \
        /usr/bin/eu-readelf \
        /usr/bin/eu-strip \
        /usr/bin/diff3 \
        /usr/bin/getfattr \
        /usr/bin/login \
        /usr/bin/mount \
        /usr/bin/p11-kit \
        /usr/bin/setfattr \
        /usr/bin/ssh \
        /usr/bin/tar \
        /usr/bin/unexpand \
        /etc/login.defs \
        /etc/subgid \
        /etc/subuid \
        /usr/lib/git-core/git-http-push \
        /usr/lib/x86_64-linux-gnu/libexpat.so.1 \
        /usr/lib/x86_64-linux-gnu/libexpat.so.1.11.2 \
        /usr/lib/systemd/systemd-journald \
        /usr/libexec/p11-kit/p11-kit-server \
        /usr/share/cattle/install_cattle_binaries; do
        test ! -e "${removed_path}"
    done
    ! ldconfig -p | grep -Fq "libexpat.so"
    test -z "$(find /run -xdev -type s -path "*p11-kit*" -print -quit 2>/dev/null)"
    libgcrypt_user="$(
        find /usr/bin /usr/sbin /usr/share/cattle -xdev -type f -perm /0111 -print0 |
        while IFS= read -r -d "" executable; do
            if ldd "${executable}" 2>/dev/null | grep -Fq "libgcrypt.so"; then
                printf "%s\n" "${executable}"
            fi
        done | head -n 1
    )"
    test -z "${libgcrypt_user}"
    if grep -Eq "(^|[[:space:]])(git clone|git -C|apt-get install|tar xzf)([[:space:]]|$)" /usr/share/cattle/cattle.sh; then
        exit 1
    fi
'

printf 'SERVER_API_EXPLORER_PATCH_IMAGE_OK image=%s revision=%s base=%s orchestration=%s orchestration_commit=%s orchestration_sha256=%s api_explorer=%s api_explorer_commit=%s artifact_sha256=%s web_console=%s web_console_commit=%s web_console_sha256=%s websocket_proxy=%s websocket_proxy_commit=%s websocket_proxy_archive_sha256=%s websocket_proxy_binary_sha256=%s compose_executor=%s compose_executor_commit=%s compose_executor_archive_sha256=%s compose_executor_binary_sha256=%s vsphere_cli=%s vsphere_cli_commit=%s vsphere_cli_archive_sha256=%s govc_binary_sha256=%s audit_log_filters=1 audit_calendar_localized=1 footer_menus_bounded=1 resource_layout=attached-responsive docker_29_range=29.4.1..29.7.2 docker_29_6_2=supported bootstrap_javascript=0 runtime_go=1.27.0 ubuntu_security_refresh=2026-09-10 curl=8.18.0-1ubuntu2.5 glibc=2.43-2ubuntu2.4 glibc_cve_2026_18374=not-in-execute-path upstream_package_review_pending=1 perl=5.40.1-7ubuntu0.3 coreutils_uniq=9.11+d64e35a8 openssl=3.5.8 zlib=1.3.2 diff3=removed source_build_mode=removed runtime_tar=removed ssh_client=removed orchestration_updated=1 wrappers_pinned=1\n' \
    "$image" "$revision" "$base_image" "${orchestration_engine_release_tag#v}" \
    "$orchestration_engine_commit" "$orchestration_engine_artifact_sha256" \
    "${api_explorer_release_tag#v}" "$api_explorer_commit" "$api_explorer_artifact_sha256" \
    "$web_console_release_tag" "$web_console_commit" "$web_console_artifact_sha256" \
    "$websocket_proxy_version" "$websocket_proxy_commit" \
    "$websocket_proxy_archive_sha256" "$websocket_proxy_binary_sha256" \
    "$compose_executor_version" "$compose_executor_commit" \
    "$compose_executor_archive_sha256" "$compose_executor_binary_sha256" \
    "$vsphere_cli_bundle_version" "$vsphere_cli_bundle_commit" \
    "$vsphere_cli_bundle_archive_sha256" "$govc_binary_sha256"

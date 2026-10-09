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
server_release_tag=${SERVER_RELEASE_TAG:-v1.6.519}
source_date_epoch=${SOURCE_DATE_EPOCH:-$(git show -s --format=%ct HEAD)}
base_image=${BASE_IMAGE:-ghcr.io/pasturestack/server:v1.6.460@sha256:c855af8aea232dacc5bb6df68e2271d482c68b53c43ab0c108ec19118f5ab403}
orchestration_engine_release_base_url=${ORCHESTRATION_ENGINE_RELEASE_BASE_URL:-https://github.com/PastureStack/orchestration-engine/releases/download}
orchestration_engine_release_tag=${ORCHESTRATION_ENGINE_RELEASE_TAG:-v0.183.334}
orchestration_engine_artifact=${ORCHESTRATION_ENGINE_ARTIFACT:-cattle.jar}
orchestration_engine_artifact_sha256=${ORCHESTRATION_ENGINE_ARTIFACT_SHA256:-b0e3608b21ce405cdaf2f74699442b9420844384055f85acf88cfeb638600490}
orchestration_engine_commit=${ORCHESTRATION_ENGINE_COMMIT:-91f44685953f7cc72344a21cb47ca235c0bce53f}
orchestration_engine_version=${orchestration_engine_release_tag#v}
engine_readonly_schema_sha256=${ENGINE_READONLY_SCHEMA_SHA256:-7f274219e8dd9c6d750a408a6edec1448b564f4b16ba2204c425c5b45cec2233}
engine_restricted_schema_sha256=${ENGINE_RESTRICTED_SCHEMA_SHA256:-f854ba99260f29e324ab7446a8592996946038920ac9bcf17689d98d1ebc5e51}
host_api_version=${HOST_API_VERSION:-0.38.5}
host_api_package_mode=${HOST_API_PACKAGE_MODE:-producer}
host_api_release_base_url=${HOST_API_RELEASE_BASE_URL:-https://github.com/PastureStack/host-api/releases/download}
host_api_release_tag=${HOST_API_RELEASE_TAG:-v0.38.5}
host_api_archive_sha256=${HOST_API_ARCHIVE_SHA256:-ba111038695aa03a82c51d60944bbbdbbec30bb269051ba29fa21d46ada17179}
host_api_package_id=${HOST_API_PACKAGE_ID:-84754fe8bc79027d0c72f492923c4786}
host_api_binary_sha256=${HOST_API_BINARY_SHA256:-fda5080d6cfec0a4c1e9daf15b43cea2dce7ffb116c8292ff0f3547c8fb371f7}
host_api_apply_sha256=${HOST_API_APPLY_SHA256:-8a21f63099832afb571755011bbcf8d97710994a50c419b20700cbc31efced0f}
host_api_commit=${HOST_API_COMMIT:-84754fe8bc79027d0c72f492923c47861aa74b99}
node_agent_version=${NODE_AGENT_VERSION:-0.13.28}
node_agent_release_base_url=${NODE_AGENT_RELEASE_BASE_URL:-https://github.com/PastureStack/node-agent/releases/download}
node_agent_commit=${NODE_AGENT_COMMIT:-bb4e057c089e5384bc9836b42db206326c690387}
node_agent_package_id=${NODE_AGENT_PACKAGE_ID:-${node_agent_commit:0:32}}
node_agent_archive_sha256=${NODE_AGENT_ARCHIVE_SHA256:-a16ae6be5fb72fa2ba38bd1076fd3b9e0536c48e70995ffa49d17b8063e2f8d0}
node_agent_binary_sha256=${NODE_AGENT_BINARY_SHA256:-ce8342e10da07c50cc414b471cadc67db4dd390e6e2dcb632b30c542f658b021}
node_agent_apply_sha256=${NODE_AGENT_APPLY_SHA256:-dd8cb342518a43e7468cc121db5c4e44b16731f2620b77ea0fd03c02c03766a9}
component_artifact_mode=remote
api_explorer_release_base_url=${API_EXPLORER_RELEASE_BASE_URL:-https://github.com/PastureStack/api-explorer/releases/download}
api_explorer_release_tag=${API_EXPLORER_RELEASE_TAG:-v1.1.18}
api_explorer_artifact=${API_EXPLORER_ARTIFACT:-api-explorer-1.1.18.tar.gz}
api_explorer_artifact_sha256=${API_EXPLORER_ARTIFACT_SHA256:-92b718c46163018ea40c008ac552911f0eb610647377725405f4046dcd411f2c}
api_explorer_commit=${API_EXPLORER_COMMIT:-3b1c39e8a116f58649d94233a384a0362c02b43e}
web_console_release_base_url=${WEB_CONSOLE_RELEASE_BASE_URL:-https://github.com/PastureStack/web-console/releases/download}
web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-1.6.181}
web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.181.tar.gz}
web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:-82bf7c4107a6834c96e41230a7b57efe7e0cf6c1e57b9a74e16da295863ab891}
web_console_commit=${WEB_CONSOLE_COMMIT:-72851518ba024777146f8eae9909484d7adba230}
catalog_service_release_base_url=${CATALOG_SERVICE_RELEASE_BASE_URL:-https://github.com/PastureStack/catalog-service/releases/download}
catalog_service_version=${CATALOG_SERVICE_VERSION:-0.20.13}
catalog_service_commit=${CATALOG_SERVICE_COMMIT:-4c39c73a8131ba06e9ff0aaec3b95cc27e049324}
catalog_service_archive_sha256=${CATALOG_SERVICE_ARCHIVE_SHA256:-29626181cb8489b016e5975ffaddc00b2a32d290b1c0066e833d27fa7a5edf83}
catalog_service_binary_sha256=${CATALOG_SERVICE_BINARY_SHA256:-7224c76e5643130dee047e3f1888ce6845d024307bec74d72eebdc4baeae1aea}
catalog_service_sqlite_binary_sha256=${CATALOG_SERVICE_SQLITE_BINARY_SHA256:-4aeda3e1ee1ca4c57f26938f3ef27651f9c8c129ee12957642960d22b95034ce}
catalog_service_license_sha256=${CATALOG_SERVICE_LICENSE_SHA256:-0d542e0c8804e39aa7f37eb00da5a762149dc682d7829451287e11b938e94594}
authentication_service_release_base_url=${AUTHENTICATION_SERVICE_RELEASE_BASE_URL:-https://github.com/PastureStack/authentication-service/releases/download}
authentication_service_version=${AUTHENTICATION_SERVICE_VERSION:-0.4.43}
authentication_service_commit=${AUTHENTICATION_SERVICE_COMMIT:-cae736f377019bd9743648a8e9aa469a0e21b5e0}
authentication_service_archive_sha256=${AUTHENTICATION_SERVICE_ARCHIVE_SHA256:-e9218771af8dd68323c8c6fdab149c40a3ad02da9ff23f8aad6f0b2977740273}
authentication_service_binary_sha256=${AUTHENTICATION_SERVICE_BINARY_SHA256:-fe11eec4b31b43863b49a582b1dbbe309eae08fb78adc150037981174f0622da}
websocket_proxy_release_base_url=${WEBSOCKET_PROXY_RELEASE_BASE_URL:-https://github.com/PastureStack/websocket-proxy/releases/download}
websocket_proxy_version=${WEBSOCKET_PROXY_VERSION:-0.23.15}
websocket_proxy_commit=${WEBSOCKET_PROXY_COMMIT:-1928f602b66443cdab40c8cdb450c811548d2749}
websocket_proxy_archive_sha256=${WEBSOCKET_PROXY_ARCHIVE_SHA256:-4657338973f672f6ae4d6e5510d06e811b9951afea1baa27a9caa3034e487f2a}
websocket_proxy_binary_sha256=${WEBSOCKET_PROXY_BINARY_SHA256:-9111d5a569b6326d7cd71fc3384251d9684972492a22e1e9dbbb9863019fbaaa}
webhook_automation_service_release_base_url=${WEBHOOK_AUTOMATION_SERVICE_RELEASE_BASE_URL:-https://github.com/PastureStack/webhook-automation-service/releases/download}
webhook_automation_service_version=${WEBHOOK_AUTOMATION_SERVICE_VERSION:-0.10.4}
webhook_automation_service_commit=${WEBHOOK_AUTOMATION_SERVICE_COMMIT:-400118b893843d2a7d7c65cc70c3449d76c4a8d8}
webhook_automation_service_archive_sha256=${WEBHOOK_AUTOMATION_SERVICE_ARCHIVE_SHA256:-49c4579829a04e758045fae02a5a9fca12bb0ba3af0d5e979cf9eb97f23a88a9}
webhook_automation_service_binary_sha256=${WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256:-98c7faea665b7eb95206b8c73a6f47d644c5d2d0eae53f274f6a15faf5205744}
compose_executor_release_base_url=${COMPOSE_EXECUTOR_RELEASE_BASE_URL:-https://github.com/PastureStack/compose-cli/releases/download}
compose_executor_version=${COMPOSE_EXECUTOR_VERSION:-0.14.37}
compose_executor_commit=${COMPOSE_EXECUTOR_COMMIT:-88e991e823f06d2334c07d5370595aae3c48ee99}
compose_executor_archive_sha256=${COMPOSE_EXECUTOR_ARCHIVE_SHA256:-5ff465601930218f531885a384f231d969033e4cef794ce33d16bfe24e5c1c81}
compose_executor_binary_sha256=${COMPOSE_EXECUTOR_BINARY_SHA256:-a9bf9f0f77e914fe557d3e178a73c31526b0ca0adc4afbf17bf68d8d75c7ee27}
vsphere_cli_bundle_release_base_url=${VSPHERE_CLI_BUNDLE_RELEASE_BASE_URL:-https://github.com/PastureStack/vsphere-cli-bundle/releases/download}
vsphere_cli_bundle_version=${VSPHERE_CLI_BUNDLE_VERSION:-0.55.3}
vsphere_cli_bundle_commit=${VSPHERE_CLI_BUNDLE_COMMIT:-f48ab9fd9990132c85845fc162186a04f1e0418d}
vsphere_cli_bundle_archive_sha256=${VSPHERE_CLI_BUNDLE_ARCHIVE_SHA256:-31be702e515741686e2c665d387562e5e993c5d2ffbdb2d614ed287243b166e4}
govc_binary_sha256=${GOVC_BINARY_SHA256:-d3c4f4fab44403ec4110743b52da99f5ce3d7e3773c4661db8a87dec3ead8990}
host_provisioner_release_base_url=${HOST_PROVISIONER_RELEASE_BASE_URL:-https://github.com/PastureStack/host-provisioner/releases/download}
host_provisioner_version=${HOST_PROVISIONER_VERSION:-0.39.8}
host_provisioner_commit=${HOST_PROVISIONER_COMMIT:-385e5b536c108f17fdfcdec84c01750a5be5ab1c}
host_provisioner_archive_sha256=${HOST_PROVISIONER_ARCHIVE_SHA256:-d775f36a613b1a486a5e60d6ad61fdbd1ebb4bd22422cbb6dcb70fdd7c4abf0c}
host_provisioner_binary_sha256=${HOST_PROVISIONER_BINARY_SHA256:-1d37e20a7a1cf4f3e36036a15ff7699ef22cd8809fd14a20892034dd054fd1fc}
secret_delivery_api_release_base_url=${SECRET_DELIVERY_API_RELEASE_BASE_URL:-https://github.com/PastureStack/secret-delivery-api/releases/download}
secret_delivery_api_version=${SECRET_DELIVERY_API_VERSION:-0.3.2}
secret_delivery_api_commit=${SECRET_DELIVERY_API_COMMIT:-53060369b29946b1f1b62e5fabbcfc8778c55bb6}
secret_delivery_api_archive_sha256=${SECRET_DELIVERY_API_ARCHIVE_SHA256:-8a5e6da29db8f7b55ab3291b0270e843a5c15e67154fa075575d8b84f4bc0ae9}
secret_delivery_api_binary_sha256=${SECRET_DELIVERY_API_BINARY_SHA256:-c263f61fd01423da30e06addc4385817fe683df42c299e53f27a812d8621e777}
usage_telemetry_agent_release_base_url=${USAGE_TELEMETRY_AGENT_RELEASE_BASE_URL:-https://github.com/PastureStack/usage-telemetry-agent/releases/download}
usage_telemetry_agent_version=${USAGE_TELEMETRY_AGENT_VERSION:-0.4.2}
usage_telemetry_agent_commit=${USAGE_TELEMETRY_AGENT_COMMIT:-40f9af7ca932fedacdb87e30b4ef1c60a4a7444e}
usage_telemetry_agent_archive_sha256=${USAGE_TELEMETRY_AGENT_ARCHIVE_SHA256:-5ce031c84f76b3e62dafdb04fb4ed014aa1921e83be056c2d5dd712acbce25a8}
usage_telemetry_agent_binary_sha256=${USAGE_TELEMETRY_AGENT_BINARY_SHA256:-e62a21270142181315293d7e11482288ffe8fc4d91cc8fe07dacc90b461f3709}
supported_docker_range='~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || >=v29.4.1 <=v29.7.2 || v29.8.0'
newest_docker_version=v29.8.0
image=${IMAGE:-pasturestack-validation/server:v1.6.519}
build_options=()

[[ "$revision" =~ ^[0-9a-f]{40}$ ]]
[[ "$server_release_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$host_api_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$host_api_release_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$host_api_package_id" =~ ^[0-9a-f]{32}$ ]]
[[ "$node_agent_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$node_agent_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$node_agent_package_id" == "${node_agent_commit:0:32}" ]]
for component_hash in "$host_api_archive_sha256" "$host_api_binary_sha256" "$host_api_apply_sha256" "$engine_readonly_schema_sha256" "$engine_restricted_schema_sha256" "$node_agent_archive_sha256" "$node_agent_binary_sha256" "$node_agent_apply_sha256"; do
    [[ "$component_hash" =~ ^[0-9a-f]{64}$ ]]
done
if [[ "$host_api_package_mode" == legacy-repair ]]; then
    [[ "$host_api_version" == 0.38.4 ]]
else
    [[ "$host_api_package_mode" == producer && "$host_api_commit" =~ ^[0-9a-f]{40}$ ]]
fi
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
[[ "$catalog_service_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$catalog_service_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$catalog_service_archive_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$catalog_service_binary_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$catalog_service_sqlite_binary_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$catalog_service_license_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$authentication_service_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$authentication_service_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$authentication_service_archive_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$authentication_service_binary_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$websocket_proxy_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$websocket_proxy_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$websocket_proxy_archive_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$websocket_proxy_binary_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$webhook_automation_service_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$webhook_automation_service_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$webhook_automation_service_archive_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$webhook_automation_service_binary_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$compose_executor_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$compose_executor_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$compose_executor_archive_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$compose_executor_binary_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$vsphere_cli_bundle_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$vsphere_cli_bundle_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$vsphere_cli_bundle_archive_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$govc_binary_sha256" =~ ^[0-9a-f]{64}$ ]]
for component_version in "$host_provisioner_version" "$secret_delivery_api_version" "$usage_telemetry_agent_version"; do
    [[ "$component_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
done
for component_commit in "$host_provisioner_commit" "$secret_delivery_api_commit" "$usage_telemetry_agent_commit"; do
    [[ "$component_commit" =~ ^[0-9a-f]{40}$ ]]
done
for component_hash in "$host_provisioner_archive_sha256" "$host_provisioner_binary_sha256" "$secret_delivery_api_archive_sha256" "$secret_delivery_api_binary_sha256" "$usage_telemetry_agent_archive_sha256" "$usage_telemetry_agent_binary_sha256"; do
    [[ "$component_hash" =~ ^[0-9a-f]{64}$ ]]
done
for release_base_url in "$host_provisioner_release_base_url" "$secret_delivery_api_release_base_url" "$usage_telemetry_agent_release_base_url"; do
    case "$release_base_url" in
        https://*) ;;
        http://127.0.0.1:*|http://localhost:*) [[ ${PASTURESTACK_ALLOW_LOOPBACK_ARTIFACTS:-0} == 1 ]] ;;
        *) echo 'Runtime producer source must use HTTPS or authorized loopback' >&2; exit 1 ;;
    esac
done
[[ "$base_image" == ghcr.io/pasturestack/server:v1.6.460@sha256:c855af8aea232dacc5bb6df68e2271d482c68b53c43ab0c108ec19118f5ab403 ]]
for release_base_url in "$orchestration_engine_release_base_url" "$api_explorer_release_base_url" "$web_console_release_base_url" "$catalog_service_release_base_url" "$authentication_service_release_base_url" "$websocket_proxy_release_base_url" "$webhook_automation_service_release_base_url" "$host_api_release_base_url" "$node_agent_release_base_url" "$compose_executor_release_base_url" "$vsphere_cli_bundle_release_base_url"; do
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
if [[ -n ${PASTURESTACK_COMPONENT_ARTIFACT_DIR:-} ]]; then
    component_artifact_mode=local
    component_directory=$(realpath -- "$PASTURESTACK_COMPONENT_ARTIFACT_DIR")
    [[ "$component_directory" != / && "$component_directory" != "$repo_root" && "$component_directory" != "$server_dir" ]]
    test -d "$component_directory"
    test -z "$(find "$component_directory" -type l -print -quit)"
    component_assets=(
        "$orchestration_engine_artifact|$orchestration_engine_artifact_sha256"
        "$web_console_artifact|$web_console_artifact_sha256"
        "websocket-proxy-${websocket_proxy_version}-linux-amd64.tar.xz|$websocket_proxy_archive_sha256"
        "host-api-${host_api_version}.tar.gz|$host_api_archive_sha256"
        "node-agent-${node_agent_version}.tar.gz|$node_agent_archive_sha256"
        "host-provisioner-${host_provisioner_version}-linux-amd64.tar.xz|$host_provisioner_archive_sha256"
        "secret-delivery-api-${secret_delivery_api_version}-linux-amd64.tar.xz|$secret_delivery_api_archive_sha256"
        "usage-telemetry-agent-${usage_telemetry_agent_version}-linux-amd64.tar.xz|$usage_telemetry_agent_archive_sha256"
        "catalog-service-${catalog_service_version}.tar.xz|$catalog_service_archive_sha256"
        "catalog-service-${catalog_service_version}-LICENSE.txt|$catalog_service_license_sha256"
        "authentication-service-${authentication_service_version}-linux-amd64.tar.xz|$authentication_service_archive_sha256"
        "webhook-automation-service-${webhook_automation_service_version}-linux-amd64.tar.xz|$webhook_automation_service_archive_sha256"
        "compose-executor-${compose_executor_version}-linux-amd64.gz|$compose_executor_archive_sha256"
        "vsphere-cli-bundle-${vsphere_cli_bundle_version}-linux-amd64.tar.xz|$vsphere_cli_bundle_archive_sha256"
    )
    expected_components=$(printf '%s\n' "${component_assets[@]%%|*}" | LC_ALL=C sort)
    actual_components=$(find "$component_directory" -mindepth 1 -printf '%P\n' | LC_ALL=C sort)
    [[ "$actual_components" == "$expected_components" ]]
    for component_asset in "${component_assets[@]}"; do
        IFS='|' read -r component_name component_sha256 <<< "$component_asset"
        test -s "$component_directory/$component_name" && test -f "$component_directory/$component_name"
        printf '%s  %s\n' "$component_sha256" "$component_directory/$component_name" | sha256sum -c -
    done
    build_options+=(--build-context "component_input=$component_directory")
fi

docker buildx build \
    "${build_options[@]}" \
    --provenance=false \
    --load \
    --network=host \
    --build-arg "BASE_IMAGE=${base_image}" \
    --build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}" \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --build-arg "SERVER_RELEASE_TAG=${server_release_tag}" \
    --build-arg "ORCHESTRATION_ENGINE_VERSION=${orchestration_engine_version}" \
    --build-arg "ENGINE_READONLY_SCHEMA_SHA256=${engine_readonly_schema_sha256}" \
    --build-arg "ENGINE_RESTRICTED_SCHEMA_SHA256=${engine_restricted_schema_sha256}" \
    --build-arg "COMPONENT_ARTIFACT_MODE=${component_artifact_mode}" \
    --build-arg "PASTURESTACK_ALLOW_LOOPBACK_ARTIFACTS=${PASTURESTACK_ALLOW_LOOPBACK_ARTIFACTS:-0}" \
    --build-arg "HOST_API_VERSION=${host_api_version}" \
    --build-arg "HOST_API_PACKAGE_MODE=${host_api_package_mode}" \
    --build-arg "HOST_API_RELEASE_BASE_URL=${host_api_release_base_url}" \
    --build-arg "HOST_API_RELEASE_TAG=${host_api_release_tag}" \
    --build-arg "HOST_API_ARCHIVE_SHA256=${host_api_archive_sha256}" \
    --build-arg "HOST_API_PACKAGE_ID=${host_api_package_id}" \
    --build-arg "HOST_API_BINARY_SHA256=${host_api_binary_sha256}" \
    --build-arg "HOST_API_APPLY_SHA256=${host_api_apply_sha256}" \
    --build-arg "HOST_API_COMMIT=${host_api_commit}" \
    --build-arg "NODE_AGENT_VERSION=${node_agent_version}" \
    --build-arg "NODE_AGENT_RELEASE_BASE_URL=${node_agent_release_base_url}" \
    --build-arg "NODE_AGENT_COMMIT=${node_agent_commit}" \
    --build-arg "NODE_AGENT_PACKAGE_ID=${node_agent_package_id}" \
    --build-arg "NODE_AGENT_ARCHIVE_SHA256=${node_agent_archive_sha256}" \
    --build-arg "NODE_AGENT_BINARY_SHA256=${node_agent_binary_sha256}" \
    --build-arg "NODE_AGENT_APPLY_SHA256=${node_agent_apply_sha256}" \
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
    --build-arg "CATALOG_SERVICE_RELEASE_BASE_URL=${catalog_service_release_base_url}" \
    --build-arg "CATALOG_SERVICE_VERSION=${catalog_service_version}" \
    --build-arg "CATALOG_SERVICE_COMMIT=${catalog_service_commit}" \
    --build-arg "CATALOG_SERVICE_ARCHIVE_SHA256=${catalog_service_archive_sha256}" \
    --build-arg "CATALOG_SERVICE_BINARY_SHA256=${catalog_service_binary_sha256}" \
    --build-arg "CATALOG_SERVICE_SQLITE_BINARY_SHA256=${catalog_service_sqlite_binary_sha256}" \
    --build-arg "CATALOG_SERVICE_LICENSE_SHA256=${catalog_service_license_sha256}" \
    --build-arg "AUTHENTICATION_SERVICE_RELEASE_BASE_URL=${authentication_service_release_base_url}" \
    --build-arg "AUTHENTICATION_SERVICE_VERSION=${authentication_service_version}" \
    --build-arg "AUTHENTICATION_SERVICE_COMMIT=${authentication_service_commit}" \
    --build-arg "AUTHENTICATION_SERVICE_ARCHIVE_SHA256=${authentication_service_archive_sha256}" \
    --build-arg "AUTHENTICATION_SERVICE_BINARY_SHA256=${authentication_service_binary_sha256}" \
    --build-arg "WEBSOCKET_PROXY_RELEASE_BASE_URL=${websocket_proxy_release_base_url}" \
    --build-arg "WEBSOCKET_PROXY_VERSION=${websocket_proxy_version}" \
    --build-arg "WEBSOCKET_PROXY_COMMIT=${websocket_proxy_commit}" \
    --build-arg "WEBSOCKET_PROXY_ARCHIVE_SHA256=${websocket_proxy_archive_sha256}" \
    --build-arg "WEBSOCKET_PROXY_BINARY_SHA256=${websocket_proxy_binary_sha256}" \
    --build-arg "WEBHOOK_AUTOMATION_SERVICE_RELEASE_BASE_URL=${webhook_automation_service_release_base_url}" \
    --build-arg "WEBHOOK_AUTOMATION_SERVICE_VERSION=${webhook_automation_service_version}" \
    --build-arg "WEBHOOK_AUTOMATION_SERVICE_COMMIT=${webhook_automation_service_commit}" \
    --build-arg "WEBHOOK_AUTOMATION_SERVICE_ARCHIVE_SHA256=${webhook_automation_service_archive_sha256}" \
    --build-arg "WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256=${webhook_automation_service_binary_sha256}" \
    --build-arg "COMPOSE_EXECUTOR_RELEASE_BASE_URL=${compose_executor_release_base_url}" \
    --build-arg "COMPOSE_EXECUTOR_VERSION=${compose_executor_version}" \
    --build-arg "COMPOSE_EXECUTOR_COMMIT=${compose_executor_commit}" \
    --build-arg "COMPOSE_EXECUTOR_ARCHIVE_SHA256=${compose_executor_archive_sha256}" \
    --build-arg "COMPOSE_EXECUTOR_BINARY_SHA256=${compose_executor_binary_sha256}" \
    --build-arg "VSPHERE_CLI_BUNDLE_RELEASE_BASE_URL=${vsphere_cli_bundle_release_base_url}" \
    --build-arg "VSPHERE_CLI_BUNDLE_VERSION=${vsphere_cli_bundle_version}" \
    --build-arg "VSPHERE_CLI_BUNDLE_COMMIT=${vsphere_cli_bundle_commit}" \
    --build-arg "VSPHERE_CLI_BUNDLE_ARCHIVE_SHA256=${vsphere_cli_bundle_archive_sha256}" \
    --build-arg "GOVC_BINARY_SHA256=${govc_binary_sha256}" \
    --build-arg "HOST_PROVISIONER_RELEASE_BASE_URL=${host_provisioner_release_base_url}" \
    --build-arg "HOST_PROVISIONER_VERSION=${host_provisioner_version}" \
    --build-arg "HOST_PROVISIONER_COMMIT=${host_provisioner_commit}" \
    --build-arg "HOST_PROVISIONER_ARCHIVE_SHA256=${host_provisioner_archive_sha256}" \
    --build-arg "HOST_PROVISIONER_BINARY_SHA256=${host_provisioner_binary_sha256}" \
    --build-arg "SECRET_DELIVERY_API_RELEASE_BASE_URL=${secret_delivery_api_release_base_url}" \
    --build-arg "SECRET_DELIVERY_API_VERSION=${secret_delivery_api_version}" \
    --build-arg "SECRET_DELIVERY_API_COMMIT=${secret_delivery_api_commit}" \
    --build-arg "SECRET_DELIVERY_API_ARCHIVE_SHA256=${secret_delivery_api_archive_sha256}" \
    --build-arg "SECRET_DELIVERY_API_BINARY_SHA256=${secret_delivery_api_binary_sha256}" \
    --build-arg "USAGE_TELEMETRY_AGENT_RELEASE_BASE_URL=${usage_telemetry_agent_release_base_url}" \
    --build-arg "USAGE_TELEMETRY_AGENT_VERSION=${usage_telemetry_agent_version}" \
    --build-arg "USAGE_TELEMETRY_AGENT_COMMIT=${usage_telemetry_agent_commit}" \
    --build-arg "USAGE_TELEMETRY_AGENT_ARCHIVE_SHA256=${usage_telemetry_agent_archive_sha256}" \
    --build-arg "USAGE_TELEMETRY_AGENT_BINARY_SHA256=${usage_telemetry_agent_binary_sha256}" \
    --build-arg "SUPPORTED_DOCKER_RANGE=${supported_docker_range}" \
    --build-arg "NEWEST_DOCKER_VERSION=${newest_docker_version}" \
    --tag "$image" \
    --file server/Dockerfile.web-compose-release \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    "$server_release_tag"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    ghcr.io/pasturestack/server:v1.6.460
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.digest"}}')" = \
    sha256:c855af8aea232dacc5bb6df68e2271d482c68b53c43ab0c108ec19118f5ab403

image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
for marker in \
    CATTLE_RANCHER_SERVER_VERSION="${server_release_tag}" \
    CATTLE_API_UI_VERSION=1.1.18 \
    CATTLE_CATTLE_VERSION="${orchestration_engine_release_tag}" \
    RC16_GO_AGENT_VERSION="${node_agent_version}" \
    RC16_WINDOWS_AGENT_VERSION=0.13.27 \
    RC16_HOST_API_VERSION="${host_api_version}" \
    PASTURESTACK_HOST_API_PACKAGE_ID="${host_api_package_id}" \
    PASTURESTACK_HOST_API_COMMIT="${host_api_commit}" \
    PASTURESTACK_HOST_API_ARCHIVE_SHA256="${host_api_archive_sha256}" \
    RC16_AGENT_PACKAGE_URL="/usr/share/cattle/artifacts/node-agent-${node_agent_version}.tar.gz" \
    PASTURESTACK_NODE_AGENT_VERSION="${node_agent_version}" \
    PASTURESTACK_NODE_AGENT_COMMIT="${node_agent_commit}" \
    PASTURESTACK_NODE_AGENT_ARCHIVE_SHA256="${node_agent_archive_sha256}" \
    PASTURESTACK_ORCHESTRATION_ENGINE_COMMIT="${orchestration_engine_commit}" \
    PASTURESTACK_ORCHESTRATION_ENGINE_ARTIFACT_SHA256="${orchestration_engine_artifact_sha256}" \
    PASTURESTACK_RUNTIME_GO_VERSION=1.27.2 \
    PASTURESTACK_UBUNTU_SECURITY_REFRESH=2026-09-10 \
    PASTURESTACK_CURL_SECURITY_SNAPSHOT=20261002T000000Z \
    PASTURESTACK_CURL_PACKAGE_VERSION=8.18.0-1ubuntu2.7 \
    PASTURESTACK_GLIBC_CVE_2026_18374_FIX=not-in-execute-path \
    PASTURESTACK_GLIBC_PACKAGE_VERSION=2.43-2ubuntu2.4 \
    PASTURESTACK_PERL_PACKAGE_VERSION=5.40.1-7ubuntu0.3 \
    PASTURESTACK_LIBDBI_PERL_PACKAGE_VERSION=1.647-1ubuntu0.26.04.3 \
    PASTURESTACK_FREETYPE_PACKAGE_VERSION=2.14.2+dfsg-1ubuntu0.2 \
    PASTURESTACK_COREUTILS_PROVIDER=gnu \
    PASTURESTACK_COREUTILS_UNIQ_VERSION=9.11 \
    PASTURESTACK_COREUTILS_UNIQ_FIX=d64e35a8a4c0e4608321433e0d84d917e4e36371 \
    PASTURESTACK_ZLIB_VERSION=1.3.2 \
    PASTURESTACK_OPENSSL_VERSION=3.5.5 \
    PASTURESTACK_OPENSSL_PACKAGE_VERSION=3.5.5-1ubuntu3.7 \
    PASTURESTACK_OPENSSL_SECURITY_SNAPSHOT=20261002T000000Z \
    PASTURESTACK_DIFF3_HARDENING=removed \
    PASTURESTACK_SSH_CLIENT_HARDENING=client-removed \
    PASTURESTACK_PRIVILEGED_MOUNT_HELPERS=removed \
    PASTURESTACK_RUNTIME_USER_MAPPING=removed \
    PASTURESTACK_GPG_VERIFIER=removed \
    PASTURESTACK_CONTAINER_SOURCE_BUILD_MODE=removed \
    PASTURESTACK_CONSOLE_BROKER_GO_VERSION=1.27.2 \
    PASTURESTACK_API_EXPLORER_PACKAGE=1.1.18 \
    PASTURESTACK_API_EXPLORER_COMMIT="${api_explorer_commit}" \
    PASTURESTACK_API_EXPLORER_ARTIFACT_SHA256="${api_explorer_artifact_sha256}" \
    PASTURESTACK_WEB_CONSOLE_PACKAGE="${web_console_release_tag}" \
    PASTURESTACK_WEB_CONSOLE_COMMIT="${web_console_commit}" \
    PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256="${web_console_artifact_sha256}" \
    PASTURESTACK_AUTHENTICATION_SERVICE_VERSION="${authentication_service_version}" \
    PASTURESTACK_AUTHENTICATION_SERVICE_COMMIT="${authentication_service_commit}" \
    PASTURESTACK_AUTHENTICATION_SERVICE_ARCHIVE_SHA256="${authentication_service_archive_sha256}" \
    PASTURESTACK_AUTHENTICATION_SERVICE_BINARY_SHA256="${authentication_service_binary_sha256}" \
    PASTURESTACK_CATALOG_SERVICE_VERSION="${catalog_service_version}" \
    PASTURESTACK_CATALOG_SERVICE_COMMIT="${catalog_service_commit}" \
    PASTURESTACK_CATALOG_SERVICE_ARCHIVE_SHA256="${catalog_service_archive_sha256}" \
    PASTURESTACK_CATALOG_SERVICE_BINARY_SHA256="${catalog_service_binary_sha256}" \
    PASTURESTACK_CATALOG_SERVICE_SQLITE_BINARY_SHA256="${catalog_service_sqlite_binary_sha256}" \
    PASTURESTACK_COMPOSE_EXECUTOR_VERSION="${compose_executor_version}" \
    PASTURESTACK_COMPOSE_EXECUTOR_COMMIT="${compose_executor_commit}" \
    PASTURESTACK_COMPOSE_EXECUTOR_ARCHIVE_SHA256="${compose_executor_archive_sha256}" \
    PASTURESTACK_COMPOSE_EXECUTOR_BINARY_SHA256="${compose_executor_binary_sha256}" \
    PASTURESTACK_HOST_PROVISIONER_VERSION="${host_provisioner_version}" \
    PASTURESTACK_HOST_PROVISIONER_COMMIT="${host_provisioner_commit}" \
    PASTURESTACK_HOST_PROVISIONER_ARCHIVE_SHA256="${host_provisioner_archive_sha256}" \
    PASTURESTACK_HOST_PROVISIONER_BINARY_SHA256="${host_provisioner_binary_sha256}" \
    PASTURESTACK_SECRET_DELIVERY_API_VERSION="${secret_delivery_api_version}" \
    PASTURESTACK_SECRET_DELIVERY_API_COMMIT="${secret_delivery_api_commit}" \
    PASTURESTACK_SECRET_DELIVERY_API_ARCHIVE_SHA256="${secret_delivery_api_archive_sha256}" \
    PASTURESTACK_SECRET_DELIVERY_API_BINARY_SHA256="${secret_delivery_api_binary_sha256}" \
    PASTURESTACK_USAGE_TELEMETRY_AGENT_VERSION="${usage_telemetry_agent_version}" \
    PASTURESTACK_USAGE_TELEMETRY_AGENT_COMMIT="${usage_telemetry_agent_commit}" \
    PASTURESTACK_USAGE_TELEMETRY_AGENT_ARCHIVE_SHA256="${usage_telemetry_agent_archive_sha256}" \
    PASTURESTACK_USAGE_TELEMETRY_AGENT_BINARY_SHA256="${usage_telemetry_agent_binary_sha256}" \
    PASTURESTACK_WEBHOOK_AUTOMATION_SERVICE_VERSION="${webhook_automation_service_version}" \
    PASTURESTACK_WEBHOOK_AUTOMATION_SERVICE_COMMIT="${webhook_automation_service_commit}" \
    PASTURESTACK_WEBHOOK_AUTOMATION_SERVICE_ARCHIVE_SHA256="${webhook_automation_service_archive_sha256}" \
    PASTURESTACK_WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256="${webhook_automation_service_binary_sha256}" \
    PASTURESTACK_WEBSOCKET_PROXY_VERSION="${websocket_proxy_version}" \
    PASTURESTACK_WEBSOCKET_PROXY_COMMIT="${websocket_proxy_commit}" \
    PASTURESTACK_WEBSOCKET_PROXY_ARCHIVE_SHA256="${websocket_proxy_archive_sha256}" \
    PASTURESTACK_WEBSOCKET_PROXY_BINARY_SHA256="${websocket_proxy_binary_sha256}" \
    PASTURESTACK_VSPHERE_CLI_BUNDLE_VERSION="${vsphere_cli_bundle_version}" \
    PASTURESTACK_VSPHERE_CLI_BUNDLE_COMMIT="${vsphere_cli_bundle_commit}" \
    PASTURESTACK_VSPHERE_CLI_BUNDLE_ARCHIVE_SHA256="${vsphere_cli_bundle_archive_sha256}" \
    PASTURESTACK_GOVC_BINARY_SHA256="${govc_binary_sha256}" \
    PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-08-28 \
    PASTURESTACK_CATALOG_COMMIT=b6b658888fce50d3ec217eb4eba0f26ab0113baf \
    'DEFAULT_CATTLE_CATALOG_URL={"catalogs":{"pasturestack":{"url":"https://github.com/PastureStack/catalog-templates.git","branch":"main","pinnedCommit":"b6b658888fce50d3ec217eb4eba0f26ab0113baf"}}}' \
    'CATTLE_CATALOG_URL={"catalogs":{"pasturestack":{"url":"https://github.com/PastureStack/catalog-templates.git","branch":"main","pinnedCommit":"b6b658888fce50d3ec217eb4eba0f26ab0113baf"}}}'; do
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

docker run --rm \
    --env "HOST_API_VERSION=${host_api_version}" \
    --env "HOST_API_PACKAGE_MODE=${host_api_package_mode}" \
    --env "HOST_API_ARCHIVE_SHA256=${host_api_archive_sha256}" \
    --env "NODE_AGENT_VERSION=${node_agent_version}" \
    --env "NODE_AGENT_ARCHIVE_SHA256=${node_agent_archive_sha256}" \
    --entrypoint sh "$image" -eu -c '
    printf "%s\n" \
      "$NODE_AGENT_ARCHIVE_SHA256  /usr/share/cattle/artifacts/node-agent-${NODE_AGENT_VERSION}.tar.gz" \
      "b6a56f8833c31bc224b7baf20ceb1a252c027021efbe6265c1906f8478d7c2fa  /usr/share/cattle/artifacts/node-agent-0.13.27-windows-amd64.zip" | sha256sum -c -
    test "$(readlink /usr/share/cattle/artifacts/go-agent.tar.gz)" = "node-agent-${NODE_AGENT_VERSION}.tar.gz"
    . /usr/share/cattle/env_vars
    test "$DEFAULT_CATTLE_AGENT_PACKAGE_PYTHON_AGENT_URL" = "/usr/share/cattle/artifacts/node-agent-${NODE_AGENT_VERSION}.tar.gz"
    test "$CATTLE_AGENT_PACKAGE_PYTHON_AGENT_URL" = "/usr/share/cattle/artifacts/node-agent-${NODE_AGENT_VERSION}.tar.gz"
    test "$CATTLE_AGENT_PACKAGE_WINDOWS_AGENT_URL" = /usr/share/cattle/artifacts/node-agent-0.13.27-windows-amd64.zip
    host_archive="/usr/share/cattle/artifacts/host-api-${HOST_API_VERSION}.tar.gz"
    test -s "$host_archive"
    test "$(readlink /usr/share/cattle/artifacts/host-api.tar.gz)" = "host-api-${HOST_API_VERSION}.tar.gz"
    test "$DEFAULT_CATTLE_AGENT_PACKAGE_HOST_API_URL" = "$host_archive"
    test "$CATTLE_AGENT_PACKAGE_HOST_API_URL" = "$host_archive"
    # Producer packages are installed byte-for-byte. The compatibility-only
    # 518 repair intentionally changes its archive checksum, not its binaries.
    if [ "$HOST_API_PACKAGE_MODE" = producer ]; then
        printf "%s  %s\n" "$HOST_API_ARCHIVE_SHA256" "$host_archive" | sha256sum -c -
    fi
'

image_catalog_license=$(docker run --rm --entrypoint sha256sum "$image" \
    /usr/share/licenses/pasturestack/catalog-service/LICENSE.txt)
test "$image_catalog_license" = \
    "${catalog_service_license_sha256}  /usr/share/licenses/pasturestack/catalog-service/LICENSE.txt"

image_orchestration=$(docker run --rm --entrypoint sha256sum "$image" \
    /usr/share/cattle/cattle.jar)
test "$image_orchestration" = \
    "${orchestration_engine_artifact_sha256}  /usr/share/cattle/cattle.jar"

docker run --rm \
    --env "ORCHESTRATION_ENGINE_VERSION=${orchestration_engine_version}" \
    --env "ENGINE_READONLY_SCHEMA_SHA256=${engine_readonly_schema_sha256}" \
    --env "ENGINE_RESTRICTED_SCHEMA_SHA256=${engine_restricted_schema_sha256}" \
    --entrypoint bash "$image" -lc '
    set -euo pipefail
    engine_hash=$(sha256sum /usr/share/cattle/cattle.jar | awk "{print \$1}")
    web_root=$(readlink -f /usr/share/cattle/war)
    test "${web_root}" = "/usr/share/cattle/${engine_hash}"
    resources_jar=$(find "${web_root}/WEB-INF/lib" -maxdepth 1 -type f \
        -name "cattle-resources-${ORCHESTRATION_ENGINE_VERSION}.jar" -print -quit)
    test -n "${resources_jar}"
    test "$(unzip -p "${resources_jar}" schema/v1/readonly.ser | sha256sum | cut -d" " -f1)" = \
        "${ENGINE_READONLY_SCHEMA_SHA256}"
    test "$(unzip -p "${resources_jar}" schema/v1/restricted.ser | sha256sum | cut -d" " -f1)" = \
        "${ENGINE_RESTRICTED_SCHEMA_SHA256}"
    unzip -p "${resources_jar}" db/core-124.xml |
        grep -F "pasturestack-catalog-pinned-commit" >/dev/null
    unzip -p "${resources_jar}" schema/service/service-auth.json |
        grep -F "\"subscribe\": \"cr\"" >/dev/null
    unzip -p "${resources_jar}" db/core-125.xml |
        grep -F "pasturestack-credential-secret-value-mediumtext" >/dev/null
    app_config_jar=$(find "${web_root}/WEB-INF/lib" -maxdepth 1 -type f \
        -name "cattle-app-config-*.jar" -print -quit)
    test -n "${app_config_jar}"
    unzip -p "${app_config_jar}" META-INF/cattle/iaas-api/defaults.properties |
        grep -Fx "auth.service.external.id.types=github_user,github_org,github_team,shibboleth_user,shibboleth_group,ldap_user,ldap_group,oidc_user,oidc_group" >/dev/null
    unzip -p "${app_config_jar}" META-INF/cattle/api-server/defaults.properties |
        grep -Fx "supported.docker.range=~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || >=v29.4.1 <=v29.7.2 || v29.8.0" >/dev/null
    unzip -p "${app_config_jar}" META-INF/cattle/api-server/defaults.properties |
        grep -Fx "newest.docker.version=v29.8.0" >/dev/null
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

docker run --rm --env "WEB_CONSOLE_RELEASE_TAG=${web_console_release_tag}" --entrypoint bash "$image" -lc '
    set -euo pipefail
    web_root=$(readlink -f /usr/share/cattle/war)
    test "$(cat "${web_root}/VERSION.txt")" = "${WEB_CONSOLE_RELEASE_TAG}"
    test "$(find "${web_root}/translations" -maxdepth 1 -type f -name "*.json" | wc -l)" -eq 13
    test ! -e "${web_root}/translations/none.json"
    test -z "$(find "${web_root}" -type f -name "*.map" -print -quit)"
    ui_entry=$(find "${web_root}/assets" -maxdepth 1 -type f -name "ui-*.js" -print -quit)
    test -n "${ui_entry}"
    grep -aF "growl-mount" "${ui_entry}" >/dev/null
    grep -aF "createIdentity" "${web_root}"/assets/*.js >/dev/null
    grep -aF "hasRecord" "${web_root}"/assets/*.js >/dev/null
    grep -aF "dropdown-menu project-menu" "${ui_entry}" >/dev/null
    ! grep -aF "dropdown-menu-end project-menu" "${ui_entry}" >/dev/null
    grep -aF "pod-empty-message text-center text-muted" "${ui_entry}" >/dev/null
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
        oidcAccessPolicyUpdate \
        LocalRecoveryRequired \
        MfaConfirmationRequired \
        InvalidAllowedIdentity \
        resourceLoadError.stackUnavailable \
        resourceLoadError.serviceUnavailable \
        resourceLoadError.serviceFailed \
        resourceLoadError.secretsUnavailable \
        resourceLoadError.secretsFailed \
        hostsPage.permissionDenied \
        containersPage.permissionDenied \
        hookPage.receiver.permissionDenied \
        hookPage.receiver.editPermissionDenied \
        routePermission.title \
        routePermission.denied \
        routePermission.updateDenied \
        _notlike; do
        grep -aF "${marker}" "${ui_entry}" >/dev/null
    done
    grep -aF "ember-basic-dropdown-wormhole" "${web_root}"/assets/*.js >/dev/null
    for theme_asset in ui-light.css ui-light.rtl.css ui-dark.css ui-dark.rtl.css; do
        grep -F -A 2 ".jGrowl.top-right {" "${web_root}/assets/${theme_asset}" | grep -Fx "  top: 45px;" >/dev/null
        grep -F -A 4 ".jGrowl .jGrowl-closer {" "${web_root}/assets/${theme_asset}" | grep -Fx "  max-width: calc(100vw - 20px);" >/dev/null
        grep -F -A 5 "#growl-mount .jGrowl.top-right {" "${web_root}/assets/${theme_asset}" | grep -Fx "  position: static;" >/dev/null
        grep -F -A 3 ".pods .pod-empty-message {" "${web_root}/assets/${theme_asset}" | grep -Fx "  white-space: normal;" >/dev/null
        grep -F -A 3 ".pods .pod-empty-message {" "${web_root}/assets/${theme_asset}" | grep -Fx "  overflow-wrap: anywhere;" >/dev/null
        grep -F -A 18 "HEADER NAV.navbar .project-btn .dropdown-menu.project-menu {" "${web_root}/assets/${theme_asset}" | grep -Fx "  max-width: calc(100vw - 68px);" >/dev/null
        grep -F -A 18 "HEADER NAV.navbar .project-btn .dropdown-menu.project-menu {" "${web_root}/assets/${theme_asset}" | grep -Fx "  overflow-wrap: anywhere;" >/dev/null
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
    for theme in light dark; do
        normal_css="${web_root}/assets/ui-${theme}.css"
        rtl_css="${web_root}/assets/ui-${theme}.rtl.css"
        grep -F -A 8 "HEADER NAV.navbar .project-btn .dropdown-menu.project-menu {" "${normal_css}" | grep -Fx "  left: 0;" >/dev/null
        grep -F -A 8 "HEADER NAV.navbar .project-btn .dropdown-menu.project-menu {" "${normal_css}" | grep -Fx "  right: auto;" >/dev/null
        grep -F -A 8 "HEADER NAV.navbar .project-btn .dropdown-menu.project-menu {" "${rtl_css}" | grep -Fx "  right: 0;" >/dev/null
        grep -F -A 8 "HEADER NAV.navbar .project-btn .dropdown-menu.project-menu {" "${rtl_css}" | grep -Fx "  left: auto;" >/dev/null
        grep -F -A 4 "html[dir=rtl] .fail-whale .error {" "${rtl_css}" | grep -Fx "  direction: rtl;" >/dev/null
        grep -F -A 4 "html[dir=rtl] .fail-whale .error {" "${rtl_css}" | grep -Fx "  text-align: right;" >/dev/null
    done
    grep -F "篩選稽核日誌" "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"formResources.addUlimit\":\"新增限制\"" \
        "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"hostsPage.permissionDenied\":\"您沒有權限在此環境中新增主機。\"" \
        "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"routePermission.title\":\"無法執行此操作\"" \
        "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"routePermission.denied\":\"您沒有權限在此環境中建立此資源。\"" \
        "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"routePermission.updateDenied\":\"您沒有權限在此環境中更新此資源。\"" \
        "${web_root}/translations/zh-tw.json" >/dev/null
    for permission_locale in en-us zh-tw ja-jp; do
        locale_file="${web_root}/translations/${permission_locale}.json"
        for permission_key in routePermission.title routePermission.denied routePermission.updateDenied; do
            grep -F "\"${permission_key}\":" "${locale_file}" >/dev/null
        done
    done
    grep -F "\"containersPage.permissionDenied\":\"您沒有權限在此環境中新增容器。\"" \
        "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"hookPage.receiver.permissionDenied\":\"您沒有權限在此環境中新增接收端 Webhook。\"" \
        "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"hookPage.receiver.editPermissionDenied\":\"此環境不提供編輯接收端 Webhook 的功能。\"" \
        "${web_root}/translations/zh-tw.json" >/dev/null
    for locale_file in "${web_root}"/translations/*.json; do
        grep -F "\"hostsPage.permissionDenied\":" "${locale_file}" >/dev/null
        grep -F "\"containersPage.permissionDenied\":" "${locale_file}" >/dev/null
        grep -F "\"hookPage.receiver.permissionDenied\":" "${locale_file}" >/dev/null
        grep -F "\"hookPage.receiver.editPermissionDenied\":" "${locale_file}" >/dev/null
        for validation_label in \
            formNameDescription.name.label \
            formNameDescription.description.label \
            newSecret.value.label \
            newSecret.name.editHelp \
            inputCertificate.cert.label \
            inputCertificate.key.label \
            certificatesPage.encryptedKeyError \
            registriesPage.new.form.custom.labelText \
            registriesPage.new.form.username.labelText \
            registriesPage.new.form.password.labelText; do
            grep -F "\"${validation_label}\":" "${locale_file}" >/dev/null
        done
    done
    grep -F "篩選服務日誌" "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "開始時間必須早於結束時間" "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"viewEditProject.error.projectUnavailable\":\"找不到此環境" "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"viewEditProject.error.membersNotSaved\":\"成員變更未完成" "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"viewEditProject.error.loadFailed\":\"暫時無法載入環境資料" "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"viewEditProject.error.projectFailed\":\"環境設定未儲存：伺服器暫時無法處理" "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"inputIdentity.error.forbidden\":\"您沒有權限搜尋" "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"resourceLoadError.stackUnavailable\":\"找不到此應用堆疊" "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"resourceLoadError.serviceUnavailable\":\"找不到此服務" "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"resourceLoadError.secretsUnavailable\":\"無法載入機密資料" "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"resourceLoadError.accountsUnavailable\":\"無法載入帳號資料" "${web_root}/translations/zh-tw.json" >/dev/null
    for locale in de-de fa-ir fil-ph fr-fr hu-hu ja-jp ko-kr pt-br ru-ru uk-ua zh-hans zh-tw; do
        locale_file="${web_root}/translations/${locale}.json"
        grep -F "\"hostsPage.permissionDenied\":" "${locale_file}" >/dev/null
        grep -F "\"auditLogsPage.filterBuilder.title\":" "${locale_file}" >/dev/null
        grep -F "\"auditLogsPage.filterBuilder.timeDialog.calendar.today\":" "${locale_file}" >/dev/null
        ! grep -F "\"auditLogsPage.filterBuilder.title\":\"Filter audit logs\"" "${locale_file}" >/dev/null
        ! grep -F "\"auditLogsPage.filterBuilder.timeDialog.calendar.today\":\"Today\"" "${locale_file}" >/dev/null
    done
    # The new load-error strings are translated in the supported QA locales;
    # ember-intl uses en-us as the base locale for other translations.
    for locale in en-us zh-tw ja-jp; do
        locale_file="${web_root}/translations/${locale}.json"
        for load_key in serviceUnavailable serviceFailed secretsUnavailable secretsFailed; do
            grep -F "\"resourceLoadError.${load_key}\":" "${locale_file}" >/dev/null
        done
    done
    grep -F "\"auditLogsPage.filterBuilder.timeDialog.calendar.today\":\"Today\"" "${web_root}/translations/en-us.json" >/dev/null
'

docker run --rm --env "ORCHESTRATION_ENGINE_VERSION=${orchestration_engine_version}" --entrypoint bash "$image" -lc '
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
        grep -Fx "Implementation-Version: ${ORCHESTRATION_ENGINE_VERSION}" >/dev/null
    test "$(find /usr/share/cattle/war/WEB-INF/lib -maxdepth 1 -type f -name "freemarker-2.3.35.jar" | wc -l)" -eq 1
    resources_jar=$(find /usr/share/cattle/war/WEB-INF/lib -maxdepth 1 -type f \
        -name "cattle-resources-${ORCHESTRATION_ENGINE_VERSION}.jar" -print -quit)
    test -n "${resources_jar}"
    unzip -p "${resources_jar}" schema/user/user-auth.json |
        grep -F "\"volume.isNative\" : \"r\"" >/dev/null
    unzip -p "${resources_jar}" schema/base/mfaOperation.json |
        grep -F "oidcAccessPolicyUpdate" >/dev/null
    unzip -p "${resources_jar}" schema/base/mfaOperation.json |
        grep -F '"'"'"requestDigest"'"'"' >/dev/null
    unzip -p "${resources_jar}" schema/token/token-auth.json |
        grep -F '"'"'"token.clientSessionId": "cro"'"'"' >/dev/null
    for frozen_token_schema in base superadmin token; do
        unzip -p "${resources_jar}" "schema/v1/${frozen_token_schema}.ser" |
            grep -aF "clientSessionId" >/dev/null
    done
    unzip -p "${resources_jar}" cattle-global.properties |
        grep -Fx "auth.service.external.id.types=github_user,github_org,github_team,shibboleth_user,shibboleth_group,ldap_user,ldap_group,oidc_user,oidc_group" >/dev/null
    for oidc_type in oidc_user oidc_group; do
        unzip -p "${resources_jar}" schema/base/projectMember.json |
            grep -F "\"${oidc_type}\"" >/dev/null
    done
    hazelcast_entry=$(unzip -Z1 /usr/share/cattle/cattle.jar |
        grep -E "^WEB-INF/lib/hazelcast-[^/]+[.]jar$")
    test "${hazelcast_entry}" = "WEB-INF/lib/hazelcast-5.7.5.jar"
    unzip -p /usr/share/cattle/cattle.jar "${hazelcast_entry}" >/tmp/hazelcast.jar
    echo "0f536a9c7bcd00f2369586fb6ca1606f7e45f3225e24795d10d38397051c8715  /tmp/hazelcast.jar" |
        sha256sum -c -
    rm -f /tmp/hazelcast.jar
    cat <<'"'"'EOF'"'"' | sha256sum -c -
fe11eec4b31b43863b49a582b1dbbe309eae08fb78adc150037981174f0622da  /usr/bin/authentication-service.real
a9bf9f0f77e914fe557d3e178a73c31526b0ca0adc4afbf17bf68d8d75c7ee27  /usr/bin/compose-executor.real
1d37e20a7a1cf4f3e36036a15ff7699ef22cd8809fd14a20892034dd054fd1fc  /usr/bin/host-provisioner.real
c263f61fd01423da30e06addc4385817fe683df42c299e53f27a812d8621e777  /usr/bin/secret-delivery-api
e62a21270142181315293d7e11482288ffe8fc4d91cc8fe07dacc90b461f3709  /usr/bin/usage-telemetry-agent
98c7faea665b7eb95206b8c73a6f47d644c5d2d0eae53f274f6a15faf5205744  /usr/bin/webhook-automation-service
EOF
    echo "${PASTURESTACK_GOVC_BINARY_SHA256}  /usr/bin/govc" | sha256sum -c -
    echo "${PASTURESTACK_WEBSOCKET_PROXY_BINARY_SHA256}  /usr/bin/websocket-proxy.real" | sha256sum -c -
    echo "${PASTURESTACK_CATALOG_SERVICE_BINARY_SHA256}  /usr/bin/catalog-service.real" | sha256sum -c -
    echo "${PASTURESTACK_CATALOG_SERVICE_SQLITE_BINARY_SHA256}  /usr/bin/catalog-service-sqlite" | sha256sum -c -
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
        grep -aF "go1.27.2" "${binary}" >/dev/null
    done
    /usr/bin/authentication-service.real --version | grep -F "0.4.43" >/dev/null
    for marker in \
        oidcAccessPolicyUpdate \
        LocalRecoveryRequired \
        MfaConfirmationRequired \
        InvalidAllowedIdentity; do
        grep -aF "${marker}" /usr/bin/authentication-service.real >/dev/null
    done
    test "$(/usr/bin/compose-executor.real --version)" = \
        "pasturestack-compose version ${PASTURESTACK_COMPOSE_EXECUTOR_VERSION}"
    for ssh_binary in /usr/bin/host-provisioner.real /usr/bin/compose-executor.real; do
        grep -aF "$(printf "dep\tgolang.org/x/crypto\tv0.56.0\t")" "${ssh_binary}" >/dev/null
    done
    test "$(/usr/bin/catalog-service.real --version)" = "v${PASTURESTACK_CATALOG_SERVICE_VERSION}"
    test "$(/usr/bin/catalog-service-sqlite --version)" = "v${PASTURESTACK_CATALOG_SERVICE_VERSION}"
    test -s /usr/share/licenses/pasturestack/catalog-service/LICENSE.txt
    grep -Fx "Release source commit: ${PASTURESTACK_CATALOG_SERVICE_COMMIT}" \
        /usr/share/licenses/pasturestack/catalog-service/SOURCES.txt >/dev/null
    /usr/bin/secret-delivery-api --version | grep -F "v0.3.2" >/dev/null
    /usr/bin/usage-telemetry-agent --version | grep -F "0.4.2" >/dev/null
    /usr/bin/webhook-automation-service --version | grep -F "0.10.4" >/dev/null
    test "$(readlink -f /usr/bin/webhook-service)" = /usr/bin/webhook-automation-service
    grep -Fx "Release source commit: 400118b893843d2a7d7c65cc70c3449d76c4a8d8" \
        /usr/share/licenses/pasturestack/webhook-automation-service/webhook-automation-service-SOURCES.txt >/dev/null
    test "$(/usr/bin/govc version)" = "govc ${PASTURESTACK_VSPHERE_CLI_BUNDLE_VERSION}"
    grep -aF "$(printf "dep\tgolang.org/x/text\tv0.41.0\t")" /usr/bin/govc >/dev/null
    grep -Fx "Security dependency: golang.org/x/text v0.41.0" \
        /usr/share/licenses/pasturestack/vsphere-cli-bundle/vsphere-cli-bundle-SOURCES.txt >/dev/null
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
            "8.18.0-1ubuntu2.7"
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
    for package in openssl libssl3t64 openssl-provider-legacy; do
        test "$(dpkg-query -W -f='"'"'${Version}'"'"' "${package}")" = 3.5.5-1ubuntu3.7
    done
    cd /
    test "$(wc -l < /usr/share/pasturestack/security/openssl-runtime.sha256)" -eq 7
    sha256sum -c /usr/share/pasturestack/security/openssl-runtime.sha256
    test "$(dpkg-query -W -f='"'"'${Version}'"'"' libdbi-perl)" = 1.647-1ubuntu0.26.04.3
    test "$(wc -l < /usr/share/pasturestack/security/libdbi-perl-runtime.sha256)" -eq 2
    sha256sum -c /usr/share/pasturestack/security/libdbi-perl-runtime.sha256
    test "$(dpkg-query -W -f='"'"'${Version}'"'"' libfreetype6)" = 2.14.2+dfsg-1ubuntu0.2
    test "$(wc -l < /usr/share/pasturestack/security/freetype-runtime.sha256)" -eq 1
    sha256sum -c /usr/share/pasturestack/security/freetype-runtime.sha256
    test "$(readlink -f /usr/lib/x86_64-linux-gnu/libfreetype.so.6)" = /usr/lib/x86_64-linux-gnu/libfreetype.so.6.20.5
    perl -MDBI -e '"'"'die "Unexpected DBI runtime version\n" unless $DBI::VERSION eq "1.647"'"'"'
    openssl version | grep -E "^OpenSSL 3\\.5\\.5 .*\\(Library: OpenSSL 3\\.5\\.5 " >/dev/null
    test "$(openssl version -d)" = "OPENSSLDIR: \"/usr/lib/ssl\""
    test "$(openssl version -e)" = "ENGINESDIR: \"/usr/lib/x86_64-linux-gnu/engines-3\""
    test "$(openssl version -m)" = "MODULESDIR: \"/usr/lib/x86_64-linux-gnu/ossl-modules\""
    openssl list -providers -provider legacy | grep -F "OpenSSL Legacy Provider" >/dev/null
    printf abc | openssl dgst -provider default -provider legacy -md4 | grep -F a448017aaf21d8525fc10ae87aa6729d >/dev/null
    for target in /usr/bin/curl /usr/sbin/mariadbd /usr/bin/mariadb /usr/lib/x86_64-linux-gnu/libssh2.so.1 /usr/lib/x86_64-linux-gnu/libfreetype.so.6; do
        linkage=$(ldd -r "$target" 2>&1)
        ! printf "%s\n" "$linkage" | grep -E "not found|undefined symbol"
    done
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

docker run --rm -i --network none --entrypoint bash "$image" -s \
    < scripts/test-server-openssl-tls.sh

printf 'SERVER_API_EXPLORER_PATCH_IMAGE_OK image=%s revision=%s base=%s orchestration=%s orchestration_commit=%s orchestration_sha256=%s api_explorer=%s api_explorer_commit=%s artifact_sha256=%s web_console=%s web_console_commit=%s web_console_sha256=%s catalog_service=%s catalog_service_commit=%s catalog_service_archive_sha256=%s catalog_service_binary_sha256=%s catalog_service_sqlite_binary_sha256=%s authentication_service=%s authentication_service_commit=%s authentication_service_archive_sha256=%s authentication_service_binary_sha256=%s websocket_proxy=%s websocket_proxy_commit=%s websocket_proxy_archive_sha256=%s websocket_proxy_binary_sha256=%s compose_executor=%s compose_executor_commit=%s compose_executor_archive_sha256=%s compose_executor_binary_sha256=%s vsphere_cli=%s vsphere_cli_commit=%s vsphere_cli_archive_sha256=%s govc_binary_sha256=%s runtime_go=1.27.2 orchestration_updated=1 wrappers_pinned=1 audit_log_filters=1 curl=8.18.0-1ubuntu2.7 freemarker=2.3.35 vendor_pending=exact-set artifact_scan=required\n' \
    "$image" "$revision" "$base_image" "${orchestration_engine_release_tag#v}" \
    "$orchestration_engine_commit" "$orchestration_engine_artifact_sha256" \
    "${api_explorer_release_tag#v}" "$api_explorer_commit" "$api_explorer_artifact_sha256" \
    "$web_console_release_tag" "$web_console_commit" "$web_console_artifact_sha256" \
    "$catalog_service_version" "$catalog_service_commit" "$catalog_service_archive_sha256" \
    "$catalog_service_binary_sha256" "$catalog_service_sqlite_binary_sha256" \
    "$authentication_service_version" "$authentication_service_commit" \
    "$authentication_service_archive_sha256" "$authentication_service_binary_sha256" \
    "$websocket_proxy_version" "$websocket_proxy_commit" \
    "$websocket_proxy_archive_sha256" "$websocket_proxy_binary_sha256" \
    "$compose_executor_version" "$compose_executor_commit" \
    "$compose_executor_archive_sha256" "$compose_executor_binary_sha256" \
    "$vsphere_cli_bundle_version" "$vsphere_cli_bundle_commit" \
    "$vsphere_cli_bundle_archive_sha256" "$govc_binary_sha256"

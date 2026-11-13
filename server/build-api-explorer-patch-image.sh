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
server_release_tag=${SERVER_RELEASE_TAG:-v1.6.598}
source_date_epoch=${SOURCE_DATE_EPOCH:-$(git show -s --format=%ct HEAD)}
base_image=${BASE_IMAGE:-ghcr.io/pasturestack/server:v1.6.460@sha256:c855af8aea232dacc5bb6df68e2271d482c68b53c43ab0c108ec19118f5ab403}
orchestration_engine_release_base_url=${ORCHESTRATION_ENGINE_RELEASE_BASE_URL:-https://github.com/PastureStack/orchestration-engine/releases/download}
orchestration_engine_asset_api_url=${ORCHESTRATION_ENGINE_ASSET_API_URL:-https://api.github.com/repos/PastureStack/orchestration-engine/releases/assets/733683735}
orchestration_engine_release_tag=${ORCHESTRATION_ENGINE_RELEASE_TAG:-v0.183.395}
orchestration_engine_artifact=${ORCHESTRATION_ENGINE_ARTIFACT:-cattle.jar}
orchestration_engine_artifact_sha256=${ORCHESTRATION_ENGINE_ARTIFACT_SHA256:-0c446a67b9a11fb9018045be0b114b328365e4c3da314d1db6e4e4421d07fcfa}
orchestration_engine_commit=${ORCHESTRATION_ENGINE_COMMIT:-9611a0abde9b8e13a21182b544b98cdac92b7c6a}
orchestration_engine_version=${orchestration_engine_release_tag#v}
engine_readonly_schema_sha256=${ENGINE_READONLY_SCHEMA_SHA256:-7f274219e8dd9c6d750a408a6edec1448b564f4b16ba2204c425c5b45cec2233}
engine_restricted_schema_sha256=${ENGINE_RESTRICTED_SCHEMA_SHA256:-f854ba99260f29e324ab7446a8592996946038920ac9bcf17689d98d1ebc5e51}
host_api_version=${HOST_API_VERSION:-0.38.10}
host_api_package_mode=${HOST_API_PACKAGE_MODE:-producer}
host_api_release_base_url=${HOST_API_RELEASE_BASE_URL:-https://github.com/PastureStack/host-api/releases/download}
host_api_release_tag=${HOST_API_RELEASE_TAG:-v0.38.10}
host_api_archive_sha256=${HOST_API_ARCHIVE_SHA256:-804154a1a1df32c8520bbd2849a3caa46237ea551c9c08316c49e1284bed454f}
host_api_package_id=${HOST_API_PACKAGE_ID:-b82be96846a267f8b20ba836449dbd49}
host_api_binary_sha256=${HOST_API_BINARY_SHA256:-bfcaa9871df9a5d13d31f5f60036a2a655911ab4549950821586b82e0bd4be53}
host_api_apply_sha256=${HOST_API_APPLY_SHA256:-8a21f63099832afb571755011bbcf8d97710994a50c419b20700cbc31efced0f}
host_api_commit=${HOST_API_COMMIT:-b82be96846a267f8b20ba836449dbd494636bf83}
node_agent_version=${NODE_AGENT_VERSION:-0.13.36}
node_agent_release_base_url=${NODE_AGENT_RELEASE_BASE_URL:-https://github.com/PastureStack/node-agent/releases/download}
node_agent_commit=${NODE_AGENT_COMMIT:-fcdf27422d392e415d2781622fdb7fbe999343ed}
node_agent_package_id=${NODE_AGENT_PACKAGE_ID:-${node_agent_commit:0:32}}
node_agent_archive_sha256=${NODE_AGENT_ARCHIVE_SHA256:-8a54f88a293d6982b363882a148dcd5cf83eb00fce2f2ef039353bdc12111fa9}
node_agent_binary_sha256=${NODE_AGENT_BINARY_SHA256:-7c3d5fe509c2a8497c16b9a8744cdbc733f5fb0b4db909640f08fe9dc765f78f}
node_agent_apply_sha256=${NODE_AGENT_APPLY_SHA256:-dd8cb342518a43e7468cc121db5c4e44b16731f2620b77ea0fd03c02c03766a9}
node_agent_windows_archive_sha256=${NODE_AGENT_WINDOWS_ARCHIVE_SHA256:-32acf59e06c50b127077abc23e9b0a4b788101ec555983f514627f4be5ec8b0a}
node_agent_windows_binary_sha256=${NODE_AGENT_WINDOWS_BINARY_SHA256:-42515ffe1004081b160383499e143c75fea69518dbd6f9cc70c553a7706d71a1}
node_agent_windows_startup_sha256=${NODE_AGENT_WINDOWS_STARTUP_SHA256:-e1e84e1c5125db2b8f0c1a83ada8294556cb2390de969398a2436d9481378fca}
per_host_subnet_version=${PER_HOST_SUBNET_VERSION:-0.2.6}
per_host_subnet_release_base_url=${PER_HOST_SUBNET_RELEASE_BASE_URL:-https://github.com/PastureStack/per-host-subnet/releases/download}
per_host_subnet_producer_commit=${PER_HOST_SUBNET_PRODUCER_COMMIT:-05c69dba52ab770062e81a9b60b69408cbe58218}
per_host_subnet_archive_sha256=${PER_HOST_SUBNET_ARCHIVE_SHA256:-a3a7592582c443f4f36b31c54a0a3c87d5961d664e3604b20acb97dec55725be}
per_host_subnet_binary_sha256=${PER_HOST_SUBNET_BINARY_SHA256:-a0e8d6aaa44cfc0579878611a15ace3a939d52d709165b92fb4d45eed49a112c}
per_host_subnet_startup_sha256=${PER_HOST_SUBNET_STARTUP_SHA256:-f22b41f18d1733c037babed4d2e0474efeedc6017a96849d4309dd864f5f86d1}
per_host_subnet_provenance_sha256=${PER_HOST_SUBNET_PROVENANCE_SHA256:-272ea108e8d938c352cf47a4fa82e0dab3c81b6f3b181d0d12b71e1469f87edd}
[[ "$per_host_subnet_version" = 0.2.6 && "$per_host_subnet_producer_commit" =~ ^[0-9a-f]{40}$ ]]
for cni_hash in "$per_host_subnet_archive_sha256" "$per_host_subnet_binary_sha256" "$per_host_subnet_startup_sha256" "$per_host_subnet_provenance_sha256"; do
    [[ "$cni_hash" =~ ^[0-9a-f]{64}$ ]]
done
case "$per_host_subnet_release_base_url" in https://*) ;; *) exit 1 ;; esac
component_artifact_mode=remote
api_explorer_release_base_url=${API_EXPLORER_RELEASE_BASE_URL:-https://github.com/PastureStack/api-explorer/releases/download}
api_explorer_release_tag=${API_EXPLORER_RELEASE_TAG:-v1.1.20}
api_explorer_artifact=${API_EXPLORER_ARTIFACT:-api-explorer-1.1.20.tar.gz}
api_explorer_artifact_sha256=${API_EXPLORER_ARTIFACT_SHA256:-c989ee12a518f6d9d2b23b1f17f48d781aacf6ec31fb65291dd7de9b1661badb}
api_explorer_commit=${API_EXPLORER_COMMIT:-a586f0dc0aa50df579049a8d4bf26f04400fdf75}
web_console_release_base_url=${WEB_CONSOLE_RELEASE_BASE_URL:-https://github.com/PastureStack/web-console/releases/download}
web_console_asset_api_url=${WEB_CONSOLE_ASSET_API_URL:-https://api.github.com/repos/PastureStack/web-console/releases/assets/734661689}
web_console_sbom_asset_api_url=${WEB_CONSOLE_SBOM_ASSET_API_URL:-https://api.github.com/repos/PastureStack/web-console/releases/assets/734661683}
web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-1.6.236}
web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.236.tar.gz}
web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:-93917f9e4f7629e4642fe6bd74599433e67097df19fca28e55936af767d66171}
web_console_commit=${WEB_CONSOLE_COMMIT:-7a64037859fde2618c8b61dce1f1f2a25829db0a}
web_console_lock_sha256=${WEB_CONSOLE_LOCK_SHA256:-028d0fb61227c960eeb46e4f4c4afbe4dee81e4e04ef1bfd804ea07a7c8db2c3}
web_console_runtime_sbom_artifact=${WEB_CONSOLE_RUNTIME_SBOM_ARTIFACT:-web-console-${web_console_release_tag}-runtime.cdx.json}
web_console_runtime_sbom_sha256=${WEB_CONSOLE_RUNTIME_SBOM_SHA256:-ea9ca004d908a7d0286d3040685860f66d34de1e4c70f6c139d1021c1b20d942}
catalog_service_release_base_url=${CATALOG_SERVICE_RELEASE_BASE_URL:-https://github.com/PastureStack/catalog-service/releases/download}
catalog_service_version=${CATALOG_SERVICE_VERSION:-0.20.18}
catalog_service_commit=${CATALOG_SERVICE_COMMIT:-193234b5c44d29638b4a546dfaa4f07eeb2fd56b}
catalog_service_archive_sha256=${CATALOG_SERVICE_ARCHIVE_SHA256:-91dd703a07a49f6491d383ba8bec894f359b24ac091fc576a05ab8b480072b1a}
catalog_service_binary_sha256=${CATALOG_SERVICE_BINARY_SHA256:-fe5a4c2a9aaaf64bd3f7f4a64697af84169a44ddba00ae054b5a6a10d8b1596b}
catalog_service_sqlite_binary_sha256=${CATALOG_SERVICE_SQLITE_BINARY_SHA256:-6f79e877dd76603d8a40bcc2b89619deb5be7d2c23c89a69a1b2372c7b3fcd43}
catalog_service_license_sha256=${CATALOG_SERVICE_LICENSE_SHA256:-0d542e0c8804e39aa7f37eb00da5a762149dc682d7829451287e11b938e94594}
authentication_service_release_base_url=${AUTHENTICATION_SERVICE_RELEASE_BASE_URL:-https://github.com/PastureStack/authentication-service/releases/download}
authentication_service_version=${AUTHENTICATION_SERVICE_VERSION:-0.4.47}
authentication_service_commit=${AUTHENTICATION_SERVICE_COMMIT:-621488e73a41257f053bf22237c833eda2035822}
authentication_service_archive_sha256=${AUTHENTICATION_SERVICE_ARCHIVE_SHA256:-a3ec5a38d0ed497c881c020a9712acc7d5ac27bd15c4f279c1697d82be574ff3}
authentication_service_binary_sha256=${AUTHENTICATION_SERVICE_BINARY_SHA256:-f4e6db78d33483a799e52954c4afa0e780136d1d87fc09914369e54f5a9f8f05}
websocket_proxy_release_base_url=${WEBSOCKET_PROXY_RELEASE_BASE_URL:-https://github.com/PastureStack/websocket-proxy/releases/download}
websocket_proxy_version=${WEBSOCKET_PROXY_VERSION:-0.23.19}
websocket_proxy_commit=${WEBSOCKET_PROXY_COMMIT:-bab79fd154ad1a2da6ba2c35227f9408a4c80b15}
websocket_proxy_archive_sha256=${WEBSOCKET_PROXY_ARCHIVE_SHA256:-715705c0a6217e5f064dddff486b76af249fa52d710a37800567015da86cfb03}
websocket_proxy_binary_sha256=${WEBSOCKET_PROXY_BINARY_SHA256:-a3387ce01f70bac130e8b5665e263d7fc384ef7b4d37e18e43cb56f327494231}
webhook_automation_service_release_base_url=${WEBHOOK_AUTOMATION_SERVICE_RELEASE_BASE_URL:-https://github.com/PastureStack/webhook-automation-service/releases/download}
webhook_automation_service_version=${WEBHOOK_AUTOMATION_SERVICE_VERSION:-0.10.6}
webhook_automation_service_commit=${WEBHOOK_AUTOMATION_SERVICE_COMMIT:-ae1eb711b786463d1b3619d6668a88f4909e37fe}
webhook_automation_service_archive_sha256=${WEBHOOK_AUTOMATION_SERVICE_ARCHIVE_SHA256:-0f4535bf6c47302c1766dcae57f202f49ff25e39da6baa35e06e5d3038f8b3cb}
webhook_automation_service_binary_sha256=${WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256:-52e548ddb5905863dd1da713bfbd15491ef143fe98854d4759219f78b88f3912}
compose_executor_release_base_url=${COMPOSE_EXECUTOR_RELEASE_BASE_URL:-https://github.com/PastureStack/compose-cli/releases/download}
compose_executor_asset_api_url=${COMPOSE_EXECUTOR_ASSET_API_URL:-https://api.github.com/repos/PastureStack/compose-cli/releases/assets/741756962}
compose_executor_version=${COMPOSE_EXECUTOR_VERSION:-0.14.46}
compose_executor_commit=${COMPOSE_EXECUTOR_COMMIT:-c10fea6d53fd196c728aa11c15c7d055d461b907}
compose_executor_archive_sha256=${COMPOSE_EXECUTOR_ARCHIVE_SHA256:-625004f26fdaa89d4ccdbae133c1ecac2ea993f810b1aa850615c4e8f622991b}
compose_executor_binary_sha256=${COMPOSE_EXECUTOR_BINARY_SHA256:-a22985547fea122edd12606728d3bc5f98d9457ae5724d65a21ef3c36d62cab5}
vsphere_cli_bundle_release_base_url=${VSPHERE_CLI_BUNDLE_RELEASE_BASE_URL:-https://github.com/PastureStack/vsphere-cli-bundle/releases/download}
machine_driver_bundle_release_base_url=${MACHINE_DRIVER_BUNDLE_RELEASE_BASE_URL:-https://github.com/PastureStack/machine-driver-bundle/releases/download}
machine_driver_bundle_version=${MACHINE_DRIVER_BUNDLE_VERSION:-0.16.7}
machine_driver_bundle_commit=${MACHINE_DRIVER_BUNDLE_COMMIT:-5db9eb04f45853ad296832b6311cf800b981319f}
machine_driver_bundle_archive_sha256=${MACHINE_DRIVER_BUNDLE_ARCHIVE_SHA256:-903d7fa1703ae30203c13d69ceba355239c518147a5a1836f0d4b8055463f194}
machine_driver_binary_sha256=${MACHINE_DRIVER_BINARY_SHA256:-f77366c8460baf78798dcaaa675cdd5f656c9670b79c651983129c55bb41dd37}
packet_driver_binary_sha256=${PACKET_DRIVER_BINARY_SHA256:-601e958704a2eea7bd3872db99b54007fe2b04cd0c66e96ccf15c50133f4dba0}
[[ "$machine_driver_bundle_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$machine_driver_bundle_commit" =~ ^[0-9a-f]{40}$ ]]
for machine_hash in "$machine_driver_bundle_archive_sha256" "$machine_driver_binary_sha256" "$packet_driver_binary_sha256"; do
    [[ "$machine_hash" =~ ^[0-9a-f]{64}$ ]]
done
[[ "$machine_driver_bundle_release_base_url" == https://* ]]
vsphere_cli_bundle_version=${VSPHERE_CLI_BUNDLE_VERSION:-0.55.5}
vsphere_cli_bundle_commit=${VSPHERE_CLI_BUNDLE_COMMIT:-2388ea4277ed63f6b05d0a8003cda7f662daa3d9}
vsphere_cli_bundle_archive_sha256=${VSPHERE_CLI_BUNDLE_ARCHIVE_SHA256:-bc3fda8383746c4d9927eb0d91155df5ca43a689668f07bcc4621bf808bb9ec6}
govc_binary_sha256=${GOVC_BINARY_SHA256:-7319102b997d19d3a1571b36485c52fd881a23338dfa0410546719b6d4719784}
host_provisioner_release_base_url=${HOST_PROVISIONER_RELEASE_BASE_URL:-https://github.com/PastureStack/host-provisioner/releases/download}
host_provisioner_version=${HOST_PROVISIONER_VERSION:-0.39.11}
host_provisioner_commit=${HOST_PROVISIONER_COMMIT:-59e945e8019c11b69bba7389a849c02096123ce2}
host_provisioner_archive_sha256=${HOST_PROVISIONER_ARCHIVE_SHA256:-01813dfba991709f23658616ad424bc6ef5f9caf956d777093620b7a767fe095}
host_provisioner_binary_sha256=${HOST_PROVISIONER_BINARY_SHA256:-54c22fa95bb16ce9b49df6bec012b9103f3e1b0eafc947d205eaef49e11b45a8}
secret_delivery_api_release_base_url=${SECRET_DELIVERY_API_RELEASE_BASE_URL:-https://github.com/PastureStack/secret-delivery-api/releases/download}
secret_delivery_api_version=${SECRET_DELIVERY_API_VERSION:-0.3.5}
secret_delivery_api_commit=${SECRET_DELIVERY_API_COMMIT:-b97466fd1cfc11253ca8e095a5016a2d44513f6d}
secret_delivery_api_archive_sha256=${SECRET_DELIVERY_API_ARCHIVE_SHA256:-9fdc7c1cc135047b86b20fc12bf17fe994f22856527158379e36eebb4a291492}
secret_delivery_api_binary_sha256=${SECRET_DELIVERY_API_BINARY_SHA256:-8733f1c3c10f4998ea01724f3586fd45ce013a843620e954c0fc3a950ee212b2}
usage_telemetry_agent_release_base_url=${USAGE_TELEMETRY_AGENT_RELEASE_BASE_URL:-https://github.com/PastureStack/usage-telemetry-agent/releases/download}
usage_telemetry_agent_version=${USAGE_TELEMETRY_AGENT_VERSION:-0.4.5}
usage_telemetry_agent_commit=${USAGE_TELEMETRY_AGENT_COMMIT:-88dd6c690e4e6af43b06ded4ee9b548cb3fd2ab0}
usage_telemetry_agent_archive_sha256=${USAGE_TELEMETRY_AGENT_ARCHIVE_SHA256:-c330191944777ec8f68e812cc3aab2f78daf59d0519ed748dc4f4cbff0425da9}
usage_telemetry_agent_binary_sha256=${USAGE_TELEMETRY_AGENT_BINARY_SHA256:-48e22a6654c058cef7126dfa7c39da4c98a92bb939d37f09536d992f507f92ca}
supported_docker_range='~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || >=v29.4.1 <=v29.7.2 || v29.8.0'
newest_docker_version=v29.8.0
image=${IMAGE:-pasturestack-validation/server:v1.6.598}
build_options=()

[[ "$revision" =~ ^[0-9a-f]{40}$ ]]
[[ "$server_release_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$host_api_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$host_api_release_tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$host_api_package_id" =~ ^[0-9a-f]{32}$ ]]
[[ "$node_agent_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$node_agent_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$node_agent_package_id" == "${node_agent_commit:0:32}" ]]
for component_hash in "$host_api_archive_sha256" "$host_api_binary_sha256" "$host_api_apply_sha256" "$engine_readonly_schema_sha256" "$engine_restricted_schema_sha256" "$node_agent_archive_sha256" "$node_agent_binary_sha256" "$node_agent_apply_sha256" "$node_agent_windows_archive_sha256" "$node_agent_windows_binary_sha256" "$node_agent_windows_startup_sha256"; do
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
[[ "$web_console_lock_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$web_console_runtime_sbom_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$web_console_runtime_sbom_artifact" == "web-console-${web_console_release_tag}-runtime.cdx.json" ]]
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
python3 server/security/check_compose_release_identity.py \
    --version "$compose_executor_version" --source "$compose_executor_commit" \
    --archive "$compose_executor_archive_sha256" --binary "$compose_executor_binary_sha256"
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
        "$api_explorer_artifact|$api_explorer_artifact_sha256"
        "$web_console_artifact|$web_console_artifact_sha256"
        "$web_console_runtime_sbom_artifact|$web_console_runtime_sbom_sha256"
        "websocket-proxy-${websocket_proxy_version}-linux-amd64.tar.xz|$websocket_proxy_archive_sha256"
        "host-api-${host_api_version}.tar.gz|$host_api_archive_sha256"
        "node-agent-${node_agent_version}.tar.gz|$node_agent_archive_sha256"
        "node-agent-${node_agent_version}-windows-amd64.zip|$node_agent_windows_archive_sha256"
        "per-host-subnet-${per_host_subnet_version}-windows-amd64.zip|$per_host_subnet_archive_sha256"
        "host-provisioner-${host_provisioner_version}-linux-amd64.tar.xz|$host_provisioner_archive_sha256"
        "secret-delivery-api-${secret_delivery_api_version}-linux-amd64.tar.xz|$secret_delivery_api_archive_sha256"
        "usage-telemetry-agent-${usage_telemetry_agent_version}-linux-amd64.tar.xz|$usage_telemetry_agent_archive_sha256"
        "catalog-service-${catalog_service_version}.tar.xz|$catalog_service_archive_sha256"
        "catalog-service-${catalog_service_version}-LICENSE.txt|$catalog_service_license_sha256"
        "authentication-service-${authentication_service_version}-linux-amd64.tar.xz|$authentication_service_archive_sha256"
        "webhook-automation-service-${webhook_automation_service_version}-linux-amd64.tar.xz|$webhook_automation_service_archive_sha256"
        "compose-executor-${compose_executor_version}-linux-amd64.gz|$compose_executor_archive_sha256"
        "vsphere-cli-bundle-${vsphere_cli_bundle_version}-linux-amd64.tar.xz|$vsphere_cli_bundle_archive_sha256"
        "machine-driver-bundle-${machine_driver_bundle_version}-linux-amd64.tar.xz|$machine_driver_bundle_archive_sha256"
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
    --build-arg "NODE_AGENT_WINDOWS_ARCHIVE_SHA256=${node_agent_windows_archive_sha256}" \
    --build-arg "NODE_AGENT_WINDOWS_BINARY_SHA256=${node_agent_windows_binary_sha256}" \
    --build-arg "NODE_AGENT_WINDOWS_STARTUP_SHA256=${node_agent_windows_startup_sha256}" \
    --build-arg "PER_HOST_SUBNET_VERSION=${per_host_subnet_version}" \
    --build-arg "PER_HOST_SUBNET_RELEASE_BASE_URL=${per_host_subnet_release_base_url}" \
    --build-arg "PER_HOST_SUBNET_PRODUCER_COMMIT=${per_host_subnet_producer_commit}" \
    --build-arg "PER_HOST_SUBNET_ARCHIVE_SHA256=${per_host_subnet_archive_sha256}" \
    --build-arg "PER_HOST_SUBNET_BINARY_SHA256=${per_host_subnet_binary_sha256}" \
    --build-arg "PER_HOST_SUBNET_STARTUP_SHA256=${per_host_subnet_startup_sha256}" \
    --build-arg "PER_HOST_SUBNET_PROVENANCE_SHA256=${per_host_subnet_provenance_sha256}" \
    --build-arg "ORCHESTRATION_ENGINE_RELEASE_BASE_URL=${orchestration_engine_release_base_url}" \
    --build-arg "ORCHESTRATION_ENGINE_ASSET_API_URL=${orchestration_engine_asset_api_url}" \
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
    --build-arg "WEB_CONSOLE_ASSET_API_URL=${web_console_asset_api_url}" \
    --build-arg "WEB_CONSOLE_SBOM_ASSET_API_URL=${web_console_sbom_asset_api_url}" \
    --build-arg "WEB_CONSOLE_RELEASE_TAG=${web_console_release_tag}" \
    --build-arg "WEB_CONSOLE_ARTIFACT=${web_console_artifact}" \
    --build-arg "WEB_CONSOLE_ARTIFACT_SHA256=${web_console_artifact_sha256}" \
    --build-arg "WEB_CONSOLE_COMMIT=${web_console_commit}" \
    --build-arg "WEB_CONSOLE_LOCK_SHA256=${web_console_lock_sha256}" \
    --build-arg "WEB_CONSOLE_RUNTIME_SBOM_ARTIFACT=${web_console_runtime_sbom_artifact}" \
    --build-arg "WEB_CONSOLE_RUNTIME_SBOM_SHA256=${web_console_runtime_sbom_sha256}" \
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
    --build-arg "COMPOSE_EXECUTOR_ASSET_API_URL=${compose_executor_asset_api_url}" \
    --build-arg "COMPOSE_EXECUTOR_VERSION=${compose_executor_version}" \
    --build-arg "COMPOSE_EXECUTOR_COMMIT=${compose_executor_commit}" \
    --build-arg "COMPOSE_EXECUTOR_ARCHIVE_SHA256=${compose_executor_archive_sha256}" \
    --build-arg "COMPOSE_EXECUTOR_BINARY_SHA256=${compose_executor_binary_sha256}" \
    --build-arg "VSPHERE_CLI_BUNDLE_RELEASE_BASE_URL=${vsphere_cli_bundle_release_base_url}" \
    --build-arg "MACHINE_DRIVER_BUNDLE_RELEASE_BASE_URL=${machine_driver_bundle_release_base_url}" \
    --build-arg "MACHINE_DRIVER_BUNDLE_VERSION=${machine_driver_bundle_version}" \
    --build-arg "MACHINE_DRIVER_BUNDLE_COMMIT=${machine_driver_bundle_commit}" \
    --build-arg "MACHINE_DRIVER_BUNDLE_ARCHIVE_SHA256=${machine_driver_bundle_archive_sha256}" \
    --build-arg "MACHINE_DRIVER_BINARY_SHA256=${machine_driver_binary_sha256}" \
    --build-arg "PACKET_DRIVER_BINARY_SHA256=${packet_driver_binary_sha256}" \
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
    CATTLE_RANCHER_CLI_VERSION=v0.6.20 \
    PASTURESTACK_CLI_RELEASE_BASE_URL=https://github.com/PastureStack/cli/releases/download \
    CATTLE_API_UI_VERSION=1.1.20 \
    CATTLE_CATTLE_VERSION="${orchestration_engine_release_tag}" \
    DEFAULT_CATTLE_AGENT_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.34 \
    DEFAULT_CATTLE_BOOTSTRAP_REQUIRED_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.34 \
    DEFAULT_CATTLE_LB_INSTANCE_IMAGE=ghcr.io/pasturestack/load-balancer-service:v0.9.34 \
    DEFAULT_CATTLE_LB_INSTANCE_IMAGE_UUID=docker:ghcr.io/pasturestack/load-balancer-service:v0.9.34 \
    RC16_GO_AGENT_VERSION="${node_agent_version}" \
    RC16_PER_HOST_SUBNET_VERSION="${per_host_subnet_version}" \
    PASTURESTACK_PER_HOST_SUBNET_PRODUCER_COMMIT="${per_host_subnet_producer_commit}" \
    PASTURESTACK_PER_HOST_SUBNET_ARCHIVE_SHA256="${per_host_subnet_archive_sha256}" \
    PASTURESTACK_PER_HOST_SUBNET_PROVENANCE_SHA256="${per_host_subnet_provenance_sha256}" \
    RC16_WINDOWS_AGENT_VERSION="${node_agent_version}" \
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
    PASTURESTACK_RUNTIME_GO_VERSION=1.27.4 \
    PASTURESTACK_UBUNTU_SECURITY_REFRESH=2026-10-23 \
    PASTURESTACK_CURL_SECURITY_SNAPSHOT=20261002T000000Z \
    PASTURESTACK_CURL_PACKAGE_VERSION=8.18.0-1ubuntu2.8 \
    PASTURESTACK_GLIBC_CVE_2026_18374_FIX=official-ubuntu-package \
    PASTURESTACK_GLIBC_OFFICIAL_PACKAGE_VERSION=2.43-2ubuntu2.7 \
    PASTURESTACK_GLIBC_PACKAGE_VERSION=2.43-2ubuntu2.7 \
    PASTURESTACK_PERL_PACKAGE_VERSION=5.40.1-7ubuntu0.4 \
    PASTURESTACK_LIBDBI_PERL_PACKAGE_VERSION=1.647-1ubuntu0.26.04.4 \
    PASTURESTACK_FREETYPE_PACKAGE_VERSION=2.14.2+dfsg-1ubuntu0.2 \
    PASTURESTACK_LIBPNG_PACKAGE_VERSION=1.6.57-1ubuntu0.1 \
    PASTURESTACK_BROTLI_PACKAGE_VERSION=1.2.0-3ubuntu0.1 \
    PASTURESTACK_COREUTILS_PROVIDER=gnu \
    PASTURESTACK_COREUTILS_UNIQ_VERSION=9.11 \
    PASTURESTACK_COREUTILS_UNIQ_FIX=d64e35a8a4c0e4608321433e0d84d917e4e36371 \
    PASTURESTACK_ZLIB_VERSION=1.3.1 \
    PASTURESTACK_ZLIB_PACKAGE_VERSION=1:1.3.dfsg+really1.3.1-1ubuntu3.2 \
    PASTURESTACK_OPENSSL_VERSION=3.5.5 \
    PASTURESTACK_OPENSSL_PACKAGE_VERSION=3.5.5-1ubuntu3.7 \
    PASTURESTACK_OPENSSL_SECURITY_SNAPSHOT=20261002T000000Z \
    PASTURESTACK_DIFF3_HARDENING=removed \
    PASTURESTACK_SSH_CLIENT_HARDENING=client-removed \
    PASTURESTACK_PRIVILEGED_MOUNT_HELPERS=removed \
    PASTURESTACK_RUNTIME_USER_MAPPING=removed \
    PASTURESTACK_GPG_VERIFIER=removed \
    PASTURESTACK_CONTAINER_SOURCE_BUILD_MODE=removed \
    PASTURESTACK_CONSOLE_BROKER_GO_VERSION=1.27.4 \
    PASTURESTACK_API_EXPLORER_PACKAGE=1.1.20 \
    PASTURESTACK_API_EXPLORER_COMMIT="${api_explorer_commit}" \
    PASTURESTACK_API_EXPLORER_ARTIFACT_SHA256="${api_explorer_artifact_sha256}" \
    PASTURESTACK_WEB_CONSOLE_PACKAGE="${web_console_release_tag}" \
    PASTURESTACK_WEB_CONSOLE_COMMIT="${web_console_commit}" \
    PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256="${web_console_artifact_sha256}" \
    PASTURESTACK_WEB_CONSOLE_LOCK_SHA256="${web_console_lock_sha256}" \
    PASTURESTACK_WEB_CONSOLE_RUNTIME_SBOM_SHA256="${web_console_runtime_sbom_sha256}" \
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
    PASTURESTACK_MACHINE_DRIVER_BUNDLE_VERSION="${machine_driver_bundle_version}" \
    PASTURESTACK_MACHINE_DRIVER_BUNDLE_COMMIT="${machine_driver_bundle_commit}" \
    PASTURESTACK_MACHINE_DRIVER_BUNDLE_ARCHIVE_SHA256="${machine_driver_bundle_archive_sha256}" \
    PASTURESTACK_MACHINE_DRIVER_BINARY_SHA256="${machine_driver_binary_sha256}" \
    PASTURESTACK_PACKET_DRIVER_BINARY_SHA256="${packet_driver_binary_sha256}" \
    PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-08-28 \
    PASTURESTACK_CATALOG_COMMIT=88183beee826effcc92451624bbe3465bb3e6a7b \
    'DEFAULT_CATTLE_CATALOG_URL={"catalogs":{"pasturestack":{"url":"https://github.com/PastureStack/catalog-templates.git","branch":"main","pinnedCommit":"88183beee826effcc92451624bbe3465bb3e6a7b"}}}' \
    'CATTLE_CATALOG_URL={"catalogs":{"pasturestack":{"url":"https://github.com/PastureStack/catalog-templates.git","branch":"main","pinnedCommit":"88183beee826effcc92451624bbe3465bb3e6a7b"}}}'; do
    test "$(grep -Fxc "$marker" <<<"$image_environment")" = 1
done

docker run --rm --network none --entrypoint sh "$image" -eu -c '
    . /usr/share/cattle/env_vars
    test -z "${CATTLE_LB_INSTANCE_IMAGE:-}${CATTLE_LB_INSTANCE_IMAGE_UUID:-}${RC16_LB_INSTANCE_IMAGE:-}${RC16_LB_INSTANCE_IMAGE_UUID:-}"
    test "$DEFAULT_CATTLE_LB_INSTANCE_IMAGE" = ghcr.io/pasturestack/load-balancer-service:v0.9.34
    test "$DEFAULT_CATTLE_LB_INSTANCE_IMAGE_UUID" = docker:ghcr.io/pasturestack/load-balancer-service:v0.9.34
    test "$(grep -Fxc "  image: ghcr.io/pasturestack/load-balancer-service:v0.9.34" /usr/share/cattle/compose/docker-compose.yml)" = 2
'

docker run --rm --entrypoint bash "$image" -lc '
    set -euo pipefail
    for package in libc6 libc-bin libc-gconv-modules-extra; do
        test "$(dpkg-query -W -f='"'"'${Version}'"'"' "${package}")" = "2.43-2ubuntu2.7"
    done
    for package in libperl5.40 perl perl-base perl-modules-5.40; do
        test "$(dpkg-query -W -f='"'"'${Version}'"'"' "${package}")" = "5.40.1-7ubuntu0.4"
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
    --env "NODE_AGENT_WINDOWS_ARCHIVE_SHA256=${node_agent_windows_archive_sha256}" \
    --env "PER_HOST_SUBNET_VERSION=${per_host_subnet_version}" \
    --env "PER_HOST_SUBNET_ARCHIVE_SHA256=${per_host_subnet_archive_sha256}" \
    --entrypoint sh "$image" -eu -c '
    printf "%s\n" \
      "$NODE_AGENT_ARCHIVE_SHA256  /usr/share/cattle/artifacts/node-agent-${NODE_AGENT_VERSION}.tar.gz" \
      "$NODE_AGENT_WINDOWS_ARCHIVE_SHA256  /usr/share/cattle/artifacts/node-agent-${NODE_AGENT_VERSION}-windows-amd64.zip" | sha256sum -c -
    test "$(readlink /usr/share/cattle/artifacts/go-agent.tar.gz)" = "node-agent-${NODE_AGENT_VERSION}.tar.gz"
    . /usr/share/cattle/env_vars
    printf "%s  %s\n" "$PER_HOST_SUBNET_ARCHIVE_SHA256" "/usr/share/cattle/artifacts/per-host-subnet-${PER_HOST_SUBNET_VERSION}-windows-amd64.zip" | sha256sum -c -
    test "$CATTLE_AGENT_PACKAGE_PER_HOST_SUBNET_URL" = "/usr/share/cattle/artifacts/per-host-subnet-${PER_HOST_SUBNET_VERSION}-windows-amd64.zip"
    test "$DEFAULT_CATTLE_AGENT_PACKAGE_PER_HOST_SUBNET_URL" = "$CATTLE_AGENT_PACKAGE_PER_HOST_SUBNET_URL"
    test ! -e /usr/share/cattle/artifacts/per-host-subnet-0.2.4-windows-amd64.zip
    test "$DEFAULT_CATTLE_AGENT_PACKAGE_PYTHON_AGENT_URL" = "/usr/share/cattle/artifacts/node-agent-${NODE_AGENT_VERSION}.tar.gz"
    test "$CATTLE_AGENT_PACKAGE_PYTHON_AGENT_URL" = "/usr/share/cattle/artifacts/node-agent-${NODE_AGENT_VERSION}.tar.gz"
    test "$DEFAULT_CATTLE_AGENT_PACKAGE_WINDOWS_AGENT_URL" = "/usr/share/cattle/artifacts/node-agent-${NODE_AGENT_VERSION}-windows-amd64.zip"
    test "$CATTLE_AGENT_PACKAGE_WINDOWS_AGENT_URL" = "$DEFAULT_CATTLE_AGENT_PACKAGE_WINDOWS_AGENT_URL"
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
    grep -Fx "{\"ceiling\":\"enabled\",\"initialMode\":\"off\"}" "${web_root}/webmcp-build.json"
    echo "${PASTURESTACK_WEB_CONSOLE_RUNTIME_SBOM_SHA256}  /usr/share/licenses/pasturestack/web-console/runtime.cdx.json" | sha256sum -c -
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

docker run --rm -i --entrypoint sh "$image" -s -- \
    /usr/share/cattle/cattle.jar "${orchestration_engine_version}" "${orchestration_engine_artifact_sha256}" \
    < "${server_dir}/artifacts/verify-engine-archive.sh"
docker run --rm --env "ORCHESTRATION_ENGINE_VERSION=${orchestration_engine_version}" \
    --env "API_EXPLORER_COMMIT=${api_explorer_commit}" \
    --env "API_EXPLORER_RELEASE_TAG=${api_explorer_release_tag}" --entrypoint bash "$image" -lc '
    set -Eeuo pipefail
    trap "printf \"SERVER_RUNTIME_CONTRACT_FAILED line=%s\\n\" \"\${LINENO}\" >&2" ERR
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
    test -s "${api_dir}/licenses/handlebars-4.7.10/LICENSE"
    test ! -e "${api_dir}/js/bootstrap.js"
    test "$(find "${api_dir}" -type f -name "*.map" | wc -l)" -eq 0
    grep -F "\"version\": \"${API_EXPLORER_RELEASE_TAG#v}\"" "${api_dir}/version.json" >/dev/null
    grep -F "\"commit\": \"${API_EXPLORER_COMMIT:0:7}\"" "${api_dir}/version.json" >/dev/null
    grep -aF "handlebars v4.7.10" "${api_dir}/ui.js" >/dev/null
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
    cat <<'"'"'EOF'"'"' | sha256sum -c -
f4e6db78d33483a799e52954c4afa0e780136d1d87fc09914369e54f5a9f8f05  /usr/bin/authentication-service.real
a22985547fea122edd12606728d3bc5f98d9457ae5724d65a21ef3c36d62cab5  /usr/bin/compose-executor.real
54c22fa95bb16ce9b49df6bec012b9103f3e1b0eafc947d205eaef49e11b45a8  /usr/bin/host-provisioner.real
8733f1c3c10f4998ea01724f3586fd45ce013a843620e954c0fc3a950ee212b2  /usr/bin/secret-delivery-api
48e22a6654c058cef7126dfa7c39da4c98a92bb939d37f09536d992f507f92ca  /usr/bin/usage-telemetry-agent
52e548ddb5905863dd1da713bfbd15491ef143fe98854d4759219f78b88f3912  /usr/bin/webhook-automation-service
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
        /usr/bin/govc; do
        test -x "${binary}"
        grep -aF "go1.27.4" "${binary}" >/dev/null
    done
    test -x /usr/bin/pasturestack-console-broker
    grep -aF "go1.27.4" /usr/bin/pasturestack-console-broker >/dev/null
    /usr/bin/authentication-service.real --version | grep -F "0.4.47" >/dev/null
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
    /usr/bin/secret-delivery-api --version | grep -F "v0.3.5" >/dev/null
    /usr/bin/usage-telemetry-agent --version | grep -F "0.4.5" >/dev/null
    /usr/bin/webhook-automation-service --version | grep -F "0.10.6" >/dev/null
    test "$(readlink -f /usr/bin/webhook-service)" = /usr/bin/webhook-automation-service
    grep -Fx "Release source commit: ae1eb711b786463d1b3619d6668a88f4909e37fe" \
        /usr/share/licenses/pasturestack/webhook-automation-service/webhook-automation-service-SOURCES.txt >/dev/null
    test "$(/usr/bin/govc version)" = "govc ${PASTURESTACK_VSPHERE_CLI_BUNDLE_VERSION}"
    test "$(/usr/bin/docker-machine version)" = "docker-machine version ${PASTURESTACK_MACHINE_DRIVER_BUNDLE_VERSION}, build 95d190cb"
    printf "%s  %s\n" "$PASTURESTACK_MACHINE_DRIVER_BINARY_SHA256" /usr/bin/docker-machine "$PASTURESTACK_PACKET_DRIVER_BINARY_SHA256" /usr/bin/docker-machine-driver-packet | sha256sum -c -
    printf "%s  %s\n" "$PASTURESTACK_MACHINE_DRIVER_BUNDLE_ARCHIVE_SHA256" "/usr/share/cattle/artifacts/machine-driver-bundle-${PASTURESTACK_MACHINE_DRIVER_BUNDLE_VERSION}-linux-amd64.tar.xz" | sha256sum -c -
    for machine_binary in /usr/bin/docker-machine /usr/bin/docker-machine-driver-packet; do
        grep -aF "go1.27.4" "$machine_binary" >/dev/null
    done
    grep -Fx "PACKET_DRIVER_NEW_INSTALL_DEFAULT=false" /usr/share/licenses/pasturestack/machine-driver-bundle/machine-driver-bundle-SOURCES.txt
    machine_storage=$(mktemp -d)
    /usr/bin/docker-machine --storage-path "$machine_storage" ls -q > "$machine_storage/list"
    test ! -s "$machine_storage/list"
    rm -r -- "$machine_storage"
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
    require_package_absent()
    {
        if package_is_installed "$1"; then
            printf "Unexpected runtime package: %s\n" "$1" >&2
            return 1
        fi
    }
    require_resolved_linkage()
    {
        if printf "%s\n" "$1" | grep -E "not found|undefined symbol"; then
            printf "Unresolved runtime linkage\n" >&2
            return 1
        fi
    }
    test "$(dpkg-query -W -f='"'"'${Version}'"'"' libbrotli1)" = 1.2.0-3ubuntu0.1
    sh /usr/local/libexec/pasturestack/verify-brotli-runtime.sh
    brotli_integrity="$(dpkg --verify libbrotli1)"
    test -z "$brotli_integrity"
    for brotli_library in libbrotlicommon.so.1 libbrotlidec.so.1 libbrotlienc.so.1; do
        brotli_linkage="$(ldd -r "/usr/lib/x86_64-linux-gnu/${brotli_library}" 2>&1)"
        require_resolved_linkage "$brotli_linkage"
    done
    for curl_package in curl libcurl3t64-gnutls libcurl4t64; do
        test "$(dpkg-query -W -f='"'"'${Version}'"'"' "${curl_package}")" = \
            "8.18.0-1ubuntu2.8"
    done
    for glibc_package in libc6 libc-bin libc-gconv-modules-extra; do
        test "$(dpkg-query -W -f='"'"'${Version}'"'"' "${glibc_package}")" = \
            "2.43-2ubuntu2.7"
    done
    for perl_package in libperl5.40 perl perl-base perl-modules-5.40; do
        test "$(dpkg-query -W -f='"'"'${Version}'"'"' "${perl_package}")" = \
            "5.40.1-7ubuntu0.4"
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
    version_at_least libexpat1 2.7.4-1ubuntu0.2
    package_is_installed coreutils-from-gnu
    require_package_absent coreutils-from-uutils
    require_package_absent rust-coreutils
    ls --version | grep -Fq "GNU coreutils"
    test "$(git --version)" = "git version 2.53.0"
    uniq --version | grep -Fq "uniq (GNU coreutils) 9.11"
    longline="$(printf "\360\237\230\200"; head -c 255 /dev/zero | tr "\000" A)"
    printf "%s\n%s\n" "${longline}" "${longline}" >/tmp/uniq-input
    printf "%s\n" "${longline}" >/tmp/uniq-expected
    LC_ALL=C.UTF-8 uniq -w256 /tmp/uniq-input >/tmp/uniq-output
    cmp /tmp/uniq-expected /tmp/uniq-output
    test "$(dpkg-query -W -f='"'"'${Version}'"'"' zlib1g)" = 1:1.3.dfsg+really1.3.1-1ubuntu3.2
    test "$PASTURESTACK_ZLIB_VERSION" = 1.3.1
    test "$PASTURESTACK_ZLIB_PACKAGE_VERSION" = 1:1.3.dfsg+really1.3.1-1ubuntu3.2
    test ! -e /usr/lib/x86_64-linux-gnu/libz.so.1.3.2
    test "$(readlink -f /usr/lib/x86_64-linux-gnu/libz.so.1)" = /usr/lib/x86_64-linux-gnu/libz.so.1.3.1
    zlib_integrity=$(dpkg --verify zlib1g)
    test -z "$zlib_integrity"
    ldd /usr/sbin/mariadbd | grep -F "/usr/lib/x86_64-linux-gnu/libz.so.1" >/dev/null
    printf "%s  %s\n" 27fa6c6cb94fb5b099ead61758a300dbc392d1dbf307fff6c16a9b8e57fdc9de /usr/lib/x86_64-linux-gnu/libz.so.1.3.1 | sha256sum -c -
    for package in openssl libssl3t64 openssl-provider-legacy; do
        test "$(dpkg-query -W -f='"'"'${Version}'"'"' "${package}")" = 3.5.5-1ubuntu3.7
    done
    cd /
    test "$(wc -l < /usr/share/pasturestack/security/openssl-runtime.sha256)" -eq 7
    sha256sum -c /usr/share/pasturestack/security/openssl-runtime.sha256
    test "$(dpkg-query -W -f='"'"'${Version}'"'"' libdbi-perl)" = 1.647-1ubuntu0.26.04.4
    test "$(wc -l < /usr/share/pasturestack/security/libdbi-perl-runtime.sha256)" -eq 2
    sha256sum -c /usr/share/pasturestack/security/libdbi-perl-runtime.sha256
    test "$(dpkg-query -W -f='"'"'${Version}'"'"' libfreetype6)" = 2.14.2+dfsg-1ubuntu0.2
    test "$(wc -l < /usr/share/pasturestack/security/freetype-runtime.sha256)" -eq 1
    sha256sum -c /usr/share/pasturestack/security/freetype-runtime.sha256
    test "$(dpkg-query -W -f='"'"'${Version}'"'"' libpng16-16t64)" = 1.6.57-1ubuntu0.1
    test "$(wc -l < /usr/share/pasturestack/security/libpng-runtime.sha256)" -eq 1
    sha256sum -c /usr/share/pasturestack/security/libpng-runtime.sha256
    sh /usr/local/libexec/pasturestack/verify-pcre2-runtime.sh
    libpng_linkage=$(ldd -r /usr/lib/x86_64-linux-gnu/libpng16.so.16 2>&1)
    require_resolved_linkage "$libpng_linkage"
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
        require_resolved_linkage "$linkage"
    done
    ldd /usr/bin/curl | grep -F "/usr/lib/x86_64-linux-gnu/libssl.so.3" >/dev/null
    ldd /usr/bin/curl | grep -F "/usr/lib/x86_64-linux-gnu/libcrypto.so.3" >/dev/null
    ldd /usr/sbin/mariadbd | grep -F "/usr/lib/x86_64-linux-gnu/libssl.so.3" >/dev/null
    ldd /usr/sbin/mariadbd | grep -F "/usr/lib/x86_64-linux-gnu/libcrypto.so.3" >/dev/null
    for removed_package in fontconfig keychain libfontconfig1 openssh-client; do
        require_package_absent "${removed_package}"
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
    if ldconfig -p | grep -F "libexpat.so"; then
        printf "Unexpected Expat runtime linkage\n" >&2
        exit 1
    fi
    test -z "$(find /run -xdev -type s -path "*p11-kit*" -print -quit 2>/dev/null)"
    unexpected_native_dependency="$(
        find /usr/bin /usr/sbin /usr/share/cattle -xdev -type f -perm /0111 -print0 |
        while IFS= read -r -d "" executable; do
            if ldd "${executable}" 2>/dev/null | grep -Eq "libgcrypt[.]so|libexpat[.]so"; then
                printf "%s\n" "${executable}"
            fi
        done | head -n 1
    )"
    test -z "${unexpected_native_dependency}"
    if grep -Eq "(^|[[:space:]])(git clone|git -C|apt-get install|tar xzf)([[:space:]]|$)" /usr/share/cattle/cattle.sh; then
        exit 1
    fi
'

docker run --rm -i --network none --entrypoint bash "$image" -s \
    < scripts/test-server-openssl-tls.sh

printf 'SERVER_API_EXPLORER_PATCH_IMAGE_OK image=%s revision=%s base=%s orchestration=%s orchestration_commit=%s orchestration_sha256=%s api_explorer=%s api_explorer_commit=%s artifact_sha256=%s web_console=%s web_console_commit=%s web_console_sha256=%s catalog_service=%s catalog_service_commit=%s catalog_service_archive_sha256=%s catalog_service_binary_sha256=%s catalog_service_sqlite_binary_sha256=%s authentication_service=%s authentication_service_commit=%s authentication_service_archive_sha256=%s authentication_service_binary_sha256=%s websocket_proxy=%s websocket_proxy_commit=%s websocket_proxy_archive_sha256=%s websocket_proxy_binary_sha256=%s compose_executor=%s compose_executor_commit=%s compose_executor_archive_sha256=%s compose_executor_binary_sha256=%s vsphere_cli=%s vsphere_cli_commit=%s vsphere_cli_archive_sha256=%s govc_binary_sha256=%s runtime_go=1.27.4 console_broker_go=1.27.4 orchestration_updated=1 wrappers_pinned=1 audit_log_filters=1 curl=8.18.0-1ubuntu2.8 freemarker=2.3.35 vendor_pending=exact-set artifact_scan=required\n' \
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

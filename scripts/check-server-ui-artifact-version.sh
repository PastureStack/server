#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

failures=0

dockerfile_env() {
  local key=$1
  awk -v key="$key" '
    $1 == "ENV" {
      if ($2 ~ "^" key "=") {
        sub("^" key "=", "", $2)
        print $2
        exit
      }
      if ($2 == key) {
        print $3
        exit
      }
    }
  ' server/Dockerfile
}

expected_server_version="${RC16_EXPECTED_SERVER_VERSION:-$(dockerfile_env CATTLE_RANCHER_SERVER_VERSION)}"
expected_cattle_version="${RC16_EXPECTED_CATTLE_VERSION:-$(dockerfile_env CATTLE_CATTLE_VERSION)}"
expected_ui_version="${RC16_EXPECTED_UI_VERSION:-1.6.56}"
expected_api_ui_version="${RC16_EXPECTED_API_UI_VERSION:-1.1.14}"
expected_agent_image="${RC16_EXPECTED_AGENT_IMAGE:-ghcr.io/pasturestack/node-agent:v1.2.30@sha256:5310b748fc52bcd87fdeaa2285f424a07ec13c9b41639692eef96bda53ac8277}"
expected_lb_image="${RC16_EXPECTED_LB_IMAGE:-ghcr.io/pasturestack/load-balancer-service:v0.9.23@sha256:3139b2a54688e4e34b24df943a36a2ed1eecc26d53c0ab329bf7ffcb62cdb893}"
expected_catalog_commit="${PASTURESTACK_EXPECTED_CATALOG_COMMIT:-91f5910a44cb181051be2adc4c14f0e6ec7842ef}"
expected_catalog_service_version="${PASTURESTACK_EXPECTED_CATALOG_SERVICE_VERSION:-0.20.6}"
expected_catalog_service_sha256="${PASTURESTACK_EXPECTED_CATALOG_SERVICE_SHA256:-5099bf0c69aad625dcd4c857b573496c88243c068891699293c99771859a414d}"
expected_authentication_service_version="${PASTURESTACK_EXPECTED_AUTHENTICATION_SERVICE_VERSION:-0.1.7}"
expected_authentication_service_sha256="${PASTURESTACK_EXPECTED_AUTHENTICATION_SERVICE_SHA256:-093ab5f5c7e733e56a7e5af5795bf49b4339234e2235ded36c5b854bc8b103bb}"
expected_websocket_proxy_version="${PASTURESTACK_EXPECTED_WEBSOCKET_PROXY_VERSION:-0.23.12}"
expected_compose_executor_version="${PASTURESTACK_EXPECTED_COMPOSE_EXECUTOR_VERSION:-0.14.31}"
expected_compose_executor_binary_sha256="${PASTURESTACK_EXPECTED_COMPOSE_EXECUTOR_BINARY_SHA256:-04f6e5d165514daee28f225182ad813ca165edd8bac901e20476e8532cf656b2}"
expected_host_provisioner_version="${PASTURESTACK_EXPECTED_HOST_PROVISIONER_VERSION:-0.39.4}"
expected_host_provisioner_binary_sha256="${PASTURESTACK_EXPECTED_HOST_PROVISIONER_BINARY_SHA256:-dba5fd4d423a49f35a443951ac274ea680305a5a7a5945623139417c2e60ada3}"
expected_machine_driver_bundle_version="${PASTURESTACK_EXPECTED_MACHINE_DRIVER_BUNDLE_VERSION:-0.14.0}"
expected_machine_manager_binary_sha256="${PASTURESTACK_EXPECTED_MACHINE_MANAGER_BINARY_SHA256:-a4c69bffb78d3cfe103b89dae61c3ea11cc2d1a91c4ff86e630c9ae88244db02}"
expected_packet_driver_binary_sha256="${PASTURESTACK_EXPECTED_PACKET_DRIVER_BINARY_SHA256:-e77c635969a76f498d7088904acd375f25b79a81632b87fa9e5cc5b8e2e72184}"
expected_vsphere_cli_bundle_version="${PASTURESTACK_EXPECTED_VSPHERE_CLI_BUNDLE_VERSION:-0.54.1}"
expected_govc_binary_sha256="${PASTURESTACK_EXPECTED_GOVC_BINARY_SHA256:-115af2599f9c9939ee44cbd8218e5fe70e42d7957fd66f1ecad4148a1b980e2a}"
expected_secret_delivery_api_version="${PASTURESTACK_EXPECTED_SECRET_DELIVERY_API_VERSION:-0.2.2}"
expected_secret_delivery_api_binary_sha256="${PASTURESTACK_EXPECTED_SECRET_DELIVERY_API_BINARY_SHA256:-e62141d968cc5323bc53ad0cdc3630239b9e27e7ab5a212bf40a321c48e5dd1a}"
expected_usage_telemetry_agent_version="${PASTURESTACK_EXPECTED_USAGE_TELEMETRY_AGENT_VERSION:-0.4.0-pasturestack.1}"
expected_usage_telemetry_agent_binary_sha256="${PASTURESTACK_EXPECTED_USAGE_TELEMETRY_AGENT_BINARY_SHA256:-3c587d14ffed4640090cf5c532a1844b41d1b3c225f51507053ec3bd77714093}"
expected_webhook_automation_service_version="${PASTURESTACK_EXPECTED_WEBHOOK_AUTOMATION_SERVICE_VERSION:-0.9.15-pasturestack.1}"
expected_webhook_automation_service_binary_sha256="${PASTURESTACK_EXPECTED_WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256:-195cec94370e5ab61bcba1bbbad6b048dbc1dd3d5bf696fe690017b3bda57e9a}"
expected_windows_agent_version="${PASTURESTACK_EXPECTED_WINDOWS_AGENT_VERSION:-0.13.21}"
expected_windows_agent_artifact_sha256="${PASTURESTACK_EXPECTED_WINDOWS_AGENT_ARTIFACT_SHA256:-f511a41c0eb410473e1a223b70f7e8046b38f99e64b5b01167a4ca8c09a496e7}"
expected_graphite_exporter_version="${PASTURESTACK_EXPECTED_GRAPHITE_EXPORTER_VERSION:-0.2.0}"
expected_graphite_exporter_artifact_sha256="${PASTURESTACK_EXPECTED_GRAPHITE_EXPORTER_ARTIFACT_SHA256:-1058b72a73f568adc24191f74e972ed6be0d932b9a80f43a7043e4e3d0501388}"
expected_graphite_exporter_binary_sha256="${PASTURESTACK_EXPECTED_GRAPHITE_EXPORTER_BINARY_SHA256:-a27df929e213a3e87adf057f3af2f9bb6d4b8c92d49c1795e6a79bd117f0e5d9}"
expected_runtime_license_bundle_version="${PASTURESTACK_EXPECTED_RUNTIME_LICENSE_BUNDLE_VERSION:-1.6.273}"
expected_runtime_license_bundle_sha256="${PASTURESTACK_EXPECTED_RUNTIME_LICENSE_BUNDLE_SHA256:-336af1936c3b0c90f87a2dd348792f79672eddc45a22b26e5fee35c10fa54fba}"
expected_s6_overlay_version="${PASTURESTACK_EXPECTED_S6_OVERLAY_VERSION:-1.19.1.1}"
expected_s6_overlay_artifact_sha256="${PASTURESTACK_EXPECTED_S6_OVERLAY_ARTIFACT_SHA256:-b5d360383dd519a33bd39651c43c49b4cf0e95344a94ba65dd8628eefd9ee5cb}"
require_promotion_defaults="${RC16_REQUIRE_PROMOTION_DEFAULTS:-false}"

require_marker() {
  local file=$1
  local marker=$2
  local code=$3
  if ! grep -Fq -- "$marker" "$file"; then
    printf '%s file=%s marker=%s\n' "$code" "$file" "$marker"
    failures=$((failures + 1))
  fi
}

reject_marker() {
  local file=$1
  local marker=$2
  local code=$3
  if grep -Fq -- "$marker" "$file"; then
    printf '%s file=%s marker=%s\n' "$code" "$file" "$marker"
    failures=$((failures + 1))
  fi
}

if [ -z "$expected_server_version" ]; then
  printf 'SERVER_EXPECTED_VERSION_UNRESOLVED file=server/Dockerfile key=CATTLE_RANCHER_SERVER_VERSION\n'
  failures=$((failures + 1))
fi

if [ -z "$expected_cattle_version" ]; then
  printf 'SERVER_EXPECTED_CATTLE_VERSION_UNRESOLVED file=server/Dockerfile key=CATTLE_CATTLE_VERSION\n'
  failures=$((failures + 1))
fi

require_marker server/Dockerfile "ENV CATTLE_RANCHER_SERVER_VERSION=${expected_server_version}" SERVER_VERSION_NOT_BUMPED
require_marker server/Dockerfile "ENV CATTLE_CATTLE_VERSION=${expected_cattle_version}" SERVER_CATTLE_VERSION_NOT_BUMPED
require_marker server/Dockerfile "ENV CATTLE_UI_VERSION=${expected_ui_version}" SERVER_UI_VERSION_ENV_MISSING
require_marker server/Dockerfile "ENV CATTLE_API_UI_VERSION=${expected_api_ui_version}" SERVER_API_UI_VERSION_ENV_MISSING
require_marker server/Dockerfile "ENV DEFAULT_CATTLE_AGENT_IMAGE=${expected_agent_image}" SERVER_AGENT_IMAGE_NOT_CURRENT
require_marker server/Dockerfile "ENV DEFAULT_CATTLE_BOOTSTRAP_REQUIRED_IMAGE=${expected_agent_image}" SERVER_AGENT_BOOTSTRAP_IMAGE_NOT_CURRENT
require_marker server/Dockerfile.auth-hotfix "ENV DEFAULT_CATTLE_AGENT_IMAGE=${expected_agent_image}" SERVER_AUTH_HOTFIX_AGENT_IMAGE_NOT_CURRENT
require_marker server/Dockerfile.auth-hotfix "ENV DEFAULT_CATTLE_BOOTSTRAP_REQUIRED_IMAGE=${expected_agent_image}" SERVER_AUTH_HOTFIX_AGENT_BOOTSTRAP_IMAGE_NOT_CURRENT
require_marker scripts/migrate-server-mysql55-to-mariadb118.sh "RC16_AGENT_IMAGE=\"\${RC16_AGENT_IMAGE:-${expected_agent_image}}\"" SERVER_MIGRATION_AGENT_IMAGE_DEFAULT_NOT_CURRENT
require_marker scripts/migrate-server-mysql55-to-mariadb118.sh "UPDATE setting SET value='\${RC16_AGENT_IMAGE}' WHERE name='agent.image';" SERVER_MIGRATION_AGENT_IMAGE_SETTING_NOT_CURRENT
require_marker server/Dockerfile "ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE=${expected_lb_image}" SERVER_LB_IMAGE_NOT_CURRENT
require_marker server/Dockerfile "ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE_UUID=docker:${expected_lb_image}" SERVER_LB_IMAGE_UUID_NOT_CURRENT
require_marker scripts/migrate-server-mysql55-to-mariadb118.sh "RC16_LB_INSTANCE_IMAGE=\"\${RC16_LB_INSTANCE_IMAGE:-${expected_lb_image}}\"" SERVER_MIGRATION_LB_IMAGE_DEFAULT_NOT_CURRENT
require_marker scripts/migrate-server-mysql55-to-mariadb118.sh "\"pinnedCommit\":\"${expected_catalog_commit}\"" SERVER_MIGRATION_CATALOG_PIN_MISSING
require_marker server/Dockerfile 'web-console-${CATTLE_UI_VERSION}.tar.gz' SERVER_UI_ARTIFACT_NOT_PARAMETERIZED
require_marker server/Dockerfile 'api-explorer-${CATTLE_API_UI_VERSION}.tar.gz' SERVER_API_UI_ARTIFACT_NOT_PARAMETERIZED
require_marker server/Dockerfile 'curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o /tmp/web-console.tar.gz "${artifact_base}/web-console-${CATTLE_UI_VERSION}.tar.gz"' SERVER_UI_ARTIFACT_DOWNLOAD_NOT_FAIL_CLOSED
require_marker server/Dockerfile 'if [ -f resources.jar ]; then unzip -oq resources.jar; rm -f resources.jar; fi' SERVER_EMBEDDED_BUNDLE_EXPANSION_MISSING
require_marker server/Dockerfile 'test -d WEB-INF/lib' SERVER_EMBEDDED_BUNDLE_WEB_INF_CHECK_MISSING
require_marker server/Dockerfile 'test -f io/cattle/platform/launcher/Main.class' SERVER_EMBEDDED_BUNDLE_LAUNCHER_CHECK_MISSING
require_marker server/Dockerfile 'tar xzf /tmp/web-console.tar.gz -C /usr/share/cattle/war --strip-components=1' SERVER_UI_ARTIFACT_TAR_NOT_FILE_BACKED
require_marker server/Dockerfile 'curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o /tmp/api-explorer.tar.gz "${artifact_base}/api-explorer-${CATTLE_API_UI_VERSION}.tar.gz"' SERVER_API_UI_ARTIFACT_DOWNLOAD_NOT_FAIL_CLOSED
require_marker server/Dockerfile 'tar xzf /tmp/api-explorer.tar.gz -C /usr/share/cattle/war/api-ui --strip-components=1' SERVER_API_UI_ARTIFACT_TAR_NOT_FILE_BACKED
require_marker server/Dockerfile "ARG GRAPHITE_EXPORTER_VERSION=${expected_graphite_exporter_version}" SERVER_GRAPHITE_EXPORTER_VERSION_NOT_PINNED
require_marker server/Dockerfile "ARG GRAPHITE_EXPORTER_ARTIFACT_SHA256=${expected_graphite_exporter_artifact_sha256}" SERVER_GRAPHITE_EXPORTER_ARTIFACT_SHA256_NOT_PINNED
require_marker server/Dockerfile "ARG GRAPHITE_EXPORTER_BINARY_SHA256=${expected_graphite_exporter_binary_sha256}" SERVER_GRAPHITE_EXPORTER_BINARY_SHA256_NOT_PINNED
require_marker server/Dockerfile 'curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o /tmp/graphite_exporter.tar.gz "${artifact_base}/graphite_exporter-${GRAPHITE_EXPORTER_VERSION}.linux-amd64.tar.gz"' SERVER_GRAPHITE_EXPORTER_DOWNLOAD_NOT_FAIL_CLOSED
require_marker server/Dockerfile 'graphite_archive_root="graphite_exporter-${GRAPHITE_EXPORTER_VERSION}.linux-amd64"' SERVER_GRAPHITE_EXPORTER_OFFICIAL_ARCHIVE_ROOT_MISSING
require_marker server/Dockerfile 'install -m 0755 "${graphite_tmp_dir}/${graphite_archive_root}/graphite_exporter" /usr/bin/graphite_exporter' SERVER_GRAPHITE_EXPORTER_INSTALL_MISSING
require_marker server/Dockerfile 'install -m 0644 "${graphite_tmp_dir}/${graphite_archive_root}/LICENSE" /usr/share/licenses/graphite-exporter/LICENSE' SERVER_GRAPHITE_EXPORTER_LICENSE_INSTALL_MISSING
require_marker server/Dockerfile 'install -m 0644 "${graphite_tmp_dir}/${graphite_archive_root}/NOTICE" /usr/share/licenses/graphite-exporter/NOTICE' SERVER_GRAPHITE_EXPORTER_NOTICE_INSTALL_MISSING
require_marker server/Dockerfile 'test -x /usr/bin/graphite_exporter' SERVER_GRAPHITE_EXPORTER_EXECUTABLE_CHECK_MISSING
reject_marker server/Dockerfile 'tar -xzf /tmp/graphite_exporter.tar.gz -C /usr/bin/ graphite_exporter' SERVER_GRAPHITE_EXPORTER_OFFICIAL_LAYOUT_IGNORED
require_marker server/Dockerfile "ARG RUNTIME_LICENSE_BUNDLE_VERSION=${expected_runtime_license_bundle_version}" SERVER_RUNTIME_LICENSE_BUNDLE_VERSION_NOT_PINNED
require_marker server/Dockerfile "ARG RUNTIME_LICENSE_BUNDLE_SHA256=${expected_runtime_license_bundle_sha256}" SERVER_RUNTIME_LICENSE_BUNDLE_SHA256_NOT_PINNED
require_marker server/Dockerfile 'pasturestack-runtime-licenses-${RUNTIME_LICENSE_BUNDLE_VERSION}.tar.xz' SERVER_RUNTIME_LICENSE_BUNDLE_DOWNLOAD_MISSING
require_marker server/Dockerfile 'tar -xJf /tmp/runtime-licenses.tar.xz -C /usr/share/licenses/pasturestack-runtime --strip-components=1' SERVER_RUNTIME_LICENSE_BUNDLE_INSTALL_MISSING
require_marker server/Dockerfile '(cd /usr/share/licenses/pasturestack-runtime && sha256sum -c FILES.sha256 >/dev/null)' SERVER_RUNTIME_LICENSE_BUNDLE_INTERNAL_HASH_CHECK_MISSING
require_marker server/Dockerfile 'test -f /usr/share/licenses/pasturestack-runtime/source-legal/server/LICENSE' SERVER_RUNTIME_LICENSE_BUNDLE_SERVER_LICENSE_MISSING
require_marker server/Dockerfile 'rm -f /tmp/web-console.tar.gz /tmp/api-explorer.tar.gz /tmp/graphite_exporter.tar.gz /tmp/runtime-licenses.tar.xz' SERVER_ARTIFACT_DOWNLOAD_TMP_CLEANUP_MISSING
require_marker server/Dockerfile 'ARG SOURCE_DATE_EPOCH=1784791898' SERVER_DOCKERFILE_SOURCE_DATE_EPOCH_MISSING
require_marker server/Dockerfile '/var/lib/mariadb \' SERVER_UNUSED_MARIADB_PACKAGE_DATADIR_NOT_REMOVED
require_marker server/Dockerfile '/var/cache/fontconfig/* \' SERVER_NONDETERMINISTIC_FONT_CACHE_NOT_REMOVED
require_marker server/Dockerfile '&& : > /etc/machine-id' SERVER_NONDETERMINISTIC_MACHINE_ID_NOT_CLEARED
require_marker server/Dockerfile 'jar --update --file "${resources_jar}" --date="${source_date_iso}"' SERVER_RESOURCE_JAR_FIXED_TIMESTAMP_UPDATE_MISSING
require_marker server/Dockerfile "find cache -type f \\( -path '*/.git/index' -o -path '*/.git/logs/*' \\) -delete" SERVER_CATALOG_GIT_VOLATILE_METADATA_NOT_REMOVED
require_marker server/Dockerfile 'rm -f local.db' SERVER_CATALOG_VOLATILE_DATABASE_NOT_REMOVED
require_marker server/Dockerfile 'catalog-service-sqlite --sqlite --validate --config repo.json; \' SERVER_CATALOG_VALIDATION_NOT_FAIL_CLOSED
require_marker server/build-image.sh "S6_OVERLAY_VERSION=${expected_s6_overlay_version}" SERVER_S6_OVERLAY_VERSION_NOT_PINNED
require_marker server/build-image.sh "S6_OVERLAY_ARTIFACT_SHA256=${expected_s6_overlay_artifact_sha256}" SERVER_S6_OVERLAY_SHA256_NOT_PINNED
require_marker server/build-image.sh 'S6_OVERLAY_ASSET="s6-overlay-amd64-v${S6_OVERLAY_VERSION}.tar.gz"' SERVER_S6_OVERLAY_ASSET_NOT_PARAMETERIZED
require_marker server/build-image.sh 'echo "${S6_OVERLAY_ARTIFACT_SHA256}  ${S6_OVERLAY_TARGET}" | sha256sum -c -' SERVER_S6_OVERLAY_HARD_PIN_CHECK_MISSING
require_marker server/build-image.sh 'source_date_epoch=${SOURCE_DATE_EPOCH:-$(git show -s --format=%ct "${server_revision}")}' SERVER_REPRODUCIBLE_EPOCH_DEFAULT_MISSING
require_marker server/build-image.sh 'if [[ ! "${source_date_epoch}" =~ ^[0-9]+$ ]]; then' SERVER_REPRODUCIBLE_EPOCH_VALIDATION_MISSING
require_marker server/build-image.sh 'export SOURCE_DATE_EPOCH="${source_date_epoch}"' SERVER_REPRODUCIBLE_EPOCH_EXPORT_MISSING
require_marker server/build-image.sh '--build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}"' SERVER_REPRODUCIBLE_EPOCH_BUILD_ARG_MISSING
require_marker server/build-image.sh 'rewrite-timestamp=true,unpack=false' SERVER_REPRODUCIBLE_LAYER_TIMESTAMP_REWRITE_MISSING
reject_marker server/Dockerfile 'curl -sL "${artifact_base}/ui/${CATTLE_UI_VERSION}.tar.gz" | tar' SERVER_UI_ARTIFACT_PIPE_DOWNLOAD_CAN_MASK_CURL_FAILURE
reject_marker server/Dockerfile 'curl -sL "${artifact_base}/api-ui/${CATTLE_API_UI_VERSION}.tar.gz" | tar' SERVER_API_UI_ARTIFACT_PIPE_DOWNLOAD_CAN_MASK_CURL_FAILURE
reject_marker server/Dockerfile 'curl -sL "${artifact_base}/graphite_exporter-${GRAPHITE_EXPORTER_VERSION}.linux-amd64.tar.gz" | tar' SERVER_GRAPHITE_EXPORTER_PIPE_DOWNLOAD_CAN_MASK_CURL_FAILURE
reject_marker server/Dockerfile 'ENV DEFAULT_CATTLE_BOOTSTRAP_REQUIRED_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.23' SERVER_DOCKERFILE_AGENT_BOOTSTRAP_IMAGE_STALE
reject_marker server/Dockerfile 'ENV DEFAULT_CATTLE_AGENT_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.23' SERVER_DOCKERFILE_AGENT_IMAGE_STALE
reject_marker server/Dockerfile.auth-hotfix 'ENV DEFAULT_CATTLE_BOOTSTRAP_REQUIRED_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.23' SERVER_AUTH_HOTFIX_AGENT_BOOTSTRAP_IMAGE_STALE
reject_marker server/Dockerfile.auth-hotfix 'ENV DEFAULT_CATTLE_AGENT_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.23' SERVER_AUTH_HOTFIX_AGENT_IMAGE_STALE
reject_marker scripts/migrate-server-mysql55-to-mariadb118.sh 'RC16_AGENT_IMAGE="${RC16_AGENT_IMAGE:-ghcr.io/pasturestack/node-agent:v1.2.23}"' SERVER_MIGRATION_AGENT_IMAGE_DEFAULT_STALE
require_marker server/Dockerfile 'org.opencontainers.image.source="https://github.com/PastureStack/server"' SERVER_OCI_SOURCE_LABEL_MISSING
require_marker server/Dockerfile 'org.opencontainers.image.description="PastureStack server compatibility image."' SERVER_OCI_DESCRIPTION_LABEL_MISSING
require_marker server/Dockerfile 'org.opencontainers.image.licenses="Apache-2.0"' SERVER_OCI_LICENSE_LABEL_MISSING
require_marker server/Dockerfile "org.opencontainers.image.version=\"${expected_server_version}\"" SERVER_OCI_VERSION_LABEL_MISSING
require_marker server/Dockerfile 'org.opencontainers.image.revision="${PASTURESTACK_SERVER_REVISION}"' SERVER_OCI_REVISION_LABEL_MISSING
require_marker server/Dockerfile "ARG CATALOG_SERVICE_VERSION=${expected_catalog_service_version}" SERVER_CATALOG_HELPER_VERSION_NOT_CURRENT
require_marker server/Dockerfile "ARG CATALOG_SERVICE_ARTIFACT_SHA256=${expected_catalog_service_sha256}" SERVER_CATALOG_HELPER_SHA256_NOT_CURRENT
require_marker server/Dockerfile 'catalog-service-${CATALOG_SERVICE_VERSION}.tar.xz' SERVER_CATALOG_HELPER_PACKAGE_NOT_CURRENT
require_marker server/Dockerfile 'install -m 0755 "${tmp_dir}/catalog-service-sqlite" /usr/bin/catalog-service-sqlite' SERVER_CATALOG_SQLITE_BINARY_NOT_PRESERVED
require_marker server/Dockerfile 'catalog-service-sqlite --sqlite --validate --config repo.json; \' SERVER_CATALOG_SQLITE_VALIDATE_NOT_FAIL_CLOSED
reject_marker server/Dockerfile 'catalog-service-sqlite --sqlite --validate --config repo.json && \' SERVER_CATALOG_SQLITE_VALIDATE_CAN_BE_MASKED
require_marker server/Dockerfile 'ln -sfn catalog-service /usr/bin/rancher-catalog-service' SERVER_CATALOG_COMPATIBILITY_ALIAS_MISSING
require_marker server/Dockerfile 'install_service_wrapper catalog-service rancher-catalog-service' SERVER_CATALOG_PRIMARY_WRAPPER_MISSING
require_marker server/Dockerfile.auth-hotfix 'install_service_wrapper catalog-service rancher-catalog-service' SERVER_AUTH_HOTFIX_CATALOG_PRIMARY_WRAPPER_MISSING
require_marker server/Dockerfile "ARG AUTHENTICATION_SERVICE_VERSION=${expected_authentication_service_version}" SERVER_AUTH_HELPER_VERSION_NOT_CURRENT
require_marker server/Dockerfile "ARG AUTHENTICATION_SERVICE_ARTIFACT_SHA256=${expected_authentication_service_sha256}" SERVER_AUTH_HELPER_SHA256_NOT_CURRENT
require_marker server/Dockerfile 'authentication-service-${AUTHENTICATION_SERVICE_VERSION}-linux-amd64.tar.xz' SERVER_AUTH_HELPER_PACKAGE_NOT_CURRENT
require_marker server/Dockerfile 'install -m 0755 "${tmp_dir}/authentication-service" /usr/bin/authentication-service' SERVER_AUTH_HELPER_BINARY_NOT_CURRENT
require_marker server/Dockerfile 'ln -sfn authentication-service /usr/bin/rancher-auth-service' SERVER_AUTH_COMPATIBILITY_ALIAS_MISSING
require_marker server/Dockerfile 'install_service_wrapper authentication-service rancher-auth-service' SERVER_AUTH_PRIMARY_WRAPPER_MISSING
require_marker server/Dockerfile.auth-hotfix 'install_service_wrapper authentication-service rancher-auth-service' SERVER_AUTH_HOTFIX_PRIMARY_WRAPPER_MISSING
require_marker server/Dockerfile "ARG COMPOSE_EXECUTOR_VERSION=${expected_compose_executor_version}" SERVER_COMPOSE_EXECUTOR_VERSION_NOT_CURRENT
require_marker server/Dockerfile "ARG COMPOSE_EXECUTOR_BINARY_SHA256=${expected_compose_executor_binary_sha256}" SERVER_COMPOSE_EXECUTOR_BINARY_SHA256_NOT_CURRENT
require_marker server/Dockerfile 'test -x /usr/bin/compose-executor' SERVER_COMPOSE_EXECUTOR_BINARY_MISSING
require_marker server/Dockerfile 'echo "${COMPOSE_EXECUTOR_BINARY_SHA256}  /usr/bin/compose-executor" | sha256sum -c -' SERVER_COMPOSE_EXECUTOR_BINARY_NOT_VERIFIED
require_marker server/Dockerfile 'ln -sfn compose-executor /usr/bin/rancher-compose-executor' SERVER_COMPOSE_EXECUTOR_COMPATIBILITY_ALIAS_MISSING
require_marker server/Dockerfile.auth-hotfix 'ln -sfn "${canonical}" "/usr/bin/${legacy}"' SERVER_AUTH_HOTFIX_SERVICE_COMPATIBILITY_ALIAS_MISSING
require_marker server/Dockerfile 'install_service_wrapper compose-executor rancher-compose-executor' SERVER_COMPOSE_EXECUTOR_PRIMARY_WRAPPER_MISSING
require_marker server/Dockerfile.auth-hotfix 'install_service_wrapper compose-executor rancher-compose-executor' SERVER_AUTH_HOTFIX_COMPOSE_EXECUTOR_PRIMARY_WRAPPER_MISSING
require_marker server/Dockerfile "ARG HOST_PROVISIONER_VERSION=${expected_host_provisioner_version}" SERVER_HOST_PROVISIONER_VERSION_NOT_CURRENT
require_marker server/Dockerfile "ARG HOST_PROVISIONER_BINARY_SHA256=${expected_host_provisioner_binary_sha256}" SERVER_HOST_PROVISIONER_BINARY_SHA256_NOT_CURRENT
require_marker server/Dockerfile 'test -x /usr/bin/host-provisioner' SERVER_HOST_PROVISIONER_BINARY_MISSING
require_marker server/Dockerfile 'echo "${HOST_PROVISIONER_BINARY_SHA256}  /usr/bin/host-provisioner" | sha256sum -c -' SERVER_HOST_PROVISIONER_BINARY_NOT_VERIFIED
require_marker server/Dockerfile 'ln -sfn host-provisioner /usr/bin/go-machine-service' SERVER_HOST_PROVISIONER_COMPATIBILITY_ALIAS_MISSING
require_marker server/Dockerfile 'install_service_wrapper host-provisioner go-machine-service' SERVER_HOST_PROVISIONER_PRIMARY_WRAPPER_MISSING
require_marker server/Dockerfile.auth-hotfix 'install_service_wrapper host-provisioner go-machine-service' SERVER_AUTH_HOTFIX_HOST_PROVISIONER_PRIMARY_WRAPPER_MISSING
require_marker server/Dockerfile "ARG MACHINE_DRIVER_BUNDLE_VERSION=${expected_machine_driver_bundle_version}" SERVER_MACHINE_DRIVER_BUNDLE_VERSION_NOT_CURRENT
require_marker server/Dockerfile "ARG MACHINE_MANAGER_BINARY_SHA256=${expected_machine_manager_binary_sha256}" SERVER_MACHINE_MANAGER_BINARY_SHA256_NOT_CURRENT
require_marker server/Dockerfile "ARG PACKET_DRIVER_BINARY_SHA256=${expected_packet_driver_binary_sha256}" SERVER_PACKET_DRIVER_BINARY_SHA256_NOT_CURRENT
require_marker server/Dockerfile 'test -x /usr/bin/docker-machine' SERVER_MACHINE_MANAGER_BINARY_MISSING
require_marker server/Dockerfile 'test -x /usr/bin/docker-machine-driver-packet' SERVER_PACKET_DRIVER_BINARY_MISSING
require_marker server/Dockerfile 'machine_license_dir=/usr/share/licenses/pasturestack/machine-driver-bundle' SERVER_MACHINE_DRIVER_LICENSE_DESTINATION_MISSING
require_marker server/Dockerfile "ARG VSPHERE_CLI_BUNDLE_VERSION=${expected_vsphere_cli_bundle_version}" SERVER_VSPHERE_CLI_BUNDLE_VERSION_NOT_CURRENT
require_marker server/Dockerfile "ARG GOVC_BINARY_SHA256=${expected_govc_binary_sha256}" SERVER_GOVC_BINARY_SHA256_NOT_CURRENT
require_marker server/Dockerfile 'test -x /usr/bin/govc' SERVER_GOVC_BINARY_MISSING
require_marker server/Dockerfile 'echo "${GOVC_BINARY_SHA256}  /usr/bin/govc" | sha256sum -c -' SERVER_GOVC_BINARY_NOT_VERIFIED
require_marker server/Dockerfile 'vsphere_license_dir=/usr/share/licenses/pasturestack/vsphere-cli-bundle' SERVER_VSPHERE_CLI_LICENSE_DESTINATION_MISSING
require_marker server/Dockerfile "ARG SECRET_DELIVERY_API_VERSION=${expected_secret_delivery_api_version}" SERVER_SECRET_DELIVERY_API_VERSION_NOT_CURRENT
require_marker server/Dockerfile "ARG SECRET_DELIVERY_API_BINARY_SHA256=${expected_secret_delivery_api_binary_sha256}" SERVER_SECRET_DELIVERY_API_BINARY_SHA256_NOT_CURRENT
require_marker server/Dockerfile 'test -x /usr/bin/secret-delivery-api' SERVER_SECRET_DELIVERY_API_BINARY_MISSING
require_marker server/Dockerfile 'echo "${SECRET_DELIVERY_API_BINARY_SHA256}  /usr/bin/secret-delivery-api" | sha256sum -c -' SERVER_SECRET_DELIVERY_API_BINARY_NOT_VERIFIED
require_marker server/Dockerfile 'ln -sfn secret-delivery-api /usr/bin/secrets-api' SERVER_SECRET_DELIVERY_API_COMPATIBILITY_ALIAS_MISSING
require_marker server/Dockerfile 'secret_delivery_license_dir=/usr/share/licenses/pasturestack/secret-delivery-api' SERVER_SECRET_DELIVERY_API_LICENSE_DESTINATION_MISSING
require_marker server/Dockerfile "ARG USAGE_TELEMETRY_AGENT_VERSION=${expected_usage_telemetry_agent_version}" SERVER_USAGE_TELEMETRY_AGENT_VERSION_NOT_CURRENT
require_marker server/Dockerfile "ARG USAGE_TELEMETRY_AGENT_BINARY_SHA256=${expected_usage_telemetry_agent_binary_sha256}" SERVER_USAGE_TELEMETRY_AGENT_BINARY_SHA256_NOT_CURRENT
require_marker server/Dockerfile 'test -x /usr/bin/usage-telemetry-agent' SERVER_USAGE_TELEMETRY_AGENT_BINARY_MISSING
require_marker server/Dockerfile 'echo "${USAGE_TELEMETRY_AGENT_BINARY_SHA256}  /usr/bin/usage-telemetry-agent" | sha256sum -c -' SERVER_USAGE_TELEMETRY_AGENT_BINARY_NOT_VERIFIED
require_marker server/Dockerfile 'ln -sfn usage-telemetry-agent /usr/bin/telemetry' SERVER_USAGE_TELEMETRY_AGENT_COMPATIBILITY_ALIAS_MISSING
require_marker server/Dockerfile 'usage_telemetry_license_dir=/usr/share/licenses/pasturestack/usage-telemetry-agent' SERVER_USAGE_TELEMETRY_AGENT_LICENSE_DESTINATION_MISSING
require_marker server/Dockerfile "ARG WEBHOOK_AUTOMATION_SERVICE_VERSION=${expected_webhook_automation_service_version}" SERVER_WEBHOOK_AUTOMATION_SERVICE_VERSION_NOT_CURRENT
require_marker server/Dockerfile "ARG WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256=${expected_webhook_automation_service_binary_sha256}" SERVER_WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256_NOT_CURRENT
require_marker server/Dockerfile 'webhook_automation_license_dir=/usr/share/licenses/pasturestack/webhook-automation-service' SERVER_WEBHOOK_AUTOMATION_SERVICE_LICENSE_DESTINATION_MISSING
require_marker server/Dockerfile 'echo "${WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256}  /usr/bin/webhook-automation-service" | sha256sum -c -' SERVER_WEBHOOK_AUTOMATION_SERVICE_BINARY_CHECK_MISSING
require_marker server/Dockerfile 'ln -sfn webhook-automation-service /usr/bin/webhook-service' SERVER_WEBHOOK_AUTOMATION_SERVICE_COMPATIBILITY_LINK_MISSING
require_marker server/Dockerfile "ARG WINDOWS_AGENT_VERSION=${expected_windows_agent_version}" SERVER_WINDOWS_AGENT_VERSION_NOT_CURRENT
require_marker server/Dockerfile "ARG WINDOWS_AGENT_ARTIFACT_SHA256=${expected_windows_agent_artifact_sha256}" SERVER_WINDOWS_AGENT_ARTIFACT_SHA256_NOT_CURRENT
require_marker server/Dockerfile.auth-hotfix "ARG WINDOWS_AGENT_VERSION=${expected_windows_agent_version}" SERVER_AUTH_HOTFIX_WINDOWS_AGENT_VERSION_NOT_CURRENT
require_marker server/Dockerfile.auth-hotfix "ARG WINDOWS_AGENT_ARTIFACT_SHA256=${expected_windows_agent_artifact_sha256}" SERVER_AUTH_HOTFIX_WINDOWS_AGENT_ARTIFACT_SHA256_NOT_CURRENT
reject_marker server/Dockerfile '/usr/lib/jvm/zulu-8-amd64' SERVER_DOCKERFILE_STILL_HAS_ZULU8_PATH
reject_marker server/Dockerfile 'ui/1.6.52.tar.gz' SERVER_DOCKERFILE_STILL_HARDCODES_OLD_UI

require_marker server/artifacts/install_cattle_binaries 'local ui_version="${CATTLE_UI_VERSION:-1.6.56}"' SERVER_INSTALL_UI_VERSION_DEFAULT_MISSING
require_marker server/artifacts/install_cattle_binaries '/web-console-${ui_version}.tar.gz' SERVER_INSTALL_UI_REWRITE_NOT_PARAMETERIZED
require_marker server/artifacts/install_cattle_binaries '/api-explorer-${api_ui_version}.tar.gz' SERVER_INSTALL_API_UI_REWRITE_NOT_PARAMETERIZED
require_marker server/Dockerfile "ENV PASTURESTACK_RELEASE_BASE_URL=https://github.com/PastureStack/server/releases/download/${expected_server_version}" SERVER_GITHUB_RELEASE_BASE_NOT_CURRENT
require_marker server/Dockerfile 'https://github.com/PastureStack/catalog-templates.git' SERVER_GITHUB_CATALOG_URL_MISSING
require_marker server/Dockerfile "\"pinnedCommit\":\"${expected_catalog_commit}\"" SERVER_GITHUB_CATALOG_PIN_MISSING
reject_marker server/artifacts/install_cattle_binaries '/ui/1.6.52' SERVER_INSTALL_STILL_HARDCODES_OLD_UI
require_marker server/artifacts/install_cattle_binaries 'catalog-service-${RC16_CATALOG_SERVICE_VERSION}.tar.xz,catalog-service' SERVER_INSTALLER_CATALOG_HELPER_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries 'authentication-service-${RC16_AUTHENTICATION_SERVICE_VERSION}-linux-amd64.tar.xz,authentication-service' SERVER_INSTALLER_AUTH_HELPER_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries "RC16_WEBSOCKET_PROXY_VERSION=\"\${RC16_WEBSOCKET_PROXY_VERSION:-${expected_websocket_proxy_version}}\"" SERVER_INSTALLER_WEBSOCKET_VERSION_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries 'websocket-proxy-${RC16_WEBSOCKET_PROXY_VERSION}-linux-amd64.tar.xz,websocket-proxy' SERVER_INSTALLER_WEBSOCKET_PACKAGE_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries "RC16_COMPOSE_EXECUTOR_VERSION=\"\${RC16_COMPOSE_EXECUTOR_VERSION:-${expected_compose_executor_version}}\"" SERVER_INSTALLER_COMPOSE_EXECUTOR_VERSION_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries 'compose-executor-${RC16_COMPOSE_EXECUTOR_VERSION}-linux-amd64.gz,compose-executor' SERVER_INSTALLER_COMPOSE_EXECUTOR_PACKAGE_NOT_CURRENT
reject_marker server/artifacts/install_cattle_binaries '${RC16_ARTIFACT_BASE_URL}/rancher-compose-executor-v0.14.30.gz,rancher-compose-executor' SERVER_INSTALLER_COMPOSE_EXECUTOR_BRANDED_ASSET_PRESENT
require_marker server/artifacts/install_cattle_binaries "RC16_HOST_PROVISIONER_VERSION=\"\${RC16_HOST_PROVISIONER_VERSION:-${expected_host_provisioner_version}}\"" SERVER_INSTALLER_HOST_PROVISIONER_VERSION_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries 'host-provisioner-${RC16_HOST_PROVISIONER_VERSION}-linux-amd64.tar.xz,host-provisioner' SERVER_INSTALLER_HOST_PROVISIONER_PACKAGE_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries "RC16_MACHINE_DRIVER_BUNDLE_VERSION=\"\${RC16_MACHINE_DRIVER_BUNDLE_VERSION:-${expected_machine_driver_bundle_version}}\"" SERVER_INSTALLER_MACHINE_DRIVER_BUNDLE_VERSION_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries 'machine-driver-bundle-${RC16_MACHINE_DRIVER_BUNDLE_VERSION}-linux-amd64.tar.xz,docker-machine' SERVER_INSTALLER_MACHINE_DRIVER_BUNDLE_PACKAGE_NOT_CURRENT
reject_marker server/artifacts/install_cattle_binaries '${RC16_ARTIFACT_BASE_URL}/docker-machine-v0.14.0.tar.gz,docker-machine' SERVER_INSTALLER_OLD_MACHINE_BUNDLE_ASSET_PRESENT
require_marker server/artifacts/install_cattle_binaries "RC16_VSPHERE_CLI_BUNDLE_VERSION=\"\${RC16_VSPHERE_CLI_BUNDLE_VERSION:-${expected_vsphere_cli_bundle_version}}\"" SERVER_INSTALLER_VSPHERE_CLI_BUNDLE_VERSION_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries 'vsphere-cli-bundle-${RC16_VSPHERE_CLI_BUNDLE_VERSION}-linux-amd64.tar.xz,govc' SERVER_INSTALLER_VSPHERE_CLI_BUNDLE_PACKAGE_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries 'https?://[^,[:space:]]*/govc-v0\.[0-9]+\.[0-9]+(-go[0-9]+)?-linux-amd64\.tar\.gz(,govc)?' SERVER_INSTALLER_GOVC_COMPATIBILITY_REWRITE_MISSING
require_marker server/artifacts/install_cattle_binaries 'https?://[^,[:space:]]*/vsphere-cli-bundle-0\.[0-9]+\.[0-9]+-linux-amd64\.tar\.xz(,govc)?' SERVER_INSTALLER_VSPHERE_CLI_CANONICAL_REWRITE_MISSING
reject_marker server/artifacts/install_cattle_binaries '${RC16_ARTIFACT_BASE_URL}/govc-v0.54.1-go1264-linux-amd64.tar.gz' SERVER_INSTALLER_OLD_GOVC_ASSET_PRESENT
require_marker server/artifacts/install_cattle_binaries "RC16_SECRET_DELIVERY_API_VERSION=\"\${RC16_SECRET_DELIVERY_API_VERSION:-${expected_secret_delivery_api_version}}\"" SERVER_INSTALLER_SECRET_DELIVERY_API_VERSION_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries 'secret-delivery-api-${RC16_SECRET_DELIVERY_API_VERSION}-linux-amd64.tar.xz,secret-delivery-api' SERVER_INSTALLER_SECRET_DELIVERY_API_PACKAGE_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries 'https?://[^,[:space:]]*/secrets-api-v?0\.2\.[0-9]+(,secrets-api)?' SERVER_INSTALLER_SECRET_DELIVERY_API_COMPATIBILITY_REWRITE_MISSING
require_marker server/artifacts/install_cattle_binaries 'https?://[^,[:space:]]*/secret-delivery-api-0\.2\.[0-9]+-linux-amd64\.tar\.xz(,(secrets-api|secret-delivery-api))?' SERVER_INSTALLER_SECRET_DELIVERY_API_CANONICAL_REWRITE_MISSING
require_marker server/artifacts/install_cattle_binaries "RC16_USAGE_TELEMETRY_AGENT_VERSION=\"\${RC16_USAGE_TELEMETRY_AGENT_VERSION:-${expected_usage_telemetry_agent_version}}\"" SERVER_INSTALLER_USAGE_TELEMETRY_AGENT_VERSION_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries 'usage-telemetry-agent-${RC16_USAGE_TELEMETRY_AGENT_VERSION}-linux-amd64.tar.xz,usage-telemetry-agent' SERVER_INSTALLER_USAGE_TELEMETRY_AGENT_PACKAGE_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries 'https?://[^,[:space:]]*/telemetry(-v)?0\.4\.[0-9]+\.tar\.xz(,telemetry)?' SERVER_INSTALLER_USAGE_TELEMETRY_COMPATIBILITY_REWRITE_MISSING
require_marker server/artifacts/install_cattle_binaries 'https?://[^,[:space:]]*/usage-telemetry-agent-0\.4\.0-pasturestack\.[0-9]+-linux-amd64\.tar\.xz(,(telemetry|usage-telemetry-agent))?' SERVER_INSTALLER_USAGE_TELEMETRY_CANONICAL_REWRITE_MISSING
reject_marker server/artifacts/install_cattle_binaries '${RC16_ARTIFACT_BASE_URL}/telemetry-v0.4.0.tar.xz,telemetry' SERVER_INSTALLER_RETIRED_TELEMETRY_ASSET_PRESENT
require_marker server/artifacts/install_cattle_binaries "RC16_WEBHOOK_AUTOMATION_SERVICE_VERSION=\"\${RC16_WEBHOOK_AUTOMATION_SERVICE_VERSION:-${expected_webhook_automation_service_version}}\"" SERVER_INSTALLER_WEBHOOK_AUTOMATION_SERVICE_VERSION_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries 'webhook-automation-service-${RC16_WEBHOOK_AUTOMATION_SERVICE_VERSION}-linux-amd64.tar.xz,webhook-automation-service' SERVER_INSTALLER_WEBHOOK_AUTOMATION_SERVICE_PACKAGE_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries 'https?://[^,[:space:]]*/webhook-service-?v?0\.9\.[0-9]+\.tar\.xz(,webhook-service)?' SERVER_INSTALLER_WEBHOOK_AUTOMATION_COMPATIBILITY_REWRITE_MISSING
require_marker server/artifacts/install_cattle_binaries 'https?://[^,[:space:]]*/webhook-automation-service-0\.9\.15-pasturestack\.[0-9]+-linux-amd64\.tar\.xz(,(webhook-service|webhook-automation-service))?' SERVER_INSTALLER_WEBHOOK_AUTOMATION_CANONICAL_REWRITE_MISSING
reject_marker server/artifacts/install_cattle_binaries '${RC16_ARTIFACT_BASE_URL}/webhook-service-v0.9.15.tar.xz,webhook-service' SERVER_INSTALLER_RETIRED_WEBHOOK_ASSET_PRESENT
require_marker server/artifacts/install_cattle_binaries "RC16_WINDOWS_AGENT_VERSION=\"\${RC16_WINDOWS_AGENT_VERSION:-${expected_windows_agent_version}}\"" SERVER_INSTALLER_WINDOWS_AGENT_VERSION_NOT_CURRENT
require_marker server/artifacts/install_cattle_binaries 'node-agent-${RC16_WINDOWS_AGENT_VERSION}-windows-amd64.zip' SERVER_INSTALLER_WINDOWS_AGENT_PACKAGE_NOT_CURRENT
reject_marker server/artifacts/install_cattle_binaries 'go-machine-service-v0.39.8.tar.xz' SERVER_INSTALLER_UNREVIEWED_GMS_ASSET_PRESENT
reject_marker server/bin/update-platform-ssl '/usr/lib/jvm/zulu-8-amd64' SERVER_SSL_UPDATE_STILL_HAS_ZULU8_PATH
reject_marker server/Dockerfile.auth-hotfix 'ln -sf /usr/bin/rancher-catalog-service.real /usr/bin/rancher-catalog-service-sqlite' SERVER_AUTH_HOTFIX_SQLITE_SYMLINKS_TO_NOSQLITE
reject_marker server/Dockerfile 'ln -sf /usr/bin/rancher-catalog-service.real /usr/bin/rancher-catalog-service-sqlite' SERVER_SQLITE_SYMLINKS_TO_NOSQLITE
require_marker server/Dockerfile.externaldb "ARG BASE_IMAGE=ghcr.io/pasturestack/server:${expected_server_version}" SERVER_EXTERNALDB_BASE_NOT_CURRENT
require_marker server/Dockerfile.auth-hotfix "ARG BASE_IMAGE=ghcr.io/pasturestack/server:${expected_server_version}" SERVER_AUTH_HOTFIX_BASE_NOT_CURRENT
require_marker server/Dockerfile.auth-hotfix "ENV CATTLE_RANCHER_SERVER_VERSION=${expected_server_version}" SERVER_AUTH_HOTFIX_VERSION_NOT_CURRENT
require_marker server/Dockerfile.auth-hotfix "ENV CATTLE_CATTLE_VERSION=${expected_cattle_version}" SERVER_AUTH_HOTFIX_CATTLE_NOT_CURRENT
require_marker server/Dockerfile.auth-hotfix "ARG CATALOG_SERVICE_VERSION=${expected_catalog_service_version}" SERVER_AUTH_HOTFIX_CATALOG_HELPER_NOT_CURRENT
require_marker server/Dockerfile.auth-hotfix "ARG CATALOG_SERVICE_ARTIFACT_SHA256=${expected_catalog_service_sha256}" SERVER_AUTH_HOTFIX_CATALOG_SHA256_NOT_CURRENT
require_marker server/Dockerfile.auth-hotfix "ARG AUTHENTICATION_SERVICE_VERSION=${expected_authentication_service_version}" SERVER_AUTH_HOTFIX_AUTH_HELPER_VERSION_NOT_CURRENT
require_marker server/Dockerfile.auth-hotfix "ARG AUTHENTICATION_SERVICE_ARTIFACT_SHA256=${expected_authentication_service_sha256}" SERVER_AUTH_HOTFIX_AUTH_HELPER_SHA256_NOT_CURRENT
require_marker server/Dockerfile.auth-hotfix 'authentication-service-${AUTHENTICATION_SERVICE_VERSION}-linux-amd64.tar.xz' SERVER_AUTH_HOTFIX_AUTH_HELPER_PACKAGE_NOT_CURRENT
require_marker server/Dockerfile.auth-hotfix 'db/core-060.xml' SERVER_AUTH_HOTFIX_DB_PATCH_MISSING
require_marker server/Dockerfile.auth-hotfix 'db/core-124.xml' SERVER_AUTH_HOTFIX_CATALOG_DB_PATCH_MISSING
reject_marker server/Dockerfile.auth-hotfix 'v1.6.202' SERVER_AUTH_HOTFIX_STALE_SERVER_VERSION
reject_marker server/Dockerfile.auth-hotfix 'v0.183.218' SERVER_AUTH_HOTFIX_STALE_CATTLE_VERSION
require_marker server/artifacts/mysql.sh 'set -eo pipefail' SERVER_MYSQL_SCRIPT_PIPEFAIL_MISSING
require_marker server/artifacts/mysql.sh 'tzinfo_to_sql_bin()' SERVER_MYSQL_TZINFO_HELPER_MISSING
require_marker server/artifacts/mysql.sh 'command -v mariadb-tzinfo-to-sql || command -v mysql_tzinfo_to_sql' SERVER_MYSQL_TZINFO_CURRENT_TOOL_MISSING
require_marker server/artifacts/mysql.sh '"$(tzinfo_to_sql_bin)" /usr/share/zoneinfo | "$(mysql_bin)"' SERVER_MYSQL_TZINFO_HELPER_NOT_USED
reject_marker server/artifacts/mysql.sh 'mysql_tzinfo_to_sql /usr/share/zoneinfo |' SERVER_MYSQL_TZINFO_LEGACY_DIRECT_CALL_PRESENT
require_marker server/artifacts/mysql.sh '/etc/mysql/mariadb.conf.d/99-pasturestack.cnf' SERVER_MYSQL_CONFIG_NAME_NOT_CURRENT
require_marker server/artifacts/mysql.sh 'innodb_snapshot_isolation = OFF' SERVER_MYSQL_SNAPSHOT_ISOLATION_COMPATIBILITY_MISSING
reject_marker server/artifacts/mysql.sh '/etc/mysql/mariadb.conf.d/99-rancher.cnf' SERVER_MYSQL_OLD_CONFIG_NAME_PRESENT
require_marker server/Dockerfile '                    tzdata \' SERVER_DOCKERFILE_TZDATA_PACKAGE_MISSING
if [ "$require_promotion_defaults" = "true" ] || [ "$require_promotion_defaults" = "1" ]; then
  require_marker scripts/migrate-server-mysql55-to-mariadb118.sh "NEW_IMAGE=\"\${NEW_IMAGE:-ghcr.io/pasturestack/server:${expected_server_version}}\"" SERVER_MIGRATION_DEFAULT_NOT_CURRENT
  require_marker scripts/externaldb-restored-server-smoke.sh "server_image=\"\${SERVER_IMAGE:-ghcr.io/pasturestack/server-externaldb:${expected_server_version}}\"" SERVER_EXTERNALDB_SMOKE_DEFAULT_NOT_CURRENT
fi

printf 'failure_count=%s\n' "$failures"
[ "$failures" -eq 0 ]
printf 'SERVER_UI_ARTIFACT_VERSION_OK server=%s cattle=%s ui=%s api_ui=%s artifact_download_fail_closed=1 oci_labels=1 externaldb_base=1 auth_hotfix_base=1 promotion_defaults=%s helper_artifacts=1 catalog_sqlite_binary=1 vsphere_cli_bundle=1 usage_telemetry_agent=1 webhook_automation_service=1 govc_compatibility_rewrite=1 reproducible_epoch=1 zulu8_path=0 mariadb_tzinfo_tool=1 mariadb_tzdata=1 mariadb_snapshot_isolation_compatibility=1\n' \
  "$expected_server_version" "$expected_cattle_version" "$expected_ui_version" "$expected_api_ui_version" "$require_promotion_defaults"

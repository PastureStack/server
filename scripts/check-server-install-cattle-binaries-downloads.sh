#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

failure_count=0

fail() {
  printf '%s\n' "$1" >&2
  failure_count=$((failure_count + 1))
}

require_marker() {
  local file=$1
  local marker=$2
  local code=$3

  if ! grep -F -- "$marker" "$file" >/dev/null; then
    fail "$code"
  fi
}

reject_marker() {
  local file=$1
  local marker=$2
  local code=$3

  if grep -F -- "$marker" "$file" >/dev/null; then
    fail "$code"
  fi
}

if ! bash -n server/artifacts/install_cattle_binaries; then
  fail "SERVER_INSTALL_CATTLE_BINARIES_SYNTAX_INVALID"
fi

require_marker server/artifacts/install_cattle_binaries 'local connect_timeout="${RC16_INSTALL_BINARIES_CONNECT_TIMEOUT:-10}"' SERVER_INSTALL_CATTLE_BINARIES_CONNECT_TIMEOUT_MISSING
require_marker server/artifacts/install_cattle_binaries 'local max_time="${RC16_INSTALL_BINARIES_MAX_TIME:-300}"' SERVER_INSTALL_CATTLE_BINARIES_MAX_TIME_MISSING
require_marker server/artifacts/install_cattle_binaries 'curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout "$connect_timeout" --max-time "$max_time" -o "${file}" "${src}"' SERVER_INSTALL_CATTLE_BINARIES_CURL_NOT_BOUNDED
require_marker server/artifacts/install_cattle_binaries 'RC16_VERIFY_RELEASE_ASSETS="${RC16_VERIFY_RELEASE_ASSETS:-1}"' SERVER_INSTALL_CATTLE_BINARIES_INTEGRITY_DEFAULT_MISSING
require_marker server/artifacts/install_cattle_binaries 'bash /usr/share/cattle/verify_release_asset "${RC16_ARTIFACT_SHA256_FILE}" "${file}" >/dev/null' SERVER_INSTALL_CATTLE_BINARIES_INTEGRITY_CHECK_MISSING
reject_marker server/artifacts/install_cattle_binaries 'curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 -o "${file}" "${src}"' SERVER_INSTALL_CATTLE_BINARIES_LEGACY_UNBOUNDED_CURL

sample_run=$(mktemp -d "${TMPDIR:-/tmp}/rc16-install-cattle-binaries.XXXXXX")
cleanup() {
  rm -rf "$sample_run"
}
trap cleanup EXIT

curl_log="$sample_run/curl.log"
output_log="$sample_run/output.log"

(
  curl() {
    printf 'CURL' >>"$curl_log"
    local arg
    for arg in "$@"; do
      printf '\t%s' "$arg" >>"$curl_log"
    done
    printf '\n' >>"$curl_log"
  }

  export RC16_ARTIFACT_BASE_URL=https://artifacts.invalid/rc16
  export RC16_VERIFY_RELEASE_ASSETS=0
  # shellcheck source=/dev/null
  source server/artifacts/install_cattle_binaries
  cd "$sample_run"
  export RC16_INSTALL_BINARIES_CONNECT_TIMEOUT=4
  export RC16_INSTALL_BINARIES_MAX_TIME=31
  download_file '//downloads.example.invalid/tool.tar.gz?signature=abc'
) >"$output_log"

if ! grep -Fx 'tool.tar.gz' "$output_log" >/dev/null; then
  fail "SERVER_INSTALL_CATTLE_BINARIES_SAMPLE_BASENAME_MISMATCH"
fi

expected=$'CURL\t-fsSL\t--retry\t5\t--retry-all-errors\t--retry-delay\t2\t--connect-timeout\t4\t--max-time\t31\t-o\ttool.tar.gz\thttps://downloads.example.invalid/tool.tar.gz?signature=abc'
if ! grep -F -- "$expected" "$curl_log" >/dev/null; then
  fail "SERVER_INSTALL_CATTLE_BINARIES_SAMPLE_CURL_FLAGS_MISMATCH"
fi

cat >"$sample_run/cattle-global.properties" <<'EOF'
service.package.catalog.url=https://downloads.example.invalid/rancher-catalog-service-rc16-v0.1.4.tar.xz,rancher-catalog-service
service.package.catalog-placeholder.url=https://artifacts.invalid/rc16/catalog-service-v0.1.4.tar.xz,rancher-catalog-service
service.package.authentication.url=https://downloads.example.invalid/rancher-auth-service-rc16-v0.1.7,rancher-auth-service
service.package.authentication-placeholder.url=https://artifacts.invalid/rc16/authentication-service-v0.1.7,rancher-auth-service
service.package.websocket.url=https://artifacts.invalid/rc16/websocket-proxy-v0.23.12.tar.xz,websocket-proxy
service.package.compose-upstream.url=https://github.com/rancher/rancher-compose-executor/releases/download/v0.14.30/rancher-compose.gz,rancher-compose-executor
service.package.compose-prior.url=https://artifacts.invalid/rc16/rancher-compose-executor-v0.14.30.gz,rancher-compose-executor
service.package.compose-placeholder.url=https://artifacts.invalid/rc16/compose-cli-v0.14.30.gz,rancher-compose-executor
service.package.host-provisioner-upstream.url=https://github.com/rancher/go-machine-service/releases/download/v0.39.4/go-machine-service.tar.xz
service.package.host-provisioner-prior.url=https://artifacts.invalid/rc16/go-machine-service-v0.39.8.tar.xz,go-machine-service
service.package.host-provisioner-placeholder.url=https://artifacts.invalid/rc16/host-provisioner-v0.39.8.tar.xz,go-machine-service
service.package.machine-bundle-upstream.url=https://github.com/rancher/machine-package/releases/download/v0.14.0/docker-machine.tar.gz
service.package.machine-bundle-prior.url=https://artifacts.invalid/rc16/docker-machine-v0.14.0.tar.gz,docker-machine
service.package.machine-bundle-placeholder.url=https://artifacts.invalid/rc16/machine-package-0.14.0.tar.xz,docker-machine
service.package.vsphere-cli-upstream.url=https://github.com/vmware/govmomi/releases/download/v0.2.0/govc_linux_amd64.gz,govc
service.package.vsphere-cli-prior.url=https://artifacts.invalid/rc16/govc-v0.54.1-go1264-linux-amd64.tar.gz,govc
service.package.vsphere-cli-placeholder.url=https://artifacts.invalid/rc16/vsphere-cli-bundle-0.53.1-linux-amd64.tar.xz,govc
service.package.secret-delivery-upstream.url=https://github.com/rancher/secrets-api/releases/download/v0.2.2/secrets-api
service.package.secret-delivery-prior.url=https://artifacts.invalid/rc16/secrets-api-v0.2.1,secrets-api
service.package.secret-delivery-placeholder.url=https://artifacts.invalid/rc16/secret-delivery-api-0.2.1-linux-amd64.tar.xz,secrets-api
service.package.usage-telemetry-upstream.url=https://github.com/rancher/telemetry/releases/download/v0.4.0/telemetry.tar.xz
service.package.usage-telemetry-prior.url=https://artifacts.invalid/rc16/telemetry-v0.4.0.tar.xz,telemetry
service.package.usage-telemetry-placeholder.url=https://artifacts.invalid/rc16/usage-telemetry-agent-0.4.0-pasturestack.0-linux-amd64.tar.xz,telemetry
service.package.webhook-automation-upstream.url=https://github.com/rancher/webhook-service/releases/download/v0.9.15/webhook-service.tar.xz,webhook-service
service.package.webhook-automation-prior.url=https://artifacts.invalid/rc16/webhook-service-v0.9.15.tar.xz,webhook-service
service.package.webhook-automation-placeholder.url=https://artifacts.invalid/rc16/webhook-automation-service-0.9.15-pasturestack.0-linux-amd64.tar.xz,webhook-service
agent.package.per-host-subnet-upstream.url=https://github.com/rancher/per-host-subnet/releases/download/v0.2.4/rancher-per-host-subnet.zip
agent.package.per-host-subnet-prior.url=https://artifacts.invalid/rc16/rancher-per-host-subnet-v0.2.4.zip
agent.package.per-host-subnet-placeholder.url=https://artifacts.invalid/rc16/per-host-subnet-v0.2.4.zip
agent.package.windows-agent-upstream.url=https://github.com/rancher/agent/releases/download/v0.13.3/go-agent.zip
agent.package.windows-agent-prior.url=https://artifacts.invalid/rc16/go-agent-v0.13.3.zip
agent.package.windows-agent-placeholder.url=https://artifacts.invalid/rc16/node-agent-0.13.3.zip
agent.package.host-api-current.url=https://github.com/PastureStack/server/releases/download/v1.6.276/host-api-0.38.4.tar.gz
agent.package.python-agent-current.url=https://github.com/PastureStack/server/releases/download/v1.6.276/node-agent-0.13.21.tar.gz
agent.package.windows-agent-current.url=https://github.com/PastureStack/server/releases/download/v1.6.276/node-agent-0.13.21-windows-amd64.zip
agent.package.per-host-subnet-current.url=https://github.com/PastureStack/server/releases/download/v1.6.276/per-host-subnet-0.2.4-windows-amd64.zip
service.package.catalog-current.url=https://github.com/PastureStack/server/releases/download/v1.6.276/catalog-service-0.20.6.tar.xz,catalog-service
service.package.authentication-current.url=https://github.com/PastureStack/server/releases/download/v1.6.276/authentication-service-0.1.7-linux-amd64.tar.xz,authentication-service
service.package.compose-current.url=https://github.com/PastureStack/server/releases/download/v1.6.276/compose-executor-0.14.31-linux-amd64.gz,compose-executor
service.package.machine-bundle-current.url=https://github.com/PastureStack/server/releases/download/v1.6.276/machine-driver-bundle-0.14.0-linux-amd64.tar.xz,docker-machine
service.package.host-provisioner-current.url=https://github.com/PastureStack/server/releases/download/v1.6.276/host-provisioner-0.39.4-linux-amd64.tar.xz,host-provisioner
service.package.vsphere-cli-current.url=https://github.com/PastureStack/server/releases/download/v1.6.276/vsphere-cli-bundle-0.54.1-linux-amd64.tar.xz,govc
service.package.secret-delivery-current.url=https://github.com/PastureStack/server/releases/download/v1.6.276/secret-delivery-api-0.2.2-linux-amd64.tar.xz,secret-delivery-api
service.package.usage-telemetry-current.url=https://github.com/PastureStack/server/releases/download/v1.6.276/usage-telemetry-agent-0.4.0-pasturestack.1-linux-amd64.tar.xz,usage-telemetry-agent
service.package.webhook-automation-current.url=https://github.com/PastureStack/server/releases/download/v1.6.276/webhook-automation-service-0.9.15-pasturestack.1-linux-amd64.tar.xz,webhook-automation-service
service.package.websocket-current.url=https://github.com/PastureStack/server/releases/download/v1.6.276/websocket-proxy-0.23.12-linux-amd64.tar.xz,websocket-proxy
EOF
(
  export RC16_ARTIFACT_BASE_URL=https://artifacts.invalid/rc16
  # shellcheck source=/dev/null
  source server/artifacts/install_cattle_binaries
  cd "$sample_run"
  normalize_cattle_global_urls
)

cat >"$sample_run/current-release-expected.txt" <<'EOF'
agent.package.host-api-current.url=https://artifacts.invalid/rc16/host-api-0.38.4.tar.gz
agent.package.python-agent-current.url=https://artifacts.invalid/rc16/node-agent-0.13.21.tar.gz
agent.package.windows-agent-current.url=https://artifacts.invalid/rc16/node-agent-0.13.21-windows-amd64.zip
agent.package.per-host-subnet-current.url=https://artifacts.invalid/rc16/per-host-subnet-0.2.4-windows-amd64.zip
service.package.catalog-current.url=https://artifacts.invalid/rc16/catalog-service-0.20.6.tar.xz,catalog-service
service.package.authentication-current.url=https://artifacts.invalid/rc16/authentication-service-0.1.7-linux-amd64.tar.xz,authentication-service
service.package.compose-current.url=https://artifacts.invalid/rc16/compose-executor-0.14.31-linux-amd64.gz,compose-executor
service.package.machine-bundle-current.url=https://artifacts.invalid/rc16/machine-driver-bundle-0.14.0-linux-amd64.tar.xz,docker-machine
service.package.host-provisioner-current.url=https://artifacts.invalid/rc16/host-provisioner-0.39.4-linux-amd64.tar.xz,host-provisioner
service.package.vsphere-cli-current.url=https://artifacts.invalid/rc16/vsphere-cli-bundle-0.54.1-linux-amd64.tar.xz,govc
service.package.secret-delivery-current.url=https://artifacts.invalid/rc16/secret-delivery-api-0.2.2-linux-amd64.tar.xz,secret-delivery-api
service.package.usage-telemetry-current.url=https://artifacts.invalid/rc16/usage-telemetry-agent-0.4.0-pasturestack.1-linux-amd64.tar.xz,usage-telemetry-agent
service.package.webhook-automation-current.url=https://artifacts.invalid/rc16/webhook-automation-service-0.9.15-pasturestack.1-linux-amd64.tar.xz,webhook-automation-service
service.package.websocket-current.url=https://artifacts.invalid/rc16/websocket-proxy-0.23.12-linux-amd64.tar.xz,websocket-proxy
EOF
while IFS= read -r expected_current; do
  if ! grep -Fx -- "$expected_current" "$sample_run/cattle-global.properties" >/dev/null; then
    fail "SERVER_INSTALL_CATTLE_BINARIES_CURRENT_RELEASE_URL_MISMATCH expected=${expected_current}"
  fi
done <"$sample_run/current-release-expected.txt"

if ! grep -Fx 'service.package.catalog.url=https://artifacts.invalid/rc16/catalog-service-0.20.6.tar.xz,catalog-service' "$sample_run/cattle-global.properties" >/dev/null; then
  fail "SERVER_INSTALL_CATTLE_BINARIES_CATALOG_NEUTRAL_PACKAGE_MISMATCH"
fi
if ! grep -Fx 'service.package.catalog-placeholder.url=https://artifacts.invalid/rc16/catalog-service-0.20.6.tar.xz,catalog-service' "$sample_run/cattle-global.properties" >/dev/null; then
  fail "SERVER_INSTALL_CATTLE_BINARIES_CATALOG_PLACEHOLDER_NEUTRAL_PACKAGE_MISMATCH"
fi
if ! grep -Fx 'service.package.authentication.url=https://artifacts.invalid/rc16/authentication-service-0.1.7-linux-amd64.tar.xz,authentication-service' "$sample_run/cattle-global.properties" >/dev/null; then
  fail "SERVER_INSTALL_CATTLE_BINARIES_AUTHENTICATION_NEUTRAL_PACKAGE_MISMATCH"
fi
if ! grep -Fx 'service.package.authentication-placeholder.url=https://artifacts.invalid/rc16/authentication-service-0.1.7-linux-amd64.tar.xz,authentication-service' "$sample_run/cattle-global.properties" >/dev/null; then
  fail "SERVER_INSTALL_CATTLE_BINARIES_AUTHENTICATION_PLACEHOLDER_NEUTRAL_PACKAGE_MISMATCH"
fi
if ! grep -Fx 'service.package.websocket.url=https://artifacts.invalid/rc16/websocket-proxy-0.23.12-linux-amd64.tar.xz,websocket-proxy' "$sample_run/cattle-global.properties" >/dev/null; then
  fail "SERVER_INSTALL_CATTLE_BINARIES_WEBSOCKET_NEUTRAL_PACKAGE_MISMATCH"
fi
if ! grep -Fx 'service.package.compose-upstream.url=https://artifacts.invalid/rc16/compose-executor-0.14.31-linux-amd64.gz,compose-executor' "$sample_run/cattle-global.properties" >/dev/null; then
  fail "SERVER_INSTALL_CATTLE_BINARIES_COMPOSE_UPSTREAM_NEUTRAL_PACKAGE_MISMATCH"
fi
if ! grep -Fx 'service.package.compose-prior.url=https://artifacts.invalid/rc16/compose-executor-0.14.31-linux-amd64.gz,compose-executor' "$sample_run/cattle-global.properties" >/dev/null; then
  fail "SERVER_INSTALL_CATTLE_BINARIES_COMPOSE_PRIOR_NEUTRAL_PACKAGE_MISMATCH"
fi
if ! grep -Fx 'service.package.compose-placeholder.url=https://artifacts.invalid/rc16/compose-executor-0.14.31-linux-amd64.gz,compose-executor' "$sample_run/cattle-global.properties" >/dev/null; then
  fail "SERVER_INSTALL_CATTLE_BINARIES_COMPOSE_PLACEHOLDER_NEUTRAL_PACKAGE_MISMATCH"
fi
if ! grep -Fx 'service.package.host-provisioner-upstream.url=https://artifacts.invalid/rc16/host-provisioner-0.39.4-linux-amd64.tar.xz,host-provisioner' "$sample_run/cattle-global.properties" >/dev/null; then
  fail "SERVER_INSTALL_CATTLE_BINARIES_HOST_PROVISIONER_UPSTREAM_NEUTRAL_PACKAGE_MISMATCH"
fi
if ! grep -Fx 'service.package.host-provisioner-prior.url=https://artifacts.invalid/rc16/host-provisioner-0.39.4-linux-amd64.tar.xz,host-provisioner' "$sample_run/cattle-global.properties" >/dev/null; then
  fail "SERVER_INSTALL_CATTLE_BINARIES_HOST_PROVISIONER_PRIOR_NEUTRAL_PACKAGE_MISMATCH"
fi
if ! grep -Fx 'service.package.host-provisioner-placeholder.url=https://artifacts.invalid/rc16/host-provisioner-0.39.4-linux-amd64.tar.xz,host-provisioner' "$sample_run/cattle-global.properties" >/dev/null; then
  fail "SERVER_INSTALL_CATTLE_BINARIES_HOST_PROVISIONER_PLACEHOLDER_NEUTRAL_PACKAGE_MISMATCH"
fi
for package_key in upstream prior placeholder; do
  if ! grep -Fx "service.package.machine-bundle-${package_key}.url=https://artifacts.invalid/rc16/machine-driver-bundle-0.14.0-linux-amd64.tar.xz,docker-machine" "$sample_run/cattle-global.properties" >/dev/null; then
    fail "SERVER_INSTALL_CATTLE_BINARIES_MACHINE_DRIVER_BUNDLE_NEUTRAL_PACKAGE_MISMATCH key=${package_key}"
  fi
done
for package_key in upstream prior placeholder; do
  if ! grep -Fx "service.package.vsphere-cli-${package_key}.url=https://artifacts.invalid/rc16/vsphere-cli-bundle-0.54.1-linux-amd64.tar.xz,govc" "$sample_run/cattle-global.properties" >/dev/null; then
    fail "SERVER_INSTALL_CATTLE_BINARIES_VSPHERE_CLI_BUNDLE_NEUTRAL_PACKAGE_MISMATCH key=${package_key}"
  fi
done
for package_key in upstream prior placeholder; do
  if ! grep -Fx "service.package.secret-delivery-${package_key}.url=https://artifacts.invalid/rc16/secret-delivery-api-0.2.2-linux-amd64.tar.xz,secret-delivery-api" "$sample_run/cattle-global.properties" >/dev/null; then
    fail "SERVER_INSTALL_CATTLE_BINARIES_SECRET_DELIVERY_API_NEUTRAL_PACKAGE_MISMATCH key=${package_key}"
  fi
done
for package_key in upstream prior placeholder; do
  if ! grep -Fx "service.package.usage-telemetry-${package_key}.url=https://artifacts.invalid/rc16/usage-telemetry-agent-0.4.0-pasturestack.1-linux-amd64.tar.xz,usage-telemetry-agent" "$sample_run/cattle-global.properties" >/dev/null; then
    fail "SERVER_INSTALL_CATTLE_BINARIES_USAGE_TELEMETRY_AGENT_NEUTRAL_PACKAGE_MISMATCH key=${package_key}"
  fi
done
for package_key in upstream prior placeholder; do
  if ! grep -Fx "service.package.webhook-automation-${package_key}.url=https://artifacts.invalid/rc16/webhook-automation-service-0.9.15-pasturestack.1-linux-amd64.tar.xz,webhook-automation-service" "$sample_run/cattle-global.properties" >/dev/null; then
    fail "SERVER_INSTALL_CATTLE_BINARIES_WEBHOOK_AUTOMATION_SERVICE_NEUTRAL_PACKAGE_MISMATCH key=${package_key}"
  fi
done
for package_key in upstream prior placeholder; do
  if ! grep -Fx "agent.package.per-host-subnet-${package_key}.url=https://artifacts.invalid/rc16/per-host-subnet-0.2.4-windows-amd64.zip" "$sample_run/cattle-global.properties" >/dev/null; then
    fail "SERVER_INSTALL_CATTLE_BINARIES_PER_HOST_SUBNET_NEUTRAL_PACKAGE_MISMATCH key=${package_key}"
  fi
done
for package_key in upstream prior placeholder; do
  if ! grep -Fx "agent.package.windows-agent-${package_key}.url=https://artifacts.invalid/rc16/node-agent-0.13.21-windows-amd64.zip" "$sample_run/cattle-global.properties" >/dev/null; then
    fail "SERVER_INSTALL_CATTLE_BINARIES_WINDOWS_AGENT_NEUTRAL_PACKAGE_MISMATCH key=${package_key}"
  fi
done

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'SERVER_INSTALL_CATTLE_BINARIES_DOWNLOADS_OK curl_bounded=1 retry=5 timeout_overrides=1 normalize_url=1 sample=1 current_release_urls=14 neutral_helper_packages=1 neutral_compose_executor=1 neutral_host_provisioner=1 neutral_machine_driver_bundle=1 neutral_vsphere_cli_bundle=1 neutral_secret_delivery_api=1 neutral_usage_telemetry_agent=1 neutral_webhook_automation_service=1 neutral_per_host_subnet=1 neutral_windows_node_agent=1\n'

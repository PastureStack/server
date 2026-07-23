#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

failure_count=0
passed_gates=()

run_gate() {
  local name=$1
  shift

  printf 'SERVER_SOURCE_GATE_START gate=%s\n' "$name"
  if "$@"; then
    printf 'SERVER_SOURCE_GATE_PASS gate=%s\n' "$name"
    passed_gates+=("$name")
    return 0
  fi

  printf 'SERVER_SOURCE_GATE_FAIL gate=%s\n' "$name" >&2
  failure_count=$((failure_count + 1))
}

run_gate version_defaults scripts/check-server-ui-artifact-version.sh
run_gate dockerfile_artifact_downloads scripts/check-server-dockerfile-artifact-downloads.sh
run_gate server_dev_dockerfile_downloads scripts/check-server-dev-dockerfile-downloads.sh
run_gate install_cattle_binaries_downloads scripts/check-server-install-cattle-binaries-downloads.sh
run_gate build_artifact_downloads scripts/check-server-build-artifact-downloads.sh
run_gate cattle_sh_downloads scripts/check-server-cattle-sh-downloads.sh
run_gate cattle_sh_linked_env scripts/check-server-cattle-sh-linked-env.sh
run_gate client_download_urls scripts/check-server-client-download-urls.sh
run_gate metric_mapper scripts/check-server-metric-mapper.sh
run_gate entry_advertise_address scripts/check-server-entry-advertise-address.sh
run_gate websocket_proxy_wrapper scripts/check-server-websocket-proxy-wrapper.sh
run_gate bootstrap_read_env scripts/check-server-bootstrap-read-env.sh
run_gate bootstrap_downloads scripts/check-server-bootstrap-downloads.sh
run_gate agent_base_downloads scripts/check-agent-base-downloads.sh
run_gate agent_run_downloads scripts/check-agent-run-downloads.sh
run_gate agent_run_env_parsing scripts/check-agent-run-env-parsing.sh
run_gate scripts_test_env scripts/check-scripts-test-env.sh
run_gate host_compat_inventory scripts/check-legacy-host-compat-inventory.sh
run_gate externaldb_restored_smoke scripts/check-externaldb-restored-server-smoke.sh
run_gate db_sanity_check scripts/check-database-sanity-check.sh
run_gate local_auth_rollback scripts/check-enable-local-auth-with-rollback.sh
run_gate migration_local_http scripts/check-migration-local-http.sh
run_gate approved_runtime_coordinate_migration scripts/check-migrate-approved-runtime-coordinates.sh
run_gate pack200_free scripts/check-server-pack200-free.sh
run_gate strong_artifact_hash scripts/check-server-strong-artifact-hash.sh
run_gate release_asset_integrity scripts/check-server-release-asset-integrity.sh
run_gate graphite_exporter_artifact scripts/check-server-graphite-exporter-artifact.sh
run_gate s6_overlay_artifact scripts/check-server-s6-overlay-artifact.sh
run_gate runtime_license_bundle scripts/check-server-runtime-license-bundle.sh
run_gate compose_executor_artifact scripts/check-server-compose-executor-artifact.sh
run_gate host_provisioner_artifact scripts/check-server-host-provisioner-artifact.sh
run_gate machine_driver_bundle_artifact scripts/check-server-machine-driver-bundle-artifact.sh
run_gate vsphere_cli_bundle_artifact scripts/check-server-vsphere-cli-bundle-artifact.sh
run_gate secret_delivery_api_artifact scripts/check-server-secret-delivery-api-artifact.sh
run_gate usage_telemetry_agent_artifact scripts/check-server-usage-telemetry-agent-artifact.sh
run_gate webhook_automation_service_artifact scripts/check-server-webhook-automation-service-artifact.sh
run_gate per_host_subnet_artifact scripts/check-server-per-host-subnet-artifact.sh
run_gate windows_node_agent_artifact scripts/check-server-windows-node-agent-artifact.sh
run_gate server_jdk25_source_policy bash scripts/check-server-jdk25-source-policy.sh
run_gate cattle_artifact_mirror scripts/check-server-cattle-artifact-mirror.sh

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

passed_gate_list=$(IFS=,; printf '%s' "${passed_gates[*]}")
printf 'SERVER_SOURCE_GATES_OK gate_count=%s gates=%s manual_release_gates=jdk25_java_patches,cattle_jdk25_release_evidence\n' \
  "${#passed_gates[@]}" "$passed_gate_list"

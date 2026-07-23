#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

file=server/artifacts/cattle.sh
failures=0

require_marker() {
  local marker=$1
  local code=$2
  if ! grep -Fq -- "$marker" "$file"; then
    printf '%s marker=%s\n' "$code" "$marker"
    failures=$((failures + 1))
  fi
}

reject_marker() {
  local marker=$1
  local code=$2
  if grep -Fq -- "$marker" "$file"; then
    printf '%s marker=%s\n' "$code" "$marker"
    failures=$((failures + 1))
  fi
}

bash -n "$file"

require_marker 'local compose_version="${CATTLE_RANCHER_COMPOSE_VERSION:-v0.14.30}"' SERVER_COMPOSE_DOWNLOAD_VERSION_NOT_CURRENT
require_marker '${artifact_base}/compose-cli-${compose_asset_version}-linux-amd64.tar.gz' SERVER_COMPOSE_LINUX_DOWNLOAD_NOT_FLAT
require_marker '${artifact_base}/compose-cli-${compose_asset_version}-darwin-amd64.tar.gz' SERVER_COMPOSE_DARWIN_DOWNLOAD_NOT_FLAT
require_marker '${artifact_base}/compose-cli-${compose_asset_version}-windows-amd64.zip' SERVER_COMPOSE_WINDOWS_DOWNLOAD_NOT_FLAT
require_marker '${artifact_base}/pasturestack-cli-${cli_asset_version}-linux-amd64.tar.gz' SERVER_CLI_LINUX_DOWNLOAD_NOT_FLAT
require_marker '${artifact_base}/pasturestack-cli-${cli_asset_version}-darwin-amd64.tar.gz' SERVER_CLI_DARWIN_DOWNLOAD_NOT_FLAT
require_marker '${artifact_base}/pasturestack-cli-${cli_asset_version}-windows-amd64.zip' SERVER_CLI_WINDOWS_DOWNLOAD_NOT_FLAT
require_marker '${artifact_base}/compose-cli-${CATTLE_RANCHER_COMPOSE_VERSION#v}-linux-amd64.tar.gz' SERVER_MASTER_COMPOSE_DOWNLOAD_NOT_FLAT
require_marker '${artifact_base}/pasturestack-cli-${CATTLE_RANCHER_CLI_VERSION#v}-linux-amd64.tar.gz' SERVER_MASTER_CLI_DOWNLOAD_NOT_FLAT

reject_marker '/compose/${compose_version}/' SERVER_COMPOSE_LEGACY_RELEASE_SUBDIRECTORY_PRESENT
reject_marker '/cli/${cli_version}/' SERVER_CLI_LEGACY_RELEASE_SUBDIRECTORY_PRESENT
reject_marker 'rancher-compose-linux-amd64-' SERVER_COMPOSE_BRANDED_RELEASE_FILENAME_PRESENT
reject_marker 'rancher-linux-amd64-' SERVER_CLI_BRANDED_RELEASE_FILENAME_PRESENT

printf 'failure_count=%s\n' "$failures"
[ "$failures" -eq 0 ]
printf 'SERVER_CLIENT_DOWNLOAD_URLS_OK compose=0.14.30 cli=0.6.14 flat_release_assets=6 legacy_subdirectories=0\n'

#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

failure_count=0

require_marker() {
  local marker=$1
  local code=$2
  if ! grep -F -- "$marker" Dockerfile >/dev/null; then
    printf '%s marker=%s\n' "$code" "$marker"
    failure_count=$((failure_count + 1))
  fi
}

reject_marker() {
  local marker=$1
  local code=$2
  if grep -F -- "$marker" Dockerfile >/dev/null; then
    printf '%s marker=%s\n' "$code" "$marker"
    failure_count=$((failure_count + 1))
  fi
}

if ! bash -n scripts/bootstrap scripts/test; then
  echo 'SERVER_DEV_SCRIPT_SYNTAX_INVALID'
  failure_count=$((failure_count + 1))
fi

require_marker 'ARG SERVER_DEV_VERSION=v0.1.1' SERVER_DEV_VERSION_NOT_ROLLED_FORWARD
require_marker 'org.opencontainers.image.version="${SERVER_DEV_VERSION}"' SERVER_DEV_OCI_VERSION_LABEL_MISSING
require_marker 'ARG DOCKER_VERSION=29.5.3' SERVER_DEV_DOCKER_VERSION_NOT_UPDATED
require_marker 'ARG DOCKER_SHA256=34eea64e9c3435f5af1b760827a56a561cd67fc2d6e9cd1813b8bb1e3ff7930b' SERVER_DEV_DOCKER_SHA_MISSING
require_marker 'ARG COMPOSE_VERSION=v5.1.4' SERVER_DEV_COMPOSE_VERSION_NOT_PINNED
require_marker 'ARG COMPOSE_SHA256=33b208d7e76639db742fae84b966cc01dacae58ca3fc4dabbc907045aefdf0c4' SERVER_DEV_COMPOSE_SHA_MISSING
require_marker '-o "$docker_tgz" "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz"' SERVER_DEV_DOCKER_DOWNLOAD_NOT_FILE_BACKED
require_marker 'echo "${DOCKER_SHA256}  $docker_tgz" | sha256sum -c -' SERVER_DEV_DOCKER_SHA_NOT_CHECKED
require_marker 'tar xzf "$docker_tgz" -C /usr/bin --strip-components=1' SERVER_DEV_DOCKER_EXTRACT_NOT_FILE_BACKED
require_marker '-o "$compose_bin" "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64"' SERVER_DEV_COMPOSE_DOWNLOAD_NOT_FILE_BACKED
require_marker 'echo "${COMPOSE_SHA256}  $compose_bin" | sha256sum -c -' SERVER_DEV_COMPOSE_SHA_NOT_CHECKED
require_marker 'curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300' SERVER_DEV_DOWNLOADS_NOT_RETRIED
require_marker 'exec docker compose "$@"' SERVER_DEV_COMPOSE_WRAPPER_MISSING

reject_marker 'docker.io' SERVER_DEV_APT_DOCKER_IO_PRESENT
reject_marker 'docker-compose-v2' SERVER_DEV_APT_COMPOSE_PRESENT
reject_marker 'curl -sL ' SERVER_DEV_LEGACY_CURL_PRESENT
reject_marker 'curl -sfL ' SERVER_DEV_LEGACY_CURL_PRESENT
reject_marker 'curl -sLf ' SERVER_DEV_LEGACY_CURL_PRESENT

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

echo 'SERVER_DEV_DOCKERFILE_DOWNLOADS_OK version=v0.1.1 docker=29.5.3 compose=v5.1.4 sha=1 file_backed_downloads=1 retry=5'

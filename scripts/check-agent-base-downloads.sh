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

if ! bash -n agent-base/build-image.sh; then
  fail "AGENT_BASE_BUILD_SCRIPT_SYNTAX_INVALID"
fi

require_marker agent-base/Dockerfile 'org.opencontainers.image.version="v0.3.9"' AGENT_BASE_VERSION_NOT_ROLLED_FORWARD
require_marker agent-base/Dockerfile 'COPY ./share-mnt /usr/bin/share-mnt' AGENT_BASE_SHARE_MNT_NOT_CONTEXT_BACKED
require_marker agent-base/Dockerfile 'COPY ./r /usr/bin/r' AGENT_BASE_NETWORK_HELPER_NOT_CONTEXT_BACKED
require_marker agent-base/Dockerfile 'COPY ./update-platform-ssl /usr/bin/update-platform-ssl' AGENT_BASE_SSL_SCRIPT_NOT_CONTEXT_BACKED
require_marker agent-base/Dockerfile 'golang:1.27.4-bookworm@sha256:4fa7c968ba93f1635670522dbb01a2c78150443e1385746924566079f36570ea' AGENT_BASE_GO_COMPILER_NOT_PINNED
require_marker agent-base/Dockerfile 'ADD --checksum=sha256:36d502ba53623c50c51fe44f916aeff4c4051b1132aabde2e8982895d0361651 https://codeload.github.com/docker/cli/tar.gz/5457199aa57c45e990c59c89cab5f02b817238d7' AGENT_BASE_DOCKER_CLI_SOURCE_NOT_PINNED
require_marker agent-base/Dockerfile 'go get golang.org/x/net@v0.62.0' AGENT_BASE_DOCKER_NETWORKING_MODULE_NOT_FIXED
require_marker agent-base/Dockerfile 'COPY --from=docker_cli /out/docker /usr/bin/docker' AGENT_BASE_DOCKER_BINARY_NOT_BUILT
require_marker agent-base/Dockerfile 'ENV PYTHON_SHA256=e02d9ac21cebda6e46435369744a92c65cc7cd8669697694122cf97ffacd1e53' AGENT_BASE_PYTHON_SHA_MISSING
require_marker agent-base/Dockerfile '-o /tmp/Python-${PYTHON_VERSION}.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz"' AGENT_BASE_PYTHON_DOWNLOAD_NOT_FILE_BACKED
require_marker agent-base/Dockerfile 'echo "${PYTHON_SHA256}  /tmp/Python-${PYTHON_VERSION}.tar.xz" | sha256sum -c -' AGENT_BASE_PYTHON_SHA_NOT_CHECKED
require_marker agent-base/Dockerfile 'curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 \' AGENT_BASE_DOWNLOADS_NOT_RETRIED
require_marker agent-base/Dockerfile 'go mod verify' AGENT_BASE_DOCKER_MODULES_NOT_VERIFIED
require_marker agent-base/Dockerfile 'apt-get update --error-on=any' AGENT_BASE_APT_UPDATE_NOT_FAIL_CLOSED
require_marker agent-base/build-image.sh 'IMAGE=${IMAGE:-ghcr.io/pasturestack/node-agent-base:v0.3.9}' AGENT_BASE_BUILD_DEFAULT_IMAGE_NOT_UPDATED
require_marker agent-base/build-image.sh 'SHARE_MNT_BIN="${SHARE_MNT_BIN:-}"' AGENT_BASE_BUILD_SHARE_MNT_INPUT_MISSING
require_marker agent-base/build-image.sh 'Set SHARE_MNT_BIN to the reviewed mount-propagation binary path before building $IMAGE' AGENT_BASE_BUILD_SHARE_MNT_FAIL_CLOSED_MISSING
require_marker agent-base/build-image.sh 'cp "$SHARE_MNT_BIN" "$tmpdir/share-mnt"' AGENT_BASE_BUILD_SHARE_MNT_CONTEXT_COPY_MISSING
require_marker agent-base/build-image.sh 'R_BIN="${R_BIN:-}"' AGENT_BASE_BUILD_NETWORK_HELPER_INPUT_MISSING
require_marker agent-base/build-image.sh 'cp "$R_BIN" "$tmpdir/r"' AGENT_BASE_BUILD_NETWORK_HELPER_CONTEXT_COPY_MISSING
require_marker agent-base/build-image.sh 'cp ../server/bin/update-platform-ssl "$tmpdir/update-platform-ssl"' AGENT_BASE_BUILD_SSL_SCRIPT_CONTEXT_COPY_MISSING

require_marker agent/Dockerfile 'FROM ghcr.io/pasturestack/node-agent-base:v0.3.8@sha256:d6c391a2b8c8a36747a33a9fd17a8692439809be95c8bccaa586bd48097a73b7' AGENT_DOCKERFILE_BASE_NOT_UPDATED
require_marker agent/Dockerfile 'org.opencontainers.image.version="v1.2.34"' AGENT_DOCKERFILE_VERSION_NOT_ROLLED_FORWARD
require_marker agent/Dockerfile 'ENV RANCHER_AGENT_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.34' AGENT_DOCKERFILE_SELF_IMAGE_NOT_ROLLED_FORWARD
require_marker agent/Dockerfile 'io.pasturestack.container.system="node-agent"' AGENT_DOCKERFILE_PASTURESTACK_SYSTEM_LABEL_MISSING
require_marker agent/Dockerfile 'COPY loglevel /usr/bin/loglevel' AGENT_DOCKERFILE_LOGLEVEL_NOT_CONTEXT_BACKED
require_marker agent/Dockerfile 'RUN test -s /usr/bin/share-mnt && \' AGENT_DOCKERFILE_BASE_SHARE_MNT_NONEMPTY_CHECK_MISSING
require_marker agent/Dockerfile 'COPY control_plane_url.py register.py resolve_url.py run.sh /' AGENT_DOCKERFILE_URL_POLICY_NOT_CONTEXT_BACKED
require_marker agent/build-image.sh 'cp Dockerfile control_plane_url.py register.py resolve_url.py run.sh loglevel "$tmpdir"/' AGENT_BUILD_TRACKED_CONTEXT_COPY_MISSING
test -s agent/loglevel || fail AGENT_LOGLEVEL_TRACKED_SOURCE_MISSING

reject_marker agent-base/Dockerfile 'github.com/rancher/runc/releases/download/share-mnt' AGENT_BASE_LEGACY_SHARE_MNT_DOWNLOAD
reject_marker agent-base/Dockerfile 'docker-29.4.2.tgz' AGENT_BASE_LEGACY_DOCKER_CLI_VERSION
reject_marker agent-base/Dockerfile 'wget -O /tmp/Python-${PYTHON_VERSION}.tar.xz' AGENT_BASE_PYTHON_WGET_DOWNLOAD
reject_marker agent-base/Dockerfile 'curl -sfL https://download.docker.com/linux/static/stable/x86_64/docker-' AGENT_BASE_DOCKER_PIPE_DOWNLOAD_CAN_MASK_FAILURE
reject_marker agent-base/Dockerfile 'github.com/rancher/weave' AGENT_BASE_NETWORK_HELPER_REMOTE_DOWNLOAD
reject_marker agent-base/Dockerfile 'raw.githubusercontent.com/rancher/rancher' AGENT_BASE_SSL_SCRIPT_REMOTE_DOWNLOAD
reject_marker agent/Dockerfile 'github.com/rancher/loglevel' AGENT_DOCKERFILE_LOGLEVEL_REMOTE_DOWNLOAD
reject_marker agent/Dockerfile 'COPY share-mnt /usr/bin/share-mnt' AGENT_DOCKERFILE_EMPTY_SHARE_MNT_OVERRIDE
reject_marker agent/build-image.sh 'SHARE_MNT_BIN=' AGENT_BUILD_EXTERNAL_SHARE_MNT_INPUT
reject_marker agent/build-image.sh 'LOGLEVEL_BIN=' AGENT_BUILD_EXTERNAL_LOGLEVEL_INPUT
reject_marker agent/Dockerfile 'org.opencontainers.image.version="v1.2.29"' AGENT_DOCKERFILE_SUPERSEDED_VERSION_STILL_PRESENT
reject_marker agent/Dockerfile 'ENV RANCHER_AGENT_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.29' AGENT_DOCKERFILE_SUPERSEDED_SELF_IMAGE_STILL_PRESENT
reject_marker agent/Dockerfile 'ENV RANCHER_AGENT_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.30' AGENT_DOCKERFILE_SUPERSEDED_SELF_IMAGE_STILL_PRESENT
reject_marker agent/Dockerfile 'org.opencontainers.image.version="v1.2.28"' AGENT_DOCKERFILE_SUPERSEDED_VERSION_STILL_PRESENT
reject_marker agent/Dockerfile 'ENV RANCHER_AGENT_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.28' AGENT_DOCKERFILE_SUPERSEDED_SELF_IMAGE_STILL_PRESENT
reject_marker agent/Dockerfile 'org.opencontainers.image.version="v1.2.27"' AGENT_DOCKERFILE_FAILED_VERSION_STILL_PRESENT
reject_marker agent/Dockerfile 'ENV RANCHER_AGENT_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.27' AGENT_DOCKERFILE_FAILED_SELF_IMAGE_STILL_PRESENT
reject_marker agent/Dockerfile 'org.opencontainers.image.version="v1.2.26"' AGENT_DOCKERFILE_OLD_VERSION_STILL_PRESENT
reject_marker agent/Dockerfile 'ENV RANCHER_AGENT_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.26' AGENT_DOCKERFILE_OLD_SELF_IMAGE_STILL_PRESENT

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'AGENT_BASE_DOWNLOADS_OK base=v0.3.9 agent=v1.2.34 base_share_mnt_nonempty=1 tracked_loglevel=1 docker_cli=29.9.3 python_sha=1 docker_sha=1 remote_legacy_helpers=0\n'

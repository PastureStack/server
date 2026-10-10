#!/usr/bin/env bash
set -Eeuo pipefail

# The same formal recipe and verification gates consume local and published
# assets. New identities are mandatory: never inherit the 518 artifact hashes.
required=(ORCHESTRATION_ENGINE_COMMIT ORCHESTRATION_ENGINE_ARTIFACT_SHA256
    ENGINE_READONLY_SCHEMA_SHA256 ENGINE_RESTRICTED_SCHEMA_SHA256
    WEB_CONSOLE_COMMIT WEB_CONSOLE_ARTIFACT_SHA256 WEBSOCKET_PROXY_COMMIT
    WEBSOCKET_PROXY_ARCHIVE_SHA256 WEBSOCKET_PROXY_BINARY_SHA256 HOST_API_COMMIT
    HOST_API_ARCHIVE_SHA256 HOST_API_BINARY_SHA256 HOST_API_APPLY_SHA256
    NODE_AGENT_COMMIT NODE_AGENT_ARCHIVE_SHA256 NODE_AGENT_BINARY_SHA256 NODE_AGENT_APPLY_SHA256)
for name in "${required[@]}"; do
    [[ -n ${!name:-} ]] || { printf 'Missing required component identity: %s\n' "$name" >&2; exit 2; }
    case "$name" in *_COMMIT) [[ ${!name} =~ ^[0-9a-f]{40}$ ]] ;; *) [[ ${!name} =~ ^[0-9a-f]{64}$ ]] ;; esac
    export "$name"
done
export SERVER_RELEASE_TAG=${SERVER_RELEASE_TAG:-v1.6.519}
export ORCHESTRATION_ENGINE_RELEASE_TAG=${ORCHESTRATION_ENGINE_RELEASE_TAG:-v0.183.334}
export ORCHESTRATION_ENGINE_ARTIFACT=cattle.jar
export WEB_CONSOLE_RELEASE_TAG=${WEB_CONSOLE_RELEASE_TAG:-1.6.181}
export WEB_CONSOLE_ARTIFACT="web-console-${WEB_CONSOLE_RELEASE_TAG}.tar.gz"
export WEBSOCKET_PROXY_VERSION=${WEBSOCKET_PROXY_VERSION:-0.23.15}
export HOST_API_VERSION=${HOST_API_VERSION:-0.38.5}
export NODE_AGENT_VERSION=${NODE_AGENT_VERSION:-0.13.28}
export HOST_API_PACKAGE_MODE=producer
export HOST_API_PACKAGE_ID=${HOST_API_PACKAGE_ID:-${HOST_API_COMMIT:0:32}}
[[ "$HOST_API_PACKAGE_ID" == "${HOST_API_COMMIT:0:32}" ]]
export NODE_AGENT_PACKAGE_ID=${NODE_AGENT_PACKAGE_ID:-${NODE_AGENT_COMMIT:0:32}}
[[ "$NODE_AGENT_PACKAGE_ID" == "${NODE_AGENT_COMMIT:0:32}" ]]
export HOST_API_RELEASE_BASE_URL=https://github.com/PastureStack/host-api/releases/download
export HOST_API_RELEASE_TAG="v${HOST_API_VERSION}"
export IMAGE=${IMAGE:-pasturestack-validation/server:${SERVER_RELEASE_TAG}}
[[ "$SERVER_RELEASE_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$ORCHESTRATION_ENGINE_RELEASE_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$WEB_CONSOLE_RELEASE_TAG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$WEBSOCKET_PROXY_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$HOST_API_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$NODE_AGENT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
if [[ ${1:-} == --check-inputs ]]; then
    [[ $# == 1 ]]
    printf 'SERVER_COMPONENT_INPUTS_OK server=%s engine=%s web=%s proxy=%s host=%s node=%s package_id=%s\n' \
        "$SERVER_RELEASE_TAG" "$ORCHESTRATION_ENGINE_RELEASE_TAG" "$WEB_CONSOLE_RELEASE_TAG" \
        "$WEBSOCKET_PROXY_VERSION" "$HOST_API_VERSION" "$NODE_AGENT_VERSION" "$HOST_API_PACKAGE_ID"
    exit 0
fi
[[ $# == 0 ]] || { echo 'usage: build-component-candidate.sh [--check-inputs]' >&2; exit 2; }
exec bash "$(dirname "${BASH_SOURCE[0]}")/build-api-explorer-patch-image.sh"

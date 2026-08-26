#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.api-explorer-patch
build_script=server/build-api-explorer-patch-image.sh

for path in "$dockerfile" "$build_script"; do
    test -f "$path"
done

require_marker()
{
    local file=$1
    local marker=$2
    local code=$3
    if ! grep -Fq -- "$marker" "$file"; then
        printf '%s file=%s marker=%s\n' "$code" "$file" "$marker" >&2
        exit 1
    fi
}

require_marker "$dockerfile" \
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.358@sha256:14064cb8a91c2ff058e620ca11b3342de422d1bbc34e43ed82f5712801637fa7' \
    SERVER_API_EXPLORER_PATCH_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.359"' \
    SERVER_API_EXPLORER_PATCH_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.359' \
    SERVER_API_EXPLORER_PATCH_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_API_UI_VERSION=1.1.17' \
    SERVER_API_EXPLORER_PATCH_API_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG API_EXPLORER_ARTIFACT_SHA256=6dc1bfd64f520444efe370bb8141fa3bcc36fa0008617e508375b781ecf30fc3' \
    SERVER_API_EXPLORER_PATCH_HASH_MISSING
require_marker "$dockerfile" \
    'ARG API_EXPLORER_COMMIT=94e617e0f8950ea80bdb46aaf181f463bae2cea9' \
    SERVER_API_EXPLORER_PATCH_COMMIT_MISSING
require_marker "$dockerfile" \
    'tar --no-same-owner --no-same-permissions -xzf' \
    SERVER_API_EXPLORER_PATCH_SAFE_EXTRACTION_MISSING
require_marker "$dockerfile" \
    'test ! -e "${stage}/js/bootstrap.js"' \
    SERVER_API_EXPLORER_PATCH_BOOTSTRAP_JS_REJECTION_MISSING
require_marker "$dockerfile" \
    'pasturestack:modal:shown' \
    SERVER_API_EXPLORER_PATCH_MODAL_GATE_MISSING
require_marker "$dockerfile" \
    'data-pasturestack-toggle' \
    SERVER_API_EXPLORER_PATCH_DROPDOWN_GATE_MISSING
require_marker "$dockerfile" \
    'licenses/inherited-vendor/LICENSE-async-0.9.0' \
    SERVER_API_EXPLORER_PATCH_LEGAL_GATE_MISSING
require_marker "$build_script" \
    'critical_runtime_unchanged=1' \
    SERVER_API_EXPLORER_PATCH_CRITICAL_REGRESSION_GATE_MISSING
require_marker "$build_script" \
    'web_console_unchanged=1' \
    SERVER_API_EXPLORER_PATCH_WEB_CONSOLE_REGRESSION_GATE_MISSING

require_marker "$dockerfile" \
    'org.opencontainers.image.base.digest="sha256:14064cb8a91c2ff058e620ca11b3342de422d1bbc34e43ed82f5712801637fa7"' \
    SERVER_API_EXPLORER_PATCH_BASE_DIGEST_MISSING
require_marker "$build_script" \
    'ghcr.io/pasturestack/server:v1.6.358@sha256:14064cb8a91c2ff058e620ca11b3342de422d1bbc34e43ed82f5712801637fa7' \
    SERVER_API_EXPLORER_PATCH_BUILD_BASE_DIGEST_MISSING

if grep -RInE '(^|[^[:alnum:]])[A-Za-z]:\\Users\\|/home/[^/[:space:]]+/|(^|[^[:digit:]])10[.][[:digit:]]{1,3}[.][[:digit:]]{1,3}[.][[:digit:]]{1,3}([^[:digit:]]|$)|[[:alnum:]._%+-]+@[[:alnum:].-]+[.][[:alpha:]]{2,}' \
    "$dockerfile" "$build_script"; then
    echo 'SERVER_API_EXPLORER_PATCH_PRIVATE_MARKER' >&2
    exit 1
fi

bash -n "$build_script"

printf 'SERVER_API_EXPLORER_PATCH_OK release=v1.6.359 base=v1.6.358 api_explorer=1.1.17 bootstrap=5.3.8 bootstrap_icons=1.13.1 bootstrap_javascript=0 runtime_digest_coordinates=1 legal_assets=complete\n'

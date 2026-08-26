#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.api-explorer-patch
build_script=server/build-api-explorer-patch-image.sh
publish_workflow=.github/workflows/publish-current-server.yml
cattle_script=server/artifacts/cattle.sh

for path in "$dockerfile" "$build_script" "$publish_workflow" "$cattle_script"; do
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
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.364@sha256:98ace6dd822f883f2f161f8e7c3191d45cc1f1aef6d2cb6de281cfb1d93237e5' \
    SERVER_API_EXPLORER_PATCH_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'ARG UBUNTU_SNAPSHOT=20260826T000000Z' \
    SERVER_API_EXPLORER_PATCH_UBUNTU_SNAPSHOT_NOT_CURRENT
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.365"' \
    SERVER_API_EXPLORER_PATCH_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.365' \
    SERVER_API_EXPLORER_PATCH_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE=ghcr.io/pasturestack/load-balancer-service:v0.9.27' \
    SERVER_API_EXPLORER_PATCH_LB_IMAGE_MISSING
require_marker "$dockerfile" \
    'ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE_UUID=docker:ghcr.io/pasturestack/load-balancer-service:v0.9.27' \
    SERVER_API_EXPLORER_PATCH_LB_IMAGE_UUID_MISSING
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
    'ARG GO_BUILDER_IMAGE=golang:1.27.0-bookworm@sha256:ded31c68586d2e49e760acc2e65a884b23d032e9bbbed0ae0c55abd3fcaf4452' \
    SERVER_RUNTIME_GO_BUILDER_NOT_CURRENT
require_marker "$dockerfile" \
    'ENV PASTURESTACK_RUNTIME_GO_VERSION=1.27.0' \
    SERVER_RUNTIME_GO_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_UBUNTU_SECURITY_REFRESH=2026-08-26' \
    SERVER_UBUNTU_SECURITY_REFRESH_MISSING
require_marker "$dockerfile" \
    'coreutils-from-gnu coreutils-from-uutils- rust-coreutils-' \
    SERVER_GNU_COREUTILS_SWITCH_MISSING
require_marker "$dockerfile" \
    '! dpkg-query -W rust-coreutils' \
    SERVER_RUST_COREUTILS_ABSENCE_GATE_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_COREUTILS_PROVIDER=gnu' \
    SERVER_COREUTILS_PROVIDER_IDENTITY_MISSING
require_marker "$dockerfile" \
    'ARG COREUTILS_SHA256=394024eda0a5955217ceda9cd1201e65dc8fa3aa29c2951135a49521d57c3cc3' \
    SERVER_COREUTILS_SOURCE_HASH_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_COREUTILS_UNIQ_VERSION=9.11' \
    SERVER_COREUTILS_UNIQ_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG ZLIB_SHA256=bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16' \
    SERVER_ZLIB_SOURCE_HASH_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_ZLIB_VERSION=1.3.2' \
    SERVER_ZLIB_VERSION_MISSING
require_marker "$dockerfile" \
    'version_at_least openssl 3.5.5-1ubuntu3.4' \
    SERVER_OPENSSL_FIXED_VERSION_GATE_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_SSH_CLIENT_HARDENING=client-removed' \
    SERVER_SSH_CLIENT_REMOVAL_IDENTITY_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_PRIVILEGED_MOUNT_HELPERS=removed' \
    SERVER_MOUNT_HELPER_REMOVAL_IDENTITY_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_CONTAINER_SOURCE_BUILD_MODE=removed' \
    SERVER_SOURCE_BUILD_MODE_REMOVAL_IDENTITY_MISSING
require_marker "$dockerfile" \
    '/usr/lib/systemd/systemd-journald' \
    SERVER_JOURNALD_REMOVAL_GATE_MISSING
require_marker "$dockerfile" \
    '/usr/share/cattle/install_cattle_binaries' \
    SERVER_RUNTIME_INSTALLER_REMOVAL_GATE_MISSING
require_marker "$cattle_script" \
    'CATTLE_MASTER source-build mode has been removed' \
    SERVER_SOURCE_BUILD_MODE_REJECTION_MISSING
if grep -Eq '(^|[[:space:]])(git clone|git -C|apt-get install|tar xzf)([[:space:]]|$)' "$cattle_script"; then
    echo 'SERVER_SOURCE_BUILD_TOOLING_REMAINS' >&2
    exit 1
fi
while IFS='|' read -r marker code; do
    require_marker "$dockerfile" "$marker" "$code"
done <<'EOF'
ARG AUTHENTICATION_SERVICE_VERSION=0.4.36|SERVER_AUTHENTICATION_SERVICE_VERSION_MISSING
ARG AUTHENTICATION_SERVICE_BINARY_SHA256=33c59675901c459feb478e55f731420bd2f5f3c3f27e0f6c7b4659207d025d7b|SERVER_AUTHENTICATION_SERVICE_HASH_MISSING
ARG CATALOG_SERVICE_VERSION=0.20.11|SERVER_CATALOG_SERVICE_VERSION_MISSING
ARG CATALOG_SERVICE_BINARY_SHA256=ccfc75831678df31f58b327b3177da6f40d31603ab329af7bdf700a8513ea329|SERVER_CATALOG_SERVICE_HASH_MISSING
ARG COMPOSE_EXECUTOR_VERSION=0.14.34|SERVER_COMPOSE_EXECUTOR_VERSION_MISSING
ARG COMPOSE_EXECUTOR_BINARY_SHA256=e429714b321db8c1a47c727bb241b3de41b74facdfb61af144237d46f3f2c47b|SERVER_COMPOSE_EXECUTOR_HASH_MISSING
ARG HOST_PROVISIONER_VERSION=0.39.6|SERVER_HOST_PROVISIONER_VERSION_MISSING
ARG HOST_PROVISIONER_BINARY_SHA256=1d06bde76920e9738da0365e9fd0ef1eac3a414785bede06b8d8665bf25a2710|SERVER_HOST_PROVISIONER_HASH_MISSING
ARG SECRET_DELIVERY_API_VERSION=0.3.1|SERVER_SECRET_DELIVERY_API_VERSION_MISSING
ARG SECRET_DELIVERY_API_BINARY_SHA256=fbdd12862e1cfe3c957f492ae81c4c1c5658357502bd322febbbe209496929be|SERVER_SECRET_DELIVERY_API_HASH_MISSING
ARG USAGE_TELEMETRY_AGENT_VERSION=0.4.1|SERVER_USAGE_TELEMETRY_AGENT_VERSION_MISSING
ARG USAGE_TELEMETRY_AGENT_BINARY_SHA256=f18ed969b8b5959293fdbcd55d2e28846372ab87c9348fbb315a9a490bf85ad4|SERVER_USAGE_TELEMETRY_AGENT_HASH_MISSING
ARG WEBHOOK_AUTOMATION_SERVICE_VERSION=0.10.1|SERVER_WEBHOOK_AUTOMATION_SERVICE_VERSION_MISSING
ARG WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256=07e807c3f66e7e75e7a45073eabbd041a74b5727e315aee96f00e5b6a801ccc5|SERVER_WEBHOOK_AUTOMATION_SERVICE_HASH_MISSING
ARG WEBSOCKET_PROXY_VERSION=0.23.13|SERVER_WEBSOCKET_PROXY_VERSION_MISSING
ARG WEBSOCKET_PROXY_BINARY_SHA256=8e24dc052faf54603c95d9187ca63b25435482ad9046825d3676ae522439c949|SERVER_WEBSOCKET_PROXY_HASH_MISSING
ARG VSPHERE_CLI_BUNDLE_VERSION=0.55.1-pasturestack.2|SERVER_VSPHERE_CLI_BUNDLE_VERSION_MISSING
ARG GOVC_BINARY_SHA256=a42b0649c723b76a2208467c821ff1a9b713b2c8c5ab762808c1d193bd112287|SERVER_GOVC_HASH_MISSING
EOF
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
    'runtime_go=1.27.0' \
    SERVER_RUNTIME_GO_GATE_MISSING
require_marker "$build_script" \
    'orchestration_unchanged=1' \
    SERVER_ORCHESTRATION_REGRESSION_GATE_MISSING
require_marker "$build_script" \
    'wrappers_unchanged=1' \
    SERVER_WRAPPER_REGRESSION_GATE_MISSING
require_marker "$build_script" \
    'web_console_unchanged=1' \
    SERVER_API_EXPLORER_PATCH_WEB_CONSOLE_REGRESSION_GATE_MISSING

require_marker "$dockerfile" \
    'org.opencontainers.image.base.digest="sha256:98ace6dd822f883f2f161f8e7c3191d45cc1f1aef6d2cb6de281cfb1d93237e5"' \
    SERVER_API_EXPLORER_PATCH_BASE_DIGEST_MISSING
require_marker "$build_script" \
    'ghcr.io/pasturestack/server:v1.6.364@sha256:98ace6dd822f883f2f161f8e7c3191d45cc1f1aef6d2cb6de281cfb1d93237e5' \
    SERVER_API_EXPLORER_PATCH_BUILD_BASE_DIGEST_MISSING

if grep -RInE '(^|[^[:alnum:]])[A-Za-z]:\\Users\\|/home/[^/[:space:]]+/|(^|[^[:digit:]])10[.][[:digit:]]{1,3}[.][[:digit:]]{1,3}[.][[:digit:]]{1,3}([^[:digit:]]|$)|[[:alnum:]._%+-]+@[[:alnum:].-]+[.][[:alpha:]]{2,}' \
    "$dockerfile" "$build_script"; then
    echo 'SERVER_API_EXPLORER_PATCH_PRIVATE_MARKER' >&2
    exit 1
fi

bash -n "$build_script"

for marker in \
    'release_tag:' \
    '.features["containerd-snapshotter"] = true' \
    "grep -F 'io.containerd.snapshotter.v1'" \
    'PASTURESTACK_BUILD_NO_CACHE=1 IMAGE="$CANDIDATE_IMAGE"' \
    'docker restart "$CANDIDATE_NAME"' \
    'ghcr.io/aquasecurity/trivy:0.74.0@sha256:62b1e65e8869bc4b4c6aa4fa2b21595256c7c2f6018a9d9ad61caf87187c1969' \
    'server-critical-high.tsv' \
    'server-secrets.tsv' \
    'server.cdx.json' \
    'test -s "$release_notes"' \
    'actions/attest@1e69f48acb82d1966a394da916b4c1698aa569d6 # v4.2.2' \
    'gh release create "$RELEASE_TAG"'; do
    require_marker "$publish_workflow" "$marker" \
        SERVER_CURRENT_PUBLISH_WORKFLOW_GATE_MISSING
done

printf 'SERVER_API_EXPLORER_PATCH_OK release=v1.6.365 base=v1.6.364 api_explorer=1.1.17 bootstrap=5.3.8 bootstrap_icons=1.13.1 bootstrap_javascript=0 runtime_go=1.27.0 ubuntu_security_refresh=2026-08-26 coreutils_uniq=9.11 zlib=1.3.2 source_build_mode=removed runtime_tar=removed ssh_client=removed mount_helpers=removed runtime_digest_coordinates=1 legal_assets=complete\n'

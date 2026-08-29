#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.api-explorer-patch
build_script=server/build-api-explorer-patch-image.sh
publish_workflow=.github/workflows/publish-current-server.yml
cattle_script=server/artifacts/cattle.sh
coreutils_patch=server/patches/coreutils-CVE-2026-56391.patch
runtime_vex=server/security/openvex.json
release_notes=docs/releases/server-1.6.373.md

for path in "$dockerfile" "$build_script" "$publish_workflow" "$cattle_script" \
    "$coreutils_patch" "$runtime_vex" "$release_notes"; do
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
    'org.opencontainers.image.version="v1.6.376"' \
    SERVER_API_EXPLORER_PATCH_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.376' \
    SERVER_API_EXPLORER_PATCH_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG SUPPORTED_DOCKER_RANGE="~v1.12.3 || ~v1.13.0 || ~v17.03.0 || ~v17.06.0 || ~v17.09.0 || ~v17.12.0 || ~v18.03.0 || ~v18.06.0 || ~v18.09.0 || ~v19.03.2 || v24.0.9 || >=v29.4.1 <=v29.7.2"' \
    SERVER_DOCKER_29_COMPATIBILITY_RANGE_MISSING
require_marker "$dockerfile" \
    'jar --update --file "${app_config_jar}" --date="${source_date_iso}"' \
    SERVER_DOCKER_SUPPORT_RUNTIME_PATCH_MISSING
require_marker "$build_script" \
    'docker_29_range=29.4.1..29.7.2 docker_29_6_2=supported' \
    SERVER_DOCKER_SUPPORT_IMAGE_GATE_MISSING
require_marker "$dockerfile" \
    'ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE=ghcr.io/pasturestack/load-balancer-service:v0.9.27' \
    SERVER_API_EXPLORER_PATCH_LB_IMAGE_MISSING
require_marker "$dockerfile" \
    'ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE_UUID=docker:ghcr.io/pasturestack/load-balancer-service:v0.9.27' \
    SERVER_API_EXPLORER_PATCH_LB_IMAGE_UUID_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_API_UI_VERSION=1.1.18' \
    SERVER_API_EXPLORER_PATCH_API_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG API_EXPLORER_ARTIFACT_SHA256=92b718c46163018ea40c008ac552911f0eb610647377725405f4046dcd411f2c' \
    SERVER_API_EXPLORER_PATCH_HASH_MISSING
require_marker "$dockerfile" \
    'ARG API_EXPLORER_COMMIT=3b1c39e8a116f58649d94233a384a0362c02b43e' \
    SERVER_API_EXPLORER_PATCH_COMMIT_MISSING
require_marker "$dockerfile" \
    'ARG ORCHESTRATION_ENGINE_RELEASE_TAG=v0.183.286' \
    SERVER_ORCHESTRATION_RELEASE_TAG_MISSING
require_marker "$dockerfile" \
    'ARG ORCHESTRATION_ENGINE_ARTIFACT=orchestration-engine-0.183.286.jar' \
    SERVER_ORCHESTRATION_RELEASE_ARTIFACT_MISSING
require_marker "$dockerfile" \
    'ARG ORCHESTRATION_ENGINE_ARTIFACT_SHA256=1506ad37153bede468ad2ff1b87caf8dd448a13c45a31c851dc7acce73a86484' \
    SERVER_ORCHESTRATION_RELEASE_HASH_MISSING
require_marker "$dockerfile" \
    'ARG ORCHESTRATION_ENGINE_COMMIT=f0b9e8a10e20527f2f6a9b9b0179a3cfc752cbc6' \
    SERVER_ORCHESTRATION_RELEASE_COMMIT_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_CATTLE_VERSION=v0.183.286' \
    SERVER_ORCHESTRATION_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'grep -Fx '\''Implementation-Version: 0.183.286'\'' >/dev/null' \
    SERVER_ORCHESTRATION_MANIFEST_GATE_MISSING
require_marker "$dockerfile" \
    'WEB-INF/lib/hazelcast-5\.7\.3-pasturestack\.4\.jar' \
    SERVER_DISTRIBUTED_CACHE_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    '9fa751998ce3cc1f17692e21933b24646c39a7142ca387af772e43f49dc77764  /tmp/hazelcast.jar' \
    SERVER_DISTRIBUTED_CACHE_RUNTIME_HASH_GATE_MISSING
require_marker "$build_script" \
    'image_orchestration' \
    SERVER_ORCHESTRATION_IMAGE_HASH_GATE_MISSING
require_marker "$dockerfile" \
    'COPY patches/db/core-124.xml /tmp/pasturestack-server-overlays/db/core-124.xml' \
    SERVER_CATALOG_PINNED_COMMIT_OVERLAY_MISSING
require_marker "$dockerfile" \
    'java -cp ".:${new_web_root}/WEB-INF/lib/*" PatchV1GlobalSubscribe verify' \
    SERVER_GLOBAL_SUBSCRIBE_SCHEMA_OVERLAY_MISSING
require_marker "$dockerfile" \
    'test "$(readlink -f /usr/share/cattle/war)" = "${new_web_root}"' \
    SERVER_ORCHESTRATION_EXPLODED_ROOT_BINDING_MISSING
require_marker "$dockerfile" \
    'web_console_stage=/tmp/pasturestack-web-console' \
    SERVER_WEB_CONSOLE_PRESERVATION_STAGE_MISSING
require_marker "$dockerfile" \
    'cp -a "${old_web_root}/${static_path}" "${web_console_stage}/${static_path}"' \
    SERVER_WEB_CONSOLE_PRESERVATION_COPY_MISSING
require_marker "$dockerfile" \
    'test -z "$(find "${web_console_stage}" -type l -print -quit)"' \
    SERVER_WEB_CONSOLE_PRESERVATION_SYMLINK_GATE_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_RELEASE_TAG=1.6.79' \
    SERVER_WEB_CONSOLE_RELEASE_TAG_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_ARTIFACT=web-console-1.6.79.tar.gz' \
    SERVER_WEB_CONSOLE_RELEASE_ARTIFACT_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_ARTIFACT_SHA256=ff2ff9d9e48a699ccf7bec003886880c062a916ace2492006372ce35de29f19d' \
    SERVER_WEB_CONSOLE_RELEASE_HASH_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_COMMIT=43f1f1f30025f65db8acfa0d0a2b527da148ecd8' \
    SERVER_WEB_CONSOLE_RELEASE_COMMIT_MISSING
require_marker "$dockerfile" \
    'tar --no-same-owner --no-same-permissions -xzf "${archive}" -C "${stage}"' \
    SERVER_WEB_CONSOLE_SAFE_EXTRACTION_MISSING
require_marker "$dockerfile" \
    'grep -aF "${marker}" "${ui_entry}"' \
    SERVER_WEB_CONSOLE_AUDIT_FILTER_MARKER_GATE_MISSING
require_marker "$dockerfile" \
    'ui/utils/bootstrap-runtime' \
    SERVER_WEB_CONSOLE_BOOTSTRAP_MODULE_GATE_MISSING
require_marker "$dockerfile" \
    'window.bootstrap=' \
    SERVER_WEB_CONSOLE_BOOTSTRAP_GLOBAL_GATE_MISSING
require_marker "$dockerfile" \
    'ember-basic-dropdown-wormhole' \
    SERVER_WEB_CONSOLE_DROPDOWN_DESTINATION_GATE_MISSING
require_marker "$dockerfile" \
    'basic-dropdown-wormhole' \
    SERVER_WEB_CONSOLE_DROPDOWN_COMPONENT_GATE_MISSING
require_marker "$dockerfile" \
    "grep -F '篩選稽核日誌'" \
    SERVER_WEB_CONSOLE_ZH_TW_FILTER_GATE_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=${WEB_CONSOLE_RELEASE_TAG}' \
    SERVER_WEB_CONSOLE_RUNTIME_VERSION_MISSING
require_marker "$build_script" \
    'PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256="${web_console_artifact_sha256}"' \
    SERVER_WEB_CONSOLE_RUNTIME_HASH_GATE_MISSING
require_marker "$build_script" \
    'test "$(cat "${web_root}/VERSION.txt")" = "1.6.79"' \
    SERVER_WEB_CONSOLE_RUNTIME_VERSION_GATE_MISSING
require_marker "$build_script" \
    'grep -aF "ui/utils/bootstrap-runtime" "${ui_entry}"' \
    SERVER_WEB_CONSOLE_RUNTIME_MODULE_GATE_MISSING
require_marker "$build_script" \
    'grep -aF "window.bootstrap=" "${ui_entry}"' \
    SERVER_WEB_CONSOLE_RUNTIME_GLOBAL_GATE_MISSING
if grep -F 'grep -aF "bs.collapse"' "$build_script" >/dev/null; then
    echo SERVER_WEB_CONSOLE_DORMANT_VENDOR_RUNTIME_GATE_PRESENT
    exit 1
fi
require_marker "$build_script" \
    'grep -F "pasturestack-catalog-pinned-commit"' \
    SERVER_CATALOG_PINNED_COMMIT_IMAGE_GATE_MISSING
require_marker "$dockerfile" \
    'COPY --chmod=0755 patches/websocket-proxy-wrapper.sh /usr/bin/websocket-proxy' \
    SERVER_WEBSOCKET_PROXY_ROUTING_WRAPPER_INSTALL_MISSING
require_marker "$build_script" \
    'websocket_wrapper_sha256=$(sha256sum server/patches/websocket-proxy-wrapper.sh' \
    SERVER_WEBSOCKET_PROXY_ROUTING_WRAPPER_HASH_GATE_MISSING
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
    'ARG COREUTILS_SHA256=2033b8a3049c06bff49a9e3cea72bdf4683bcd0cbeb975211dd56dbaf8b736ae' \
    SERVER_COREUTILS_SOURCE_HASH_MISSING
require_marker "$dockerfile" \
    'https://ftp.gnu.org/gnu/coreutils/coreutils-${COREUTILS_VERSION}.tar.gz' \
    SERVER_COREUTILS_PRIMARY_SOURCE_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_COREUTILS_UNIQ_VERSION=9.11' \
    SERVER_COREUTILS_UNIQ_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG COREUTILS_UNIQ_FIX_COMMIT=d64e35a8a4c0e4608321433e0d84d917e4e36371' \
    SERVER_COREUTILS_UNIQ_FIX_COMMIT_MISSING
require_marker "$dockerfile" \
    'ARG COREUTILS_UNIQ_PATCH_SHA256=7c0a1b74325caf05fe0021b26dcde6b19560ea04388f18386cacc4e8bb436efd' \
    SERVER_COREUTILS_UNIQ_FIX_HASH_MISSING
require_marker "$dockerfile" \
    'git apply --check --no-index /src/coreutils-CVE-2026-56391.patch' \
    SERVER_COREUTILS_UNIQ_FIX_APPLICATION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_COREUTILS_UNIQ_FIX=d64e35a8a4c0e4608321433e0d84d917e4e36371' \
    SERVER_COREUTILS_UNIQ_FIX_IDENTITY_MISSING
test "$(sha256sum "$coreutils_patch" | awk '{print $1}')" = \
    7c0a1b74325caf05fe0021b26dcde6b19560ea04388f18386cacc4e8bb436efd
require_marker "$coreutils_patch" \
    'Upstream-Commit: d64e35a8a4c0e4608321433e0d84d917e4e36371' \
    SERVER_COREUTILS_UNIQ_PATCH_PROVENANCE_MISSING
require_marker "$release_notes" \
    'd64e35a8a4c0e4608321433e0d84d917e4e36371' \
    SERVER_RELEASE_NOTES_UNIQ_FIX_MISSING
require_marker "$release_notes" \
    'unmatched vulnerability at any severity remains a release blocker.' \
    SERVER_RELEASE_NOTES_VEX_BOUNDARY_MISSING
require_marker "$release_notes" \
    'CVE-2026-75803' \
    SERVER_RELEASE_NOTES_OPENSSL_FIX_MISSING
require_marker "$release_notes" \
    'CVE-2026-53910' \
    SERVER_RELEASE_NOTES_DIFF3_CLOSURE_MISSING
require_marker "$dockerfile" \
    'ARG ZLIB_SHA256=bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16' \
    SERVER_ZLIB_SOURCE_HASH_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_ZLIB_VERSION=1.3.2' \
    SERVER_ZLIB_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG OPENSSL_VERSION=3.5.8' \
    SERVER_OPENSSL_SOURCE_VERSION_MISSING
require_marker "$dockerfile" \
    'ARG OPENSSL_SHA256=a8f84a39918ec6415ce765d9b429d313ba97b8143169c172e734b9514464f5b2' \
    SERVER_OPENSSL_SOURCE_HASH_MISSING
require_marker "$dockerfile" \
    'make test TESTS=test_evp_extra' \
    SERVER_OPENSSL_TARGETED_TEST_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_OPENSSL_VERSION=3.5.8' \
    SERVER_OPENSSL_RUNTIME_IDENTITY_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_DIFF3_HARDENING=removed' \
    SERVER_DIFF3_REMOVAL_IDENTITY_MISSING
require_marker "$build_script" \
    'openssl version | grep -F "OpenSSL 3.5.8 25 Aug 2026"' \
    SERVER_OPENSSL_IMAGE_VERSION_GATE_MISSING
require_marker "$build_script" \
    'test "$(openssl version -d)" = "OPENSSLDIR: \"/usr/lib/ssl\""' \
    SERVER_OPENSSL_IMAGE_OPENSSLDIR_GATE_MISSING
require_marker "$build_script" \
    'test "$(openssl version -e)" = "ENGINESDIR: \"/usr/lib/x86_64-linux-gnu/engines-3\""' \
    SERVER_OPENSSL_IMAGE_ENGINESDIR_GATE_MISSING
require_marker "$build_script" \
    'test "$(openssl version -m)" = "MODULESDIR: \"/usr/lib/x86_64-linux-gnu/ossl-modules\""' \
    SERVER_OPENSSL_IMAGE_MODULESDIR_GATE_MISSING
require_marker "$build_script" \
    'ldd /usr/bin/curl | grep -F "/usr/lib/x86_64-linux-gnu/libssl.so.3"' \
    SERVER_OPENSSL_CURL_LINKAGE_GATE_MISSING
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
for removed_path in \
    /usr/bin/eu-readelf \
    /usr/bin/eu-strip \
    /usr/bin/diff3 \
    /usr/bin/getfattr \
    /usr/bin/gpgv \
    /usr/bin/p11-kit \
    /usr/bin/setfattr \
    /usr/bin/unexpand \
    /usr/lib/git-core/git-http-push \
    /usr/lib/x86_64-linux-gnu/libexpat.so.1 \
    /usr/lib/x86_64-linux-gnu/libexpat.so.1.11.2 \
    /usr/libexec/p11-kit/p11-kit-server \
    /etc/login.defs \
    /etc/subgid \
    /etc/subuid; do
    require_marker "$dockerfile" "$removed_path" \
        SERVER_RUNTIME_VULNERABLE_PATH_REMOVAL_MISSING
    require_marker "$build_script" "$removed_path" \
        SERVER_RUNTIME_VULNERABLE_PATH_VALIDATION_MISSING
done
require_marker "$build_script" \
    'find /usr/bin /usr/sbin /usr/share/cattle -xdev -type f -perm /0111 -print0' \
    SERVER_RUNTIME_LIBGCRYPT_EXECUTABLE_AUDIT_MISSING
require_marker "$build_script" \
    'find /run -xdev -type s -path "*p11-kit*"' \
    SERVER_RUNTIME_P11_KIT_SOCKET_AUDIT_MISSING
require_marker "$dockerfile" \
    '/usr/lib/systemd/systemd-journald' \
    SERVER_JOURNALD_REMOVAL_GATE_MISSING
require_marker "$dockerfile" \
    '/usr/share/cattle/install_cattle_binaries' \
    SERVER_RUNTIME_INSTALLER_REMOVAL_GATE_MISSING
require_marker "$cattle_script" \
    'CATTLE_MASTER source-build mode has been removed' \
    SERVER_SOURCE_BUILD_MODE_REJECTION_MISSING
require_marker "$dockerfile" \
    "git --version | grep -Fx 'git version 2.53.0'" \
    SERVER_CATALOG_GIT_RUNTIME_GATE_MISSING
require_marker "$build_script" \
    'test "$(git --version)" = "git version 2.53.0"' \
    SERVER_CATALOG_GIT_IMAGE_VALIDATION_MISSING
require_marker "$dockerfile" \
    "! ldconfig -p | grep -F 'libexpat.so'" \
    SERVER_RUNTIME_EXPAT_LINKER_GATE_MISSING
require_marker "$build_script" \
    '! ldconfig -p | grep -Fq "libexpat.so"' \
    SERVER_RUNTIME_EXPAT_IMAGE_VALIDATION_MISSING
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
    'orchestration_updated=1' \
    SERVER_ORCHESTRATION_UPDATE_GATE_MISSING
require_marker "$build_script" \
    'wrappers_pinned=1' \
    SERVER_WRAPPER_REGRESSION_GATE_MISSING
require_marker "$build_script" \
    'launcher_wrapper_sha256=57b6422dc4a51d4c5448306a4efad182517ed1622bba1257df3c270c5c23ee47' \
    SERVER_WRAPPER_HASH_GATE_MISSING
require_marker "$build_script" \
    'audit_log_filters=1' \
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

jq -e '
  .["@context"] == "https://openvex.dev/ns/v0.2.0"
  and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.376"
  and (.statements | length) == 20
  and ([.statements[].vulnerability.name] | length == (unique | length))
  and ([.statements[] | select(.status == "fixed") | .vulnerability.name] | sort)
      == ["CVE-2024-52005", "CVE-2026-18798", "CVE-2026-27171", "CVE-2026-56391", "CVE-2026-75803"]
  and ([.statements[] | select(.status == "not_affected") | .vulnerability.name] | sort)
      == ["CVE-2024-2236", "CVE-2024-56433", "CVE-2025-1352",
          "CVE-2025-1376", "CVE-2025-66382", "CVE-2026-13757", "CVE-2026-18477",
          "CVE-2026-18508", "CVE-2026-27456", "CVE-2026-3184",
          "CVE-2026-40228", "CVE-2026-53910", "CVE-2026-54371", "CVE-2026-56392",
          "GO-2026-5932"]
  and all(.statements[]; (.products | length) > 0)
  and all(.statements[].products[]; (.["@id"] | startswith("pkg:") and (contains("*") | not)))
  and all(.statements[] | select(.status == "not_affected");
          (.justification | type) == "string" and (.impact_statement | length) > 20)
' "$runtime_vex" >/dev/null

for marker in \
    'release_tag:' \
    '.features["containerd-snapshotter"] = true' \
    "grep -F 'io.containerd.snapshotter.v1'" \
    'PASTURESTACK_BUILD_NO_CACHE=1 IMAGE="$CANDIDATE_IMAGE"' \
    'docker restart "$CANDIDATE_NAME"' \
    'ghcr.io/aquasecurity/trivy:0.74.0@sha256:62b1e65e8869bc4b4c6aa4fa2b21595256c7c2f6018a9d9ad61caf87187c1969' \
    'server.openvex.json' \
    'server-security-scan-raw.json' \
    '--vex /evidence/server.openvex.json' \
    'server-vulnerabilities-raw.tsv' \
    'server-vulnerabilities-unresolved.tsv' \
    'test ! -s "$evidence/server-vulnerabilities-unresolved.tsv"' \
    'server-secrets.tsv' \
    'server.cdx.json' \
    'test -s "$release_notes"' \
    'actions/attest@1e69f48acb82d1966a394da916b4c1698aa569d6 # v4.2.2' \
    'gh release create "$RELEASE_TAG"'; do
    require_marker "$publish_workflow" "$marker" \
        SERVER_CURRENT_PUBLISH_WORKFLOW_GATE_MISSING
done

printf 'SERVER_API_EXPLORER_PATCH_OK release=v1.6.376 base=v1.6.364 orchestration=0.183.286 distributed_cache=5.7.3-pasturestack.4 api_explorer=1.1.18 web_console=1.6.79 audit_log_filters=1 dropdown_destination=1 locale_compatibility=1 operator_state=1 login_experience=1 classic_layout=server-v1.6.358-visual-only docker_29_range=29.4.1..29.7.2 docker_29_6_2=supported bootstrap=5.3.8 bootstrap_icons=1.13.1 bootstrap_javascript=0 runtime_go=1.27.0 ubuntu_security_refresh=2026-08-26 coreutils_uniq=9.11+d64e35a8 openssl=3.5.8 zlib=1.3.2 diff3=removed source_build_mode=removed runtime_tar=removed ssh_client=removed mount_helpers=removed runtime_digest_coordinates=1 vex=openvex-0.2.0 unresolved=0 legal_assets=complete\n'

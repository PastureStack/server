#!/usr/bin/env bash
set -euo pipefail

server_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "${server_dir}/.." && pwd)
cd "$repo_root"

if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
    echo "Refusing to build a release image from an uncommitted worktree" >&2
    exit 1
fi

revision=${PASTURESTACK_SERVER_REVISION:-$(git rev-parse HEAD)}
source_date_epoch=${SOURCE_DATE_EPOCH:-$(git show -s --format=%ct HEAD)}
base_image=${BASE_IMAGE:-ghcr.io/pasturestack/server:v1.6.341}
orchestration_engine_release_base_url=${ORCHESTRATION_ENGINE_RELEASE_BASE_URL:-https://github.com/PastureStack/orchestration-engine/releases/download}
orchestration_engine_release_tag=${ORCHESTRATION_ENGINE_RELEASE_TAG:-v0.183.281}
orchestration_engine_artifact=${ORCHESTRATION_ENGINE_ARTIFACT:-orchestration-engine-0.183.281.jar}
orchestration_engine_artifact_sha256=${ORCHESTRATION_ENGINE_ARTIFACT_SHA256:-da2a8a51562ed16e296f7e29e99482bb44042ff0834cca679bbe01d951ba1682}
orchestration_engine_commit=${ORCHESTRATION_ENGINE_COMMIT:-17c9b856a8004fb71c64f876ad120942429eb260}
node_agent_release_base_url=${NODE_AGENT_RELEASE_BASE_URL:-https://github.com/PastureStack/node-agent/releases/download}
node_agent_release_tag=${NODE_AGENT_RELEASE_TAG:-v0.13.22}
node_agent_linux_artifact=${NODE_AGENT_LINUX_ARTIFACT:-node-agent-0.13.22.tar.gz}
node_agent_linux_artifact_sha256=${NODE_AGENT_LINUX_ARTIFACT_SHA256:-4272c9005ea70c0087668ad9f179bfdc7f277801c938ba55a4fc8c2d1d057b49}
node_agent_windows_artifact=${NODE_AGENT_WINDOWS_ARTIFACT:-node-agent-0.13.22-windows-amd64.zip}
node_agent_windows_artifact_sha256=${NODE_AGENT_WINDOWS_ARTIFACT_SHA256:-36230c05845c6895988edc06c1d8094cccd66899c2f268e3eb7644ca1e7b7c39}
node_agent_commit=${NODE_AGENT_COMMIT:-d370dc6772aea00381a97769b9bf827f35440656}
web_console_release_base_url=${WEB_CONSOLE_RELEASE_BASE_URL:-https://github.com/PastureStack/web-console/releases/download}
web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-1.6.66}
web_console_artifact=${WEB_CONSOLE_ARTIFACT:-1.6.66.tar.gz}
web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:-826f68413598f1fcc8c6983f487cb357a4a1a46af2b65e7059f7c5c8d335054f}
web_console_commit=${WEB_CONSOLE_COMMIT:-dd5f6428ae2bebbc3b427569906be43b419c2c99}
image=${IMAGE:-pasturestack-validation/server:v1.6.355}
build_options=()

[[ "$revision" =~ ^[0-9a-f]{40}$ ]]
[[ "$source_date_epoch" =~ ^[0-9]+$ ]]
[[ "$orchestration_engine_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$orchestration_engine_artifact_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$node_agent_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$node_agent_linux_artifact_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$node_agent_windows_artifact_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$web_console_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$web_console_artifact_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$web_console_release_tag" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$web_console_artifact" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]
[[ "$base_image" == ghcr.io/pasturestack/server:v1.6.341 ]]
for release_base_url in \
    "$orchestration_engine_release_base_url" \
    "$node_agent_release_base_url" \
    "$web_console_release_base_url"; do
case "$release_base_url" in
    https://*) ;;
    http://127.0.0.1:*|http://localhost:*)
        [[ ${PASTURESTACK_ALLOW_LOOPBACK_ARTIFACTS:-0} == 1 ]]
        ;;
    *)
        echo "Release artifact source must use HTTPS or an explicitly allowed loopback address" >&2
        exit 1
        ;;
esac
done
if [[ ${PASTURESTACK_BUILD_NO_CACHE:-0} == 1 ]]; then
    build_options+=(--no-cache)
fi

docker buildx build \
    "${build_options[@]}" \
    --provenance=false \
    --load \
    --network=host \
    --build-arg "BASE_IMAGE=${base_image}" \
    --build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}" \
    --build-arg "PASTURESTACK_SERVER_REVISION=${revision}" \
    --build-arg "ORCHESTRATION_ENGINE_RELEASE_BASE_URL=${orchestration_engine_release_base_url}" \
    --build-arg "ORCHESTRATION_ENGINE_RELEASE_TAG=${orchestration_engine_release_tag}" \
    --build-arg "ORCHESTRATION_ENGINE_ARTIFACT=${orchestration_engine_artifact}" \
    --build-arg "ORCHESTRATION_ENGINE_ARTIFACT_SHA256=${orchestration_engine_artifact_sha256}" \
    --build-arg "ORCHESTRATION_ENGINE_COMMIT=${orchestration_engine_commit}" \
    --build-arg "NODE_AGENT_RELEASE_BASE_URL=${node_agent_release_base_url}" \
    --build-arg "NODE_AGENT_RELEASE_TAG=${node_agent_release_tag}" \
    --build-arg "NODE_AGENT_LINUX_ARTIFACT=${node_agent_linux_artifact}" \
    --build-arg "NODE_AGENT_LINUX_ARTIFACT_SHA256=${node_agent_linux_artifact_sha256}" \
    --build-arg "NODE_AGENT_WINDOWS_ARTIFACT=${node_agent_windows_artifact}" \
    --build-arg "NODE_AGENT_WINDOWS_ARTIFACT_SHA256=${node_agent_windows_artifact_sha256}" \
    --build-arg "NODE_AGENT_COMMIT=${node_agent_commit}" \
    --build-arg "WEB_CONSOLE_RELEASE_BASE_URL=${web_console_release_base_url}" \
    --build-arg "WEB_CONSOLE_RELEASE_TAG=${web_console_release_tag}" \
    --build-arg "WEB_CONSOLE_ARTIFACT=${web_console_artifact}" \
    --build-arg "WEB_CONSOLE_ARTIFACT_SHA256=${web_console_artifact_sha256}" \
    --build-arg "WEB_CONSOLE_COMMIT=${web_console_commit}" \
    --tag "$image" \
    --file server/Dockerfile.port-preflight-runtime-patch \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.355
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    "$base_image"

image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
catalog_json='{"catalogs":{"pasturestack":{"url":"https://github.com/PastureStack/catalog-templates.git","branch":"main","pinnedCommit":"bc446236c16f1170eb9130b4901af3d57dd82db4"}}}'
for marker in \
    CATTLE_RANCHER_SERVER_VERSION=v1.6.355 \
    CATTLE_API_UI_VERSION=1.1.15 \
    PASTURESTACK_API_EXPLORER_PACKAGE=1.1.15 \
    CATTLE_CATTLE_VERSION=v0.183.281 \
    RC16_GO_AGENT_VERSION=0.13.22 \
    RC16_WINDOWS_AGENT_VERSION=0.13.22 \
    RC16_AGENT_PACKAGE_URL=/usr/share/cattle/artifacts/node-agent-0.13.22.tar.gz \
    PASTURESTACK_ORCHESTRATION_ENGINE_COMMIT="${orchestration_engine_commit}" \
    PASTURESTACK_ORCHESTRATION_ENGINE_ARTIFACT_SHA256="${orchestration_engine_artifact_sha256}" \
    PASTURESTACK_NODE_AGENT_VERSION=0.13.22 \
    PASTURESTACK_NODE_AGENT_COMMIT="${node_agent_commit}" \
    PASTURESTACK_NODE_AGENT_LINUX_ARTIFACT_SHA256="${node_agent_linux_artifact_sha256}" \
    PASTURESTACK_NODE_AGENT_WINDOWS_ARTIFACT_SHA256="${node_agent_windows_artifact_sha256}" \
    PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.66 \
    PASTURESTACK_WEB_CONSOLE_COMMIT="${web_console_commit}" \
    PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256="${web_console_artifact_sha256}" \
    PASTURESTACK_AUTHENTICATION_SERVICE_VERSION=0.2.5 \
    PASTURESTACK_VSPHERE_CLI_BUNDLE_VERSION=0.55.1-pasturestack.1 \
    PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27 \
    PASTURESTACK_CATALOG_COMMIT=bc446236c16f1170eb9130b4901af3d57dd82db4 \
    "DEFAULT_CATTLE_CATALOG_URL=${catalog_json}" \
    "CATTLE_CATALOG_URL=${catalog_json}"; do
    test "$(grep -Fxc "$marker" <<<"$image_environment")" = 1
done

critical_paths=(
    /usr/bin/authentication-service.real
    /usr/bin/catalog-service.real
    /usr/bin/govc
    /usr/bin/websocket-proxy.real
)
base_critical=$(docker run --rm --entrypoint sha256sum "$base_image" \
    "${critical_paths[@]}")
image_critical=$(docker run --rm --entrypoint sha256sum "$image" \
    "${critical_paths[@]}")
test "$base_critical" = "$image_critical"

base_engine=$(docker run --rm --entrypoint sha256sum "$base_image" \
    /usr/share/cattle/cattle.jar)
image_engine=$(docker run --rm --entrypoint sha256sum "$image" \
    /usr/share/cattle/cattle.jar)
test "$base_engine" != "$image_engine"
test "$(cut -d ' ' -f 1 <<<"$image_engine")" = \
    "$orchestration_engine_artifact_sha256"

docker run --rm --entrypoint bash "$image" -lc "
    set -euo pipefail
    echo '${node_agent_linux_artifact_sha256}  /usr/share/cattle/artifacts/${node_agent_linux_artifact}' | sha256sum -c -
    echo '${node_agent_windows_artifact_sha256}  /usr/share/cattle/artifacts/${node_agent_windows_artifact}' | sha256sum -c -
    test \"\$(readlink /usr/share/cattle/artifacts/go-agent.tar.gz)\" = '${node_agent_linux_artifact}'
    grep -Fx 'export CATTLE_AGENT_PACKAGE_PYTHON_AGENT_URL=/usr/share/cattle/artifacts/${node_agent_linux_artifact}' /usr/share/cattle/env_vars >/dev/null
    grep -Fx 'export CATTLE_AGENT_PACKAGE_WINDOWS_AGENT_URL=/usr/share/cattle/artifacts/${node_agent_windows_artifact}' /usr/share/cattle/env_vars >/dev/null
"

base_broker=$(docker run --rm --entrypoint sha256sum "$base_image" \
    /usr/bin/pasturestack-console-broker)
image_broker=$(docker run --rm --entrypoint sha256sum "$image" \
    /usr/bin/pasturestack-console-broker)
test "$base_broker" = "$image_broker"

tree_hashes()
{
    local candidate=$1
    local root=$2
    docker run --rm --entrypoint bash "$candidate" -lc \
        "set -euo pipefail; find '$root' -type f -print0 | sort -z | xargs -0 sha256sum"
}
test "$(tree_hashes "$base_image" /usr/share/cattle/war/api-ui)" = \
    "$(tree_hashes "$image" /usr/share/cattle/war/api-ui)"

web_console_hashes()
{
    local candidate=$1
    docker run --rm --entrypoint bash "$candidate" -lc '
        set -euo pipefail
        web_root=$(readlink -f /usr/share/cattle/war)
        {
            find \
                "${web_root}/assets" \
                "${web_root}/ember-fetch" \
                "${web_root}/licenses" \
                "${web_root}/translations" \
                -type f -print0
            printf "%s\0" \
                "${web_root}/VERSION.txt" \
                "${web_root}/favicon.ico" \
                "${web_root}/humans.txt" \
                "${web_root}/index.html" \
                "${web_root}/robots.txt"
        } | sort -z | xargs -0 sha256sum
    '
}
test "$(web_console_hashes "$base_image")" != "$(web_console_hashes "$image")"

docker run --rm --entrypoint bash "$image" -lc '
    set -euo pipefail
    web_root=$(readlink -f /usr/share/cattle/war)
    test "$(cat "${web_root}/VERSION.txt")" = "1.6.66"
    test -s "${web_root}/favicon.ico"
    test -s "${web_root}/index.html"
    test -s "${web_root}/licenses/ember/LICENSE"
    test -s "${web_root}/licenses/ember/UPSTREAM.md"
    for required_file in \
        assets/ui-light.css \
        assets/ui-light.rtl.css \
        assets/ui-dark.css \
        assets/ui-dark.rtl.css \
        licenses/ember-fetch/LICENSE.md \
        licenses/ember-fetch/UPSTREAM.md \
        licenses/ember-power-select/LICENSE.md \
        licenses/ember-power-select/UPSTREAM.md \
        licenses/ember-basic-dropdown/LICENSE.md \
        licenses/ember-basic-dropdown/UPSTREAM.md \
        licenses/runtime/ember-power-select/LICENSE.md \
        licenses/runtime/ember-power-select/UPSTREAM.md \
        licenses/runtime/ember-basic-dropdown/LICENSE.md \
        licenses/runtime/ember-basic-dropdown/UPSTREAM.md \
        licenses/runtime/ember-concurrency/LICENSE.md \
        licenses/runtime/ember-concurrency/UPSTREAM.md \
        licenses/runtime/ember-modifier/LICENSE.md \
        licenses/runtime/ember-modifier/UPSTREAM.md; do
        test -s "${web_root}/${required_file}"
    done
    echo "84e97eb6663fa5fa07f36661e6040ab8a557b165c13860e2e72c1a692ca3c2a0  ${web_root}/licenses/ember/LICENSE" |
        sha256sum -c -
    grep -Fx -- "- Distribution: \`ember-source@6.12.0\`" \
        "${web_root}/licenses/ember/UPSTREAM.md" >/dev/null
    echo "bae5cb45df11b4fa8e894ae3b9b13595e154ade61ee6c57d5cfcd422771153a7  ${web_root}/licenses/ember-fetch/LICENSE.md" |
        sha256sum -c -
    grep -F -- "- Upstream version: \`5.1.3\`" \
        "${web_root}/licenses/ember-fetch/UPSTREAM.md" >/dev/null
    echo "0c454de6bb0a94445b9fe315cdad6830e317ca6aa9fb04d0b84fe000d04a5c90  ${web_root}/licenses/ember-power-select/LICENSE.md" |
        sha256sum -c -
    grep -F -- "- Upstream version: \`1.0.0-beta.19\`" \
        "${web_root}/licenses/ember-power-select/UPSTREAM.md" >/dev/null
    echo "c3cd4817d1568725ab93dced4bd46f0dceaeace8c6badb9d12e2239fced7e810  ${web_root}/licenses/ember-basic-dropdown/LICENSE.md" |
        sha256sum -c -
    grep -F -- "- Upstream version: \`0.16.0-beta.4\`" \
        "${web_root}/licenses/ember-basic-dropdown/UPSTREAM.md" >/dev/null
    echo "fee7ff7079edfdbac1c78d0329da16ae9b6ef73405cec197ed6136ddf1d70117  ${web_root}/licenses/runtime/ember-power-select/LICENSE.md" |
        sha256sum -c -
    grep -F -- "- Upstream version: \`9.0.2\`" \
        "${web_root}/licenses/runtime/ember-power-select/UPSTREAM.md" >/dev/null
    echo "fee7ff7079edfdbac1c78d0329da16ae9b6ef73405cec197ed6136ddf1d70117  ${web_root}/licenses/runtime/ember-basic-dropdown/LICENSE.md" |
        sha256sum -c -
    grep -F -- "- Upstream version: \`9.0.0\`" \
        "${web_root}/licenses/runtime/ember-basic-dropdown/UPSTREAM.md" >/dev/null
    echo "c7543891093cb613eeb5a90c16a18fa25b8708a0c7c1c67691202384ff9b6567  ${web_root}/licenses/runtime/ember-concurrency/LICENSE.md" |
        sha256sum -c -
    grep -F -- "- Upstream version: \`5.2.0\`" \
        "${web_root}/licenses/runtime/ember-concurrency/UPSTREAM.md" >/dev/null
    echo "0390d452d98169895ab1ca8c14d35471642759366d51e1cfd014ded8bb10c51d  ${web_root}/licenses/runtime/ember-modifier/LICENSE.md" |
        sha256sum -c -
    grep -F -- "- Upstream version: \`4.3.0\`" \
        "${web_root}/licenses/runtime/ember-modifier/UPSTREAM.md" >/dev/null
    echo "SERVER_IMAGE_GATE_STAGE=artifact-legal-complete"
    test "$(find "${web_root}/translations" -maxdepth 1 -type f -name "*.json" | wc -l)" -eq 13
    test ! -e "${web_root}/translations/none.json"
    test "$(find "${web_root}" -type f -name "*.map" | wc -l)" -eq 0
    echo "SERVER_IMAGE_GATE_STAGE=artifact-layout-complete"
    ui_entry=$(find "${web_root}/assets" -maxdepth 1 -type f -name "ui-*.js" -print -quit)
    vendor_entry=$(find "${web_root}/assets" -maxdepth 1 -type f -name "vendor-*.js" -print -quit)
    test -n "${ui_entry}"
    test -n "${vendor_entry}"
    require_ui_marker()
    {
        marker=$1
        if ! grep -aF "${marker}" "${ui_entry}" >/dev/null; then
            echo "SERVER_IMAGE_GATE_FAILED=web-console-marker marker=${marker}" >&2
            exit 1
        fi
        echo "SERVER_IMAGE_GATE_MARKER_OK=${marker}"
    }
    require_ui_marker "Subscribe disconnected"
    require_ui_marker "Socket refusing to connect while another socket exists"
    require_ui_marker "ui/models/oidcconfig"
    require_ui_marker "X-PastureStack-Session-Secret"
    require_ui_marker "\"missing\"===t?\"create\""
    require_ui_marker "catalog-version-options"
    require_ui_marker "upgradeVersionLinks"
    require_ui_marker " (current)"
    require_ui_marker "ui/components/schema/input-enum/template"
    require_ui_marker "[\"choice\"]"
    require_ui_marker "ui/utils/catalog-question-answer"
    require_ui_marker "ui/utils/localized-catalog-field"
    require_ui_marker "mergeCatalogLocalizationLabels"
    require_ui_marker "catalogQuestionLocalizationLabels"
    require_ui_marker "templateRequestSerial"
    require_ui_marker "portpreflight"
    require_ui_marker "buildPreflightInput"
    require_ui_marker "preflightChanged"
    require_ui_marker "invokePassedAction"
    require_ui_marker "setPorts"
    require_ui_marker "volumepreflight"
    require_ui_marker "volume-path-autocomplete"
    require_ui_marker "pasturestack-nfs"
    require_ui_marker "volumePreflightChanged"
    require_ui_marker "publishPreflightState"
    require_ui_marker "loadingWatchdog"
    require_ui_marker "loadingTimeout:3e4"
    require_ui_marker "scheduleLoadingOverlayHide"
    # Minified production marker: stop(!0,!0).css("opacity",1).show()
    require_ui_marker "stop(!0,!0).css(\"opacity\",1).show()"
    require_ui_marker "pasturestack-loader"
    require_ui_marker "pasturestack-loader__panel"
    require_ui_marker "pasturestack-loader__stack"
    require_ui_marker "pasturestack-loader__layer--three"
    require_ui_marker "pasturestack-loader__progress"
    for retired_loader_marker in \
        'class="loadfield"' \
        'class="orbit"' \
        'class="grass"' \
        'class="sun"' \
        'class="moon"'; do
        if grep -aF "${retired_loader_marker}" "${ui_entry}"; then
            echo "SERVER_IMAGE_GATE_FAILED=retired-loading-scene marker=${retired_loader_marker}" >&2
            exit 1
        fi
    done
    for retired_loader_marker in \
        'pasturestack-loader__ring' \
        'pasturestack-loader-spin' \
        'pasturestack-loader-pulse'; do
        if grep -aF "${retired_loader_marker}" "${ui_entry}"; then
            echo "SERVER_IMAGE_GATE_FAILED=retired-circular-loader marker=${retired_loader_marker}" >&2
            exit 1
        fi
    done
    if grep -aF "stop().show().fadeIn({duration:100" "${ui_entry}"; then
        echo "Rejected race-prone nested loading overlay fade callback in Web Console image" >&2
        exit 1
    fi
    require_ui_marker "([A-Z]+)([A-Z][a-z])"
    if grep -aF ".dasherize()" "${ui_entry}"; then
        echo "Rejected legacy String prototype extension in Web Console image" >&2
        exit 1
    fi
    if grep -aF "formVolumes.errors.preflightChecking" "${ui_entry}"; then
        echo "Rejected stale client-side volume preflight save blocker in Web Console image" >&2
        exit 1
    fi
    require_ui_marker "define(\"ui/services/prefs\""
    require_ui_marker "storageTablePerPage:"
    require_ui_marker ".PREFS.STORAGE_TABLE_COUNT"
    require_ui_marker ".TABLES.STORAGE_PAGE_SIZES"
    require_ui_marker ".TABLES.DEFAULT_STORAGE_COUNT"
    require_ui_marker "storagePageSizeChanged"
    require_ui_marker "pageSizeChanged"
    require_ui_marker "ui/host/containers/route"
    require_ui_marker "followLink(\"instances\")"
    echo "SERVER_IMAGE_GATE_STAGE=web-console-markers-complete"
    require_vendor_marker()
    {
        marker=$1
        if ! grep -aF "${marker}" "${vendor_entry}" >/dev/null; then
            echo "SERVER_IMAGE_GATE_FAILED=web-console-vendor-marker marker=${marker}" >&2
            exit 1
        fi
        echo "SERVER_IMAGE_GATE_VENDOR_MARKER_OK=${marker}"
    }
    require_vendor_marker "_filteredShouldChangeContent"
    require_vendor_marker "\"body\",\"body.[]\",\"arranged.[]\",\"sortBy\",\"descending\",\"sortRevision\""
    require_vendor_marker "didReceiveAttrs(){this._super(...arguments),this._syncRequestedPageSize(),this._updateFiltered()}"
    require_vendor_marker "_syncRequestedPageSize(){let e=this.get(\"perPage\")"
    require_vendor_marker "this._lastRequestedPageSizeInput!==e&&(this._lastRequestedPageSizeInput=e,this._applyRequestedPageSize(e))"
    require_vendor_marker "this.setProperties({page:1,effectivePerPage:0===t?this.get(\"allPageSizeValue\"):t,selectedPageSize:t})"
    if grep -aF "this.setProperties({page:1,perPage:" "${vendor_entry}"; then
        echo "Rejected caller-owned page-size mutation found in image" >&2
        exit 1
    fi
    require_vendor_marker "_pagedOptionsShouldChange"
    require_vendor_marker "_syncPagedContent(e){let t=this.get(\"pagedContent\")"
    require_vendor_marker "t.get(\"content\")!==e&&t.set(\"content\",e)"
    require_vendor_marker "t.get(\"page\")!==r&&t.set(\"page\",r),t.get(\"perPage\")!==n&&t.set(\"perPage\",n)"
    require_vendor_marker "clampPageToContentLength"
    require_vendor_marker "this.clampPageToContentLength(e.length),this.set(\"filtered\",e),this._syncPagedContent(e)"
    require_ui_marker "storageTableRevision:0"
    require_ui_marker "_removeSuccessfulVolumes(e)"
    require_ui_marker "onRemoved:e=>"
    require_ui_marker "this.get(\"opts.onRemoved\")"
    require_vendor_marker "arranged.[]"
    require_vendor_marker "run.throttle(this,this._updateFiltered,100,!1)"
    require_vendor_marker "run.debounce(this,this._updateFiltered,100,!1)"
    echo "SERVER_IMAGE_GATE_STAGE=sortable-table-refresh-complete"
    for theme_asset in ui-light.css ui-light.rtl.css ui-dark.css ui-dark.rtl.css; do
        theme="${web_root}/assets/${theme_asset}"
        grep -Fx "  --prism-code-foreground: #f8f8f2;" "${theme}" >/dev/null
        grep -Fx "  --prism-code-background: #272822;" "${theme}" >/dev/null
        grep -Fx "  --prism-code-border: #3e3d32;" "${theme}" >/dev/null
        code_surface_rules=$(sed -n "/^pre {/,/^}/p" "${theme}")
        grep -Fx "  background: var(--prism-code-background);" <<<"${code_surface_rules}" >/dev/null
        grep -Fx "  border-color: var(--prism-code-border);" <<<"${code_surface_rules}" >/dev/null
        grep -Fx "  color: var(--prism-code-foreground);" <<<"${code_surface_rules}" >/dev/null
    done
    resize_rule=$(sed -n "/^\\.console-workspace-resize-handle {/,/^}/p" "${web_root}/assets/ui-light.css")
    grep -Fx "  width: 11px;" <<<"${resize_rule}" >/dev/null
    grep -Fx "  height: 11px;" <<<"${resize_rule}" >/dev/null
    echo "SERVER_IMAGE_GATE_STAGE=web-console-style-complete"
    grep -aF "bs.collapse" "${vendor_entry}" >/dev/null
    grep -aF "bs.dropdown" "${vendor_entry}" >/dev/null
    if grep -aEq "bs\.(button|tooltip|popover)|data-loading-text" "${vendor_entry}"; then
        echo "Rejected Bootstrap runtime plugin found in Server image" >&2
        exit 1
    fi
    echo "SERVER_IMAGE_GATE_STAGE=vendor-runtime-complete"
    grep -F "href=\"/favicon.ico\"" "${web_root}/index.html" >/dev/null
    grep -F "pasturestack-favicon.svg" "${web_root}/index.html" >/dev/null
    grep -F \
      "\"systemManaged\":\"SMTP 寄信服務由系統管理員集中設定，全系統共用。您的帳號不會儲存 SMTP 伺服器、寄件者或密碼。\"" \
      "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F \
      "\"active_port_conflict_on_other_host\":\"此環境中的另一台主機已使用這個託管網路連接埠。\"" \
      "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F \
      "\"nfs_incomplete_host_coverage\":\"pasturestack-nfs 尚未涵蓋所有使用中的主機。\"" \
      "${web_root}/translations/zh-tw.json" >/dev/null
    echo "SERVER_IMAGE_GATE_STAGE=web-console-content-complete"
    grep -F "\"version\": \"1.1.15\"" "${web_root}/api-ui/version.json" >/dev/null
    echo "SERVER_IMAGE_GATE_STAGE=api-explorer-complete"
    unzip -p /usr/share/cattle/cattle.jar META-INF/MANIFEST.MF |
        tr -d "\r" |
        grep -Fx "Implementation-Version: 0.183.281" >/dev/null
    api_logic=$(find "${web_root}/WEB-INF/lib" -maxdepth 1 -type f \
        -name "cattle-iaas-api-logic-0.183.281.jar" -print -quit)
    model=$(find "${web_root}/WEB-INF/lib" -maxdepth 1 -type f \
        -name "cattle-iaas-model-0.183.281.jar" -print -quit)
    resources=$(find "${web_root}/WEB-INF/lib" -maxdepth 1 -type f \
        -name "cattle-resources-0.183.281.jar" -print -quit)
    app_config=$(find "${web_root}/WEB-INF/lib" -maxdepth 1 -type f \
        -name "cattle-app-config-0.183.281.jar" -print -quit)
    service_discovery=$(find "${web_root}/WEB-INF/lib" -maxdepth 1 -type f \
        -name "cattle-iaas-service-discovery-api-0.183.281.jar" -print -quit)
    test -n "${api_logic}"
    test -n "${model}"
    test -n "${resources}"
    test -n "${app_config}"
    test -n "${service_discovery}"
    unzip -p "${api_logic}" \
        io/cattle/platform/iaas/api/port/PortPreflightService.class |
        grep -aF "host.port.check" >/dev/null
    unzip -p "${api_logic}" \
        io/cattle/platform/iaas/api/port/PortPreflightService.class |
        grep -aF "active_port_conflict_on_other_host" >/dev/null
    unzip -p "${api_logic}" \
        schema/base/project.json.d/port-preflight.json |
        grep -F '"portpreflight"' >/dev/null
    unzip -p "${model}" \
        io/cattle/platform/core/util/PortBindingAddress.class |
        grep -aF "normalize" >/dev/null
    unzip -p "${resources}" schema/user/user-auth.json |
        grep -F "\"portPreflightInput\" : \"r\"" >/dev/null
    unzip -p "${resources}" schema/user/user-auth.json |
        grep -F "\"portPreflightInput.ports\" : \"cr\"" >/dev/null
    unzip -p "${resources}" schema/user/user-auth.json |
        grep -F "\"portPreflightResult.conflicts\" : \"r\"" >/dev/null
    unzip -p "${resources}" schema/project/project-auth.json |
        grep -F "\"portPreflightInput\" : \"cr\"" >/dev/null
    unzip -p "${resources}" schema/project/project-auth.json |
        grep -F "\"portPreflightPort\" : \"cr\"" >/dev/null
    unzip -p "${resources}" schema/project/project-auth.json |
        grep -F "\"portPreflightResult\" : \"r\"" >/dev/null
    unzip -p "${resources}" schema/project/project-auth.json |
        grep -F "\"portPreflightConflict\" : \"r\"" >/dev/null
    for class_name in \
        io/cattle/platform/iaas/api/filter/instance/InstanceVolumesValidationFilter.class \
        io/cattle/platform/iaas/api/volume/VolumePreflightActionHandler.class \
        io/cattle/platform/iaas/api/volume/VolumePreflightInputs.class \
        io/cattle/platform/iaas/api/volume/VolumePreflightService.class; do
        test "$(unzip -Z1 "${api_logic}" | grep -Fxc "${class_name}")" -eq 1
    done
    unzip -p "${api_logic}" schema/base/project.json.d/volume-preflight.json |
        grep -F '"volumepreflight"' >/dev/null
    for class_name in \
        io/cattle/platform/core/addon/VolumePreflightInput.class \
        io/cattle/platform/core/addon/VolumePreflightIssue.class \
        io/cattle/platform/core/addon/VolumePreflightResult.class; do
        test "$(unzip -Z1 "${model}" | grep -Fxc "${class_name}")" -eq 1
    done
    unzip -p "${resources}" schema/user/user-auth.json |
        grep -F "\"volumePreflightInput.dataVolumes\" : \"cr\"" >/dev/null
    unzip -p "${resources}" schema/user/user-auth.json |
        grep -F "\"volumePreflightResult.issues\" : \"r\"" >/dev/null
    unzip -p "${resources}" schema/project/project-auth.json |
        grep -F "\"volumePreflightInput\" : \"cr\"" >/dev/null
    unzip -p "${resources}" schema/project/project-auth.json |
        grep -F "\"volumePreflightResult\" : \"r\"" >/dev/null
    unzip -p "${resources}" schema/project/project-auth.json |
        grep -F "\"volumePreflightIssue\" : \"r\"" >/dev/null
    unzip -p "${app_config}" io/cattle/platform/app/ApiServerConfig.class |
        grep -aF "VolumePreflightActionHandler" >/dev/null
    for schema_type in VolumePreflightInput VolumePreflightResult VolumePreflightIssue; do
        unzip -p "${app_config}" io/cattle/platform/app/CoreModelConfig.class |
            grep -aF "${schema_type}" >/dev/null
    done
    for class_name in \
        io/cattle/platform/servicediscovery/api/filter/ServiceValidationFilter.class \
        io/cattle/platform/servicediscovery/api/filter/ServiceUpgradeValidationFilter.class; do
        test "$(unzip -Z1 "${service_discovery}" | grep -Fxc "${class_name}")" -eq 1
        unzip -p "${service_discovery}" "${class_name}" |
            grep -aF "VolumePreflightService" >/dev/null
    done
    echo "SERVER_IMAGE_GATE_STAGE=server-core-complete"
    test "$(/usr/bin/govc version)" = "govc 0.55.1-pasturestack.1"
    echo "SERVER_IMAGE_GATE_STAGE=vsphere-cli-complete"
    /usr/bin/authentication-service.real --version | grep -F "0.2.5" >/dev/null
    echo "SERVER_IMAGE_GATE_STAGE=authentication-service-complete"
'

printf 'SERVER_PORT_PREFLIGHT_RUNTIME_PATCH_IMAGE_OK image=%s revision=%s base=%s engine_commit=%s engine_sha256=%s node_agent_commit=%s node_agent_linux_sha256=%s node_agent_windows_sha256=%s web_console_commit=%s web_console_sha256=%s catalog_commit=bc446236c16f1170eb9130b4901af3d57dd82db4 loading_scene=rectangular_stack port_preflight=authoritative port_preflight_schema_auth=project_visible volume_preflight=authoritative volume_preflight_project_schema=authorized volume_preflight_type_set=registered volume_validation=create_and_upgrade volume_driver=select volume_autocomplete=max8 nfs_contract=environment_multiHostRW_complete_coverage save_validation_string=native node_inspection=host.port.check port_preflight_closure_actions=direct api_explorer_unchanged=1 critical_runtime_unchanged=1 console_broker=unchanged_recoverable_missing_status websocket_reconnect=single_owner terminal_recovery=broker_probe oidc_writable_model=1 legacy_catalog_versions=retained catalog_version_select=reactive_upgrade_links catalog_enum_options=native catalog_required_answers=false_zero_valid catalog_revision_localization=target_label_fallback catalog_version_requests=latest_only sortable_table_late_body=refreshed sortable_table_body_replacement=refreshed sortable_table_initial_attrs=refreshed sortable_table_paged_content=explicit_sync sortable_table_pagination=explicit_sync storage_table_page_size_preference=controller_owned_callback storage_table_page_clamp=last_valid storage_bulk_remove_refresh=per_success host_container_relationship=follow_link theme_css=4 code_block_contrast=wcag_aa code_block_surface=commonmark_pre legal_sources=8\n' \
    "$image" "$revision" "$base_image" \
    "$orchestration_engine_commit" "$orchestration_engine_artifact_sha256" \
    "$node_agent_commit" "$node_agent_linux_artifact_sha256" \
    "$node_agent_windows_artifact_sha256" "$web_console_commit" \
    "$web_console_artifact_sha256"

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
base_image=${BASE_IMAGE:-ghcr.io/pasturestack/server:v1.6.339}
web_console_release_base_url=${WEB_CONSOLE_RELEASE_BASE_URL:-https://github.com/PastureStack/web-console/releases/download}
web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-v1.6.56-pasturestack.51}
web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.56-pasturestack.51.tar.gz}
web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:-3676d870f2326f47897f97da9a9fc16173d2edf3daccf0ed62754cac8e590f7a}
web_console_commit=${WEB_CONSOLE_COMMIT:-fe7f366d9d976404a0bfb6b2763999cd99e9efa0}
image=${IMAGE:-pasturestack-validation/server:v1.6.340}
build_options=()

[[ "$revision" =~ ^[0-9a-f]{40}$ ]]
[[ "$source_date_epoch" =~ ^[0-9]+$ ]]
[[ "$web_console_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$web_console_artifact_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$web_console_release_tag" =~ ^v[0-9][0-9A-Za-z.-]*$ ]]
[[ "$web_console_artifact" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]
[[ "$base_image" == ghcr.io/pasturestack/server:v1.6.339 ]]
case "$web_console_release_base_url" in
    https://*) ;;
    http://127.0.0.1:*|http://localhost:*)
        [[ ${PASTURESTACK_ALLOW_LOOPBACK_ARTIFACTS:-0} == 1 ]]
        ;;
    *)
        echo "Web Console artifact source must use HTTPS or an explicitly allowed loopback address" >&2
        exit 1
        ;;
esac
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
    --build-arg "WEB_CONSOLE_RELEASE_BASE_URL=${web_console_release_base_url}" \
    --build-arg "WEB_CONSOLE_RELEASE_TAG=${web_console_release_tag}" \
    --build-arg "WEB_CONSOLE_ARTIFACT=${web_console_artifact}" \
    --build-arg "WEB_CONSOLE_ARTIFACT_SHA256=${web_console_artifact_sha256}" \
    --build-arg "WEB_CONSOLE_COMMIT=${web_console_commit}" \
    --tag "$image" \
    --file server/Dockerfile.web-console-runtime-patch \
    server

test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.version"}}')" = \
    v1.6.340
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')" = \
    "$revision"
test "$(docker image inspect "$image" \
    --format '{{index .Config.Labels "org.opencontainers.image.base.name"}}')" = \
    "$base_image"

image_environment=$(docker image inspect "$image" \
    --format '{{range .Config.Env}}{{println .}}{{end}}')
catalog_json='{"catalogs":{"pasturestack":{"url":"https://github.com/PastureStack/catalog-templates.git","branch":"main","pinnedCommit":"57707ddf891e36066a144d7821adc458dbf8da9c"}}}'
for marker in \
    CATTLE_RANCHER_SERVER_VERSION=v1.6.340 \
    CATTLE_API_UI_VERSION=1.1.15 \
    PASTURESTACK_API_EXPLORER_PACKAGE=1.1.15 \
    PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.51 \
    PASTURESTACK_WEB_CONSOLE_COMMIT="${web_console_commit}" \
    PASTURESTACK_WEB_CONSOLE_ARTIFACT_SHA256="${web_console_artifact_sha256}" \
    CATTLE_CATTLE_VERSION=v0.183.273 \
    PASTURESTACK_AUTHENTICATION_SERVICE_VERSION=0.2.5 \
    PASTURESTACK_VSPHERE_CLI_BUNDLE_VERSION=0.55.1-pasturestack.1 \
    PASTURESTACK_DOCKER_SUPPORT_POLICY=2026-07-27 \
    PASTURESTACK_CATALOG_COMMIT=57707ddf891e36066a144d7821adc458dbf8da9c \
    "DEFAULT_CATTLE_CATALOG_URL=${catalog_json}" \
    "CATTLE_CATALOG_URL=${catalog_json}"; do
    test "$(grep -Fxc "$marker" <<<"$image_environment")" = 1
done

critical_paths=(
    /usr/share/cattle/cattle.jar
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
    test "$(cat "${web_root}/VERSION.txt")" = "1.6.56"
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
    require_vendor_marker "didReceiveAttrs(){this._super(...arguments),this._updateFiltered()}"
    require_vendor_marker "_pagedOptionsShouldChange"
    require_vendor_marker "_syncPagedContent(e){let t=this.get(\"pagedContent\")"
    require_vendor_marker "t.get(\"content\")!==e&&t.set(\"content\",e)"
    require_vendor_marker "t.get(\"page\")!==r&&t.set(\"page\",r),t.get(\"perPage\")!==n&&t.set(\"perPage\",n)"
    require_vendor_marker "this.set(\"filtered\",e),this._syncPagedContent(e)"
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
    echo "SERVER_IMAGE_GATE_STAGE=web-console-content-complete"
    grep -F "\"version\": \"1.1.15\"" "${web_root}/api-ui/version.json" >/dev/null
    echo "SERVER_IMAGE_GATE_STAGE=api-explorer-complete"
    unzip -p /usr/share/cattle/cattle.jar META-INF/MANIFEST.MF |
        tr -d "\r" |
        grep -Fx "Implementation-Version: 0.183.273" >/dev/null
    echo "SERVER_IMAGE_GATE_STAGE=server-core-complete"
    test "$(/usr/bin/govc version)" = "govc 0.55.1-pasturestack.1"
    echo "SERVER_IMAGE_GATE_STAGE=vsphere-cli-complete"
    /usr/bin/authentication-service.real --version | grep -F "0.2.5" >/dev/null
    echo "SERVER_IMAGE_GATE_STAGE=authentication-service-complete"
'

printf 'SERVER_WEB_CONSOLE_RUNTIME_PATCH_IMAGE_OK image=%s revision=%s base=%s web_console_commit=%s artifact_sha256=%s catalog_commit=57707ddf891e36066a144d7821adc458dbf8da9c api_explorer_unchanged=1 critical_runtime_unchanged=1 console_broker=unchanged_recoverable_missing_status websocket_reconnect=single_owner terminal_recovery=broker_probe oidc_writable_model=1 legacy_catalog_versions=retained catalog_version_select=reactive_upgrade_links catalog_enum_options=native catalog_required_answers=false_zero_valid catalog_revision_localization=target_label_fallback catalog_version_requests=latest_only sortable_table_late_body=refreshed sortable_table_body_replacement=refreshed sortable_table_initial_attrs=refreshed sortable_table_paged_content=explicit_sync sortable_table_pagination=explicit_sync host_container_relationship=follow_link theme_css=4 code_block_contrast=wcag_aa code_block_surface=commonmark_pre legal_sources=8\n' \
    "$image" "$revision" "$base_image" "$web_console_commit" \
    "$web_console_artifact_sha256"

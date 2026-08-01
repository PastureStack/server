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
base_image=${BASE_IMAGE:-ghcr.io/pasturestack/server:v1.6.325}
web_console_release_base_url=${WEB_CONSOLE_RELEASE_BASE_URL:-https://github.com/PastureStack/web-console/releases/download}
web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-v1.6.56-pasturestack.38}
web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.56-pasturestack.38.tar.gz}
web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:-572d33673d939240077876a12cc546ab74c2f3525dd86f860ebe1d45344e0438}
web_console_commit=${WEB_CONSOLE_COMMIT:-21e53a5427a1099af026e72fdee8675d8ed5e55f}
image=${IMAGE:-pasturestack-validation/server:v1.6.327}
build_options=()

[[ "$revision" =~ ^[0-9a-f]{40}$ ]]
[[ "$source_date_epoch" =~ ^[0-9]+$ ]]
[[ "$web_console_commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$web_console_artifact_sha256" =~ ^[0-9a-f]{64}$ ]]
[[ "$web_console_release_tag" =~ ^v[0-9][0-9A-Za-z.-]*$ ]]
[[ "$web_console_artifact" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]
[[ "$base_image" == ghcr.io/pasturestack/server:v1.6.325 ]]
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
    v1.6.327
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
    CATTLE_RANCHER_SERVER_VERSION=v1.6.327 \
    CATTLE_API_UI_VERSION=1.1.15 \
    PASTURESTACK_API_EXPLORER_PACKAGE=1.1.15 \
    PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.38 \
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
    test "$(find "${web_root}/translations" -maxdepth 1 -type f -name "*.json" | wc -l)" -eq 13
    test ! -e "${web_root}/translations/none.json"
    test "$(find "${web_root}" -type f -name "*.map" | wc -l)" -eq 0
    ui_entry=$(find "${web_root}/assets" -maxdepth 1 -type f -name "ui-*.js" -print -quit)
    vendor_entry=$(find "${web_root}/assets" -maxdepth 1 -type f -name "vendor-*.js" -print -quit)
    test -n "${ui_entry}"
    test -n "${vendor_entry}"
    grep -aF "Subscribe disconnected" "${ui_entry}" >/dev/null
    grep -aF "Socket refusing to connect while another socket exists" "${ui_entry}" >/dev/null
    grep -aF "bs.collapse" "${vendor_entry}" >/dev/null
    grep -aF "bs.dropdown" "${vendor_entry}" >/dev/null
    if grep -aEq "bs\.(button|tooltip|popover)|data-loading-text" "${vendor_entry}"; then
        echo "Rejected Bootstrap runtime plugin found in Server image" >&2
        exit 1
    fi
    grep -F "href=\"/favicon.ico\"" "${web_root}/index.html" >/dev/null
    grep -F "pasturestack-favicon.svg" "${web_root}/index.html" >/dev/null
    grep -F \
      "\"systemManaged\":\"SMTP 寄信服務由系統管理員集中設定，全系統共用。您的帳號不會儲存 SMTP 伺服器、寄件者或密碼。\"" \
      "${web_root}/translations/zh-tw.json" >/dev/null
    grep -F "\"version\": \"1.1.15\"" "${web_root}/api-ui/version.json" >/dev/null
    unzip -p /usr/share/cattle/cattle.jar META-INF/MANIFEST.MF |
        tr -d "\r" |
        grep -Fx "Implementation-Version: 0.183.273" >/dev/null
    test "$(/usr/bin/govc version)" = "govc 0.55.1-pasturestack.1"
    /usr/bin/authentication-service.real --version | grep -F "0.2.5" >/dev/null
'

printf 'SERVER_WEB_CONSOLE_RUNTIME_PATCH_IMAGE_OK image=%s revision=%s base=%s web_console_commit=%s artifact_sha256=%s catalog_commit=57707ddf891e36066a144d7821adc458dbf8da9c api_explorer_unchanged=1 critical_runtime_unchanged=1 websocket_reconnect=single_owner legacy_catalog_versions=retained theme_css=4 legal_sources=8\n' \
    "$image" "$revision" "$base_image" "$web_console_commit" \
    "$web_console_artifact_sha256"

#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.web-console-runtime-patch
build_script=server/build-web-console-runtime-patch-image.sh

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
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.333' \
    SERVER_WEB_CONSOLE_PATCH_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.334"' \
    SERVER_WEB_CONSOLE_PATCH_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.334' \
    SERVER_WEB_CONSOLE_PATCH_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.45' \
    SERVER_WEB_CONSOLE_PATCH_PACKAGE_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_ARTIFACT_SHA256=44d825c31749490dad5e7262d9e1d4bec1ffbaa94fab3d8e44bb8493ec920b6e' \
    SERVER_WEB_CONSOLE_PATCH_HASH_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_COMMIT=7a388418b10168cab56853d4be553f65f1f2c48e' \
    SERVER_WEB_CONSOLE_PATCH_COMMIT_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_CATALOG_COMMIT=57707ddf891e36066a144d7821adc458dbf8da9c' \
    SERVER_WEB_CONSOLE_PATCH_CATALOG_PIN_MISSING
require_marker "$dockerfile" \
    '"pinnedCommit":"57707ddf891e36066a144d7821adc458dbf8da9c"' \
    SERVER_WEB_CONSOLE_PATCH_CATALOG_URL_PIN_MISSING
require_marker "$dockerfile" \
    'tar --no-same-owner --no-same-permissions -xzf' \
    SERVER_WEB_CONSOLE_PATCH_SAFE_EXTRACTION_MISSING
require_marker "$dockerfile" \
    'test ! -e "${package_root}/translations/none.json"' \
    SERVER_WEB_CONSOLE_PATCH_PSEUDO_LOCALE_REJECTION_MISSING
require_marker "$dockerfile" \
    "Private migration marker found in Web Console artifact" \
    SERVER_WEB_CONSOLE_PATCH_PRIVACY_GATE_MISSING
require_marker "$dockerfile" \
    'licenses/ember/LICENSE' \
    SERVER_WEB_CONSOLE_PATCH_EMBER_LICENSE_MISSING
require_marker "$dockerfile" \
    '84e97eb6663fa5fa07f36661e6040ab8a557b165c13860e2e72c1a692ca3c2a0' \
    SERVER_WEB_CONSOLE_PATCH_EMBER_LICENSE_HASH_MISSING
for theme_asset in ui-light.css ui-light.rtl.css ui-dark.css ui-dark.rtl.css; do
    require_marker "$dockerfile" \
        "assets/${theme_asset}" \
        SERVER_WEB_CONSOLE_PATCH_THEME_ASSET_MISSING
    require_marker "$build_script" \
        "assets/${theme_asset}" \
        SERVER_WEB_CONSOLE_PATCH_IMAGE_THEME_ASSET_GATE_MISSING
done
for legal_path in \
    licenses/ember-fetch/LICENSE.md \
    licenses/ember-power-select/LICENSE.md \
    licenses/ember-basic-dropdown/LICENSE.md \
    licenses/runtime/ember-power-select/LICENSE.md \
    licenses/runtime/ember-basic-dropdown/LICENSE.md \
    licenses/runtime/ember-concurrency/LICENSE.md \
    licenses/runtime/ember-modifier/LICENSE.md; do
    require_marker "$dockerfile" \
        "$legal_path" \
        SERVER_WEB_CONSOLE_PATCH_DEPENDENCY_LICENSE_MISSING
    require_marker "$build_script" \
        "$legal_path" \
        SERVER_WEB_CONSOLE_PATCH_IMAGE_DEPENDENCY_LICENSE_GATE_MISSING
done
for legal_hash in \
    bae5cb45df11b4fa8e894ae3b9b13595e154ade61ee6c57d5cfcd422771153a7 \
    0c454de6bb0a94445b9fe315cdad6830e317ca6aa9fb04d0b84fe000d04a5c90 \
    c3cd4817d1568725ab93dced4bd46f0dceaeace8c6badb9d12e2239fced7e810 \
    fee7ff7079edfdbac1c78d0329da16ae9b6ef73405cec197ed6136ddf1d70117 \
    c7543891093cb613eeb5a90c16a18fa25b8708a0c7c1c67691202384ff9b6567 \
    0390d452d98169895ab1ca8c14d35471642759366d51e1cfd014ded8bb10c51d; do
    require_marker "$dockerfile" \
        "$legal_hash" \
        SERVER_WEB_CONSOLE_PATCH_DEPENDENCY_LICENSE_HASH_MISSING
    require_marker "$build_script" \
        "$legal_hash" \
        SERVER_WEB_CONSOLE_PATCH_IMAGE_DEPENDENCY_LICENSE_HASH_GATE_MISSING
done
require_marker "$build_script" \
    'api_explorer_unchanged=1' \
    SERVER_WEB_CONSOLE_PATCH_API_EXPLORER_REGRESSION_GATE_MISSING
require_marker "$build_script" \
    'critical_runtime_unchanged=1' \
    SERVER_WEB_CONSOLE_PATCH_CRITICAL_REGRESSION_GATE_MISSING
require_marker "$build_script" \
    'websocket_reconnect=single_owner' \
    SERVER_WEB_CONSOLE_PATCH_WEBSOCKET_GATE_MISSING
require_marker "$dockerfile" \
    'ui/models/oidcconfig' \
    SERVER_WEB_CONSOLE_PATCH_OIDC_MODEL_GATE_MISSING
require_marker "$build_script" \
    'oidc_writable_model=1' \
    SERVER_WEB_CONSOLE_PATCH_OIDC_IMAGE_GATE_MISSING
require_marker "$dockerfile" \
    'X-PastureStack-Session-Secret' \
    SERVER_WEB_CONSOLE_PATCH_TERMINAL_PROBE_GATE_MISSING
require_marker "$dockerfile" \
    '"missing"===t?"create"' \
    SERVER_WEB_CONSOLE_PATCH_MISSING_SESSION_RECOVERY_GATE_MISSING
require_marker "$dockerfile" \
    "grep -Fx '  width: 11px;'" \
    SERVER_WEB_CONSOLE_PATCH_RESIZE_HANDLE_WIDTH_GATE_MISSING
require_marker "$dockerfile" \
    "grep -Fx '  height: 11px;'" \
    SERVER_WEB_CONSOLE_PATCH_RESIZE_HANDLE_HEIGHT_GATE_MISSING
require_marker "$build_script" \
    'terminal_recovery=broker_probe' \
    SERVER_WEB_CONSOLE_PATCH_TERMINAL_IMAGE_GATE_MISSING
require_marker "$build_script" \
    'console_broker=unchanged_recoverable_missing_status' \
    SERVER_WEB_CONSOLE_PATCH_BROKER_MISSING_STATUS_GATE_MISSING
require_marker "$build_script" \
    'legacy_catalog_versions=retained' \
    SERVER_WEB_CONSOLE_PATCH_CATALOG_VERSION_GATE_MISSING
for catalog_marker in \
    catalog-version-options \
    upgradeVersionLinks \
    ' (current)' \
    'ui/components/schema/input-enum/template' \
    '["choice"]' \
    'ui/utils/catalog-question-answer' \
    'ui/utils/localized-catalog-field' \
    mergeCatalogLocalizationLabels \
    catalogQuestionLocalizationLabels \
    templateRequestSerial; do
    require_marker "$dockerfile" \
        "$catalog_marker" \
        SERVER_WEB_CONSOLE_PATCH_CATALOG_SELECTION_ARTIFACT_GATE_MISSING
    if [[ "$catalog_marker" == '["choice"]' ]]; then
        require_marker "$build_script" \
            'require_ui_marker "[\"choice\"]"' \
            SERVER_WEB_CONSOLE_PATCH_CATALOG_SELECTION_IMAGE_GATE_MISSING
    else
        require_marker "$build_script" \
            "$catalog_marker" \
            SERVER_WEB_CONSOLE_PATCH_CATALOG_SELECTION_IMAGE_GATE_MISSING
    fi
done
require_marker "$build_script" \
    'catalog_version_select=reactive_upgrade_links' \
    SERVER_WEB_CONSOLE_PATCH_CATALOG_SELECTION_RESULT_MISSING
require_marker "$build_script" \
    'catalog_enum_options=native' \
    SERVER_WEB_CONSOLE_PATCH_CATALOG_ENUM_RESULT_MISSING
require_marker "$build_script" \
    'catalog_required_answers=false_zero_valid' \
    SERVER_WEB_CONSOLE_PATCH_CATALOG_REQUIRED_ANSWER_RESULT_MISSING
require_marker "$build_script" \
    'catalog_revision_localization=target_label_fallback' \
    SERVER_WEB_CONSOLE_PATCH_CATALOG_REVISION_LOCALIZATION_RESULT_MISSING
require_marker "$build_script" \
    'catalog_version_requests=latest_only' \
    SERVER_WEB_CONSOLE_PATCH_CATALOG_VERSION_REQUEST_RESULT_MISSING
require_marker "$build_script" \
    'theme_css=4' \
    SERVER_WEB_CONSOLE_PATCH_THEME_COUNT_GATE_MISSING

digest_coordinate='@''sha256:'
if grep -Fq "$digest_coordinate" "$dockerfile" "$build_script"; then
    echo 'SERVER_WEB_CONSOLE_PATCH_DIGEST_QUALIFIED_RUNTIME_COORDINATE' >&2
    exit 1
fi

if grep -Fq 'console-broker-build' "$dockerfile" || \
   grep -Fq 'COPY --from=console-broker-build' "$dockerfile"; then
    echo 'SERVER_WEB_CONSOLE_PATCH_REBUILDS_UNCHANGED_BROKER' >&2
    exit 1
fi

if grep -RInE '(^|[^[:alnum:]])[A-Za-z]:\\Users\\|/home/[^/[:space:]]+/|(^|[^[:digit:]])10[.][[:digit:]]{1,3}[.][[:digit:]]{1,3}[.][[:digit:]]{1,3}([^[:digit:]]|$)|[[:alnum:]._%+-]+@[[:alnum:].-]+[.][[:alpha:]]{2,}' \
    "$dockerfile" "$build_script"; then
    echo 'SERVER_WEB_CONSOLE_PATCH_PRIVATE_MARKER' >&2
    exit 1
fi

bash -n "$build_script"

printf 'SERVER_WEB_CONSOLE_RUNTIME_PATCH_OK release=v1.6.334 base=v1.6.333 web_console=1.6.56-pasturestack.45 catalog_commit=57707ddf891e36066a144d7821adc458dbf8da9c ember_lts=6.12 websocket_reconnect=single_owner terminal_recovery=recoverable_missing_status resize_handle=11px oidc_writable_model=1 legacy_catalog_versions=retained catalog_version_select=reactive_upgrade_links catalog_enum_options=native catalog_required_answers=false_zero_valid catalog_revision_localization=target_label_fallback catalog_version_requests=latest_only unchanged_broker=1 theme_css=4 legal_sources=8 runtime_digest_coordinates=0\n'

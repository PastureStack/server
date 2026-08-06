#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.port-preflight-runtime-patch
build_script=server/build-port-preflight-runtime-patch-image.sh
release_doc=docs/releases/server-1.6.353.md

for path in "$dockerfile" "$build_script" "$release_doc"; do
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

for marker in \
    'Orchestration Engine: `0.183.281`' \
    'Web Console: `1.6.56-pasturestack.62`' \
    '`volumePreflightInput`' \
    '`volumepreflight`' \
    'real core add-on type set' \
    '`String.prototype.dasherize`' \
    'same-tick volume recheck' \
    '`pasturestack-nfs` driver requires environment scope, `multiHostRW`' \
    'Every successful selected-volume deletion'; do
    require_marker "$release_doc" "$marker" \
        SERVER_VOLUME_PREFLIGHT_PATCH_RELEASE_DOCUMENTATION_MISSING
done

require_marker "$dockerfile" \
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.341' \
    SERVER_PORT_PREFLIGHT_PATCH_BASE_NOT_CURRENT
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.353"' \
    SERVER_PORT_PREFLIGHT_PATCH_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.353' \
    SERVER_PORT_PREFLIGHT_PATCH_RUNTIME_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_PACKAGE=1.6.56-pasturestack.62' \
    SERVER_WEB_CONSOLE_PATCH_PACKAGE_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_ARTIFACT_SHA256=99aed13daa89bccc5043bfc944cf7cbac260f975a4a50ad84274f82542c28f50' \
    SERVER_WEB_CONSOLE_PATCH_HASH_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_COMMIT=d1b59b25be45183a36c76b36c89d55c979fed87e' \
    SERVER_WEB_CONSOLE_PATCH_COMMIT_MISSING
require_marker "$dockerfile" \
    'ARG ORCHESTRATION_ENGINE_RELEASE_TAG=v0.183.281' \
    SERVER_PORT_PREFLIGHT_PATCH_ENGINE_RELEASE_MISSING
require_marker "$dockerfile" \
    'ARG ORCHESTRATION_ENGINE_ARTIFACT_SHA256=da2a8a51562ed16e296f7e29e99482bb44042ff0834cca679bbe01d951ba1682' \
    SERVER_PORT_PREFLIGHT_PATCH_ENGINE_HASH_MISSING
require_marker "$dockerfile" \
    'ARG ORCHESTRATION_ENGINE_COMMIT=17c9b856a8004fb71c64f876ad120942429eb260' \
    SERVER_PORT_PREFLIGHT_PATCH_ENGINE_COMMIT_MISSING
require_marker "$dockerfile" \
    '0\\.183\\.281\\.jar$' \
    SERVER_PORT_PREFLIGHT_PATCH_ENGINE_ENTRY_VERSION_MISSING
if grep -Fq '0\\.183\\.280\\.jar$' "$dockerfile"; then
    echo 'SERVER_PORT_PREFLIGHT_PATCH_STALE_ENGINE_ENTRY_VERSION' >&2
    exit 1
fi
require_marker "$dockerfile" \
    'ARG NODE_AGENT_RELEASE_TAG=v0.13.22' \
    SERVER_PORT_PREFLIGHT_PATCH_NODE_AGENT_RELEASE_MISSING
require_marker "$dockerfile" \
    'ARG NODE_AGENT_COMMIT=d370dc6772aea00381a97769b9bf827f35440656' \
    SERVER_PORT_PREFLIGHT_PATCH_NODE_AGENT_COMMIT_MISSING
require_marker "$dockerfile" \
    'ARG NODE_AGENT_LINUX_ARTIFACT_SHA256=4272c9005ea70c0087668ad9f179bfdc7f277801c938ba55a4fc8c2d1d057b49' \
    SERVER_PORT_PREFLIGHT_PATCH_NODE_AGENT_LINUX_HASH_MISSING
require_marker "$dockerfile" \
    'ARG NODE_AGENT_WINDOWS_ARTIFACT_SHA256=36230c05845c6895988edc06c1d8094cccd66899c2f268e3eb7644ca1e7b7c39' \
    SERVER_PORT_PREFLIGHT_PATCH_NODE_AGENT_WINDOWS_HASH_MISSING
for marker in \
    'PortPreflightActionHandler.class' \
    'PortPreflightService.class' \
    'active_port_conflict_on_other_host' \
    'PortBindingAddress.class' \
    'schema/base/project.json.d/port-preflight.json' \
    'host.port.check'; do
    require_marker "$dockerfile" "$marker" \
        SERVER_PORT_PREFLIGHT_PATCH_ENGINE_ARTIFACT_GATE_MISSING
done
for marker in \
    'for schema_type in VolumePreflightInput VolumePreflightResult VolumePreflightIssue; do' \
    'io/cattle/platform/app/CoreModelConfig.class' \
    'InstanceVolumesValidationFilter.class' \
    'VolumePreflightActionHandler.class' \
    'VolumePreflightInputs.class' \
    'VolumePreflightService.class' \
    'schema/base/project.json.d/volume-preflight.json' \
    'VolumePreflightInput.class' \
    'VolumePreflightIssue.class' \
    'VolumePreflightResult.class' \
    'CoreModelConfig.class' \
    'ServiceValidationFilter.class' \
    'ServiceUpgradeValidationFilter.class'; do
    require_marker "$dockerfile" "$marker" \
        SERVER_VOLUME_PREFLIGHT_PATCH_ENGINE_ARTIFACT_GATE_MISSING
    require_marker "$build_script" "$marker" \
        SERVER_VOLUME_PREFLIGHT_PATCH_ENGINE_IMAGE_GATE_MISSING
done
for marker in \
    '"volumePreflightInput.dataVolumes" : "cr"' \
    '"volumePreflightResult.issues" : "r"' \
    '"volumePreflightInput" : "cr"' \
    '"volumePreflightResult" : "r"' \
    '"volumePreflightIssue" : "r"'; do
    require_marker "$dockerfile" "$marker" \
        SERVER_VOLUME_PREFLIGHT_PATCH_SCHEMA_AUTH_GATE_MISSING
done
for marker in \
    volumePreflightInput.dataVolumes \
    volumePreflightResult.issues \
    'volumePreflightInput\" : \"cr' \
    'volumePreflightResult\" : \"r' \
    'volumePreflightIssue\" : \"r'; do
    require_marker "$build_script" "$marker" \
        SERVER_VOLUME_PREFLIGHT_PATCH_SCHEMA_AUTH_IMAGE_GATE_MISSING
done
for marker in \
    'nfs_incomplete_host_coverage' \
    'pasturestack-nfs 尚未涵蓋所有使用中的主機。'; do
    require_marker "$dockerfile" "$marker" \
        SERVER_VOLUME_PREFLIGHT_PATCH_LOCALIZATION_MISSING
    require_marker "$build_script" "$marker" \
        SERVER_VOLUME_PREFLIGHT_PATCH_LOCALIZATION_IMAGE_GATE_MISSING
done
for localization_marker in \
    'active_port_conflict_on_other_host' \
    '此環境中的另一台主機已使用這個託管網路連接埠。'; do
    require_marker "$dockerfile" "$localization_marker" \
        SERVER_PORT_PREFLIGHT_PATCH_MANAGED_SCOPE_LOCALIZATION_MISSING
    require_marker "$build_script" "$localization_marker" \
        SERVER_PORT_PREFLIGHT_PATCH_MANAGED_SCOPE_IMAGE_GATE_MISSING
done
for authorization_marker in \
    '"portPreflightInput" : "r"' \
    '"portPreflightInput.ports" : "cr"' \
    '"portPreflightResult.conflicts" : "r"' \
    '"portPreflightInput" : "cr"' \
    '"portPreflightPort" : "cr"' \
    '"portPreflightResult" : "r"' \
    '"portPreflightConflict" : "r"'; do
    require_marker "$dockerfile" "$authorization_marker" \
        SERVER_PORT_PREFLIGHT_PATCH_SCHEMA_AUTH_GATE_MISSING
done
for authorization_field in \
    portPreflightInput.ports \
    portPreflightResult.conflicts \
    portPreflightPort \
    portPreflightConflict; do
    require_marker "$build_script" "$authorization_field" \
        SERVER_PORT_PREFLIGHT_PATCH_SCHEMA_AUTH_IMAGE_GATE_MISSING
done
require_marker "$build_script" \
    'port_preflight_schema_auth=project_visible' \
    SERVER_PORT_PREFLIGHT_PATCH_SCHEMA_AUTH_RESULT_MISSING
for marker in \
    'NODE_AGENT_LINUX_ARTIFACT_SHA256' \
    'NODE_AGENT_WINDOWS_ARTIFACT_SHA256' \
    'CATTLE_AGENT_PACKAGE_PYTHON_AGENT_URL' \
    'CATTLE_AGENT_PACKAGE_WINDOWS_AGENT_URL'; do
    require_marker "$dockerfile" "$marker" \
        SERVER_PORT_PREFLIGHT_PATCH_NODE_AGENT_ARTIFACT_GATE_MISSING
done
for marker in portpreflight buildPreflightInput preflightChanged invokePassedAction setPorts volumepreflight volume-path-autocomplete pasturestack-nfs volumePreflightChanged publishPreflightState '([A-Z]+)([A-Z][a-z])' '.dasherize()' 'formVolumes.errors.preflightChecking' 'storageTablePerPage:l(' storagePageSizeChanged pageSizeChanged clampPageToContentLength; do
    require_marker "$dockerfile" "$marker" \
        SERVER_PORT_PREFLIGHT_PATCH_WEB_CONSOLE_GATE_MISSING
    require_marker "$build_script" "$marker" \
        SERVER_PORT_PREFLIGHT_PATCH_WEB_CONSOLE_IMAGE_GATE_MISSING
done
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
for sortable_marker in \
    _filteredShouldChangeContent \
    'arranged.[]' \
    'didReceiveAttrs(){this._super(...arguments),this._syncRequestedPageSize(),this._updateFiltered()}' \
    'run.throttle(this,this._updateFiltered,100,!1)' \
    'run.debounce(this,this._updateFiltered,100,!1)'; do
    require_marker "$dockerfile" \
        "$sortable_marker" \
        SERVER_WEB_CONSOLE_PATCH_SORTABLE_TABLE_ARTIFACT_GATE_MISSING
    require_marker "$build_script" \
        "$sortable_marker" \
        SERVER_WEB_CONSOLE_PATCH_SORTABLE_TABLE_IMAGE_GATE_MISSING
done
require_marker "$dockerfile" \
    '"body","body.[]","arranged.[]","sortBy","descending","sortRevision"' \
    SERVER_WEB_CONSOLE_PATCH_SORTABLE_TABLE_BODY_REPLACEMENT_ARTIFACT_GATE_MISSING
require_marker "$build_script" \
    'require_vendor_marker "\"body\",\"body.[]\",\"arranged.[]\",\"sortBy\",\"descending\",\"sortRevision\""' \
    SERVER_WEB_CONSOLE_PATCH_SORTABLE_TABLE_BODY_REPLACEMENT_IMAGE_GATE_MISSING
require_marker "$build_script" \
    'sortable_table_late_body=refreshed' \
    SERVER_WEB_CONSOLE_PATCH_SORTABLE_TABLE_RESULT_MISSING
require_marker "$build_script" \
    'sortable_table_body_replacement=refreshed' \
    SERVER_WEB_CONSOLE_PATCH_SORTABLE_TABLE_BODY_REPLACEMENT_RESULT_MISSING
require_marker "$build_script" \
    'sortable_table_initial_attrs=refreshed' \
    SERVER_WEB_CONSOLE_PATCH_SORTABLE_TABLE_INITIAL_ATTRS_RESULT_MISSING
for pagination_marker in \
    _pagedOptionsShouldChange \
    '_syncPagedContent(e){let t=this.get' \
    't.get(\"content\")!==e&&t.set(\"content\",e)' \
    't.get(\"page\")!==r&&t.set(\"page\",r)' \
    't.get(\"perPage\")!==n&&t.set(\"perPage\",n)' \
    'this.set(\"filtered\",e),this._syncPagedContent(e)'; do
    require_marker "$dockerfile" \
        "${pagination_marker//\\\"/\"}" \
        SERVER_WEB_CONSOLE_PATCH_PAGED_CONTENT_ARTIFACT_GATE_MISSING
    require_marker "$build_script" \
        "$pagination_marker" \
        SERVER_WEB_CONSOLE_PATCH_PAGED_CONTENT_IMAGE_GATE_MISSING
done
require_marker "$build_script" \
    'sortable_table_paged_content=explicit_sync' \
    SERVER_WEB_CONSOLE_PATCH_PAGED_CONTENT_RESULT_MISSING
require_marker "$build_script" \
    'sortable_table_pagination=explicit_sync' \
    SERVER_WEB_CONSOLE_PATCH_PAGINATION_RESULT_MISSING
for page_size_marker in \
    '_syncRequestedPageSize(){let e=this.get("perPage")' \
    'this._lastRequestedPageSizeInput!==e&&(this._lastRequestedPageSizeInput=e,this._applyRequestedPageSize(e))' \
    'this.setProperties({page:1,effectivePerPage:0===t?this.get("allPageSizeValue"):t,selectedPageSize:t})'; do
    require_marker "$dockerfile" \
        "$page_size_marker" \
        SERVER_WEB_CONSOLE_PATCH_PAGE_SIZE_ARTIFACT_GATE_MISSING
    require_marker "$build_script" \
        "${page_size_marker//\"/\\\"}" \
        SERVER_WEB_CONSOLE_PATCH_PAGE_SIZE_IMAGE_GATE_MISSING
done
require_marker "$dockerfile" \
    'Rejected caller-owned page-size mutation found in Web Console' \
    SERVER_WEB_CONSOLE_PATCH_PAGE_SIZE_MUTATION_REJECTION_MISSING
require_marker "$build_script" \
    'Rejected caller-owned page-size mutation found in image' \
    SERVER_WEB_CONSOLE_PATCH_PAGE_SIZE_IMAGE_MUTATION_REJECTION_MISSING
for storage_marker in \
    storageTableRevision:0 \
    '_removeSuccessfulVolumes(e)' \
    'onRemoved:e=>' \
    'this.get("opts.onRemoved")'; do
    require_marker "$dockerfile" \
        "$storage_marker" \
        SERVER_WEB_CONSOLE_PATCH_STORAGE_REFRESH_ARTIFACT_GATE_MISSING
    require_marker "$build_script" \
        "${storage_marker//\"/\\\"}" \
        SERVER_WEB_CONSOLE_PATCH_STORAGE_REFRESH_IMAGE_GATE_MISSING
done
require_marker "$build_script" \
    'storage_table_page_size_preference=controller_owned_callback' \
    SERVER_WEB_CONSOLE_PATCH_PAGE_SIZE_RESULT_MISSING
require_marker "$build_script" \
    'storage_table_page_clamp=last_valid' \
    SERVER_WEB_CONSOLE_PATCH_PAGE_CLAMP_RESULT_MISSING
require_marker "$build_script" \
    'storage_bulk_remove_refresh=per_success' \
    SERVER_WEB_CONSOLE_PATCH_STORAGE_REFRESH_RESULT_MISSING
require_marker "$dockerfile" \
    'ui/host/containers/route' \
    SERVER_WEB_CONSOLE_PATCH_HOST_CONTAINER_RELATIONSHIP_ARTIFACT_ROUTE_GATE_MISSING
require_marker "$build_script" \
    'ui/host/containers/route' \
    SERVER_WEB_CONSOLE_PATCH_HOST_CONTAINER_RELATIONSHIP_IMAGE_ROUTE_GATE_MISSING
require_marker "$dockerfile" \
    'followLink("instances")' \
    SERVER_WEB_CONSOLE_PATCH_HOST_CONTAINER_RELATIONSHIP_ARTIFACT_LINK_GATE_MISSING
require_marker "$build_script" \
    'followLink(\"instances\")' \
    SERVER_WEB_CONSOLE_PATCH_HOST_CONTAINER_RELATIONSHIP_IMAGE_LINK_GATE_MISSING
require_marker "$build_script" \
    'host_container_relationship=follow_link' \
    SERVER_WEB_CONSOLE_PATCH_HOST_CONTAINER_PRELOAD_RESULT_MISSING
require_marker "$build_script" \
    'theme_css=4' \
    SERVER_WEB_CONSOLE_PATCH_THEME_COUNT_GATE_MISSING
require_marker "$dockerfile" \
    '--prism-code-background: #272822;' \
    SERVER_WEB_CONSOLE_PATCH_CODE_BACKGROUND_GATE_MISSING
require_marker "$dockerfile" \
    'background: var(--prism-code-background);' \
    SERVER_WEB_CONSOLE_PATCH_CODE_SURFACE_GATE_MISSING
require_marker "$build_script" \
    'code_block_contrast=wcag_aa' \
    SERVER_WEB_CONSOLE_PATCH_CODE_CONTRAST_RESULT_MISSING
require_marker "$build_script" \
    'code_block_surface=commonmark_pre' \
    SERVER_WEB_CONSOLE_PATCH_CODE_SURFACE_RESULT_MISSING

digest_coordinate='@''sha256:'
if grep -Fq "$digest_coordinate" "$dockerfile" "$build_script"; then
    echo 'SERVER_PORT_PREFLIGHT_PATCH_DIGEST_QUALIFIED_RUNTIME_COORDINATE' >&2
    exit 1
fi

if grep -Fq 'console-broker-build' "$dockerfile" || \
   grep -Fq 'COPY --from=console-broker-build' "$dockerfile"; then
    echo 'SERVER_PORT_PREFLIGHT_PATCH_REBUILDS_UNCHANGED_BROKER' >&2
    exit 1
fi

if grep -RInE '(^|[^[:alnum:]])[A-Za-z]:\\Users\\|/home/[^/[:space:]]+/|(^|[^[:digit:]])10[.][[:digit:]]{1,3}[.][[:digit:]]{1,3}[.][[:digit:]]{1,3}([^[:digit:]]|$)|[[:alnum:]._%+-]+@[[:alnum:].-]+[.][[:alpha:]]{2,}' \
    "$dockerfile" "$build_script"; then
    echo 'SERVER_PORT_PREFLIGHT_PATCH_PRIVATE_MARKER' >&2
    exit 1
fi

bash -n "$build_script"

printf 'SERVER_PORT_PREFLIGHT_RUNTIME_PATCH_OK release=v1.6.353 base=v1.6.341 engine=0.183.281 node_agent=0.13.22 web_console=1.6.56-pasturestack.62 catalog_commit=57707ddf891e36066a144d7821adc458dbf8da9c port_preflight=authoritative managed_scope=environment bridge_host_scope=selected_host stopped_owner=warning port_preflight_schema_auth=project_visible volume_preflight=authoritative volume_preflight_project_schema=authorized volume_preflight_type_set=registered volume_validation=create_and_upgrade volume_driver=select volume_autocomplete=max8 nfs_contract=environment_multiHostRW_complete_coverage save_validation_string=native node_inspection=host.port.check port_preflight_closure_actions=direct named_port_callback=1 ember_lts=6.12 websocket_reconnect=single_owner terminal_recovery=broker_probe console_broker=unchanged_recoverable_missing_status resize_handle=11px oidc_writable_model=1 legacy_catalog_versions=retained catalog_version_select=reactive_upgrade_links catalog_enum_options=native catalog_required_answers=false_zero_valid catalog_revision_localization=target_label_fallback catalog_version_requests=latest_only sortable_table_late_body=refreshed sortable_table_body_replacement=refreshed sortable_table_initial_attrs=refreshed sortable_table_paged_content=explicit_sync sortable_table_pagination=explicit_sync storage_table_page_size_preference=controller_owned_callback storage_table_page_clamp=last_valid storage_bulk_remove_refresh=per_success host_container_relationship=follow_link unchanged_broker=1 theme_css=4 code_block_contrast=wcag_aa code_block_surface=commonmark_pre legal_sources=8 runtime_digest_coordinates=0\n'

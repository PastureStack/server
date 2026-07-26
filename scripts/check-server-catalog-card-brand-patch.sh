#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.catalog-card-brand-patch
build_script=server/build-catalog-card-brand-patch-image.sh
release_notes=docs/releases/server-1.6.297.md
failures=0

require_marker() {
    local file=$1
    local marker=$2
    local code=$3
    if ! grep -Fq -- "$marker" "$file"; then
        printf '%s file=%s marker=%s\n' "$code" "$file" "$marker"
        failures=$((failures + 1))
    fi
}

reject_marker() {
    local file=$1
    local marker=$2
    local code=$3
    if grep -Fq -- "$marker" "$file"; then
        printf '%s file=%s marker=%s\n' "$code" "$file" "$marker"
        failures=$((failures + 1))
    fi
}

for file in "$dockerfile" "$build_script" "$release_notes"; do
    if [[ ! -f "$file" ]]; then
        printf 'SERVER_CATALOG_CARD_BRAND_FILE_MISSING file=%s\n' "$file"
        failures=$((failures + 1))
    fi
done

if [[ "$failures" -ne 0 ]]; then
    exit 1
fi

require_marker "$dockerfile" \
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.296' \
    SERVER_CATALOG_CARD_BRAND_BASE_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_RELEASE_TAG=v1.6.56-pasturestack.10' \
    SERVER_CATALOG_CARD_BRAND_UI_RELEASE_MISSING
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.297"' \
    SERVER_CATALOG_CARD_BRAND_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_COMMIT=840da39d9d6f3ca35a56c7574ebcb49783d7c3e6' \
    SERVER_CATALOG_CARD_BRAND_UI_COMMIT_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_CATALOG_COMMIT=a44fbf3649165347a4b780159bf5daa92812a53a' \
    SERVER_CATALOG_CARD_BRAND_CATALOG_COMMIT_MISSING
require_marker "$dockerfile" \
    'grep -F '\''catalogDisplayName'\'' "${ui_entry}" >/dev/null' \
    SERVER_CATALOG_CARD_BRAND_DISPLAY_GATE_MISSING
require_marker "$dockerfile" \
    'grep -F '\''"upstreamFirstParty":"PastureStack"'\'' \' \
    SERVER_CATALOG_CARD_BRAND_BADGE_GATE_MISSING
require_marker "$dockerfile" \
    'grep -F '\''"upstreamFirstParty":"上游第一方範本"'\'' \' \
    SERVER_CATALOG_CARD_BRAND_PROVENANCE_GATE_MISSING
require_marker "$dockerfile" \
    'grep -F '\''"childSidekicks":"相關容器"'\'' \' \
    SERVER_CATALOG_CARD_BRAND_SIDEKICKS_GATE_MISSING
require_marker "$build_script" \
    'image=${IMAGE:-pasturestack-validation/server:v1.6.297}' \
    SERVER_CATALOG_CARD_BRAND_BUILD_IMAGE_MISSING
require_marker "$build_script" \
    'catalog_commit=a44fbf3649165347a4b780159bf5daa92812a53a' \
    SERVER_CATALOG_CARD_BRAND_BUILD_CATALOG_COMMIT_MISSING
require_marker "$build_script" \
    'web_console_commit=840da39d9d6f3ca35a56c7574ebcb49783d7c3e6' \
    SERVER_CATALOG_CARD_BRAND_BUILD_UI_COMMIT_MISSING
require_marker "$release_notes" \
    'does not repeat the brand prefix' \
    SERVER_CATALOG_CARD_BRAND_RELEASE_BEHAVIOR_MISSING

for file in "$dockerfile" "$build_script" "$release_notes"; do
    reject_marker "$file" '__WEB_CONSOLE' \
        SERVER_CATALOG_CARD_BRAND_PLACEHOLDER_PRESENT
    reject_marker "$file" '@sha256:' \
        SERVER_CATALOG_CARD_BRAND_OPERATIONAL_DIGEST_PRESENT
    if grep -Eqi \
        '(^|[^0-9])(10[.]|192[.]168[.]|172[.](1[6-9]|2[0-9]|3[01])[.])[0-9]+' \
        "$file"; then
        printf 'SERVER_CATALOG_CARD_BRAND_PRIVATE_ADDRESS_PRESENT file=%s\n' \
            "$file"
        failures=$((failures + 1))
    fi
    if grep -Eqi \
        'C:[\\/]+Users[\\/]+|[[:alnum:]._%+-]+@(gmail|outlook|hotmail)[.]com' \
        "$file"; then
        printf 'SERVER_CATALOG_CARD_BRAND_PERSONAL_MARKER_PRESENT file=%s\n' \
            "$file"
        failures=$((failures + 1))
    fi
done

if ! bash -n "$build_script"; then
    printf 'SERVER_CATALOG_CARD_BRAND_BUILD_SCRIPT_INVALID file=%s\n' \
        "$build_script"
    failures=$((failures + 1))
fi

printf 'server_catalog_card_brand_blocker_count=%s\n' "$failures"
if [[ "$failures" -ne 0 ]]; then
    exit 1
fi

printf 'SERVER_CATALOG_CARD_BRAND_PATCH_OK version=v1.6.297 catalog_templates=23 infra_first_party=22 prefixed_card_names=0\n'

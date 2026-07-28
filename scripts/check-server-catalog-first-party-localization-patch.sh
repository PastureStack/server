#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

dockerfile=server/Dockerfile.catalog-first-party-localization-patch
build_script=server/build-catalog-first-party-localization-patch-image.sh
release_notes=docs/releases/server-1.6.296.md
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
        printf 'SERVER_CATALOG_FIRST_PARTY_FILE_MISSING file=%s\n' "$file"
        failures=$((failures + 1))
    fi
done

if [[ "$failures" -ne 0 ]]; then
    exit 1
fi

require_marker "$dockerfile" \
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.293' \
    SERVER_CATALOG_FIRST_PARTY_BASE_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_RELEASE_TAG=v1.6.56-pasturestack.9' \
    SERVER_CATALOG_FIRST_PARTY_UI_RELEASE_MISSING
require_marker "$dockerfile" \
    'ARG WEB_CONSOLE_ARTIFACT_SHA256=b080f2299aed008e95071ed754163b3761d5399b95e0e2532e7bd2dd1bacb6ba' \
    SERVER_CATALOG_FIRST_PARTY_UI_SHA256_MISSING
require_marker "$dockerfile" \
    'org.opencontainers.image.version="v1.6.296"' \
    SERVER_CATALOG_FIRST_PARTY_VERSION_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_WEB_CONSOLE_COMMIT=894e8e55eddbe22a09907d76efda8d98b6401e1c' \
    SERVER_CATALOG_FIRST_PARTY_UI_COMMIT_MISSING
require_marker "$dockerfile" \
    'ENV PASTURESTACK_CATALOG_COMMIT=8806a61a58c41edbaab22b440b5e2fdbbd16d0b7' \
    SERVER_CATALOG_FIRST_PARTY_CATALOG_COMMIT_MISSING
require_marker "$dockerfile" \
    'grep -F '\''upstream-first-party'\'' "${ui_entry}" >/dev/null' \
    SERVER_CATALOG_FIRST_PARTY_UI_ORIGIN_GATE_MISSING
require_marker "$dockerfile" \
    'grep -F '\''"upstreamFirstParty":"上游第一方範本"'\'' \' \
    SERVER_CATALOG_FIRST_PARTY_TW_ORIGIN_GATE_MISSING
require_marker "$dockerfile" \
    'grep -F '\''"currentMaintenance":"目前維護："'\'' \' \
    SERVER_CATALOG_FIRST_PARTY_TW_MAINTENANCE_GATE_MISSING
require_marker "$build_script" \
    'image=${IMAGE:-pasturestack-validation/server:v1.6.296}' \
    SERVER_CATALOG_FIRST_PARTY_BUILD_IMAGE_MISSING
require_marker "$build_script" \
    'catalog_commit=8806a61a58c41edbaab22b440b5e2fdbbd16d0b7' \
    SERVER_CATALOG_FIRST_PARTY_BUILD_CATALOG_COMMIT_MISSING
require_marker "$build_script" \
    'web_console_commit=894e8e55eddbe22a09907d76efda8d98b6401e1c' \
    SERVER_CATALOG_FIRST_PARTY_BUILD_UI_COMMIT_MISSING
require_marker "$release_notes" \
    'all 171 configuration questions' \
    SERVER_CATALOG_FIRST_PARTY_RELEASE_LOCALIZATION_EVIDENCE_MISSING

for file in "$dockerfile" "$build_script" "$release_notes"; do
    reject_marker "$file" '__WEB_CONSOLE' \
        SERVER_CATALOG_FIRST_PARTY_PLACEHOLDER_PRESENT
    reject_marker "$file" '@sha256:' \
        SERVER_CATALOG_FIRST_PARTY_OPERATIONAL_DIGEST_PRESENT
    if grep -Eqi \
        '(^|[^0-9])(10[.]|192[.]168[.]|172[.](1[6-9]|2[0-9]|3[01])[.])[0-9]+' \
        "$file"; then
        printf 'SERVER_CATALOG_FIRST_PARTY_PRIVATE_ADDRESS_PRESENT file=%s\n' \
            "$file"
        failures=$((failures + 1))
    fi
    if grep -Eqi \
        'C:[\\/]+Users[\\/]+|[[:alnum:]._%+-]+@(gmail|outlook|hotmail)[.]com' \
        "$file"; then
        printf 'SERVER_CATALOG_FIRST_PARTY_PERSONAL_MARKER_PRESENT file=%s\n' \
            "$file"
        failures=$((failures + 1))
    fi
done

if ! bash -n "$build_script"; then
    printf 'SERVER_CATALOG_FIRST_PARTY_BUILD_SCRIPT_INVALID file=%s\n' \
        "$build_script"
    failures=$((failures + 1))
fi

printf 'server_catalog_first_party_localization_blocker_count=%s\n' "$failures"
if [[ "$failures" -ne 0 ]]; then
    exit 1
fi

printf 'SERVER_CATALOG_FIRST_PARTY_LOCALIZATION_PATCH_OK version=v1.6.296 catalog_templates=23 infra_first_party=22 localized_questions=171\n'

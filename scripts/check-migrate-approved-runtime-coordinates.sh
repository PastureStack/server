#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

script=scripts/migrate-approved-runtime-coordinates.sh
test -x "$script" || {
    echo "migration script must be executable: $script" >&2
    exit 1
}

bash -n "$script"
"$script" --help >/dev/null

require_marker() {
    local marker=$1
    local failure=$2
    grep -Fq -- "$marker" "$script" || {
        echo "$failure" >&2
        exit 1
    }
}

require_marker 'ACTION="audit"' DEFAULT_ACTION_MUST_BE_READ_ONLY
require_marker 'apply and rollback' WRITE_ACTION_CONFIRMATION_MISSING
require_marker 'confirm_write' WRITE_CONFIRMATION_GATE_MISSING
require_marker 'START TRANSACTION;' TRANSACTION_MISSING
require_marker 'rollback.sql' ROLLBACK_BUNDLE_MISSING
require_marker 'sha256sum -c SHA256SUMS' ROLLBACK_CHECKSUM_VERIFY_MISSING
require_marker 'duplicate allowlisted setting names' DUPLICATE_SETTING_GUARD_MISSING
require_marker 'ghcr.io/pasturestack/node-agent:v1.2.30@sha256:5310b748fc52bcd87fdeaa2285f424a07ec13c9b41639692eef96bda53ac8277' AGENT_DIGEST_MISSING
require_marker "UPDATE setting SET value='\${APPROVED_AGENT_IMAGE}' WHERE name='agent.image';" AGENT_IMAGE_MIGRATION_MISSING
require_marker 'expected 13 approved persisted coordinates' APPROVED_SETTING_COUNT_NOT_UPDATED
require_marker 'ghcr.io/pasturestack/load-balancer-service:v0.9.23@sha256:3139b2a54688e4e34b24df943a36a2ed1eecc26d53c0ab329bf7ffcb62cdb893' LOAD_BALANCER_DIGEST_MISSING
require_marker 'https://github.com/PastureStack/catalog-templates.git' CATALOG_URL_MISSING
require_marker '91f5910a44cb181051be2adc4c14f0e6ec7842ef' CATALOG_PIN_MISSING
require_marker 'pasturestack-cli-0.6.14-linux-amd64.tar.gz' CLI_ASSET_MISSING
require_marker 'compose-cli-0.14.31-linux-amd64.tar.gz' COMPOSE_ASSET_MISSING
require_marker 'repaired_invalid_values=0' CORRUPTED_SETTING_REPAIR_VERIFY_MISSING
require_marker 'docker buildx imagetools inspect' PLATFORM_MANIFEST_VERIFY_MISSING
require_marker 'git -C "$catalog_tmp" fetch -q --depth=1 "$APPROVED_CATALOG_URL" "$APPROVED_CATALOG_COMMIT"' PINNED_CATALOG_FETCH_VERIFY_MISSING
require_marker 'fetched Catalog commit does not match the approved commit' PINNED_CATALOG_CONTENT_ADDRESS_VERIFY_MISSING

if grep -Eqi 'chen[0-9]+|@[A-Za-z0-9._%+-]+\.com|10\.0\.0\.[0-9]+' "$script"; then
    echo PUBLIC_IDENTITY_OR_PRIVATE_ADDRESS_FOUND >&2
    exit 1
fi

echo MIGRATE_APPROVED_RUNTIME_COORDINATES_CHECK_OK

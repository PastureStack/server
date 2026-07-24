#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

failure_count=0
fail() {
  printf '%s\n' "$1" >&2
  failure_count=$((failure_count + 1))
}

bash -n server/artifacts/verify_release_asset || fail SERVER_RELEASE_ASSET_VERIFIER_SYNTAX_INVALID

sample_run=$(mktemp -d "${TMPDIR:-/tmp}/pasturestack-release-integrity.XXXXXX")
cleanup() {
  rm -rf "$sample_run"
}
trap cleanup EXIT

asset="$sample_run/example-1.0.0.tar.gz"
checksums="$sample_run/SHA256SUMS"
printf 'reviewed release payload\n' >"$asset"
asset_hash=$(sha256sum "$asset" | awk '{print $1}')
printf '%s  %s\n' "$asset_hash" "$(basename "$asset")" >"$checksums"

if ! bash server/artifacts/verify_release_asset "$checksums" "$asset" >/dev/null; then
  fail SERVER_RELEASE_ASSET_VALID_SAMPLE_REJECTED
fi

printf 'tampered\n' >>"$asset"
if bash server/artifacts/verify_release_asset "$checksums" "$asset" >/dev/null 2>&1; then
  fail SERVER_RELEASE_ASSET_TAMPER_ACCEPTED
fi

printf 'reviewed release payload\n' >"$asset"
printf '%s  %s\n' "$asset_hash" "$(basename "$asset")" >>"$checksums"
if bash server/artifacts/verify_release_asset "$checksums" "$asset" >/dev/null 2>&1; then
  fail SERVER_RELEASE_ASSET_DUPLICATE_CHECKSUM_ACCEPTED
fi

if bash server/artifacts/verify_release_asset "$checksums" "$asset" '../unsafe-name' >/dev/null 2>&1; then
  fail SERVER_RELEASE_ASSET_UNSAFE_NAME_ACCEPTED
fi

for file in server/Dockerfile server/Dockerfile.auth-hotfix; do
  if ! grep -Fq 'bash /usr/share/cattle/verify_release_asset' "$file"; then
    fail "SERVER_RELEASE_ASSET_DOCKERFILE_VERIFICATION_MISSING file=${file}"
  fi
done
if ! grep -Fq 'RC16_VERIFY_RELEASE_ASSETS="${RC16_VERIFY_RELEASE_ASSETS:-1}"' server/artifacts/install_cattle_binaries; then
  fail SERVER_RELEASE_ASSET_INSTALLER_FAIL_CLOSED_DEFAULT_MISSING
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

echo 'SERVER_RELEASE_ASSET_INTEGRITY_OK checksum_manifest=1 exact_entry=1 tamper_rejected=1 duplicate_rejected=1 unsafe_name_rejected=1 dockerfiles=2 installer_default=fail_closed'

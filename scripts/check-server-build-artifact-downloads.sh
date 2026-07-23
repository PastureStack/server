#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

failure_count=0

require_marker() {
  local file=$1
  local marker=$2
  local code=$3
  if ! grep -Fq -- "$marker" "$file"; then
    printf '%s file=%s marker=%s\n' "$code" "$file" "$marker"
    failure_count=$((failure_count + 1))
  fi
}

reject_marker() {
  local file=$1
  local marker=$2
  local code=$3
  if grep -Fq -- "$marker" "$file"; then
    printf '%s file=%s marker=%s\n' "$code" "$file" "$marker"
    failure_count=$((failure_count + 1))
  fi
}

require_marker server/build-image.sh 'set -euo pipefail' SERVER_BUILD_IMAGE_STRICT_SHELL_MISSING
require_marker server/build-image.sh 'checksum_tmp=target/release-SHA256SUMS.tmp' SERVER_BUILD_CHECKSUM_TMP_FILE_MISSING
require_marker server/build-image.sh '-o "${checksum_tmp}" "${ARTIFACT_BASE}/SHA256SUMS"' SERVER_BUILD_CHECKSUM_DOWNLOAD_MISSING
require_marker server/build-image.sh 'tmp_file="${S6_OVERLAY_TARGET}.tmp"' SERVER_S6_DOWNLOAD_TMP_FILE_MISSING
require_marker server/build-image.sh 'rm -f "${tmp_file}"' SERVER_S6_DOWNLOAD_TMP_CLEANUP_MISSING
require_marker server/build-image.sh 'curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 \' SERVER_S6_DOWNLOAD_NOT_RETRIED_OR_FAIL_CLOSED
require_marker server/build-image.sh '-o "${tmp_file}" "${ARTIFACT_BASE}/${S6_OVERLAY_ASSET}"' SERVER_S6_DOWNLOAD_NOT_TMP_FILE_BACKED
require_marker server/build-image.sh 'mv "${tmp_file}" "${S6_OVERLAY_TARGET}"' SERVER_S6_DOWNLOAD_NOT_ATOMIC_MOVED
require_marker server/build-image.sh 'bash artifacts/verify_release_asset target/release-SHA256SUMS "${tmp_file}" "${S6_OVERLAY_ASSET}" >/dev/null' SERVER_S6_DOWNLOAD_MANIFEST_SHA256_NOT_VERIFIED
require_marker server/build-image.sh 'echo "${S6_OVERLAY_ARTIFACT_SHA256}  ${tmp_file}" | sha256sum -c -' SERVER_S6_DOWNLOAD_HARD_SHA256_NOT_VERIFIED
require_marker server/build-image.sh 'echo "${S6_OVERLAY_ARTIFACT_SHA256}  ${S6_OVERLAY_TARGET}" | sha256sum -c -' SERVER_S6_CACHE_HARD_SHA256_NOT_VERIFIED
if [ "$(grep -Fc -- '    --provenance=false \' server/build-image.sh)" -ne 2 ]; then
  printf '%s file=%s expected=%s\n' SERVER_REPRODUCIBLE_PROVENANCE_DISABLE_COUNT server/build-image.sh 2
  failure_count=$((failure_count + 1))
fi
require_marker server/build-image.sh 'export SOURCE_DATE_EPOCH="${source_date_epoch}"' SERVER_REPRODUCIBLE_EPOCH_NOT_EXPORTED
if [ "$(grep -Fc -- 'DOCKER_BUILDKIT=1 docker buildx build \' server/build-image.sh)" -ne 2 ]; then
  printf '%s file=%s expected=%s\n' SERVER_REPRODUCIBLE_BUILDX_BUILD_COUNT server/build-image.sh 2
  failure_count=$((failure_count + 1))
fi
if [ "$(grep -Fc -- 'rewrite-timestamp=true,unpack=false' server/build-image.sh)" -ne 2 ]; then
  printf '%s file=%s expected=%s\n' SERVER_REPRODUCIBLE_TIMESTAMP_REWRITE_COUNT server/build-image.sh 2
  failure_count=$((failure_count + 1))
fi
reject_marker server/build-image.sh 'curl -sLf -o target/s6-overlay-amd64-static.tar.gz' SERVER_S6_DOWNLOAD_LEGACY_CURL_FLAGS

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

echo 'SERVER_BUILD_ARTIFACT_DOWNLOADS_OK checksum_manifest=1 s6_overlay_fail_closed=1 retry=5 tmp_file=1 atomic_move=1 manifest_sha256=1 hard_sha256=1 provenance=disabled layer_timestamps=source_date_epoch'

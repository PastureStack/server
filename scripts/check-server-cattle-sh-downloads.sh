#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

failure_count=0

for marker in \
  'if [ -f resources.jar ]; then' \
  'unzip -oq resources.jar' \
  'test -d WEB-INF/lib' \
  'test -f io/cattle/platform/launcher/Main.class'; do
  if ! grep -F -- "$marker" server/artifacts/cattle.sh >/dev/null; then
    printf 'SERVER_CATTLE_SH_EMBEDDED_BUNDLE_MARKER_MISSING marker=%s\n' "$marker" >&2
    failure_count=$((failure_count + 1))
  fi
done

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

require_marker server/artifacts/cattle.sh 'if [ "${URL:-}" != "" ]' SERVER_CATTLE_SH_URL_UNSET_UNSAFE
require_marker server/artifacts/cattle.sh 'TMP_JAR="${DOWNLOADED_JAR}.tmp"' SERVER_CATTLE_SH_DOWNLOAD_TMP_MISSING
require_marker server/artifacts/cattle.sh 'rm -f "$TMP_JAR"' SERVER_CATTLE_SH_DOWNLOAD_TMP_CLEANUP_MISSING
require_marker server/artifacts/cattle.sh 'curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o "$TMP_JAR" "$URL"' SERVER_CATTLE_SH_DOWNLOAD_NOT_RETRIED_OR_FAIL_CLOSED
require_marker server/artifacts/cattle.sh 'mv "$TMP_JAR" "$DOWNLOADED_JAR"' SERVER_CATTLE_SH_DOWNLOAD_NOT_ATOMIC_MOVED
require_marker server/artifacts/cattle.sh 'HASH=$(sha256sum "$JAR" | awk' SERVER_CATTLE_SH_HASH_RECOMPUTE_MISSING
require_marker server/artifacts/cattle.sh 'HASH_PATH=$(dirname "$JAR")/$HASH' SERVER_CATTLE_SH_HASH_PATH_UNQUOTED
require_marker server/artifacts/cattle.sh 'local docker_tgz=/tmp/rc16-docker-29.4.0.tgz' SERVER_CATTLE_SH_DOCKER_DOWNLOAD_TMP_MISSING
require_marker server/artifacts/cattle.sh 'curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 \' SERVER_CATTLE_SH_DOCKER_DOWNLOAD_NOT_RETRIED_OR_FAIL_CLOSED
require_marker server/artifacts/cattle.sh '-o "$docker_tgz" https://download.docker.com/linux/static/stable/x86_64/docker-29.4.0.tgz' SERVER_CATTLE_SH_DOCKER_DOWNLOAD_NOT_FILE_BACKED
require_marker server/artifacts/cattle.sh 'tar xzf "$docker_tgz" -C /usr/bin --strip-components=1 docker/docker' SERVER_CATTLE_SH_DOCKER_TAR_NOT_FILE_BACKED
require_marker server/artifacts/cattle.sh 'rm -f "$docker_tgz"' SERVER_CATTLE_SH_DOCKER_DOWNLOAD_TMP_CLEANUP_MISSING
reject_marker server/artifacts/cattle.sh 'curl -sLf $URL > cattle-download.jar' SERVER_CATTLE_SH_LEGACY_URL_DOWNLOAD
reject_marker server/artifacts/cattle.sh 'curl -sfL https://download.docker.com/linux/static/stable/x86_64/docker-29.4.0.tgz | \' SERVER_CATTLE_SH_LEGACY_DOCKER_PIPE_DOWNLOAD

hash_line=$(grep -n -F 'HASH=$(sha256sum "$JAR" | awk' server/artifacts/cattle.sh | cut -d: -f1 | tail -1)
debug_line=$(grep -n -F 'if [ -e "$DEBUG_JAR" ]; then' server/artifacts/cattle.sh | cut -d: -f1 | tail -1)
if [ -z "$hash_line" ] || [ -z "$debug_line" ] || [ "$hash_line" -le "$debug_line" ]; then
  printf 'SERVER_CATTLE_SH_HASH_NOT_AFTER_JAR_SELECTION hash_line=%s debug_line=%s\n' "${hash_line:-missing}" "${debug_line:-missing}"
  failure_count=$((failure_count + 1))
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

echo 'SERVER_CATTLE_SH_DOWNLOADS_OK url_download_fail_closed=1 tmp_file=1 atomic_move=1 hash_after_jar_selection=1 docker_fallback_fail_closed=1 embedded_bundle_expansion=1'

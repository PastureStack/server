#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

failures=0

dockerfile_cattle_version=$(
  sed -n 's/^ENV CATTLE_CATTLE_VERSION=\([^[:space:]]*\)$/\1/p' server/Dockerfile | tail -n 1
)
expected_cattle_version="${RC16_EXPECTED_CATTLE_VERSION:-$dockerfile_cattle_version}"
engine_version="${expected_cattle_version#v}"
release_file="docs/releases/orchestration-engine-${engine_version}.md"

fail() {
  printf '%s\n' "$1" >&2
  failures=$((failures + 1))
}

require_marker() {
  local marker=$1
  local code=$2
  if ! grep -Fq "$marker" "$release_file"; then
    fail "${code} file=${release_file} marker=${marker}"
  fi
}

if [ -z "$expected_cattle_version" ]; then
  fail "SERVER_CATTLE_VERSION_UNRESOLVED file=server/Dockerfile"
elif [ ! -f "$release_file" ]; then
  fail "SERVER_CATTLE_RELEASE_EVIDENCE_MISSING file=${release_file}"
else
  require_marker 'CATTLE_JDK25_FULL_PACKAGE_OK' SERVER_CATTLE_RELEASE_FULL_PACKAGE_MARKER_MISSING
  require_marker 'bytecode major `69`' SERVER_CATTLE_RELEASE_BYTECODE_MARKER_MISSING
  require_marker 'packaged-lib hygiene OK' SERVER_CATTLE_RELEASE_PACKAGED_LIB_MARKER_MISSING
  require_marker 'standalone startup OK' SERVER_CATTLE_RELEASE_STANDALONE_MARKER_MISSING
  require_marker 'failure_count=0' SERVER_CATTLE_RELEASE_FAILURE_COUNT_MARKER_MISSING
  require_marker "orchestration-engine-${engine_version}.jar" SERVER_ENGINE_RELEASE_PRIMARY_ARTIFACT_SHA_MISSING
  require_marker "orchestration-engine-auth-logic-${engine_version}.jar" SERVER_ENGINE_RELEASE_AUTH_ARTIFACT_SHA_MISSING
fi

printf 'failure_count=%s\n' "$failures"
if [ "$failures" -ne 0 ]; then
  exit 1
fi

printf 'SERVER_ENGINE_JDK25_RELEASE_EVIDENCE_OK engine=%s release_file=%s full_package=1 bytecode_major=69 packaged_lib_hygiene=1 standalone=1 artifact_sha=1\n' \
  "$engine_version" "$release_file"

#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

failure_count=0

fail() {
  printf '%s\n' "$1" >&2
  failure_count=$((failure_count + 1))
}

dockerfile_cattle_version=$(
  sed -n 's/^ENV CATTLE_CATTLE_VERSION=\([^[:space:]]*\)$/\1/p' server/Dockerfile | tail -n 1
)
expected_cattle_version="${RC16_EXPECTED_CATTLE_VERSION:-$dockerfile_cattle_version}"
artifact_base="${RC16_ARTIFACT_BASE_URL:-}"

if [ -z "$expected_cattle_version" ]; then
  fail "SERVER_CATTLE_VERSION_UNRESOLVED file=server/Dockerfile"
fi

if [ -z "$artifact_base" ]; then
  if [ "${RC16_REQUIRE_CATTLE_ARTIFACT_MIRROR:-0}" = "1" ]; then
    fail "SERVER_CATTLE_ARTIFACT_MIRROR_BASE_UNSET env=RC16_ARTIFACT_BASE_URL"
  else
    printf 'failure_count=%s\n' "$failure_count"
    if [ "$failure_count" -ne 0 ]; then
      exit 1
    fi
    printf 'SERVER_CATTLE_ARTIFACT_MIRROR_SKIPPED cattle=%s reason=RC16_ARTIFACT_BASE_URL_unset\n' "$expected_cattle_version"
    exit 0
  fi
fi

if [ "$failure_count" -ne 0 ]; then
  printf 'failure_count=%s\n' "$failure_count"
  exit 1
fi

artifact_base="${artifact_base%/}"
workdir=$(mktemp -d "${TMPDIR:-/tmp}/rc16-cattle-artifact-mirror.XXXXXX")
trap 'rm -rf "$workdir"' EXIT

download() {
  local name=$1
  local url="${artifact_base}/${name}"
  local target="${workdir}/${name}"

  if ! curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 \
      -o "$target" "$url"; then
    fail "SERVER_CATTLE_ARTIFACT_MIRROR_DOWNLOAD_FAILED url=${url}"
    return
  fi
}

engine_version="${expected_cattle_version#v}"
primary_artifact="orchestration-engine-${engine_version}.jar"
auth_artifact="orchestration-engine-auth-logic-${engine_version}.jar"
sha_artifact="SHA256SUMS"

download "$sha_artifact"
download "$primary_artifact"
download "$auth_artifact"

if [ "$failure_count" -eq 0 ]; then
  if ! grep -Eq "^[0-9a-f]{64}[[:space:]]+${primary_artifact}$" "${workdir}/${sha_artifact}"; then
    fail "SERVER_CATTLE_ARTIFACT_MIRROR_PRIMARY_SHA_ENTRY_MISSING file=${sha_artifact} artifact=${primary_artifact}"
  fi
  if ! grep -Eq "^[0-9a-f]{64}[[:space:]]+${auth_artifact}$" "${workdir}/${sha_artifact}"; then
    fail "SERVER_CATTLE_ARTIFACT_MIRROR_AUTH_SHA_ENTRY_MISSING file=${sha_artifact} artifact=${auth_artifact}"
  fi
fi

if [ "$failure_count" -eq 0 ]; then
  selected_checksums="${workdir}/selected-SHA256SUMS"
  awk -v primary="$primary_artifact" -v auth="$auth_artifact" '
    $2 == primary || $2 == auth { print }
  ' "${workdir}/${sha_artifact}" >"$selected_checksums"
  if [ "$(wc -l <"$selected_checksums")" -ne 2 ]; then
    fail "SERVER_CATTLE_ARTIFACT_MIRROR_SELECTED_SHA_COUNT_INVALID file=${sha_artifact}"
  elif ! (
    cd "$workdir"
    sha256sum -c "$(basename "$selected_checksums")"
  ); then
    fail "SERVER_CATTLE_ARTIFACT_MIRROR_SHA256_MISMATCH file=${sha_artifact}"
  fi
fi

if [ "$failure_count" -eq 0 ]; then
  archive_listing="${workdir}/${primary_artifact}.listing"
  if command -v unzip >/dev/null 2>&1; then
    unzip -l "${workdir}/${primary_artifact}" > "$archive_listing" ||
      fail "SERVER_CATTLE_ARTIFACT_MIRROR_PRIMARY_ARCHIVE_UNREADABLE artifact=${primary_artifact}"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "${workdir}/${primary_artifact}" > "$archive_listing" <<'PY' ||
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    for name in archive.namelist():
        print(name)
PY
      fail "SERVER_CATTLE_ARTIFACT_MIRROR_PRIMARY_ARCHIVE_UNREADABLE artifact=${primary_artifact}"
  else
    fail "SERVER_CATTLE_ARTIFACT_MIRROR_ARCHIVE_LISTER_MISSING tools=unzip,python3"
  fi
fi

if [ "$failure_count" -eq 0 ]; then
    for entry in \
      "WEB-INF/lib/cattle-resources-${engine_version}.jar" \
      "WEB-INF/lib/cattle-iaas-auth-logic-${engine_version}.jar" \
      "WEB-INF/web.xml"
    do
      if ! grep -Fq "$entry" "$archive_listing"; then
        fail "SERVER_CATTLE_ARTIFACT_MIRROR_PRIMARY_WEBAPP_ENTRY_MISSING artifact=${primary_artifact} entry=${entry}"
      fi
    done
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'SERVER_CATTLE_ARTIFACT_MIRROR_OK cattle=%s base=%s artifacts=%s,%s sha=%s primary_webapp=1\n' \
  "$expected_cattle_version" "$artifact_base" "$primary_artifact" "$auth_artifact" "$sha_artifact"

#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

artifact="${PASTURESTACK_RUNTIME_LICENSE_BUNDLE:-}"
expected_version="${PASTURESTACK_EXPECTED_RUNTIME_LICENSE_BUNDLE_VERSION:-1.6.270}"
expected_sha256="${PASTURESTACK_EXPECTED_RUNTIME_LICENSE_BUNDLE_SHA256:-dbf6566fd0182e5ed35dc8dc3a292f9dcc9e0f7d1861054814b33343f42145ba}"
expected_name="pasturestack-runtime-licenses-${expected_version}.tar.xz"
expected_root="pasturestack-runtime-licenses-${expected_version}"

if [ -z "$artifact" ]; then
  if [ "${RC16_REQUIRE_RUNTIME_LICENSE_BUNDLE:-0}" = "1" ]; then
    echo 'SERVER_RUNTIME_LICENSE_BUNDLE_PATH_UNSET env=PASTURESTACK_RUNTIME_LICENSE_BUNDLE' >&2
    exit 1
  fi
  printf 'SERVER_RUNTIME_LICENSE_BUNDLE_SKIPPED version=%s reason=PASTURESTACK_RUNTIME_LICENSE_BUNDLE_unset\n' "$expected_version"
  exit 0
fi

test -f "$artifact"
test "$(basename "$artifact")" = "$expected_name"
actual_sha256=$(sha256sum "$artifact" | awk '{print $1}')
test "$actual_sha256" = "$expected_sha256"

if tar -tJf "$artifact" | grep -E '(^/|(^|/)\.\.(/|$))' >/dev/null; then
  echo 'SERVER_RUNTIME_LICENSE_BUNDLE_UNSAFE_MEMBER' >&2
  exit 1
fi
if tar -tJf "$artifact" | grep -v -E "^${expected_root}(/|$)" >/dev/null; then
  echo 'SERVER_RUNTIME_LICENSE_BUNDLE_MULTIPLE_ROOTS' >&2
  exit 1
fi

workdir=$(mktemp -d "${TMPDIR:-/tmp}/pasturestack-runtime-license-gate.XXXXXX")
cleanup()
{
  rm -rf "$workdir"
}
trap cleanup EXIT
tar -xJf "$artifact" -C "$workdir"
bundle_root="$workdir/$expected_root"

test -f "$bundle_root/README.md"
test -f "$bundle_root/SOURCES.tsv"
test -f "$bundle_root/FILES.sha256"
cmp -s release/runtime-components.tsv "$bundle_root/SOURCES.tsv"
(cd "$bundle_root" && sha256sum -c FILES.sha256 >/dev/null)

asset_count=$(($(wc -l <release/runtime-components.tsv) - 1))
test "$asset_count" -eq 21
test "$(tail -n +2 release/runtime-components.tsv | cut -f1 | sort -u | wc -l)" -eq "$asset_count"
test "$(find "$bundle_root/source-legal" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 19
test "$(find "$bundle_root" -type f | wc -l)" -ge 300
test -f "$bundle_root/source-legal/server/LICENSE"
test -f "$bundle_root/source-legal/graphite-exporter/LICENSE"
test -f "$bundle_root/source-legal/s6-overlay/LICENSE.md"
test -f "$bundle_root/source-legal/orchestration-engine/third-party/HAZELCAST.md"
test -f "$bundle_root/embedded-asset-legal/graphite_exporter-0.2.0.linux-amd64.tar.gz/graphite_exporter-0.2.0.linux-amd64/NOTICE"
test -f "$bundle_root/embedded-asset-legal/orchestration-engine-0.183.269.jar/nested/WEB-INF/lib/hazelcast-5.7.0-pasturestack.1.jar/META-INF/NOTICE"
test -f "$bundle_root/embedded-asset-legal/orchestration-engine-0.183.269.jar/nested/WEB-INF/lib/hazelcast-5.7.0-pasturestack.1.jar/LICENSE-ClassGraph.txt"

while IFS=$'\t' read -r asset component repository commit license_summary; do
  if [ "$asset" = asset ]; then
    continue
  fi
  test -d "$bundle_root/source-legal/$component"
  test -n "$(find "$bundle_root/source-legal/$component" -type f -print -quit)"
done <release/runtime-components.tsv

if grep -R -I -n -E 'C:\\Users\\|/home/[^/]+/|(^|[^0-9])(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3})([^0-9]|$)' "$bundle_root"; then
  echo 'SERVER_RUNTIME_LICENSE_BUNDLE_PRIVATE_MARKER_PRESENT' >&2
  exit 1
fi

printf 'SERVER_RUNTIME_LICENSE_BUNDLE_OK version=%s sha256=%s assets=%s source_components=18 server_legal=1 embedded_legal=1 nested_jar_legal=1 internal_hashes=valid private_markers=0\n' \
  "$expected_version" "$actual_sha256" "$asset_count"

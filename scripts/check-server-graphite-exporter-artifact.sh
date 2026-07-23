#!/usr/bin/env bash
set -euo pipefail

artifact="${PASTURESTACK_GRAPHITE_EXPORTER_ARTIFACT:-}"
expected_version="${PASTURESTACK_EXPECTED_GRAPHITE_EXPORTER_VERSION:-0.2.0}"
expected_artifact_sha256="${PASTURESTACK_EXPECTED_GRAPHITE_EXPORTER_ARTIFACT_SHA256:-1058b72a73f568adc24191f74e972ed6be0d932b9a80f43a7043e4e3d0501388}"
expected_binary_sha256="${PASTURESTACK_EXPECTED_GRAPHITE_EXPORTER_BINARY_SHA256:-a27df929e213a3e87adf057f3af2f9bb6d4b8c92d49c1795e6a79bd117f0e5d9}"
expected_license_sha256="${PASTURESTACK_EXPECTED_GRAPHITE_EXPORTER_LICENSE_SHA256:-c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4}"
expected_notice_sha256="${PASTURESTACK_EXPECTED_GRAPHITE_EXPORTER_NOTICE_SHA256:-50a135fbddd0f0e3ede477d948e1b9c613688ba9ec22f6c8a059b434d94b4c92}"
expected_source_commit="${PASTURESTACK_EXPECTED_GRAPHITE_EXPORTER_SOURCE_COMMIT:-e76b500729ba944f7370d58c43f431632da339e5}"
expected_name="graphite_exporter-${expected_version}.linux-amd64.tar.gz"
archive_root="graphite_exporter-${expected_version}.linux-amd64"

if [ -z "$artifact" ]; then
  if [ "${RC16_REQUIRE_GRAPHITE_EXPORTER_ARTIFACT:-0}" = "1" ]; then
    echo 'SERVER_GRAPHITE_EXPORTER_ARTIFACT_PATH_UNSET env=PASTURESTACK_GRAPHITE_EXPORTER_ARTIFACT' >&2
    exit 1
  fi
  printf 'SERVER_GRAPHITE_EXPORTER_ARTIFACT_SKIPPED version=%s reason=PASTURESTACK_GRAPHITE_EXPORTER_ARTIFACT_unset\n' "$expected_version"
  exit 0
fi

if [ ! -f "$artifact" ]; then
  printf 'SERVER_GRAPHITE_EXPORTER_ARTIFACT_MISSING path=%s\n' "$artifact" >&2
  exit 1
fi
if [ "$(basename "$artifact")" != "$expected_name" ]; then
  printf 'SERVER_GRAPHITE_EXPORTER_ARTIFACT_NAME_MISMATCH actual=%s expected=%s\n' "$(basename "$artifact")" "$expected_name" >&2
  exit 1
fi

actual_artifact_sha256=$(sha256sum "$artifact" | awk '{print $1}')
if [ "$actual_artifact_sha256" != "$expected_artifact_sha256" ]; then
  printf 'SERVER_GRAPHITE_EXPORTER_ARTIFACT_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_artifact_sha256" "$expected_artifact_sha256" >&2
  exit 1
fi

expected_entries=$(printf '%s\n' \
  "${archive_root}/" \
  "${archive_root}/LICENSE" \
  "${archive_root}/NOTICE" \
  "${archive_root}/graphite_exporter")
actual_entries=$(tar -tzf "$artifact")
if [ "$actual_entries" != "$expected_entries" ]; then
  printf 'SERVER_GRAPHITE_EXPORTER_LAYOUT_MISMATCH\nactual:\n%s\nexpected:\n%s\n' "$actual_entries" "$expected_entries" >&2
  exit 1
fi

workdir=$(mktemp -d "${TMPDIR:-/tmp}/pasturestack-graphite-exporter-server-gate.XXXXXX")
cleanup()
{
  rm -rf "$workdir"
}
trap cleanup EXIT
tar -xzf "$artifact" -C "$workdir"

binary="$workdir/$archive_root/graphite_exporter"
license="$workdir/$archive_root/LICENSE"
notice="$workdir/$archive_root/NOTICE"
test -x "$binary"
test "$(sha256sum "$binary" | awk '{print $1}')" = "$expected_binary_sha256"
test "$(sha256sum "$license" | awk '{print $1}')" = "$expected_license_sha256"
test "$(sha256sum "$notice" | awk '{print $1}')" = "$expected_notice_sha256"
file "$binary" | grep -F 'ELF 64-bit LSB executable, x86-64' >/dev/null
file "$binary" | grep -F 'statically linked' >/dev/null
"$binary" --version 2>&1 | grep -F "graphite_exporter, version ${expected_version} (branch: master, revision: ${expected_source_commit})" >/dev/null
grep -F 'Apache License' "$license" >/dev/null
grep -F 'Prometheus Authors' "$notice" >/dev/null

printf 'SERVER_GRAPHITE_EXPORTER_ARTIFACT_OK version=%s artifact_sha256=%s binary_sha256=%s source=%s upstream_asset=unchanged license=Apache-2.0 notice=present\n' \
  "$expected_version" "$actual_artifact_sha256" "$expected_binary_sha256" "$expected_source_commit"

#!/usr/bin/env bash
set -euo pipefail

artifact="${PASTURESTACK_VSPHERE_CLI_BUNDLE_ARTIFACT:-}"
expected_version="${PASTURESTACK_EXPECTED_VSPHERE_CLI_BUNDLE_VERSION:-0.54.1}"
expected_artifact_sha256="${PASTURESTACK_EXPECTED_VSPHERE_CLI_BUNDLE_ARTIFACT_SHA256:-010e5166afe5e17c98e15cc4528a9003f09caa4a3ef3ccee9c751e7b3ef2e0e5}"
expected_binary_sha256="${PASTURESTACK_EXPECTED_GOVC_BINARY_SHA256:-115af2599f9c9939ee44cbd8218e5fe70e42d7957fd66f1ecad4148a1b980e2a}"
expected_source_commit="${PASTURESTACK_EXPECTED_GOVMOMI_COMMIT:-e6cfff79a15f1c7e7a59187985132ee1685b8233}"
expected_license_sha256="${PASTURESTACK_EXPECTED_GOVMOMI_LICENSE_SHA256:-cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30}"
expected_name="vsphere-cli-bundle-${expected_version}-linux-amd64.tar.xz"

if [ -z "$artifact" ]; then
  if [ "${RC16_REQUIRE_VSPHERE_CLI_BUNDLE_ARTIFACT:-0}" = "1" ]; then
    echo 'SERVER_VSPHERE_CLI_BUNDLE_ARTIFACT_PATH_UNSET env=PASTURESTACK_VSPHERE_CLI_BUNDLE_ARTIFACT' >&2
    exit 1
  fi
  printf 'SERVER_VSPHERE_CLI_BUNDLE_ARTIFACT_SKIPPED version=%s reason=PASTURESTACK_VSPHERE_CLI_BUNDLE_ARTIFACT_unset\n' "$expected_version"
  exit 0
fi

if [ ! -f "$artifact" ]; then
  printf 'SERVER_VSPHERE_CLI_BUNDLE_ARTIFACT_MISSING path=%s\n' "$artifact" >&2
  exit 1
fi

if [ "$(basename "$artifact")" != "$expected_name" ]; then
  printf 'SERVER_VSPHERE_CLI_BUNDLE_ARTIFACT_NAME_MISMATCH actual=%s expected=%s\n' "$(basename "$artifact")" "$expected_name" >&2
  exit 1
fi

actual_artifact_sha256=$(sha256sum "$artifact" | awk '{print $1}')
if [ "$actual_artifact_sha256" != "$expected_artifact_sha256" ]; then
  printf 'SERVER_VSPHERE_CLI_BUNDLE_ARTIFACT_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_artifact_sha256" "$expected_artifact_sha256" >&2
  exit 1
fi

expected_entries=$(printf '%s\n' \
  govc \
  vsphere-cli-bundle-LICENSES.txt \
  vsphere-cli-bundle-SOURCES.txt \
  vsphere-cli-bundle-THIRD-PARTY-NOTICES.txt)
actual_entries=$(tar -tJf "$artifact")
if [ "$actual_entries" != "$expected_entries" ]; then
  printf 'SERVER_VSPHERE_CLI_BUNDLE_LAYOUT_MISMATCH\nactual:\n%s\nexpected:\n%s\n' "$actual_entries" "$expected_entries" >&2
  exit 1
fi

workdir=$(mktemp -d "${TMPDIR:-/tmp}/pasturestack-vsphere-cli-server-gate.XXXXXX")
trap 'rm -rf "$workdir"' EXIT
tar -xJf "$artifact" -C "$workdir"

binary="$workdir/govc"
actual_binary_sha256=$(sha256sum "$binary" | awk '{print $1}')
test "$actual_binary_sha256" = "$expected_binary_sha256"
file "$binary" | grep -F 'ELF 64-bit LSB executable, x86-64' >/dev/null
file "$binary" | grep -F 'statically linked' >/dev/null
file "$binary" | grep -F 'stripped' >/dev/null

test "$("$binary" version)" = "govc ${expected_version}"
"$binary" version -require "$expected_version" >/dev/null
version_long=$("$binary" version -l)
printf '%s\n' "$version_long" | grep -Fx "Build Version: v${expected_version}" >/dev/null
printf '%s\n' "$version_long" | grep -Fx 'Build Commit: e6cfff79a15f' >/dev/null
printf '%s\n' "$version_long" | grep -Fx 'Build Date: 2026-05-29T18:14:11Z' >/dev/null
"$binary" about -h >/dev/null

licenses="$workdir/vsphere-cli-bundle-LICENSES.txt"
sources="$workdir/vsphere-cli-bundle-SOURCES.txt"
notices="$workdir/vsphere-cli-bundle-THIRD-PARTY-NOTICES.txt"
grep -F 'MIT License' "$licenses" >/dev/null
grep -F 'Apache License' "$licenses" >/dev/null
grep -F "Commit: ${expected_source_commit}" "$sources" >/dev/null
grep -F "License SHA-256: ${expected_license_sha256}" "$sources" >/dev/null
grep -F "Binary SHA-256: ${expected_binary_sha256}" "$sources" >/dev/null
grep -F 'does not claim' "$notices" >/dev/null

printf 'SERVER_VSPHERE_CLI_BUNDLE_ARTIFACT_OK version=%s artifact_sha256=%s binary_sha256=%s source=%s neutral_asset=1 reproducible=1 licenses=2 command_smoke=1 live_vsphere_lifecycle=pending\n' \
  "$expected_version" "$actual_artifact_sha256" "$actual_binary_sha256" "$expected_source_commit"

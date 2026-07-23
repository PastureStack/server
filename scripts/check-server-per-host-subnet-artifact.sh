#!/usr/bin/env bash
set -euo pipefail

artifact="${PASTURESTACK_PER_HOST_SUBNET_WINDOWS_ARTIFACT:-}"
expected_version="${PASTURESTACK_EXPECTED_PER_HOST_SUBNET_VERSION:-0.2.4}"
expected_artifact_sha256="${PASTURESTACK_EXPECTED_PER_HOST_SUBNET_WINDOWS_ARTIFACT_SHA256:-2521cb61c0e001f2d6b4c16e920d2f62180a1bdf63e62f70544e2abdc24f9e2b}"
expected_binary_sha256="${PASTURESTACK_EXPECTED_PER_HOST_SUBNET_WINDOWS_BINARY_SHA256:-2f6f44abbfe87cce1a89d104efcb211b5eb8b32e7d0d95a3a9830a7e6d99a32e}"
expected_startup_sha256="${PASTURESTACK_EXPECTED_PER_HOST_SUBNET_WINDOWS_STARTUP_SHA256:-f22b41f18d1733c037babed4d2e0474efeedc6017a96849d4309dd864f5f86d1}"
expected_name="per-host-subnet-${expected_version}-windows-amd64.zip"

if [ -z "$artifact" ]; then
  if [ "${RC16_REQUIRE_PER_HOST_SUBNET_ARTIFACT:-0}" = "1" ]; then
    echo 'SERVER_PER_HOST_SUBNET_ARTIFACT_PATH_UNSET env=PASTURESTACK_PER_HOST_SUBNET_WINDOWS_ARTIFACT' >&2
    exit 1
  fi
  printf 'SERVER_PER_HOST_SUBNET_ARTIFACT_SKIPPED version=%s reason=PASTURESTACK_PER_HOST_SUBNET_WINDOWS_ARTIFACT_unset\n' "$expected_version"
  exit 0
fi

if [ ! -f "$artifact" ]; then
  printf 'SERVER_PER_HOST_SUBNET_ARTIFACT_MISSING path=%s\n' "$artifact" >&2
  exit 1
fi

if [ "$(basename "$artifact")" != "$expected_name" ]; then
  printf 'SERVER_PER_HOST_SUBNET_ARTIFACT_NAME_MISMATCH actual=%s expected=%s\n' "$(basename "$artifact")" "$expected_name" >&2
  exit 1
fi

actual_artifact_sha256=$(sha256sum "$artifact" | awk '{print $1}')
if [ "$actual_artifact_sha256" != "$expected_artifact_sha256" ]; then
  printf 'SERVER_PER_HOST_SUBNET_ARTIFACT_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_artifact_sha256" "$expected_artifact_sha256" >&2
  exit 1
fi

workdir=$(mktemp -d "${TMPDIR:-/tmp}/pasturestack-per-host-subnet.XXXXXX")
trap 'rm -rf "$workdir"' EXIT

# The legacy directory is retained only because the Windows agent extracts this
# established include layout. It is not an external asset or current brand name.
compatibility_root="rancher"
expected_entries=$(printf '%s\n' \
  "${compatibility_root}/" \
  "${compatibility_root}/per-host-subnet.exe" \
  "${compatibility_root}/startup_per-host-subnet.ps1")
actual_entries=$(unzip -Z1 "$artifact")
if [ "$actual_entries" != "$expected_entries" ]; then
  printf 'SERVER_PER_HOST_SUBNET_ZIP_LAYOUT_MISMATCH\nactual:\n%s\nexpected:\n%s\n' "$actual_entries" "$expected_entries" >&2
  exit 1
fi

unzip -qq "$artifact" -d "$workdir"
binary="$workdir/${compatibility_root}/per-host-subnet.exe"
startup="$workdir/${compatibility_root}/startup_per-host-subnet.ps1"

actual_binary_sha256=$(sha256sum "$binary" | awk '{print $1}')
if [ "$actual_binary_sha256" != "$expected_binary_sha256" ]; then
  printf 'SERVER_PER_HOST_SUBNET_BINARY_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_binary_sha256" "$expected_binary_sha256" >&2
  exit 1
fi

actual_startup_sha256=$(sha256sum "$startup" | awk '{print $1}')
if [ "$actual_startup_sha256" != "$expected_startup_sha256" ]; then
  printf 'SERVER_PER_HOST_SUBNET_STARTUP_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_startup_sha256" "$expected_startup_sha256" >&2
  exit 1
fi

file "$binary" | grep -F 'PE32+ executable' >/dev/null
file "$binary" | grep -F 'x86-64' >/dev/null
LC_ALL=C grep -aF "v${expected_version}" "$binary" >/dev/null

printf 'SERVER_PER_HOST_SUBNET_ARTIFACT_OK version=%s artifact_sha256=%s binary_sha256=%s startup_sha256=%s neutral_asset=1 windows_amd64=1 compatibility_layout=1 runtime_validation=pending\n' \
  "$expected_version" "$actual_artifact_sha256" "$actual_binary_sha256" "$actual_startup_sha256"

#!/usr/bin/env bash
set -euo pipefail

artifact="${PASTURESTACK_HOST_PROVISIONER_ARTIFACT:-}"
expected_version="${PASTURESTACK_EXPECTED_HOST_PROVISIONER_VERSION:-0.39.4}"
expected_artifact_sha256="${PASTURESTACK_EXPECTED_HOST_PROVISIONER_ARTIFACT_SHA256:-d967599c6e09acacec065f20078b039cf9b425356824acf0fd6adb3602e660af}"
expected_binary_sha256="${PASTURESTACK_EXPECTED_HOST_PROVISIONER_BINARY_SHA256:-dba5fd4d423a49f35a443951ac274ea680305a5a7a5945623139417c2e60ada3}"
expected_name="host-provisioner-${expected_version}-linux-amd64.tar.xz"

if [ -z "$artifact" ]; then
  if [ "${RC16_REQUIRE_HOST_PROVISIONER_ARTIFACT:-0}" = "1" ]; then
    echo 'SERVER_HOST_PROVISIONER_ARTIFACT_PATH_UNSET env=PASTURESTACK_HOST_PROVISIONER_ARTIFACT' >&2
    exit 1
  fi
  printf 'SERVER_HOST_PROVISIONER_ARTIFACT_SKIPPED version=%s reason=PASTURESTACK_HOST_PROVISIONER_ARTIFACT_unset\n' "$expected_version"
  exit 0
fi

if [ ! -f "$artifact" ]; then
  printf 'SERVER_HOST_PROVISIONER_ARTIFACT_MISSING path=%s\n' "$artifact" >&2
  exit 1
fi

if [ "$(basename "$artifact")" != "$expected_name" ]; then
  printf 'SERVER_HOST_PROVISIONER_ARTIFACT_NAME_MISMATCH actual=%s expected=%s\n' "$(basename "$artifact")" "$expected_name" >&2
  exit 1
fi

actual_artifact_sha256=$(sha256sum "$artifact" | awk '{print $1}')
if [ "$actual_artifact_sha256" != "$expected_artifact_sha256" ]; then
  printf 'SERVER_HOST_PROVISIONER_ARTIFACT_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_artifact_sha256" "$expected_artifact_sha256" >&2
  exit 1
fi

workdir=$(mktemp -d "${TMPDIR:-/tmp}/pasturestack-host-provisioner.XXXXXX")
trap 'rm -rf "$workdir"' EXIT
tar -xJf "$artifact" -C "$workdir"

binary="$workdir/host-provisioner"
if [ ! -x "$binary" ]; then
  printf 'SERVER_HOST_PROVISIONER_BINARY_MISSING path=%s\n' "$binary" >&2
  exit 1
fi

actual_binary_sha256=$(sha256sum "$binary" | awk '{print $1}')
if [ "$actual_binary_sha256" != "$expected_binary_sha256" ]; then
  printf 'SERVER_HOST_PROVISIONER_BINARY_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_binary_sha256" "$expected_binary_sha256" >&2
  exit 1
fi

file "$binary" | grep -F 'ELF 64-bit LSB executable' >/dev/null
file "$binary" | grep -F 'statically linked' >/dev/null
file "$binary" | grep -F 'stripped' >/dev/null

expected_version_output=$'host-provisioner\t gitcommit=v'"${expected_version}"
version_output=$("$binary" -v)
if [ "$version_output" != "$expected_version_output" ]; then
  printf 'SERVER_HOST_PROVISIONER_VERSION_MISMATCH actual=%s expected=%s\n' "$version_output" "$expected_version_output" >&2
  exit 1
fi

ln -s host-provisioner "$workdir/go-machine-service"
compatibility_version_output=$("$workdir/go-machine-service" -v)
if [ "$compatibility_version_output" != "$expected_version_output" ]; then
  printf 'SERVER_HOST_PROVISIONER_COMPATIBILITY_VERSION_MISMATCH actual=%s expected=%s\n' "$compatibility_version_output" "$expected_version_output" >&2
  exit 1
fi

printf 'SERVER_HOST_PROVISIONER_ARTIFACT_OK version=%s artifact_sha256=%s binary_sha256=%s neutral_asset=1 static=1 stripped=1 compatibility_alias=1\n' \
  "$expected_version" "$actual_artifact_sha256" "$actual_binary_sha256"

#!/usr/bin/env bash
set -euo pipefail

artifact="${PASTURESTACK_COMPOSE_EXECUTOR_ARTIFACT:-}"
expected_version="${PASTURESTACK_EXPECTED_COMPOSE_EXECUTOR_VERSION:-0.14.30}"
expected_artifact_sha256="${PASTURESTACK_EXPECTED_COMPOSE_EXECUTOR_ARTIFACT_SHA256:-e12c533c93ec4c3d4590c09c2616d6bf1f72db147a28178dcc8afa878ec99ea3}"
expected_binary_sha256="${PASTURESTACK_EXPECTED_COMPOSE_EXECUTOR_BINARY_SHA256:-cf23479f9d3eeb1f0e8dfce61efef0abedb2054d5837a444c5a46ff7779e9ff8}"
expected_name="compose-executor-${expected_version}-linux-amd64.gz"

if [ -z "$artifact" ]; then
  if [ "${RC16_REQUIRE_COMPOSE_EXECUTOR_ARTIFACT:-0}" = "1" ]; then
    echo 'SERVER_COMPOSE_EXECUTOR_ARTIFACT_PATH_UNSET env=PASTURESTACK_COMPOSE_EXECUTOR_ARTIFACT' >&2
    exit 1
  fi
  printf 'SERVER_COMPOSE_EXECUTOR_ARTIFACT_SKIPPED version=%s reason=PASTURESTACK_COMPOSE_EXECUTOR_ARTIFACT_unset\n' "$expected_version"
  exit 0
fi

if [ ! -f "$artifact" ]; then
  printf 'SERVER_COMPOSE_EXECUTOR_ARTIFACT_MISSING path=%s\n' "$artifact" >&2
  exit 1
fi

if [ "$(basename "$artifact")" != "$expected_name" ]; then
  printf 'SERVER_COMPOSE_EXECUTOR_ARTIFACT_NAME_MISMATCH actual=%s expected=%s\n' "$(basename "$artifact")" "$expected_name" >&2
  exit 1
fi

actual_artifact_sha256=$(sha256sum "$artifact" | awk '{print $1}')
if [ "$actual_artifact_sha256" != "$expected_artifact_sha256" ]; then
  printf 'SERVER_COMPOSE_EXECUTOR_ARTIFACT_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_artifact_sha256" "$expected_artifact_sha256" >&2
  exit 1
fi

gzip -t "$artifact"
workdir=$(mktemp -d "${TMPDIR:-/tmp}/pasturestack-compose-executor.XXXXXX")
trap 'rm -rf "$workdir"' EXIT
gzip -cd "$artifact" >"$workdir/compose-executor"
chmod 0755 "$workdir/compose-executor"

actual_binary_sha256=$(sha256sum "$workdir/compose-executor" | awk '{print $1}')
if [ "$actual_binary_sha256" != "$expected_binary_sha256" ]; then
  printf 'SERVER_COMPOSE_EXECUTOR_BINARY_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_binary_sha256" "$expected_binary_sha256" >&2
  exit 1
fi

file "$workdir/compose-executor" | grep -F 'ELF 64-bit LSB executable' >/dev/null
file "$workdir/compose-executor" | grep -F 'statically linked' >/dev/null

version_output=$("$workdir/compose-executor" --version)
if [ "$version_output" != "compose-executor version v${expected_version}" ]; then
  printf 'SERVER_COMPOSE_EXECUTOR_VERSION_MISMATCH actual=%s expected=%s\n' "$version_output" "compose-executor version v${expected_version}" >&2
  exit 1
fi

ln -s compose-executor "$workdir/rancher-compose-executor"
compatibility_version_output=$("$workdir/rancher-compose-executor" --version)
if [ "$compatibility_version_output" != "compose-executor version v${expected_version}" ]; then
  printf 'SERVER_COMPOSE_EXECUTOR_COMPATIBILITY_VERSION_MISMATCH actual=%s expected=%s\n' "$compatibility_version_output" "compose-executor version v${expected_version}" >&2
  exit 1
fi

printf 'SERVER_COMPOSE_EXECUTOR_ARTIFACT_OK version=%s artifact_sha256=%s binary_sha256=%s neutral_asset=1 static=1 compatibility_alias=1\n' \
  "$expected_version" "$actual_artifact_sha256" "$actual_binary_sha256"

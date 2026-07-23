#!/usr/bin/env bash
set -euo pipefail

artifact="${PASTURESTACK_WINDOWS_NODE_AGENT_ARTIFACT:-}"
expected_version="${PASTURESTACK_EXPECTED_WINDOWS_AGENT_VERSION:-0.13.21}"
expected_artifact_sha256="${PASTURESTACK_EXPECTED_WINDOWS_AGENT_ARTIFACT_SHA256:-f511a41c0eb410473e1a223b70f7e8046b38f99e64b5b01167a4ca8c09a496e7}"
expected_binary_sha256="${PASTURESTACK_EXPECTED_WINDOWS_AGENT_BINARY_SHA256:-99432c5d94d01c3fbb9f5491820f8a56f641c63297af7c2d4eb58009ee42620b}"
expected_startup_sha256="${PASTURESTACK_EXPECTED_WINDOWS_AGENT_STARTUP_SHA256:-e1e84e1c5125db2b8f0c1a83ada8294556cb2390de969398a2436d9481378fca}"
expected_name="node-agent-${expected_version}-windows-amd64.zip"

if [ -z "$artifact" ]; then
  if [ "${RC16_REQUIRE_WINDOWS_NODE_AGENT_ARTIFACT:-0}" = "1" ]; then
    echo 'SERVER_WINDOWS_NODE_AGENT_ARTIFACT_PATH_UNSET env=PASTURESTACK_WINDOWS_NODE_AGENT_ARTIFACT' >&2
    exit 1
  fi
  printf 'SERVER_WINDOWS_NODE_AGENT_ARTIFACT_SKIPPED version=%s reason=PASTURESTACK_WINDOWS_NODE_AGENT_ARTIFACT_unset\n' "$expected_version"
  exit 0
fi

if [ ! -f "$artifact" ]; then
  printf 'SERVER_WINDOWS_NODE_AGENT_ARTIFACT_MISSING path=%s\n' "$artifact" >&2
  exit 1
fi

if [ "$(basename "$artifact")" != "$expected_name" ]; then
  printf 'SERVER_WINDOWS_NODE_AGENT_ARTIFACT_NAME_MISMATCH actual=%s expected=%s\n' "$(basename "$artifact")" "$expected_name" >&2
  exit 1
fi

actual_artifact_sha256=$(sha256sum "$artifact" | awk '{print $1}')
if [ "$actual_artifact_sha256" != "$expected_artifact_sha256" ]; then
  printf 'SERVER_WINDOWS_NODE_AGENT_ARTIFACT_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_artifact_sha256" "$expected_artifact_sha256" >&2
  exit 1
fi

workdir=$(mktemp -d "${TMPDIR:-/tmp}/pasturestack-windows-node-agent.XXXXXX")
trap 'rm -rf "$workdir"' EXIT

expected_entries=$(printf '%s\n' \
  'pasturestack/' \
  'pasturestack/node-agent.exe' \
  'pasturestack/startup_node-agent.ps1')
actual_entries=$(unzip -Z1 "$artifact")
if [ "$actual_entries" != "$expected_entries" ]; then
  printf 'SERVER_WINDOWS_NODE_AGENT_ZIP_LAYOUT_MISMATCH\nactual:\n%s\nexpected:\n%s\n' "$actual_entries" "$expected_entries" >&2
  exit 1
fi

unzip -qq "$artifact" -d "$workdir"
binary="$workdir/pasturestack/node-agent.exe"
startup="$workdir/pasturestack/startup_node-agent.ps1"

actual_binary_sha256=$(sha256sum "$binary" | awk '{print $1}')
if [ "$actual_binary_sha256" != "$expected_binary_sha256" ]; then
  printf 'SERVER_WINDOWS_NODE_AGENT_BINARY_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_binary_sha256" "$expected_binary_sha256" >&2
  exit 1
fi

actual_startup_sha256=$(sha256sum "$startup" | awk '{print $1}')
if [ "$actual_startup_sha256" != "$expected_startup_sha256" ]; then
  printf 'SERVER_WINDOWS_NODE_AGENT_STARTUP_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_startup_sha256" "$expected_startup_sha256" >&2
  exit 1
fi

file "$binary" | grep -F 'PE32+ executable' >/dev/null
file "$binary" | grep -F 'x86-64' >/dev/null
LC_ALL=C grep -aF "v${expected_version}" "$binary" >/dev/null

printf 'SERVER_WINDOWS_NODE_AGENT_ARTIFACT_OK version=%s artifact_sha256=%s binary_sha256=%s startup_sha256=%s neutral_asset=1 neutral_layout=1 windows_amd64=1 runtime_validation=pending bootstrap_runtime=pending\n' \
  "$expected_version" "$actual_artifact_sha256" "$actual_binary_sha256" "$actual_startup_sha256"

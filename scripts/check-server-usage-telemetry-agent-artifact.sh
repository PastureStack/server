#!/usr/bin/env bash
set -euo pipefail

artifact="${PASTURESTACK_USAGE_TELEMETRY_AGENT_ARTIFACT:-}"
expected_version="${PASTURESTACK_EXPECTED_USAGE_TELEMETRY_AGENT_VERSION:-0.4.0-pasturestack.1}"
expected_artifact_sha256="${PASTURESTACK_EXPECTED_USAGE_TELEMETRY_AGENT_ARTIFACT_SHA256:-9f6ca46d5dba98ba0c61d00495d9aa37eb21586005b412ed873a1b0bc727baf6}"
expected_binary_sha256="${PASTURESTACK_EXPECTED_USAGE_TELEMETRY_AGENT_BINARY_SHA256:-3c587d14ffed4640090cf5c532a1844b41d1b3c225f51507053ec3bd77714093}"
expected_source_commit="${PASTURESTACK_EXPECTED_USAGE_TELEMETRY_AGENT_SOURCE_COMMIT:-d0dfbb148bc738bda5b396ee9e7d64f40aa567f5}"
expected_upstream_boundary="${PASTURESTACK_EXPECTED_USAGE_TELEMETRY_AGENT_UPSTREAM_BOUNDARY:-83df963051f33520dda867e6e882afa277b62cbc}"
expected_legacy_reference="${PASTURESTACK_EXPECTED_USAGE_TELEMETRY_AGENT_LEGACY_REFERENCE:-71cd4522b3f1c716597b2715dc52f8f2a6827026}"
expected_name="usage-telemetry-agent-${expected_version}-linux-amd64.tar.xz"

if [ -z "$artifact" ]; then
  if [ "${RC16_REQUIRE_USAGE_TELEMETRY_AGENT_ARTIFACT:-0}" = "1" ]; then
    echo 'SERVER_USAGE_TELEMETRY_AGENT_ARTIFACT_PATH_UNSET env=PASTURESTACK_USAGE_TELEMETRY_AGENT_ARTIFACT' >&2
    exit 1
  fi
  printf 'SERVER_USAGE_TELEMETRY_AGENT_ARTIFACT_SKIPPED version=%s reason=PASTURESTACK_USAGE_TELEMETRY_AGENT_ARTIFACT_unset\n' "$expected_version"
  exit 0
fi

if [ ! -f "$artifact" ]; then
  printf 'SERVER_USAGE_TELEMETRY_AGENT_ARTIFACT_MISSING path=%s\n' "$artifact" >&2
  exit 1
fi
if [ "$(basename "$artifact")" != "$expected_name" ]; then
  printf 'SERVER_USAGE_TELEMETRY_AGENT_ARTIFACT_NAME_MISMATCH actual=%s expected=%s\n' "$(basename "$artifact")" "$expected_name" >&2
  exit 1
fi

actual_artifact_sha256=$(sha256sum "$artifact" | awk '{print $1}')
if [ "$actual_artifact_sha256" != "$expected_artifact_sha256" ]; then
  printf 'SERVER_USAGE_TELEMETRY_AGENT_ARTIFACT_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_artifact_sha256" "$expected_artifact_sha256" >&2
  exit 1
fi

expected_entries=$(printf '%s\n' \
  usage-telemetry-agent \
  usage-telemetry-agent-LICENSES.txt \
  usage-telemetry-agent-PRIVACY.md \
  usage-telemetry-agent-SOURCES.txt \
  usage-telemetry-agent-THIRD-PARTY-NOTICES.md)
actual_entries=$(tar -tJf "$artifact")
if [ "$actual_entries" != "$expected_entries" ]; then
  printf 'SERVER_USAGE_TELEMETRY_AGENT_LAYOUT_MISMATCH\nactual:\n%s\nexpected:\n%s\n' "$actual_entries" "$expected_entries" >&2
  exit 1
fi

workdir=$(mktemp -d "${TMPDIR:-/tmp}/pasturestack-usage-telemetry-agent-server-gate.XXXXXX")
cleanup()
{
  rm -rf "$workdir"
}
trap cleanup EXIT
tar -xJf "$artifact" -C "$workdir"

binary="$workdir/usage-telemetry-agent"
actual_binary_sha256=$(sha256sum "$binary" | awk '{print $1}')
test "$actual_binary_sha256" = "$expected_binary_sha256"
file "$binary" | grep -F 'ELF 64-bit LSB executable, x86-64' >/dev/null
file "$binary" | grep -F 'statically linked' >/dev/null
file "$binary" | grep -F 'stripped' >/dev/null
"$binary" --version | grep -F "v${expected_version} (${expected_source_commit})" >/dev/null
ln -s usage-telemetry-agent "$workdir/telemetry"
"$workdir/telemetry" --version | grep -F "v${expected_version}" >/dev/null

licenses="$workdir/usage-telemetry-agent-LICENSES.txt"
privacy="$workdir/usage-telemetry-agent-PRIVACY.md"
sources="$workdir/usage-telemetry-agent-SOURCES.txt"
notices="$workdir/usage-telemetry-agent-THIRD-PARTY-NOTICES.md"
grep -F 'Apache License' "$licenses" >/dev/null
grep -F 'Redistribution and use in source and binary forms' "$licenses" >/dev/null
grep -F "Release source commit: ${expected_source_commit}" "$sources" >/dev/null
grep -F "Latest preserved upstream boundary: ${expected_upstream_boundary}" "$sources" >/dev/null
grep -F "Legacy v1.6 client reference: ${expected_legacy_reference}" "$sources" >/dev/null
grep -F 'External publishing is off by default.' "$privacy" >/dev/null
grep -F 'The program never creates or updates the setting.' "$privacy" >/dev/null
grep -F 'The executable uses only the Go standard library.' "$notices" >/dev/null

for marker in PASTURESTACK_API_URL PASTURESTACK_API_ACCESS_KEY PASTURESTACK_API_SECRET_KEY PASTURESTACK_USAGE_TELEMETRY_TARGET_URL; do
  grep -aF "$marker" "$binary" >/dev/null
done
if grep -aF 'TELEMETRY_TO_URL' "$binary" >/dev/null; then
  echo 'SERVER_USAGE_TELEMETRY_AGENT_RETIRED_TARGET_VARIABLE_PRESENT' >&2
  exit 1
fi
if grep -aF 'telemetry.rancher.io' "$binary" >/dev/null; then
  echo 'SERVER_USAGE_TELEMETRY_AGENT_RETIRED_TARGET_PRESENT' >&2
  exit 1
fi

printf 'SERVER_USAGE_TELEMETRY_AGENT_ARTIFACT_OK version=%s artifact_sha256=%s binary_sha256=%s source=%s upstream=%s legacy_reference=%s neutral_asset=1 compatibility_alias=1 privacy_notice=1 retired_target=0\n' \
  "$expected_version" "$actual_artifact_sha256" "$actual_binary_sha256" "$expected_source_commit" "$expected_upstream_boundary" "$expected_legacy_reference"

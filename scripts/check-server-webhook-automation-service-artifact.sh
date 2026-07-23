#!/usr/bin/env bash
set -euo pipefail

artifact="${PASTURESTACK_WEBHOOK_AUTOMATION_SERVICE_ARTIFACT:-}"
expected_version="${PASTURESTACK_EXPECTED_WEBHOOK_AUTOMATION_SERVICE_VERSION:-0.9.15-pasturestack.1}"
expected_artifact_sha256="${PASTURESTACK_EXPECTED_WEBHOOK_AUTOMATION_SERVICE_ARTIFACT_SHA256:-b48ceb5adb0c6fa11806caf04353d21faf9bd38d570b08e6f099fc6c0da200d6}"
expected_binary_sha256="${PASTURESTACK_EXPECTED_WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256:-195cec94370e5ab61bcba1bbbad6b048dbc1dd3d5bf696fe690017b3bda57e9a}"
expected_source_commit="${PASTURESTACK_EXPECTED_WEBHOOK_AUTOMATION_SERVICE_SOURCE_COMMIT:-905f7a41ba86d300ba53ea9700b7b74d9e6ff239}"
expected_upstream_boundary="${PASTURESTACK_EXPECTED_WEBHOOK_AUTOMATION_SERVICE_UPSTREAM_BOUNDARY:-5d68737e9c5edafc70a4963ffca1466e0b95c708}"
expected_name="webhook-automation-service-${expected_version}-linux-amd64.tar.xz"

if [ -z "$artifact" ]; then
  if [ "${RC16_REQUIRE_WEBHOOK_AUTOMATION_SERVICE_ARTIFACT:-0}" = "1" ]; then
    echo 'SERVER_WEBHOOK_AUTOMATION_SERVICE_ARTIFACT_PATH_UNSET env=PASTURESTACK_WEBHOOK_AUTOMATION_SERVICE_ARTIFACT' >&2
    exit 1
  fi
  printf 'SERVER_WEBHOOK_AUTOMATION_SERVICE_ARTIFACT_SKIPPED version=%s reason=PASTURESTACK_WEBHOOK_AUTOMATION_SERVICE_ARTIFACT_unset\n' "$expected_version"
  exit 0
fi

if [ ! -f "$artifact" ]; then
  printf 'SERVER_WEBHOOK_AUTOMATION_SERVICE_ARTIFACT_MISSING path=%s\n' "$artifact" >&2
  exit 1
fi
if [ "$(basename "$artifact")" != "$expected_name" ]; then
  printf 'SERVER_WEBHOOK_AUTOMATION_SERVICE_ARTIFACT_NAME_MISMATCH actual=%s expected=%s\n' "$(basename "$artifact")" "$expected_name" >&2
  exit 1
fi

actual_artifact_sha256=$(sha256sum "$artifact" | awk '{print $1}')
if [ "$actual_artifact_sha256" != "$expected_artifact_sha256" ]; then
  printf 'SERVER_WEBHOOK_AUTOMATION_SERVICE_ARTIFACT_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_artifact_sha256" "$expected_artifact_sha256" >&2
  exit 1
fi

expected_entries=$(printf '%s\n' \
  webhook-automation-service \
  webhook-automation-service-COMPATIBILITY.md \
  webhook-automation-service-LICENSES.txt \
  webhook-automation-service-SOURCES.txt \
  webhook-automation-service-THIRD-PARTY-NOTICES.md)
actual_entries=$(tar -tJf "$artifact")
if [ "$actual_entries" != "$expected_entries" ]; then
  printf 'SERVER_WEBHOOK_AUTOMATION_SERVICE_LAYOUT_MISMATCH\nactual:\n%s\nexpected:\n%s\n' "$actual_entries" "$expected_entries" >&2
  exit 1
fi

workdir=$(mktemp -d "${TMPDIR:-/tmp}/pasturestack-webhook-automation-service-server-gate.XXXXXX")
cleanup()
{
  rm -rf "$workdir"
}
trap cleanup EXIT
tar -xJf "$artifact" -C "$workdir"

binary="$workdir/webhook-automation-service"
actual_binary_sha256=$(sha256sum "$binary" | awk '{print $1}')
test "$actual_binary_sha256" = "$expected_binary_sha256"
file "$binary" | grep -F 'ELF 64-bit LSB executable, x86-64' >/dev/null
file "$binary" | grep -F 'statically linked' >/dev/null
file "$binary" | grep -F 'stripped' >/dev/null
"$binary" --version | grep -F "v${expected_version}" >/dev/null
ln -s webhook-automation-service "$workdir/webhook-service"
"$workdir/webhook-service" --version | grep -F "v${expected_version}" >/dev/null

licenses="$workdir/webhook-automation-service-LICENSES.txt"
compatibility="$workdir/webhook-automation-service-COMPATIBILITY.md"
sources="$workdir/webhook-automation-service-SOURCES.txt"
notices="$workdir/webhook-automation-service-THIRD-PARTY-NOTICES.md"
grep -F 'Apache License' "$licenses" >/dev/null
grep -F 'Redistribution and use in source and binary forms' "$licenses" >/dev/null
grep -F "Release source commit: ${expected_source_commit}" "$sources" >/dev/null
grep -F "Latest relevant upstream boundary: ${expected_upstream_boundary}" "$sources" >/dev/null
grep -F 'never reads `RSA_PRIVATE_KEY_CONTENTS`' "$compatibility" >/dev/null
grep -F 'The retired `dgrijalva/jwt-go`' "$notices" >/dev/null

for marker in PASTURESTACK_API_URL PASTURESTACK_API_ACCESS_KEY PASTURESTACK_API_SECRET_KEY PASTURESTACK_API_PUBLIC_KEY_CONTENTS; do
  grep -aF "$marker" "$binary" >/dev/null
done
if grep -aF 'RSA_PRIVATE_KEY_CONTENTS' "$binary" >/dev/null; then
  echo 'SERVER_WEBHOOK_AUTOMATION_SERVICE_PRIVATE_KEY_VARIABLE_PRESENT' >&2
  exit 1
fi
if grep -aF 'github.com/dgrijalva/jwt-go' "$binary" >/dev/null; then
  echo 'SERVER_WEBHOOK_AUTOMATION_SERVICE_RETIRED_JWT_DEPENDENCY_PRESENT' >&2
  exit 1
fi

printf 'SERVER_WEBHOOK_AUTOMATION_SERVICE_ARTIFACT_OK version=%s artifact_sha256=%s binary_sha256=%s source=%s upstream=%s neutral_asset=1 compatibility_alias=1 private_key_export=0 retired_jwt=0\n' \
  "$expected_version" "$actual_artifact_sha256" "$actual_binary_sha256" "$expected_source_commit" "$expected_upstream_boundary"

#!/usr/bin/env bash
set -euo pipefail

artifact="${PASTURESTACK_SECRET_DELIVERY_API_ARTIFACT:-}"
expected_version="${PASTURESTACK_EXPECTED_SECRET_DELIVERY_API_VERSION:-0.2.2}"
expected_artifact_sha256="${PASTURESTACK_EXPECTED_SECRET_DELIVERY_API_ARTIFACT_SHA256:-b189da012bcabedbb9562cebb376afe8139f0101e27cbb1a0acda10f089af216}"
expected_binary_sha256="${PASTURESTACK_EXPECTED_SECRET_DELIVERY_API_BINARY_SHA256:-e62141d968cc5323bc53ad0cdc3630239b9e27e7ab5a212bf40a321c48e5dd1a}"
expected_source_commit="${PASTURESTACK_EXPECTED_SECRET_DELIVERY_API_SOURCE_COMMIT:-227aaa22a0daa54e15ca600e9ea903d3b7194fc1}"
expected_upstream_boundary="${PASTURESTACK_EXPECTED_SECRET_DELIVERY_API_UPSTREAM_BOUNDARY:-46d8cb7c0cf2ecf07447aadbfaa39c11bd4b5fbb}"
expected_name="secret-delivery-api-${expected_version}-linux-amd64.tar.xz"

if [ -z "$artifact" ]; then
  if [ "${RC16_REQUIRE_SECRET_DELIVERY_API_ARTIFACT:-0}" = "1" ]; then
    echo 'SERVER_SECRET_DELIVERY_API_ARTIFACT_PATH_UNSET env=PASTURESTACK_SECRET_DELIVERY_API_ARTIFACT' >&2
    exit 1
  fi
  printf 'SERVER_SECRET_DELIVERY_API_ARTIFACT_SKIPPED version=%s reason=PASTURESTACK_SECRET_DELIVERY_API_ARTIFACT_unset\n' "$expected_version"
  exit 0
fi

if [ ! -f "$artifact" ]; then
  printf 'SERVER_SECRET_DELIVERY_API_ARTIFACT_MISSING path=%s\n' "$artifact" >&2
  exit 1
fi

if [ "$(basename "$artifact")" != "$expected_name" ]; then
  printf 'SERVER_SECRET_DELIVERY_API_ARTIFACT_NAME_MISMATCH actual=%s expected=%s\n' "$(basename "$artifact")" "$expected_name" >&2
  exit 1
fi

actual_artifact_sha256=$(sha256sum "$artifact" | awk '{print $1}')
if [ "$actual_artifact_sha256" != "$expected_artifact_sha256" ]; then
  printf 'SERVER_SECRET_DELIVERY_API_ARTIFACT_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_artifact_sha256" "$expected_artifact_sha256" >&2
  exit 1
fi

expected_entries=$(printf '%s\n' \
  secret-delivery-api \
  secret-delivery-api-LICENSES.txt \
  secret-delivery-api-SOURCES.txt \
  secret-delivery-api-THIRD-PARTY-NOTICES.md)
actual_entries=$(tar -tJf "$artifact")
if [ "$actual_entries" != "$expected_entries" ]; then
  printf 'SERVER_SECRET_DELIVERY_API_LAYOUT_MISMATCH\nactual:\n%s\nexpected:\n%s\n' "$actual_entries" "$expected_entries" >&2
  exit 1
fi

workdir=$(mktemp -d "${TMPDIR:-/tmp}/pasturestack-secret-delivery-api-server-gate.XXXXXX")
pid=''
cleanup()
{
  if [ -n "$pid" ]; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  rm -rf "$workdir"
}
trap cleanup EXIT
tar -xJf "$artifact" -C "$workdir"

binary="$workdir/secret-delivery-api"
actual_binary_sha256=$(sha256sum "$binary" | awk '{print $1}')
test "$actual_binary_sha256" = "$expected_binary_sha256"
file "$binary" | grep -F 'ELF 64-bit LSB executable, x86-64' >/dev/null
file "$binary" | grep -F 'statically linked' >/dev/null
file "$binary" | grep -F 'stripped' >/dev/null
"$binary" --version | grep -F "v${expected_version}" >/dev/null
ln -s secret-delivery-api "$workdir/secrets-api"
"$workdir/secrets-api" --version | grep -F "v${expected_version}" >/dev/null

licenses="$workdir/secret-delivery-api-LICENSES.txt"
sources="$workdir/secret-delivery-api-SOURCES.txt"
notices="$workdir/secret-delivery-api-THIRD-PARTY-NOTICES.md"
grep -F 'Apache License' "$licenses" >/dev/null
grep -F 'Mozilla Public License' "$licenses" >/dev/null
grep -F "Release source commit: ${expected_source_commit}" "$sources" >/dev/null
grep -F "Preserved upstream boundary: ${expected_upstream_boundary}" "$sources" >/dev/null
grep -F 'PastureStack claims only its subsequent modifications' "$sources" >/dev/null
grep -F 'legacy control-plane wire-format dependency' "$notices" >/dev/null

dd if=/dev/urandom of="$workdir/smoke-key" bs=32 count=1 status=none
chmod 0600 "$workdir/smoke-key"
listen_address=127.0.0.1:18182
"$binary" server --enc-key-path "$workdir" --listen-address "$listen_address" >"$workdir/service.log" 2>&1 &
pid=$!
ready=0
for _ in $(seq 1 50); do
  if curl --silent --fail "http://${listen_address}/v1-secrets" >/dev/null; then
    ready=1
    break
  fi
  if ! kill -0 "$pid" 2>/dev/null; then
    cat "$workdir/service.log" >&2
    exit 1
  fi
  sleep 0.1
done
test "$ready" = 1

response=$(curl --silent --show-error --fail \
  -H 'Content-Type: application/json' \
  -d '{"type":"secretInput","name":"server-gate","clearText":"Server gate secret","backend":"localkey","keyName":"smoke-key"}' \
  "http://${listen_address}/v1-secrets/secrets/create")
RESPONSE="$response" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["RESPONSE"])
assert payload["type"] == "encryptedSecret"
assert payload["backend"] == "localkey"
assert payload["keyName"] == "smoke-key"
assert payload.get("cipherText")
assert payload.get("signature")
assert "clearText" not in payload
assert "Server gate secret" not in json.dumps(payload)
PY

printf 'SERVER_SECRET_DELIVERY_API_ARTIFACT_OK version=%s artifact_sha256=%s binary_sha256=%s source=%s upstream=%s neutral_asset=1 compatibility_alias=1 localkey_smoke=1 cleartext_leak=0\n' \
  "$expected_version" "$actual_artifact_sha256" "$actual_binary_sha256" "$expected_source_commit" "$expected_upstream_boundary"

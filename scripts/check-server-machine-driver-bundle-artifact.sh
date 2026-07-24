#!/usr/bin/env bash
set -euo pipefail

artifact="${PASTURESTACK_MACHINE_DRIVER_BUNDLE_ARTIFACT:-}"
expected_version="${PASTURESTACK_EXPECTED_MACHINE_DRIVER_BUNDLE_VERSION:-0.14.0}"
expected_artifact_sha256="${PASTURESTACK_EXPECTED_MACHINE_DRIVER_BUNDLE_ARTIFACT_SHA256:-bbe535bd5d40f71040ea8e13508188a2634973b1b8a1e7a3081fded6a78b3a9e}"
expected_machine_sha256="${PASTURESTACK_EXPECTED_MACHINE_MANAGER_BINARY_SHA256:-a4c69bffb78d3cfe103b89dae61c3ea11cc2d1a91c4ff86e630c9ae88244db02}"
expected_packet_sha256="${PASTURESTACK_EXPECTED_PACKET_DRIVER_BINARY_SHA256:-e77c635969a76f498d7088904acd375f25b79a81632b87fa9e5cc5b8e2e72184}"
expected_name="machine-driver-bundle-${expected_version}-linux-amd64.tar.xz"

if [ -z "$artifact" ]; then
  if [ "${RC16_REQUIRE_MACHINE_DRIVER_BUNDLE_ARTIFACT:-0}" = "1" ]; then
    echo 'SERVER_MACHINE_DRIVER_BUNDLE_ARTIFACT_PATH_UNSET env=PASTURESTACK_MACHINE_DRIVER_BUNDLE_ARTIFACT' >&2
    exit 1
  fi
  printf 'SERVER_MACHINE_DRIVER_BUNDLE_ARTIFACT_SKIPPED version=%s reason=PASTURESTACK_MACHINE_DRIVER_BUNDLE_ARTIFACT_unset\n' "$expected_version"
  exit 0
fi

if [ ! -f "$artifact" ]; then
  printf 'SERVER_MACHINE_DRIVER_BUNDLE_ARTIFACT_MISSING path=%s\n' "$artifact" >&2
  exit 1
fi

if [ "$(basename "$artifact")" != "$expected_name" ]; then
  printf 'SERVER_MACHINE_DRIVER_BUNDLE_ARTIFACT_NAME_MISMATCH actual=%s expected=%s\n' "$(basename "$artifact")" "$expected_name" >&2
  exit 1
fi

actual_artifact_sha256=$(sha256sum "$artifact" | awk '{print $1}')
if [ "$actual_artifact_sha256" != "$expected_artifact_sha256" ]; then
  printf 'SERVER_MACHINE_DRIVER_BUNDLE_ARTIFACT_SHA256_MISMATCH actual=%s expected=%s\n' "$actual_artifact_sha256" "$expected_artifact_sha256" >&2
  exit 1
fi

expected_entries=$(printf '%s\n' \
  docker-machine \
  docker-machine-driver-packet \
  machine-driver-bundle-LICENSES.txt \
  machine-driver-bundle-SOURCES.txt \
  machine-driver-bundle-THIRD-PARTY-NOTICES.txt)
actual_entries=$(tar -tJf "$artifact")
if [ "$actual_entries" != "$expected_entries" ]; then
  printf 'SERVER_MACHINE_DRIVER_BUNDLE_LAYOUT_MISMATCH\nactual:\n%s\nexpected:\n%s\n' "$actual_entries" "$expected_entries" >&2
  exit 1
fi

workdir=$(mktemp -d "${TMPDIR:-/tmp}/pasturestack-machine-driver-server-gate.XXXXXX")
trap 'rm -rf "$workdir"' EXIT
mkdir "$workdir/extracted" "$workdir/storage"
tar -xJf "$artifact" -C "$workdir/extracted"

machine="$workdir/extracted/docker-machine"
packet="$workdir/extracted/docker-machine-driver-packet"
actual_machine_sha256=$(sha256sum "$machine" | awk '{print $1}')
actual_packet_sha256=$(sha256sum "$packet" | awk '{print $1}')
test "$actual_machine_sha256" = "$expected_machine_sha256"
test "$actual_packet_sha256" = "$expected_packet_sha256"
file "$machine" | grep -F 'ELF 64-bit LSB executable' >/dev/null
file "$machine" | grep -F 'x86-64' >/dev/null
file "$packet" | grep -F 'ELF 64-bit LSB executable' >/dev/null
file "$packet" | grep -F 'x86-64' >/dev/null
"$machine" version | grep -F "version ${expected_version}" >/dev/null

licenses="$workdir/extracted/machine-driver-bundle-LICENSES.txt"
sources="$workdir/extracted/machine-driver-bundle-SOURCES.txt"
notices="$workdir/extracted/machine-driver-bundle-THIRD-PARTY-NOTICES.txt"
grep -F 'Apache License' "$licenses" >/dev/null
grep -F 'BSD 3-Clause License' "$licenses" >/dev/null
grep -F '89b833253d9412716a0291cbdccc94454c33d1b5' "$sources" >/dev/null
grep -F '319c90277d69d553f8d4b9a5205e32034d78789e' "$sources" >/dev/null
grep -F 'Docker Machine 0.14.0' "$notices" >/dev/null
grep -F 'Packet machine driver 0.1.5' "$notices" >/dev/null

PATH="$workdir/extracted:$PATH" "$machine" --storage-path "$workdir/storage" ls >/dev/null
PATH="$workdir/extracted:$PATH" timeout 20 "$machine" --storage-path "$workdir/storage" \
  create --driver packet --help >"$workdir/packet-help.txt"
grep -F -- '--packet-api-key' "$workdir/packet-help.txt" >/dev/null
grep -F -- '--packet-project-id' "$workdir/packet-help.txt" >/dev/null

printf 'SERVER_MACHINE_DRIVER_BUNDLE_ARTIFACT_OK version=%s artifact_sha256=%s machine_sha256=%s packet_sha256=%s neutral_asset=1 reproducible=1 licenses=2 machine_smoke=1 packet_protocol=1 provider_lifecycle=pending\n' \
  "$expected_version" "$actual_artifact_sha256" "$actual_machine_sha256" "$actual_packet_sha256"

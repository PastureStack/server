#!/usr/bin/env bash
# Consume the immutable producer bundle without enabling retired providers.
set -euo pipefail
[[ $# == 6 ]] || { echo 'usage: verify-machine-driver-bundle VERSION COMMIT ARCHIVE MACHINE_SHA256 PACKET_SHA256 OUTPUT' >&2; exit 2; }
version=$1 commit=$2 archive=$3 machine_sha=$4 packet_sha=$5 output=$6
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$commit" =~ ^[0-9a-f]{40}$ ]]
[[ "$machine_sha" =~ ^[0-9a-f]{64}$ && "$packet_sha" =~ ^[0-9a-f]{64}$ ]]
[[ "$output" =~ ^/(out|tmp/[A-Za-z0-9._-]+)/machine-driver-bundle$ && ! -e "$output" && ! -L "$output" ]]
listing=$(mktemp)
verbose=$(mktemp)
expected=$(mktemp)
trap 'rm -f -- "$listing" "$verbose" "$expected"' EXIT
tar -tJf "$archive" > "$listing"
printf '%s\n' docker-machine docker-machine-driver-packet \
    machine-driver-bundle-DEPENDENCY-LICENSES.txt machine-driver-bundle-LICENSES.txt \
    machine-driver-bundle-PROVIDER-LIFECYCLE.json machine-driver-bundle-SECURITY-VEX.json \
    machine-driver-bundle-SOURCES.txt machine-driver-bundle-THIRD-PARTY-NOTICES.txt | LC_ALL=C sort > "$expected"
# Exact members reject traversal, absolute paths, duplicates and extra payloads.
LC_ALL=C sort "$listing" | cmp "$expected" -
tar -tvJf "$archive" > "$verbose"
! grep -Eq '^[^-]' "$verbose"
mkdir -p "$output"
tar --no-same-owner --no-same-permissions -xJf "$archive" -C "$output"
printf '%s  %s\n' "$machine_sha" "$output/docker-machine" "$packet_sha" "$output/docker-machine-driver-packet" | sha256sum -c -
grep -Fx "BUNDLE_VERSION=$version" "$output/machine-driver-bundle-SOURCES.txt"
grep -Fx "DOCKER_MACHINE_BINARY_SHA256=$machine_sha" "$output/machine-driver-bundle-SOURCES.txt"
grep -Fx "PACKET_DRIVER_BINARY_SHA256=$packet_sha" "$output/machine-driver-bundle-SOURCES.txt"
grep -Fx 'GO_VERSION=1.27.3' "$output/machine-driver-bundle-SOURCES.txt"
grep -Fx 'PACKET_DRIVER_STATUS=retired-compatibility-only' "$output/machine-driver-bundle-SOURCES.txt"
grep -Fx 'PACKET_DRIVER_NEW_INSTALL_DEFAULT=false' "$output/machine-driver-bundle-SOURCES.txt"
grep -F '"newInstallDefault": false' "$output/machine-driver-bundle-PROVIDER-LIFECYCLE.json"
grep -F '"existingConfigurationPolicy": "preserve-for-rollback"' "$output/machine-driver-bundle-PROVIDER-LIFECYCLE.json"
for binary in docker-machine docker-machine-driver-packet; do
    chmod 0755 "$output/$binary"
    test "$(go version -m "$output/$binary" | awk 'NR==1 {print $2}')" = go1.27.3
done
"$output/docker-machine" version | grep -F "docker-machine version $version,"
mkdir -p "$output/licenses"
for member in "$output"/machine-driver-bundle-*; do mv -- "$member" "$output/licenses/"; done
printf 'Release source commit: %s\nMachine SHA-256: %s\nPacket SHA-256: %s\n' "$commit" "$machine_sha" "$packet_sha" > "$output/licenses/SERVER-PRODUCER-SOURCES.txt"

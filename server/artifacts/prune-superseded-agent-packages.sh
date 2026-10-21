#!/bin/sh
# Build-time only. Never touches a running host, data volume or rollback image.
set -eu
test "$#" -eq 4
directory=$1
env_file=$2
host_version=$3
node_version=$4
test -d "$directory" || exit 1
test ! -L "$directory" || exit 1
test -f "$env_file" || exit 1
test ! -L "$env_file" || exit 1
if printf '%s\n' "$host_version" "$node_version" | grep -Eqv '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    exit 1
fi
for current in "host-api-$host_version.tar.gz" "node-agent-$node_version.tar.gz" "node-agent-$node_version-windows-amd64.zip"; do
    test -f "$directory/$current" || exit 1
    test ! -L "$directory/$current" || exit 1
done
# First validate the whole removal set. A stale active reference or symlink
# rejects the build before any old bundle is removed.
for archive in "$directory"/host-api-*.tar.gz "$directory"/node-agent-*.tar.gz "$directory"/node-agent-*-windows-amd64.zip; do
    test -e "$archive" || continue
    name=${archive##*/}
    case "$name" in
        "host-api-$host_version.tar.gz"|"node-agent-$node_version.tar.gz"|"node-agent-$node_version-windows-amd64.zip") continue ;;
    esac
    printf '%s\n' "$name" | grep -Eq '^(host-api|node-agent)-[0-9]+\.[0-9]+\.[0-9]+(\.tar\.gz|-windows-amd64\.zip)$'
    test -f "$archive" || exit 1
    test ! -L "$archive" || exit 1
    if grep -Fq "$name" "$env_file"; then
        echo "Superseded agent bundle is still referenced: $name" >&2
        exit 1
    fi
done
for archive in "$directory"/host-api-*.tar.gz "$directory"/node-agent-*.tar.gz "$directory"/node-agent-*-windows-amd64.zip; do
    test -e "$archive" || continue
    case "${archive##*/}" in
        "host-api-$host_version.tar.gz"|"node-agent-$node_version.tar.gz"|"node-agent-$node_version-windows-amd64.zip") continue ;;
    esac
    rm -f -- "$archive"
done

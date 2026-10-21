#!/bin/sh
# Build-time only. Never touches a running host, data volume or rollback image.
set -eu
test "$#" -eq 4
directory=$1
env_file=$2
host_version=$3
node_version=$4
test -d "$directory" && test ! -L "$directory"
test -f "$env_file" && test ! -L "$env_file"
printf '%s\n' "$host_version" "$node_version" | grep -Eqv '^[0-9]+\.[0-9]+\.[0-9]+$' && exit 1
for current in "host-api-$host_version.tar.gz" "node-agent-$node_version.tar.gz" "node-agent-$node_version-windows-amd64.zip"; do
    test -f "$directory/$current" && test ! -L "$directory/$current"
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
    test -f "$archive" && test ! -L "$archive"
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

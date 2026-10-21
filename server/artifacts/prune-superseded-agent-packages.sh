#!/bin/sh
# Build-time only. Never touches a running host, data volume or rollback image.
set -eu
test "$#" -eq 5
directory=$1
env_file=$2
host_version=$3
node_version=$4
cni_version=$5
test "$cni_version" = 0.2.5 || exit 1
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
cni_current="per-host-subnet-$cni_version-windows-amd64.zip"
cni_old="$directory/per-host-subnet-0.2.4-windows-amd64.zip"
test -f "$directory/$cni_current" && test ! -L "$directory/$cni_current" || exit 1
if [ -e "$cni_old" ] || [ -L "$cni_old" ]; then
    test -f "$cni_old" && test ! -L "$cni_old" || exit 1
    if grep -Fq "per-host-subnet-0.2.4-windows-amd64.zip" "$env_file"; then
        echo 'Superseded CNI024 bundle is still referenced' >&2
        exit 1
    fi
fi
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

# Only the explicitly superseded CNI024 bundle, after every validation above.
rm -f -- "$cni_old"

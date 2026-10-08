#!/usr/bin/env bash
set -euo pipefail

[[ $# == 5 || $# == 6 ]] || { echo 'usage: verify-agent-package COMPONENT ARCHIVE PACKAGE_ID BINARY_SHA256 APPLY_SHA256 [SOURCE_COMMIT]' >&2; exit 2; }
component=$1 archive=$(realpath -- "$2") root=$3 binary_hash=$4 apply_hash=$5
[[ "$component" == host-api || "$component" == node-agent ]]
[[ "$root" =~ ^[0-9a-f]{32}$ ]]
[[ "$binary_hash" =~ ^[0-9a-f]{64}$ && "$apply_hash" =~ ^[0-9a-f]{64}$ ]]
test -s "$archive" && test ! -L "$archive"
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
tar -tzf "$archive" >"$scratch/listing"
! grep -Eq '(^/|(^|/)\.\.(/|$))' "$scratch/listing"
test -z "$(LC_ALL=C sort "$scratch/listing" | uniq -d)"
! tar -tvzf "$archive" | grep -Eq '^[lh]'
while IFS= read -r member; do
    case "$member" in "$root/"|"$root/"*) ;; *) echo 'Unexpected agent package root' >&2; exit 1 ;; esac
done <"$scratch/listing"
mkdir "$scratch/content"
tar --no-same-owner --no-same-permissions -xzf "$archive" -C "$scratch/content"
cd "$scratch/content"
for manifest in SHA1SUMS SHA1SUMSSUM SHA256SUMS SHA256SUMSSUM; do
    test -s "$root/$manifest"
    awk -v root="$root/" '{ path=$0; if (path !~ /^[0-9a-f]+ [ *]/) exit 1; sub(/^[0-9a-f]+ [ *]/, "", path); if (index(path, root) != 1 || path ~ /(^|\/)\.\.(\/|$)/) exit 1 }' "$root/$manifest"
done
sha1sum -c "$root/SHA1SUMSSUM"
sha1sum -c "$root/SHA1SUMS"
sha256sum -c "$root/SHA256SUMSSUM"
sha256sum -c "$root/SHA256SUMS"
printf '%s  %s\n' "$binary_hash" "$root/bin/$component" "$apply_hash" "$root/apply.sh" | sha256sum -c -
if [[ -n ${6:-} ]]; then
    [[ "$6" =~ ^[0-9a-f]{40}$ ]]
    go version -m "$root/bin/$component" | grep -F "vcs.revision=$6" >/dev/null
    go version -m "$root/bin/$component" | grep -F 'vcs.modified=false' >/dev/null
fi
printf 'AGENT_PRODUCER_PACKAGE_OK component=%s package_id=%s\n' "$component" "$root"

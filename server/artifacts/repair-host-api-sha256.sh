#!/usr/bin/env bash
set -euo pipefail

# Repair only the checksum contract of the already released Host API binary.
# The current host-api main branch is a separate migration candidate, not a
# drop-in runtime replacement for this Server release.
if [ "$#" -ne 3 ]; then
    echo 'usage: repair-host-api-sha256.sh ORIGINAL.tar.gz OUTPUT.tar.gz SOURCE_DATE_EPOCH' >&2
    exit 2
fi

original=$1
output=$2
source_date_epoch=$3
root=301025de31c07073cc03efa17e1ab8ef

[[ "$source_date_epoch" =~ ^[0-9]+$ ]]
test -f "$original"
test ! -e "$output"

scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
tar -tzf "$original" >"$scratch/listing"
printf '%s\n' \
    "$root/" \
    "$root/SHA1SUMS" \
    "$root/SHA1SUMSSUM" \
    "$root/apply.sh" \
    "$root/bin/" \
    "$root/bin/host-api" >"$scratch/expected"
diff -u <(LC_ALL=C sort "$scratch/expected") \
        <(LC_ALL=C sort "$scratch/listing")
if tar -tvzf "$original" | grep -Eq '^[lh]'; then
    echo 'Host API archive must not contain links' >&2
    exit 1
fi

mkdir "$scratch/content"
tar --no-same-owner --no-same-permissions -xzf "$original" -C "$scratch/content"
cd "$scratch/content"
sha1sum -c "$root/SHA1SUMSSUM"
sha1sum -c "$root/SHA1SUMS"
echo '74de989cde3dfe3c1c7bb84c87a4661ce0ad7a3c83c52d7d6e52c4b3b5942bac' \
    " $root/bin/host-api" | sha256sum -c -
echo 'c087761e6efe66a1750bfc9adc7bc0a8473eeebbfe32e5b5fbca27554217c3b1' \
    " $root/apply.sh" | sha256sum -c -

sha256sum -b "$root/apply.sh" "$root/bin/host-api" >"$root/SHA256SUMS"
sha256sum "$root/SHA256SUMS" >"$root/SHA256SUMSSUM"
sha256sum -c "$root/SHA256SUMSSUM"
sha256sum -c "$root/SHA256SUMS"

tar --sort=name --format=gnu --mtime="@$source_date_epoch" \
    --owner=0 --group=0 --numeric-owner -cf - "$root" | gzip -n >"$output"
test -s "$output"

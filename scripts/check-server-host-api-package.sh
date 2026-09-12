#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo 'usage: check-server-host-api-package.sh HOST_API_ARCHIVE' >&2
    exit 2
fi

archive=$(realpath -- "$1")
root=301025de31c07073cc03efa17e1ab8ef
test -s "$archive"
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT

tar -tzf "$archive" >"$scratch/listing"
printf '%s\n' \
    "$root/" \
    "$root/SHA1SUMS" \
    "$root/SHA1SUMSSUM" \
    "$root/SHA256SUMS" \
    "$root/SHA256SUMSSUM" \
    "$root/apply.sh" \
    "$root/bin/" \
    "$root/bin/host-api" >"$scratch/expected"
diff -u <(LC_ALL=C sort "$scratch/expected") \
        <(LC_ALL=C sort "$scratch/listing")
if tar -tvzf "$archive" | grep -Eq '^[lh]'; then
    echo 'Host API archive must not contain links' >&2
    exit 1
fi

mkdir "$scratch/content"
tar --no-same-owner --no-same-permissions -xzf "$archive" -C "$scratch/content"
cd "$scratch/content"
sha1sum -c "$root/SHA1SUMSSUM"
sha1sum -c "$root/SHA1SUMS"
# Exactly the two checks executed by config.sh on an uncached host download.
sha256sum -c "$root/SHA256SUMSSUM"
sha256sum -c "$root/SHA256SUMS"
echo '74de989cde3dfe3c1c7bb84c87a4661ce0ad7a3c83c52d7d6e52c4b3b5942bac' \
    " $root/bin/host-api" | sha256sum -c -
echo 'c087761e6efe66a1750bfc9adc7bc0a8473eeebbfe32e5b5fbca27554217c3b1' \
    " $root/apply.sh" | sha256sum -c -
printf 'HOST_API_PACKAGE_OK archive_sha256=%s binary=unchanged sha1=pass sha256=pass\n' \
    "$(sha256sum "$archive" | awk '{print $1}')"

#!/bin/sh
# Verify the original published Engine archive before extraction or after assembly.
set -eu
test "$#" -eq 3 || { echo 'usage: verify-engine-archive ARCHIVE VERSION SHA256' >&2; exit 2; }
archive=$1 expected_version=$2 expected_sha256=$3
printf '%s\n' "$expected_version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'
printf '%s\n' "$expected_sha256" | grep -Eq '^[0-9a-f]{64}$'
test -f "$archive"
printf '%s  %s\n' "$expected_sha256" "$archive" | sha256sum -c -
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
unzip -Z1 "$archive" > "$work/listing"
if grep -Eq '(^/|(^|/)\.\.(/|$))' "$work/listing"; then
    echo 'Unsafe Orchestration Engine JAR path' >&2
    exit 1
fi
sort "$work/listing" | uniq -d > "$work/duplicates"
if test -s "$work/duplicates"; then
    echo 'Duplicate Orchestration Engine JAR path' >&2
    exit 1
fi
unzip -p "$archive" META-INF/MANIFEST.MF > "$work/manifest"
if tr -d '\r' < "$work/manifest" | grep -Fx "Implementation-Version: $expected_version" >/dev/null; then :; else
    echo 'Orchestration Engine implementation version mismatch' >&2
    exit 1
fi
if grep -Eq '^WEB-INF/lib/freemarker-2\.3\.(3[0-4]|[0-2][0-9])\.jar$' "$work/listing"; then
    echo 'Rejected old Freemarker dependency' >&2
    exit 1
fi
freemarker_entries=$(grep -E '^WEB-INF/lib/freemarker-[^/]+\.jar$' "$work/listing" || true)
if test "$freemarker_entries" != 'WEB-INF/lib/freemarker-2.3.35.jar'; then
    echo 'Freemarker archive contract mismatch: expected exactly 2.3.35' >&2
    exit 1
fi
if grep -Eq '^WEB-INF/lib/hazelcast-(5\.7\.[0-5]|5\.7\.3-pasturestack\.[0-9]+)([.-]|\.jar$)' "$work/listing"; then
    echo 'Rejected old Hazelcast dependency' >&2
    exit 1
fi
hazelcast_entries=$(grep -E '^WEB-INF/lib/hazelcast-[^/]+\.jar$' "$work/listing" || true)
if test "$hazelcast_entries" != 'WEB-INF/lib/hazelcast-5.7.6.jar'; then
    echo 'Hazelcast archive contract mismatch: expected exactly 5.7.6' >&2
    exit 1
fi
unzip -p "$archive" WEB-INF/lib/hazelcast-5.7.6.jar > "$work/hazelcast.jar"
printf '%s  %s\n' '825b5fc9526a10549bcb580f2d6c03bf1f5667625661722c0406ea6f796e83f2' "$work/hazelcast.jar" | sha256sum -c -
printf 'ENGINE_ARCHIVE_CONTRACT_OK version=%s freemarker=2.3.35 hazelcast=5.7.6 sha256=%s\n' "$expected_version" "$expected_sha256"

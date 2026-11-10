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
if grep -Eq '^WEB-INF/lib/hazelcast-(5\.7\.[0-6]|5\.7\.3-pasturestack\.[0-9]+)([.-]|\.jar$)' "$work/listing"; then
    echo 'Rejected old Hazelcast dependency' >&2
    exit 1
fi
hazelcast_entries=$(grep -E '^WEB-INF/lib/hazelcast-[^/]+\.jar$' "$work/listing" || true)
if test "$hazelcast_entries" != 'WEB-INF/lib/hazelcast-5.7.7.jar'; then
    echo 'Hazelcast archive contract mismatch: expected exactly 5.7.7' >&2
    exit 1
fi
unzip -p "$archive" WEB-INF/lib/hazelcast-5.7.7.jar > "$work/hazelcast.jar"
printf '%s  %s\n' 'a72ddfd7638527cbccd79d9d3e3611e2979cadd78e615381f230c07a2767b631' "$work/hazelcast.jar" | sha256sum -c -
if ! unzip -p "$work/hazelcast.jar" META-INF/maven/org.json/json/pom.properties > "$work/json.properties" 2>/dev/null; then
    echo 'Hazelcast embedded JSON metadata missing' >&2
    exit 1
fi
if test "$(sed -n 's/^version=//p' "$work/json.properties")" != '20260719'; then
    echo 'Hazelcast embedded JSON version mismatch: expected exactly 20260719' >&2
    exit 1
fi

guava_entries=$(grep -E '^WEB-INF/lib/guava-[^/]+\.jar$' "$work/listing" || true)
if test "$guava_entries" != 'WEB-INF/lib/guava-33.7.2-jre.jar'; then
    echo 'Guava archive contract mismatch: expected exactly 33.7.2-jre' >&2
    exit 1
fi
unzip -p "$archive" WEB-INF/lib/guava-33.7.2-jre.jar > "$work/guava.jar"
printf '%s  %s\n' 'b530942257fb935f8b2cfaa5f8eb5bd59c555fd8e8d01b8ce98912e077ea606c' "$work/guava.jar" | sha256sum -c -
printf 'ENGINE_ARCHIVE_CONTRACT_OK version=%s freemarker=2.3.35 hazelcast=5.7.7 guava=33.7.2-jre sha256=%s\n' "$expected_version" "$expected_sha256"

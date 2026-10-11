#!/usr/bin/env bash
# Build-time validation of the original Host/Secret/Telemetry producer assets.
set -euo pipefail
[[ $# == 6 ]] || { echo 'usage: verify-runtime-producer TYPE VERSION COMMIT ARCHIVE BINARY_SHA256 OUTPUT' >&2; exit 2; }
type=$1 version=$2 commit=$3 archive=$4 binary_sha=$5 output=$6
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$commit" =~ ^[0-9a-f]{40}$ && "$binary_sha" =~ ^[0-9a-f]{64}$ ]]
[[ "$output" == "/out/$type" && ! -e "$output" ]]
listing=$(mktemp /tmp/runtime-producer-list.XXXXXXXX)
expected=$(mktemp /tmp/runtime-producer-expected.XXXXXXXX)
verbose=$(mktemp /tmp/runtime-producer-verbose.XXXXXXXX)
duplicates=$(mktemp /tmp/runtime-producer-duplicates.XXXXXXXX)
trap 'rm -f -- "$listing" "$expected" "$verbose" "$duplicates"' EXIT
tar -tJf "$archive" > "$listing"
! grep -Eq '(^/|(^|/)\.\.(/|$))' "$listing"
sort "$listing" | uniq -d > "$duplicates"
test ! -s "$duplicates"
tar -tvJf "$archive" > "$verbose"
! grep -Eq '^[lh]' "$verbose"
case "$type" in
    host-provisioner)
        package_root="host-provisioner-${version}-linux-amd64"
        while IFS= read -r member; do
            case "$member" in "$package_root/"|"$package_root/"*) ;; *) exit 1 ;; esac
        done < "$listing"
        mkdir -p "$output"
        tar --no-same-owner --no-same-permissions --strip-components=1 -xJf "$archive" -C "$output"
        test -s "$output/LICENSE" && test -s "$output/ORIGIN.md"
        test "$(find "$output/licenses" -type f | wc -l)" -eq 35
        version_flag=-v
        ;;
    secret-delivery-api|usage-telemetry-agent)
        printf '%s\n' "$type" "$type-LICENSES.txt" "$type-SOURCES.txt" "$type-THIRD-PARTY-NOTICES.md" > "$expected"
        if [[ "$type" == usage-telemetry-agent ]]; then printf '%s\n' "$type-PRIVACY.md" >> "$expected"; fi
        sort "$listing" | cmp - <(sort "$expected")
        mkdir -p "$output"
        tar --no-same-owner --no-same-permissions -xJf "$archive" -C "$output"
        grep -Fx "Release source commit: $commit" "$output/$type-SOURCES.txt" >/dev/null
        version_flag=--version
        ;;
    *) echo 'Unknown runtime producer' >&2; exit 2 ;;
esac
test -f "$output/$type" && test ! -L "$output/$type"
echo "$binary_sha  $output/$type" | sha256sum -c -
chmod 0755 "$output/$type"
"$output/$type" "$version_flag" | grep -F "$version" >/dev/null
metadata=$(go version -m "$output/$type")
test "$(printf '%s\n' "$metadata" | awk 'NR==1 {print $2}')" = go1.27.2
for field in 'CGO_ENABLED=0' 'GOOS=linux' 'GOARCH=amd64' 'GOAMD64=v1'; do
    printf '%s\n' "$metadata" | grep -F "$field" >/dev/null
done
printf '%s\n' "Release source commit: $commit" "Binary SHA-256: $binary_sha" "Go compiler: 1.27.2" > "$output/SERVER-PRODUCER-SOURCES.txt"
mkdir -p "/out/$type-licenses"
for entry in "$output"/*; do
    if [[ "${entry##*/}" != "$type" ]]; then mv -- "$entry" "/out/$type-licenses/"; fi
done

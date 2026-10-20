#!/usr/bin/env bash
# Validate the immutable explorer product before it can replace the base image UI.
set -euo pipefail
export LC_ALL=C

[[ $# == 4 ]] || { echo 'usage: prepare-api-explorer ARCHIVE VERSION COMMIT OUTPUT' >&2; exit 2; }
archive=$1 version=$2 commit=$3 output=$4
[[ "$version" == 1.1.19 && "$commit" =~ ^[0-9a-f]{40}$ ]]
test ! -e "$output"
test ! -L "$output"
listing=$(mktemp)
verbose=$(mktemp)
trap 'rm -f -- "$listing" "$verbose"' EXIT

# An exact canonical member set rejects traversal, duplicate/aliased names,
# source maps, extra executables and unexpected license/runtime versions.
tar -tzf "$archive" | sort > "$listing"
sort <<'MEMBERS' | cmp - "$listing"
./
./fonts/
./fonts/bootstrap-icons.woff
./fonts/bootstrap-icons.woff2
./licenses/
./licenses/LICENSE.txt
./licenses/ORIGIN.md
./licenses/THIRD-PARTY-NOTICES.md
./licenses/bootstrap-5.3.8/
./licenses/bootstrap-5.3.8/LICENSE
./licenses/bootstrap-icons-1.13.1/
./licenses/bootstrap-icons-1.13.1/LICENSE
./licenses/handlebars-4.7.10/
./licenses/handlebars-4.7.10/LICENSE
./licenses/inherited-vendor/
./licenses/inherited-vendor/LICENSE-async-0.9.0
./licenses/inherited-vendor/LICENSE-jquery-scrollintoview-1.8
./licenses/inherited-vendor/LICENSE-jsonformatter-2009
./licenses/inherited-vendor/LICENSE-polyfill-compat
./licenses/inherited-vendor/NOTICE-json2
./licenses/jquery-4.0.0/
./licenses/jquery-4.0.0/LICENSE.txt
./ui.css
./ui.js
./ui.min.css
./ui.min.js
./version.json
MEMBERS
tar -tvzf "$archive" > "$verbose"
if grep -Eq '^[^d-]' "$verbose"; then
    echo 'API Explorer archive permits only regular files and directories' >&2
    exit 1
fi
mkdir -p "$output"
tar --no-same-owner --no-same-permissions -xzf "$archive" -C "$output"
test -z "$(find "$output" -type l -print -quit)"
while IFS= read -r member; do
    if [[ "$member" == */ ]]; then
        test -d "$output/$member"
    else
        test -f "$output/$member"
        test ! -L "$output/$member"
        test -s "$output/$member"
    fi
done < "$listing"
identity=$(tr -d '[:space:]' < "$output/version.json")
test "$identity" = "{\"version\":\"${version}\",\"commit\":\"${commit:0:7}\"}"
grep -aF 'handlebars v4.7.10' "$output/ui.js" >/dev/null
for marker in PastureStackUi pasturestack:modal:shown pasturestack:modal:hidden data-pasturestack-toggle; do
    grep -aF "$marker" "$output/ui.js" >/dev/null
done
if grep -aEq 'Bootstrap v3\.4\.1|bs\.(button|tooltip|popover|modal|dropdown)|data-loading-text|data-toggle="dropdown"' "$output/ui.js"; then
    echo 'Rejected Bootstrap executable surface in API Explorer' >&2
    exit 1
fi
grep -Eq 'Bootstrap +v5\.3\.8' "$output/ui.css"
grep -F 'url("./fonts/bootstrap-icons.woff2' "$output/ui.css" >/dev/null
printf 'SERVER_API_EXPLORER_PRODUCT_OK version=%s commit=%s handlebars=4.7.10 exact_members=27\n' "$version" "$commit"

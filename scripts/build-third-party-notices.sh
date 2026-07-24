#!/usr/bin/env bash
set -euo pipefail

bundle=${1:?runtime license bundle is required}
output=${2:?output path is required}
release_version=${3:?numeric release version is required}

if ! [[ "$release_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo 'release version must use numeric x.y.z form' >&2
  exit 2
fi

bundle_name="pasturestack-runtime-licenses-${release_version}.tar.xz"
bundle_root="pasturestack-runtime-licenses-${release_version}"
test -s "$bundle"
test "$(basename "$bundle")" = "$bundle_name"

workdir=$(mktemp -d "${TMPDIR:-/tmp}/pasturestack-third-party-notices.XXXXXX")
cleanup()
{
  rm -rf "$workdir"
}
trap cleanup EXIT

sources="$workdir/SOURCES.tsv"
tar -xJOf "$bundle" "$bundle_root/SOURCES.tsv" >"$sources"
test -s "$sources"
test "$(head -n 1 "$sources")" = $'asset\tcomponent\trepository\tcommit\tlicense_summary'
entry_count=$(($(wc -l <"$sources") - 1))
test "$entry_count" -gt 0

{
  cat <<EOF_HEADER
PastureStack Server v${release_version} — Third-Party Notices

PastureStack is an independent community effort to preserve, audit, and modernize the Rancher 1.6 ecosystem. It is not affiliated with or endorsed by Rancher Labs or SUSE.

This file is a navigation aid, not a replacement for any license, notice, patent, privacy, or copyright text. Copyright and authorship remain with the respective upstream projects and contributors. PastureStack claims only its own changes and packaging work.

Complete legal texts, source coordinates, embedded-archive notices, and file checksums are distributed in ${bundle_name}. The matching SPDX 2.3 software bill of materials is distributed as sbom.spdx.json.

Runtime component index:
EOF_HEADER

  tail -n +2 "$sources" |
    while IFS=$'\t' read -r asset component repository commit license_summary; do
      test -n "$asset"
      test -n "$component"
      test -n "$repository"
      test -n "$commit"
      test -n "$license_summary"
      cat <<EOF_COMPONENT

* ${component}
  Asset: ${asset}
  Source: ${repository} @ ${commit}
  License summary: ${license_summary}
EOF_COMPONENT
    done
} >"$output"

test -s "$output"
test "$(grep -c '^\* ' "$output")" -eq "$entry_count"
grep -F "$bundle_name" "$output" >/dev/null
grep -F 'catalog-service-0.20.7.tar.xz' "$output" >/dev/null
grep -F 'https://github.com/PastureStack/catalog-service @ 26bf62b24b4bf7893821f7a3f744f2e1d919411f' \
  "$output" >/dev/null

printf 'THIRD_PARTY_NOTICES_OK release=v%s entries=%s sha256=%s\n' \
  "$release_version" \
  "$entry_count" \
  "$(sha256sum "$output" | awk '{print $1}')"

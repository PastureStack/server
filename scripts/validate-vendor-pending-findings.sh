#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
    printf 'usage: %s TRACKER_JSON UNRESOLVED_TSV RELEASE_TAG\n' "$0" >&2
    exit 2
fi

tracker=$1
unresolved=$2
release_tag=$3
today=${PASTURESTACK_POLICY_DATE:-$(date -u +%F)}

test -s "$tracker"
test -f "$unresolved"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

jq -e --arg release "$release_tag" --arg today "$today" '
  .schemaVersion == 1
  and .release == $release
  and .policy.allowedSeverities == ["LOW", "MEDIUM"]
  and .policy.requiresEmptyFixedVersion == true
  and .policy.vendorStatus == "needs-evaluation"
  and .policy.scanTarget == "merged-rootfs"
  and ((.policy.trivyTarget | type) == "string" and (.policy.trivyTarget | length) > 0)
  and ((.findings | type) == "array" and (.findings | length) > 0)
  and all(.findings[];
      (.vulnerabilityId | test("^CVE-[0-9]{4}-[0-9]+$"))
      and (.severity == "LOW" or .severity == "MEDIUM")
      and .vendorStatus == "needs-evaluation"
      and .source == ("https://ubuntu.com/security/" + .vulnerabilityId)
      and (.reviewAfter | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))
      and .reviewAfter >= $today
      and ((.packages | type) == "array" and (.packages | length) > 0)
      and all(.packages[];
          ((.name | type) == "string" and (.name | length) > 0)
          and ((.installedVersion | type) == "string" and (.installedVersion | length) > 0)))
  and (([.findings[].vulnerabilityId] | unique | length) == (.findings | length))
' "$tracker" >/dev/null

if awk -F '\t' '
    NF != 6 { bad=1 }
    $1 == "CRITICAL" || $1 == "HIGH" { bad=1 }
    $5 != "" { bad=1 }
    END { exit bad ? 1 : 0 }
' "$unresolved"; then
    :
else
    printf 'SERVER_VENDOR_PENDING_POLICY_VIOLATION file=%s\n' "$unresolved" >&2
    exit 1
fi

jq -r '
  . as $root
  | .findings[] as $finding
  | $finding.packages[]
  | [$finding.severity, $finding.vulnerabilityId, .name, .installedVersion,
     "", $root.policy.trivyTarget]
  | @tsv
' "$tracker" | LC_ALL=C sort -u >"$tmpdir/expected.tsv"
LC_ALL=C sort -u "$unresolved" >"$tmpdir/actual.tsv"

if ! cmp -s "$tmpdir/expected.tsv" "$tmpdir/actual.tsv"; then
    printf 'SERVER_VENDOR_PENDING_SET_MISMATCH tracker=%s unresolved=%s\n' \
        "$tracker" "$unresolved" >&2
    diff -u "$tmpdir/expected.tsv" "$tmpdir/actual.tsv" >&2 || true
    exit 1
fi

tracked_count=$(wc -l <"$tmpdir/actual.tsv" | tr -d ' ')
unique_cves=$(jq '[.findings[].vulnerabilityId] | unique | length' "$tracker")
review_after=$(jq -r '[.findings[].reviewAfter] | min' "$tracker")
printf 'SERVER_VENDOR_PENDING_OK tracked=%s unique_cves=%s review_after=%s untracked=0 critical_high=0 fixed_available=0\n' \
    "$tracked_count" "$unique_cves" "$review_after"

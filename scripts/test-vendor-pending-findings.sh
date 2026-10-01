#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
validator="$repo_root/scripts/validate-vendor-pending-findings.sh"
tracker="$repo_root/server/security/vendor-pending.json"
release=$(jq -r '.release' "$tracker")
fixture_dir=$(mktemp -d)
trap 'rm -rf "$fixture_dir"' EXIT

jq -r '
  . as $root | .findings[] as $finding | $finding.packages[]
  | [$finding.severity, $finding.vulnerabilityId, .name, .installedVersion,
     "", $root.policy.trivyTarget] | @tsv
' "$tracker" > "$fixture_dir/exact.tsv"
bash "$validator" "$tracker" "$fixture_dir/exact.tsv" "$release"

reject_case() {
    local name=$1
    local scan=$2
    local input_tracker=${3:-$tracker}
    if bash "$validator" "$input_tracker" "$scan" "$release" >"$fixture_dir/$name.log" 2>&1; then
        printf 'VENDOR_PENDING_UNEXPECTED_ACCEPT case=%s\n' "$name" >&2
        exit 1
    fi
    printf 'VENDOR_PENDING_REJECT_OK case=%s\n' "$name"
}

# A newly found HIGH must still block even when all pending package rows match.
{ cat "$fixture_dir/exact.tsv"; printf 'HIGH\tCVE-2026-91776\tcom.fasterxml.jackson.core:jackson-databind\t2.22.2\t2.22.3\tJava\n'; } > "$fixture_dir/high.tsv"
reject_case high "$fixture_dir/high.tsv"
awk -F '\t' 'BEGIN { OFS="\t" } NR==1 { $5="released-fix" } { print }' "$fixture_dir/exact.tsv" > "$fixture_dir/fixed.tsv"
reject_case available_fix "$fixture_dir/fixed.tsv"
{ cat "$fixture_dir/exact.tsv"; printf 'LOW\tCVE-2026-99999\tuntracked\t1\t\t/rootfs (ubuntu 26.04)\n'; } > "$fixture_dir/untracked.tsv"
reject_case untracked "$fixture_dir/untracked.tsv"
tail -n +2 "$fixture_dir/exact.tsv" > "$fixture_dir/missing.tsv"
reject_case missing_package "$fixture_dir/missing.tsv"
jq '.findings[0].reviewAfter="2000-01-01"' "$tracker" > "$fixture_dir/expired.json"
reject_case expired_review "$fixture_dir/exact.tsv" "$fixture_dir/expired.json"
printf 'VENDOR_PENDING_TESTS_OK accepted=1 rejected=5 policy_unchanged=true\n'

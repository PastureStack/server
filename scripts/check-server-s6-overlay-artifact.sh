#!/usr/bin/env bash
set -euo pipefail

artifact="${PASTURESTACK_S6_OVERLAY_ARTIFACT:-}"
expected_version="${PASTURESTACK_EXPECTED_S6_OVERLAY_VERSION:-1.19.1.1}"
expected_sha256="${PASTURESTACK_EXPECTED_S6_OVERLAY_ARTIFACT_SHA256:-b5d360383dd519a33bd39651c43c49b4cf0e95344a94ba65dd8628eefd9ee5cb}"
expected_source_commit="${PASTURESTACK_EXPECTED_S6_OVERLAY_SOURCE_COMMIT:-b8e0312a7d888448d2a5d5d092a1bfbfe388522a}"
expected_name="s6-overlay-amd64-v${expected_version}.tar.gz"

if [ -z "$artifact" ]; then
  if [ "${RC16_REQUIRE_S6_OVERLAY_ARTIFACT:-0}" = "1" ]; then
    echo 'SERVER_S6_OVERLAY_ARTIFACT_PATH_UNSET env=PASTURESTACK_S6_OVERLAY_ARTIFACT' >&2
    exit 1
  fi
  printf 'SERVER_S6_OVERLAY_ARTIFACT_SKIPPED version=%s reason=PASTURESTACK_S6_OVERLAY_ARTIFACT_unset\n' "$expected_version"
  exit 0
fi

test -f "$artifact"
test "$(basename "$artifact")" = "$expected_name"
actual_sha256=$(sha256sum "$artifact" | awk '{print $1}')
test "$actual_sha256" = "$expected_sha256"
test "$(stat -c %s "$artifact")" = 1713081

if tar -tzf "$artifact" | grep -E '(^/|(^|/)\.\.(/|$))' >/dev/null; then
  echo 'SERVER_S6_OVERLAY_ARTIFACT_UNSAFE_MEMBER' >&2
  exit 1
fi
for entry in ./init ./bin/s6-svscan ./etc/s6/init/init-stage1 ./etc/s6/init/init-stage2 ./etc/s6/init/init-stage3; do
  test "$(tar -tzf "$artifact" | grep -Fxc "$entry")" -eq 1
done

printf 'SERVER_S6_OVERLAY_ARTIFACT_OK version=%s sha256=%s source=%s upstream_asset=unchanged license=ISC legal_material=runtime-license-bundle\n' \
  "$expected_version" "$actual_sha256" "$expected_source_commit"

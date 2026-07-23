#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

failure_count=0
if grep -R -n -E '\bunpack200\b|java\.util\.jar\.Pack200' server scripts --exclude='check-server-pack200-free.sh'; then
  failure_count=$((failure_count + 1))
fi

if ! grep -q 'Pack200 cattle resources are not supported by the rc16 JDK25 server image' server/artifacts/install_cattle_binaries; then
  echo 'PACK200_FAIL_CLOSED_MESSAGE_MISSING file=server/artifacts/install_cattle_binaries'
  failure_count=$((failure_count + 1))
fi

printf 'failure_count=%s
' "$failure_count"
if [ "$failure_count" -gt 0 ]; then
  exit 1
fi

echo 'SERVER_PACK200_FREE_OK scope=server,scripts policy=fail-closed-on-pack200-resources'

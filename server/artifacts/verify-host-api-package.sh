#!/usr/bin/env bash
set -euo pipefail
[[ $# == 4 || $# == 5 ]] || { echo 'usage: verify-host-api-package ARCHIVE PACKAGE_ID BINARY_SHA256 APPLY_SHA256 [SOURCE_COMMIT]' >&2; exit 2; }
bash "$(dirname "${BASH_SOURCE[0]}")/verify-agent-package.sh" host-api "$@"
printf 'HOST_API_PRODUCER_PACKAGE_OK package_id=%s\n' "$2"

#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

failure_count=0
required_flags=(
  'curl -fsSL'
  '--retry 5'
  '--retry-all-errors'
  '--retry-delay 2'
  '--connect-timeout 10'
  '--max-time 300'
)

check_curl_line() {
  local file=$1
  local line_no=$2
  local line=$3

  for flag in "${required_flags[@]}"; do
    if [[ "$line" != *"$flag"* ]]; then
      printf 'SERVER_DOCKERFILE_CURL_NOT_RETRIED file=%s line=%s missing=%s text=%s\n' "$file" "$line_no" "$flag" "$line"
      failure_count=$((failure_count + 1))
    fi
  done

  if [[ "$line" != *' -o '* ]]; then
    printf 'SERVER_DOCKERFILE_CURL_NOT_FILE_BACKED file=%s line=%s text=%s\n' "$file" "$line_no" "$line"
    failure_count=$((failure_count + 1))
  fi
}

for file in server/Dockerfile server/Dockerfile.auth-hotfix; do
  while IFS=: read -r line_no line; do
    check_curl_line "$file" "$line_no" "$line"
  done < <(grep -n 'curl -' "$file" || true)
done

if grep -R -n -I -E 'curl -s(fL|Lf)|curl -sL ' server/Dockerfile server/Dockerfile.auth-hotfix; then
  echo 'SERVER_DOCKERFILE_LEGACY_CURL_FLAGS_PRESENT'
  failure_count=$((failure_count + 1))
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

echo 'SERVER_DOCKERFILE_ARTIFACT_DOWNLOADS_OK files=server/Dockerfile,server/Dockerfile.auth-hotfix curl_retry=5 file_backed=1'

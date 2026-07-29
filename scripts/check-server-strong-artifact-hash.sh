#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

failure_count=0

reject_marker() {
  local file=$1
  local marker=$2
  local code=$3
  if grep -Fq "$marker" "$file"; then
    printf '%s file=%s marker=%s\n' "$code" "$file" "$marker"
    failure_count=$((failure_count + 1))
  fi
}

require_marker() {
  local file=$1
  local marker=$2
  local code=$3
  if ! grep -Fq "$marker" "$file"; then
    printf '%s file=%s marker=%s\n' "$code" "$file" "$marker"
    failure_count=$((failure_count + 1))
  fi
}

reject_marker server/Dockerfile 'md5sum cattle.jar' SERVER_DOCKERFILE_CATTLE_JAR_MD5_IDENTITY
reject_marker server/artifacts/cattle.sh 'md5sum $JAR' SERVER_CATTLE_SH_JAR_MD5_IDENTITY
reject_marker server/artifacts/cattle.sh 'md5sum "$JAR"' SERVER_CATTLE_SH_JAR_MD5_IDENTITY

require_marker server/Dockerfile 'sha256sum cattle.jar' SERVER_DOCKERFILE_CATTLE_JAR_SHA256_IDENTITY_MISSING
require_marker server/artifacts/cattle.sh 'sha256sum "$JAR"' SERVER_CATTLE_SH_JAR_SHA256_IDENTITY_MISSING

while IFS= read -r match; do
  case "$match" in
    server/bin/mysql-strict-sql-setup.sh:*MD5SUM*'varchar(35) DEFAULT NULL,' | \
    server/artifacts/mysql-dump.sql:*MD5SUM*'varchar(35) DEFAULT NULL,' | \
    server/artifacts/mysql-dump.sql:*md5checksum*'varchar(255) DEFAULT NULL,')
      continue
      ;;
  esac

  printf 'SERVER_RUNTIME_WEAK_HASH_MARKER file_line=%s\n' "$match"
  failure_count=$((failure_count + 1))
done < <(
  grep -R -n -I -E '(^|[^[:alnum:]_])([Mm][Dd]5|md5sum)([^[:alnum:]_]|$)' \
    server scripts \
    --exclude='check-server-strong-artifact-hash.sh' \
    --exclude='check-agent-windows-strong-artifact-hash.sh' || true
)

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

echo 'SERVER_STRONG_ARTIFACT_HASH_OK scope=server-runtime artifact=cattle.jar algorithm=sha256 runtime_weak_hash_markers=0 schema_md5checksum_preserved=1'

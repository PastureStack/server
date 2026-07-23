#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

failure_count=0

fail() {
  printf '%s\n' "$1" >&2
  failure_count=$((failure_count + 1))
}

require_marker() {
  local file=$1
  local marker=$2
  local code=$3

  if ! grep -F -- "$marker" "$file" >/dev/null; then
    fail "$code"
  fi
}

reject_marker() {
  local file=$1
  local marker=$2
  local code=$3

  if grep -F -- "$marker" "$file" >/dev/null; then
    fail "$code"
  fi
}

if ! bash -n scripts/database-sanity-check.sh; then
  fail "DB_SANITY_CHECK_SYNTAX_INVALID"
fi

require_marker scripts/database-sanity-check.sh 'set -euo pipefail' DB_SANITY_CHECK_STRICT_SHELL_MISSING
require_marker scripts/database-sanity-check.sh 'container=${RC16_RANCHER_CONTAINER:-pasturestack-server}' DB_SANITY_CHECK_NEUTRAL_CONTAINER_DEFAULT_MISSING
require_marker scripts/database-sanity-check.sh 'curl_connect_timeout="${RC16_DB_SANITY_CONNECT_TIMEOUT:-5}"' DB_SANITY_CHECK_CONNECT_TIMEOUT_DEFAULT_MISSING
require_marker scripts/database-sanity-check.sh 'curl_max_time="${RC16_DB_SANITY_MAX_TIME:-20}"' DB_SANITY_CHECK_MAX_TIME_DEFAULT_MISSING
require_marker scripts/database-sanity-check.sh 'sanity_curl()' DB_SANITY_CHECK_CURL_HELPER_MISSING
require_marker scripts/database-sanity-check.sh 'curl -sS --connect-timeout "$curl_connect_timeout" --max-time "$curl_max_time" "$@"' DB_SANITY_CHECK_CURL_NOT_BOUNDED
require_marker scripts/database-sanity-check.sh 'http_code=$(sanity_curl -o "$auth_tmp" -w' DB_SANITY_CHECK_TOKEN_NOT_HELPER_BACKED
require_marker server/patches/db/core-124.xml '<changeSet author="PastureStack" id="pasturestack-catalog-table-order-guard">' DB_CATALOG_TABLE_ORDER_GUARD_MISSING
require_marker server/patches/db/core-124.xml '<preConditions onFail="HALT">' DB_CATALOG_TABLE_ORDER_HALT_MISSING
require_marker server/patches/db/core-124.xml '<tableExists tableName="catalog"/>' DB_CATALOG_TABLE_ORDER_PRECONDITION_MISSING
require_marker server/patches/db/core-124.xml '<changeSet dbms="mysql,mariadb" author="PastureStack" id="pasturestack-catalog-pinned-commit">' DB_CATALOG_PINNED_COMMIT_CHANGESET_MISSING
require_marker server/patches/db/core-124.xml '<preConditions onFail="MARK_RAN">' DB_CATALOG_PINNED_COMMIT_IDEMPOTENT_PRECONDITION_MISSING
require_marker server/patches/db/core-124.xml '<sqlCheck expectedResult="0">SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = '\''catalog'\'' AND column_name = '\''pinned_commit'\''</sqlCheck>' DB_CATALOG_PINNED_COMMIT_ERROR_FREE_PRECONDITION_MISSING
require_marker server/patches/db/core-124.xml '<changeSet dbms="h2,postgresql" author="PastureStack" id="pasturestack-catalog-pinned-commit-portable">' DB_CATALOG_PINNED_COMMIT_PORTABLE_CHANGESET_MISSING
require_marker server/patches/db/core-124.xml '<columnExists tableName="catalog" columnName="pinned_commit"/>' DB_CATALOG_PINNED_COMMIT_COLUMN_PRECONDITION_MISSING
require_marker server/patches/db/core-124.xml '<addColumn tableName="catalog">' DB_CATALOG_PINNED_COMMIT_ADD_COLUMN_MISSING
require_marker server/patches/db/core-124.xml '<column name="pinned_commit" type="varchar(255)"/>' DB_CATALOG_PINNED_COMMIT_COLUMN_DEFINITION_MISSING
reject_marker server/patches/db/core-060.xml 'pasturestack-catalog-pinned-commit' DB_CATALOG_PINNED_COMMIT_PRECEDES_TABLE_CREATION

reject_marker scripts/database-sanity-check.sh 'http_code=$(curl -sS -o "$auth_tmp" -w' DB_SANITY_CHECK_LEGACY_TOKEN_CURL

sample_run=$(mktemp -d "${TMPDIR:-/tmp}/rc16-db-sanity.XXXXXX")
sample_functions=$(mktemp "${TMPDIR:-/tmp}/rc16-db-sanity-functions.XXXXXX")
trap 'rm -rf "$sample_run" "$sample_functions"' EXIT

sed -n '/^sanity_curl()/,/^}/p' scripts/database-sanity-check.sh >"$sample_functions"

mkdir -p "$sample_run/bin"
curl_log="$sample_run/curl.log"
body="$sample_run/token.json"
output="$sample_run/output.log"

cat >"$sample_run/bin/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'CURL'
  for arg in "$@"; do
    printf '\t%s' "$arg"
  done
  printf '\n'
} >>"$RC16_DB_SANITY_CURL_LOG"

out_file=""
url=""
while [ $# -gt 0 ]; do
  case "$1" in
    -o)
      out_file="$2"
      shift
      ;;
    http://*)
      url="$1"
      ;;
  esac
  shift || true
done

case "$url" in
  http://127.0.0.1:8080/v1/token)
    [ -n "$out_file" ] && printf '%s\n' '{"type":"token","jwt":"stub"}' >"$out_file"
    printf '%s' '201'
    ;;
  *)
    printf 'unexpected curl url: %s\n' "$url" >&2
    exit 99
    ;;
esac
STUB
chmod +x "$sample_run/bin/curl"

(
  # shellcheck source=/dev/null
  source "$sample_functions"

  export PATH="$sample_run/bin:$PATH"
  export RC16_DB_SANITY_CURL_LOG="$curl_log"
  curl_connect_timeout=6
  curl_max_time=22

  http_code=$(sanity_curl -o "$body" -w '%{http_code}' \
    -X POST "http://127.0.0.1:8080/v1/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'code=admin:password')

  printf 'http_code=%s\n' "$http_code"
  printf 'token_body=%s\n' "$(cat "$body")"
) >"$output"

if ! grep -F 'http_code=201' "$output" >/dev/null; then
  fail "DB_SANITY_CHECK_TOKEN_CODE_SAMPLE_FAILED"
fi

if ! grep -F 'token_body={"type":"token","jwt":"stub"}' "$output" >/dev/null; then
  fail "DB_SANITY_CHECK_TOKEN_BODY_SAMPLE_FAILED"
fi

if ! grep -F $'CURL\t-sS\t--connect-timeout\t6\t--max-time\t22\t-o' "$curl_log" >/dev/null; then
  fail "DB_SANITY_CHECK_TOKEN_CURL_FLAGS_NOT_USED"
fi

if ! grep -F $'\t-X\tPOST\thttp://127.0.0.1:8080/v1/token\t-H\tContent-Type: application/x-www-form-urlencoded\t--data-urlencode\tcode=admin:password' "$curl_log" >/dev/null; then
  fail "DB_SANITY_CHECK_TOKEN_REQUEST_ARGS_CHANGED"
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'DB_SANITY_CHECK_OK strict_shell=1 neutral_container_default=1 curl_bounded=1 token_sample=1 catalog_pinned_commit_migration=1\n'

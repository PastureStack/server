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

if ! bash -n scripts/externaldb-restored-server-smoke.sh; then
  fail "EXTERNALDB_RESTORED_SMOKE_SYNTAX_INVALID"
fi

require_marker scripts/externaldb-restored-server-smoke.sh 'set -Eeuo pipefail' EXTERNALDB_RESTORED_SMOKE_STRICT_SHELL_MISSING
require_marker scripts/externaldb-restored-server-smoke.sh 'curl_connect_timeout="${RC16_RESTORED_SMOKE_CONNECT_TIMEOUT:-5}"' EXTERNALDB_RESTORED_SMOKE_CONNECT_TIMEOUT_DEFAULT_MISSING
require_marker scripts/externaldb-restored-server-smoke.sh 'curl_max_time="${RC16_RESTORED_SMOKE_MAX_TIME:-20}"' EXTERNALDB_RESTORED_SMOKE_MAX_TIME_DEFAULT_MISSING
require_marker scripts/externaldb-restored-server-smoke.sh 'smoke_curl()' EXTERNALDB_RESTORED_SMOKE_CURL_HELPER_MISSING
require_marker scripts/externaldb-restored-server-smoke.sh 'curl -sS --connect-timeout "$curl_connect_timeout" --max-time "$curl_max_time" "$@"' EXTERNALDB_RESTORED_SMOKE_CURL_NOT_BOUNDED
require_marker scripts/externaldb-restored-server-smoke.sh 'code=$(smoke_curl -f -o "$body" -w' EXTERNALDB_RESTORED_SMOKE_PING_NOT_HELPER_BACKED
require_marker scripts/externaldb-restored-server-smoke.sh 'v2_code=$(smoke_curl -o /dev/null -w' EXTERNALDB_RESTORED_SMOKE_V2_NOT_HELPER_BACKED
require_marker scripts/externaldb-restored-server-smoke.sh '-e "CATTLE_DB_CATTLE_MYSQL_URL=${native_jdbc_url}"' EXTERNALDB_RESTORED_SMOKE_NATIVE_CATTLE_URL_MISSING
require_marker scripts/externaldb-restored-server-smoke.sh '-e "CATTLE_DB_LIQUIBASE_MYSQL_URL=${native_jdbc_url}"' EXTERNALDB_RESTORED_SMOKE_NATIVE_LIQUIBASE_URL_MISSING

reject_marker scripts/externaldb-restored-server-smoke.sh 'curl -fsS -o "$body" -w' EXTERNALDB_RESTORED_SMOKE_LEGACY_PING_CURL
reject_marker scripts/externaldb-restored-server-smoke.sh 'curl -sS -o /dev/null -w' EXTERNALDB_RESTORED_SMOKE_LEGACY_V2_CURL

sample_run=$(mktemp -d "${TMPDIR:-/tmp}/rc16-externaldb-restored-smoke.XXXXXX")
sample_functions=$(mktemp "${TMPDIR:-/tmp}/rc16-externaldb-restored-smoke-functions.XXXXXX")
trap 'rm -rf "$sample_run" "$sample_functions"' EXIT

sed -n '/^smoke_curl()/,/^}/p' scripts/externaldb-restored-server-smoke.sh >"$sample_functions"

mkdir -p "$sample_run/bin"
curl_log="$sample_run/curl.log"
body="$sample_run/body.txt"
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
} >>"$RC16_RESTORED_SMOKE_CURL_LOG"

out_file=""
url="${*: -1}"
while [ $# -gt 0 ]; do
  case "$1" in
    -o)
      out_file="$2"
      shift
      ;;
  esac
  shift || true
done

case "$url" in
  http://127.0.0.1:18094/ping)
    [ -n "$out_file" ] && printf '%s\n' 'pong' >"$out_file"
    printf '%s' '200'
    ;;
  http://127.0.0.1:18094/v2-beta)
    printf '%s' '401'
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
  export RC16_RESTORED_SMOKE_CURL_LOG="$curl_log"
  curl_connect_timeout=7
  curl_max_time=31

  ping_code=$(smoke_curl -f -o "$body" -w '%{http_code}' "http://127.0.0.1:18094/ping")
  v2_code=$(smoke_curl -o /dev/null -w '%{http_code}' "http://127.0.0.1:18094/v2-beta")

  printf 'ping_code=%s\n' "$ping_code"
  printf 'ping_body=%s\n' "$(cat "$body")"
  printf 'v2_code=%s\n' "$v2_code"
) >"$output"

if ! grep -F 'ping_code=200' "$output" >/dev/null; then
  fail "EXTERNALDB_RESTORED_SMOKE_PING_CODE_SAMPLE_FAILED"
fi

if ! grep -F 'ping_body=pong' "$output" >/dev/null; then
  fail "EXTERNALDB_RESTORED_SMOKE_PING_BODY_SAMPLE_FAILED"
fi

if ! grep -F 'v2_code=401' "$output" >/dev/null; then
  fail "EXTERNALDB_RESTORED_SMOKE_V2_CODE_SAMPLE_FAILED"
fi

if ! grep -F $'CURL\t-sS\t--connect-timeout\t7\t--max-time\t31\t-f\t-o' "$curl_log" >/dev/null; then
  fail "EXTERNALDB_RESTORED_SMOKE_PING_CURL_FLAGS_NOT_USED"
fi

if ! grep -F $'CURL\t-sS\t--connect-timeout\t7\t--max-time\t31\t-o\t/dev/null\t-w\t%{http_code}\thttp://127.0.0.1:18094/v2-beta' "$curl_log" >/dev/null; then
  fail "EXTERNALDB_RESTORED_SMOKE_V2_CURL_FLAGS_NOT_USED"
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'EXTERNALDB_RESTORED_SMOKE_OK strict_shell=1 curl_bounded=1 ping_sample=1 v2_sample=1\n'

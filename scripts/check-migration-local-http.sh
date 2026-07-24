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

if ! bash -n scripts/migrate-server-mysql55-to-mariadb118.sh; then
  fail "MIGRATION_LOCAL_HTTP_SYNTAX_INVALID"
fi

require_marker scripts/migrate-server-mysql55-to-mariadb118.sh 'set -Eeuo pipefail' MIGRATION_LOCAL_HTTP_STRICT_SHELL_MISSING
require_marker scripts/migrate-server-mysql55-to-mariadb118.sh 'MIGRATION_CURL_CONNECT_TIMEOUT="${RC16_MIGRATION_CURL_CONNECT_TIMEOUT:-5}"' MIGRATION_LOCAL_HTTP_CONNECT_TIMEOUT_DEFAULT_MISSING
require_marker scripts/migrate-server-mysql55-to-mariadb118.sh 'MIGRATION_CURL_MAX_TIME="${RC16_MIGRATION_CURL_MAX_TIME:-15}"' MIGRATION_LOCAL_HTTP_MAX_TIME_DEFAULT_MISSING
require_marker scripts/migrate-server-mysql55-to-mariadb118.sh 'migration_curl()' MIGRATION_LOCAL_HTTP_CURL_HELPER_MISSING
require_marker scripts/migrate-server-mysql55-to-mariadb118.sh 'curl -sS --connect-timeout "$MIGRATION_CURL_CONNECT_TIMEOUT" --max-time "$MIGRATION_CURL_MAX_TIME" "$@"' MIGRATION_LOCAL_HTTP_CURL_NOT_BOUNDED
require_marker scripts/migrate-server-mysql55-to-mariadb118.sh 'migration_curl -f "http://127.0.0.1:${port}/ping"' MIGRATION_LOCAL_HTTP_WAIT_PING_NOT_HELPER_BACKED
require_marker scripts/migrate-server-mysql55-to-mariadb118.sh 'migration_curl -f "http://127.0.0.1:${HOST_HTTP_PORT}/ping" >/dev/null' MIGRATION_LOCAL_HTTP_PING_NOT_HELPER_BACKED
require_marker scripts/migrate-server-mysql55-to-mariadb118.sh 'code="$(migration_curl -o /dev/null -w' MIGRATION_LOCAL_HTTP_CHECK_NOT_HELPER_BACKED
require_marker scripts/migrate-server-mysql55-to-mariadb118.sh 'migration_curl -o "${BACKUP_DIR}/live-v2-beta.json" -w' MIGRATION_LOCAL_HTTP_V2_CAPTURE_NOT_HELPER_BACKED

reject_marker scripts/migrate-server-mysql55-to-mariadb118.sh 'curl -s "http://127.0.0.1:${port}/ping"' MIGRATION_LOCAL_HTTP_LEGACY_WAIT_PING_CURL
reject_marker scripts/migrate-server-mysql55-to-mariadb118.sh 'curl -fsS "http://127.0.0.1:${HOST_HTTP_PORT}/ping"' MIGRATION_LOCAL_HTTP_LEGACY_DIRECT_PING_CURL
reject_marker scripts/migrate-server-mysql55-to-mariadb118.sh "curl -s -o /dev/null -w '%{http_code}'" MIGRATION_LOCAL_HTTP_LEGACY_HTTP_CHECK_CURL
reject_marker scripts/migrate-server-mysql55-to-mariadb118.sh 'curl -sS -o "${BACKUP_DIR}/live-v2-beta.json" -w' MIGRATION_LOCAL_HTTP_LEGACY_V2_CAPTURE_CURL

sample_run=$(mktemp -d "${TMPDIR:-/tmp}/rc16-migration-local-http.XXXXXX")
sample_functions=$(mktemp "${TMPDIR:-/tmp}/rc16-migration-local-http-functions.XXXXXX")
trap 'rm -rf "$sample_run" "$sample_functions"' EXIT

sed -n '/^migration_curl()/,/^}/p' scripts/migrate-server-mysql55-to-mariadb118.sh >"$sample_functions"

mkdir -p "$sample_run/bin"
curl_log="$sample_run/curl.log"
body="$sample_run/body.json"
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
} >>"$RC16_MIGRATION_LOCAL_HTTP_CURL_LOG"

out_file=""
want_code=0
url="${*: -1}"
while [ $# -gt 0 ]; do
  case "$1" in
    -o)
      out_file="$2"
      shift
      ;;
    -w)
      want_code=1
      shift
      ;;
  esac
  shift || true
done

case "$url" in
  http://127.0.0.1:8080/ping)
    printf '%s\n' 'pong'
    ;;
  http://127.0.0.1:8080/v2-beta)
    [ -n "$out_file" ] && [ "$out_file" != /dev/null ] && printf '%s\n' '{"type":"apiRoot"}' >"$out_file"
    [ "$want_code" = 1 ] && printf '%s' '401'
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
  export RC16_MIGRATION_LOCAL_HTTP_CURL_LOG="$curl_log"
  MIGRATION_CURL_CONNECT_TIMEOUT=4
  MIGRATION_CURL_MAX_TIME=11

  ping_body=$(migration_curl -f "http://127.0.0.1:8080/ping")
  check_code=$(migration_curl -o /dev/null -w '%{http_code}' "http://127.0.0.1:8080/v2-beta")
  capture_code=$(migration_curl -o "$body" -w '%{http_code}\n' "http://127.0.0.1:8080/v2-beta")

  printf 'ping_body=%s\n' "$ping_body"
  printf 'check_code=%s\n' "$check_code"
  printf 'capture_code=%s\n' "$capture_code"
  printf 'capture_body=%s\n' "$(cat "$body")"
) >"$output"

for expected in \
  'ping_body=pong' \
  'check_code=401' \
  'capture_code=401' \
  'capture_body={"type":"apiRoot"}'; do
  if ! grep -F -- "$expected" "$output" >/dev/null; then
    fail "MIGRATION_LOCAL_HTTP_SAMPLE_OUTPUT_MISSING expected=$expected"
  fi
done

for expected in \
  $'CURL\t-sS\t--connect-timeout\t4\t--max-time\t11\t-f\thttp://127.0.0.1:8080/ping' \
  $'CURL\t-sS\t--connect-timeout\t4\t--max-time\t11\t-o\t/dev/null\t-w\t%{http_code}\thttp://127.0.0.1:8080/v2-beta' \
  $'CURL\t-sS\t--connect-timeout\t4\t--max-time\t11\t-o\t'"$body"$'\t-w\t%{http_code}\\n\thttp://127.0.0.1:8080/v2-beta'; do
  if ! grep -F -- "$expected" "$curl_log" >/dev/null; then
    fail "MIGRATION_LOCAL_HTTP_CURL_ARGS_MISSING expected=$expected"
  fi
done

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'MIGRATION_LOCAL_HTTP_OK strict_shell=1 curl_bounded=1 local_probe_sample=1\n'

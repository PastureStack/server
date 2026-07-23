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

if ! bash -n scripts/enable-local-auth-with-rollback.sh; then
  fail "LOCAL_AUTH_ROLLBACK_SYNTAX_INVALID"
fi

require_marker scripts/enable-local-auth-with-rollback.sh 'set -euo pipefail' LOCAL_AUTH_ROLLBACK_STRICT_SHELL_MISSING
require_marker scripts/enable-local-auth-with-rollback.sh 'curl_connect_timeout=${RC16_CURL_CONNECT_TIMEOUT:-5}' LOCAL_AUTH_ROLLBACK_CONNECT_TIMEOUT_DEFAULT_MISSING
require_marker scripts/enable-local-auth-with-rollback.sh 'auth_curl()' LOCAL_AUTH_ROLLBACK_CURL_HELPER_MISSING
require_marker scripts/enable-local-auth-with-rollback.sh 'curl -fsS --connect-timeout "$curl_connect_timeout" --max-time "$curl_timeout" "$@"' LOCAL_AUTH_ROLLBACK_CURL_NOT_BOUNDED
require_marker scripts/enable-local-auth-with-rollback.sh 'body=$(auth_curl "$url/ping"' LOCAL_AUTH_ROLLBACK_PING_NOT_HELPER_BACKED
require_marker scripts/enable-local-auth-with-rollback.sh 'auth_curl \' LOCAL_AUTH_ROLLBACK_API_CALLS_NOT_HELPER_BACKED
require_marker scripts/enable-local-auth-with-rollback.sh '"$base_url/v1/localauthconfigs"' LOCAL_AUTH_ROLLBACK_LOCALAUTH_URL_MISSING
require_marker scripts/enable-local-auth-with-rollback.sh '"$base_url/v1/token"' LOCAL_AUTH_ROLLBACK_TOKEN_URL_MISSING
require_marker scripts/enable-local-auth-with-rollback.sh '"$base_url/v2-beta/projects/$project_id/hosts"' LOCAL_AUTH_ROLLBACK_HOSTS_URL_MISSING

reject_marker scripts/enable-local-auth-with-rollback.sh 'curl -fsS --max-time "$curl_timeout"' LOCAL_AUTH_ROLLBACK_LEGACY_UNBOUNDED_CURL

sample_run=$(mktemp -d "${TMPDIR:-/tmp}/rc16-local-auth-rollback.XXXXXX")
sample_functions=$(mktemp "${TMPDIR:-/tmp}/rc16-local-auth-rollback-functions.XXXXXX")
trap 'rm -rf "$sample_run" "$sample_functions"' EXIT

sed -n '/^auth_curl()/,/^}/p' scripts/enable-local-auth-with-rollback.sh >"$sample_functions"

mkdir -p "$sample_run/bin"
curl_log="$sample_run/curl.log"
json_payload="$sample_run/local-auth-config.json"
token_payload="$sample_run/token-request.form"
token_file="$sample_run/local-admin-jwt.txt"
hosts_json="$sample_run/hosts.json"
output="$sample_run/output.log"

printf '%s\n' '{"enabled":true,"username":"admin","password":"password"}' >"$json_payload"
printf '%s' 'code=admin%3Apassword' >"$token_payload"
printf '%s\n' 'jwt-token' >"$token_file"

cat >"$sample_run/bin/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'CURL'
  for arg in "$@"; do
    printf '\t%s' "$arg"
  done
  printf '\n'
} >>"$RC16_LOCAL_AUTH_CURL_LOG"

url="${*: -1}"
case "$url" in
  http://127.0.0.1:8080/ping)
    printf '%s\n' 'pong'
    ;;
  http://127.0.0.1:8080/v1/localauthconfigs)
    printf '%s\n' '{"type":"localAuthConfig"}'
    ;;
  http://127.0.0.1:8080/v1/token)
    printf '%s\n' '{"type":"token","jwt":"stub"}'
    ;;
  http://127.0.0.1:8080/v2-beta/projects/1a5/hosts)
    printf '%s\n' '{"data":[{"id":"1h1","state":"active","agentState":"active"}]}'
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
  export RC16_LOCAL_AUTH_CURL_LOG="$curl_log"
  curl_connect_timeout=4
  curl_timeout=17
  base_url=http://127.0.0.1:8080
  project_id=1a5

  ping_body=$(auth_curl "$base_url/ping")
  auth_body=$(auth_curl \
    -H 'Content-Type: application/json' \
    --data-binary "@$json_payload" \
    "$base_url/v1/localauthconfigs")
  token_body=$(auth_curl \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-binary "@$token_payload" \
    "$base_url/v1/token")
  auth_curl \
    -H "Authorization: Bearer $(cat "$token_file")" \
    -H "X-API-Project-Id: $project_id" \
    "$base_url/v2-beta/projects/$project_id/hosts" >"$hosts_json"

  printf 'ping_body=%s\n' "$ping_body"
  printf 'auth_body=%s\n' "$auth_body"
  printf 'token_body=%s\n' "$token_body"
  printf 'hosts_body=%s\n' "$(cat "$hosts_json")"
) >"$output"

for expected in \
  'ping_body=pong' \
  'auth_body={"type":"localAuthConfig"}' \
  'token_body={"type":"token","jwt":"stub"}' \
  'hosts_body={"data":[{"id":"1h1","state":"active","agentState":"active"}]}'; do
  if ! grep -F -- "$expected" "$output" >/dev/null; then
    fail "LOCAL_AUTH_ROLLBACK_SAMPLE_OUTPUT_MISSING expected=$expected"
  fi
done

for expected in \
  $'CURL\t-fsS\t--connect-timeout\t4\t--max-time\t17\thttp://127.0.0.1:8080/ping' \
  $'CURL\t-fsS\t--connect-timeout\t4\t--max-time\t17\t-H\tContent-Type: application/json\t--data-binary\t@'"$json_payload"$'\thttp://127.0.0.1:8080/v1/localauthconfigs' \
  $'CURL\t-fsS\t--connect-timeout\t4\t--max-time\t17\t-H\tContent-Type: application/x-www-form-urlencoded\t--data-binary\t@'"$token_payload"$'\thttp://127.0.0.1:8080/v1/token' \
  $'CURL\t-fsS\t--connect-timeout\t4\t--max-time\t17\t-H\tAuthorization: Bearer jwt-token\t-H\tX-API-Project-Id: 1a5\thttp://127.0.0.1:8080/v2-beta/projects/1a5/hosts'; do
  if ! grep -F -- "$expected" "$curl_log" >/dev/null; then
    fail "LOCAL_AUTH_ROLLBACK_CURL_ARGS_MISSING expected=$expected"
  fi
done

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'LOCAL_AUTH_ROLLBACK_OK strict_shell=1 curl_bounded=1 ping_sample=1 api_samples=1\n'

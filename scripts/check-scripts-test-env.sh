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

if ! bash -n scripts/test; then
  fail "SCRIPTS_TEST_SYNTAX_INVALID"
fi

require_marker tests/server/fig-test-env.yml 'services:' SCRIPTS_TEST_COMPOSE_SPEC_SERVICES_MISSING
require_marker tests/server/fig-test-env.yml 'container_name: server_h2dbcattle_1' SCRIPTS_TEST_H2_CONTAINER_NAME_NOT_PINNED
require_marker tests/server/fig-test-env.yml 'container_name: server_mysqllinkcattle_1' SCRIPTS_TEST_LINK_CONTAINER_NAME_NOT_PINNED
require_marker tests/server/fig-test-env.yml 'container_name: server_localmysqlcattle_1' SCRIPTS_TEST_LOCAL_CONTAINER_NAME_NOT_PINNED
require_marker tests/server/fig-test-env.yml 'container_name: server_mysqlmanualcattle_1' SCRIPTS_TEST_MANUAL_CONTAINER_NAME_NOT_PINNED

require_marker scripts/test 'curl -fsS --connect-timeout "${RC16_TEST_CONNECT_TIMEOUT:-10}" --max-time "${RC16_TEST_MAX_TIME:-60}" "${url}/ping"' SCRIPTS_TEST_PING_CURL_NOT_BOUNDED
require_marker scripts/test 'export "$url=$(get_url "$PORT")"' SCRIPTS_TEST_EXPORT_NOT_QUOTED
require_marker scripts/test 'wait_for_env "${!url}"' SCRIPTS_TEST_INDIRECT_URL_MISSING

reject_marker scripts/test 'eval url=\$$url' SCRIPTS_TEST_LEGACY_EVAL
reject_marker scripts/test 'curl -s ${url}/ping' SCRIPTS_TEST_LEGACY_SILENT_CURL

sample_run=$(mktemp -d "${TMPDIR:-/tmp}/rc16-scripts-test-env.XXXXXX")
sample_functions=$(mktemp "${TMPDIR:-/tmp}/rc16-scripts-test-env-functions.XXXXXX")
trap 'rm -rf "$sample_run" "$sample_functions"' EXIT

extract_function() {
  local function_name=$1
  sed -n "/^${function_name}()/,/^}$/p" scripts/test
}

{
  extract_function wait_for_env
  extract_function get_port
  extract_function get_url
  extract_function setup
} >"$sample_functions"

mkdir -p "$sample_run/bin"
curl_log="$sample_run/curl.log"
docker_log="$sample_run/docker.log"
sample_output="$sample_run/output.log"
marker="$sample_run/eval-marker"

cat >"$sample_run/bin/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'CURL'
  for arg in "$@"; do
    printf '\t%s' "$arg"
  done
  printf '\n'
} >>"$RC16_SCRIPTS_TEST_CURL_LOG"

if [ "${*: -1}" = "http://198.51.100.10:18080/ping" ]; then
  printf '%s\n' 'pong'
  exit 0
fi

printf 'unexpected curl url: %s\n' "${*: -1}" >&2
exit 99
STUB
chmod +x "$sample_run/bin/curl"

cat >"$sample_run/bin/docker" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf 'DOCKER_ARGS=%s\n' "$*" >>"$RC16_SCRIPTS_TEST_DOCKER_LOG"
printf '%s\n' '18080'
STUB
chmod +x "$sample_run/bin/docker"

(
  # shellcheck source=/dev/null
  source "$sample_functions"

  fig_get_id() {
    printf '%s\n' 'container-id'
  }

  export PATH="$sample_run/bin:$PATH"
  export RC16_SCRIPTS_TEST_CURL_LOG="$curl_log"
  export RC16_SCRIPTS_TEST_DOCKER_LOG="$docker_log"
  export RC16_TEST_CONNECT_TIMEOUT=3
  export RC16_TEST_MAX_TIME=9
  export DOCKER_IP=198.51.100.10

  setup h2dbcattle CATTLE_H2DB_TEST_URL
  printf 'CATTLE_H2DB_TEST_URL=%s\n' "${CATTLE_H2DB_TEST_URL:-}"

  CATTLE_H2DB_TEST_URL="\$(touch $marker)"
  printf 'LITERAL_URL=%s\n' "${CATTLE_H2DB_TEST_URL:-}"
) >"$sample_output"

if ! grep -F 'CATTLE_H2DB_TEST_URL=http://198.51.100.10:18080' "$sample_output" >/dev/null; then
  fail "SCRIPTS_TEST_SETUP_DID_NOT_EXPORT_URL"
fi

if ! grep -F "LITERAL_URL=\$(touch $marker)" "$sample_output" >/dev/null; then
  fail "SCRIPTS_TEST_LITERAL_VALUE_NOT_PRESERVED"
fi

if [ -e "$marker" ]; then
  fail "SCRIPTS_TEST_COMMAND_SUBSTITUTION_EXECUTED"
fi

if ! grep -F $'CURL\t-fsS\t--connect-timeout\t3\t--max-time\t9\thttp://198.51.100.10:18080/ping' "$curl_log" >/dev/null; then
  fail "SCRIPTS_TEST_CURL_FLAGS_NOT_USED"
fi

if ! grep -F 'DOCKER_ARGS=inspect -f {{ (index (index .NetworkSettings.Ports "8080/tcp") 0).HostPort }} container-id' "$docker_log" >/dev/null; then
  fail "SCRIPTS_TEST_DOCKER_INSPECT_ARGS_CHANGED"
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'SCRIPTS_TEST_ENV_OK eval_free=1 bounded_ping=1 setup_smoke=1\n'

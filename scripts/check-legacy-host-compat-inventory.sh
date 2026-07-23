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

if ! bash -n scripts/legacy-host-compat-inventory.sh; then
  fail "HOST_COMPAT_INVENTORY_SYNTAX_INVALID"
fi

require_marker scripts/legacy-host-compat-inventory.sh 'set -euo pipefail' HOST_COMPAT_INVENTORY_STRICT_SHELL_MISSING
require_marker scripts/legacy-host-compat-inventory.sh 'fetch_hosts()' HOST_COMPAT_INVENTORY_FETCH_HELPER_MISSING
require_marker scripts/legacy-host-compat-inventory.sh 'curl -fsS --retry 5 --retry-all-errors --retry-delay 2 \' HOST_COMPAT_INVENTORY_CURL_NOT_RETRIED
require_marker scripts/legacy-host-compat-inventory.sh '--connect-timeout "$connect_timeout"' HOST_COMPAT_INVENTORY_CONNECT_TIMEOUT_MISSING
require_marker scripts/legacy-host-compat-inventory.sh '--max-time "$max_time"' HOST_COMPAT_INVENTORY_MAX_TIME_MISSING
require_marker scripts/legacy-host-compat-inventory.sh '-u "${RANCHER_ACCESS_KEY}:${RANCHER_SECRET_KEY}"' HOST_COMPAT_INVENTORY_AUTH_NOT_QUOTED
require_marker scripts/legacy-host-compat-inventory.sh 'fetch_hosts |' HOST_COMPAT_INVENTORY_PIPE_NOT_HELPER_BACKED

reject_marker scripts/legacy-host-compat-inventory.sh 'curl -fsS -u "${RANCHER_ACCESS_KEY}:${RANCHER_SECRET_KEY}" "${API}/hosts?limit=-1" |' HOST_COMPAT_INVENTORY_LEGACY_CURL

sample_run=$(mktemp -d "${TMPDIR:-/tmp}/rc16-host-compat-inventory.XXXXXX")
trap 'rm -rf "$sample_run"' EXIT

mkdir -p "$sample_run/bin"
curl_log="$sample_run/curl.log"
jq_log="$sample_run/jq.log"
jq_stdin="$sample_run/jq-stdin.json"
output="$sample_run/output.tsv"

cat >"$sample_run/bin/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'CURL'
  for arg in "$@"; do
    printf '\t%s' "$arg"
  done
  printf '\n'
} >>"$RC16_HOST_COMPAT_CURL_LOG"

url="${*: -1}"
if [ "$url" != "http://rancher.example.invalid:8080/v2-beta/projects/1a5/hosts?limit=-1" ]; then
  printf 'unexpected curl url: %s\n' "$url" >&2
  exit 99
fi

printf '%s\n' '{"data":[{"id":"1h1","hostname":"host-a","state":"active","labels":{"docker_version":"20.10.24","os":"Ubuntu","kernel_version":"6.8.0"},"agentIpAddress":"10.42.0.1"}]}'
STUB
chmod +x "$sample_run/bin/curl"

cat >"$sample_run/bin/jq" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
{
  printf 'JQ'
  for arg in "$@"; do
    printf '\t%s' "$arg"
  done
  printf '\n'
} >>"$RC16_HOST_COMPAT_JQ_LOG"

if [ "${1:-}" != "-r" ]; then
  printf 'unexpected jq args: %s\n' "$*" >&2
  exit 98
fi

cat >"$RC16_HOST_COMPAT_JQ_STDIN"
if ! grep -F '"id":"1h1"' "$RC16_HOST_COMPAT_JQ_STDIN" >/dev/null; then
  printf 'expected host fixture was not piped to jq\n' >&2
  exit 97
fi

printf 'id\tname\tstate\tdocker\tos\tkernel\tagent_ip\tcompat\n'
printf '1h1\thost-a\tactive\t20.10.24\tUbuntu\t6.8.0\t10.42.0.1\tmodern-candidate\n'
STUB
chmod +x "$sample_run/bin/jq"

(
  export PATH="$sample_run/bin:$PATH"
  export RANCHER_URL=http://rancher.example.invalid:8080
  export RANCHER_ACCESS_KEY=access-key
  export RANCHER_SECRET_KEY=secret-key
  export RANCHER_PROJECT_ID=1a5
  export RC16_HOST_COMPAT_CONNECT_TIMEOUT=4
  export RC16_HOST_COMPAT_MAX_TIME=40
  export RC16_HOST_COMPAT_CURL_LOG="$curl_log"
  export RC16_HOST_COMPAT_JQ_LOG="$jq_log"
  export RC16_HOST_COMPAT_JQ_STDIN="$jq_stdin"
  bash scripts/legacy-host-compat-inventory.sh
) >"$output"

if ! grep -F $'id\tname\tstate\tdocker\tos\tkernel\tagent_ip\tcompat' "$output" >/dev/null; then
  fail "HOST_COMPAT_INVENTORY_HEADER_MISSING"
fi

if ! grep -F $'1h1\thost-a\tactive\t20.10.24\tUbuntu\t6.8.0\t10.42.0.1\tmodern-candidate' "$output" >/dev/null; then
  fail "HOST_COMPAT_INVENTORY_SAMPLE_ROW_MISSING"
fi

if ! grep -F $'CURL\t-fsS\t--retry\t5\t--retry-all-errors\t--retry-delay\t2\t--connect-timeout\t4\t--max-time\t40\t-u\taccess-key:secret-key\thttp://rancher.example.invalid:8080/v2-beta/projects/1a5/hosts?limit=-1' "$curl_log" >/dev/null; then
  fail "HOST_COMPAT_INVENTORY_CURL_FLAGS_NOT_USED"
fi

if ! grep -F $'JQ\t-r' "$jq_log" >/dev/null; then
  fail "HOST_COMPAT_INVENTORY_JQ_NOT_INVOKED"
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'HOST_COMPAT_INVENTORY_OK strict_shell=1 curl_fail_closed=1 retry=5 timeouts=1 sample=1\n'

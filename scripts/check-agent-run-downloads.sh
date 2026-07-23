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

if ! bash -n agent/run.sh; then
  fail "AGENT_RUN_SYNTAX_INVALID"
fi

require_marker agent/run.sh 'agent_curl()' AGENT_RUN_CURL_HELPER_MISSING
require_marker agent/run.sh 'local retry_all_errors=()' AGENT_RUN_RETRY_ALL_ERRORS_ARRAY_MISSING
require_marker agent/run.sh 'if curl --retry-all-errors --version >/dev/null 2>&1; then' AGENT_RUN_RETRY_ALL_ERRORS_DETECT_MISSING
require_marker agent/run.sh 'retry_all_errors=(--retry-all-errors)' AGENT_RUN_RETRY_ALL_ERRORS_ENABLE_MISSING
require_marker agent/run.sh 'curl --retry 5 "${retry_all_errors[@]}" --retry-delay 2 \' AGENT_RUN_CURL_RETRY_MISSING
require_marker agent/run.sh '--connect-timeout "${RC16_AGENT_CURL_CONNECT_TIMEOUT:-10}"' AGENT_RUN_CONNECT_TIMEOUT_MISSING
require_marker agent/run.sh '--max-time "${RC16_AGENT_CURL_MAX_TIME:-300}"' AGENT_RUN_MAX_TIME_MISSING
require_marker agent/run.sh "sed -E -e 's!/(v1|v2-beta)(/.*)?/scripts.*!/\\1!'" AGENT_RUN_PRINT_URL_SCRIPT_REDACTION_MISSING
require_marker agent/run.sh "sed -E 's/((SECRET|ACCESS_KEY|TOKEN|PASSWORD)[^=]*=).*/\\1xxxxxxx/g'" AGENT_RUN_ENV_LOG_REDACTION_MISSING
require_marker agent/run.sh 'agent_curl --insecure -fsSL -o /tmp/ca.crt "$cert"' AGENT_RUN_CA_DOWNLOAD_NOT_FILE_BACKED
require_marker agent/run.sh 'content=$(agent_curl -fsSL "$url")' AGENT_RUN_ENV_LOAD_NOT_FAIL_CLOSED
require_marker agent/run.sh 'agent_curl -fsSL -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" -o "$SCRIPT" "${CATTLE_URL}/scripts/bootstrap"' AGENT_RUN_BOOTSTRAP_NOT_FILE_BACKED
require_marker agent/run.sh 'agent_curl -fsS -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" -o test.json "${CATTLE_URL}/schemas/configcontent"' AGENT_RUN_SCHEMA_AUTH_NOT_QUOTED
require_marker agent/run.sh 'agent_curl -fsS -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" -o /dev/null "${CATTLE_URL}/schemas/account"' AGENT_RUN_ACCOUNT_AUTH_NOT_QUOTED
require_marker agent/run.sh 'bash "$SCRIPT" "$@"' AGENT_RUN_BOOTSTRAP_SCRIPT_NOT_QUOTED
require_marker agent/run.sh 'err_file=$(mktemp "${TMPDIR:-/tmp}/rc16-agent-check-url.XXXXXX")' AGENT_RUN_CHECK_URL_TMP_FILE_MISSING
require_marker agent/run.sh 'agent_curl -f -L -sS --connect-timeout 15 -o /dev/null --stderr "$err_file" "$1"' AGENT_RUN_CHECK_URL_STDERR_NOT_FILE_BACKED

reject_marker agent/run.sh 'curl -sLf $1 >/dev/null 2>&1' AGENT_RUN_LEGACY_SELF_SIGNED_CHECK
reject_marker agent/run.sh 'agent_curl -f -L -sS --connect-timeout 15 -o /dev/null --stderr - "$1" | head -n1 ; exit ${PIPESTATUS[0]}' AGENT_RUN_LEGACY_CHECK_URL_PIPESTATUS
reject_marker agent/run.sh 'curl --insecure -sLf "$CERT" > /tmp/ca.crt' AGENT_RUN_LEGACY_CA_DOWNLOAD
reject_marker agent/run.sh 'local content=$(curl -sL $1)' AGENT_RUN_LEGACY_ENV_LOAD
reject_marker agent/run.sh 'curl -u ${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY} -s ${CATTLE_URL}/schemas/configcontent >test.json 2>&1' AGENT_RUN_LEGACY_SCHEMA_CURL
reject_marker agent/run.sh 'curl -u ${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY} -s ${CATTLE_URL}/scripts/bootstrap > $SCRIPT' AGENT_RUN_LEGACY_BOOTSTRAP_CURL
reject_marker agent/run.sh 'curl -f -u ${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY} -s ${CATTLE_URL}/schemas/account' AGENT_RUN_LEGACY_ACCOUNT_CURL
reject_marker agent/run.sh "sed -e 's!/v1.*/scripts.*!/v1!'" AGENT_RUN_LEGACY_PRINT_URL_V1_ONLY
reject_marker agent/run.sh "sed 's/\\(SECRET.*=\\).*/\\1xxxxxxx/g'" AGENT_RUN_LEGACY_ENV_LOG_SECRET_ONLY

sample_run=$(mktemp -d "${TMPDIR:-/tmp}/rc16-agent-run-downloads.XXXXXX")
sample_functions=$(mktemp "${TMPDIR:-/tmp}/rc16-agent-run-functions.XXXXXX")
trap 'rm -rf "$sample_run" "$sample_functions" /tmp/bootstrap.sh /tmp/ca.crt /tmp/ca.crt.clean' EXIT

extract_function() {
  local function_name=$1
  sed -n "/^${function_name}()/,/^}$/p" agent/run.sh
}

{
  extract_function info
  extract_function error
  extract_function agent_curl
  extract_function trim_agent_env_line
  extract_function apply_agent_env_line
  extract_function apply_agent_env_output
  extract_function print_url
  extract_function setup_self_signed
  extract_function load
  extract_function run_bootstrap
  extract_function check_url
} >"$sample_functions"

mkdir -p "$sample_run/bin"

cat >"$sample_run/bin/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

if [ "${RC16_AGENT_SAMPLE_LEGACY_CURL:-false}" = "true" ]; then
  for arg in "$@"; do
    if [ "$arg" = "--retry-all-errors" ]; then
      printf 'curl: option --retry-all-errors: is unknown\n' >&2
      exit 2
    fi
  done
fi

for arg in "$@"; do
  if [ "$arg" = "--version" ]; then
    printf 'curl sample\n'
    exit 0
  fi
done

{
  printf 'CALL'
  for arg in "$@"; do
    printf '\t%s' "$arg"
  done
  printf '\n'
} >>"$RC16_AGENT_CURL_LOG"

out=
stderr_file=
url=
previous=
for arg in "$@"; do
  if [ "${previous:-}" = "-o" ]; then
    out=$arg
    previous=
    continue
  fi

  if [ "${previous:-}" = "--stderr" ]; then
    stderr_file=$arg
    previous=
    continue
  fi

  if [ "$arg" = "-o" ]; then
    previous="-o"
    continue
  fi

  if [ "$arg" = "--stderr" ]; then
    previous="--stderr"
    continue
  fi

  case "$arg" in
    http://*|https://*)
      url=$arg
      ;;
  esac
done

case "$url" in
  https://selfsigned.example/v1)
    exit 60
    ;;
  https://selfsigned.example/v1/scripts/ca.crt)
    [ -n "$out" ] || exit 90
    printf '%s\n' 'CERT' >"$out"
    ;;
  http://rancher.example/env-script)
    printf '%s\n' '#!/bin/sh'
    printf '%s\n' 'export CATTLE_URL_OVERRIDE=http://override.example/v1'
    ;;
  http://rancher.example/v1/schemas/configcontent)
    exit 22
    ;;
  http://rancher.example/v1/scripts/bootstrap)
    [ -n "$out" ] || exit 91
    cat >"$out" <<'BOOTSTRAP'
#!/usr/bin/env bash
printf 'BOOTSTRAP_ARGS=%s\n' "$*" >"$RC16_AGENT_BOOTSTRAP_LOG"
BOOTSTRAP
    chmod 700 "$out"
    ;;
  http://rancher.example/v1/schemas/account)
    exit 22
    ;;
  http://wait.example/v1)
    exit 0
    ;;
  http://bad.example/v1)
    if [ -n "$stderr_file" ] && [ "$stderr_file" != "-" ]; then
      printf '%s\n' 'curl: (7) Failed to connect bad.example' >"$stderr_file"
    else
      printf '%s\n' 'curl: (7) Failed to connect bad.example' >&2
    fi
    exit 7
    ;;
  *)
    printf 'UNEXPECTED_CURL_URL=%s\n' "$url" >&2
    exit 99
    ;;
esac
STUB
chmod +x "$sample_run/bin/curl"

cat >"$sample_run/bin/openssl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail

{
  printf 'OPENSSL'
  for arg in "$@"; do
    printf '\t%s' "$arg"
  done
  printf '\n'
} >>"$RC16_AGENT_OPENSSL_LOG"

for arg in "$@"; do
  if [ "$arg" = "-fingerprint" ]; then
    printf '%s\n' 'SHA256 Fingerprint=AA:BB'
    exit 0
  fi
done

printf '%s\n' 'CLEAN_CERT'
STUB
chmod +x "$sample_run/bin/openssl"

sample_output="$sample_run/output.log"
curl_log="$sample_run/curl.log"
legacy_output="$sample_run/output-legacy.log"
legacy_curl_log="$sample_run/curl-legacy.log"
openssl_log="$sample_run/openssl.log"
legacy_openssl_log="$sample_run/openssl-legacy.log"
bootstrap_log="$sample_run/bootstrap.log"
legacy_bootstrap_log="$sample_run/bootstrap-legacy.log"
ca_bundle_log="$sample_run/ca-bundle.log"
legacy_ca_bundle_log="$sample_run/ca-bundle-legacy.log"

(
  # shellcheck source=/dev/null
  source "$sample_functions"

  setup_custom_ca_bundle() {
    printf '%s\n' 'CUSTOM_CA_BUNDLE_CALLED=1' >"$RC16_AGENT_CA_BUNDLE_LOG"
  }

  export PATH="$sample_run/bin:$PATH"
  export RC16_AGENT_CURL_LOG="$curl_log"
  export RC16_AGENT_OPENSSL_LOG="$openssl_log"
  export RC16_AGENT_BOOTSTRAP_LOG="$bootstrap_log"
  export RC16_AGENT_CA_BUNDLE_LOG="$ca_bundle_log"
  export RC16_AGENT_CURL_CONNECT_TIMEOUT=3
  export RC16_AGENT_CURL_MAX_TIME=30
  export CA_CERT_FILE="$sample_run/ca/ca.crt"
  export CA_FINGERPRINT='AA:BB'

  setup_self_signed "https://selfsigned.example/v1"

  CATTLE_URL='http://original.example/v1'
  load "http://rancher.example/env-script"
  printf 'LOAD_CATTLE_URL=%s\n' "$CATTLE_URL"
  printf 'PRINT_URL_V1=%s\n' "$(print_url 'http://rancher.example/v1/projects/1a5/scripts/SECRET_V1')"
  printf 'PRINT_URL_V2=%s\n' "$(print_url 'http://rancher.example/v2-beta/projects/1a5/scripts/SECRET_V2')"

  export CATTLE_URL='http://rancher.example/v1'
  export CATTLE_ACCESS_KEY='access'
  export CATTLE_SECRET_KEY='secret'
  export CATTLE_EXEC_AGENT='false'
  unset CATTLE_CONFIG_URL CATTLE_STORAGE_URL
  run_bootstrap configscripts pyagent
  printf 'CHECK_URL_OK=%s\n' "$(check_url 'http://wait.example/v1')"
  printf 'CHECK_URL_BAD=%s\n' "$(check_url 'http://bad.example/v1')"
) >"$sample_output"

if ! grep -F 'CLEAN_CERT' "$sample_run/ca/ca.crt" >/dev/null; then
  fail "AGENT_RUN_CA_CERT_NOT_INSTALLED"
fi

if ! grep -F 'CUSTOM_CA_BUNDLE_CALLED=1' "$ca_bundle_log" >/dev/null; then
  fail "AGENT_RUN_CA_BUNDLE_NOT_CONFIGURED"
fi

if ! grep -F 'LOAD_CATTLE_URL=http://override.example/v1' "$sample_output" >/dev/null; then
  fail "AGENT_RUN_ENV_LOAD_SAMPLE_FAILED"
fi

if ! grep -F 'PRINT_URL_V1=http://rancher.example/v1' "$sample_output" >/dev/null; then
  fail "AGENT_RUN_PRINT_URL_V1_SAMPLE_FAILED"
fi

if ! grep -F 'PRINT_URL_V2=http://rancher.example/v2-beta' "$sample_output" >/dev/null; then
  fail "AGENT_RUN_PRINT_URL_V2_SAMPLE_FAILED"
fi

if grep -F 'SECRET_V1' "$sample_output" >/dev/null || grep -F 'SECRET_V2' "$sample_output" >/dev/null; then
  fail "AGENT_RUN_PRINT_URL_REGISTRATION_TOKEN_LEAK"
fi

if ! grep -F 'BOOTSTRAP_ARGS=configscripts pyagent' "$bootstrap_log" >/dev/null; then
  fail "AGENT_RUN_BOOTSTRAP_ARGS_CHANGED"
fi

if ! grep -Fx 'CHECK_URL_OK=' "$sample_output" >/dev/null; then
  fail "AGENT_RUN_CHECK_URL_SUCCESS_NOT_EMPTY"
fi

if ! grep -F 'CHECK_URL_BAD=Failed to connect bad.example' "$sample_output" >/dev/null; then
  fail "AGENT_RUN_CHECK_URL_ERROR_SAMPLE_FAILED"
fi

require_log_marker() {
  local marker=$1
  local code=$2

  if ! grep -F -- "$marker" "$curl_log" >/dev/null; then
    fail "$code"
  fi
}

require_log_marker $'\t--retry\t5' AGENT_RUN_SMOKE_RETRY_MISSING
require_log_marker $'\t--retry-all-errors' AGENT_RUN_SMOKE_RETRY_ALL_ERRORS_MISSING
require_log_marker $'\t--retry-delay\t2' AGENT_RUN_SMOKE_RETRY_DELAY_MISSING
require_log_marker $'\t--connect-timeout\t3' AGENT_RUN_SMOKE_CONNECT_TIMEOUT_MISSING
require_log_marker $'\t--max-time\t30' AGENT_RUN_SMOKE_MAX_TIME_MISSING
require_log_marker $'\t--insecure\t-fsSL\t-o\t/tmp/ca.crt\thttps://selfsigned.example/v1/scripts/ca.crt' AGENT_RUN_SMOKE_CA_DOWNLOAD_MISMATCH
require_log_marker $'\t-fsSL\thttp://rancher.example/env-script' AGENT_RUN_SMOKE_ENV_LOAD_MISMATCH
require_log_marker $'\t-u\taccess:secret\t-o\ttest.json\thttp://rancher.example/v1/schemas/configcontent' AGENT_RUN_SMOKE_SCHEMA_AUTH_MISMATCH
require_log_marker $'\t-u\taccess:secret\t-o\t/tmp/bootstrap.sh\thttp://rancher.example/v1/scripts/bootstrap' AGENT_RUN_SMOKE_BOOTSTRAP_DOWNLOAD_MISMATCH
require_log_marker $'\t-u\taccess:secret\t-o\t/dev/null\thttp://rancher.example/v1/schemas/account' AGENT_RUN_SMOKE_ACCOUNT_AUTH_MISMATCH
require_log_marker $'\t--stderr\t' AGENT_RUN_SMOKE_CHECK_URL_STDERR_FILE_MISSING

(
  # shellcheck source=/dev/null
  source "$sample_functions"

  setup_custom_ca_bundle() {
    printf '%s\n' 'CUSTOM_CA_BUNDLE_CALLED=1' >"$RC16_AGENT_CA_BUNDLE_LOG"
  }

  export PATH="$sample_run/bin:$PATH"
  export RC16_AGENT_SAMPLE_LEGACY_CURL=true
  export RC16_AGENT_CURL_LOG="$legacy_curl_log"
  export RC16_AGENT_OPENSSL_LOG="$legacy_openssl_log"
  export RC16_AGENT_BOOTSTRAP_LOG="$legacy_bootstrap_log"
  export RC16_AGENT_CA_BUNDLE_LOG="$legacy_ca_bundle_log"
  export RC16_AGENT_CURL_CONNECT_TIMEOUT=4
  export RC16_AGENT_CURL_MAX_TIME=40
  export CA_CERT_FILE="$sample_run/ca-legacy/ca.crt"
  export CA_FINGERPRINT='AA:BB'

  setup_self_signed "https://selfsigned.example/v1"

  CATTLE_URL='http://original.example/v1'
  load "http://rancher.example/env-script"
  printf 'LOAD_CATTLE_URL=%s\n' "$CATTLE_URL"
  printf 'PRINT_URL_V1=%s\n' "$(print_url 'http://rancher.example/v1/projects/1a5/scripts/SECRET_V1')"
  printf 'PRINT_URL_V2=%s\n' "$(print_url 'http://rancher.example/v2-beta/projects/1a5/scripts/SECRET_V2')"

  export CATTLE_URL='http://rancher.example/v1'
  export CATTLE_ACCESS_KEY='access'
  export CATTLE_SECRET_KEY='secret'
  export CATTLE_EXEC_AGENT='false'
  unset CATTLE_CONFIG_URL CATTLE_STORAGE_URL
  run_bootstrap configscripts pyagent
  printf 'CHECK_URL_OK=%s\n' "$(check_url 'http://wait.example/v1')"
  printf 'CHECK_URL_BAD=%s\n' "$(check_url 'http://bad.example/v1')"
) >"$legacy_output"

if ! grep -F 'CLEAN_CERT' "$sample_run/ca-legacy/ca.crt" >/dev/null; then
  fail "AGENT_RUN_LEGACY_CA_CERT_NOT_INSTALLED"
fi

if ! grep -F 'CUSTOM_CA_BUNDLE_CALLED=1' "$legacy_ca_bundle_log" >/dev/null; then
  fail "AGENT_RUN_LEGACY_CA_BUNDLE_NOT_CONFIGURED"
fi

if ! grep -F 'LOAD_CATTLE_URL=http://override.example/v1' "$legacy_output" >/dev/null; then
  fail "AGENT_RUN_LEGACY_ENV_LOAD_SAMPLE_FAILED"
fi

if ! grep -F 'PRINT_URL_V1=http://rancher.example/v1' "$legacy_output" >/dev/null; then
  fail "AGENT_RUN_LEGACY_PRINT_URL_V1_SAMPLE_FAILED"
fi

if ! grep -F 'PRINT_URL_V2=http://rancher.example/v2-beta' "$legacy_output" >/dev/null; then
  fail "AGENT_RUN_LEGACY_PRINT_URL_V2_SAMPLE_FAILED"
fi

if grep -F 'SECRET_V1' "$legacy_output" >/dev/null || grep -F 'SECRET_V2' "$legacy_output" >/dev/null; then
  fail "AGENT_RUN_LEGACY_PRINT_URL_REGISTRATION_TOKEN_LEAK"
fi

if ! grep -F 'BOOTSTRAP_ARGS=configscripts pyagent' "$legacy_bootstrap_log" >/dev/null; then
  fail "AGENT_RUN_LEGACY_BOOTSTRAP_ARGS_CHANGED"
fi

if ! grep -Fx 'CHECK_URL_OK=' "$legacy_output" >/dev/null; then
  fail "AGENT_RUN_LEGACY_CHECK_URL_SUCCESS_NOT_EMPTY"
fi

if ! grep -F 'CHECK_URL_BAD=Failed to connect bad.example' "$legacy_output" >/dev/null; then
  fail "AGENT_RUN_LEGACY_CHECK_URL_ERROR_SAMPLE_FAILED"
fi

if ! grep -F -- $'\t--retry\t5' "$legacy_curl_log" >/dev/null || \
   grep -F -- $'\t--retry-all-errors\t--retry-delay\t2' "$legacy_curl_log" >/dev/null || \
   ! grep -F -- $'\t--retry-delay\t2' "$legacy_curl_log" >/dev/null; then
  fail "AGENT_RUN_LEGACY_RETRY_FLAGS_INVALID"
fi

if ! grep -F -- $'\t--connect-timeout\t4' "$legacy_curl_log" >/dev/null || \
   ! grep -F -- $'\t--max-time\t40' "$legacy_curl_log" >/dev/null; then
  fail "AGENT_RUN_LEGACY_TIMEOUT_FLAGS_MISSING"
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'AGENT_RUN_DOWNLOADS_OK curl_fail_closed=1 retry=5 timeouts=1 ca_sample=1 env_load_sample=1 bootstrap_sample=1 print_url_redaction=1\n'

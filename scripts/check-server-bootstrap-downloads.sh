#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

failure_count=0

require_marker() {
  local file=$1
  local marker=$2
  local code=$3
  if ! grep -F -- "$marker" "$file" >/dev/null; then
    printf '%s file=%s marker=%s\n' "$code" "$file" "$marker" >&2
    failure_count=$((failure_count + 1))
  fi
}

reject_marker() {
  local file=$1
  local marker=$2
  local code=$3
  if grep -F -- "$marker" "$file" >/dev/null; then
    printf '%s file=%s marker=%s\n' "$code" "$file" "$marker" >&2
    failure_count=$((failure_count + 1))
  fi
}

if ! bash -n server/patches/bootstrap.sh; then
  printf 'SERVER_BOOTSTRAP_SYNTAX_INVALID file=server/patches/bootstrap.sh\n' >&2
  failure_count=$((failure_count + 1))
fi

require_marker server/patches/bootstrap.sh 'local content="$TEMP_DOWNLOAD/content"' SERVER_BOOTSTRAP_DOWNLOAD_CONTENT_PATH_MISSING
require_marker server/patches/bootstrap.sh 'rm "$0" 2>/dev/null || true' SERVER_BOOTSTRAP_CLEANUP_DEV_NULL_MISSING
require_marker server/patches/bootstrap.sh 'local url="${CATTLE_CONFIG_URL}${CONTENT_URL}"' SERVER_BOOTSTRAP_DOWNLOAD_URL_VAR_MISSING
require_marker server/patches/bootstrap.sh 'local retry_all_errors=()' SERVER_BOOTSTRAP_DOWNLOAD_RETRY_ALL_ERRORS_ARRAY_MISSING
require_marker server/patches/bootstrap.sh 'if curl --retry-all-errors --version >/dev/null 2>&1; then' SERVER_BOOTSTRAP_DOWNLOAD_RETRY_ALL_ERRORS_DETECT_MISSING
require_marker server/patches/bootstrap.sh 'retry_all_errors=(--retry-all-errors)' SERVER_BOOTSTRAP_DOWNLOAD_RETRY_ALL_ERRORS_ENABLE_MISSING
require_marker server/patches/bootstrap.sh 'curl -fsS --retry 5 "${retry_all_errors[@]}" --retry-delay 2 \' SERVER_BOOTSTRAP_DOWNLOAD_CURL_NOT_FAIL_CLOSED
require_marker server/patches/bootstrap.sh '--connect-timeout "${RC16_BOOTSTRAP_CONNECT_TIMEOUT:-10}"' SERVER_BOOTSTRAP_DOWNLOAD_CONNECT_TIMEOUT_MISSING
require_marker server/patches/bootstrap.sh '--max-time "${RC16_BOOTSTRAP_MAX_TIME:-300}"' SERVER_BOOTSTRAP_DOWNLOAD_MAX_TIME_MISSING
require_marker server/patches/bootstrap.sh '-u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}"' SERVER_BOOTSTRAP_DOWNLOAD_AUTH_UNQUOTED
require_marker server/patches/bootstrap.sh '-o "$content" "$url"' SERVER_BOOTSTRAP_DOWNLOAD_NOT_FILE_BACKED
require_marker server/patches/bootstrap.sh 'tar xzf "$content" -C "$TEMP_DOWNLOAD"' SERVER_BOOTSTRAP_DOWNLOAD_TAR_NOT_QUOTED
reject_marker server/patches/bootstrap.sh 'curl --retry 5 -s -u $CATTLE_ACCESS_KEY:$CATTLE_SECRET_KEY ${CATTLE_CONFIG_URL}${CONTENT_URL} > $TEMP_DOWNLOAD/content' SERVER_BOOTSTRAP_DOWNLOAD_LEGACY_CURL
reject_marker server/patches/bootstrap.sh '2>/null' SERVER_BOOTSTRAP_CLEANUP_LEGACY_NULL_REDIRECT

sample_run=$(mktemp -d "${TMPDIR:-/tmp}/rc16-bootstrap-download.XXXXXX")
sample_functions=$(mktemp "${TMPDIR:-/tmp}/rc16-bootstrap-download-functions.XXXXXX")
sample_bin="$sample_run/bin"
sample_curl_log="$sample_run/curl.log"
sample_config_log="$sample_run/config.log"
sample_legacy_curl_log="$sample_run/curl-legacy.log"
sample_legacy_config_log="$sample_run/config-legacy.log"
cleanup() {
  rm -rf "$sample_run"
  rm -f "$sample_functions"
}
trap cleanup EXIT
mkdir -p "$sample_bin"

cat >"$sample_bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ "${RC16_BOOTSTRAP_SAMPLE_LEGACY_CURL:-false}" = "true" ]; then
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

out=
auth=
url=
connect_timeout=
max_time=
retry=
retry_all_errors=0
retry_delay=

while [ "$#" -gt 0 ]; do
  case "$1" in
    -o)
      out="$2"
      shift 2
      ;;
    -u)
      auth="$2"
      shift 2
      ;;
    --connect-timeout)
      connect_timeout="$2"
      shift 2
      ;;
    --max-time)
      max_time="$2"
      shift 2
      ;;
    --retry)
      retry="$2"
      shift 2
      ;;
    --retry-all-errors)
      retry_all_errors=1
      shift
      ;;
    --retry-delay)
      retry_delay="$2"
      shift 2
      ;;
    -*)
      shift
      ;;
    *)
      url="$1"
      shift
      ;;
  esac
done

{
  printf 'AUTH=%s\n' "$auth"
  printf 'URL=%s\n' "$url"
  printf 'OUT=%s\n' "$out"
  printf 'CONNECT_TIMEOUT=%s\n' "$connect_timeout"
  printf 'MAX_TIME=%s\n' "$max_time"
  printf 'RETRY=%s\n' "$retry"
  printf 'RETRY_ALL_ERRORS=%s\n' "$retry_all_errors"
  printf 'RETRY_DELAY=%s\n' "$retry_delay"
} >"$RC16_BOOTSTRAP_DOWNLOAD_CURL_LOG"

printf 'stub content\n' >"$out"
EOF
chmod +x "$sample_bin/curl"

cat >"$sample_bin/tar" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

dest=
while [ "$#" -gt 0 ]; do
  case "$1" in
    -C)
      dest="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

mkdir -p "$dest/config"
cat >"$dest/config/config.sh" <<'CONFIG'
#!/usr/bin/env bash
printf 'CONFIG_ARGS=%s\n' "$*" >"$RC16_BOOTSTRAP_DOWNLOAD_CONFIG_LOG"
CONFIG
chmod +x "$dest/config/config.sh"
EOF
chmod +x "$sample_bin/tar"

awk '
  /^info\(\)/,/^}/ { print }
  /^cleanup\(\)/,/^}/ { print }
  /^download_agent\(\)/,/^}/ { print }
' server/patches/bootstrap.sh >"$sample_functions"

cat >>"$sample_functions" <<'EOF'
CONTENT_URL=/configcontent/configscripts
INSTALL_ITEMS="configscripts pyagent"
CATTLE_ACCESS_KEY=access
CATTLE_SECRET_KEY=secret
CATTLE_CONFIG_URL=http://127.0.0.1:8080
download_agent
EOF

(
  cd "$sample_run"
  PATH="$sample_bin:$PATH" \
    RC16_BOOTSTRAP_CONNECT_TIMEOUT=4 \
    RC16_BOOTSTRAP_MAX_TIME=40 \
    RC16_BOOTSTRAP_DOWNLOAD_CURL_LOG="$sample_curl_log" \
    RC16_BOOTSTRAP_DOWNLOAD_CONFIG_LOG="$sample_config_log" \
    bash "$sample_functions" >/dev/null
)

if ! grep -F 'AUTH=access:secret' "$sample_curl_log" >/dev/null; then
  printf 'SERVER_BOOTSTRAP_DOWNLOAD_SAMPLE_AUTH_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'URL=http://127.0.0.1:8080/configcontent/configscripts' "$sample_curl_log" >/dev/null; then
  printf 'SERVER_BOOTSTRAP_DOWNLOAD_SAMPLE_URL_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'CONNECT_TIMEOUT=4' "$sample_curl_log" >/dev/null; then
  printf 'SERVER_BOOTSTRAP_DOWNLOAD_SAMPLE_CONNECT_TIMEOUT_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'MAX_TIME=40' "$sample_curl_log" >/dev/null; then
  printf 'SERVER_BOOTSTRAP_DOWNLOAD_SAMPLE_MAX_TIME_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'RETRY=5' "$sample_curl_log" >/dev/null || ! grep -F 'RETRY_ALL_ERRORS=1' "$sample_curl_log" >/dev/null || ! grep -F 'RETRY_DELAY=2' "$sample_curl_log" >/dev/null; then
  printf 'SERVER_BOOTSTRAP_DOWNLOAD_SAMPLE_RETRY_FLAGS_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'CONFIG_ARGS=--force configscripts pyagent' "$sample_config_log" >/dev/null; then
  printf 'SERVER_BOOTSTRAP_DOWNLOAD_SAMPLE_CONFIG_ARGS_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

awk '
  /^info\(\)/,/^}/ { print }
  /^cleanup\(\)/,/^}/ { print }
  /^download_agent\(\)/,/^}/ { print }
' server/patches/bootstrap.sh >"$sample_functions"

cat >>"$sample_functions" <<'EOF'
CONTENT_URL=/configcontent/configscripts
INSTALL_ITEMS="configscripts pyagent"
CATTLE_ACCESS_KEY=access
CATTLE_SECRET_KEY=secret
CATTLE_CONFIG_URL=http://127.0.0.1:8080
download_agent
EOF

(
  cd "$sample_run"
  PATH="$sample_bin:$PATH" \
    RC16_BOOTSTRAP_SAMPLE_LEGACY_CURL=true \
    RC16_BOOTSTRAP_CONNECT_TIMEOUT=4 \
    RC16_BOOTSTRAP_MAX_TIME=40 \
    RC16_BOOTSTRAP_DOWNLOAD_CURL_LOG="$sample_legacy_curl_log" \
    RC16_BOOTSTRAP_DOWNLOAD_CONFIG_LOG="$sample_legacy_config_log" \
    bash "$sample_functions" >/dev/null
)

if ! grep -F 'RETRY=5' "$sample_legacy_curl_log" >/dev/null || grep -F 'RETRY_ALL_ERRORS=1' "$sample_legacy_curl_log" >/dev/null || ! grep -F 'RETRY_DELAY=2' "$sample_legacy_curl_log" >/dev/null; then
  printf 'SERVER_BOOTSTRAP_DOWNLOAD_SAMPLE_LEGACY_RETRY_FLAGS_INVALID\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'CONNECT_TIMEOUT=4' "$sample_legacy_curl_log" >/dev/null || ! grep -F 'MAX_TIME=40' "$sample_legacy_curl_log" >/dev/null; then
  printf 'SERVER_BOOTSTRAP_DOWNLOAD_SAMPLE_LEGACY_TIMEOUTS_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'CONFIG_ARGS=--force configscripts pyagent' "$sample_legacy_config_log" >/dev/null; then
  printf 'SERVER_BOOTSTRAP_DOWNLOAD_SAMPLE_LEGACY_CONFIG_ARGS_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'SERVER_BOOTSTRAP_DOWNLOADS_OK curl_fail_closed=1 retry=5 timeouts=1 sample_download=1\n'

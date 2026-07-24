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

if ! bash -n server/patches/websocket-proxy-wrapper.sh; then
  printf 'SERVER_WEBSOCKET_PROXY_WRAPPER_SYNTAX_INVALID file=server/patches/websocket-proxy-wrapper.sh\n' >&2
  failure_count=$((failure_count + 1))
fi

require_marker server/patches/websocket-proxy-wrapper.sh 'real_dir="${RC16_WRAPPER_REAL_DIR:-/usr/bin}"' SERVER_WEBSOCKET_PROXY_WRAPPER_REAL_DIR_OVERRIDE_MISSING
require_marker server/patches/websocket-proxy-wrapper.sh 'compose-executor|rancher-compose-executor)' SERVER_COMPOSE_EXECUTOR_WRAPPER_MAPPING_MISSING
require_marker server/patches/websocket-proxy-wrapper.sh 'real="${real_dir}/compose-executor.real"' SERVER_COMPOSE_EXECUTOR_REAL_MAPPING_MISSING
require_marker server/patches/websocket-proxy-wrapper.sh 'host-provisioner|go-machine-service)' SERVER_HOST_PROVISIONER_WRAPPER_MAPPING_MISSING
require_marker server/patches/websocket-proxy-wrapper.sh 'real="${real_dir}/host-provisioner.real"' SERVER_HOST_PROVISIONER_REAL_MAPPING_MISSING
require_marker server/patches/websocket-proxy-wrapper.sh 'catalog-service|rancher-catalog-service)' SERVER_CATALOG_WRAPPER_MAPPING_MISSING
require_marker server/patches/websocket-proxy-wrapper.sh 'real="${real_dir}/catalog-service.real"' SERVER_CATALOG_REAL_MAPPING_MISSING
require_marker server/patches/websocket-proxy-wrapper.sh 'authentication-service|rancher-auth-service)' SERVER_AUTH_WRAPPER_MAPPING_MISSING
require_marker server/patches/websocket-proxy-wrapper.sh 'real="${real_dir}/authentication-service.real"' SERVER_AUTH_REAL_MAPPING_MISSING
require_marker server/patches/websocket-proxy-wrapper.sh 'attempts="${PASTURESTACK_CATALOG_BOOTSTRAP_ATTEMPTS:-60}"' SERVER_CATALOG_BOOTSTRAP_ATTEMPTS_MISSING
require_marker server/patches/websocket-proxy-wrapper.sh 'endpoint="${PASTURESTACK_CATALOG_BOOTSTRAP_URL:-http://127.0.0.1:8088/v1-catalog/templates}"' SERVER_CATALOG_BOOTSTRAP_ENDPOINT_MISSING
require_marker server/patches/websocket-proxy-wrapper.sh '"${endpoint}?action=refresh"' SERVER_CATALOG_BOOTSTRAP_REFRESH_MISSING
require_marker server/patches/websocket-proxy-wrapper.sh 'PastureStack Catalog bootstrap verified a non-empty collection.' SERVER_CATALOG_BOOTSTRAP_SUCCESS_MARKER_MISSING
require_marker server/patches/websocket-proxy-wrapper.sh 'ready_connect_timeout="${RC16_CATTLE_READY_CONNECT_TIMEOUT:-2}"' SERVER_WEBSOCKET_PROXY_READY_CONNECT_TIMEOUT_MISSING
require_marker server/patches/websocket-proxy-wrapper.sh 'ready_max_time="${RC16_CATTLE_READY_CURL_TIMEOUT:-5}"' SERVER_WEBSOCKET_PROXY_READY_MAX_TIME_MISSING
require_marker server/patches/websocket-proxy-wrapper.sh 'curl -sS -o /dev/null -w "%{http_code}" --connect-timeout "$ready_connect_timeout" --max-time "$ready_max_time" "$ready_url"' SERVER_WEBSOCKET_PROXY_READY_CURL_NOT_BOUNDED
reject_marker server/patches/websocket-proxy-wrapper.sh 'curl -sS -o /dev/null -w "%{http_code}" --max-time "${RC16_CATTLE_READY_CURL_TIMEOUT:-5}" "$ready_url"' SERVER_WEBSOCKET_PROXY_READY_LEGACY_CURL

sample_dir=$(mktemp -d "${TMPDIR:-/tmp}/rc16-websocket-wrapper.XXXXXX")
cleanup() {
  rm -rf "$sample_dir"
}
trap cleanup EXIT

for canonical in websocket-proxy compose-executor host-provisioner catalog-service authentication-service; do
  cp server/patches/websocket-proxy-wrapper.sh "$sample_dir/$canonical"
  chmod +x "$sample_dir/$canonical"
  cat >"$sample_dir/$canonical.real" <<'EOF'
#!/usr/bin/env bash
printf 'REAL_NAME=%s\n' "${0##*/}"
printf 'ARGS=%s\n' "$*"
EOF
  chmod +x "$sample_dir/$canonical.real"
done

ln -s compose-executor "$sample_dir/rancher-compose-executor"
ln -s host-provisioner "$sample_dir/go-machine-service"
ln -s catalog-service "$sample_dir/rancher-catalog-service"
ln -s authentication-service "$sample_dir/rancher-auth-service"

for mapping in \
  websocket-proxy:websocket-proxy \
  compose-executor:compose-executor \
  rancher-compose-executor:compose-executor \
  host-provisioner:host-provisioner \
  go-machine-service:host-provisioner \
  catalog-service:catalog-service \
  rancher-catalog-service:catalog-service \
  authentication-service:authentication-service \
  rancher-auth-service:authentication-service; do
  invoked=${mapping%%:*}
  canonical=${mapping#*:}
  output="$sample_dir/output-$invoked"
  RC16_WRAPPER_REAL_DIR="$sample_dir" RC16_CATTLE_READY_TIMEOUT=0 \
    PASTURESTACK_CATALOG_BOOTSTRAP_ATTEMPTS=0 \
    GMS_BIN_DIR="$sample_dir/bin" \
    "$sample_dir/$invoked" alpha beta >"$output"

  if ! grep -F "REAL_NAME=${canonical}.real" "$output" >/dev/null; then
    printf 'SERVER_SERVICE_WRAPPER_SAMPLE_REAL_NOT_EXECUTED invoked=%s canonical=%s\n' "$invoked" "$canonical" >&2
    failure_count=$((failure_count + 1))
  fi

  if ! grep -F 'ARGS=alpha beta' "$output" >/dev/null; then
    printf 'SERVER_SERVICE_WRAPPER_SAMPLE_ARGS_NOT_PRESERVED invoked=%s\n' "$invoked" >&2
    failure_count=$((failure_count + 1))
  fi
done

cat >"$sample_dir/catalog-service.real" <<'EOF'
#!/usr/bin/env bash
sleep 1
printf 'REAL_NAME=%s\n' "${0##*/}"
printf 'ARGS=%s\n' "$*"
EOF
chmod +x "$sample_dir/catalog-service.real"

cat >"$sample_dir/mock-curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

state_file=${RC16_CATALOG_TEST_STATE:?}
case " $* " in
  *" -X POST "*)
    printf 'refreshed\n' >"$state_file"
    exit 0
    ;;
esac

if [ -s "$state_file" ]; then
  printf '{"data":[{"id":"pasturestack:infra*sample:1"}]}\n'
else
  printf '{"data":[]}\n'
fi
EOF
chmod +x "$sample_dir/mock-curl"

catalog_output="$sample_dir/output-catalog-bootstrap"
catalog_error="$sample_dir/error-catalog-bootstrap"
catalog_state="$sample_dir/catalog-bootstrap-state"
RC16_WRAPPER_REAL_DIR="$sample_dir" \
  RC16_CURL_BIN="$sample_dir/mock-curl" \
  RC16_CATALOG_TEST_STATE="$catalog_state" \
  PASTURESTACK_CATALOG_BOOTSTRAP_ATTEMPTS=5 \
  PASTURESTACK_CATALOG_BOOTSTRAP_DELAY_SECONDS=0 \
  "$sample_dir/catalog-service" alpha beta >"$catalog_output" 2>"$catalog_error"

if ! grep -Fx 'refreshed' "$catalog_state" >/dev/null; then
  printf 'SERVER_CATALOG_BOOTSTRAP_REFRESH_NOT_TRIGGERED\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'PastureStack Catalog bootstrap verified a non-empty collection.' "$catalog_error" >/dev/null; then
  printf 'SERVER_CATALOG_BOOTSTRAP_NON_EMPTY_NOT_VERIFIED\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'REAL_NAME=catalog-service.real' "$catalog_output" >/dev/null; then
  printf 'SERVER_CATALOG_BOOTSTRAP_REAL_NOT_EXECUTED\n' >&2
  failure_count=$((failure_count + 1))
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'SERVER_WEBSOCKET_PROXY_WRAPPER_OK bounded_ready_curl=1 catalog_bootstrap_retry=1 real_dir_override=1 canonical_and_legacy_exec_smoke=1\n'

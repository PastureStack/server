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

require_marker server/patches/bootstrap.sh 'apply_read_env_line()' SERVER_BOOTSTRAP_READ_ENV_HELPER_MISSING
require_marker server/patches/bootstrap.sh '([A-Za-z_][A-Za-z0-9_]*)=(.*)$' SERVER_BOOTSTRAP_READ_ENV_IDENTIFIER_GUARD_MISSING
require_marker server/patches/bootstrap.sh 'export "$key=$value"' SERVER_BOOTSTRAP_READ_ENV_EXPORT_MISSING
require_marker server/patches/bootstrap.sh 'apply_read_env_line "$LINE"' SERVER_BOOTSTRAP_READ_ENV_HELPER_NOT_USED
require_marker server/patches/bootstrap.sh 'PASTURESTACK_AGENT_CONTAINER_NAME=${PASTURESTACK_AGENT_CONTAINER_NAME:-pasturestack-node-agent}' SERVER_BOOTSTRAP_PRIMARY_AGENT_CONTAINER_MISSING
require_marker server/patches/bootstrap.sh 'PASTURESTACK_AGENT_UPGRADE_CONTAINER_NAME=${PASTURESTACK_AGENT_UPGRADE_CONTAINER_NAME:-pasturestack-node-agent-upgrade}' SERVER_BOOTSTRAP_PRIMARY_UPGRADE_CONTAINER_MISSING
require_marker server/patches/bootstrap.sh 'LEGACY_AGENT_CONTAINER_NAME=${LEGACY_AGENT_CONTAINER_NAME:-rancher-agent}' SERVER_BOOTSTRAP_LEGACY_AGENT_COMPATIBILITY_MISSING
require_marker server/patches/bootstrap.sh 'for upgrade_container in "${PASTURESTACK_AGENT_UPGRADE_CONTAINER_NAME}" "${LEGACY_AGENT_UPGRADE_CONTAINER_NAME}"; do' SERVER_BOOTSTRAP_UPGRADE_DUAL_CLEANUP_MISSING
require_marker server/patches/bootstrap.sh '--name "${PASTURESTACK_AGENT_UPGRADE_CONTAINER_NAME}"' SERVER_BOOTSTRAP_UPGRADE_PRIMARY_NAME_MISSING
require_marker server/patches/bootstrap.sh 'docker inspect -f '\''{{.Config.Image}}'\'' "${PASTURESTACK_AGENT_CONTAINER_NAME}"' SERVER_BOOTSTRAP_PRIMARY_AGENT_INSPECT_MISSING
require_marker server/patches/bootstrap.sh 'docker inspect -f '\''{{.Config.Image}}'\'' "${LEGACY_AGENT_CONTAINER_NAME}"' SERVER_BOOTSTRAP_LEGACY_AGENT_INSPECT_MISSING
reject_marker server/patches/bootstrap.sh 'eval "$LINE"' SERVER_BOOTSTRAP_READ_ENV_EVAL

sample_functions=$(mktemp "${TMPDIR:-/tmp}/rc16-bootstrap-read-env-functions.XXXXXX")
sample_output=$(mktemp "${TMPDIR:-/tmp}/rc16-bootstrap-read-env-output.XXXXXX")
sample_marker=$(mktemp "${TMPDIR:-/tmp}/rc16-bootstrap-read-env-marker.XXXXXX")
cleanup() {
  rm -f "$sample_functions" "$sample_output" "$sample_marker"
}
trap cleanup EXIT
rm -f "$sample_marker"

awk '
  /^error\(\)/,/^}/ { print }
  /^apply_read_env_line\(\)/,/^}/ { print }
' server/patches/bootstrap.sh >"$sample_functions"

cat >>"$sample_functions" <<EOF
apply_read_env_line 'CATTLE_AGENT_IP=192.0.2.10'
apply_read_env_line 'export CATTLE_AGENT_PORT=9345'
apply_read_env_line 'CATTLE_CONFIG_URL="http://127.0.0.1:8080/v1"'
apply_read_env_line "CATTLE_STORAGE_URL='http://127.0.0.1:8080/storage'"
apply_read_env_line 'CATTLE_SECRET_KEY=\$(touch $sample_marker)'
if ( apply_read_env_line 'BAD-NAME=value' ) >/dev/null 2>&1; then
  printf 'BAD_NAME_ACCEPTED=1\n'
else
  printf 'BAD_NAME_ACCEPTED=0\n'
fi
printf 'CATTLE_AGENT_IP=%s\n' "\${CATTLE_AGENT_IP:-}"
printf 'CATTLE_AGENT_PORT=%s\n' "\${CATTLE_AGENT_PORT:-}"
printf 'CATTLE_CONFIG_URL=%s\n' "\${CATTLE_CONFIG_URL:-}"
printf 'CATTLE_STORAGE_URL=%s\n' "\${CATTLE_STORAGE_URL:-}"
printf 'CATTLE_SECRET_KEY=%s\n' "\${CATTLE_SECRET_KEY:-}"
if [ -e '$sample_marker' ]; then
  printf 'COMMAND_SUBSTITUTION_EXECUTED=1\n'
else
  printf 'COMMAND_SUBSTITUTION_EXECUTED=0\n'
fi
EOF

bash "$sample_functions" >"$sample_output"

if ! grep -F 'CATTLE_AGENT_IP=192.0.2.10' "$sample_output" >/dev/null; then
  printf 'SERVER_BOOTSTRAP_READ_ENV_IP_SAMPLE_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'CATTLE_AGENT_PORT=9345' "$sample_output" >/dev/null; then
  printf 'SERVER_BOOTSTRAP_READ_ENV_PORT_SAMPLE_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'CATTLE_CONFIG_URL=http://127.0.0.1:8080/v1' "$sample_output" >/dev/null; then
  printf 'SERVER_BOOTSTRAP_READ_ENV_DOUBLE_QUOTE_SAMPLE_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'CATTLE_STORAGE_URL=http://127.0.0.1:8080/storage' "$sample_output" >/dev/null; then
  printf 'SERVER_BOOTSTRAP_READ_ENV_SINGLE_QUOTE_SAMPLE_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'BAD_NAME_ACCEPTED=0' "$sample_output" >/dev/null; then
  printf 'SERVER_BOOTSTRAP_READ_ENV_BAD_NAME_ACCEPTED\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'COMMAND_SUBSTITUTION_EXECUTED=0' "$sample_output" >/dev/null; then
  printf 'SERVER_BOOTSTRAP_READ_ENV_COMMAND_SUBSTITUTION_EXECUTED\n' >&2
  failure_count=$((failure_count + 1))
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'SERVER_BOOTSTRAP_READ_ENV_OK eval_free=1 assignment_parser=1 injection_sample=1\n'

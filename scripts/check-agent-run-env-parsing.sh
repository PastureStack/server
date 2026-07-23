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
  fail "AGENT_RUN_ENV_SYNTAX_INVALID"
fi

require_marker agent/run.sh 'apply_agent_env_line()' AGENT_RUN_ENV_HELPER_MISSING
require_marker agent/run.sh 'trim_agent_env_line()' AGENT_RUN_ENV_TRIM_HELPER_MISSING
require_marker agent/run.sh 'export "$key=$value"' AGENT_RUN_ENV_LITERAL_EXPORT_MISSING
require_marker agent/run.sh 'apply_agent_env_output "$content"' AGENT_RUN_REGISTRATION_SCRIPT_PARSER_NOT_USED
require_marker agent/run.sh 'apply_agent_env_output "$env"' AGENT_RUN_REGISTER_ENV_PARSER_NOT_USED
require_marker agent/run.sh "jq -r '.[0].Config.Env[]?'" AGENT_RUN_DOCKER_ENV_RAW_JQ_MISSING
require_marker agent/run.sh 'apply_agent_info_env_output "$content"' AGENT_RUN_INFO_ENV_PARSER_NOT_USED
require_marker agent/run.sh 'export RANCHER_AGENT_IMAGE=$save' AGENT_RUN_IMAGE_RESTORE_EXPORT_MISSING
require_marker agent/run.sh 'PASTURESTACK_AGENT_CONTAINER_NAME=${PASTURESTACK_AGENT_CONTAINER_NAME:-pasturestack-node-agent}' AGENT_RUN_PRIMARY_CONTAINER_NAME_MISSING
require_marker agent/run.sh 'LEGACY_AGENT_CONTAINER_NAME=${LEGACY_AGENT_CONTAINER_NAME:-rancher-agent}' AGENT_RUN_LEGACY_CONTAINER_COMPATIBILITY_MISSING
require_marker agent/run.sh '--name "${PASTURESTACK_AGENT_CONTAINER_NAME}"' AGENT_RUN_NEW_CONTAINER_NOT_PRIMARY
require_marker agent/run.sh 'container="$(agent_container_name)"' AGENT_RUN_CURRENT_CONTAINER_SELECTION_MISSING

reject_marker agent/run.sh 'eval "$content"' AGENT_RUN_REGISTRATION_SCRIPT_EVAL
reject_marker agent/run.sh 'eval "$ENV"' AGENT_RUN_REGISTER_EVAL
reject_marker agent/run.sh 'eval $(docker inspect rancher-agent' AGENT_RUN_DOCKER_ENV_EVAL
reject_marker agent/run.sh 'eval $(echo "$content" | grep '\''INFO: env'\''' AGENT_RUN_INFO_ENV_EVAL
reject_marker agent/run.sh '--name rancher-agent \' AGENT_RUN_LEGACY_CONTAINER_STILL_PRIMARY

sample_run=$(mktemp -d "${TMPDIR:-/tmp}/rc16-agent-run-env.XXXXXX")
sample_functions=$(mktemp "${TMPDIR:-/tmp}/rc16-agent-run-env-functions.XXXXXX")
trap 'rm -rf "$sample_run" "$sample_functions"' EXIT

extract_function() {
  local function_name=$1
  sed -n "/^${function_name}()/,/^}$/p" agent/run.sh
}

{
  extract_function info
  extract_function error
  extract_function trim_agent_env_line
  extract_function apply_agent_env_line
  extract_function apply_agent_env_output
  extract_function apply_agent_info_env_output
  extract_function print_url
  extract_function load
  extract_function register
  extract_function agent_container_name
  extract_function read_node_agent_env
} >"$sample_functions"

cat >"$sample_run/register.py" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' 'export CATTLE_ACCESS_KEY=access'
printf '%s\n' "export CATTLE_SECRET_KEY='secret value'"
printf '%s\n' 'export "CATTLE_HOST_LABELS=role=db node"'
STUB
chmod +x "$sample_run/register.py"

mkdir -p "$sample_run/bin"
cat >"$sample_run/bin/docker" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf 'DOCKER_ARGS=%s\n' "$*" >>"$RC16_AGENT_ENV_DOCKER_LOG"
printf '%s\n' '{}'
STUB
chmod +x "$sample_run/bin/docker"

cat >"$sample_run/bin/jq" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf 'JQ_ARGS=%s\n' "$*" >>"$RC16_AGENT_ENV_JQ_LOG"
cat >/dev/null
printf '%s\n' 'RANCHER_AGENT_IMAGE=from-container'
printf '%s\n' 'CATTLE_DOCKER_UUID=docker uuid with spaces'
printf '%s\n' 'CATTLE_MEMORY_OVERRIDE=4096'
STUB
chmod +x "$sample_run/bin/jq"

sample_output="$sample_run/output.log"
marker="$sample_run/command-substitution-marker"
docker_log="$sample_run/docker.log"
jq_log="$sample_run/jq.log"

(
  # shellcheck source=/dev/null
  source "$sample_functions"
  export PATH="$sample_run/bin:$PATH"
  export RC16_AGENT_ENV_DOCKER_LOG="$docker_log"
  export RC16_AGENT_ENV_JQ_LOG="$jq_log"
  export PASTURESTACK_AGENT_CONTAINER_NAME=pasturestack-node-agent
  export LEGACY_AGENT_CONTAINER_NAME=rancher-agent

  agent_curl() {
    if [ "$*" != "-fsSL http://registration.example/script" ]; then
      printf 'UNEXPECTED_AGENT_CURL=%s\n' "$*" >&2
      return 99
    fi

    printf '%s\n' '#!/bin/sh'
    printf '%s\n' 'export CATTLE_REGISTRATION_ACCESS_KEY="registrationToken"'
    printf '%s\n' 'export CATTLE_REGISTRATION_SECRET_KEY="secret token"'
    printf '%s\n' 'export CATTLE_URL="http://server.example/v1"'
    printf '%s\n' 'export DETECTED_CATTLE_AGENT_IP="192.0.2.55"'
    printf '%s\n' 'export CATTLE_URL_OVERRIDE="http://override.example/v1"'
    printf '%s\n' "export CATTLE_SECRET_KEY='\$(touch $marker)'"
  }

  cd "$sample_run"
  load "http://registration.example/script"
  printf 'LOAD_REG_ACCESS=%s\n' "${CATTLE_REGISTRATION_ACCESS_KEY:-}"
  printf 'LOAD_REG_SECRET=%s\n' "${CATTLE_REGISTRATION_SECRET_KEY:-}"
  printf 'LOAD_CATTLE_URL=%s\n' "${CATTLE_URL:-}"
  printf 'LOAD_DETECTED_IP=%s\n' "${DETECTED_CATTLE_AGENT_IP:-}"
  printf 'LOAD_LITERAL_SECRET=%s\n' "${CATTLE_SECRET_KEY:-}"

  TOKEN='sample-token'
  register
  printf 'REGISTER_ACCESS=%s\n' "${CATTLE_ACCESS_KEY:-}"
  printf 'REGISTER_SECRET=%s\n' "${CATTLE_SECRET_KEY:-}"
  printf 'REGISTER_LABELS=%s\n' "${CATTLE_HOST_LABELS:-}"

  apply_agent_info_env_output $'noise\nINFO: env TOKEN=abc123\nINFO: env "CATTLE_VAR_LIB_WRITABLE=true"\nINFO: env export CATTLE_BOOT2DOCKER=false'
  printf 'INFO_TOKEN=%s\n' "${TOKEN:-}"
  printf 'INFO_WRITABLE=%s\n' "${CATTLE_VAR_LIB_WRITABLE:-}"
  printf 'INFO_BOOT2DOCKER=%s\n' "${CATTLE_BOOT2DOCKER:-}"

  RANCHER_AGENT_IMAGE='original-image'
  read_node_agent_env
  printf 'RESTORED_IMAGE=%s\n' "${RANCHER_AGENT_IMAGE:-}"
  printf 'DOCKER_UUID=%s\n' "${CATTLE_DOCKER_UUID:-}"
  printf 'MEMORY_OVERRIDE=%s\n' "${CATTLE_MEMORY_OVERRIDE:-}"

  apply_agent_env_line "CATTLE_SECRET_KEY=\$(touch $marker)"
  printf 'LITERAL_SECRET=%s\n' "${CATTLE_SECRET_KEY:-}"

  if apply_agent_env_line 'BAD-NAME=value' 2>/dev/null; then
    printf '%s\n' 'INVALID_KEY_ACCEPTED=1'
  else
    printf '%s\n' 'INVALID_KEY_REJECTED=1'
  fi
) >"$sample_output"

for expected in \
  'LOAD_REG_ACCESS=registrationToken' \
  'LOAD_REG_SECRET=secret token' \
  'LOAD_CATTLE_URL=http://override.example/v1' \
  'LOAD_DETECTED_IP=192.0.2.55' \
  "LOAD_LITERAL_SECRET=\$(touch $marker)" \
  'REGISTER_ACCESS=access' \
  'REGISTER_SECRET=secret value' \
  'REGISTER_LABELS=role=db node' \
  'INFO_TOKEN=abc123' \
  'INFO_WRITABLE=true' \
  'INFO_BOOT2DOCKER=false' \
  'RESTORED_IMAGE=original-image' \
  'DOCKER_UUID=docker uuid with spaces' \
  'MEMORY_OVERRIDE=4096' \
  "LITERAL_SECRET=\$(touch $marker)" \
  'INVALID_KEY_REJECTED=1'; do
  if ! grep -F -- "$expected" "$sample_output" >/dev/null; then
    fail "AGENT_RUN_ENV_SAMPLE_MISSING expected=$expected"
  fi
done

if [ -e "$marker" ]; then
  fail "AGENT_RUN_ENV_COMMAND_SUBSTITUTION_EXECUTED"
fi

if ! grep -F 'DOCKER_ARGS=inspect pasturestack-node-agent' "$docker_log" >/dev/null; then
  fail "AGENT_RUN_ENV_DOCKER_INSPECT_NOT_CALLED"
fi

if ! grep -F "JQ_ARGS=-r .[0].Config.Env[]?" "$jq_log" >/dev/null; then
  fail "AGENT_RUN_ENV_JQ_RAW_ENV_NOT_USED"
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'AGENT_RUN_ENV_PARSING_OK registration_script_eval_free=1 register_eval_free=1 docker_env_eval_free=1 info_env_eval_free=1 command_substitution_literal=1\n'

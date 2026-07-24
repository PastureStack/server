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

if ! bash -n server/artifacts/cattle.sh; then
  printf 'SERVER_CATTLE_SH_SYNTAX_INVALID file=server/artifacts/cattle.sh\n' >&2
  failure_count=$((failure_count + 1))
fi

require_marker server/artifacts/cattle.sh 'linked_env_value()' SERVER_CATTLE_SH_LINKED_ENV_HELPER_MISSING
require_marker server/artifacts/cattle.sh 'printf '"'"'%s'"'"' "${!name:-}"' SERVER_CATTLE_SH_LINKED_ENV_INDIRECT_EXPANSION_MISSING
require_marker server/artifacts/cattle.sh 'while [ -n "$(linked_env_value "REDIS${i}_PORT_6379_TCP_ADDR")" ]; do' SERVER_CATTLE_SH_REDIS_LINKED_ENV_HELPER_NOT_USED
require_marker server/artifacts/cattle.sh 'while [ -n "$(linked_env_value "ZK${i}_PORT_2181_TCP_ADDR")" ]; do' SERVER_CATTLE_SH_ZK_LINKED_ENV_HELPER_NOT_USED
reject_marker server/artifacts/cattle.sh 'eval echo $REDIS' SERVER_CATTLE_SH_REDIS_EVAL_LINKED_ENV
reject_marker server/artifacts/cattle.sh 'eval echo $ZK' SERVER_CATTLE_SH_ZK_EVAL_LINKED_ENV
reject_marker server/artifacts/cattle.sh 'eval echo \$REDIS' SERVER_CATTLE_SH_REDIS_ESCAPED_EVAL_LINKED_ENV
reject_marker server/artifacts/cattle.sh 'eval echo \$ZK' SERVER_CATTLE_SH_ZK_ESCAPED_EVAL_LINKED_ENV

sample_functions=$(mktemp "${TMPDIR:-/tmp}/rc16-cattle-linked-env-functions.XXXXXX")
sample_output=$(mktemp "${TMPDIR:-/tmp}/rc16-cattle-linked-env-output.XXXXXX")
sample_bin=$(mktemp -d "${TMPDIR:-/tmp}/rc16-cattle-linked-env-bin.XXXXXX")
cleanup() {
  rm -f "$sample_functions" "$sample_output"
  rm -rf "$sample_bin"
}
trap cleanup EXIT

cat >"$sample_bin/nc" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null
printf 'imok\n'
EOF
chmod +x "$sample_bin/nc"

awk '
  /^linked_env_value\(\)/,/^}/ { print }
  /^setup_redis\(\)/,/^}/ { print }
  /^setup_zk\(\)/,/^}/ { print }
' server/artifacts/cattle.sh >"$sample_functions"

cat >>"$sample_functions" <<'EOF'
REDIS1_PORT_6379_TCP_ADDR=10.0.0.10
REDIS1_PORT_6379_TCP_PORT=6379
REDIS2_PORT_6379_TCP_ADDR=10.0.0.11
REDIS2_PORT_6379_TCP_PORT=6380
ZK1_PORT_2181_TCP_ADDR=10.0.1.10
ZK1_PORT_2181_TCP_PORT=2181
ZK2_PORT_2181_TCP_ADDR=10.0.1.11
ZK2_PORT_2181_TCP_PORT=2182
setup_redis
setup_zk
printf 'CATTLE_REDIS_HOSTS=%s\n' "${CATTLE_REDIS_HOSTS:-}"
printf 'CATTLE_ZOOKEEPER_CONNECTION_STRING=%s\n' "${CATTLE_ZOOKEEPER_CONNECTION_STRING:-}"
printf 'CATTLE_MODULE_PROFILE_REDIS=%s\n' "${CATTLE_MODULE_PROFILE_REDIS:-}"
printf 'CATTLE_MODULE_PROFILE_ZOOKEEPER=%s\n' "${CATTLE_MODULE_PROFILE_ZOOKEEPER:-}"
EOF

PATH="$sample_bin:$PATH" bash "$sample_functions" >"$sample_output"

if ! grep -F 'CATTLE_REDIS_HOSTS=10.0.0.10:6379,10.0.0.11:6380' "$sample_output" >/dev/null; then
  printf 'SERVER_CATTLE_SH_REDIS_LINKED_ENV_SAMPLE_MISMATCH\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'CATTLE_ZOOKEEPER_CONNECTION_STRING=10.0.1.10:2181,10.0.1.11:2182' "$sample_output" >/dev/null; then
  printf 'SERVER_CATTLE_SH_ZK_LINKED_ENV_SAMPLE_MISMATCH\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'CATTLE_MODULE_PROFILE_REDIS=true' "$sample_output" >/dev/null; then
  printf 'SERVER_CATTLE_SH_REDIS_PROFILE_SAMPLE_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'CATTLE_MODULE_PROFILE_ZOOKEEPER=true' "$sample_output" >/dev/null; then
  printf 'SERVER_CATTLE_SH_ZK_PROFILE_SAMPLE_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'SERVER_CATTLE_SH_LINKED_ENV_OK eval_free=1 redis_sample=1 zk_sample=1\n'

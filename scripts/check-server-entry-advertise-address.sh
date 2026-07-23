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

if ! bash -n server/bin/entry; then
  printf 'SERVER_ENTRY_SHELL_SYNTAX_INVALID file=server/bin/entry\n' >&2
  failure_count=$((failure_count + 1))
fi

require_marker server/bin/entry 'fetch_advertise_address()' SERVER_ENTRY_ADVERTISE_HELPER_MISSING
require_marker server/bin/entry 'fetch_interface_advertise_address()' SERVER_ENTRY_INTERFACE_ADVERTISE_HELPER_MISSING
require_marker server/bin/entry 'local value' SERVER_ENTRY_ADVERTISE_LOCAL_VALUE_MISSING
require_marker server/bin/entry 'value=$(curl -fsS --connect-timeout "$connect_timeout" --max-time "$max_time" "$url")' SERVER_ENTRY_ADVERTISE_CURL_NOT_FAIL_CLOSED
require_marker server/bin/entry 'ip_output=$(ip addr show dev "$interface_name")' SERVER_ENTRY_INTERFACE_IP_LOOKUP_MISSING
require_marker server/bin/entry 'value=$(printf' SERVER_ENTRY_INTERFACE_PARSE_MISSING
require_marker server/bin/entry 'if [ -z "$value" ]; then' SERVER_ENTRY_ADVERTISE_EMPTY_VALUE_NOT_REJECTED
require_marker server/bin/entry 'if [ -e "${PASTURESTACK_SYS_CLASS_NET:-${RC16_SYS_CLASS_NET:-/sys/class/net}}/$1" ]; then' SERVER_ENTRY_INTERFACE_SYSFS_OVERRIDE_MISSING
require_marker server/bin/entry 'CATTLE_CLUSTER_ADVERTISE_ADDRESS=$(fetch_interface_advertise_address "$1")' SERVER_ENTRY_INTERFACE_HELPER_NOT_USED
require_marker server/bin/entry 'CATTLE_CLUSTER_ADVERTISE_ADDRESS=$(fetch_advertise_address awslocal "${PASTURESTACK_AWSLOCAL_METADATA_URL:-${RC16_AWSLOCAL_METADATA_URL:-http://169.254.169.254/latest/meta-data/local-ipv4}}")' SERVER_ENTRY_AWSLOCAL_HELPER_NOT_USED
require_marker server/bin/entry 'CATTLE_CLUSTER_ADVERTISE_ADDRESS=$(fetch_advertise_address ipify "${PASTURESTACK_IPIFY_URL:-${RC16_IPIFY_URL:-https://api.ipify.org}}")' SERVER_ENTRY_IPIFY_HELPER_NOT_USED
reject_marker server/bin/entry 'export CATTLE_CLUSTER_ADVERTISE_ADDRESS=$(ip addr show dev "$1" | grep -w inet | awk' SERVER_ENTRY_INTERFACE_LEGACY_PIPELINE
reject_marker server/bin/entry 'export CATTLE_CLUSTER_ADVERTISE_ADDRESS=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)' SERVER_ENTRY_AWSLOCAL_LEGACY_CURL
reject_marker server/bin/entry 'export CATTLE_CLUSTER_ADVERTISE_ADDRESS=$(curl -s https://api.ipify.org)' SERVER_ENTRY_IPIFY_LEGACY_CURL

sample_sys=$(mktemp -d "${TMPDIR:-/tmp}/rc16-sys-net.XXXXXX")
sample_bin=$(mktemp -d "${TMPDIR:-/tmp}/rc16-entry-bin.XXXXXX")
sample_ipify=$(mktemp "${TMPDIR:-/tmp}/rc16-ipify.XXXXXX")
sample_awslocal=$(mktemp "${TMPDIR:-/tmp}/rc16-awslocal.XXXXXX")
sample_empty=$(mktemp "${TMPDIR:-/tmp}/rc16-empty-advertise.XXXXXX")
sample_output=$(mktemp "${TMPDIR:-/tmp}/rc16-entry-advertise-output.XXXXXX")
cleanup() {
  rm -f "$sample_ipify" "$sample_awslocal" "$sample_empty" "$sample_output"
  rm -f "$sample_bin/ip"
  rmdir "$sample_sys/eth-test" "$sample_bin" "$sample_sys" 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p "$sample_sys/eth-test"
cat >"$sample_bin/ip" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ "${RC16_ENTRY_IP_STUB_MODE:-ok}" = "fail" ]; then
  exit 1
fi

if [ "$#" -ne 4 ] || [ "$1" != "addr" ] || [ "$2" != "show" ] || [ "$3" != "dev" ] || [ "$4" != "eth-test" ]; then
  printf 'unexpected ip invocation: %s\n' "$*" >&2
  exit 2
fi

if [ "${RC16_ENTRY_IP_STUB_MODE:-ok}" = "empty" ]; then
  printf '2: eth-test: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500\n'
  exit 0
fi

cat <<'IP_OUTPUT'
2: eth-test: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
    inet 198.51.100.24/24 brd 198.51.100.255 scope global eth-test
IP_OUTPUT
EOF
chmod +x "$sample_bin/ip"

printf '203.0.113.42\n' >"$sample_ipify"
printf '10.42.0.15\n' >"$sample_awslocal"
: >"$sample_empty"

PATH="$sample_bin:$PATH" RC16_SYS_CLASS_NET="$sample_sys" bash server/bin/entry --advertise-address eth-test env >"$sample_output"
if ! grep -F 'CATTLE_CLUSTER_ADVERTISE_ADDRESS=198.51.100.24' "$sample_output" >/dev/null; then
  printf 'SERVER_ENTRY_INTERFACE_SAMPLE_ADDRESS_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

RC16_IPIFY_URL="file://$sample_ipify" bash server/bin/entry --advertise-address ipify env >"$sample_output"
if ! grep -F 'CATTLE_CLUSTER_ADVERTISE_ADDRESS=203.0.113.42' "$sample_output" >/dev/null; then
  printf 'SERVER_ENTRY_IPIFY_SAMPLE_ADDRESS_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

RC16_AWSLOCAL_METADATA_URL="file://$sample_awslocal" bash server/bin/entry --advertise-address awslocal env >"$sample_output"
if ! grep -F 'CATTLE_CLUSTER_ADVERTISE_ADDRESS=10.42.0.15' "$sample_output" >/dev/null; then
  printf 'SERVER_ENTRY_AWSLOCAL_SAMPLE_ADDRESS_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

if RC16_IPIFY_URL="file://$sample_empty" bash server/bin/entry --advertise-address ipify true >/dev/null 2>&1; then
  printf 'SERVER_ENTRY_EMPTY_ADVERTISE_VALUE_ACCEPTED\n' >&2
  failure_count=$((failure_count + 1))
fi

if RC16_IPIFY_URL='file:///tmp/rc16-missing-advertise-address' bash server/bin/entry --advertise-address ipify true >/dev/null 2>&1; then
  printf 'SERVER_ENTRY_FAILED_ADVERTISE_FETCH_ACCEPTED\n' >&2
  failure_count=$((failure_count + 1))
fi

if PATH="$sample_bin:$PATH" RC16_ENTRY_IP_STUB_MODE=fail RC16_SYS_CLASS_NET="$sample_sys" bash server/bin/entry --advertise-address eth-test true >/dev/null 2>&1; then
  printf 'SERVER_ENTRY_FAILED_INTERFACE_LOOKUP_ACCEPTED\n' >&2
  failure_count=$((failure_count + 1))
fi

if PATH="$sample_bin:$PATH" RC16_ENTRY_IP_STUB_MODE=empty RC16_SYS_CLASS_NET="$sample_sys" bash server/bin/entry --advertise-address eth-test true >/dev/null 2>&1; then
  printf 'SERVER_ENTRY_EMPTY_INTERFACE_LOOKUP_ACCEPTED\n' >&2
  failure_count=$((failure_count + 1))
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'SERVER_ENTRY_ADVERTISE_ADDRESS_OK curl_fail_closed=1 empty_rejected=1 ipify_sample=1 awslocal_sample=1 interface_sample=1 interface_fail_closed=1 interface_empty_rejected=1\n'

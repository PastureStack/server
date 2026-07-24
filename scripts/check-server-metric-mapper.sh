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

if grep -n $'\r' server/bin/metric_mapper.sh; then
  printf 'SERVER_METRIC_MAPPER_CRLF_LINE_ENDINGS file=server/bin/metric_mapper.sh\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! bash -n server/bin/metric_mapper.sh; then
  printf 'SERVER_METRIC_MAPPER_SHELL_SYNTAX_INVALID file=server/bin/metric_mapper.sh\n' >&2
  failure_count=$((failure_count + 1))
fi

require_marker server/bin/metric_mapper.sh 'set -euo pipefail' SERVER_METRIC_MAPPER_STRICT_SHELL_MISSING
require_marker server/bin/metric_mapper.sh 'metrics_url=${METRICS_URL:-http://localhost:9108/metrics}' SERVER_METRIC_MAPPER_URL_DEFAULT_UNSAFE
require_marker server/bin/metric_mapper.sh 'metrics_file=$(mktemp "${TMPDIR:-/tmp}/rc16-metric-map.XXXXXX")' SERVER_METRIC_MAPPER_TMP_FILE_MISSING
require_marker server/bin/metric_mapper.sh 'curl -fsS --connect-timeout "$connect_timeout" --max-time "$max_time" -o "$metrics_file" "$metrics_url"' SERVER_METRIC_MAPPER_CURL_NOT_FAIL_CLOSED
require_marker server/bin/metric_mapper.sh "awk '/^# HELP/ && /servers\\./ { print \$6 }' \"\$metrics_file\"" SERVER_METRIC_MAPPER_FILE_BACKED_PARSE_MISSING
reject_marker server/bin/metric_mapper.sh 'curl -s $metrics_url | grep' SERVER_METRIC_MAPPER_LEGACY_PIPELINE

sample_metrics=$(mktemp "${TMPDIR:-/tmp}/rc16-metric-mapper-sample.XXXXXX")
sample_output=$(mktemp "${TMPDIR:-/tmp}/rc16-metric-mapper-output.XXXXXX")
cleanup() {
  rm -f "$sample_metrics" "$sample_output"
}
trap cleanup EXIT

cat >"$sample_metrics" <<'EOF'
# HELP graphite_metric generated from servers.1.metric.api.api_success_project_get.Count
# TYPE servers.1.metric.api.api_success_project_get.Count counter
# HELP graphite_metric generated from servers.1.jvm.memory.HeapMemoryUsage.used
# HELP graphite_metric generated from servers.1.metric.api.api_success_project_get.FiveMinuteRate
# HELP cattle.irrelevant.Count generated
EOF

METRICS_URL="file://$sample_metrics" bash server/bin/metric_mapper.sh >"$sample_output"

if ! grep -F 'servers.*.metric.api.api_success_project_get.Count' "$sample_output" >/dev/null; then
  printf 'SERVER_METRIC_MAPPER_SAMPLE_COUNT_MAPPING_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'name="cattle_metric_api_api_success_project_get_total"' "$sample_output" >/dev/null; then
  printf 'SERVER_METRIC_MAPPER_SAMPLE_NAME_MAPPING_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

if ! grep -F 'servers.*.jvm.memory.HeapMemoryUsage.used' "$sample_output" >/dev/null; then
  printf 'SERVER_METRIC_MAPPER_SAMPLE_GAUGE_MAPPING_MISSING\n' >&2
  failure_count=$((failure_count + 1))
fi

if grep -F 'FiveMinuteRate' "$sample_output" >/dev/null; then
  printf 'SERVER_METRIC_MAPPER_SAMPLE_CALCULATED_METRIC_NOT_SKIPPED\n' >&2
  failure_count=$((failure_count + 1))
fi

printf 'failure_count=%s\n' "$failure_count"
if [ "$failure_count" -ne 0 ]; then
  exit 1
fi

printf 'SERVER_METRIC_MAPPER_OK strict_shell=1 lf=1 curl_fail_closed=1 file_backed_parse=1 sample_mapping=1\n'

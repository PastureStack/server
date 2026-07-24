#!/usr/bin/env bash
set -euo pipefail

# Location of the default metrics endpoint.
metrics_url=${METRICS_URL:-http://localhost:9108/metrics}
connect_timeout=${RC16_METRIC_MAPPER_CONNECT_TIMEOUT:-2}
max_time=${RC16_METRIC_MAPPER_MAX_TIME:-10}
metrics_file=$(mktemp "${TMPDIR:-/tmp}/rc16-metric-map.XXXXXX")

cleanup() {
  rm -f "$metrics_file"
}
trap cleanup EXIT

curl -fsS --connect-timeout "$connect_timeout" --max-time "$max_time" -o "$metrics_file" "$metrics_url"

awk '/^# HELP/ && /servers\./ { print $6 }' "$metrics_file" | while IFS= read -r line; do
  case "$line" in
    *.Mean|*.Min|*.Max|*.FifteenMinuteRate|*.FiveMinuteRate|*.OneMinuteRate|*.95thPercentile)
      # Calculations can be done by scraping server directly.
      ;;
    *)
      name=$(printf '%s\n' "$line" \
        | sed 's/\(^servers\.[^\.]*\)\.\(.*$\)/\2/' \
        | sed 's/^/cattle_/' \
        | sed 's/\.Count/_total/' \
        | sed 's/\.*Count$/_total/' \
        | tr '.' '_')
      printf '%s\n' "$(printf '%s\n' "$line" | sed 's/\(^servers\.\)\([^\.]*\)\(.*$\)/\1\*\3/')"
      printf 'name="%s"\n' "$name"
      printf 'cattle_id="$1"\n\n'
      ;;
  esac
done

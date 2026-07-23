#!/usr/bin/env bash
set -euo pipefail

: "${RANCHER_URL:?set RANCHER_URL, for example http://rancher.example.invalid:8080}"
: "${RANCHER_ACCESS_KEY:?set RANCHER_ACCESS_KEY}"
: "${RANCHER_SECRET_KEY:?set RANCHER_SECRET_KEY}"

RANCHER_PROJECT_ID="${RANCHER_PROJECT_ID:-1a5}"
API="${RANCHER_URL%/}/v2-beta/projects/${RANCHER_PROJECT_ID}"
connect_timeout="${RC16_HOST_COMPAT_CONNECT_TIMEOUT:-10}"
max_time="${RC16_HOST_COMPAT_MAX_TIME:-120}"

fetch_hosts() {
  curl -fsS --retry 5 --retry-all-errors --retry-delay 2 \
    --connect-timeout "$connect_timeout" \
    --max-time "$max_time" \
    -u "${RANCHER_ACCESS_KEY}:${RANCHER_SECRET_KEY}" \
    "${API}/hosts?limit=-1"
}

fetch_hosts |
jq -r '
def lbl($k): ((.labels // {})[$k] // (.labels // {})["io.rancher.host." + $k] // "");
def docker_major:
  (lbl("docker_version") | capture("^(?<major>[0-9]+)")? | .major // "0" | tonumber);
def os_family:
  (lbl("os") // lbl("os_name") // .info.osInfo.operatingSystem // "");
def risk:
  if (.state != "active") then "not-active"
  elif docker_major >= 20 then "modern-candidate"
  elif docker_major >= 19 then "canary-required"
  else "legacy-channel-required"
  end;
(["id","name","state","docker","os","kernel","agent_ip","compat"] | @tsv),
(.data[] |
  [
    .id,
    .hostname,
    .state,
    lbl("docker_version"),
    os_family,
    (lbl("kernel_version") // .info.osInfo.kernelVersion // ""),
    (.agentIpAddress // ""),
    risk
  ] | @tsv
)'

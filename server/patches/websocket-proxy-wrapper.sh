#!/bin/bash
name="${0##*/}"
real_dir="${RC16_WRAPPER_REAL_DIR:-/usr/bin}"

case "$name" in
  compose-executor|rancher-compose-executor)
    real="${real_dir}/compose-executor.real"
    ;;
  host-provisioner|go-machine-service)
    real="${real_dir}/host-provisioner.real"
    ;;
  catalog-service|rancher-catalog-service)
    real="${real_dir}/catalog-service.real"
    ;;
  authentication-service|rancher-auth-service)
    real="${real_dir}/authentication-service.real"
    ;;
  *)
    real="${real_dir}/${name}.real"
    ;;
esac

if [ ! -x "$real" ]; then
  printf 'PastureStack service executable is missing: %s\n' "$real" >&2
  exit 127
fi

if [ "$name" = "websocket-proxy" ] &&
   [ "${RC16_DISABLE_EMBEDDED_PROXY_TLS:-true}" = "true" ] &&
   [ -n "${PROXY_TLS_LISTEN_ADDRESS:-}" ] &&
   [ "${PROXY_TLS_LISTEN_ADDRESS}" = "${PROXY_LISTEN_ADDRESS:-}" ]; then
  unset PROXY_TLS_LISTEN_ADDRESS
fi

case "$name" in
  catalog-service|rancher-catalog-service|authentication-service|rancher-auth-service)
    exec "$real" "$@"
    ;;
esac

if [ "$name" = "host-provisioner" ] || [ "$name" = "go-machine-service" ]; then
  export EVENT_SUBSCRIBER_MAX_WAIT_SECONDS="${RC16_GMS_EVENT_MAX_WAIT_SECONDS:-120}"
  export GMS_BIN_DIR="${GMS_BIN_DIR:-/var/lib/cattle/bin}"
  mkdir -p "$GMS_BIN_DIR"
  export PATH="${GMS_BIN_DIR}:$PATH"
fi

if [ "$name" = "websocket-proxy" ]; then
  ready_url="${RC16_CATTLE_READY_URL:-http://127.0.0.1:8081/v2-beta}"
else
  ready_url="${RC16_CATTLE_READY_URL:-http://127.0.0.1:8080/v2-beta}"
fi
ready_timeout="${RC16_CATTLE_READY_TIMEOUT:-180}"
ready_connect_timeout="${RC16_CATTLE_READY_CONNECT_TIMEOUT:-2}"
ready_max_time="${RC16_CATTLE_READY_CURL_TIMEOUT:-5}"
i=0
while [ "$i" -lt "$ready_timeout" ]; do
  status="$(curl -sS -o /dev/null -w "%{http_code}" --connect-timeout "$ready_connect_timeout" --max-time "$ready_max_time" "$ready_url" 2>/dev/null || true)"
  case "$status" in
    2*|3*|401|403)
      break
      ;;
  esac
  i=$((i + 1))
  sleep 1
done

exec -a "$name" "$real" "$@"

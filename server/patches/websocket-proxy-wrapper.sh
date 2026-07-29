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

if [ "$name" = "websocket-proxy" ] &&
   [ -x /usr/bin/pasturestack-console-broker ]; then
  # The broker owns the public listener.  Keep the existing authenticated edge
  # proxy on a private port and preserve its direct application control channel.
  export PROXY_LISTEN_ADDRESS="${PASTURESTACK_CONSOLE_PROXY_LISTEN_ADDRESS:-:8083}"
  export PROXY_CATTLE_ADDRESS="${PASTURESTACK_CONSOLE_APPLICATION_ADDRESS:-127.0.0.1:8081}"
fi

case "$name" in
  catalog-service|rancher-catalog-service)
    # The control-platform process can ask the Catalog Service to refresh as soon
    # as port 8088 opens.  On a cold restart that request may race the initial
    # repository setup and leave the in-memory collection empty until somebody
    # refreshes it manually.  Run a bounded bootstrap worker alongside the real
    # service so an empty collection is repaired automatically.
    (
      attempts="${PASTURESTACK_CATALOG_BOOTSTRAP_ATTEMPTS:-60}"
      delay="${PASTURESTACK_CATALOG_BOOTSTRAP_DELAY_SECONDS:-2}"
      connect_timeout="${PASTURESTACK_CATALOG_BOOTSTRAP_CONNECT_TIMEOUT:-2}"
      request_timeout="${PASTURESTACK_CATALOG_BOOTSTRAP_REQUEST_TIMEOUT:-30}"
      endpoint="${PASTURESTACK_CATALOG_BOOTSTRAP_URL:-http://127.0.0.1:8088/v1-catalog/templates}"
      curl_bin="${RC16_CURL_BIN:-curl}"
      i=0

      while [ "$i" -lt "$attempts" ]; do
        body="$("$curl_bin" -fsS \
          --connect-timeout "$connect_timeout" \
          --max-time "$request_timeout" \
          "$endpoint" 2>/dev/null || true)"

        if [ -n "$body" ]; then
          case "$body" in
            *'"data":[]'*)
              "$curl_bin" -fsS -o /dev/null -X POST \
                --connect-timeout "$connect_timeout" \
                --max-time "$request_timeout" \
                "${endpoint}?action=refresh" 2>/dev/null || true
              ;;
            *'"data":['*)
              printf 'PastureStack Catalog bootstrap verified a non-empty collection.\n' >&2
              exit 0
              ;;
          esac
        fi

        i=$((i + 1))
        sleep "$delay"
      done

      if [ "$attempts" -gt 0 ]; then
        printf 'PastureStack Catalog bootstrap did not obtain a non-empty collection after %s attempts.\n' \
          "$attempts" >&2
      fi
    ) &
    exec "$real" "$@"
    ;;
  authentication-service|rancher-auth-service)
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
  ready_address="${PASTURESTACK_CONSOLE_APPLICATION_ADDRESS:-127.0.0.1:8081}"
  ready_url="${RC16_CATTLE_READY_URL:-http://${ready_address}/v2-beta}"
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

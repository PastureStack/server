#!/usr/bin/env bash
set -euo pipefail

container=${RC16_RANCHER_CONTAINER:-pasturestack-server}
failures=0
warnings=0

fail() {
  failures=$((failures + 1))
  echo "FAIL $*"
}

warn() {
  warnings=$((warnings + 1))
  echo "WARN $*"
}

pass() {
  echo "PASS $*"
}

mysql_query() {
  docker exec -i "$container" mysql --batch --raw --skip-column-names cattle -e "$1"
}

setting_value() {
  local name=$1
  mysql_query "SELECT value FROM setting WHERE name='${name}' ORDER BY id DESC LIMIT 1;" | tail -n 1
}

if ! docker inspect "$container" >/dev/null 2>&1; then
  echo "PastureStack server container not found: $container" >&2
  exit 2
fi

printf 'RC16 DB sanity check %s\n' "$(date -Is)"
printf 'container=%s\n' "$container"

critical_settings=(
  account.by.key.credential.types
  api.security.enabled
  api.auth.provider.configured
  api.auth.local.access.mode
)

duplicates=$(mysql_query "SELECT name, COUNT(*) FROM setting WHERE name IN ('account.by.key.credential.types','api.security.enabled','api.auth.provider.configured','api.auth.local.access.mode') GROUP BY name HAVING COUNT(*) > 1;" || true)
if [ -n "$duplicates" ]; then
  fail "duplicate critical setting rows detected"
  printf '%s\n' "$duplicates" | sed 's/^/  /'
else
  pass "no duplicate critical setting rows"
fi

key_types=$(setting_value account.by.key.credential.types || true)
normalized_key_types=$(printf '%s' "$key_types" | tr -d '[:space:]')
case "$normalized_key_types" in
  *agentApiKey*apiKey*usernamePassword*|*agentApiKey*usernamePassword*apiKey*|*apiKey*agentApiKey*usernamePassword*|*apiKey*usernamePassword*agentApiKey*|*usernamePassword*agentApiKey*apiKey*|*usernamePassword*apiKey*agentApiKey*)
    pass "account.by.key.credential.types includes agentApiKey, apiKey, usernamePassword"
    ;;
  *)
    fail "account.by.key.credential.types is unsafe: ${key_types:-<missing>}"
    ;;
esac

case "$key_types" in
  *ghcr.io/*|*rancher/agent*|*rc16-agent*|*:*/*)
    fail "account.by.key.credential.types appears to contain an image reference: $key_types"
    ;;
esac

security_enabled=$(setting_value api.security.enabled || true)
auth_provider=$(setting_value api.auth.provider.configured || true)
case "$security_enabled" in
  true|false|'') pass "api.security.enabled=${security_enabled:-<default>}" ;;
  *) fail "api.security.enabled has unexpected value: $security_enabled" ;;
esac
case "$auth_provider" in
  none|localAuthConfig|azureConfig|openldapconfig|openLdapConfig|'') pass "api.auth.provider.configured=${auth_provider:-<default>}" ;;
  *) warn "api.auth.provider.configured has unrecognized value: $auth_provider" ;;
esac

if [ "$security_enabled" = true ]; then
  env_dump=$(docker inspect "$container" --format '{{range .Config.Env}}{{println .}}{{end}}')
  missing=0
  for name in CATTLE_ACCESS_KEY CATTLE_SECRET_KEY CATALOG_SERVICE_CATTLE_ACCESS_KEY CATALOG_SERVICE_CATTLE_SECRET_KEY CATTLE_URL CATALOG_SERVICE_CATTLE_URL; do
    if ! printf '%s\n' "$env_dump" | grep -q "^${name}="; then
      echo "MISSING_ENV $name"
      missing=$((missing + 1))
    fi
  done
  if [ "$missing" -eq 0 ]; then
    pass "local-auth legacy runtime service credential env vars are present"
  elif docker exec "$container" sh -lc 'test -s /var/lib/cattle/authConfigFile.txt && ps -ef | grep -q "[r]ancher-auth-service" && ps -ef | grep -q "[r]ancher-catalog-service"' >/dev/null 2>&1; then
    pass "local-auth file-backed service config and embedded auth/catalog processes are present"
    warn "legacy service credential env vars are absent; current image is using file-backed embedded service config"
  else
    fail "local-auth is enabled but neither legacy service credential env vars nor file-backed embedded service config are complete"
  fi
else
  warn "api.security.enabled is not true; this is acceptable only for internal lab or behind a tested external auth layer"
fi


read_credential_file_value() {
  local key=$1
  local file=$2
  awk -v wanted="$key" '
    BEGIN { wanted = tolower(wanted) }
    /^[[:space:]]*($|#)/ { next }
    {
      line = $0
      sub(/\r$/, "", line)
      eq = index(line, "=")
      colon = index(line, ":")
      sep = eq
      if (sep == 0 || (colon > 0 && colon < sep)) {
        sep = colon
      }
      if (sep == 0) {
        next
      }
      key = substr(line, 1, sep - 1)
      value = substr(line, sep + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (tolower(key) == wanted) {
        found = value
      }
    }
    END {
      if (found != "") {
        print found
      }
    }
  ' "$file"
}

local_auth_username=${RC16_LOCAL_AUTH_USERNAME:-}
local_auth_password=${RC16_LOCAL_AUTH_PASSWORD:-}
local_auth_credential_file=${RC16_LOCAL_AUTH_CREDENTIAL_FILE:-}
rancher_url=${RC16_RANCHER_URL:-http://127.0.0.1:8080}
rancher_url=${rancher_url%/}
curl_connect_timeout="${RC16_DB_SANITY_CONNECT_TIMEOUT:-5}"
curl_max_time="${RC16_DB_SANITY_MAX_TIME:-20}"

sanity_curl() {
  curl -sS --connect-timeout "$curl_connect_timeout" --max-time "$curl_max_time" "$@"
}

if [ -n "$local_auth_credential_file" ]; then
  if [ -r "$local_auth_credential_file" ]; then
    [ -n "$local_auth_username" ] || local_auth_username=$(read_credential_file_value username "$local_auth_credential_file")
    [ -n "$local_auth_password" ] || local_auth_password=$(read_credential_file_value password "$local_auth_credential_file")
  else
    fail "RC16_LOCAL_AUTH_CREDENTIAL_FILE is not readable"
  fi
fi

if [ "$security_enabled" = true ] && [ "$auth_provider" = localAuthConfig ]; then
  if [ -n "$local_auth_username" ] && [ -n "$local_auth_password" ]; then
    auth_tmp=$(mktemp)
    chmod 600 "$auth_tmp"
    trap 'rm -f "${auth_tmp:-}"' EXIT
    for token_path in /v1/token /v2-beta/token; do
      http_code=$(sanity_curl -o "$auth_tmp" -w '%{http_code}' \
        -X POST "${rancher_url}${token_path}" \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode "code=${local_auth_username}:${local_auth_password}" || true)
      if [ "$http_code" = 201 ] && python3 - "$auth_tmp" <<'PYAUTH'
import json
import sys
with open(sys.argv[1], encoding='utf-8') as handle:
    body = json.load(handle)
if body.get('type') != 'token' or not body.get('jwt'):
    raise SystemExit(1)
PYAUTH
      then
        pass "local-auth token smoke passed for ${token_path}"
      else
        fail "local-auth token smoke failed for ${token_path}: http ${http_code}"
      fi
      : > "$auth_tmp"
    done
  else
    warn "local-auth token smoke skipped; set RC16_LOCAL_AUTH_CREDENTIAL_FILE or RC16_LOCAL_AUTH_USERNAME/RC16_LOCAL_AUTH_PASSWORD"
  fi
fi

printf 'warning_count=%s\n' "$warnings"
printf 'failure_count=%s\n' "$failures"
if [ "$failures" -ne 0 ]; then
  exit 1
fi

#!/usr/bin/env bash
set -euo pipefail

# Enable the legacy platform local auth in a repeatable way while preserving legacy
# agent compatibility. The script always takes a DB backup first, injects the
# embedded-service API key environment variables required by auth-enabled
# PastureStack Server, and rolls back on validation failure by default.

container=${RC16_RANCHER_CONTAINER:-pasturestack-server}
base_url=${RANCHER_URL:-http://127.0.0.1:8080}
project_id=${RC16_PROJECT_ID:-1a5}
backup_root=${RC16_BACKUP_ROOT:-/home/ubuntu/rc16-work/backups}
admin_file=${RC16_LOCAL_ADMIN_CREDENTIAL_FILE:-}
service_file=${RC16_INTERNAL_SERVICE_KEY_FILE:-}
rollback_on_failure=${RC16_ROLLBACK_ON_FAILURE:-1}
curl_timeout=${RC16_CURL_TIMEOUT:-15}
curl_connect_timeout=${RC16_CURL_CONNECT_TIMEOUT:-5}
host_wait_seconds=${RC16_HOST_WAIT_SECONDS:-240}
ping_wait_seconds=${RC16_WAIT_PING_SECONDS:-240}
skip_local_auth_config=${RC16_SKIP_LOCAL_AUTH_CONFIG:-0}
keep_auth_evidence=${RC16_KEEP_AUTH_EVIDENCE:-0}

ts=$(date +%Y%m%d%H%M%S)
state_dir=${RC16_STATE_DIR:-$backup_root/local-auth-$ts}
db_backup=$state_dir/mysql-all-databases.sql.gz
inspect_backup=$state_dir/${container}.inspect.json
env_file=$state_dir/${container}.env
create_script=$state_dir/docker-create-${container}.sh
token_file=$state_dir/local-admin-jwt.txt
payload=""
token_payload=""
token_response=""
old_container=""
recreated=0
rollback_ready=0

log() {
  printf 'RC16_AUTH %s\n' "$*"
}

die() {
  printf 'RC16_AUTH_FAIL %s\n' "$*" >&2
  if [ "${rollback_ready:-0}" = 1 ]; then
    trap - ERR
    rollback "$*"
  fi
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

read_kv() {
  local file=$1
  local key=$2
  awk -F= -v k="$key" '$1 == k { sub(/^[^=]*=/, ""); print; exit }' "$file"
}

json_escape_file() {
  local out=$1
  ADMIN_USERNAME=$admin_username ADMIN_PASSWORD=$admin_password python3 - "$out" <<'PY'
import json
import os
import sys

payload = {
    "enabled": True,
    "username": os.environ["ADMIN_USERNAME"],
    "password": os.environ["ADMIN_PASSWORD"],
}
with open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump(payload, f, separators=(",", ":"))
PY
  chmod 600 "$out"
}

form_token_file() {
  local out=$1
  ADMIN_USERNAME=$admin_username ADMIN_PASSWORD=$admin_password python3 - "$out" <<'PY'
import os
import sys
import urllib.parse

code = os.environ["ADMIN_USERNAME"] + ":" + os.environ["ADMIN_PASSWORD"]
with open(sys.argv[1], "w", encoding="utf-8") as f:
    f.write(urllib.parse.urlencode({"code": code}))
PY
  chmod 600 "$out"
}

auth_curl() {
  curl -fsS --connect-timeout "$curl_connect_timeout" --max-time "$curl_timeout" "$@"
}

wait_ping() {
  local url=${1:-$base_url}
  local seconds=${2:-$ping_wait_seconds}
  local end=$((SECONDS + seconds))
  local body
  while [ "$SECONDS" -lt "$end" ]; do
    body=$(auth_curl "$url/ping" 2>/dev/null || true)
    if [ "$body" = pong ]; then
      return 0
    fi
    sleep 3
  done
  return 1
}

wait_mysql() {
  local end=$((SECONDS + 180))
  while [ "$SECONDS" -lt "$end" ]; do
    if docker exec "$container" mysqladmin ping >/dev/null 2>&1; then
      return 0
    fi
    sleep 3
  done
  return 1
}

restore_db_backup() {
  [ -f "$db_backup" ] || return 0
  log "restoring DB backup from $db_backup"
  wait_mysql || return 1
  gzip -dc "$db_backup" | docker exec -i "$container" mysql
}

disable_auth_settings_best_effort() {
  docker exec -i "$container" mysql cattle <<'SQL' >/dev/null 2>&1 || true
DELETE s1 FROM setting s1
JOIN setting s2 ON s1.name = s2.name AND s1.id < s2.id
WHERE s1.name IN ('account.by.key.credential.types','api.security.enabled','api.auth.provider.configured','api.auth.local.access.mode');
UPDATE setting SET value='agentApiKey,apiKey,usernamePassword' WHERE name='account.by.key.credential.types';
INSERT INTO setting (name, value)
SELECT 'account.by.key.credential.types', 'agentApiKey,apiKey,usernamePassword'
WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='account.by.key.credential.types');
UPDATE setting SET value='false' WHERE name='api.security.enabled';
INSERT INTO setting (name, value)
SELECT 'api.security.enabled', 'false'
WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='api.security.enabled');
UPDATE setting SET value='none' WHERE name='api.auth.provider.configured';
INSERT INTO setting (name, value)
SELECT 'api.auth.provider.configured', 'none'
WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='api.auth.provider.configured');
UPDATE setting SET value='unrestricted' WHERE name='api.auth.local.access.mode';
INSERT INTO setting (name, value)
SELECT 'api.auth.local.access.mode', 'unrestricted'
WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='api.auth.local.access.mode');
SQL
}

rollback() {
  local reason=${1:-unknown failure}
  if [ "$rollback_on_failure" != 1 ]; then
    log "rollback disabled; leaving failed state for inspection: $reason"
    return 0
  fi

  set +e
  log "rollback started: $reason"
  mkdir -p "$state_dir"
  docker logs --since 20m "$container" >"$state_dir/failed-${container}.log" 2>&1 || true
  docker inspect "$container" >"$state_dir/failed-${container}.inspect.json" 2>/dev/null || true
  docker ps -a --format '{{.Names}} {{.Image}} {{.Status}}' >"$state_dir/docker-ps-at-failure.txt" 2>/dev/null || true

  if [ "$recreated" = 1 ]; then
    docker rm -f "$container" >/dev/null 2>&1 || true
    if [ -n "$old_container" ] && docker inspect "$old_container" >/dev/null 2>&1; then
      docker rename "$old_container" "$container" >/dev/null 2>&1 || true
      docker start "$container" >/dev/null 2>&1 || true
    fi
  else
    docker restart "$container" >/dev/null 2>&1 || true
  fi
  wait_ping "$base_url" >/dev/null 2>&1 || true
  restore_db_backup >/dev/null 2>&1 || disable_auth_settings_best_effort
  docker restart "$container" >/dev/null 2>&1 || true
  wait_ping "$base_url" >/dev/null 2>&1 || true
  log "rollback finished; inspect $state_dir for evidence"
}

on_error() {
  local rc=$?
  local line=$1
  if [ "${rollback_ready:-0}" = 1 ]; then
    rollback "line $line exit $rc"
  fi
  exit "$rc"
}

trap 'on_error $LINENO' ERR

for cmd in docker curl gzip awk python3; do
  need_cmd "$cmd"
done

case "$base_url" in
  http://127.0.0.1:*|http://localhost:*|https://*) ;;
  http://*) log "warning: configuring over HTTP; use only from a trusted local/admin network" ;;
  *) die "RANCHER_URL must start with http:// or https://" ;;
esac

[ -n "$admin_file" ] && [ -f "$admin_file" ] || [ -n "${RC16_LOCAL_ADMIN_USERNAME:-}" ] || die "set RC16_LOCAL_ADMIN_CREDENTIAL_FILE or RC16_LOCAL_ADMIN_USERNAME/RC16_LOCAL_ADMIN_PASSWORD"
[ -n "$service_file" ] && [ -f "$service_file" ] || [ -n "${RC16_INTERNAL_SERVICE_ACCESS_KEY:-}" ] || [ -n "${CATTLE_ACCESS_KEY:-}" ] || die "set RC16_INTERNAL_SERVICE_KEY_FILE or RC16_INTERNAL_SERVICE_ACCESS_KEY/RC16_INTERNAL_SERVICE_SECRET_KEY"

admin_username=${RC16_LOCAL_ADMIN_USERNAME:-}
admin_password=${RC16_LOCAL_ADMIN_PASSWORD:-}
if [ -n "$admin_file" ]; then
  admin_username=${admin_username:-$(read_kv "$admin_file" username)}
  admin_password=${admin_password:-$(read_kv "$admin_file" password)}
fi
[ -n "$admin_username" ] || die "missing local admin username"
[ -n "$admin_password" ] || die "missing local admin password"

service_access_key=${RC16_INTERNAL_SERVICE_ACCESS_KEY:-${CATTLE_ACCESS_KEY:-}}
service_secret_key=${RC16_INTERNAL_SERVICE_SECRET_KEY:-${CATTLE_SECRET_KEY:-}}
if [ -n "$service_file" ]; then
  service_access_key=${service_access_key:-$(read_kv "$service_file" access_key)}
  service_secret_key=${service_secret_key:-$(read_kv "$service_file" secret_key)}
fi
[ -n "$service_access_key" ] || die "missing internal service access key"
[ -n "$service_secret_key" ] || die "missing internal service secret key"

docker inspect "$container" >/dev/null 2>&1 || die "container not found: $container"
mkdir -p "$state_dir"
chmod 700 "$state_dir"

log "state_dir=$state_dir"
log "taking DB backup"
docker inspect "$container" >"$inspect_backup"
chmod 600 "$inspect_backup"
docker exec "$container" sh -lc 'mysqldump --single-transaction --quick --routines --events --all-databases' | gzip -9 >"$db_backup"
chmod 600 "$db_backup"
rollback_ready=1
wait_ping "$base_url" || die "PastureStack ping failed before auth migration"
wait_mysql || die "PastureStack database is not ready before auth migration"

log "normalizing critical auth settings before enablement"
docker exec -i "$container" mysql cattle <<'SQL'
DELETE s1 FROM setting s1
JOIN setting s2 ON s1.name = s2.name AND s1.id < s2.id
WHERE s1.name IN ('account.by.key.credential.types','api.security.enabled','api.auth.provider.configured','api.auth.local.access.mode');
UPDATE setting SET value='agentApiKey,apiKey,usernamePassword' WHERE name='account.by.key.credential.types';
INSERT INTO setting (name, value)
SELECT 'account.by.key.credential.types', 'agentApiKey,apiKey,usernamePassword'
WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='account.by.key.credential.types');
UPDATE setting SET value='unrestricted' WHERE name='api.auth.local.access.mode';
INSERT INTO setting (name, value)
SELECT 'api.auth.local.access.mode', 'unrestricted'
WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='api.auth.local.access.mode');
SQL

missing_env=0
for name in CATTLE_ACCESS_KEY CATTLE_SECRET_KEY CATALOG_SERVICE_CATTLE_ACCESS_KEY CATALOG_SERVICE_CATTLE_SECRET_KEY CATTLE_URL CATALOG_SERVICE_CATTLE_URL RANCHER_ACCESS_KEY RANCHER_SECRET_KEY; do
  if ! docker inspect "$container" --format '{{range .Config.Env}}{{println .}}{{end}}' | grep -q "^${name}="; then
    missing_env=1
  fi
done

if [ "$missing_env" = 1 ]; then
  log "recreating server container with embedded-service credentials"
  CATTLE_ACCESS_KEY=$service_access_key \
  CATTLE_SECRET_KEY=$service_secret_key \
  CATALOG_SERVICE_CATTLE_ACCESS_KEY=$service_access_key \
  CATALOG_SERVICE_CATTLE_SECRET_KEY=$service_secret_key \
  CATTLE_URL=${RC16_INTERNAL_CATTLE_URL:-http://127.0.0.1:8080/v1} \
  CATALOG_SERVICE_CATTLE_URL=${RC16_INTERNAL_CATTLE_URL:-http://127.0.0.1:8080/v1} \
  RANCHER_ACCESS_KEY=$service_access_key \
  RANCHER_SECRET_KEY=$service_secret_key \
  python3 - "$inspect_backup" "$env_file" <<'PY'
import json
import os
import sys

inspect_path, env_path = sys.argv[1:3]
info = json.load(open(inspect_path, encoding="utf-8"))[0]
env = {}
for item in info.get("Config", {}).get("Env") or []:
    if "=" in item:
        key, value = item.split("=", 1)
        env[key] = value
for key in (
    "CATTLE_ACCESS_KEY",
    "CATTLE_SECRET_KEY",
    "CATALOG_SERVICE_CATTLE_ACCESS_KEY",
    "CATALOG_SERVICE_CATTLE_SECRET_KEY",
    "CATTLE_URL",
    "CATALOG_SERVICE_CATTLE_URL",
    "RANCHER_ACCESS_KEY",
    "RANCHER_SECRET_KEY",
):
    env[key] = os.environ[key]
with open(env_path, "w", encoding="utf-8") as f:
    for key in sorted(env):
        f.write(f"{key}={env[key]}\n")
PY
  chmod 600 "$env_file"

  python3 - "$inspect_backup" "$container" "$env_file" >"$create_script" <<'PY'
import json
import shlex
import sys

inspect_path, container_name, env_file = sys.argv[1:4]
info = json.load(open(inspect_path, encoding="utf-8"))[0]
config = info.get("Config", {})
host_config = info.get("HostConfig", {})

args = ["docker", "create", "--name", container_name, "--env-file", env_file]
restart = host_config.get("RestartPolicy") or {}
restart_name = restart.get("Name") or ""
if restart_name and restart_name != "no":
    value = restart_name
    maximum = restart.get("MaximumRetryCount") or 0
    if restart_name == "on-failure" and maximum:
        value = f"{value}:{maximum}"
    args += ["--restart", value]
network_mode = host_config.get("NetworkMode") or ""
if network_mode and network_mode != "default":
    args += ["--network", network_mode]
if host_config.get("Privileged"):
    args.append("--privileged")
for cap in host_config.get("CapAdd") or []:
    args += ["--cap-add", cap]
for bind in host_config.get("Binds") or []:
    args += ["-v", bind]
for port, bindings in sorted((host_config.get("PortBindings") or {}).items()):
    for binding in bindings or []:
        host_ip = binding.get("HostIp") or ""
        host_port = binding.get("HostPort") or ""
        if host_port:
            published = f"{host_port}:{port}"
            if host_ip:
                published = f"{host_ip}:{published}"
            args += ["-p", published]
labels = config.get("Labels") or {}
for key in sorted(labels):
    args += ["--label", f"{key}={labels[key]}"]
if config.get("User"):
    args += ["--user", config["User"]]
if config.get("WorkingDir"):
    args += ["--workdir", config["WorkingDir"]]
image = config.get("Image") or info.get("Image")
if not image:
    raise SystemExit("cannot determine image from docker inspect")
args.append(image)
args.extend(config.get("Cmd") or [])
print("#!/usr/bin/env bash")
print("set -euo pipefail")
print(" ".join(shlex.quote(x) for x in args))
PY
  chmod 700 "$create_script"
  old_container=${container}-pre-local-auth-$ts
  docker stop "$container" >/dev/null
  docker rename "$container" "$old_container"
  bash "$create_script" >/dev/null
  rm -f "$env_file"
  docker start "$container" >/dev/null
  recreated=1
  wait_ping "$base_url" || die "PastureStack ping failed after credentialized recreate"
  wait_mysql || die "PastureStack database failed after credentialized recreate"
else
  log "embedded-service credentials already present in container env"
fi

if [ "$skip_local_auth_config" != 1 ]; then
  payload=$state_dir/local-auth-config.json
  json_escape_file "$payload"
  log "enabling localAuthConfig through the compatible API"
  auth_curl \
    -H 'Content-Type: application/json' \
    --data-binary "@$payload" \
    "$base_url/v1/localauthconfigs" >/dev/null
fi

log "forcing expected auth settings after API enablement"
docker exec -i "$container" mysql cattle <<'SQL'
DELETE s1 FROM setting s1
JOIN setting s2 ON s1.name = s2.name AND s1.id < s2.id
WHERE s1.name IN ('account.by.key.credential.types','api.security.enabled','api.auth.provider.configured','api.auth.local.access.mode');
UPDATE setting SET value='agentApiKey,apiKey,usernamePassword' WHERE name='account.by.key.credential.types';
INSERT INTO setting (name, value)
SELECT 'account.by.key.credential.types', 'agentApiKey,apiKey,usernamePassword'
WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='account.by.key.credential.types');
UPDATE setting SET value='true' WHERE name='api.security.enabled';
INSERT INTO setting (name, value)
SELECT 'api.security.enabled', 'true'
WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='api.security.enabled');
UPDATE setting SET value='localAuthConfig' WHERE name='api.auth.provider.configured';
INSERT INTO setting (name, value)
SELECT 'api.auth.provider.configured', 'localAuthConfig'
WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='api.auth.provider.configured');
UPDATE setting SET value='unrestricted' WHERE name='api.auth.local.access.mode';
INSERT INTO setting (name, value)
SELECT 'api.auth.local.access.mode', 'unrestricted'
WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='api.auth.local.access.mode');
SQL

docker restart "$container" >/dev/null
wait_ping "$base_url" || die "PastureStack ping failed after auth restart"
wait_mysql || die "PastureStack database failed after auth restart"

log "requesting local auth token without printing it"
token_payload=$state_dir/token-request.form
form_token_file "$token_payload"
token_response=$state_dir/token-response.json
auth_curl \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-binary "@$token_payload" \
  "$base_url/v1/token" >"$token_response"
chmod 600 "$token_response"
python3 - "$token_response" "$token_file" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
jwt = data.get("jwt")
if not jwt:
    raise SystemExit("token response did not contain jwt")
with open(sys.argv[2], "w", encoding="utf-8") as f:
    f.write(jwt + "\n")
PY
chmod 600 "$token_file"
rm -f "$token_payload"

log "running DB sanity check"
RC16_RANCHER_CONTAINER=$container ./scripts/database-sanity-check.sh

log "running anonymous public-surface auth boundary check"
RC16_ALLOW_HTTP=1 RANCHER_URL=$base_url ./scripts/audit-live-public-surface.sh

log "waiting for hosts to stay active under auth"
end=$((SECONDS + host_wait_seconds))
while [ "$SECONDS" -lt "$end" ]; do
  hosts_json=$state_dir/hosts.json
  auth_curl \
    -H "Authorization: Bearer $(cat "$token_file")" \
    -H "X-API-Project-Id: $project_id" \
    "$base_url/v2-beta/projects/$project_id/hosts" >"$hosts_json"
  if python3 - "$hosts_json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8")).get("data", [])
if not data:
    raise SystemExit(1)
bad = []
for host in data:
    state = host.get("state")
    agent_state = host.get("agentState")
    if state != "active" or agent_state != "active":
        bad.append((host.get("id"), host.get("hostname"), state, agent_state))
if bad:
    raise SystemExit(1)
PY
  then
    break
  fi
  sleep 5
done

python3 - "$state_dir/hosts.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8")).get("data", [])
bad = []
for host in data:
    state = host.get("state")
    agent_state = host.get("agentState")
    if state != "active" or agent_state != "active":
        bad.append(f"{host.get('id')} {host.get('hostname')} {state}/{agent_state}")
if bad:
    raise SystemExit("hosts not active under auth: " + "; ".join(bad))
print("RC16_AUTH_HOSTS_ACTIVE")
for host in data:
    print(host.get("id"), host.get("hostname"), host.get("state"), host.get("agentState"))
PY

if docker logs --since 5m "$container" 2>&1 \
  | grep -Ei '(HTTP/[0-9.]+[[:space:]]+401|status[ =:]*401|code[ =:]*401|401[[:space:]]+Unauthorized|Unauthorized)' \
  | grep -Ei '(agent|publish|websocket|subscribe|/v2-beta/publish)' >/dev/null; then
  die "recent server logs contain explicit agent publish 401 markers"
fi

log "local auth migration gate passed"
if [ "$recreated" = 1 ] && [ -n "$old_container" ] && docker inspect "$old_container" >/dev/null 2>&1; then
  log "removing pre-auth rollback container after successful DB/auth validation: $old_container"
  docker rm "$old_container" >/dev/null || true
fi

if [ "$keep_auth_evidence" = 1 ]; then
  log "token_file=$token_file"
else
  rm -f "${payload:-}" "${token_payload:-}" "${token_response:-}" "$token_file"
  log "sensitive auth payload/token files removed after validation"
fi
log "db_backup=$db_backup"
trap - ERR

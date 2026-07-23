#!/usr/bin/env bash
set -Eeuo pipefail

# Restore an external-DB backup into an isolated temporary MariaDB service and
# boot the maintained non-root PastureStack Server external-DB image against it.
#
# This is a destructive test only for the temporary containers and network it
# creates. It never connects to the live embedded DB container.

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

backup_dir="${BACKUP_DIR:-}"
server_image="${SERVER_IMAGE:-ghcr.io/pasturestack/server-externaldb:v1.6.271}"
client_image="${CLIENT_IMAGE:-mariadb:11.8}"
db_image="${DB_IMAGE:-mariadb:11.8}"
http_port="${HTTP_PORT:-}"
timeout_seconds="${SERVER_READY_TIMEOUT:-180}"
keep_containers="${KEEP_CONTAINERS:-false}"
curl_connect_timeout="${RC16_RESTORED_SMOKE_CONNECT_TIMEOUT:-5}"
curl_max_time="${RC16_RESTORED_SMOKE_MAX_TIME:-20}"
native_mariadb_url="${RC16_RESTORED_SMOKE_NATIVE_MARIADB_URL:-false}"

usage() {
    cat <<'EOF_USAGE'
Usage:
  externaldb-restored-server-smoke.sh --backup-dir DIR [options]

Options:
  --backup-dir DIR       Backup directory created by externaldb-backup-restore.sh.
  --server-image IMAGE   External-DB PastureStack Server image. Default ghcr.io/pasturestack/server-externaldb:v1.6.271.
  --client-image IMAGE   MariaDB client image. Default mariadb:11.8.
  --db-image IMAGE       Temporary MariaDB server image. Default mariadb:11.8.
  --http-port PORT       Host port for the temporary PastureStack Server. Default: first free port from 18094.
  --timeout SECONDS      Server readiness timeout. Default 180.
  --keep-containers      Keep temporary containers and network for debugging.
  --native-mariadb-url   Override db.cattle.mysql.url with jdbc:mariadb://
                         and require server logs to show the native URL.

Environment equivalents:
  BACKUP_DIR, SERVER_IMAGE, CLIENT_IMAGE, DB_IMAGE, HTTP_PORT, SERVER_READY_TIMEOUT, KEEP_CONTAINERS,
  RC16_RESTORED_SMOKE_NATIVE_MARIADB_URL
EOF_USAGE
}

die() {
    echo "ERROR $*" >&2
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        --backup-dir) [ $# -ge 2 ] || die "--backup-dir requires a value"; backup_dir="$2"; shift ;;
        --server-image) [ $# -ge 2 ] || die "--server-image requires a value"; server_image="$2"; shift ;;
        --client-image) [ $# -ge 2 ] || die "--client-image requires a value"; client_image="$2"; shift ;;
        --db-image) [ $# -ge 2 ] || die "--db-image requires a value"; db_image="$2"; shift ;;
        --http-port) [ $# -ge 2 ] || die "--http-port requires a value"; http_port="$2"; shift ;;
        --timeout) [ $# -ge 2 ] || die "--timeout requires a value"; timeout_seconds="$2"; shift ;;
        --keep-containers) keep_containers=true ;;
        --native-mariadb-url) native_mariadb_url=true ;;
        --help|-h) usage; exit 0 ;;
        *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "$1 is required"
}

find_free_port() {
    local port
    for port in $(seq 18094 18150); do
        if ! ss -ltn | awk '{print $4}' | grep -Eq "[:.]${port}$"; then
            printf '%s\n' "$port"
            return
        fi
    done
    die "no free port found in 18094-18150"
}

require_command docker
require_command curl
require_command openssl
require_command ss

smoke_curl() {
    curl -sS --connect-timeout "$curl_connect_timeout" --max-time "$curl_max_time" "$@"
}

[ -n "$backup_dir" ] || die "--backup-dir is required"
[ -d "$backup_dir" ] || die "backup dir not found: $backup_dir"
if [ -f "$backup_dir/cattle.sql.gz" ]; then
    [ -f "$backup_dir/cattle.sql.gz.sha256" ] || die "backup checksum not found: $backup_dir/cattle.sql.gz.sha256"
elif [ -f "$backup_dir/cattle.sql" ]; then
    [ -f "$backup_dir/cattle.sql.sha256" ] || die "backup checksum not found: $backup_dir/cattle.sql.sha256"
else
    die "backup SQL not found: $backup_dir/cattle.sql.gz or $backup_dir/cattle.sql"
fi

if [ -z "$http_port" ]; then
    http_port=$(find_free_port)
fi

case "$http_port" in
    *[!0-9]*|"") die "invalid http port: $http_port" ;;
esac

ts=$(date -u +%Y%m%dT%H%M%SZ)
network="pasturestack-extdb-smoke-${ts}"
db_container="pasturestack-extdb-smoke-db-${ts}"
server_container="pasturestack-extdb-smoke-server-${ts}"
root_pass=$(openssl rand -hex 24)
db_pass=$(openssl rand -hex 24)
summary_file="${backup_dir%/}/restored-server-smoke-${ts}.summary"

cleanup() {
    if [ "$keep_containers" = "true" ]; then
        echo "KEEP_CONTAINERS=true; temporary resources retained: network=${network} db=${db_container} server=${server_container}" >&2
        return
    fi
    set +e
    docker rm -f "$server_container" >/dev/null 2>&1 || true
    docker rm -f "$db_container" >/dev/null 2>&1 || true
    docker network rm "$network" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "RC16 external DB restored-server smoke ${ts}"
echo "backup_dir=${backup_dir}"
echo "server_image=${server_image}"
echo "client_image=${client_image}"
echo "db_image=${db_image}"
echo "http_port=${http_port}"
echo "native_mariadb_url=${native_mariadb_url}"

docker image inspect "$client_image" >/dev/null 2>&1 || docker pull "$client_image" >/dev/null
docker image inspect "$db_image" >/dev/null 2>&1 || docker pull "$db_image" >/dev/null
docker image inspect "$server_image" >/dev/null 2>&1 || docker pull "$server_image" >/dev/null

docker network create "$network" >/dev/null

docker run -d --name "$db_container" --network "$network" \
    -e MARIADB_ROOT_PASSWORD="$root_pass" \
    -e MARIADB_DATABASE=cattle \
    -e MARIADB_USER=cattle \
    -e MARIADB_PASSWORD="$db_pass" \
    "$db_image" >/dev/null

for i in $(seq 1 90); do
    if docker exec -e MYSQL_PWD="$root_pass" "$db_container" mariadb-admin --protocol=tcp -h127.0.0.1 -P3306 -uroot ping --silent >/dev/null 2>&1; then
        echo "temp_db_ready_after=${i}s"
        break
    fi
    sleep 1
    [ "$i" != 90 ] || die "temporary MariaDB did not become ready"
done

DB_HOST="$db_container" \
DB_PORT=3306 \
DB_USER=cattle \
DB_PASS="$db_pass" \
ADMIN_DB_USER=root \
ADMIN_DB_PASS="$root_pass" \
DB_NAME=pasturestack_source_placeholder \
DB_USER_HOST='%' \
CLIENT_IMAGE="$client_image" \
DOCKER_NETWORK="$network" \
BACKUP_DIR="$backup_dir" \
scripts/externaldb-backup-restore.sh restore --yes --restore-db-name cattle

restored_tables=$(docker exec -e MYSQL_PWD="$db_pass" "$db_container" mariadb --protocol=tcp -h127.0.0.1 -P3306 -ucattle \
    --batch --skip-column-names -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='cattle';")
echo "restored_tables=${restored_tables}"
[ "$restored_tables" != "0" ] || die "restore produced zero tables"

server_env_args=(
    -e CATTLE_DB_CATTLE_DATABASE=mysql \
    -e CATTLE_DB_CATTLE_MYSQL_HOST="$db_container" \
    -e CATTLE_DB_CATTLE_MYSQL_PORT=3306 \
    -e CATTLE_DB_CATTLE_USERNAME=cattle \
    -e CATTLE_DB_CATTLE_PASSWORD="$db_pass" \
    -e CATTLE_DB_CATTLE_MYSQL_NAME=cattle
)

if [ "$native_mariadb_url" = "true" ]; then
    native_jdbc_url="jdbc:mariadb://${db_container}:3306/cattle?useUnicode=true&characterEncoding=UTF-8&characterSetResults=UTF-8&prepStmtCacheSize=517&cachePrepStmts=true&prepStmtCacheSqlLimit=4096"
    server_env_args+=(
        -e "CATTLE_DB_CATTLE_MYSQL_URL=${native_jdbc_url}"
        -e "CATTLE_DB_LIQUIBASE_MYSQL_URL=${native_jdbc_url}"
    )
    echo "server_jdbc_url_expected=${native_jdbc_url}"
fi

docker run -d --name "$server_container" --network "$network" -p "127.0.0.1:${http_port}:8080" \
    "${server_env_args[@]}" \
    "$server_image" >/dev/null

ready_after=""
for i in $(seq 1 "$timeout_seconds"); do
    body=$(mktemp)
    code=$(smoke_curl -f -o "$body" -w '%{http_code}' "http://127.0.0.1:${http_port}/ping" 2>/dev/null || true)
    if [ "$code" = "200" ] && grep -q '^pong$' "$body"; then
        ready_after="${i}s"
        rm -f "$body"
        echo "server_ping_ready_after=${ready_after}"
        break
    fi
    rm -f "$body"
    if [ $((i % 30)) = 0 ]; then
        echo "waiting_server_ping=${i}s http=${code:-000}"
        docker logs "$server_container" 2>&1 | tail -30 | sed 's/^/server_log_tail: /' || true
    fi
    sleep 1
done

[ -n "$ready_after" ] || {
    docker logs "$server_container" 2>&1 | tail -120 >&2 || true
    die "server did not pass /ping within ${timeout_seconds}s"
}

v2_code=$(smoke_curl -o /dev/null -w '%{http_code}' "http://127.0.0.1:${http_port}/v2-beta" || true)
case "$v2_code" in
    200|401|403) ;;
    *) die "unexpected /v2-beta HTTP status: $v2_code" ;;
esac

server_user=$(docker inspect "$server_container" --format '{{.Config.User}}')
server_status=$(docker inspect "$server_container" --format '{{.State.Status}}')
[ "$server_user" = "10001:10001" ] || die "external DB server is not configured as non-root: $server_user"
[ "$server_status" = "running" ] || die "server status is not running: $server_status"

server_logs=$(docker logs "$server_container" 2>&1 || true)
if [ "$native_mariadb_url" = "true" ]; then
    native_pool_marker="property [url=jdbc:mariadb://${db_container}:3306/cattle"
    if ! grep -Fq "$native_pool_marker" <<< "$server_logs"; then
        die "native MariaDB JDBC pool URL was not observed in server logs"
    fi
    if grep -Eq 'permitMysqlScheme|useMysqlMetadata=true' <<< "$server_logs"; then
        die "MySQL compatibility JDBC option was observed in native MariaDB URL smoke"
    fi
    echo "server_jdbc_url_scheme=mariadb"
    echo "server_jdbc_native_url_smoke=pass"
fi

{
    printf 'created_at=%s\n' "$(date -Is)"
    printf 'backup_dir=%s\n' "$backup_dir"
    printf 'server_image=%s\n' "$server_image"
    printf 'db_image=%s\n' "$db_image"
    printf 'client_image=%s\n' "$client_image"
    printf 'restored_tables=%s\n' "$restored_tables"
    printf 'server_ping_ready_after=%s\n' "$ready_after"
    printf 'v2_beta_http=%s\n' "$v2_code"
    printf 'server_user=%s\n' "$server_user"
    printf 'server_status=%s\n' "$server_status"
    printf 'native_mariadb_url=%s\n' "$native_mariadb_url"
    if [ "$native_mariadb_url" = "true" ]; then
        printf 'server_jdbc_url_scheme=mariadb\n'
        printf 'server_jdbc_native_url_smoke=pass\n'
    fi
} > "$summary_file"
chmod 600 "$summary_file"

echo "v2_beta_http=${v2_code}"
echo "server_user=${server_user}"
echo "server_status=${server_status}"
echo "summary_file=${summary_file}"
echo "externaldb_restored_server_smoke=pass"

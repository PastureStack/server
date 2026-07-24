#!/usr/bin/env bash
set -Eeuo pipefail

# External-DB operational backup and restore drill for the maintained the legacy platform
# server path. This intentionally targets TCP external MariaDB and never touches
# embedded server volumes.

ACTION="drill"
if [ $# -gt 0 ] && [[ "$1" != -* ]]; then
    ACTION="$1"
    shift
fi

TS="$(date +%Y%m%d%H%M%S)"
DB_HOST="${DB_HOST:-${CATTLE_DB_CATTLE_MYSQL_HOST:-}}"
DB_PORT="${DB_PORT:-${CATTLE_DB_CATTLE_MYSQL_PORT:-3306}}"
DB_USER="${DB_USER:-${CATTLE_DB_CATTLE_USERNAME:-cattle}}"
DB_PASS="${DB_PASS:-${CATTLE_DB_CATTLE_PASSWORD:-}}"
DB_USER_HOST="${DB_USER_HOST:-%}"
ADMIN_DB_USER="${ADMIN_DB_USER:-${DB_ADMIN_USER:-$DB_USER}}"
ADMIN_DB_PASS="${ADMIN_DB_PASS:-${DB_ADMIN_PASS:-$DB_PASS}}"
DB_NAME="${DB_NAME:-${CATTLE_DB_CATTLE_MYSQL_NAME:-cattle}}"
CLIENT_IMAGE="${CLIENT_IMAGE:-mariadb:11.8}"
DOCKER_NETWORK="${DOCKER_NETWORK:-host}"
BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/pasturestack-externaldb}"
BACKUP_DIR="${BACKUP_DIR:-${BACKUP_ROOT}/pasturestack-externaldb-${TS}}"
VERIFY_DB_NAME="${VERIFY_DB_NAME:-${DB_NAME}_pasturestack_verify_${TS}}"
RESTORE_DB_NAME="${RESTORE_DB_NAME:-}"
WORKDIR="${WORKDIR:-/tmp}"
REQUIRE_CONFIRM="${REQUIRE_CONFIRM:-true}"
FORCE_RESTORE="${FORCE_RESTORE:-false}"
KEEP_VERIFY_DB="${KEEP_VERIFY_DB:-false}"

secret_dir=""
log_file=""

usage() {
    cat <<'EOF_USAGE'
Usage:
  externaldb-backup-restore.sh [action] [options]

Actions:
  preflight   Validate Docker, MariaDB client image, and DB connectivity.
  backup      Create a timestamped gzip SQL backup bundle.
  verify      Verify checksum and restore a backup into a temporary DB.
  restore     Restore a backup into --restore-db-name. Requires --yes.
  drill       backup + verify. Default action.

Options:
  --db-host HOST             External MariaDB host. Also accepts DB_HOST or CATTLE_DB_CATTLE_MYSQL_HOST.
  --db-port PORT             External MariaDB port. Default 3306.
  --db-user USER             DB user. Default cattle.
  --db-pass PASS             DB password. Prefer DB_PASS env over CLI so shell history does not record it.
  --db-user-host HOST        DB user host part for grants during verify/restore. Default %.
  --admin-db-user USER       Admin user for creating/dropping verify or restore DBs. Default db user.
  --admin-db-pass PASS       Admin password. Prefer ADMIN_DB_PASS or DB_ADMIN_PASS env over CLI.
  --db-name NAME             Source DB name. Default cattle.
  --backup-root DIR          Backup root. Default /var/backups/pasturestack-externaldb.
  --backup-dir DIR           Existing or exact backup directory.
  --verify-db-name NAME      Temporary DB name for verify/drill.
  --restore-db-name NAME     Target DB name for restore.
  --docker-network NAME      Docker network for the MariaDB client container. Default host.
  --client-image IMAGE       MariaDB client image. Default mariadb:11.8.
  --yes                      Non-interactive restore.
  --force                    Allow restore into a non-empty target DB.
  --keep-verify-db           Do not drop the verify DB after a successful verify/drill.

Examples:
  # Backup only needs the PastureStack application database user.
  DB_PASS=secret sudo -E scripts/externaldb-backup-restore.sh backup \
    --db-host mariadb.internal --db-user cattle --db-name cattle

  # Drill/verify/restore also need an admin user to create and drop the temporary target DB.
  DB_PASS=secret ADMIN_DB_PASS=admin-secret sudo -E scripts/externaldb-backup-restore.sh drill \
    --db-host mariadb.internal --db-user cattle --admin-db-user root --db-name cattle

  DB_PASS=secret ADMIN_DB_PASS=admin-secret sudo -E scripts/externaldb-backup-restore.sh restore --yes \
    --backup-dir /var/backups/pasturestack-externaldb/pasturestack-externaldb-20260505120000 \
    --db-host mariadb.internal --db-user cattle --admin-db-user root --restore-db-name cattle_restore
EOF_USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --db-host) DB_HOST="$2"; shift ;;
        --db-port) DB_PORT="$2"; shift ;;
        --db-user) DB_USER="$2"; shift ;;
        --db-pass) DB_PASS="$2"; shift ;;
        --db-user-host) DB_USER_HOST="$2"; shift ;;
        --admin-db-user) ADMIN_DB_USER="$2"; shift ;;
        --admin-db-pass) ADMIN_DB_PASS="$2"; shift ;;
        --db-name) DB_NAME="$2"; shift ;;
        --backup-root) BACKUP_ROOT="$2"; BACKUP_DIR="${2%/}/pasturestack-externaldb-${TS}"; shift ;;
        --backup-dir) BACKUP_DIR="$2"; shift ;;
        --verify-db-name) VERIFY_DB_NAME="$2"; shift ;;
        --restore-db-name) RESTORE_DB_NAME="$2"; shift ;;
        --docker-network) DOCKER_NETWORK="$2"; shift ;;
        --client-image) CLIENT_IMAGE="$2"; shift ;;
        --workdir) WORKDIR="$2"; shift ;;
        --yes) REQUIRE_CONFIRM=false ;;
        --force) FORCE_RESTORE=true ;;
        --keep-verify-db) KEEP_VERIFY_DB=true ;;
        --help|-h) usage; exit 0 ;;
        *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

log() {
    local msg="$*"
    printf '%s %s\n' "$(date -Is)" "$msg" | tee -a "$log_file"
}

die() {
    log "ERROR $*"
    exit 1
}

confirm_restore() {
    if [ "$REQUIRE_CONFIRM" = "true" ]; then
        die "restore requires --yes"
    fi
}

validate_ident() {
    local value="$1"
    local label="$2"
    if [[ ! "$value" =~ ^[A-Za-z0-9_]+$ ]]; then
        die "$label must contain only letters, numbers, and underscore: $value"
    fi
}

validate_account_part() {
    local value="$1"
    local label="$2"
    if [[ ! "$value" =~ ^[A-Za-z0-9_.%:-]+$ ]]; then
        die "$label contains unsupported characters: $value"
    fi
}

require_inputs() {
    [ -n "$DB_HOST" ] || die "--db-host or DB_HOST is required"
    [ -n "$DB_PORT" ] || die "--db-port or DB_PORT is required"
    [ -n "$DB_USER" ] || die "--db-user or DB_USER is required"
    validate_ident "$DB_NAME" "db name"
    validate_ident "$VERIFY_DB_NAME" "verify db name"
    validate_account_part "$DB_USER" "db user"
    validate_account_part "$DB_USER_HOST" "db user host"
    if [ -n "$RESTORE_DB_NAME" ]; then
        validate_ident "$RESTORE_DB_NAME" "restore db name"
    fi
}

setup_logging() {
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"
    log_file="${BACKUP_DIR}/${ACTION}.log"
    touch "$log_file"
    chmod 600 "$log_file"
}

cleanup_secret() {
    if [ -n "$secret_dir" ] && [ -d "$secret_dir" ]; then
        rm -rf "$secret_dir"
    fi
}
trap cleanup_secret EXIT

write_client_secret() {
    secret_dir="$(mktemp -d "${WORKDIR%/}/pasturestack-db-client.XXXXXX")"
    chmod 700 "$secret_dir"
    cat > "${secret_dir}/client.cnf" <<EOF_SECRET
[client]
protocol=tcp
host=${DB_HOST}
port=${DB_PORT}
user=${DB_USER}
password=${DB_PASS}
default-character-set=utf8mb4
EOF_SECRET
    cat > "${secret_dir}/admin.cnf" <<EOF_SECRET
[client]
protocol=tcp
host=${DB_HOST}
port=${DB_PORT}
user=${ADMIN_DB_USER}
password=${ADMIN_DB_PASS}
default-character-set=utf8mb4
EOF_SECRET
    chmod 600 "${secret_dir}/client.cnf" "${secret_dir}/admin.cnf"
}

docker_network_args() {
    if [ -n "$DOCKER_NETWORK" ]; then
        printf '%s\n' --network "$DOCKER_NETWORK"
    fi
}

client_base() {
    docker run --rm -i $(docker_network_args) \
        -v "${secret_dir}:/run/pasturestack-db:ro" \
        "$CLIENT_IMAGE" "$@"
}

sql_query() {
    client_base mariadb --defaults-extra-file=/run/pasturestack-db/client.cnf \
        --batch --skip-column-names -e "$1"
}

sql_query_db() {
    local db="$1"
    local sql="$2"
    validate_ident "$db" "db name"
    client_base mariadb --defaults-extra-file=/run/pasturestack-db/client.cnf \
        --batch --skip-column-names "$db" -e "$sql"
}

admin_sql_query() {
    client_base mariadb --defaults-extra-file=/run/pasturestack-db/admin.cnf \
        --batch --skip-column-names -e "$1"
}

sql_account_literal() {
    local value="$1"
    validate_account_part "$value" "account literal"
    printf "'%s'" "$value"
}

create_database() {
    local db="$1"
    validate_ident "$db" "db name"
    admin_sql_query "CREATE DATABASE IF NOT EXISTS \`${db}\` CHARACTER SET utf8mb4"
    admin_sql_query "GRANT ALL PRIVILEGES ON \`${db}\`.* TO $(sql_account_literal "$DB_USER")@$(sql_account_literal "$DB_USER_HOST")"
}

drop_database() {
    local db="$1"
    validate_ident "$db" "db name"
    admin_sql_query "DROP DATABASE IF EXISTS \`${db}\`"
}

table_count() {
    local db="$1"
    validate_ident "$db" "db name"
    sql_query "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${db}'"
}

write_manifest() {
    cat > "${BACKUP_DIR}/manifest.env" <<EOF_MANIFEST
created_at=$(date -Is)
action=${ACTION}
db_host=${DB_HOST}
db_port=${DB_PORT}
db_user=${DB_USER}
db_user_host=${DB_USER_HOST}
admin_db_user=${ADMIN_DB_USER}
db_name=${DB_NAME}
client_image=${CLIENT_IMAGE}
docker_network=${DOCKER_NETWORK}
backup_dir=${BACKUP_DIR}
verify_db_name=${VERIFY_DB_NAME}
EOF_MANIFEST
    chmod 600 "${BACKUP_DIR}/manifest.env"
}

preflight() {
    require_inputs
    setup_logging
    write_client_secret
    command -v docker >/dev/null || die "docker is required"
    command -v gzip >/dev/null || die "gzip is required"
    command -v sha256sum >/dev/null || die "sha256sum is required"
    log "PREFLIGHT_START host=${DB_HOST} port=${DB_PORT} db=${DB_NAME} network=${DOCKER_NETWORK} client=${CLIENT_IMAGE}"
    docker image inspect "$CLIENT_IMAGE" >/dev/null 2>&1 || docker pull "$CLIENT_IMAGE" >/dev/null
    client_base mariadb --version > "${BACKUP_DIR}/mariadb-client-version.txt"
    sql_query "SELECT @@version, @@version_comment, @@character_set_server, @@collation_server" \
        > "${BACKUP_DIR}/db-server-version.txt"
    local count
    count="$(table_count "$DB_NAME")"
    printf 'source_table_count=%s\n' "$count" > "${BACKUP_DIR}/source-summary.txt"
    log "PREFLIGHT_OK source_table_count=${count}"
}

create_backup() {
    require_inputs
    setup_logging
    write_client_secret
    write_manifest
    log "BACKUP_START dir=${BACKUP_DIR} host=${DB_HOST} db=${DB_NAME}"
    [ ! -e "${BACKUP_DIR}/cattle.sql.gz" ] || die "backup file already exists: ${BACKUP_DIR}/cattle.sql.gz"
    [ ! -e "${BACKUP_DIR}/cattle.sql" ] || die "backup file already exists: ${BACKUP_DIR}/cattle.sql"
    docker image inspect "$CLIENT_IMAGE" >/dev/null 2>&1 || docker pull "$CLIENT_IMAGE" >/dev/null
    sql_query "SELECT @@version, @@version_comment, @@character_set_server, @@collation_server" \
        > "${BACKUP_DIR}/db-server-version.txt"
    sql_query "SELECT table_name, table_rows FROM information_schema.tables WHERE table_schema='${DB_NAME}' ORDER BY table_name" \
        > "${BACKUP_DIR}/source-table-rows.tsv"
    client_base mariadb-dump --defaults-extra-file=/run/pasturestack-db/client.cnf \
        --single-transaction --quick --routines --events --triggers --hex-blob \
        --default-character-set=utf8mb4 "$DB_NAME" | gzip -9 > "${BACKUP_DIR}/cattle.sql.gz"
    test -s "${BACKUP_DIR}/cattle.sql.gz" || die "empty cattle.sql.gz"
    gzip -t "${BACKUP_DIR}/cattle.sql.gz"
    sha256sum "${BACKUP_DIR}/cattle.sql.gz" > "${BACKUP_DIR}/cattle.sql.gz.sha256"
    chmod 600 "${BACKUP_DIR}/cattle.sql.gz" "${BACKUP_DIR}/cattle.sql.gz.sha256"
    cat > "${BACKUP_DIR}/README.md" <<EOF_README
# PastureStack External Database Backup

This backup was created by scripts/externaldb-backup-restore.sh.

Restore drill command:

\`\`\`bash
DB_PASS=<secret> ADMIN_DB_PASS=<admin-secret> \\
  scripts/externaldb-backup-restore.sh verify \\
  --backup-dir '${BACKUP_DIR}' \\
  --db-host '${DB_HOST}' \\
  --db-user '${DB_USER}' \\
  --admin-db-user root \\
  --db-name '${DB_NAME}'
\`\`\`

Production restore requires an explicit target DB and --yes:

\`\`\`bash
DB_PASS=<secret> ADMIN_DB_PASS=<admin-secret> \\
  scripts/externaldb-backup-restore.sh restore --yes \\
  --backup-dir '${BACKUP_DIR}' \\
  --db-host '${DB_HOST}' \\
  --db-user '${DB_USER}' \\
  --admin-db-user root \\
  --restore-db-name cattle_restore
\`\`\`
EOF_README
    log "BACKUP_OK file=${BACKUP_DIR}/cattle.sql.gz"
}

verify_checksum() {
    local sql_file
    local checksum_file
    if [ -f "${BACKUP_DIR}/cattle.sql.gz" ]; then
        sql_file="cattle.sql.gz"
    elif [ -f "${BACKUP_DIR}/cattle.sql" ]; then
        sql_file="cattle.sql"
    else
        die "missing ${BACKUP_DIR}/cattle.sql.gz or ${BACKUP_DIR}/cattle.sql"
    fi
    checksum_file="${sql_file}.sha256"
    [ -f "${BACKUP_DIR}/${checksum_file}" ] || die "missing ${BACKUP_DIR}/${checksum_file}"
    (cd "$BACKUP_DIR" && sha256sum -c "$checksum_file") | tee -a "$log_file"
    case "$sql_file" in
        *.gz) gzip -t "${BACKUP_DIR}/${sql_file}" ;;
    esac
}

stream_backup_sql() {
    if [ -f "${BACKUP_DIR}/cattle.sql.gz" ]; then
        gzip -dc "${BACKUP_DIR}/cattle.sql.gz"
    elif [ -f "${BACKUP_DIR}/cattle.sql" ]; then
        cat "${BACKUP_DIR}/cattle.sql"
    else
        die "missing ${BACKUP_DIR}/cattle.sql.gz or ${BACKUP_DIR}/cattle.sql"
    fi
}

restore_backup_to_db() {
    local target_db="$1"
    validate_ident "$target_db" "target db name"
    if [ "$target_db" = "$DB_NAME" ] && [ "$FORCE_RESTORE" != "true" ]; then
        die "refusing to restore into source DB ${DB_NAME} without --force"
    fi
    create_database "$target_db"
    local existing_tables
    existing_tables="$(table_count "$target_db")"
    if [ "$existing_tables" != "0" ] && [ "$FORCE_RESTORE" != "true" ]; then
        die "target DB ${target_db} is not empty (${existing_tables} tables); use --force only after an explicit rollback decision"
    fi
    log "RESTORE_IMPORT_START target_db=${target_db}"
    stream_backup_sql | client_base mariadb --defaults-extra-file=/run/pasturestack-db/client.cnf "$target_db"
    local restored_tables
    restored_tables="$(table_count "$target_db")"
    printf 'target_db=%s\ntable_count=%s\n' "$target_db" "$restored_tables" > "${BACKUP_DIR}/restore-${target_db}.summary"
    sql_query_db "$target_db" "SELECT COUNT(*) FROM DATABASECHANGELOG" > "${BACKUP_DIR}/restore-${target_db}.changelog-count" || true
    sql_query_db "$target_db" "SELECT COUNT(*) FROM setting" > "${BACKUP_DIR}/restore-${target_db}.setting-count" || true
    [ "$restored_tables" != "0" ] || die "restore produced zero tables in ${target_db}"
    log "RESTORE_IMPORT_OK target_db=${target_db} table_count=${restored_tables}"
}

verify_backup() {
    require_inputs
    setup_logging
    write_client_secret
    log "VERIFY_START backup_dir=${BACKUP_DIR} verify_db=${VERIFY_DB_NAME}"
    verify_checksum
    restore_backup_to_db "$VERIFY_DB_NAME"
    if [ "$KEEP_VERIFY_DB" = "true" ]; then
        log "VERIFY_DB_RETAINED db=${VERIFY_DB_NAME}"
    else
        drop_database "$VERIFY_DB_NAME"
        log "VERIFY_DB_DROPPED db=${VERIFY_DB_NAME}"
    fi
    log "VERIFY_OK backup_dir=${BACKUP_DIR}"
}

restore_backup() {
    require_inputs
    [ -n "$RESTORE_DB_NAME" ] || die "restore requires --restore-db-name"
    confirm_restore
    setup_logging
    write_client_secret
    log "RESTORE_START backup_dir=${BACKUP_DIR} target=${RESTORE_DB_NAME}"
    verify_checksum
    restore_backup_to_db "$RESTORE_DB_NAME"
    log "RESTORE_OK target=${RESTORE_DB_NAME}"
}

case "$ACTION" in
    preflight)
        preflight
        ;;
    backup)
        create_backup
        ;;
    verify)
        verify_backup
        ;;
    restore)
        restore_backup
        ;;
    drill)
        create_backup
        verify_backup
        ;;
    *)
        echo "unknown action: $ACTION" >&2
        usage >&2
        exit 2
        ;;
esac

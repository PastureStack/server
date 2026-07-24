#!/usr/bin/env bash
set -Eeuo pipefail

# Operational migration tool for the legacy platform single-container
# embedded DB deployments.
#
# Supported actions:
#   preflight  - validate Docker/server/image/port prerequisites
#   backup     - create a timestamped restorable backup bundle only
#   verify-backup - verify a backup bundle's manifests, checksums, SQL, and tar archives
#   verify-rollback-env - validate rollback.env without executing or sourcing it
#   migrate    - backup, initialize MariaDB 11.8, import dump, switch server
#   rollback   - restore the old server container retained by a migration
#   finalize   - archive and remove a retained rollback checkpoint
#   recycle-ipsec - run the post-cutover ipsec service recycle gate only
#   cleanup    - remove transient migration containers; never removes backups
#
# Do not mount the old MySQL 5.5 /var/lib/mysql directly into any rc16-server image.
# The validated path is dump old DB -> initialize a fresh MariaDB 11.8 datadir
# with the new image -> import SQL dump -> switch container.

ACTION="migrate"
if [ $# -gt 0 ] && [[ "$1" != -* ]]; then
    ACTION="$1"
    shift
fi

default_backup_root() {
    local system_root="/var/backups/pasturestack-server"
    local system_parent

    system_parent="$(dirname "$system_root")"
    if { [ -d "$system_root" ] && [ -w "$system_root" ]; } ||
       { [ ! -e "$system_root" ] && [ -d "$system_parent" ] && [ -w "$system_parent" ]; }; then
        printf '%s\n' "$system_root"
    else
        printf '%s\n' "${HOME:-/tmp}/pasturestack-backups/server"
    fi
}

OLD_CONTAINER="${OLD_CONTAINER:-pasturestack-server}"
NEW_CONTAINER="${NEW_CONTAINER:-pasturestack-server}"
NEW_IMAGE="${NEW_IMAGE:-ghcr.io/pasturestack/server:v1.6.273}"
HOST_HTTP_PORT="${HOST_HTTP_PORT:-8080}"
PREP_HTTP_PORT="${PREP_HTTP_PORT:-18093}"
MIGRATION_CURL_CONNECT_TIMEOUT="${RC16_MIGRATION_CURL_CONNECT_TIMEOUT:-5}"
MIGRATION_CURL_MAX_TIME="${RC16_MIGRATION_CURL_MAX_TIME:-15}"
BACKUP_ROOT="${BACKUP_ROOT:-$(default_backup_root)}"
WORKDIR="${WORKDIR:-/var/tmp/pasturestack-server-migration}"
SOURCE_BIND="${SOURCE_BIND:-}"
CATALOG_JSON="${CATALOG_JSON:-}"
RC16_AGENT_IMAGE="${RC16_AGENT_IMAGE:-ghcr.io/pasturestack/node-agent:v1.2.31@sha256:89a1703d236fb2ba34d568faef1cf0a41f91a2a5a7e6b8052415ba5a12f2d0e1}"
RC16_LB_INSTANCE_IMAGE="${RC16_LB_INSTANCE_IMAGE:-ghcr.io/pasturestack/load-balancer-service:v0.9.23@sha256:3139b2a54688e4e34b24df943a36a2ed1eecc26d53c0ab329bf7ffcb62cdb893}"
RC16_LB_INSTANCE_IMAGE_UUID="${RC16_LB_INSTANCE_IMAGE_UUID:-docker:${RC16_LB_INSTANCE_IMAGE}}"
RC16_ARTIFACT_BASE_URL="${RC16_ARTIFACT_BASE_URL:-https://github.com/PastureStack/server/releases/download/v1.6.273}"
RC16_GO_AGENT_URL="${RC16_GO_AGENT_URL:-}"
RC16_HOST_API_URL="${RC16_HOST_API_URL:-}"
RC16_RANCHER_API_KEY_FILE="${RC16_RANCHER_API_KEY_FILE:-}"
RC16_LOCAL_AUTH_CREDENTIAL_FILE="${RC16_LOCAL_AUTH_CREDENTIAL_FILE:-}"
RC16_RANCHER_BEARER_TOKEN="${RC16_RANCHER_BEARER_TOKEN:-${RC16_RANCHER_TOKEN:-}}"
RC16_RANCHER_USERNAME="${RC16_RANCHER_USERNAME:-${RANCHER_USERNAME:-}}"
RC16_RANCHER_PASSWORD="${RC16_RANCHER_PASSWORD:-${RANCHER_PASSWORD:-}}"
RANCHER_PROJECT_ID="${RANCHER_PROJECT_ID:-1a5}"
RECYCLE_IPSEC_AFTER_MIGRATION="${RECYCLE_IPSEC_AFTER_MIGRATION:-auto}"
REQUIRE_CONFIRM="${REQUIRE_CONFIRM:-true}"
SKIP_IMAGE_PULL="${SKIP_IMAGE_PULL:-false}"
BACKUP_RAW_MYSQL="${BACKUP_RAW_MYSQL:-true}"
KEEP_BACKUPS="${KEEP_BACKUPS:-10}"
DRY_RUN="${DRY_RUN:-false}"
ROLLBACK_ENV="${ROLLBACK_ENV:-}"
AUTO_CLEANUP="${AUTO_CLEANUP:-true}"
REMOVE_FAILED_VOLUMES="${REMOVE_FAILED_VOLUMES:-true}"
RC16_MIGRATION_FAILPOINT="${RC16_MIGRATION_FAILPOINT:-}"
KEEP_ROLLBACK_CONTAINER="${KEEP_ROLLBACK_CONTAINER:-false}"
OLD_BACKUP_OVERRIDE="${OLD_BACKUP:-}"
VOL_CATTLE_OVERRIDE="${VOL_CATTLE:-}"
VOL_MYSQL_OVERRIDE="${VOL_MYSQL:-}"
VOL_LOG_OVERRIDE="${VOL_LOG:-}"
PREP_CONTAINER_OVERRIDE="${PREP_CONTAINER:-}"
IMPORT_CONTAINER_OVERRIDE="${IMPORT_CONTAINER:-}"

TS="$(date +%Y%m%d%H%M%S)"
RUN_ID="pasturestack-${TS}"
BACKUP_DIR="${BACKUP_DIR:-${BACKUP_ROOT}/${RUN_ID}}"
LOG_FILE="${LOG_FILE:-${BACKUP_DIR}/migration.log}"
LOCK_DIR="${LOCK_DIR:-/var/lock/pasturestack-server-migration.lock}"
SOURCE_BIND_ARGS=()
OLD_RENAMED=false
NEW_STARTED=false

usage() {
    cat <<'EOF'
Usage:
  migrate-server-mysql55-to-mariadb118.sh [action] [options]

Actions:
  preflight     Validate current server, Docker, target image, ports.
  backup        Create backup bundle only; no server switch.
  verify-backup Verify a backup bundle created by backup or migrate; use --backup-dir.
  verify-rollback-env Validate rollback.env syntax and required fields; use --rollback-env.
  migrate       Full backup + DB migration + server switch. Default action.
  rollback      Roll back using --rollback-env <backup>/rollback.env.
  finalize      Archive and remove rollback checkpoint from rollback.env.
  recycle-ipsec Restart the IPsec system service through the compatible API only.
  cleanup       Remove transient PastureStack migration containers.

Options:
  --yes                      Non-interactive execution.
  --dry-run                  Print major commands without executing changes.
  --old-container NAME       Current PastureStack Server container.
  --new-container NAME       Target PastureStack Server container name.
  --new-image IMAGE          Target PastureStack Server image.
  --host-http-port PORT      PastureStack host port. Default 8080.
  --prep-http-port PORT      Temporary validation port. Default 18093.
  --backup-root DIR          Backup root. Defaults to /var/backups/pasturestack-server when writable, otherwise $HOME/pasturestack-backups/server.
  --backup-dir DIR           Exact backup output directory.
  --workdir DIR              Scratch directory.
  --source-bind SPEC         Optional extra docker -v bind mount, e.g. /host:/container.
  --catalog-json JSON        Compatibility catalog JSON. If omitted, preserve an existing setting or use the pinned PastureStack GitHub catalog.
  --artifact-base-url URL    Artifact base URL. Defaults to the matching public PastureStack Server GitHub Release.
  --go-agent-url URL         Full node-agent compatibility tarball URL.
  --host-api-url URL         Full host-api tarball URL.
  --platform-api-key-file FILE
                             Optional key=value file with access_key/secret_key
                             or RANCHER_ACCESS_KEY/RANCHER_SECRET_KEY for
                             migration-time compatible API operations.
  --local-auth-credential-file FILE
                             Optional key=value file with username/password for
                             local-auth token fallback during ipsec recycle.
  --project-id ID            Platform project/environment ID. Default 1a5.
  --rollback-env FILE        rollback.env file produced by a previous migration.
  --skip-image-pull          Do not docker pull target image in preflight.
  --no-raw-mysql-backup      Skip old /var/lib/mysql tar backup.
  --no-ipsec-recycle         Do not restart the ipsec system service after cutover.
  --require-ipsec-recycle    Fail migration if ipsec service recycle cannot run.
  --keep-backups N           Retain N newest backup dirs during cleanup.
  --no-auto-cleanup          Keep helper containers for debugging.
  --keep-failed-volumes      Keep failed target volumes for debugging.
  --keep-rollback-container  Keep old server container after successful migration.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --yes)
            REQUIRE_CONFIRM=false
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --old-container)
            OLD_CONTAINER="$2"; shift
            ;;
        --new-container)
            NEW_CONTAINER="$2"; shift
            ;;
        --new-image)
            NEW_IMAGE="$2"; shift
            ;;
        --host-http-port)
            HOST_HTTP_PORT="$2"; shift
            ;;
        --prep-http-port)
            PREP_HTTP_PORT="$2"; shift
            ;;
        --backup-root)
            BACKUP_ROOT="$2"; BACKUP_DIR="${BACKUP_ROOT}/${RUN_ID}"; LOG_FILE="${BACKUP_DIR}/migration.log"; shift
            ;;
        --backup-dir)
            BACKUP_DIR="$2"; LOG_FILE="${BACKUP_DIR}/migration.log"; shift
            ;;
        --workdir)
            WORKDIR="$2"; shift
            ;;
        --source-bind)
            SOURCE_BIND="$2"; shift
            ;;
        --catalog-json)
            CATALOG_JSON="$2"; shift
            ;;
        --artifact-base-url)
            RC16_ARTIFACT_BASE_URL="$2"; shift
            ;;
        --go-agent-url)
            RC16_GO_AGENT_URL="$2"; shift
            ;;
        --host-api-url)
            RC16_HOST_API_URL="$2"; shift
            ;;
        --platform-api-key-file)
            RC16_RANCHER_API_KEY_FILE="$2"; shift
            ;;
        --local-auth-credential-file)
            RC16_LOCAL_AUTH_CREDENTIAL_FILE="$2"; shift
            ;;
        --project-id)
            RANCHER_PROJECT_ID="$2"; shift
            ;;
        --rollback-env)
            ROLLBACK_ENV="$2"; shift
            ;;
        --skip-image-pull)
            SKIP_IMAGE_PULL=true
            ;;
        --no-raw-mysql-backup)
            BACKUP_RAW_MYSQL=false
            ;;
        --no-ipsec-recycle)
            RECYCLE_IPSEC_AFTER_MIGRATION=false
            ;;
        --require-ipsec-recycle)
            RECYCLE_IPSEC_AFTER_MIGRATION=require
            ;;
        --keep-backups)
            KEEP_BACKUPS="$2"; shift
            ;;
        --no-auto-cleanup)
            AUTO_CLEANUP=false
            ;;
        --keep-failed-volumes)
            REMOVE_FAILED_VOLUMES=false
            ;;
        --keep-rollback-container)
            KEEP_ROLLBACK_CONTAINER=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

if [ -n "$SOURCE_BIND" ]; then
    SOURCE_BIND_ARGS=(-v "$SOURCE_BIND")
fi

OLD_BACKUP="${OLD_BACKUP_OVERRIDE:-${OLD_CONTAINER}-backup-${TS}}"
VOL_CATTLE="${VOL_CATTLE_OVERRIDE:-pasturestack-v177-cattle-${TS}}"
VOL_MYSQL="${VOL_MYSQL_OVERRIDE:-pasturestack-v177-mysql-${TS}}"
VOL_LOG="${VOL_LOG_OVERRIDE:-pasturestack-v177-mysqllog-${TS}}"
PREP_CONTAINER="${PREP_CONTAINER_OVERRIDE:-pasturestack-migrate-prep-${TS}}"
IMPORT_CONTAINER="${IMPORT_CONTAINER_OVERRIDE:-pasturestack-migrate-import-${TS}}"

log() {
    if [ "$ACTION" = "cleanup" ] && [ ! -d "$BACKUP_DIR" ]; then
        printf '%s %s\n' "$(date -Is)" "$*"
    else
        mkdir -p "$BACKUP_DIR"
        chmod 700 "$BACKUP_DIR"
        printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$LOG_FILE"
        chmod 600 "$LOG_FILE" 2>/dev/null || true
    fi
}

secure_backup_files() {
    local path
    local rel
    local uid
    local gid

    uid="$(id -u)"
    gid="$(id -g)"

    for path in "$@"; do
        [ -e "$path" ] || continue
        if chmod 600 "$path" 2>/dev/null; then
            continue
        fi

        rel="${path#${BACKUP_DIR}/}"
        if [ "$rel" = "$path" ] || [[ "$rel" = ../* || "$rel" = */../* ]]; then
            die "refusing to chmod path outside backup dir: ${path}"
        fi

        docker run --rm -v "${BACKUP_DIR}:/backup" ubuntu:26.04 \
            sh -c 'chown "$1:$2" "$3" && chmod 600 "$3"' sh "$uid" "$gid" "/backup/${rel}"
    done
}

die() {
    log "ERROR $*"
    exit 1
}

normalize_artifact_settings() {
    if [ -n "$RC16_ARTIFACT_BASE_URL" ]; then
        RC16_ARTIFACT_BASE_URL="${RC16_ARTIFACT_BASE_URL%/}"
        RC16_GO_AGENT_URL="${RC16_GO_AGENT_URL:-${RC16_ARTIFACT_BASE_URL}/node-agent-0.13.21.tar.gz}"
        RC16_HOST_API_URL="${RC16_HOST_API_URL:-${RC16_ARTIFACT_BASE_URL}/host-api-0.38.4.tar.gz}"
    fi

    if [ -z "$RC16_GO_AGENT_URL" ] || [ -z "$RC16_HOST_API_URL" ]; then
        die "artifact URLs are required; set --artifact-base-url or both --go-agent-url and --host-api-url"
    fi

    case "$RC16_GO_AGENT_URL $RC16_HOST_API_URL" in
        *artifacts.invalid*)
            die "artifact URLs still point at artifacts.invalid; pass real artifact URLs before preflight or migrate"
            ;;
    esac
}

check_artifact_url() {
    local name="$1"
    local url="$2"

    log "checking artifact ${name}: ${url}"
    if ! curl -fsSL --retry 2 --connect-timeout 5 --max-time 60 -o /dev/null "$url"; then
        die "artifact is not reachable: ${name} ${url}"
    fi
}

migration_curl() {
    curl -sS --connect-timeout "$MIGRATION_CURL_CONNECT_TIMEOUT" --max-time "$MIGRATION_CURL_MAX_TIME" "$@"
}

run() {
    log "RUN $*"
    if [ "$DRY_RUN" = "true" ]; then
        return 0
    fi
    "$@"
}

confirm() {
    if [ "$REQUIRE_CONFIRM" != "true" ]; then
        return 0
    fi

    cat <<EOF
About to run '${ACTION}'.

Current server : ${OLD_CONTAINER}
Target image   : ${NEW_IMAGE}
Backup dir     : ${BACKUP_DIR}
HTTP port      : ${HOST_HTTP_PORT}

Type 'yes' to continue:
EOF
    read -r answer
    [ "$answer" = "yes" ] || die "operator did not confirm"
}

acquire_lock() {
    if ! mkdir "$LOCK_DIR" 2>/dev/null; then
        die "another migration appears to be running: ${LOCK_DIR}"
    fi
    trap 'rmdir "$LOCK_DIR" >/dev/null 2>&1 || true' EXIT
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

validate_catalog_json() {
    require_command python3
    python3 - "$CATALOG_JSON" <<'PY'
import json
import sys

try:
    parsed = json.loads(sys.argv[1])
except Exception as e:
    raise SystemExit("invalid CATALOG_JSON: %s" % e)

if not isinstance(parsed, dict) or not isinstance(parsed.get("catalogs"), dict):
    raise SystemExit("invalid CATALOG_JSON: expected object with catalogs object")
PY
}


container_env_value() {
    local name="$1"

    docker inspect "$OLD_CONTAINER" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null |
        sed -n "s/^${name}=//p" |
        tail -n 1
}

catalog_json_from_db() {
    docker exec "$OLD_CONTAINER" sh -c '
        db_client=mariadb
        command -v "$db_client" >/dev/null 2>&1 || db_client=mysql
        "$db_client" --protocol=socket --socket=/var/run/mysqld/mysqld.sock -uroot cattle -NBe "select value from setting where name='\''catalog.url'\'' limit 1"
    ' 2>/dev/null |
        tail -n 1
}

resolve_catalog_json() {
    local inferred

    if [ -n "$CATALOG_JSON" ]; then
        validate_catalog_json
        log "catalog_json_source=explicit"
        return 0
    fi

    inferred="$(catalog_json_from_db || true)"
    if [ -n "$inferred" ]; then
        CATALOG_JSON="$inferred"
        validate_catalog_json
        log "catalog_json_source=setting:catalog.url"
        return 0
    fi

    inferred="$(container_env_value CATTLE_CATALOG_URL || true)"
    if [ -n "$inferred" ]; then
        CATALOG_JSON="$inferred"
        validate_catalog_json
        log "catalog_json_source=old-container-env:CATTLE_CATALOG_URL"
        return 0
    fi

    inferred="$(container_env_value DEFAULT_CATTLE_CATALOG_URL || true)"
    if [ -n "$inferred" ]; then
        CATALOG_JSON="$inferred"
        validate_catalog_json
        log "catalog_json_source=old-container-env:DEFAULT_CATTLE_CATALOG_URL"
        return 0
    fi

    CATALOG_JSON='{"catalogs":{"pasturestack":{"url":"https://github.com/PastureStack/catalog-templates.git","branch":"main","pinnedCommit":"91f5910a44cb181051be2adc4c14f0e6ec7842ef"}}}'
    validate_catalog_json
    log "catalog_json_source=pinned-pasturestack-github-default"
}


preserved_env_file() {
    printf '%s/preserved-container-env.env' "$BACKUP_DIR"
}

ipsec_recycle_auth_file() {
    printf '%s/ipsec-recycle-auth.env' "$BACKUP_DIR"
}

preserved_env_args() {
    local env_file
    env_file="$(preserved_env_file)"
    if [ -s "$env_file" ]; then
        printf '%s\n' --env-file "$env_file"
    fi
}

write_preserved_env_file() {
    local env_file
    local count
    env_file="$(preserved_env_file)"
    docker inspect "$OLD_CONTAINER" --format '{{range .Config.Env}}{{println .}}{{end}}' |
        awk -F= '
            BEGIN {
                split("CATTLE_ACCESS_KEY CATTLE_SECRET_KEY CATALOG_SERVICE_CATTLE_ACCESS_KEY CATALOG_SERVICE_CATTLE_SECRET_KEY CATTLE_URL CATALOG_SERVICE_CATTLE_URL RANCHER_ACCESS_KEY RANCHER_SECRET_KEY", names, " ")
                for (i in names) keep[names[i]] = 1
            }
            index($0, "=") > 0 && keep[$1] { print $0 }
        ' > "$env_file"
    chmod 0600 "$env_file"
    count="$(wc -l < "$env_file")"
    log "preserved_runtime_env_count=${count} file=${env_file} values=redacted"
}

env_file_value() {
    local name="$1"
    local file="$2"

    [ -f "$file" ] || return 1
    awk -F= -v key="$name" '$1 == key { value = substr($0, index($0, "=") + 1); sub(/\r$/, "", value); print value; found=1; exit } END { exit found ? 0 : 1 }' "$file"
}

platform_auth_header_can_read_ipsec() {
    local auth_header="$1"

    [ -n "$auth_header" ] || return 1
    printf '%s\n' "$auth_header" | python3 -c '
import json
import sys
import urllib.request

port = sys.argv[1]
project = sys.argv[2]
auth_header = sys.stdin.readline().rstrip("\n")
req = urllib.request.Request(
    f"http://127.0.0.1:{port}/v2-beta/projects/{project}/services?name=ipsec",
    headers={"Authorization": auth_header, "X-API-Project-Id": project},
)
try:
    with urllib.request.urlopen(req, timeout=20) as response:
        json.loads(response.read().decode("utf-8"))
except Exception:
    raise SystemExit(1)
' "$HOST_HTTP_PORT" "$RANCHER_PROJECT_ID" >/dev/null 2>&1
}

platform_api_key_pair_can_read_ipsec() {
    local key="$1"
    local secret="$2"
    local token

    [ -n "$key" ] && [ -n "$secret" ] || return 1
    token="$(printf '%s:%s' "$key" "$secret" | base64 | tr -d '\n')"
    platform_auth_header_can_read_ipsec "Basic ${token}"
}

platform_bearer_can_read_ipsec() {
    local token="$1"

    [ -n "$token" ] || return 1
    platform_auth_header_can_read_ipsec "Bearer ${token}"
}

platform_local_auth_token() {
    local username="$1"
    local password="$2"

    [ -n "$username" ] && [ -n "$password" ] || return 1
    printf '%s\n%s\n' "$username" "$password" | python3 -c '
import json
import sys
import urllib.parse
import urllib.request

port = sys.argv[1]
username = sys.stdin.readline().rstrip("\n")
password = sys.stdin.readline().rstrip("\n")
form = urllib.parse.urlencode({"code": f"{username}:{password}"}).encode("utf-8")
req = urllib.request.Request(
    f"http://127.0.0.1:{port}/v1/token",
    data=form,
    headers={
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
    },
    method="POST",
)
try:
    with urllib.request.urlopen(req, timeout=20) as response:
        data = json.loads(response.read().decode("utf-8"))
except Exception:
    raise SystemExit(1)

token = data.get("jwt") or data.get("token")
if not token:
    raise SystemExit(1)
print(token)
' "$HOST_HTTP_PORT" 2>/dev/null
}

write_ipsec_recycle_auth_pair() {
    local key="$1"
    local secret="$2"
    local source="$3"
    local auth_file

    [ -n "$key" ] && [ -n "$secret" ] || return 1
    if ! platform_api_key_pair_can_read_ipsec "$key" "$secret"; then
        log "ipsec_recycle_auth_source=${source} validation=failed values=redacted"
        return 1
    fi
    auth_file="$(ipsec_recycle_auth_file)"
    {
        printf 'RANCHER_ACCESS_KEY=%s\n' "$key"
        printf 'RANCHER_SECRET_KEY=%s\n' "$secret"
    } > "$auth_file"
    chmod 0600 "$auth_file"
    log "ipsec_recycle_auth_source=${source} file=${auth_file} values=redacted line_count=$(wc -l < "$auth_file")"
    return 0
}

write_ipsec_recycle_auth_bearer() {
    local token="$1"
    local source="$2"
    local auth_file

    [ -n "$token" ] || return 1
    if ! platform_bearer_can_read_ipsec "$token"; then
        log "ipsec_recycle_auth_source=${source} validation=failed values=redacted"
        return 1
    fi
    auth_file="$(ipsec_recycle_auth_file)"
    {
        printf 'RANCHER_BEARER_TOKEN=%s\n' "$token"
    } > "$auth_file"
    chmod 0600 "$auth_file"
    log "ipsec_recycle_auth_source=${source} file=${auth_file} values=redacted line_count=$(wc -l < "$auth_file")"
    return 0
}

write_ipsec_recycle_auth_local_auth() {
    local username="$1"
    local password="$2"
    local source="$3"
    local token

    [ -n "$username" ] && [ -n "$password" ] || return 1
    token="$(platform_local_auth_token "$username" "$password" || true)"
    if [ -z "$token" ]; then
        log "ipsec_recycle_auth_source=${source} token=failed values=redacted"
        return 1
    fi
    write_ipsec_recycle_auth_bearer "$token" "$source"
}

api_key_from_source_db() {
    docker exec -i "$OLD_CONTAINER" sh -c '
        db_client=mariadb
        command -v "$db_client" >/dev/null 2>&1 || db_client=mysql
        "$db_client" --protocol=socket --socket=/var/run/mysqld/mysqld.sock -uroot cattle -N -B
    ' <<'SQL' 2>/dev/null
SELECT c.public_value, c.secret_value
FROM credential c
JOIN account a ON a.id = c.account_id
WHERE c.kind = 'apiKey'
  AND c.state = 'active'
  AND c.removed IS NULL
  AND c.public_value IS NOT NULL
  AND c.public_value <> ''
  AND c.secret_value IS NOT NULL
  AND c.secret_value <> ''
  AND a.state = 'active'
ORDER BY (c.name = 'pasturestack-internal-service') DESC,
         (a.kind = 'admin') DESC,
         c.id DESC;
SQL
}

write_ipsec_recycle_auth_file() {
    local auth_file
    local token
    local key
    local secret
    local username
    local password
    local preserved

    auth_file="$(ipsec_recycle_auth_file)"
    : > "$auth_file"
    chmod 0600 "$auth_file"

    token="${RC16_RANCHER_BEARER_TOKEN:-${RANCHER_BEARER_TOKEN:-${RANCHER_TOKEN:-}}}"
    if write_ipsec_recycle_auth_bearer "$token" "process-env-bearer"; then
        return 0
    fi

    key="${RC16_RANCHER_ACCESS_KEY:-${RANCHER_ACCESS_KEY:-${CATTLE_ACCESS_KEY:-}}}"
    secret="${RC16_RANCHER_SECRET_KEY:-${RANCHER_SECRET_KEY:-${CATTLE_SECRET_KEY:-}}}"
    if write_ipsec_recycle_auth_pair "$key" "$secret" "process-env"; then
        return 0
    fi

    username="${RC16_RANCHER_USERNAME:-${RANCHER_USERNAME:-}}"
    password="${RC16_RANCHER_PASSWORD:-${RANCHER_PASSWORD:-}}"
    if write_ipsec_recycle_auth_local_auth "$username" "$password" "process-env-local-auth"; then
        return 0
    fi

    if [ -n "$RC16_RANCHER_API_KEY_FILE" ]; then
        [ -r "$RC16_RANCHER_API_KEY_FILE" ] || die "Control API credential file is not readable: ${RC16_RANCHER_API_KEY_FILE}"
        token="$(env_file_value bearer_token "$RC16_RANCHER_API_KEY_FILE" || env_file_value token "$RC16_RANCHER_API_KEY_FILE" || env_file_value jwt "$RC16_RANCHER_API_KEY_FILE" || env_file_value RANCHER_BEARER_TOKEN "$RC16_RANCHER_API_KEY_FILE" || env_file_value RC16_RANCHER_BEARER_TOKEN "$RC16_RANCHER_API_KEY_FILE" || env_file_value RC16_RANCHER_TOKEN "$RC16_RANCHER_API_KEY_FILE" || true)"
        if write_ipsec_recycle_auth_bearer "$token" "api-key-file-bearer"; then
            return 0
        fi
        key="$(env_file_value access_key "$RC16_RANCHER_API_KEY_FILE" || env_file_value RANCHER_ACCESS_KEY "$RC16_RANCHER_API_KEY_FILE" || env_file_value RC16_RANCHER_ACCESS_KEY "$RC16_RANCHER_API_KEY_FILE" || true)"
        secret="$(env_file_value secret_key "$RC16_RANCHER_API_KEY_FILE" || env_file_value RANCHER_SECRET_KEY "$RC16_RANCHER_API_KEY_FILE" || env_file_value RC16_RANCHER_SECRET_KEY "$RC16_RANCHER_API_KEY_FILE" || true)"
        if write_ipsec_recycle_auth_pair "$key" "$secret" "api-key-file"; then
            return 0
        fi
        username="$(env_file_value username "$RC16_RANCHER_API_KEY_FILE" || env_file_value Username "$RC16_RANCHER_API_KEY_FILE" || env_file_value RANCHER_USERNAME "$RC16_RANCHER_API_KEY_FILE" || env_file_value RC16_RANCHER_USERNAME "$RC16_RANCHER_API_KEY_FILE" || true)"
        password="$(env_file_value password "$RC16_RANCHER_API_KEY_FILE" || env_file_value Password "$RC16_RANCHER_API_KEY_FILE" || env_file_value RANCHER_PASSWORD "$RC16_RANCHER_API_KEY_FILE" || env_file_value RC16_RANCHER_PASSWORD "$RC16_RANCHER_API_KEY_FILE" || true)"
        if write_ipsec_recycle_auth_local_auth "$username" "$password" "api-key-file-local-auth"; then
            return 0
        fi
        die "Control API credential file does not contain usable bearer token, access/secret, or username/password credentials: ${RC16_RANCHER_API_KEY_FILE}"
    fi

    if [ -n "$RC16_LOCAL_AUTH_CREDENTIAL_FILE" ]; then
        [ -r "$RC16_LOCAL_AUTH_CREDENTIAL_FILE" ] || die "Local-auth credential file is not readable: ${RC16_LOCAL_AUTH_CREDENTIAL_FILE}"
        username="$(env_file_value username "$RC16_LOCAL_AUTH_CREDENTIAL_FILE" || env_file_value Username "$RC16_LOCAL_AUTH_CREDENTIAL_FILE" || env_file_value RANCHER_USERNAME "$RC16_LOCAL_AUTH_CREDENTIAL_FILE" || env_file_value RC16_RANCHER_USERNAME "$RC16_LOCAL_AUTH_CREDENTIAL_FILE" || true)"
        password="$(env_file_value password "$RC16_LOCAL_AUTH_CREDENTIAL_FILE" || env_file_value Password "$RC16_LOCAL_AUTH_CREDENTIAL_FILE" || env_file_value RANCHER_PASSWORD "$RC16_LOCAL_AUTH_CREDENTIAL_FILE" || env_file_value RC16_RANCHER_PASSWORD "$RC16_LOCAL_AUTH_CREDENTIAL_FILE" || true)"
        if write_ipsec_recycle_auth_local_auth "$username" "$password" "local-auth-credential-file"; then
            return 0
        fi
        die "Local-auth credential file does not contain usable username/password credentials: ${RC16_LOCAL_AUTH_CREDENTIAL_FILE}"
    fi

    preserved="$(preserved_env_file)"
    key="$(env_file_value CATTLE_ACCESS_KEY "$preserved" || env_file_value RANCHER_ACCESS_KEY "$preserved" || true)"
    secret="$(env_file_value CATTLE_SECRET_KEY "$preserved" || env_file_value RANCHER_SECRET_KEY "$preserved" || true)"
    if write_ipsec_recycle_auth_pair "$key" "$secret" "preserved-container-env"; then
        return 0
    fi

    while IFS=$'\t' read -r key secret; do
        [ -n "$key" ] && [ -n "$secret" ] || continue
        if write_ipsec_recycle_auth_pair "$key" "$secret" "source-db-active-api-key"; then
            return 0
        fi
    done < <(api_key_from_source_db || true)

    log "ipsec_recycle_auth_source=none file=${auth_file} values=redacted line_count=0"
}

failpoint() {
    local name="$1"
    if [ "$RC16_MIGRATION_FAILPOINT" = "$name" ]; then
        log "FAILPOINT ${name}"
        return 1
    fi
}

label_args() {
    local role="$1"
    printf '%s\n' \
        --label "io.pasturestack.migration.run_id=${RUN_ID}" \
        --label "io.pasturestack.migration.role=${role}" \
        --label "io.pasturestack.migration.backup_dir=${BACKUP_DIR}"
}

remove_container_if_exists() {
    local name="$1"
    if docker ps -a --format '{{.Names}}' | grep -qx "$name"; then
        docker rm -f "$name" >/dev/null 2>&1 || true
        log "removed_container=${name}"
    fi
}

volume_users() {
    local volume="$1"
    docker ps -a --filter volume="$volume" --format '{{.Names}}' | paste -sd, -
}

remove_volume_if_unused() {
    local volume="$1"
    if ! docker volume inspect "$volume" >/dev/null 2>&1; then
        return 0
    fi

    local users
    users="$(volume_users "$volume")"
    if [ -z "$users" ]; then
        docker volume rm "$volume" >/dev/null 2>&1 || true
        log "removed_volume=${volume}"
    else
        log "kept_in_use_volume=${volume} users=${users}"
    fi
}

cleanup_transient_containers() {
    if [ "$AUTO_CLEANUP" != "true" ]; then
        log "AUTO_CLEANUP_DISABLED"
        return 0
    fi

    log "TRANSIENT_CLEANUP_START"
    remove_container_if_exists "$PREP_CONTAINER"
    remove_container_if_exists "$IMPORT_CONTAINER"
    docker ps -a \
        --filter "label=io.pasturestack.migration.run_id=${RUN_ID}" \
        --filter "label=io.pasturestack.migration.role=prep" \
        --format '{{.Names}}' | while read -r name; do
            [ -n "$name" ] && remove_container_if_exists "$name"
        done
    docker ps -a \
        --filter "label=io.pasturestack.migration.run_id=${RUN_ID}" \
        --filter "label=io.pasturestack.migration.role=import" \
        --format '{{.Names}}' | while read -r name; do
            [ -n "$name" ] && remove_container_if_exists "$name"
        done
    log "TRANSIENT_CLEANUP_OK"
}

cleanup_failed_target_volumes() {
    if [ "$REMOVE_FAILED_VOLUMES" != "true" ]; then
        log "FAILED_VOLUME_CLEANUP_DISABLED"
        return 0
    fi

    log "FAILED_VOLUME_CLEANUP_START"
    remove_volume_if_unused "$VOL_CATTLE"
    remove_volume_if_unused "$VOL_MYSQL"
    remove_volume_if_unused "$VOL_LOG"
    log "FAILED_VOLUME_CLEANUP_OK"
}

cleanup_failed_agent_upgrade_helpers() {
    log "AGENT_UPGRADE_HELPER_CLEANUP_START"
    for helper_name in pasturestack-node-agent-upgrade rancher-agent-upgrade; do
        docker ps -a \
            --filter "name=${helper_name}" \
            --filter "status=exited" \
            --format '{{.Names}}' | while read -r name; do
                [ -n "$name" ] && remove_container_if_exists "$name"
            done
    done
    docker ps -a \
        --filter "label=io.rancher.container.system=rancher-agent" \
        --filter "status=exited" \
        --format '{{.Names}}' | { grep 'upgrade' || true; } | while read -r name; do
            [ -n "$name" ] && remove_container_if_exists "$name"
        done
    log "AGENT_UPGRADE_HELPER_CLEANUP_OK"
}

write_final_inventory() {
    {
        echo "created_at=$(date -Is)"
        echo "run_id=${RUN_ID}"
        echo "new_container=${NEW_CONTAINER}"
        echo "old_backup=${OLD_BACKUP}"
        echo "vol_cattle=${VOL_CATTLE} users=$(volume_users "$VOL_CATTLE")"
        echo "vol_mysql=${VOL_MYSQL} users=$(volume_users "$VOL_MYSQL")"
        echo "vol_log=${VOL_LOG} users=$(volume_users "$VOL_LOG")"
        echo "auto_cleanup=${AUTO_CLEANUP}"
    } > "${BACKUP_DIR}/final-inventory.txt"
    secure_backup_files "${BACKUP_DIR}/final-inventory.txt"
}

wait_ping() {
    local port="$1"
    local label="$2"
    local max="${3:-360}"

    for i in $(seq 1 "$max"); do
        if [ "$(migration_curl -f "http://127.0.0.1:${port}/ping" 2>/dev/null || true)" = "pong" ]; then
            log "${label}_PING_OK after ${i}s"
            return 0
        fi
        sleep 1
    done

    log "${label}_PING_FAIL"
    return 1
}

write_runtime_metadata() {
    docker version > "${BACKUP_DIR}/docker-version.txt" 2>&1 || true
    docker info > "${BACKUP_DIR}/docker-info.txt" 2>&1 || true
    docker ps -a --format '{{.Names}} {{.Image}} {{.Status}}' > "${BACKUP_DIR}/docker-ps-before.txt" 2>&1 || true
    docker images --digests > "${BACKUP_DIR}/docker-images-before.txt" 2>&1 || true
    docker inspect "$OLD_CONTAINER" > "${BACKUP_DIR}/old-container-inspect.json"
    secure_backup_files \
        "${BACKUP_DIR}/docker-version.txt" \
        "${BACKUP_DIR}/docker-info.txt" \
        "${BACKUP_DIR}/docker-ps-before.txt" \
        "${BACKUP_DIR}/docker-images-before.txt" \
        "${BACKUP_DIR}/old-container-inspect.json"
}

preflight() {
    log "PREFLIGHT_START old_container=${OLD_CONTAINER} new_image=${NEW_IMAGE}"
    require_command docker
    require_command curl
    require_command sha256sum
    require_command tar
    resolve_catalog_json

    check_artifact_url go-agent "$RC16_GO_AGENT_URL"
    check_artifact_url host-api "$RC16_HOST_API_URL"

    docker inspect "$OLD_CONTAINER" >/dev/null
    migration_curl -f "http://127.0.0.1:${HOST_HTTP_PORT}/ping" >/dev/null

    if docker ps -a --format '{{.Names}}' | grep -qx "$NEW_CONTAINER" &&
       [ "$OLD_CONTAINER" != "$NEW_CONTAINER" ]; then
        die "new container name already exists: ${NEW_CONTAINER}"
    fi

    if [ "$SKIP_IMAGE_PULL" != "true" ]; then
        run docker pull "$NEW_IMAGE"
    fi

    if docker ps --format '{{.Ports}}' | grep -q "0.0.0.0:${PREP_HTTP_PORT}->"; then
        die "prep port appears busy: ${PREP_HTTP_PORT}"
    fi

    log "PREFLIGHT_OK"
}

create_backup() {
    log "BACKUP_START dir=${BACKUP_DIR}"
    mkdir -p "$BACKUP_DIR" "$WORKDIR"

    cat > "${BACKUP_DIR}/manifest.env" <<EOF
RUN_ID=${RUN_ID}
CREATED_AT=$(date -Is)
OLD_CONTAINER=${OLD_CONTAINER}
NEW_CONTAINER=${NEW_CONTAINER}
NEW_IMAGE=${NEW_IMAGE}
HOST_HTTP_PORT=${HOST_HTTP_PORT}
PREP_HTTP_PORT=${PREP_HTTP_PORT}
BACKUP_DIR=${BACKUP_DIR}
VOL_CATTLE=${VOL_CATTLE}
VOL_MYSQL=${VOL_MYSQL}
VOL_LOG=${VOL_LOG}
OLD_BACKUP=${OLD_BACKUP}
CATALOG_JSON=${CATALOG_JSON}
RC16_AGENT_IMAGE=${RC16_AGENT_IMAGE}
RC16_GO_AGENT_URL=${RC16_GO_AGENT_URL}
RC16_HOST_API_URL=${RC16_HOST_API_URL}
EOF
    secure_backup_files "${BACKUP_DIR}/manifest.env"

    write_runtime_metadata
    write_preserved_env_file
    write_ipsec_recycle_auth_file

    log "dumping cattle database"
    docker exec "$OLD_CONTAINER" sh -c \
        'mysqldump -uroot --single-transaction --routines --triggers cattle' \
        > "${BACKUP_DIR}/cattle.sql"
    test -s "${BACKUP_DIR}/cattle.sql" || die "empty cattle.sql dump"
    sha256sum "${BACKUP_DIR}/cattle.sql" > "${BACKUP_DIR}/cattle.sql.sha256"
    secure_backup_files "${BACKUP_DIR}/cattle.sql" "${BACKUP_DIR}/cattle.sql.sha256"

    log "archiving /var/lib/cattle"
    docker run --rm --volumes-from "$OLD_CONTAINER" -v "${BACKUP_DIR}:/backup" ubuntu:26.04 \
        bash -lc "tar --warning=no-file-changed --ignore-failed-read -C /var/lib/cattle --exclude='./cattle-debug.log' -cpf /backup/var-lib-cattle.tar ."
    sha256sum "${BACKUP_DIR}/var-lib-cattle.tar" > "${BACKUP_DIR}/var-lib-cattle.tar.sha256"
    secure_backup_files "${BACKUP_DIR}/var-lib-cattle.tar" "${BACKUP_DIR}/var-lib-cattle.tar.sha256"

    if [ "$BACKUP_RAW_MYSQL" = "true" ]; then
        log "archiving old /var/lib/mysql for old-server rollback only"
        docker run --rm --volumes-from "$OLD_CONTAINER" -v "${BACKUP_DIR}:/backup" ubuntu:26.04 \
            bash -lc "tar --warning=no-file-changed --ignore-failed-read -C /var/lib/mysql -cpf /backup/var-lib-mysql-old-format.tar . || rc=\$?; if [ \"\${rc:-0}\" -gt 1 ]; then exit \"\$rc\"; fi"
        sha256sum "${BACKUP_DIR}/var-lib-mysql-old-format.tar" > "${BACKUP_DIR}/var-lib-mysql-old-format.tar.sha256"
        secure_backup_files "${BACKUP_DIR}/var-lib-mysql-old-format.tar" "${BACKUP_DIR}/var-lib-mysql-old-format.tar.sha256"
    fi

    cat > "${BACKUP_DIR}/README.txt" <<EOF
This backup was created for PastureStack Server migration.

Restore rules:
- cattle.sql can be imported into a ${NEW_IMAGE}-initialized MariaDB 11.8 datadir.
- var-lib-cattle.tar is safe to restore with the PastureStack Server data volume.
- var-lib-mysql-old-format.tar is only for restoring the old MySQL 5.5 server.
- preserved-container-env.env contains redacted-in-logs runtime service credentials and must be protected like the SQL backup.
- ipsec-recycle-auth.env contains the redacted-in-logs control API key or Bearer token used only for post-cutover system-service recycle.
- Do not mount var-lib-mysql-old-format.tar content directly into ${NEW_IMAGE}.
EOF
    secure_backup_files "${BACKUP_DIR}/README.txt"

    log "BACKUP_OK dir=${BACKUP_DIR}"
}

require_backup_file() {
    local path="$1"
    [ -s "$path" ] || die "backup file missing or empty: ${path}"
}

require_backup_path() {
    local path="$1"
    [ -e "$path" ] || die "backup path missing: ${path}"
}

verify_sha256() {
    local artifact="$1"
    local checksum_file="$2"
    local expected
    local actual

    require_backup_file "$artifact"
    require_backup_file "$checksum_file"
    expected="$(awk 'NR == 1 {print $1}' "$checksum_file")"
    actual="$(sha256sum "$artifact" | awk '{print $1}')"
    if [ "$expected" != "$actual" ]; then
        die "checksum mismatch: ${artifact}"
    fi
    log "VERIFY_SHA256_OK artifact=${artifact}"
}

verify_tar_archive() {
    local archive="$1"

    require_backup_file "$archive"
    if ! tar -tf "$archive" >/dev/null; then
        die "tar archive cannot be listed: ${archive}"
    fi
    log "VERIFY_TAR_OK archive=${archive}"
}

is_valid_docker_name() {
    [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]]
}

is_valid_image_ref() {
    [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._/@:+-]*$ ]]
}

is_valid_backup_path() {
    [[ "$1" =~ ^[A-Za-z0-9_./-]+$ ]] && [[ "$1" != -* ]] && [[ "$1" != *".."* ]]
}

parse_rollback_env() {
    local file="$1"
    local line
    local key
    local value
    local seen=" "
    local required

    [ -s "$file" ] || die "rollback.env missing or empty: ${file}"

    while IFS= read -r line || [ -n "$line" ]; do
        value="${line%$'\r'}"
        line="$value"
        case "$line" in
            ""|\#*) continue ;;
        esac
        case "$line" in
            *=*) ;;
            *) die "rollback.env unsupported syntax: ${line}" ;;
        esac

        key="${line%%=*}"
        value="${line#*=}"
        value="${value%$'\r'}"
        [ -n "$value" ] || die "rollback.env ${key} is empty"
        case "$key" in
            OLD_CONTAINER|NEW_CONTAINER|OLD_BACKUP|NEW_IMAGE|HOST_HTTP_PORT|VOL_CATTLE|VOL_MYSQL|VOL_LOG|BACKUP_DIR)
                ;;
            *)
                die "rollback.env unexpected key: ${key}"
                ;;
        esac
        case " $seen " in
            *" $key "*) die "rollback.env duplicate key: ${key}" ;;
        esac
        seen="${seen}${key} "
        printf -v "$key" '%s' "$value"
    done < "$file"

    for required in OLD_CONTAINER NEW_CONTAINER OLD_BACKUP NEW_IMAGE HOST_HTTP_PORT VOL_CATTLE VOL_MYSQL VOL_LOG BACKUP_DIR; do
        case " $seen " in
            *" $required "*) ;;
            *) die "rollback.env missing ${required}" ;;
        esac
    done

    for key in OLD_CONTAINER NEW_CONTAINER OLD_BACKUP VOL_CATTLE VOL_MYSQL VOL_LOG; do
        is_valid_docker_name "${!key}" || die "rollback.env ${key} has an unsafe Docker name: ${!key}"
    done
    [[ "$HOST_HTTP_PORT" =~ ^[0-9]+$ ]] || die "rollback.env HOST_HTTP_PORT must be numeric: ${HOST_HTTP_PORT}"
    [ "$HOST_HTTP_PORT" -ge 1 ] && [ "$HOST_HTTP_PORT" -le 65535 ] ||
        die "rollback.env HOST_HTTP_PORT out of range: ${HOST_HTTP_PORT}"
    is_valid_image_ref "$NEW_IMAGE" || die "rollback.env NEW_IMAGE has unsafe characters: ${NEW_IMAGE}"
    is_valid_backup_path "$BACKUP_DIR" || die "rollback.env BACKUP_DIR has unsafe characters: ${BACKUP_DIR}"
}

load_rollback_env() {
    [ -n "$ROLLBACK_ENV" ] || die "${ACTION} requires --rollback-env"
    BACKUP_DIR="$(dirname "$ROLLBACK_ENV")"
    LOG_FILE="${BACKUP_DIR}/${ACTION}.log"
    parse_rollback_env "$ROLLBACK_ENV"
    LOG_FILE="${BACKUP_DIR}/${ACTION}.log"
}

verify_backup_bundle() {
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "ERROR backup dir not found: ${BACKUP_DIR}" >&2
        exit 1
    fi

    log "VERIFY_BACKUP_START dir=${BACKUP_DIR}"
    require_backup_file "${BACKUP_DIR}/manifest.env"
    require_backup_file "${BACKUP_DIR}/README.txt"
    require_backup_file "${BACKUP_DIR}/old-container-inspect.json"
    require_backup_path "${BACKUP_DIR}/preserved-container-env.env"
    log "VERIFY_PRESERVED_ENV_OK lines=$(wc -l < "${BACKUP_DIR}/preserved-container-env.env")"
    if [ -f "${BACKUP_DIR}/ipsec-recycle-auth.env" ]; then
        log "VERIFY_IPSEC_RECYCLE_AUTH_OK lines=$(wc -l < "${BACKUP_DIR}/ipsec-recycle-auth.env")"
    else
        log "VERIFY_IPSEC_RECYCLE_AUTH_SKIPPED missing"
    fi

    verify_sha256 "${BACKUP_DIR}/cattle.sql" "${BACKUP_DIR}/cattle.sql.sha256"
    if ! grep -Eq '^(CREATE|INSERT|LOCK|UNLOCK|DROP|ALTER) ' "${BACKUP_DIR}/cattle.sql"; then
        die "cattle.sql does not look like a restorable SQL dump"
    fi
    log "VERIFY_SQL_OK file=${BACKUP_DIR}/cattle.sql"

    verify_sha256 "${BACKUP_DIR}/var-lib-cattle.tar" "${BACKUP_DIR}/var-lib-cattle.tar.sha256"
    verify_tar_archive "${BACKUP_DIR}/var-lib-cattle.tar"

    if [ -e "${BACKUP_DIR}/var-lib-mysql-old-format.tar" ] ||
       [ -e "${BACKUP_DIR}/var-lib-mysql-old-format.tar.sha256" ]; then
        verify_sha256 "${BACKUP_DIR}/var-lib-mysql-old-format.tar" \
            "${BACKUP_DIR}/var-lib-mysql-old-format.tar.sha256"
        verify_tar_archive "${BACKUP_DIR}/var-lib-mysql-old-format.tar"
    fi

    for key in RUN_ID OLD_CONTAINER NEW_CONTAINER NEW_IMAGE BACKUP_DIR VOL_CATTLE VOL_MYSQL VOL_LOG; do
        if ! grep -q "^${key}=" "${BACKUP_DIR}/manifest.env"; then
            die "manifest.env missing ${key}"
        fi
    done

    if grep -q 'artifacts.invalid' "${BACKUP_DIR}/manifest.env"; then
        die "manifest.env contains artifacts.invalid"
    fi

    if [ -e "${BACKUP_DIR}/rollback.env" ]; then
        local expected_backup_dir="$BACKUP_DIR"
        parse_rollback_env "${BACKUP_DIR}/rollback.env"
        if [ "$BACKUP_DIR" != "$expected_backup_dir" ]; then
            local parsed_backup_dir="$BACKUP_DIR"
            BACKUP_DIR="$expected_backup_dir"
            LOG_FILE="${BACKUP_DIR}/migration.log"
            die "rollback.env BACKUP_DIR mismatch: parsed=${parsed_backup_dir} expected=${expected_backup_dir}"
        fi
        log "VERIFY_ROLLBACK_ENV_OK file=${BACKUP_DIR}/rollback.env"
    fi

    log "VERIFY_BACKUP_OK dir=${BACKUP_DIR}"
}

init_new_volumes() {
    log "creating target volumes"
    docker volume create \
        --label "io.pasturestack.migration.run_id=${RUN_ID}" \
        --label "io.pasturestack.migration.role=cattle" \
        "$VOL_CATTLE" >/dev/null
    docker volume create \
        --label "io.pasturestack.migration.run_id=${RUN_ID}" \
        --label "io.pasturestack.migration.role=mysql" \
        "$VOL_MYSQL" >/dev/null
    docker volume create \
        --label "io.pasturestack.migration.run_id=${RUN_ID}" \
        --label "io.pasturestack.migration.role=mysqllog" \
        "$VOL_LOG" >/dev/null

    log "restoring /var/lib/cattle into target volume"
    docker run --rm -v "${VOL_CATTLE}:/target" -v "${BACKUP_DIR}:/backup" ubuntu:26.04 \
        bash -lc "tar -C /target -xpf /backup/var-lib-cattle.tar || true"

    log "initializing MariaDB datadir with ${NEW_IMAGE}"
    docker rm -f "$PREP_CONTAINER" "$IMPORT_CONTAINER" >/dev/null 2>&1 || true
    docker run -d --name "$PREP_CONTAINER" \
        $(label_args prep) \
        $(preserved_env_args) \
        -p "${PREP_HTTP_PORT}:8080" \
        -e CATTLE_CHECK_NAMESERVER=false \
        -e "CATTLE_CATALOG_URL=${CATALOG_JSON}" \
        -v "${VOL_CATTLE}:/var/lib/cattle" \
        -v "${VOL_MYSQL}:/var/lib/mysql" \
        -v "${VOL_LOG}:/var/log/mysql" \
        "$NEW_IMAGE" >/dev/null
    wait_ping "$PREP_HTTP_PORT" PREP 300
    docker stop "$PREP_CONTAINER" >/dev/null

    log "importing old dump into PastureStack-initialized MariaDB"
    docker run -d --name "$IMPORT_CONTAINER" \
        $(label_args import) \
        -v "${VOL_MYSQL}:/var/lib/mysql" \
        -v "${VOL_LOG}:/var/log/mysql" \
        -v "${BACKUP_DIR}:/backup" \
        "$NEW_IMAGE" \
        sh -c 'mkdir -p /var/run/mysqld /var/log/mysql; chown -R mysql:mysql /var/run/mysqld /var/log/mysql /var/lib/mysql; mariadbd --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=$(mysql_config --plugindir) --user=mysql --log-error=/var/log/mysql/import-error.log --pid-file=/var/run/mysqld/mysqld.pid --socket=/var/run/mysqld/mysqld.sock --port=3306' >/dev/null

    for i in $(seq 1 120); do
        if docker exec "$IMPORT_CONTAINER" mariadb-admin --protocol=socket --socket=/var/run/mysqld/mysqld.sock -uroot ping --silent; then
            break
        fi
        sleep 1
        if [ "$i" = 120 ]; then
            docker logs "$IMPORT_CONTAINER" | tee "${BACKUP_DIR}/import-container.log"
            die "import MariaDB did not start"
        fi
    done

    docker exec "$IMPORT_CONTAINER" mariadb --protocol=socket --socket=/var/run/mysqld/mysqld.sock -uroot -e \
        'DROP DATABASE IF EXISTS cattle; CREATE DATABASE cattle COLLATE utf8_general_ci CHARACTER SET utf8; GRANT ALL ON cattle.* TO "cattle"@"%" IDENTIFIED BY "cattle"; GRANT ALL ON cattle.* TO "cattle"@"localhost" IDENTIFIED BY "cattle";'
    docker exec -i "$IMPORT_CONTAINER" mariadb --protocol=socket --socket=/var/run/mysqld/mysqld.sock -uroot cattle \
        < "${BACKUP_DIR}/cattle.sql" 2> "${BACKUP_DIR}/restore.err"
    docker stop "$IMPORT_CONTAINER" >/dev/null
}

rollback_from_current_run() {
    log "ROLLBACK_START"
    if [ "$OLD_RENAMED" = "true" ] || docker ps -a --format '{{.Names}}' | grep -qx "$OLD_BACKUP"; then
        docker rm -f "$NEW_CONTAINER" >/dev/null 2>&1 || true
        if docker ps -a --format '{{.Names}}' | grep -qx "$OLD_BACKUP"; then
            docker rename "$OLD_BACKUP" "$OLD_CONTAINER" || true
            docker start "$OLD_CONTAINER" || true
            wait_ping "$HOST_HTTP_PORT" ROLLBACK 240 || true
        fi
    else
        log "ROLLBACK_SKIPPED old container was not renamed"
    fi
    log "ROLLBACK_DONE"
}

handle_migration_failure() {
    local exit_code=$?
    trap - ERR
    log "MIGRATION_FAILED exit_code=${exit_code}"
    rollback_from_current_run
    cleanup_transient_containers
    cleanup_failed_target_volumes
    write_final_inventory || true
    exit "$exit_code"
}

write_rollback_env() {
    cat > "${BACKUP_DIR}/rollback.env" <<EOF
OLD_CONTAINER=${OLD_CONTAINER}
NEW_CONTAINER=${NEW_CONTAINER}
OLD_BACKUP=${OLD_BACKUP}
NEW_IMAGE=${NEW_IMAGE}
HOST_HTTP_PORT=${HOST_HTTP_PORT}
VOL_CATTLE=${VOL_CATTLE}
VOL_MYSQL=${VOL_MYSQL}
VOL_LOG=${VOL_LOG}
BACKUP_DIR=${BACKUP_DIR}
EOF
    secure_backup_files "${BACKUP_DIR}/rollback.env"
}

switch_server() {
    log "SWITCH_START"
    docker stop "$OLD_CONTAINER" >/dev/null
    docker rename "$OLD_CONTAINER" "$OLD_BACKUP"
    OLD_RENAMED=true

    docker run -d --restart=unless-stopped --name "$NEW_CONTAINER" \
        $(label_args server) \
        $(preserved_env_args) \
        -p "${HOST_HTTP_PORT}:8080" \
        "${SOURCE_BIND_ARGS[@]}" \
        -v "${VOL_CATTLE}:/var/lib/cattle" \
        -v "${VOL_MYSQL}:/var/lib/mysql" \
        -v "${VOL_LOG}:/var/log/mysql" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -e "CATTLE_CATALOG_URL=${CATALOG_JSON}" \
        -e CATTLE_CHECK_NAMESERVER=false \
        "$NEW_IMAGE" >/dev/null
    NEW_STARTED=true
    failpoint after_new_container_started

    wait_ping "$HOST_HTTP_PORT" LIVE 360
    write_rollback_env
    log "SWITCH_OK rollback_env=${BACKUP_DIR}/rollback.env"
}

fix_persisted_settings() {
    log "fixing persisted platform settings"
    docker exec "$NEW_CONTAINER" sh -c "mariadb --protocol=socket --socket=/var/run/mysqld/mysqld.sock -uroot cattle <<SQL
UPDATE setting SET value='${RC16_AGENT_IMAGE}' WHERE name='agent.image';
UPDATE setting SET value='${RC16_AGENT_IMAGE}' WHERE name='bootstrap.required.image';
UPDATE setting SET value='${RC16_LB_INSTANCE_IMAGE}' WHERE name='lb.instance.image';
UPDATE setting SET value='${RC16_LB_INSTANCE_IMAGE_UUID}' WHERE name='lb.instance.image.uuid';
UPDATE setting SET value='${RC16_GO_AGENT_URL}' WHERE name='agent.package.python.agent.url';
UPDATE setting SET value='${RC16_HOST_API_URL}' WHERE name='agent.package.host.api.url';
SQL"
    docker restart "$NEW_CONTAINER" >/dev/null
    wait_ping "$HOST_HTTP_PORT" RESTART 240
}

repair_blank_primary_ip_addresses() {
    log "PRIMARY_IP_REPAIR_START"
    docker exec -i "$NEW_CONTAINER" sh -c "mariadb --protocol=socket --socket=/var/run/mysqld/mysqld.sock -uroot cattle" <<'SQL' | tee "${BACKUP_DIR}/primary-ip-repair.txt"
CREATE TEMPORARY TABLE pasturestack_primary_ip_repair_candidates AS
SELECT
  i.id,
  COALESCE(
    NULLIF(JSON_UNQUOTE(JSON_EXTRACT(i.data, '$.fields.dockerIp')), ''),
    NULLIF(ip.address, '')
  ) AS repair_ip
FROM instance i
JOIN instance_host_map ihm ON ihm.instance_id = i.id AND ihm.removed IS NULL
LEFT JOIN nic n ON n.instance_id = i.id AND n.device_number = 0 AND n.removed IS NULL
LEFT JOIN ip_address_nic_map inm ON inm.nic_id = n.id AND inm.removed IS NULL
LEFT JOIN ip_address ip ON ip.id = inm.ip_address_id AND ip.removed IS NULL
WHERE i.removed IS NULL
  AND i.state IN ('running', 'active')
  AND NULLIF(JSON_UNQUOTE(JSON_EXTRACT(i.data, '$.fields.primaryIpAddress')), '') IS NULL
  AND COALESCE(
    NULLIF(JSON_UNQUOTE(JSON_EXTRACT(i.data, '$.fields.dockerIp')), ''),
    NULLIF(ip.address, '')
  ) IS NOT NULL;

SELECT COUNT(*) AS repair_candidate_count FROM pasturestack_primary_ip_repair_candidates;

UPDATE instance i
JOIN pasturestack_primary_ip_repair_candidates c ON c.id = i.id
SET i.data = JSON_SET(
  JSON_SET(
    CASE WHEN i.data IS NULL OR i.data = '' THEN '{}' ELSE i.data END,
    '$.fields',
    COALESCE(
      JSON_EXTRACT(CASE WHEN i.data IS NULL OR i.data = '' THEN '{}' ELSE i.data END, '$.fields'),
      JSON_OBJECT()
    )
  ),
  '$.fields.primaryIpAddress',
  c.repair_ip
);

SELECT ROW_COUNT() AS repaired_primary_ip_rows;

SELECT COUNT(*) AS remaining_blank_with_ip_count
FROM instance i
JOIN instance_host_map ihm ON ihm.instance_id = i.id AND ihm.removed IS NULL
LEFT JOIN nic n ON n.instance_id = i.id AND n.device_number = 0 AND n.removed IS NULL
LEFT JOIN ip_address_nic_map inm ON inm.nic_id = n.id AND inm.removed IS NULL
LEFT JOIN ip_address ip ON ip.id = inm.ip_address_id AND ip.removed IS NULL
WHERE i.removed IS NULL
  AND i.state IN ('running', 'active')
  AND NULLIF(JSON_UNQUOTE(JSON_EXTRACT(i.data, '$.fields.primaryIpAddress')), '') IS NULL
  AND COALESCE(
    NULLIF(JSON_UNQUOTE(JSON_EXTRACT(i.data, '$.fields.dockerIp')), ''),
    NULLIF(ip.address, '')
  ) IS NOT NULL;

DROP TEMPORARY TABLE pasturestack_primary_ip_repair_candidates;
SQL
    secure_backup_files "${BACKUP_DIR}/primary-ip-repair.txt"
    log "PRIMARY_IP_REPAIR_OK"
}

http_check() {
    local path="$1"
    local allowed="$2"
    local code
    code="$(migration_curl -o /dev/null -w '%{http_code}' "http://127.0.0.1:${HOST_HTTP_PORT}${path}")"
    echo "${path} ${code} allowed=${allowed}" | tee -a "${BACKUP_DIR}/http-checks.txt"
    case " ${allowed} " in
        *" ${code} "*) return 0 ;;
        *) die "unexpected HTTP ${code} for ${path}; allowed=${allowed}" ;;
    esac
}

post_validate() {
    log "POST_VALIDATE_START"
    : > "${BACKUP_DIR}/http-checks.txt"
    secure_backup_files "${BACKUP_DIR}/http-checks.txt"
    http_check / "200 401"
    http_check /index.html "200"
    http_check /v2-beta "200 401"
    http_check /v2-beta/projects "200 401"
    http_check "/v2-beta/projects/${RANCHER_PROJECT_ID}/hosts" "200 401"
    http_check "/v2-beta/projects/${RANCHER_PROJECT_ID}/stacks" "200 401"
    http_check "/env/${RANCHER_PROJECT_ID}/apps/stacks?which=infra" "200"

    docker exec -i "$NEW_CONTAINER" sh -c "mariadb --protocol=socket --socket=/var/run/mysqld/mysqld.sock -uroot cattle" <<'SQL' | tee "${BACKUP_DIR}/post-migration-db.txt"
select @@version as db_version;
select id,name,state,agent_id,removed from host order by id;
select id,name,state,health_state,kind,removed from service where removed is null order by id;
select name,value from setting where name in ('agent.image','bootstrap.required.image','agent.package.python.agent.url','agent.package.host.api.url','catalog.url','lb.instance.image','lb.instance.image.uuid','api.security.enabled','api.auth.provider.configured') order by name;
SQL
    secure_backup_files "${BACKUP_DIR}/post-migration-db.txt"

    docker ps --format '{{.Names}} {{.Image}} {{.Status}}' > "${BACKUP_DIR}/docker-ps-after.txt"
    migration_curl -o "${BACKUP_DIR}/live-v2-beta.json" -w '%{http_code}\n' "http://127.0.0.1:${HOST_HTTP_PORT}/v2-beta" > "${BACKUP_DIR}/live-v2-beta.http_code"
    secure_backup_files \
        "${BACKUP_DIR}/docker-ps-after.txt" \
        "${BACKUP_DIR}/live-v2-beta.json" \
        "${BACKUP_DIR}/live-v2-beta.http_code" \
        "${BACKUP_DIR}/http-checks.txt"
    log "POST_VALIDATE_OK"
}


recycle_ipsec_after_migration() {
    case "$RECYCLE_IPSEC_AFTER_MIGRATION" in
        false|no|0)
            log "IPSEC_RECYCLE_SKIPPED disabled"
            return 0
            ;;
        auto|true|yes|1|require)
            ;;
        *)
            die "invalid RECYCLE_IPSEC_AFTER_MIGRATION=${RECYCLE_IPSEC_AFTER_MIGRATION}"
            ;;
    esac

    if ! command -v python3 >/dev/null 2>&1; then
        if [ "$RECYCLE_IPSEC_AFTER_MIGRATION" = "require" ]; then
            die "python3 is required for ipsec service recycle"
        fi
        log "IPSEC_RECYCLE_SKIPPED python3 not found"
        return 0
    fi

    log "IPSEC_RECYCLE_START project=${RANCHER_PROJECT_ID}"
    if python3 - "$HOST_HTTP_PORT" "$RANCHER_PROJECT_ID" "$BACKUP_DIR/ipsec-recycle.txt" "$(preserved_env_file)" "$(ipsec_recycle_auth_file)" <<'PY'
import base64
import json
import sys
import time
import urllib.error
import urllib.request

port, project, output, env_path, auth_path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
base = f"http://127.0.0.1:{port}/v2-beta/projects/{project}"
auth_header = None
env = {}
for path in (env_path, auth_path):
    try:
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.rstrip("\n")
                if "=" in line:
                    k, v = line.split("=", 1)
                    env[k] = v
    except FileNotFoundError:
        pass

key = (
    env.get("RC16_RANCHER_ACCESS_KEY")
    or env.get("RANCHER_ACCESS_KEY")
    or env.get("CATTLE_ACCESS_KEY")
)
secret = (
    env.get("RC16_RANCHER_SECRET_KEY")
    or env.get("RANCHER_SECRET_KEY")
    or env.get("CATTLE_SECRET_KEY")
)
bearer = (
    env.get("RC16_RANCHER_BEARER_TOKEN")
    or env.get("RC16_RANCHER_TOKEN")
    or env.get("RANCHER_BEARER_TOKEN")
    or env.get("RANCHER_TOKEN")
)
if bearer:
    auth_header = "Bearer " + bearer
elif key and secret:
    token = base64.b64encode(f"{key}:{secret}".encode("utf-8")).decode("ascii")
    auth_header = "Basic " + token

def write(line):
    print(line)
    with open(output, "a", encoding="utf-8") as f:
        f.write(line + "\n")

def request_headers(extra=None):
    headers = dict(extra or {})
    if auth_header:
        headers["Authorization"] = auth_header
        headers["X-API-Project-Id"] = project
    return headers

def get_json(url):
    req = urllib.request.Request(url, headers=request_headers(), method="GET")
    with urllib.request.urlopen(req, timeout=20) as response:
        return json.loads(response.read().decode("utf-8"))

def post_json(url, payload):
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers=request_headers({"Content-Type": "application/json"}),
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as response:
        body = response.read().decode("utf-8")
        return json.loads(body) if body else {}

def http_error_summary(exc):
    try:
        body = exc.read().decode("utf-8", errors="replace")
    except Exception:
        body = ""
    return f"http_status={exc.code} body={body[:500]}"

if auth_header:
    write("IPSEC_RECYCLE_AUTH_AVAILABLE")
else:
    write("IPSEC_RECYCLE_AUTH_MISSING")

def restart_service_instances(service):
    instances_url = service.get("links", {}).get("instances")
    if not instances_url:
        write(f"IPSEC_RECYCLE_FALLBACK_SKIPPED service={service.get('id')} has no instances link")
        return False

    instances = get_json(instances_url).get("data", [])
    if not instances:
        write(f"IPSEC_RECYCLE_FALLBACK_SKIPPED service={service.get('id')} has no instances")
        return False

    restarted = False
    for instance in instances:
        restart = instance.get("actions", {}).get("restart")
        if not restart:
            write(
                "IPSEC_RECYCLE_FALLBACK_SKIP_INSTANCE "
                f"container={instance.get('id')} state={instance.get('state')}"
            )
            continue
        write(
            "IPSEC_RECYCLE_FALLBACK_RESTART_INSTANCE "
            f"container={instance.get('id')} name={instance.get('name')} host={instance.get('hostId')}"
        )
        for attempt in range(1, 4):
            try:
                post_json(restart, {})
                restarted = True
                break
            except urllib.error.HTTPError as exc:
                # the legacy platform may already be mutating this system container after
                # server cutover. Treat these as transient and let the convergence
                # loop below validate the final running state.
                write(
                    "IPSEC_RECYCLE_FALLBACK_RESTART_TRANSIENT "
                    f"container={instance.get('id')} attempt={attempt} {http_error_summary(exc)}"
                )
                restarted = True
                if exc.code not in (409, 422, 500):
                    break
                time.sleep(5)
            except Exception as exc:
                write(
                    "IPSEC_RECYCLE_FALLBACK_RESTART_TRANSIENT "
                    f"container={instance.get('id')} attempt={attempt} error={type(exc).__name__}: {exc}"
                )
                restarted = True
                time.sleep(5)
        time.sleep(3)

    return restarted

try:
    services = get_json(base + "/services?name=ipsec").get("data", [])
except urllib.error.HTTPError as exc:
    write(f"IPSEC_RECYCLE_UNAVAILABLE http_status={exc.code}")
    sys.exit(2)
except Exception as exc:
    write(f"IPSEC_RECYCLE_UNAVAILABLE error={type(exc).__name__}: {exc}")
    sys.exit(2)

if not services:
    write("IPSEC_RECYCLE_SKIPPED no ipsec service found")
    sys.exit(0)

service = services[0]
service_id = service.get("id")
restart_url = service.get("actions", {}).get("restart")
if not restart_url:
    write(f"IPSEC_RECYCLE_SKIPPED service={service_id} has no restart action")
    sys.exit(0)

write(f"IPSEC_RECYCLE_RESTART service={service_id} state={service.get('state')} health={service.get('healthState')}")
instance_restart = False
try:
    post_json(restart_url, {})
except urllib.error.HTTPError as exc:
    write(
        "IPSEC_RECYCLE_SERVICE_RESTART_FAILED "
        f"{http_error_summary(exc)}"
    )
    instance_restart = restart_service_instances(service)

deadline = time.time() + 360
while time.time() < deadline:
    time.sleep(5)
    if instance_restart:
        instances = get_json(service.get("links", {}).get("instances")).get("data", [])
        states = ",".join(f"{i.get('id')}:{i.get('state')}" for i in instances)
        active_instances = [i for i in instances if i.get("state") not in ("purged", "removed")]
        write(f"IPSEC_RECYCLE_WAIT_INSTANCES {states}")
        refreshed = get_json(base + f"/services/{service_id}")
        service_state = refreshed.get("state")
        service_health = refreshed.get("healthState")
        if (
            active_instances
            and all(i.get("state") == "running" for i in active_instances)
            and service_state == "active"
            and service_health in (None, "healthy")
        ):
            write("IPSEC_RECYCLE_OK")
            sys.exit(0)
        continue

    refreshed = get_json(base + f"/services/{service_id}")
    state = refreshed.get("state")
    health = refreshed.get("healthState")
    current_scale = refreshed.get("currentScale")
    write(f"IPSEC_RECYCLE_WAIT state={state} health={health} currentScale={current_scale}")
    if state == "active" and health in (None, "healthy"):
        write("IPSEC_RECYCLE_OK")
        sys.exit(0)

write("IPSEC_RECYCLE_TIMEOUT")
sys.exit(1)
PY
    then
        log "IPSEC_RECYCLE_OK"
        wait_ping "$HOST_HTTP_PORT" POST_IPSEC_RECYCLE 180
        return 0
    fi

    local status=$?
    if [ "$RECYCLE_IPSEC_AFTER_MIGRATION" = "require" ] || [ "$status" -eq 1 ]; then
        die "ipsec service recycle failed; see ${BACKUP_DIR}/ipsec-recycle.txt"
    fi

    log "IPSEC_RECYCLE_SKIPPED unavailable; see ${BACKUP_DIR}/ipsec-recycle.txt"
    return 0
}

do_migrate() {
    trap handle_migration_failure ERR
    confirm
    preflight
    create_backup
    init_new_volumes
    switch_server
    fix_persisted_settings
    repair_blank_primary_ip_addresses
    post_validate
    recycle_ipsec_after_migration
    post_validate
    cleanup_transient_containers
    cleanup_failed_agent_upgrade_helpers
    if [ "$KEEP_ROLLBACK_CONTAINER" = "true" ]; then
        log "ROLLBACK_CHECKPOINT_RETAINED checkpoint=${OLD_BACKUP}"
    else
        finalize_rollback_checkpoint
    fi
    write_final_inventory
    trap - ERR
    log "MIGRATION_SUCCESS backup_dir=${BACKUP_DIR}"
    log "Migration finalized; helper containers and failed volumes are cleaned automatically."
}

do_rollback() {
    load_rollback_env
    confirm
    rollback_from_current_run
}

do_verify_rollback_env() {
    load_rollback_env
    log "VERIFY_ROLLBACK_ENV_OK file=${ROLLBACK_ENV} backup_dir=${BACKUP_DIR}"
}

archive_path_from_checkpoint() {
    local container="$1"
    local source_path="$2"
    local target_name="$3"

    if docker run --rm --volumes-from "$container" ubuntu:26.04 \
        bash -lc "test -d '${source_path}'"; then
        docker run --rm --volumes-from "$container" -v "${BACKUP_DIR}/finalized-rollback-checkpoint:/backup" ubuntu:26.04 \
            bash -lc "tar -C '${source_path}' -cpf '/backup/${target_name}' ."
        sha256sum "${BACKUP_DIR}/finalized-rollback-checkpoint/${target_name}" >> \
            "${BACKUP_DIR}/finalized-rollback-checkpoint/SHA256SUMS"
    fi
}

finalize_rollback_checkpoint() {
    if ! docker ps -a --format '{{.Names}}' | grep -qx "$OLD_BACKUP"; then
        log "FINALIZE_SKIPPED rollback checkpoint not found: ${OLD_BACKUP}"
        return 0
    fi

    local archive_dir="${BACKUP_DIR}/finalized-rollback-checkpoint"
    mkdir -p "$archive_dir"

    log "FINALIZE_START checkpoint=${OLD_BACKUP}"
    docker inspect "$OLD_BACKUP" > "${archive_dir}/${OLD_BACKUP}.inspect.json"
    docker inspect "$OLD_BACKUP" --format '{{range .Mounts}}{{println .Type .Name .Source "->" .Destination}}{{end}}' > \
        "${archive_dir}/${OLD_BACKUP}.mounts.txt"
    docker ps -a --format '{{.Names}} {{.Image}} {{.Status}}' > "${archive_dir}/docker-ps-before-finalize.txt"
    : > "${archive_dir}/SHA256SUMS"

    archive_path_from_checkpoint "$OLD_BACKUP" /var/lib/cattle old-var-lib-cattle.tar
    archive_path_from_checkpoint "$OLD_BACKUP" /var/lib/mysql old-var-lib-mysql.tar
    archive_path_from_checkpoint "$OLD_BACKUP" /var/log/mysql old-var-log-mysql.tar

    cat > "${archive_dir}/README.txt" <<EOF
This directory archives the removed PastureStack Server rollback checkpoint.

Removed container: ${OLD_BACKUP}
The MySQL archive is old-format rollback material only.
Do not mount old-var-lib-mysql.tar contents into ${NEW_IMAGE}.
EOF

    local old_volumes
    old_volumes="$(docker inspect "$OLD_BACKUP" --format '{{range .Mounts}}{{if eq .Type "volume"}}{{println .Name}}{{end}}{{end}}')"
    docker rm -v "$OLD_BACKUP" >/dev/null

    echo "$old_volumes" | while read -r volume; do
        [ -n "$volume" ] && remove_volume_if_unused "$volume"
    done

    log "FINALIZE_OK checkpoint=${OLD_BACKUP} archive=${archive_dir}"
}

do_finalize() {
    load_rollback_env
    confirm
    migration_curl -f "http://127.0.0.1:${HOST_HTTP_PORT}/ping" >/dev/null
    finalize_rollback_checkpoint
}

do_recycle_ipsec() {
    confirm
    mkdir -p "$BACKUP_DIR"
    write_preserved_env_file
    write_ipsec_recycle_auth_file
    recycle_ipsec_after_migration
    post_validate
    log "RECYCLE_IPSEC_ACTION_OK backup_dir=${BACKUP_DIR}"
}

do_cleanup() {
    log "CLEANUP_START"
    docker rm -f "$PREP_CONTAINER" "$IMPORT_CONTAINER" >/dev/null 2>&1 || true
    docker ps -a --format '{{.Names}}' | { grep '^pasturestack-migrate-' || true; } | while read -r name; do
        [ -n "$name" ] && docker rm -f "$name" >/dev/null 2>&1 || true
    done
    docker ps -a --filter "label=io.pasturestack.migration.role=prep" --format '{{.Names}}' | while read -r name; do
        [ -n "$name" ] && remove_container_if_exists "$name"
    done
    docker ps -a --filter "label=io.pasturestack.migration.role=import" --format '{{.Names}}' | while read -r name; do
        [ -n "$name" ] && remove_container_if_exists "$name"
    done
    docker volume ls --filter "label=io.pasturestack.migration.run_id" --format '{{.Name}}' | while read -r volume; do
        [ -n "$volume" ] && remove_volume_if_unused "$volume"
    done
    cleanup_failed_agent_upgrade_helpers

    if [ -d "$BACKUP_ROOT" ] && [ "$KEEP_BACKUPS" -gt 0 ]; then
        find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' |
            sort -rn |
            awk -v keep="$KEEP_BACKUPS" 'NR > keep {print $2}' |
            while read -r old_backup_dir; do
                log "removing old backup dir ${old_backup_dir}"
                rm -rf "$old_backup_dir"
            done
    fi
    log "CLEANUP_OK"
}

case "$ACTION" in
    preflight)
        acquire_lock
        normalize_artifact_settings
        preflight
        ;;
    backup)
        acquire_lock
        confirm
        normalize_artifact_settings
        preflight
        create_backup
        ;;
    verify-backup)
        acquire_lock
        verify_backup_bundle
        ;;
    verify-rollback-env)
        acquire_lock
        do_verify_rollback_env
        ;;
    migrate)
        acquire_lock
        normalize_artifact_settings
        do_migrate
        ;;
    rollback)
        acquire_lock
        do_rollback
        ;;
    finalize)
        acquire_lock
        do_finalize
        ;;
    recycle-ipsec)
        acquire_lock
        do_recycle_ipsec
        ;;
    cleanup)
        acquire_lock
        do_cleanup
        ;;
    *)
        echo "Unknown action: ${ACTION}" >&2
        usage >&2
        exit 1
        ;;
esac

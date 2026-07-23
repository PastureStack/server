#!/usr/bin/env bash
set -Eeuo pipefail

# Migrate only the persisted distribution coordinates owned by PastureStack.
# Audit is the default and never writes to the database. Apply and rollback
# require --yes and create or consume a mode-0600 rollback bundle.

ACTION="audit"
if [ $# -gt 0 ] && [[ "$1" != -* ]]; then
    ACTION="$1"
    shift
fi

CONTAINER="${PASTURESTACK_SERVER_CONTAINER:-pasturestack-server}"
BACKUP_ROOT="${BACKUP_ROOT:-${PWD}/pasturestack-distribution-backups}"
BACKUP_DIR="${BACKUP_DIR:-}"
REQUIRE_CONFIRM=true
RESTART_SERVER=false
NETWORK_CHECKS=true
READY_TIMEOUT="${PASTURESTACK_READY_TIMEOUT:-240}"
RELEASE_TAG="${PASTURESTACK_RELEASE_TAG:-}"

APPROVED_AGENT_IMAGE="ghcr.io/pasturestack/node-agent:v1.2.30@sha256:5310b748fc52bcd87fdeaa2285f424a07ec13c9b41639692eef96bda53ac8277"
APPROVED_LB_IMAGE="ghcr.io/pasturestack/load-balancer-service:v0.9.23@sha256:3139b2a54688e4e34b24df943a36a2ed1eecc26d53c0ab329bf7ffcb62cdb893"
APPROVED_LB_IMAGE_UUID="docker:${APPROVED_LB_IMAGE}"
APPROVED_CATALOG_URL="https://github.com/PastureStack/catalog-templates.git"
APPROVED_CATALOG_BRANCH="main"
APPROVED_CATALOG_COMMIT="91f5910a44cb181051be2adc4c14f0e6ec7842ef"
APPROVED_CATALOG_JSON="{\"catalogs\":{\"pasturestack\":{\"url\":\"${APPROVED_CATALOG_URL}\",\"branch\":\"${APPROVED_CATALOG_BRANCH}\",\"pinnedCommit\":\"${APPROVED_CATALOG_COMMIT}\"}}}"

usage() {
    cat <<'EOF_USAGE'
Usage:
  migrate-approved-runtime-coordinates.sh [audit|apply|verify|rollback] [options]

Actions:
  audit       Classify the persisted Runtime, download, and Catalog coordinates.
              This is the default and never writes to the database.
  apply       Back up affected rows, migrate the allowlist, and verify it.
  verify      Verify the database values and public GitHub/GHCR resources.
  rollback    Restore the exact affected rows from --backup-dir/rollback.sql.

Options:
  --container NAME       Running PastureStack Server container.
  --backup-root DIR      Parent directory for a new apply rollback bundle.
  --backup-dir DIR       Exact rollback bundle for rollback.
  --release-tag TAG      GitHub Release tag for flat CLI and Runtime assets.
                         Defaults to the version declared by the container.
  --restart              Restart the selected container and wait for /ping.
  --skip-network-checks  Verify the database only.
  --timeout SECONDS      Restart readiness timeout. Default 240.
  --yes                  Required for apply and rollback.

The script supports the embedded MariaDB socket and the external-DB environment
variables used by the non-root Server variant. It never prints DB passwords,
credential values, registration commands, or the previous coordinate values.
EOF_USAGE
}

die() {
    printf 'ERROR %s\n' "$*" >&2
    exit 1
}

while [ $# -gt 0 ]; do
    case "$1" in
        --container) CONTAINER="$2"; shift ;;
        --backup-root) BACKUP_ROOT="$2"; shift ;;
        --backup-dir) BACKUP_DIR="$2"; shift ;;
        --release-tag) RELEASE_TAG="$2"; shift ;;
        --restart) RESTART_SERVER=true ;;
        --skip-network-checks) NETWORK_CHECKS=false ;;
        --timeout) READY_TIMEOUT="$2"; shift ;;
        --yes) REQUIRE_CONFIRM=false ;;
        --help|-h) usage; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
    shift
done

case "$ACTION" in
    audit|apply|verify|rollback) ;;
    *) die "unknown action: $ACTION" ;;
esac

case "$READY_TIMEOUT" in
    *[!0-9]*|"") die "--timeout must be a positive integer" ;;
esac
[ "$READY_TIMEOUT" -gt 0 ] || die "--timeout must be a positive integer"

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "$1 is required"
}

confirm_write() {
    [ "$REQUIRE_CONFIRM" = false ] || die "$ACTION requires --yes"
}

container_declared_version() {
    docker inspect "$CONTAINER" --format '{{range .Config.Env}}{{println .}}{{end}}' |
        sed -n 's/^CATTLE_RANCHER_SERVER_VERSION=//p' |
        tail -n 1
}

resolve_release_tag() {
    if [ -z "$RELEASE_TAG" ]; then
        RELEASE_TAG="$(container_declared_version)"
    fi
    [[ "$RELEASE_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9._-]+)?$ ]] ||
        die "invalid release tag: ${RELEASE_TAG:-empty}"
    RELEASE_BASE_URL="https://github.com/PastureStack/server/releases/download/${RELEASE_TAG}"
    APPROVED_HOST_API_URL="${RELEASE_BASE_URL}/host-api-0.38.4.tar.gz"
    APPROVED_NODE_AGENT_URL="${RELEASE_BASE_URL}/node-agent-0.13.21.tar.gz"
    APPROVED_CLI_LINUX_URL="${RELEASE_BASE_URL}/pasturestack-cli-0.6.14-linux-amd64.tar.gz"
    APPROVED_CLI_DARWIN_URL="${RELEASE_BASE_URL}/pasturestack-cli-0.6.14-darwin-amd64.tar.gz"
    APPROVED_CLI_WINDOWS_URL="${RELEASE_BASE_URL}/pasturestack-cli-0.6.14-windows-amd64.zip"
    APPROVED_COMPOSE_LINUX_URL="${RELEASE_BASE_URL}/compose-cli-0.14.31-linux-amd64.tar.gz"
    APPROVED_COMPOSE_DARWIN_URL="${RELEASE_BASE_URL}/compose-cli-0.14.31-darwin-amd64.tar.gz"
    APPROVED_COMPOSE_WINDOWS_URL="${RELEASE_BASE_URL}/compose-cli-0.14.31-windows-amd64.zip"
}

db_exec() {
    docker exec -i "$CONTAINER" sh -ec '
        db_name=${CATTLE_DB_CATTLE_MYSQL_NAME:-cattle}
        db_host=${CATTLE_DB_CATTLE_MYSQL_HOST:-}
        if [ -n "$db_host" ] && [ "$db_host" != localhost ] && [ "$db_host" != 127.0.0.1 ]; then
            export MYSQL_PWD=${CATTLE_DB_CATTLE_PASSWORD:-cattle}
            exec mariadb --protocol=tcp \
                --connect-timeout=10 \
                -h "$db_host" \
                -P "${CATTLE_DB_CATTLE_MYSQL_PORT:-3306}" \
                -u "${CATTLE_DB_CATTLE_USERNAME:-cattle}" \
                --batch --raw --skip-column-names "$db_name"
        fi
        exec mariadb --protocol=socket \
            --socket=/var/run/mysqld/mysqld.sock \
            -uroot --batch --raw --skip-column-names "$db_name"
    ' 2> >(
        sed '/^WARNING: option --ssl-verify-server-cert is disabled, because of an insecure passwordless login\.$/d' >&2
    )
}

db_query() {
    printf '%s\n' "$1" | db_exec
}

db_scalar() {
    local value
    value="$(db_query "$1" | tail -n 1)"
    printf '%s\n' "$value"
}

wait_database() {
    local i
    for i in $(seq 1 60); do
        if [ "$(db_scalar "SELECT 1;" 2>/dev/null || true)" = 1 ]; then
            return 0
        fi
        sleep 1
    done
    die "database did not become ready"
}

preflight() {
    require_command docker
    docker inspect "$CONTAINER" >/dev/null 2>&1 || die "container not found: $CONTAINER"
    [ "$(docker inspect "$CONTAINER" --format '{{.State.Running}}')" = true ] ||
        die "container is not running: $CONTAINER"
    resolve_release_tag
    wait_database

    local required_tables duplicate_settings catalog_candidates
    required_tables="$(db_scalar "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name IN ('setting','catalog');")"
    [ "$required_tables" = 2 ] || die "setting and catalog tables are required"

    duplicate_settings="$(db_scalar "
        SELECT COUNT(*) - COUNT(DISTINCT name)
        FROM setting
        WHERE name IN (
          'access.log',
          'account.type.admin.all.accounts',
          'account.type.admin.list.all.accounts',
          'account.type.admin.list.all.settings',
          'agent.image',
          'agent.package.host.api.url',
          'agent.package.python.agent.url',
          'bootstrap.required.image',
          'catalog.url',
          'lb.instance.image',
          'lb.instance.image.uuid',
          'rancher.cli.linux.url',
          'rancher.cli.darwin.url',
          'rancher.cli.windows.url',
          'rancher.compose.linux.url',
          'rancher.compose.darwin.url',
          'rancher.compose.windows.url'
        );")"
    [ "$duplicate_settings" = 0 ] ||
        die "duplicate allowlisted setting names must be resolved before migration"

    catalog_candidates="$(db_scalar "
        SELECT COUNT(*)
        FROM catalog
        WHERE (
          name IN ('library','pasturestack')
          OR url REGEXP '^https?://(10\\\\.|127\\\\.|192\\\\.168\\\\.|172\\\\.(1[6-9]|2[0-9]|3[01])\\\\.|localhost)'
          OR url LIKE '%/rancher-catalog.git'
        )
        AND NOT (
          name='pasturestack'
          AND url='${APPROVED_CATALOG_URL}'
          AND branch='${APPROVED_CATALOG_BRANCH}'
          AND commit='${APPROVED_CATALOG_COMMIT}'
        );")"
    [ "$catalog_candidates" -le 1 ] ||
        die "more than one default Catalog row requires migration; review it manually"
}

audit_database() {
    printf 'AUDIT container=%s release=%s\n' "$CONTAINER" "$RELEASE_TAG"
    db_query "
        SELECT name,
          CASE
            WHEN name='agent.image' AND value='${APPROVED_AGENT_IMAGE}' THEN 'approved'
            WHEN name='agent.package.host.api.url' AND value='${APPROVED_HOST_API_URL}' THEN 'approved'
            WHEN name='agent.package.python.agent.url' AND value='${APPROVED_NODE_AGENT_URL}' THEN 'approved'
            WHEN name='bootstrap.required.image' AND value='${APPROVED_AGENT_IMAGE}' THEN 'approved'
            WHEN name='catalog.url' AND value='${APPROVED_CATALOG_JSON}' THEN 'approved'
            WHEN name='lb.instance.image' AND value='${APPROVED_LB_IMAGE}' THEN 'approved'
            WHEN name='lb.instance.image.uuid' AND value='${APPROVED_LB_IMAGE_UUID}' THEN 'approved'
            WHEN name='rancher.cli.linux.url' AND value='${APPROVED_CLI_LINUX_URL}' THEN 'approved'
            WHEN name='rancher.cli.darwin.url' AND value='${APPROVED_CLI_DARWIN_URL}' THEN 'approved'
            WHEN name='rancher.cli.windows.url' AND value='${APPROVED_CLI_WINDOWS_URL}' THEN 'approved'
            WHEN name='rancher.compose.linux.url' AND value='${APPROVED_COMPOSE_LINUX_URL}' THEN 'approved'
            WHEN name='rancher.compose.darwin.url' AND value='${APPROVED_COMPOSE_DARWIN_URL}' THEN 'approved'
            WHEN name='rancher.compose.windows.url' AND value='${APPROVED_COMPOSE_WINDOWS_URL}' THEN 'approved'
            WHEN name IN (
              'access.log',
              'account.type.admin.all.accounts',
              'account.type.admin.list.all.accounts',
              'account.type.admin.list.all.settings'
            ) AND value REGEXP '^(docker:)?(ghcr\\\\.io|docker\\\\.io)/' THEN 'invalid_image_value'
            WHEN name IN (
              'access.log',
              'account.type.admin.all.accounts',
              'account.type.admin.list.all.accounts',
              'account.type.admin.list.all.settings'
            ) THEN 'valid_non_coordinate'
            ELSE 'migration_required'
          END AS status
        FROM setting
        WHERE name IN (
          'access.log',
          'account.type.admin.all.accounts',
          'account.type.admin.list.all.accounts',
          'account.type.admin.list.all.settings',
          'agent.image',
          'agent.package.host.api.url',
          'agent.package.python.agent.url',
          'bootstrap.required.image',
          'catalog.url',
          'lb.instance.image',
          'lb.instance.image.uuid',
          'rancher.cli.linux.url',
          'rancher.cli.darwin.url',
          'rancher.cli.windows.url',
          'rancher.compose.linux.url',
          'rancher.compose.darwin.url',
          'rancher.compose.windows.url'
        )
        ORDER BY name;"
    db_query "
        SELECT CONCAT('catalog:',COALESCE(name,'unnamed')),
          CASE
            WHEN url='${APPROVED_CATALOG_URL}'
             AND branch='${APPROVED_CATALOG_BRANCH}'
             AND commit='${APPROVED_CATALOG_COMMIT}'
              THEN 'approved'
            ELSE 'migration_required'
          END
        FROM catalog
        ORDER BY id;"
}

catalog_migration_predicate() {
    cat <<EOF
(
  name IN ('library','pasturestack')
  OR url REGEXP '^https?://(10\\\\.|127\\\\.|192\\\\.168\\\\.|172\\\\.(1[6-9]|2[0-9]|3[01])\\\\.|localhost)'
  OR url LIKE '%/rancher-catalog.git'
)
AND NOT (
  name='pasturestack'
  AND url='${APPROVED_CATALOG_URL}'
  AND branch='${APPROVED_CATALOG_BRANCH}'
  AND commit='${APPROVED_CATALOG_COMMIT}'
)
EOF
}

create_rollback_bundle() {
    local ts catalog_predicate catalog_ids
    ts="$(date -u +%Y%m%dT%H%M%SZ)"
    if [ -z "$BACKUP_DIR" ]; then
        BACKUP_DIR="${BACKUP_ROOT%/}/runtime-coordinate-${ts}"
    fi
    [ ! -e "$BACKUP_DIR" ] || die "backup directory already exists: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"

    catalog_predicate="$(catalog_migration_predicate)"
    db_query "
        SELECT id,HEX(name),HEX(value)
        FROM setting
        WHERE name IN (
          'access.log',
          'account.type.admin.all.accounts',
          'account.type.admin.list.all.accounts',
          'account.type.admin.list.all.settings',
          'agent.image',
          'agent.package.host.api.url',
          'agent.package.python.agent.url',
          'bootstrap.required.image',
          'catalog.url',
          'lb.instance.image',
          'lb.instance.image.uuid',
          'rancher.cli.linux.url',
          'rancher.cli.darwin.url',
          'rancher.cli.windows.url',
          'rancher.compose.linux.url',
          'rancher.compose.darwin.url',
          'rancher.compose.windows.url'
        )
        ORDER BY id;" > "${BACKUP_DIR}/setting-before.tsv"

    db_query "
        SELECT id,
          IFNULL(HEX(created_at),'NULL'),
          IFNULL(HEX(updated_at),'NULL'),
          IFNULL(HEX(environment_id),'NULL'),
          IFNULL(HEX(name),'NULL'),
          IFNULL(HEX(url),'NULL'),
          IFNULL(HEX(branch),'NULL'),
          IFNULL(HEX(commit),'NULL'),
          IFNULL(HEX(type),'NULL'),
          IFNULL(HEX(kind),'NULL')
        FROM catalog
        WHERE ${catalog_predicate}
           OR (name='pasturestack' AND url='${APPROVED_CATALOG_URL}')
        ORDER BY id;" > "${BACKUP_DIR}/catalog-before.tsv"

    {
        printf 'START TRANSACTION;\n'
        printf "DELETE FROM setting WHERE name IN ('access.log','account.type.admin.all.accounts','account.type.admin.list.all.accounts','account.type.admin.list.all.settings','agent.image','agent.package.host.api.url','agent.package.python.agent.url','bootstrap.required.image','catalog.url','lb.instance.image','lb.instance.image.uuid','rancher.cli.linux.url','rancher.cli.darwin.url','rancher.cli.windows.url','rancher.compose.linux.url','rancher.compose.darwin.url','rancher.compose.windows.url');\n"
        while IFS=$'\t' read -r id name_hex value_hex; do
            [ -n "$id" ] || continue
            printf "INSERT INTO setting (id,name,value) VALUES (%s,UNHEX('%s'),UNHEX('%s'));\n" \
                "$id" "$name_hex" "$value_hex"
        done < "${BACKUP_DIR}/setting-before.tsv"

        catalog_ids="$(cut -f1 "${BACKUP_DIR}/catalog-before.tsv" | paste -sd, -)"
        if [ -n "$catalog_ids" ]; then
            printf "DELETE FROM catalog WHERE id IN (%s) OR (name='pasturestack' AND url='%s');\n" \
                "$catalog_ids" "$APPROVED_CATALOG_URL"
        else
            printf "DELETE FROM catalog WHERE name='pasturestack' AND url='%s';\n" \
                "$APPROVED_CATALOG_URL"
        fi

        while IFS=$'\t' read -r id created updated environment name url branch commit type kind; do
            [ -n "$id" ] || continue
            for field in created updated environment name url branch commit type kind; do
                value="${!field}"
                if [ "$value" = NULL ]; then
                    printf -v "$field" '%s' NULL
                else
                    printf -v "$field" "UNHEX('%s')" "$value"
                fi
            done
            printf 'INSERT INTO catalog (id,created_at,updated_at,environment_id,name,url,branch,commit,type,kind) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);\n' \
                "$id" "$created" "$updated" "$environment" "$name" "$url" "$branch" "$commit" "$type" "$kind"
        done < "${BACKUP_DIR}/catalog-before.tsv"
        printf 'COMMIT;\n'
    } > "${BACKUP_DIR}/rollback.sql"

    cat > "${BACKUP_DIR}/manifest.txt" <<EOF_MANIFEST
created_at=$(date -Is)
source_container=${CONTAINER}
source_container_id=$(docker inspect "$CONTAINER" --format '{{.Id}}')
release_tag=${RELEASE_TAG}
scope=allowlisted-runtime-download-catalog-and-known-corrupted-settings
rollback_file=rollback.sql
EOF_MANIFEST

    audit_database > "${BACKUP_DIR}/audit-before.tsv"
    chmod 600 "${BACKUP_DIR}"/*
    (cd "$BACKUP_DIR" && sha256sum setting-before.tsv catalog-before.tsv rollback.sql manifest.txt audit-before.tsv > SHA256SUMS)
    chmod 600 "${BACKUP_DIR}/SHA256SUMS"
}

apply_database_changes() {
    local catalog_predicate
    catalog_predicate="$(catalog_migration_predicate)"
    db_query "
        START TRANSACTION;

        UPDATE setting SET value='${APPROVED_AGENT_IMAGE}' WHERE name='agent.image';
        INSERT INTO setting (name,value)
          SELECT 'agent.image','${APPROVED_AGENT_IMAGE}'
          WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='agent.image');

        UPDATE setting SET value='${APPROVED_HOST_API_URL}' WHERE name='agent.package.host.api.url';
        INSERT INTO setting (name,value)
          SELECT 'agent.package.host.api.url','${APPROVED_HOST_API_URL}'
          WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='agent.package.host.api.url');

        UPDATE setting SET value='${APPROVED_NODE_AGENT_URL}' WHERE name='agent.package.python.agent.url';
        INSERT INTO setting (name,value)
          SELECT 'agent.package.python.agent.url','${APPROVED_NODE_AGENT_URL}'
          WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='agent.package.python.agent.url');

        UPDATE setting SET value='${APPROVED_AGENT_IMAGE}' WHERE name='bootstrap.required.image';
        INSERT INTO setting (name,value)
          SELECT 'bootstrap.required.image','${APPROVED_AGENT_IMAGE}'
          WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='bootstrap.required.image');

        UPDATE setting SET value='${APPROVED_LB_IMAGE}' WHERE name='lb.instance.image';
        INSERT INTO setting (name,value)
          SELECT 'lb.instance.image','${APPROVED_LB_IMAGE}'
          WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='lb.instance.image');

        UPDATE setting SET value='${APPROVED_LB_IMAGE_UUID}' WHERE name='lb.instance.image.uuid';
        INSERT INTO setting (name,value)
          SELECT 'lb.instance.image.uuid','${APPROVED_LB_IMAGE_UUID}'
          WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='lb.instance.image.uuid');

        UPDATE setting SET value='${APPROVED_CATALOG_JSON}' WHERE name='catalog.url';
        INSERT INTO setting (name,value)
          SELECT 'catalog.url','${APPROVED_CATALOG_JSON}'
          WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='catalog.url');

        UPDATE setting SET value='${APPROVED_CLI_LINUX_URL}' WHERE name='rancher.cli.linux.url';
        INSERT INTO setting (name,value)
          SELECT 'rancher.cli.linux.url','${APPROVED_CLI_LINUX_URL}'
          WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='rancher.cli.linux.url');

        UPDATE setting SET value='${APPROVED_CLI_DARWIN_URL}' WHERE name='rancher.cli.darwin.url';
        INSERT INTO setting (name,value)
          SELECT 'rancher.cli.darwin.url','${APPROVED_CLI_DARWIN_URL}'
          WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='rancher.cli.darwin.url');

        UPDATE setting SET value='${APPROVED_CLI_WINDOWS_URL}' WHERE name='rancher.cli.windows.url';
        INSERT INTO setting (name,value)
          SELECT 'rancher.cli.windows.url','${APPROVED_CLI_WINDOWS_URL}'
          WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='rancher.cli.windows.url');

        UPDATE setting SET value='${APPROVED_COMPOSE_LINUX_URL}' WHERE name='rancher.compose.linux.url';
        INSERT INTO setting (name,value)
          SELECT 'rancher.compose.linux.url','${APPROVED_COMPOSE_LINUX_URL}'
          WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='rancher.compose.linux.url');

        UPDATE setting SET value='${APPROVED_COMPOSE_DARWIN_URL}' WHERE name='rancher.compose.darwin.url';
        INSERT INTO setting (name,value)
          SELECT 'rancher.compose.darwin.url','${APPROVED_COMPOSE_DARWIN_URL}'
          WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='rancher.compose.darwin.url');

        UPDATE setting SET value='${APPROVED_COMPOSE_WINDOWS_URL}' WHERE name='rancher.compose.windows.url';
        INSERT INTO setting (name,value)
          SELECT 'rancher.compose.windows.url','${APPROVED_COMPOSE_WINDOWS_URL}'
          WHERE NOT EXISTS (SELECT 1 FROM setting WHERE name='rancher.compose.windows.url');

        UPDATE setting
          SET value='/dev/null'
          WHERE name='access.log'
            AND value REGEXP '^(docker:)?(ghcr\\\\.io|docker\\\\.io)/';
        UPDATE setting
          SET value='true'
          WHERE name IN (
            'account.type.admin.all.accounts',
            'account.type.admin.list.all.accounts',
            'account.type.admin.list.all.settings'
          )
            AND value REGEXP '^(docker:)?(ghcr\\\\.io|docker\\\\.io)/';

        UPDATE catalog
          SET name='pasturestack',
              url='${APPROVED_CATALOG_URL}',
              branch='${APPROVED_CATALOG_BRANCH}',
              commit='${APPROVED_CATALOG_COMMIT}',
              updated_at=UTC_TIMESTAMP()
          WHERE ${catalog_predicate};

        INSERT INTO catalog (created_at,updated_at,name,url,branch,commit)
          SELECT UTC_TIMESTAMP(),UTC_TIMESTAMP(),'pasturestack',
                 '${APPROVED_CATALOG_URL}',
                 '${APPROVED_CATALOG_BRANCH}',
                 '${APPROVED_CATALOG_COMMIT}'
          WHERE NOT EXISTS (
            SELECT 1 FROM catalog
            WHERE name='pasturestack'
              AND url='${APPROVED_CATALOG_URL}'
              AND branch='${APPROVED_CATALOG_BRANCH}'
              AND commit='${APPROVED_CATALOG_COMMIT}'
          );

        COMMIT;"
}

verify_database() {
    local approved_settings invalid_repair_values approved_catalogs
    approved_settings="$(db_scalar "
        SELECT COUNT(*) FROM setting WHERE
          (name='agent.image' AND value='${APPROVED_AGENT_IMAGE}') OR
          (name='agent.package.host.api.url' AND value='${APPROVED_HOST_API_URL}') OR
          (name='agent.package.python.agent.url' AND value='${APPROVED_NODE_AGENT_URL}') OR
          (name='bootstrap.required.image' AND value='${APPROVED_AGENT_IMAGE}') OR
          (name='catalog.url' AND value='${APPROVED_CATALOG_JSON}') OR
          (name='lb.instance.image' AND value='${APPROVED_LB_IMAGE}') OR
          (name='lb.instance.image.uuid' AND value='${APPROVED_LB_IMAGE_UUID}') OR
          (name='rancher.cli.linux.url' AND value='${APPROVED_CLI_LINUX_URL}') OR
          (name='rancher.cli.darwin.url' AND value='${APPROVED_CLI_DARWIN_URL}') OR
          (name='rancher.cli.windows.url' AND value='${APPROVED_CLI_WINDOWS_URL}') OR
          (name='rancher.compose.linux.url' AND value='${APPROVED_COMPOSE_LINUX_URL}') OR
          (name='rancher.compose.darwin.url' AND value='${APPROVED_COMPOSE_DARWIN_URL}') OR
          (name='rancher.compose.windows.url' AND value='${APPROVED_COMPOSE_WINDOWS_URL}');")"
    [ "$approved_settings" = 13 ] ||
        die "expected 13 approved persisted coordinates, found $approved_settings"

    invalid_repair_values="$(db_scalar "
        SELECT COUNT(*) FROM setting
        WHERE name IN (
          'access.log',
          'account.type.admin.all.accounts',
          'account.type.admin.list.all.accounts',
          'account.type.admin.list.all.settings'
        )
        AND value REGEXP '^(docker:)?(ghcr\\\\.io|docker\\\\.io)/';")"
    [ "$invalid_repair_values" = 0 ] ||
        die "known non-coordinate settings still contain image references"

    approved_catalogs="$(db_scalar "
        SELECT COUNT(*) FROM catalog
        WHERE name='pasturestack'
          AND url='${APPROVED_CATALOG_URL}'
          AND branch='${APPROVED_CATALOG_BRANCH}'
          AND commit='${APPROVED_CATALOG_COMMIT}';")"
    [ "$approved_catalogs" = 1 ] ||
        die "expected exactly one pinned PastureStack Catalog row, found $approved_catalogs"

    printf 'DATABASE_VERIFY_OK approved_settings=%s repaired_invalid_values=0 approved_catalogs=%s\n' \
        "$approved_settings" "$approved_catalogs"
}

verify_public_resources() {
    [ "$NETWORK_CHECKS" = true ] || {
        printf 'NETWORK_VERIFY_SKIPPED\n'
        return
    }
    require_command curl
    require_command git

    local url
    for url in \
        "$APPROVED_HOST_API_URL" \
        "$APPROVED_NODE_AGENT_URL" \
        "$APPROVED_CLI_LINUX_URL" \
        "$APPROVED_CLI_DARWIN_URL" \
        "$APPROVED_CLI_WINDOWS_URL" \
        "$APPROVED_COMPOSE_LINUX_URL" \
        "$APPROVED_COMPOSE_DARWIN_URL" \
        "$APPROVED_COMPOSE_WINDOWS_URL"; do
        curl -fsSL --retry 3 --retry-all-errors --connect-timeout 10 --max-time 120 \
            --range 0-0 -o /dev/null "$url"
    done

    local image expected_digest observed_digest
    for image in "$APPROVED_AGENT_IMAGE" "$APPROVED_LB_IMAGE"; do
        expected_digest="${image##*@}"
        observed_digest="$(docker buildx imagetools inspect "$image" --format '{{.Manifest.Digest}}')"
        [ "$observed_digest" = "$expected_digest" ] ||
            die "image manifest digest mismatch for ${image%%@*}"
    done

    local catalog_tmp fetched_commit
    catalog_tmp="$(mktemp -d "${TMPDIR:-/tmp}/pasturestack-catalog-verify.XXXXXX")"
    if ! git -C "$catalog_tmp" init -q ||
       ! git -C "$catalog_tmp" fetch -q --depth=1 "$APPROVED_CATALOG_URL" "$APPROVED_CATALOG_COMMIT"; then
        rm -rf -- "$catalog_tmp"
        die "approved Catalog commit is not anonymously fetchable"
    fi
    fetched_commit="$(git -C "$catalog_tmp" rev-parse FETCH_HEAD)"
    rm -rf -- "$catalog_tmp"
    [ "$fetched_commit" = "$APPROVED_CATALOG_COMMIT" ] ||
        die "fetched Catalog commit does not match the approved commit"

    printf 'PUBLIC_RESOURCES_VERIFY_OK assets=8 images=2 catalog_commit=%s\n' \
        "$APPROVED_CATALOG_COMMIT"
}

restart_and_wait() {
    [ "$RESTART_SERVER" = true ] || return 0
    docker restart "$CONTAINER" >/dev/null
    local i
    for i in $(seq 1 "$READY_TIMEOUT"); do
        if docker exec "$CONTAINER" curl -fsS --connect-timeout 2 --max-time 5 \
            http://127.0.0.1:8080/ping 2>/dev/null | grep -qx pong; then
            printf 'SERVER_RESTART_OK ready_after=%ss\n' "$i"
            return 0
        fi
        sleep 1
    done
    die "server did not pass /ping after restart"
}

apply_rollback_file() {
    local rollback_file="${BACKUP_DIR%/}/rollback.sql"
    local checksum_file="${BACKUP_DIR%/}/SHA256SUMS"
    [ -f "$rollback_file" ] || die "rollback file not found: $rollback_file"
    [ -f "$checksum_file" ] || die "checksum file not found: $checksum_file"
    (cd "$BACKUP_DIR" && sha256sum -c SHA256SUMS >/dev/null)
    db_exec < "$rollback_file"
}

case "$ACTION" in
    audit)
        preflight
        audit_database
        ;;
    verify)
        preflight
        verify_database
        verify_public_resources
        ;;
    apply)
        confirm_write
        preflight
        create_rollback_bundle
        if ! apply_database_changes || ! verify_database; then
            printf 'APPLY_FAILED_ROLLBACK_START backup_dir=%s\n' "$BACKUP_DIR" >&2
            apply_rollback_file
            printf 'APPLY_FAILED_ROLLBACK_OK\n' >&2
            exit 1
        fi
        restart_and_wait
        verify_database
        verify_public_resources
        audit_database > "${BACKUP_DIR}/audit-after.tsv"
        chmod 600 "${BACKUP_DIR}/audit-after.tsv"
        sha256sum "${BACKUP_DIR}/audit-after.tsv" > "${BACKUP_DIR}/audit-after.tsv.sha256"
        chmod 600 "${BACKUP_DIR}/audit-after.tsv.sha256"
        printf 'APPLY_OK backup_dir=%s\n' "$BACKUP_DIR"
        ;;
    rollback)
        confirm_write
        [ -n "$BACKUP_DIR" ] || die "rollback requires --backup-dir"
        preflight
        apply_rollback_file
        restart_and_wait
        printf 'ROLLBACK_OK backup_dir=%s\n' "$BACKUP_DIR"
        ;;
esac

#!/bin/bash
set -e

trap "exit 1" SIGINT SIGTERM

export AGENT_CONF_FILE="/var/lib/rancher/etc/agent.conf"
export CA_CERT_FILE="/var/lib/rancher/etc/ssl/ca.crt"

# This is copied from common/scripts.sh, if there is a change here
# make it in common and then copy here
check_debug()
{
    if [ -n "$CATTLE_SCRIPT_DEBUG" ] || [ -n "$RANCHER_DEBUG" ] || echo "${@}" | grep -q -- --debug; then
        export CATTLE_SCRIPT_DEBUG=true
        export RANCHER_DEBUG=true
        export PS4='[${BASH_SOURCE##*/}:${LINENO}] '
        set -x
    fi
}

info()
{
    echo "INFO:" "${@}"
}

error()
{
    echo "ERROR:" "${@}" 1>&2
}

export CATTLE_HOME=${CATTLE_HOME:-/var/lib/cattle}
export PASTURESTACK_AGENT_CONTAINER_NAME=${PASTURESTACK_AGENT_CONTAINER_NAME:-pasturestack-node-agent}
export PASTURESTACK_AGENT_UPGRADE_CONTAINER_NAME=${PASTURESTACK_AGENT_UPGRADE_CONTAINER_NAME:-pasturestack-node-agent-upgrade}
export PASTURESTACK_AGENT_STATE_VOLUME=${PASTURESTACK_AGENT_STATE_VOLUME:-pasturestack-node-agent-state}
LEGACY_AGENT_CONTAINER_NAME=${LEGACY_AGENT_CONTAINER_NAME:-rancher-agent}
LEGACY_AGENT_UPGRADE_CONTAINER_NAME=${LEGACY_AGENT_UPGRADE_CONTAINER_NAME:-rancher-agent-upgrade}
LEGACY_AGENT_STATE_VOLUME=${LEGACY_AGENT_STATE_VOLUME:-rancher-agent-state}
# End copy

check_debug

agent_curl()
{
    local retry_all_errors=()
    if curl --retry-all-errors --version >/dev/null 2>&1; then
        retry_all_errors=(--retry-all-errors)
    fi

    curl --retry 5 "${retry_all_errors[@]}" --retry-delay 2 \
        --connect-timeout "${RC16_AGENT_CURL_CONNECT_TIMEOUT:-10}" \
        --max-time "${RC16_AGENT_CURL_MAX_TIME:-300}" \
        "$@"
}

trim_agent_env_line()
{
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

apply_agent_env_line()
{
    local line
    line="$(trim_agent_env_line "$1")"

    [ -z "$line" ] && return 0
    [ "$line" = "#!/bin/sh" ] && return 0
    [[ "$line" == \#* ]] && return 0

    if [[ "$line" == INFO:\ env* ]]; then
        line="$(trim_agent_env_line "${line#INFO: env}")"
    fi

    if [[ "$line" =~ ^export[[:space:]]+(.+)$ ]]; then
        line="$(trim_agent_env_line "${BASH_REMATCH[1]}")"
    fi

    if [[ "$line" =~ ^\"(.*)\"$ || "$line" =~ ^\'(.*)\'$ ]]; then
        line="${BASH_REMATCH[1]}"
    fi

    if [[ ! "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
        error "Invalid agent environment assignment: $line"
        return 1
    fi

    local key="${BASH_REMATCH[1]}"
    local value="${BASH_REMATCH[2]}"

    if [[ "$value" =~ ^\"(.*)\"$ || "$value" =~ ^\'(.*)\'$ ]]; then
        value="${BASH_REMATCH[1]}"
    fi

    export "$key=$value"
}

apply_agent_env_output()
{
    local line
    while IFS= read -r line; do
        apply_agent_env_line "$line"
    done <<< "$1"
}

apply_agent_info_env_output()
{
    local line
    while IFS= read -r line; do
        if [[ "$line" == INFO:\ env* ]]; then
            apply_agent_env_line "$line"
        fi
    done <<< "$1"
}

MODULES="ansi_cprng
drbg
esp4
veth
xfrm4_mode_tunnel
xfrm6_mode_tunnel
xt_mark
xt_nat
vxlan"

agent_container_name()
{
    if docker inspect "${PASTURESTACK_AGENT_CONTAINER_NAME}" >/dev/null 2>&1; then
        printf '%s\n' "${PASTURESTACK_AGENT_CONTAINER_NAME}"
    elif docker inspect "${LEGACY_AGENT_CONTAINER_NAME}" >/dev/null 2>&1; then
        printf '%s\n' "${LEGACY_AGENT_CONTAINER_NAME}"
    else
        printf '%s\n' "${PASTURESTACK_AGENT_CONTAINER_NAME}"
    fi
}

agent_state_volume_name()
{
    if docker volume inspect "${PASTURESTACK_AGENT_STATE_VOLUME}" >/dev/null 2>&1; then
        printf '%s\n' "${PASTURESTACK_AGENT_STATE_VOLUME}"
    elif docker volume inspect "${LEGACY_AGENT_STATE_VOLUME}" >/dev/null 2>&1; then
        printf '%s\n' "${LEGACY_AGENT_STATE_VOLUME}"
    else
        printf '%s\n' "${PASTURESTACK_AGENT_STATE_VOLUME}"
    fi
}

CONTAINER="$(hostname)"
if [ "$1" = "run" ]; then
    CONTAINER="$(agent_container_name)"
fi

if [[ "$1" != "inspect-host" && $1 != "--" && "$1" != "state" ]]; then
    RUNNING_IMAGE="$(docker inspect -f '{{.Config.Image}}' "${CONTAINER}")"
fi

if [[ -n ${RUNNING_IMAGE} && ${RUNNING_IMAGE} != ${RANCHER_AGENT_IMAGE} ]]; then
    export RANCHER_AGENT_IMAGE=${RUNNING_IMAGE}
fi

check_and_add_conf()
{
    if [ -d $(dirname ${AGENT_CONF_FILE}) ]; then
        touch ${AGENT_CONF_FILE}
        grep -q -F "${1}=${2}" ${AGENT_CONF_FILE} || \
            echo "export ${1}=${2}" >> ${AGENT_CONF_FILE}
    fi
}

print_url()
{
    local url=$(echo "$1" | sed -E -e 's!/(v1|v2-beta)(/.*)?/scripts.*!/\1!')
    echo $url
}

setup_custom_ca_bundle()
{
    check_and_add_conf "CURL_CA_BUNDLE" ${CA_CERT_FILE}
    check_and_add_conf "REQUESTS_CA_BUNDLE" ${CA_CERT_FILE}

    # Update core container CA certs for Golang
    mkdir -p /usr/local/share/ca-certificates/rancher
    cp ${CA_CERT_FILE} /usr/local/share/ca-certificates/rancher/rancherAddedCA.crt
    update-ca-certificates

    # Configure python websocket pre-shipped cacerts.
    local websocket_pem='/var/lib/cattle/pyagent/dist/websocket/cacert.pem'
    local websocket_orig='/var/lib/cattle/pyagent/dist/websocket/cacert.orig'
    if [[ -e ${websocket_pem} ]]; then
        if [[ ! -e ${websocket_orig} ]]; then
            cp ${websocket_pem} ${websocket_orig}
        fi
        cat ${websocket_orig} ${CA_CERT_FILE} > ${websocket_pem}
    fi
}

setup_self_signed()
{
    local url="$1"

    if [[ -n "${CA_FINGERPRINT}" && $url =~ https://.* ]]; then
        # Check if curl works
        if agent_curl -fsSL "$url" >/dev/null 2>&1; then
            return
        fi

        local cert="$(print_url "$url")/scripts/ca.crt"
        if ! agent_curl --insecure -fsSL -o /tmp/ca.crt "$cert"; then
            return
        fi

        if ! openssl x509 -in /tmp/ca.crt -inform pem > /tmp/ca.crt.clean; then
            return
        fi

        if [ "$(openssl x509 -in /tmp/ca.crt.clean -inform pem -noout -fingerprint | cut -f2 -d=)" != "${CA_FINGERPRINT}" ]; then
            return
        fi

        mkdir -p "$(dirname "$CA_CERT_FILE")"
        cp /tmp/ca.crt.clean "$CA_CERT_FILE"
        setup_custom_ca_bundle
    fi
}

if [ -e ${CA_CERT_FILE} ]; then
    setup_custom_ca_bundle
else
    setup_self_signed "$1"
fi

if [ -e "${AGENT_CONF_FILE}" ]; then
    source "${AGENT_CONF_FILE}"
fi

docker_cgroupns_args()
{
    if docker run --help 2>/dev/null | grep -q -- '--cgroupns'; then
        echo "--cgroupns=host"
    fi
}

inspect_host()
{
    local cgroupns_opt="$(docker_cgroupns_args)"

    docker run --rm --privileged ${cgroupns_opt} -v /run:/run -v /var/run:/var/run -v /var/lib:/var/lib ${RANCHER_AGENT_IMAGE} inspect-host
}

launch_agent()
{
    local state_volume

    if [ -n "$NO_PROXY" ]; then
        export no_proxy=$NO_PROXY
    fi

    state_volume="$(agent_state_volume_name)"
    if [ "${CATTLE_VAR_LIB_WRITABLE}" = "true" ]; then
        opts="-v /var/lib/rancher:/var/lib/rancher"
    else
        opts="-v ${state_volume}:/var/lib/rancher"
    fi
    local cgroupns_opt="$(docker_cgroupns_args)"

    docker run \
        -d \
        --name "${PASTURESTACK_AGENT_CONTAINER_NAME}" \
        --restart=always \
        --net=host \
        --pid=host \
        ${cgroupns_opt} \
        --privileged \
        --oom-score-adj="-500" \
        -e CATTLE_AGENT_PIDNS=host \
        -e http_proxy \
        -e HTTP_PROXY \
        -e https_proxy \
        -e HTTPS_PROXY \
        -e NO_PROXY \
        -e no_proxy \
        -e CATTLE_SCHEDULER_IPS \
        -e CATTLE_SCHEDULER_REQUIRE_ANY \
        -e CATTLE_PHYSICAL_HOST_UUID \
        -e CATTLE_DOCKER_UUID \
        -e CATTLE_SCRIPT_DEBUG \
        -e CATTLE_ACCESS_KEY \
        -e CATTLE_SECRET_KEY \
        -e CATTLE_AGENT_IP \
        -e CATTLE_HOST_API_PROXY \
        -e CATTLE_URL \
        -e CATTLE_HOST_LABELS \
        -e CATTLE_VOLMGR_ENABLED \
        -e CATTLE_RUN_FIO \
        -e CATTLE_MEMORY_OVERRIDE \
        -e CATTLE_MILLI_CPU_OVERRIDE \
        -e CATTLE_LOCAL_STORAGE_MB_OVERRIDE \
        -e CATTLE_DETECT_CLOUD_PROVIDER \
        -e CATTLE_CHECK_NAMESERVER \
        -e RANCHER_DEBUG \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /var/run/rancher/storage:/var/run/rancher/storage \
        -v /lib/modules:/lib/modules:ro \
        -v /proc:/host/proc \
        -v /dev:/host/dev \
        -v rancher-cni:/.r \
        -v "${state_volume}:/var/lib/cattle" \
        ${opts} "${RANCHER_AGENT_IMAGE}" "$@"
}

delete_container()
{
    while docker inspect $1 >/dev/null 2>&1; do
        info Deleting container $1
        docker rm -f $1 >/dev/null 2>&1 || true
    done
}

cleanup_agent()
{
    delete_container "${PASTURESTACK_AGENT_CONTAINER_NAME}"
    delete_container "${LEGACY_AGENT_CONTAINER_NAME}"
}

cleanup_upgrade()
{
    delete_container "${PASTURESTACK_AGENT_UPGRADE_CONTAINER_NAME}"
    delete_container "${LEGACY_AGENT_UPGRADE_CONTAINER_NAME}"
}

setup_state()
{
    mkdir -p /var/lib/{cattle,rancher/state}

    export CATTLE_STATE_DIR=/var/lib/rancher/state
    export CATTLE_AGENT_LOG_FILE=/var/log/rancher/agent.log
    local cgroupns_opt="$(docker_cgroupns_args)"

    docker run --privileged --net host --pid host ${cgroupns_opt} -v /:/host --rm $RANCHER_AGENT_IMAGE -- /usr/bin/share-mnt /var/lib/rancher/volumes /var/lib/kubelet -- norun

    cp -f /usr/bin/r /.r/r || true

    for m in $MODULES; do
        nsenter -m -t 1 /sbin/modprobe $m >/dev/null 2>&1 || true
    done
}

load()
{
    local url="$1"
    local content

    if ! content=$(agent_curl -fsSL "$url"); then
        error Failed to load registration env from "$(print_url "$url")"
        return 1
    fi

    if [[ "$content" =~ .!/bin/sh.* ]]; then
        apply_agent_env_output "$content"
        if [ -n "$CATTLE_URL_OVERRIDE" ]; then
            CATTLE_URL=$CATTLE_URL_OVERRIDE
        fi
    else
        error $(print_url $1) returned
        error "--- START ---"
        echo "$content"
        error "--- END ---"
        return 1
    fi
}

print_token()
{
    local token_file=/var/lib/rancher/state/.registration_token
    local token=

    if [ -e $token_file ]; then
        token="$(<$token_file)"
    fi

    if [ -z "$token" ]; then
        token=$(openssl rand -hex 64)
        mkdir -p $(dirname $token_file)
        echo $token > $token_file
    fi

    info env "TOKEN=$token"
}

register()
{
    local env
    env=$(./register.py "$TOKEN")
    apply_agent_env_output "$env"
}

run_bootstrap()
{
    SCRIPT=/tmp/bootstrap.sh
    touch $SCRIPT
    chmod 700 $SCRIPT

    export CATTLE_CONFIG_URL="${CATTLE_CONFIG_URL:-${CATTLE_URL}}"
    export CATTLE_STORAGE_URL="${CATTLE_STORAGE_URL:-${CATTLE_URL}}"

    # Sanity check that these credentials are valid
    if agent_curl -fsS -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" -o test.json "${CATTLE_URL}/schemas/configcontent" 2>/dev/null; then
        # Some legacy-compatible API builds return a normal API error object for this
        # schema lookup while still accepting the same agent key for bootstrap.
        # Treat only a successful non-error schema mismatch as an invalid key.
        if cat test.json | jq -r .id >/dev/null 2>&1 && \
           [ "$(cat test.json | jq -r .type)" != "error" ] && \
           [ "$(cat test.json | jq -r .id)" != "configContent" ]; then
            error Credentials are no longer valid, please re-register this agent
            return 1
        fi
    fi

    agent_curl -fsSL -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" -o "$SCRIPT" "${CATTLE_URL}/scripts/bootstrap"

    # Sanity check if this account is really being authenticated as an agent account or the default admin auth.
    # A legacy-compatible server without an auth provider exposes admin schemas even when the
    # supplied basic-auth key is an agent key, so this must not be fatal.
    if agent_curl -fsS -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" -o /dev/null "${CATTLE_URL}/schemas/account" >/dev/null 2>&1; then
        info "Account schema is accessible; continuing because the server may be running without an auth provider"
    fi

    info "Starting agent for ${CATTLE_ACCESS_KEY}"
    if [ "$CATTLE_EXEC_AGENT" = "true" ]; then
        exec bash "$SCRIPT" "$@"
    else
        bash "$SCRIPT" "$@"
    fi
}

run()
{
    mount --rbind /host/dev /dev
    while true; do
        run_bootstrap "$@" || true
        sleep 5
    done
}

read_node_agent_env()
{
    local container

    container="$(agent_container_name)"
    info "Reading environment from ${container}"
    local save=$RANCHER_AGENT_IMAGE
    local line
    while IFS= read -r line; do
        apply_agent_env_line "$line"
    done < <(docker inspect "${container}" | jq -r '.[0].Config.Env[]?')
    export RANCHER_AGENT_IMAGE=$save
}

check_url()
{
    local err_file
    local err
    err_file=$(mktemp "${TMPDIR:-/tmp}/rc16-agent-check-url.XXXXXX")

    if agent_curl -f -L -sS --connect-timeout 15 -o /dev/null --stderr "$err_file" "$1"; then
        rm -f "$err_file"
        echo ""
    else
        err=$(sed -n '1{s/^curl: ([0-9][0-9]*) //;p;q;}' "$err_file")
        rm -f "$err_file"
        echo "$err"
    fi
}

wait_for()
{
    local url="$(print_url $CATTLE_URL)"
    info "Attempting to connect to: ${url}"
    local err
    for ((i=0; i < 300; i++)); do
        err=$(check_url $CATTLE_URL)
        if [[ $err ]]; then
            error "${url} is not accessible (${err})"
            sleep 2
            if [ "$i" -eq "299" ]; then
                error "Could not reach ${url}. Giving up."
                exit 1
            fi
        else
            info "${url} is accessible"
            break
        fi
    done
}

inspect()
{
    print_token

    if docker info 2>/dev/null | grep -i boot2docker >/dev/null 2>&1; then
        info env "CATTLE_BOOT2DOCKER=true"
        info env "CATTLE_VAR_LIB_WRITABLE=false"
    else
        info env "CATTLE_BOOT2DOCKER=false"
        if mkdir -p /var/lib/rancher/state >/dev/null 2>&1; then
            info env "CATTLE_VAR_LIB_WRITABLE=true"
        else
            info env "CATTLE_VAR_LIB_WRITABLE=false"
        fi
    fi
}

setup_env()
{
    if [ "$1" != "upgrade" ]; then
        local env="$(./resolve_url.py $CATTLE_URL)"
        info Configured Host Registration URL info: CATTLE_URL=$(print_url $CATTLE_URL) ENV_URL=$(print_url $env)
        if ! load "$env"; then
            error Failed to load registration env from CATTLE_URL=$(print_url $CATTLE_URL) ENV_URL=$(print_url $env)
            exit 1
        fi

        if echo "$(print_url $env)" | grep -q "/v1$" && [ "$(print_url $CATTLE_URL)" != "$(print_url $env)" ]; then
            error Configured Host Registration URL does not match given URL: CATTLE_URL=$(print_url $CATTLE_URL) ENV_URL=$(print_url $env)
            error Please ensure the proper value for the Host Registration URL is set
            exit 1
        fi
    fi

    info Inspecting host capabilities
    local content=$(inspect_host)

    echo "$content" | grep -v 'INFO: env' || true
    apply_agent_info_env_output "$content"

    info Boot2Docker: ${CATTLE_BOOT2DOCKER}
    info Host writable: ${CATTLE_VAR_LIB_WRITABLE}
    info Token: $(echo $TOKEN | sed 's/........*/xxxxxxxx/g')

    if [[ -z "$CATTLE_ACCESS_KEY" || -z "$CATTLE_SECRET_KEY" ]]; then
        info Running registration
        register
    else
        info Skipping registration
    fi

    info Printing Environment
    env | sort | while read LINE; do
        if [[ $LINE =~ RANCHER.* || $LINE =~ CATTLE.* ]]; then
            info "ENV:" $(echo $LINE | sed -E 's/((SECRET|ACCESS_KEY|TOKEN|PASSWORD)[^=]*=).*/\1xxxxxxx/g')
        fi
    done
}

setup_cattle_url()
{
    if [ "$1" = "register" ]; then
        if [ -z "$RANCHER_URL" ]; then
            info No RANCHER_URL environment variable, exiting
            exit 0
        fi
        CATTLE_URL="$RANCHER_URL"
    elif [ "$1" = "upgrade" ]; then
        read_node_agent_env
    else
        CATTLE_URL="$1"
    fi

    if echo $CATTLE_URL | grep -qE '(http|https)://(127\.0\.0\.1|localhost)([:/]|$)'; then
        error CATTLE_URL cannot contain localhost or 127.0.0.1, please check the Host Registration URL.
        exit 1
    fi

    export CATTLE_URL
}

validate_ip() {
        local ip=$1
        # Format should match an IP (filters pasting http://192.168.0.10 for example)
        [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || return 1
        local -a oc=(${ip//\./ })
        # Check if all octects are <= 255
        [[ ${oc[0]} -le 255 && ${oc[1]} -le 255 && ${oc[2]} -le 255 && ${oc[3]} -le 255 ]] || return 1
        # Filter loopback (127.0.0.0/8)
        [[ ${oc[0]} -ne 127 ]] || return 1
        # Filter 0.0.0.0 and 255.255.255.255
        [ $ip != '0.0.0.0' ] || return 1
        [ $ip != '255.255.255.255' ] || return 1
        return 0
}

if [ "$#" == 0 ]; then
    error "One parameter required"
    exit 1
fi

if [[ $1 =~ http.* || $1 = "register" || $1 = "upgrade" ]]; then
    if [ -n "$CATTLE_AGENT_IP" ]; then
        if ! validate_ip $CATTLE_AGENT_IP; then
            error "Invalid CATTLE_AGENT_IP (${CATTLE_AGENT_IP})"
            exit 1
        fi
    fi
    echo $http_proxy $https_proxy
    setup_cattle_url $1
    if [ "$1" = "upgrade" ]; then
        info Running upgrade
    else
        info Running Agent Registration Process, CATTLE_URL=$(print_url $CATTLE_URL)
    fi
    if [ "$1" != "upgrade" ]; then
        wait_for
    fi
    setup_env $1
    cleanup_agent
    ID=$(launch_agent run)
    info Launched PastureStack node agent: $ID
elif [ "$1" = "inspect-host" ]; then
    inspect
elif [ "$1" = "state" ]; then
    echo PastureStack State
elif [ "$1" = "run" ]; then
    cleanup_upgrade
    setup_state
    run
elif [ "$1" = "--" ]; then
    shift 1
    exec "$@"
fi

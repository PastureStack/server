#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

: "${PASTURESTACK_RELEASE_BASE_URL:=https://github.com/PastureStack/server/releases/download/v1.6.270}"
: "${PASTURESTACK_ARTIFACT_BASE_URL:=${RC16_ARTIFACT_BASE_URL:-${PASTURESTACK_RELEASE_BASE_URL}}}"
ARTIFACT_BASE="${PASTURESTACK_ARTIFACT_BASE_URL}"
ARTIFACT_BASE="${ARTIFACT_BASE%/}"
S6_OVERLAY_VERSION=1.19.1.1
S6_OVERLAY_ARTIFACT_SHA256=b5d360383dd519a33bd39651c43c49b4cf0e95344a94ba65dd8628eefd9ee5cb
S6_OVERLAY_ASSET="s6-overlay-amd64-v${S6_OVERLAY_VERSION}.tar.gz"
S6_OVERLAY_TARGET=target/s6-overlay-amd64-static.tar.gz

mkdir -p target
checksum_tmp=target/release-SHA256SUMS.tmp
rm -f "${checksum_tmp}"
curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 \
    -o "${checksum_tmp}" "${ARTIFACT_BASE}/SHA256SUMS"
mv "${checksum_tmp}" target/release-SHA256SUMS

if [ ! -e "${S6_OVERLAY_TARGET}" ] || \
   ! bash artifacts/verify_release_asset target/release-SHA256SUMS "${S6_OVERLAY_TARGET}" "${S6_OVERLAY_ASSET}" >/dev/null; then
    tmp_file="${S6_OVERLAY_TARGET}.tmp"
    rm -f "${tmp_file}"
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 \
        -o "${tmp_file}" "${ARTIFACT_BASE}/${S6_OVERLAY_ASSET}"
    bash artifacts/verify_release_asset target/release-SHA256SUMS "${tmp_file}" "${S6_OVERLAY_ASSET}" >/dev/null
    echo "${S6_OVERLAY_ARTIFACT_SHA256}  ${tmp_file}" | sha256sum -c -
    mv "${tmp_file}" "${S6_OVERLAY_TARGET}"
fi
echo "${S6_OVERLAY_ARTIFACT_SHA256}  ${S6_OVERLAY_TARGET}" | sha256sum -c -
touch target/.done

dockerfile_env() {
    local key="$1"
    awk -v key="$key" '
        $1 == "ENV" {
            if ($2 ~ "^" key "=") {
                sub("^" key "=", "", $2)
                print $2
                exit
            }
            if ($2 == key) {
                print $3
                exit
            }
        }
    ' Dockerfile
}

TAG=${TAG:-$(dockerfile_env CATTLE_RANCHER_SERVER_VERSION)}
REPO=${REPO:-$(dockerfile_env CATTLE_RANCHER_SERVER_IMAGE)}
IMAGE=${REPO}:${TAG}
server_revision=${PASTURESTACK_SERVER_REVISION:-$(git rev-parse HEAD)}
if [[ ! "${server_revision}" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Invalid PastureStack Server revision: ${server_revision}" >&2
    exit 1
fi
source_date_epoch=${SOURCE_DATE_EPOCH:-$(git show -s --format=%ct "${server_revision}")}
if [[ ! "${source_date_epoch}" =~ ^[0-9]+$ ]]; then
    echo "Invalid SOURCE_DATE_EPOCH: ${source_date_epoch}" >&2
    exit 1
fi
export SOURCE_DATE_EPOCH="${source_date_epoch}"

docker_build_flags=()
if [ "${RC16_DOCKER_BUILD_NO_CACHE:-0}" = "1" ]; then
    docker_build_flags+=(--no-cache)
fi

DOCKER_BUILDKIT=1 docker buildx build \
    "${docker_build_flags[@]}" \
    --provenance=false \
    --build-arg "PASTURESTACK_SERVER_REVISION=${server_revision}" \
    --build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}" \
    --secret id=rc16_artifact_base_url,env=PASTURESTACK_ARTIFACT_BASE_URL \
    --output "type=image,name=${IMAGE},rewrite-timestamp=true,unpack=false" .

cat > Dockerfile.master << EOF
FROM ${IMAGE}
ENV CATTLE_MASTER=true
EOF
trap "rm Dockerfile.master" EXIT

DOCKER_BUILDKIT=1 docker buildx build \
    "${docker_build_flags[@]}" \
    --provenance=false \
    --build-arg "SOURCE_DATE_EPOCH=${source_date_epoch}" \
    --output "type=image,name=${REPO}:master,rewrite-timestamp=true,unpack=false" \
    -f Dockerfile.master .

echo Done building "${IMAGE}"

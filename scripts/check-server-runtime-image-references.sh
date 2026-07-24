#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

approved_registry=ghcr.io/pasturestack
approved_agent="${approved_registry}/node-agent:v1.2.31"
approved_balancer="${approved_registry}/load-balancer-service:v0.9.25"

grep -Fq 'IMAGE_PREFIX=${IMAGE_PREFIX:-ghcr.io/pasturestack}' scripts/build || {
    echo SERVER_BUILD_IMAGE_PREFIX_NOT_APPROVED >&2
    exit 1
}
grep -Fq 'image="${IMAGE_PREFIX}/${i}:${TAG}"' scripts/build || {
    echo SERVER_BUILD_IMAGE_REFERENCE_NOT_CONFIGURABLE >&2
    exit 1
}

placeholder_count=$(grep -Fxc '  image: pasturestack/placeholder' \
    server/artifacts/compose/docker-compose.yml)
[ "$placeholder_count" -eq 4 ] || {
    echo SERVER_COMPOSE_PLACEHOLDER_COUNT_MISMATCH >&2
    exit 1
}

balancer_count=$(grep -Fxc "  image: ${approved_balancer}" \
    server/artifacts/compose/docker-compose.yml)
[ "$balancer_count" -eq 2 ] || {
    echo SERVER_COMPOSE_LOAD_BALANCER_REFERENCE_MISMATCH >&2
    exit 1
}

grep -Fq "ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE=${approved_balancer}" \
    server/Dockerfile || {
    echo SERVER_DOCKERFILE_LOAD_BALANCER_REFERENCE_MISMATCH >&2
    exit 1
}
grep -Fq "ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE_UUID=docker:${approved_balancer}" \
    server/Dockerfile || {
    echo SERVER_DOCKERFILE_LOAD_BALANCER_UUID_REFERENCE_MISMATCH >&2
    exit 1
}
grep -Fq "ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE=${approved_balancer}" \
    server/Dockerfile.runtime-hotfix || {
    echo SERVER_RUNTIME_HOTFIX_LOAD_BALANCER_REFERENCE_MISMATCH >&2
    exit 1
}
grep -Fq "ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE_UUID=docker:${approved_balancer}" \
    server/Dockerfile.runtime-hotfix || {
    echo SERVER_RUNTIME_HOTFIX_LOAD_BALANCER_UUID_REFERENCE_MISMATCH >&2
    exit 1
}
grep -Fq "ENV DEFAULT_CATTLE_AGENT_IMAGE=${approved_agent}" \
    server/Dockerfile || {
    echo SERVER_DOCKERFILE_AGENT_REFERENCE_MISMATCH >&2
    exit 1
}
grep -Fq "ENV DEFAULT_CATTLE_BOOTSTRAP_REQUIRED_IMAGE=${approved_agent}" \
    server/Dockerfile || {
    echo SERVER_DOCKERFILE_BOOTSTRAP_AGENT_REFERENCE_MISMATCH >&2
    exit 1
}
grep -Fq "ENV DEFAULT_CATTLE_AGENT_IMAGE=${approved_agent}" \
    server/Dockerfile.auth-hotfix || {
    echo SERVER_AUTH_HOTFIX_AGENT_REFERENCE_MISMATCH >&2
    exit 1
}
grep -Fq "ENV DEFAULT_CATTLE_BOOTSTRAP_REQUIRED_IMAGE=${approved_agent}" \
    server/Dockerfile.auth-hotfix || {
    echo SERVER_AUTH_HOTFIX_BOOTSTRAP_AGENT_REFERENCE_MISMATCH >&2
    exit 1
}
grep -Fq "ENV DEFAULT_CATTLE_AGENT_IMAGE=${approved_agent}" \
    server/Dockerfile.runtime-hotfix || {
    echo SERVER_RUNTIME_HOTFIX_AGENT_REFERENCE_MISMATCH >&2
    exit 1
}
grep -Fq "ENV DEFAULT_CATTLE_BOOTSTRAP_REQUIRED_IMAGE=${approved_agent}" \
    server/Dockerfile.runtime-hotfix || {
    echo SERVER_RUNTIME_HOTFIX_BOOTSTRAP_AGENT_REFERENCE_MISMATCH >&2
    exit 1
}
grep -Fq \
    "RC16_AGENT_IMAGE=\"\${RC16_AGENT_IMAGE:-${approved_agent}}\"" \
    scripts/migrate-server-mysql55-to-mariadb118.sh || {
    echo SERVER_MIGRATION_AGENT_REFERENCE_MISMATCH >&2
    exit 1
}
grep -Fq \
    "RC16_LB_INSTANCE_IMAGE=\"\${RC16_LB_INSTANCE_IMAGE:-${approved_balancer}}\"" \
    scripts/migrate-server-mysql55-to-mariadb118.sh || {
    echo SERVER_MIGRATION_LOAD_BALANCER_REFERENCE_MISMATCH >&2
    exit 1
}
grep -Fq "APPROVED_AGENT_IMAGE=\"${approved_agent}\"" \
    scripts/migrate-approved-runtime-coordinates.sh || {
    echo APPROVED_COORDINATE_AGENT_REFERENCE_MISMATCH >&2
    exit 1
}
grep -Fq "APPROVED_LB_IMAGE=\"${approved_balancer}\"" \
    scripts/migrate-approved-runtime-coordinates.sh || {
    echo APPROVED_COORDINATE_LOAD_BALANCER_REFERENCE_MISMATCH >&2
    exit 1
}
grep -Fq 'digest-qualified operational references are not allowed' \
    scripts/migrate-server-mysql55-to-mariadb118.sh || {
    echo SERVER_MIGRATION_DIGEST_REJECTION_GATE_MISSING >&2
    exit 1
}
grep -Fq 'require_operational_version_tag RC16_AGENT_IMAGE "$RC16_AGENT_IMAGE"' \
    scripts/migrate-server-mysql55-to-mariadb118.sh || {
    echo SERVER_MIGRATION_AGENT_VERSION_TAG_GATE_MISSING >&2
    exit 1
}
grep -Fq 'require_operational_version_tag RC16_LB_INSTANCE_IMAGE "$RC16_LB_INSTANCE_IMAGE"' \
    scripts/migrate-server-mysql55-to-mariadb118.sh || {
    echo SERVER_MIGRATION_LOAD_BALANCER_VERSION_TAG_GATE_MISSING >&2
    exit 1
}
grep -Fq \
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.277@sha256:075739b5ddf25805781a45cce10d183db2f31319ee53ec7e8fb781f5503e8b2e' \
    server/Dockerfile.runtime-hotfix || {
    echo SERVER_RUNTIME_HOTFIX_BASE_DIGEST_MISSING >&2
    exit 1
}
grep -Fq \
    'org.opencontainers.image.base.name="ghcr.io/pasturestack/server:v1.6.277"' \
    server/Dockerfile.runtime-hotfix || {
    echo SERVER_RUNTIME_HOTFIX_BASE_NAME_LABEL_MISMATCH >&2
    exit 1
}
grep -Fq \
    'org.opencontainers.image.base.digest="sha256:075739b5ddf25805781a45cce10d183db2f31319ee53ec7e8fb781f5503e8b2e"' \
    server/Dockerfile.runtime-hotfix || {
    echo SERVER_RUNTIME_HOTFIX_BASE_DIGEST_LABEL_MISMATCH >&2
    exit 1
}
grep -Fq 'Refusing to build a release image from tracked, uncommitted changes' \
    server/build-runtime-hotfix-image.sh || {
    echo SERVER_RUNTIME_HOTFIX_CLEAN_SOURCE_GATE_MISSING >&2
    exit 1
}
grep -Fq -- '--secret id=rc16_artifact_base_url,env=PASTURESTACK_ARTIFACT_BASE_URL' \
    server/build-runtime-hotfix-image.sh || {
    echo SERVER_RUNTIME_HOTFIX_ARTIFACT_SECRET_MISSING >&2
    exit 1
}
grep -Fq -- '--network=host' \
    server/build-runtime-hotfix-image.sh || {
    echo SERVER_RUNTIME_HOTFIX_LOCAL_ARTIFACT_NETWORK_MISSING >&2
    exit 1
}

test_image_count=$(grep -Fxc '    image: pasturestack/server:dev' \
    tests/server/fig-test-env.yml)
[ "$test_image_count" -eq 4 ] || {
    echo SERVER_TEST_IMAGE_REFERENCE_MISMATCH >&2
    exit 1
}

if grep -En '(^|[[:space:]])image:[[:space:]]*rancher/|docker build -t rancher/' \
    scripts/build \
    server/artifacts/compose/docker-compose.yml \
    tests/server/fig-test-env.yml; then
    echo SERVER_DEPLOYABLE_UPSTREAM_IMAGE_REFERENCE_FOUND >&2
    exit 1
fi

if grep -En '@sha256:' \
    server/Dockerfile \
    server/Dockerfile.auth-hotfix \
    server/artifacts/compose/docker-compose.yml ||
   grep -En '^ENV DEFAULT_CATTLE_(AGENT|BOOTSTRAP_REQUIRED|LB_INSTANCE)_IMAGE(_UUID)?=.*@sha256:' \
    server/Dockerfile.runtime-hotfix ||
   grep -En '^RC16_(AGENT|LB_INSTANCE)_IMAGE(_UUID)?=.*@sha256:' \
    scripts/migrate-server-mysql55-to-mariadb118.sh ||
   grep -En '^APPROVED_(AGENT|LB)_IMAGE=.*@sha256:' \
    scripts/migrate-approved-runtime-coordinates.sh; then
    echo SERVER_OPERATIONAL_IMAGE_DIGEST_REFERENCE_FOUND >&2
    exit 1
fi

printf 'SERVER_RUNTIME_IMAGE_REFERENCES_OK registry=%s operational_version_tags=1 operational_digest_refs=0 base_server_digest=1 placeholders=4 test_images=4\n' \
    "$approved_registry"

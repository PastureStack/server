#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

approved_registry=ghcr.io/pasturestack
approved_balancer="${approved_registry}/load-balancer-service:v0.9.25@sha256:7a41ff94e6d6f2e8e08e5cd078243861bc74442ade4630f5d940c46a89a12f24"

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
grep -Fq "ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE=${approved_balancer}" \
    server/Dockerfile.runtime-hotfix || {
    echo SERVER_RUNTIME_HOTFIX_LOAD_BALANCER_REFERENCE_MISMATCH >&2
    exit 1
}
grep -Fq \
    'ARG BASE_IMAGE=ghcr.io/pasturestack/server:v1.6.276@sha256:09a599bc6c01ab4b5a8eca6c245752a7669f4c8c396171814da9186190053ec8' \
    server/Dockerfile.runtime-hotfix || {
    echo SERVER_RUNTIME_HOTFIX_BASE_DIGEST_MISSING >&2
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

printf 'SERVER_RUNTIME_IMAGE_REFERENCES_OK registry=%s load_balancer_digest=1 base_server_digest=1 placeholders=4 test_images=4\n' \
    "$approved_registry"

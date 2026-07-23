FROM ubuntu:26.04

RUN rm -f /usr/bin/pebble

ARG SERVER_DEV_VERSION=v0.1.1
ARG DOCKER_VERSION=29.5.3
ARG DOCKER_SHA256=34eea64e9c3435f5af1b760827a56a561cd67fc2d6e9cd1813b8bb1e3ff7930b
ARG COMPOSE_VERSION=v5.1.4
ARG COMPOSE_SHA256=33b208d7e76639db742fae84b966cc01dacae58ca3fc4dabbc907045aefdf0c4

LABEL org.opencontainers.image.source="https://github.com/PastureStack/server" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.title="pasturestack-server-dev" \
      org.opencontainers.image.version="${SERVER_DEV_VERSION}" \
      org.opencontainers.image.description="PastureStack server development image for legacy compatibility testing."

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        iproute2 \
        iptables \
        libyaml-dev \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        tox && \
    rm -rf /var/lib/apt/lists/* && \
    docker_tgz=/tmp/docker.tgz && \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 \
        -o "$docker_tgz" "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" && \
    echo "${DOCKER_SHA256}  $docker_tgz" | sha256sum -c - && \
    tar xzf "$docker_tgz" -C /usr/bin --strip-components=1 \
        docker/docker \
        docker/docker-init \
        docker/ctr \
        docker/runc \
        docker/containerd-shim-runc-v2 \
        docker/dockerd \
        docker/docker-proxy \
        docker/containerd && \
    rm -f "$docker_tgz" && \
    mkdir -p /usr/local/lib/docker/cli-plugins && \
    compose_bin=/usr/local/lib/docker/cli-plugins/docker-compose && \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 \
        -o "$compose_bin" "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" && \
    echo "${COMPOSE_SHA256}  $compose_bin" | sha256sum -c - && \
    chmod 0755 "$compose_bin" && \
    printf '#!/bin/sh\nexec docker compose "$@"\n' > /usr/local/bin/docker-compose && \
    chmod 0755 /usr/local/bin/docker-compose && \
    printf '#!/bin/bash\nset -e\nmkdir -p /var/run /var/lib/docker\ndockerd --host=unix:///var/run/docker.sock > /tmp/docker.log 2>&1 &\nfor i in $(seq 1 60); do\n  if docker info >/dev/null 2>&1; then\n    exit 0\n  fi\n  sleep 1\ndone\ncat /tmp/docker.log\nexit 1\n' > /usr/local/bin/wrapdocker && \
    chmod 0755 /usr/local/bin/wrapdocker

COPY ./scripts/bootstrap /scripts/bootstrap
RUN /scripts/bootstrap
WORKDIR /source

# syntax=docker/dockerfile:1.7
FROM ubuntu:26.04@sha256:2260313b31c8c011cd2eebe728008efac1b3982be73eb71348ea2648d2c0e09b

RUN rm -f /usr/bin/pebble

ARG SERVER_DEV_VERSION=v0.1.1
ARG DOCKER_VERSION=29.7.2
ARG DOCKER_SHA256=803d433f226db4776e1768fd319fc6c6e4935a456acf84fcc0080818b854bc8f
ARG COMPOSE_VERSION=v5.1.4
ARG COMPOSE_SHA256=33b208d7e76639db742fae84b966cc01dacae58ca3fc4dabbc907045aefdf0c4
ARG UBUNTU_SNAPSHOT=20260825T000000Z

ADD --checksum=sha256:6077d27c6b6f8b23590cb01ff877ed8c804a67a5442cc32b5a33da10d2bd0e90 \
    https://snapshot.ubuntu.com/ubuntu/20260825T000000Z/pool/main/c/ca-certificates/ca-certificates_20260601~26.04.1_all.deb \
    /tmp/ca-certificates.deb

LABEL org.opencontainers.image.source="https://github.com/PastureStack/server" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.title="pasturestack-server-dev" \
      org.opencontainers.image.version="${SERVER_DEV_VERSION}" \
      org.opencontainers.image.description="PastureStack server development image for legacy compatibility testing."

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    mkdir -p /tmp/ca-bootstrap /etc/ssl/certs; \
    dpkg-deb --extract /tmp/ca-certificates.deb /tmp/ca-bootstrap; \
    find /tmp/ca-bootstrap/usr/share/ca-certificates -type f -name '*.crt' | LC_ALL=C sort | while IFS= read -r certificate; do sed -e '$a\' "${certificate}"; done > /etc/ssl/certs/ca-certificates.crt; \
    rm -rf /tmp/ca-bootstrap /tmp/ca-certificates.deb; \
    rm -f /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; \
    printf 'Types: deb\nURIs: https://snapshot.ubuntu.com/ubuntu/%s\nSuites: resolute resolute-updates resolute-backports resolute-security\nComponents: main universe restricted multiverse\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\nSnapshot: no\n' "${UBUNTU_SNAPSHOT}" > /etc/apt/sources.list.d/pasturestack-snapshot.sources; \
    printf 'Acquire::Retries "5";\nAcquire::https::CaInfo "/etc/ssl/certs/ca-certificates.crt";\nAcquire::https::Verify-Peer "true";\nAcquire::https::Verify-Host "true";\nAcquire::AllowInsecureRepositories "false";\nAPT::Get::AllowUnauthenticated "false";\n' > /etc/apt/apt.conf.d/80pasturestack-snapshot; \
    apt-get update && \
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

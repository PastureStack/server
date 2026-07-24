FROM ubuntu:26.04 AS python-builder

RUN rm -f /usr/bin/pebble

ENV PYTHON_VERSION=3.14.4
ENV PYTHON_SHA256=d923c51303e38e249136fc1bdf3568d56ecb03214efdef48516176d3d7faaef8

RUN apt-get update && \
        apt-get install --no-install-recommends -y \
        build-essential \
        ca-certificates \
        libbz2-dev \
        libffi-dev \
        libgdbm-dev \
        liblzma-dev \
        libncursesw5-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        libuuid1 \
        libzstd-dev \
        tk-dev \
        uuid-dev \
        curl \
        xz-utils \
        zlib1g-dev && \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 \
        -o /tmp/Python-${PYTHON_VERSION}.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz" && \
    echo "${PYTHON_SHA256}  /tmp/Python-${PYTHON_VERSION}.tar.xz" | sha256sum -c - && \
    mkdir -p /tmp/python-src && \
    tar -xJf /tmp/Python-${PYTHON_VERSION}.tar.xz -C /tmp/python-src --strip-components=1 && \
    cd /tmp/python-src && \
    ./configure --prefix=/usr/local --enable-shared --with-ensurepip=install && \
    make -j"$(nproc)" && \
    make install

FROM ubuntu:26.04

LABEL org.opencontainers.image.source="https://github.com/PastureStack/server" \
      org.opencontainers.image.description="PastureStack node-agent compatibility base image." \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.version="v0.3.5"

RUN rm -f /usr/bin/pebble

COPY --from=python-builder /usr/local /usr/local
COPY ./pasturestack-entrypoint.sh /
COPY ./share-mnt /usr/bin/share-mnt
COPY ./r /usr/bin/r
COPY ./update-platform-ssl /usr/bin/update-platform-ssl

ARG DOCKER_VERSION=29.5.3
ARG DOCKER_SHA256=34eea64e9c3435f5af1b760827a56a561cd67fc2d6e9cd1813b8bb1e3ff7930b

RUN apt-get update && \
        apt-get install --no-install-recommends -y \
        arptables \
        bridge-utils \
        ca-certificates \
        conntrack \
        curl \
        ethtool \
        iproute2 \
        iptables \
        iputils-ping \
        jq \
        kmod \
        libbz2-1.0 \
        libffi8 \
        libgdbm-compat4t64 \
        libgdbm6t64 \
        liblzma5 \
        libncursesw6 \
        libreadline8t64 \
        libsqlite3-0 \
        libssl3t64 \
        libtcl8.6 \
        libtk8.6 \
        libuuid1 \
        libzstd1 \
        openssl \
        psmisc \
        tcpdump \
        vim-tiny \
        zlib1g && \
    ldconfig && \
    ln -sf /usr/local/bin/python3.14 /usr/local/bin/python3 && \
    ln -sf /usr/local/bin/python3 /usr/local/bin/python && \
    python3 --version && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/lib/cattle /var/lib/rancher && \
    chmod +x /usr/bin/share-mnt /usr/bin/r /usr/bin/update-platform-ssl && \
    docker_tgz=/tmp/docker.tgz && \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 \
        -o "$docker_tgz" "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" && \
    echo "${DOCKER_SHA256}  $docker_tgz" | sha256sum -c - && \
    tar xzf "$docker_tgz" -C /usr/bin --strip-components=1 docker/docker && \
    rm -f "$docker_tgz" && \
    chmod +x /usr/bin/docker && \
    rm /var/run && \
    mkdir /var/run

ENTRYPOINT ["/pasturestack-entrypoint.sh"]

# syntax=docker/dockerfile:1.7
FROM ghcr.io/pasturestack/ubuntu-security-backports:v0.1.0@sha256:2742a3d429e4e14bc587f6dedc51ded4246cf90bbaedcd86c67d0885e32a6f2a AS ubuntu_security_backports
FROM ubuntu:26.04@sha256:2260313b31c8c011cd2eebe728008efac1b3982be73eb71348ea2648d2c0e09b AS python-builder

RUN rm -f /usr/bin/pebble

ENV PYTHON_VERSION=3.14.9
ENV PYTHON_SHA256=e02d9ac21cebda6e46435369744a92c65cc7cd8669697694122cf97ffacd1e53
ARG UBUNTU_SNAPSHOT=20261023T000000Z

COPY ./pip-security-overlay /tmp/pip-security-overlay

ADD --checksum=sha256:5b6326f1932cfd7be57130561dc78192f09ed9f58bfbe6606ed0c50510c3b6cd \
    https://archive.ubuntu.com/ubuntu/pool/main/c/ca-certificates/ca-certificates_20260816ubuntu0.26.04.1_all.deb \
    /tmp/ca-certificates.deb

RUN set -eux; \
    mkdir -p /tmp/ca-bootstrap /etc/ssl/certs; \
    dpkg-deb --extract /tmp/ca-certificates.deb /tmp/ca-bootstrap; \
    find /tmp/ca-bootstrap/usr/share/ca-certificates -type f -name '*.crt' | LC_ALL=C sort | while IFS= read -r certificate; do sed -e '$a\' "${certificate}"; done > /etc/ssl/certs/ca-certificates.crt; \
    rm -rf /tmp/ca-bootstrap; \
    rm -f /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; \
    printf 'Types: deb\nURIs: https://snapshot.ubuntu.com/ubuntu/%s\nSuites: resolute resolute-updates resolute-backports resolute-security\nComponents: main universe restricted multiverse\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\nSnapshot: no\n' "${UBUNTU_SNAPSHOT}" > /etc/apt/sources.list.d/pasturestack-snapshot.sources; \
    printf 'Acquire::Retries "5";\nAcquire::https::CaInfo "/etc/ssl/certs/ca-certificates.crt";\nAcquire::https::Verify-Peer "true";\nAcquire::https::Verify-Host "true";\nAcquire::AllowInsecureRepositories "false";\nAPT::Get::AllowUnauthenticated "false";\n' > /etc/apt/apt.conf.d/80pasturestack-snapshot; \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade --no-install-recommends -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        build-essential \
        ca-certificates \
        git \
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
    dpkg -i /tmp/ca-certificates.deb && \
    test "$(dpkg-query -W -f='${Version}' ca-certificates)" = 20260816ubuntu0.26.04.1 && \
    install -Dm0644 /tmp/ca-certificates.deb /usr/share/pasturestack/ca-certificates.deb && \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 \
        -o /tmp/Python-${PYTHON_VERSION}.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz" && \
    echo "${PYTHON_SHA256}  /tmp/Python-${PYTHON_VERSION}.tar.xz" | sha256sum -c - && \
    mkdir -p /tmp/python-src && \
    tar -xJf /tmp/Python-${PYTHON_VERSION}.tar.xz -C /tmp/python-src --strip-components=1 && \
    cd /tmp/python-src && \
    ./configure --prefix=/usr/local --enable-shared --with-ensurepip=install && \
    make -j"$(nproc)" && \
    make install && \
    ldconfig && \
    python3 /tmp/pip-security-overlay/build-pip-overlay.py --work /tmp/pip-build --output /tmp/pip-dist && \
    echo 'be5f63d537bbe611dc422fabb6740a44b5997888b592888df5091727f023802a  /tmp/pip-dist/pip-26.2.2+pasturestack.1-py3-none-any.whl' | sha256sum -c - && \
    python3 /tmp/pip-security-overlay/install-ensurepip-wheel.py --stdlib /usr/local/lib/python3.14 --wheel /tmp/pip-dist/pip-26.2.2+pasturestack.1-py3-none-any.whl --sha256 be5f63d537bbe611dc422fabb6740a44b5997888b592888df5091727f023802a && \
    python3 -m pip install --no-index --no-deps /tmp/pip-dist/pip-26.2.2+pasturestack.1-py3-none-any.whl && \
    install -Dm0644 /tmp/pip-dist/build-evidence.json /usr/share/pasturestack/pip-build-evidence.json && \
    install -Dm0644 /tmp/pip-dist/pip-vendor.cdx.json /usr/share/pasturestack/pip-vendor.cdx.json && \
    dpkg-query -W -f='${binary:Package}\t${Version}\n' > /usr/share/pasturestack/python-builder-packages.tsv

FROM ubuntu:26.04@sha256:2260313b31c8c011cd2eebe728008efac1b3982be73eb71348ea2648d2c0e09b

ARG VCS_REF
LABEL org.opencontainers.image.source="https://github.com/PastureStack/server" \
      org.opencontainers.image.description="PastureStack node-agent compatibility base image." \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.version="v0.3.7" \
      org.opencontainers.image.revision="$VCS_REF"

RUN rm -f /usr/bin/pebble

COPY --from=python-builder /usr/local /usr/local
COPY --from=python-builder /usr/share/pasturestack/ca-certificates.deb /tmp/ca-certificates.deb
COPY --from=python-builder /usr/share/pasturestack/python-builder-packages.tsv /usr/share/pasturestack/
COPY --from=python-builder /usr/share/pasturestack/pip-build-evidence.json /usr/share/pasturestack/pip-vendor.cdx.json /usr/share/pasturestack/
COPY ./pasturestack-entrypoint.sh /
COPY ./share-mnt /usr/bin/share-mnt
COPY ./r /usr/bin/r
COPY ./update-platform-ssl /usr/bin/update-platform-ssl

ARG DOCKER_VERSION=29.9.2
ARG DOCKER_SHA256=9ac225999fd5e863f7694c728ef23d480616b1e5639328fa309befd4243d69eb
ARG DOCKER_BINARY_SHA256=6c71cfe71faff949a602946a4df4799b563232e79d0b8b6fd343d0ef081c9621
ARG UBUNTU_SNAPSHOT=20261023T000000Z

COPY --from=python-builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

RUN rm -f /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources && \
    printf 'Types: deb\nURIs: https://snapshot.ubuntu.com/ubuntu/%s\nSuites: resolute resolute-updates resolute-backports resolute-security\nComponents: main universe restricted multiverse\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\nSnapshot: no\n' "${UBUNTU_SNAPSHOT}" > /etc/apt/sources.list.d/pasturestack-snapshot.sources && \
    printf 'Acquire::Retries "5";\nAcquire::https::CaInfo "/etc/ssl/certs/ca-certificates.crt";\nAcquire::https::Verify-Peer "true";\nAcquire::https::Verify-Host "true";\nAcquire::AllowInsecureRepositories "false";\nAPT::Get::AllowUnauthenticated "false";\n' > /etc/apt/apt.conf.d/80pasturestack-snapshot && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade --no-install-recommends -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
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
    dpkg -i /tmp/ca-certificates.deb && \
    test "$(dpkg-query -W -f='${Version}' ca-certificates)" = 20260816ubuntu0.26.04.1 && \
    rm -f /tmp/ca-certificates.deb && \
    ldconfig && \
    ln -sf /usr/local/bin/python3.14 /usr/local/bin/python3 && \
    ln -sf /usr/local/bin/python3 /usr/local/bin/python && \
    test "$(python3 --version)" = 'Python 3.14.9' && \
    python3 -c "import pip, ensurepip, pip._vendor.certifi as certifi, pip._vendor.urllib3 as urllib3; assert pip.__version__ == ensurepip.version() == '26.2.2+pasturestack.1'; assert urllib3.__version__ == '2.8.0'; assert certifi.__version__ == '2026.10.19'" && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/lib/cattle /var/lib/rancher && \
    chmod +x /usr/bin/share-mnt /usr/bin/r /usr/bin/update-platform-ssl && \
    docker_tgz=/tmp/docker.tgz && \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 \
        -o "$docker_tgz" "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" && \
    echo "${DOCKER_SHA256}  $docker_tgz" | sha256sum -c - && \
    tar xzf "$docker_tgz" -C /usr/bin --strip-components=1 docker/docker && \
    echo "${DOCKER_BINARY_SHA256}  /usr/bin/docker" | sha256sum -c - && \
    rm -f "$docker_tgz" && \
    chmod +x /usr/bin/docker && \
    rm /var/run && \
    mkdir /var/run

# Only the final runtime consumes these qualified packages. Keep the Python
# compiler stage and the existing coreutils provider unchanged.
RUN --mount=from=ubuntu_security_backports,source=/out,target=/opt/pasturestack/ubuntu-security-backports,ro \
    set -eux; \
    data=/opt/pasturestack/ubuntu-security-backports; \
    evidence=/usr/share/pasturestack/security/ubuntu-backports; \
    mkdir -p "$evidence"; \
    "$data/install-existing-backports" --install-in-docker-build > "$evidence/install.json"; \
    "$data/install-existing-backports" --verify-installed > "$evidence/verify.json"; \
    for name in manifest.json qualification.json source-inputs.lock.json openvex.json; do \
        install -m 0644 "$data/$name" "$evidence/$name"; \
    done; \
    printf '%s\n' 'ghcr.io/pasturestack/ubuntu-security-backports:v0.1.0@sha256:2742a3d429e4e14bc587f6dedc51ded4246cf90bbaedcd86c67d0885e32a6f2a' > "$evidence/bundle-image.txt"; \
    cd "$evidence"; \
    sha256sum manifest.json qualification.json openvex.json source-inputs.lock.json install.json verify.json bundle-image.txt > SHA256SUMS

ENTRYPOINT ["/pasturestack-entrypoint.sh"]

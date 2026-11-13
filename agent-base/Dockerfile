# syntax=docker/dockerfile:1.7
FROM ghcr.io/pasturestack/ubuntu-security-backports:v0.1.1@sha256:45d6b507b63a18459ae5cf76afd4d9731f8ef43b9c40e4c3dbb01899e1752b19 AS ubuntu_security_backports
FROM golang:1.27.4-bookworm@sha256:4fa7c968ba93f1635670522dbb01a2c78150443e1385746924566079f36570ea AS docker_cli
ADD --checksum=sha256:36d502ba53623c50c51fe44f916aeff4c4051b1132aabde2e8982895d0361651 https://codeload.github.com/docker/cli/tar.gz/5457199aa57c45e990c59c89cab5f02b817238d7 /tmp/docker-cli.tgz
WORKDIR /build
RUN set -eux; \
    test "$(go env GOVERSION)" = go1.27.4; \
    tar -xzf /tmp/docker-cli.tgz --strip-components=1; \
    cp vendor.mod go.mod; \
    cp vendor.sum go.sum; \
    export GOTOOLCHAIN=local GOFLAGS=-mod=mod GOPROXY=https://proxy.golang.org GOSUMDB=sum.golang.org; \
    go get golang.org/x/net@v0.62.0; \
    go mod download; \
    go mod verify; \
    export GOPROXY=off; \
    CGO_ENABLED=1 go build -trimpath -buildvcs=false -tags 'grpcnotrace osusergo netgo' \
        -ldflags '-X github.com/docker/cli/cli/version.GitCommit=5457199 -X github.com/docker/cli/cli/version.Version=29.9.3 -linkmode external -extldflags=-static' \
        -o /out/docker ./cmd/docker; \
    go version -m /out/docker > /out/docker-go-version.txt; \
    grep -F 'go1.27.4' /out/docker-go-version.txt; \
    awk '$1=="dep" && $2=="golang.org/x/net" && $3=="v0.62.0" { found=1 } END { exit !found }' /out/docker-go-version.txt; \
    sha256sum /out/docker | cut -d' ' -f1 > /out/docker.sha256

FROM scratch AS apt_security_inputs
ADD --checksum=sha256:0de729b8fe0e1c67c04e8e8d5bd6e0420dbd47f75b93f0b71c8e740edc2d5ffc \
    https://security.ubuntu.com/ubuntu/pool/main/a/apt/apt_3.2.1ubuntu0.1_amd64.deb \
    /tmp/apt.deb
ADD --checksum=sha256:94e5d41303265b66af0f8c70ade18bfb77260ad286edee6c8045faddef82b94c \
    https://security.ubuntu.com/ubuntu/pool/main/a/apt/libapt-pkg7.0_3.2.1ubuntu0.1_amd64.deb \
    /tmp/libapt-pkg7.0.deb
FROM scratch AS perl_security_inputs
ADD --checksum=sha256:90f8eaff943d093fd62036d60aa3d57d6a8bf9836d620e675b0a71be80124d86 \
    https://security.ubuntu.com/ubuntu/pool/main/p/perl/libperl5.40_5.40.1-7ubuntu0.4_amd64.deb \
    /perl/libperl5.40.deb
ADD --checksum=sha256:080d50944d3f9893a93c7e9c28ae403275b2385277640dbd7c67cb53adb2de12 \
    https://security.ubuntu.com/ubuntu/pool/main/p/perl/perl_5.40.1-7ubuntu0.4_amd64.deb \
    /perl/perl.deb
ADD --checksum=sha256:59392eb03fbf15419340c736e2eb4cfd345e03491810711495fccc03264b1f0b \
    https://security.ubuntu.com/ubuntu/pool/main/p/perl/perl-base_5.40.1-7ubuntu0.4_amd64.deb \
    /perl/perl-base.deb
ADD --checksum=sha256:9f96eab53f45388c41e5d470257c1cab231ec33bf968cef65a558b5d8452aeb5 \
    https://security.ubuntu.com/ubuntu/pool/main/p/perl/perl-modules-5.40_5.40.1-7ubuntu0.4_all.deb \
    /perl/perl-modules-5.40.deb

FROM ubuntu:26.04@sha256:2260313b31c8c011cd2eebe728008efac1b3982be73eb71348ea2648d2c0e09b AS python-builder

RUN rm -f /usr/bin/pebble

ENV PYTHON_VERSION=3.14.9
ENV PYTHON_SHA256=e02d9ac21cebda6e46435369744a92c65cc7cd8669697694122cf97ffacd1e53
ARG UBUNTU_SNAPSHOT=20261023T000000Z

COPY ./pip-security-overlay /tmp/pip-security-overlay

ADD --checksum=sha256:a7e3bf769aec16ba21ca39cba180d6d311dafcbae68346a05f137c5cc26c9ca6 \
    https://security.ubuntu.com/ubuntu/pool/main/c/ca-certificates/ca-certificates_20260816ubuntu0.26.04.2_all.deb \
    /tmp/ca-certificates.deb


RUN --mount=from=apt_security_inputs,source=/tmp,target=/opt/official-apt,ro \
    --mount=from=perl_security_inputs,source=/perl,target=/opt/official-perl,ro \
    set -eux; \
    mkdir -p /tmp/ca-bootstrap /etc/ssl/certs; \
    dpkg-deb --extract /tmp/ca-certificates.deb /tmp/ca-bootstrap; \
    find /tmp/ca-bootstrap/usr/share/ca-certificates -type f -name '*.crt' | LC_ALL=C sort | while IFS= read -r certificate; do sed -e '$a\' "${certificate}"; done > /etc/ssl/certs/ca-certificates.crt; \
    rm -rf /tmp/ca-bootstrap; \
    rm -f /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; \
    printf 'Types: deb\nURIs: https://snapshot.ubuntu.com/ubuntu/%s\nSuites: resolute resolute-updates resolute-backports resolute-security\nComponents: main universe restricted multiverse\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\nSnapshot: no\n' "${UBUNTU_SNAPSHOT}" > /etc/apt/sources.list.d/pasturestack-snapshot.sources; \
    printf 'Acquire::Retries "5";\nAcquire::https::CaInfo "/etc/ssl/certs/ca-certificates.crt";\nAcquire::https::Verify-Peer "true";\nAcquire::https::Verify-Host "true";\nAcquire::AllowInsecureRepositories "false";\nAPT::Get::AllowUnauthenticated "false";\n' > /etc/apt/apt.conf.d/80pasturestack-snapshot; \
    dpkg -i /opt/official-apt/libapt-pkg7.0.deb /opt/official-apt/apt.deb && \
    test "$(dpkg-query -W -f='${Version}' apt)" = 3.2.1ubuntu0.1 && \
    test "$(dpkg-query -W -f='${Version}' libapt-pkg7.0)" = 3.2.1ubuntu0.1 && \
    apt-get update --error-on=any && \
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
    dpkg -i /opt/official-perl/*.deb && \
    for package in libperl5.40 perl perl-base perl-modules-5.40; do \
        test "$(dpkg-query -W -f='${Version}' "$package")" = 5.40.1-7ubuntu0.4 || exit 1; \
    done && \
    dpkg -i /tmp/ca-certificates.deb && \
    test "$(dpkg-query -W -f='${Version}' ca-certificates)" = 20260816ubuntu0.26.04.2 && \
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
    echo '2aef7c341eef310645ab56455f5789de2819463b25fa70151954e1d208d2db36  /tmp/pip-dist/pip-26.2.2+pasturestack.2-py3-none-any.whl' | sha256sum -c - && \
    python3 /tmp/pip-security-overlay/install-ensurepip-wheel.py --stdlib /usr/local/lib/python3.14 --wheel /tmp/pip-dist/pip-26.2.2+pasturestack.2-py3-none-any.whl --sha256 2aef7c341eef310645ab56455f5789de2819463b25fa70151954e1d208d2db36 && \
    python3 -m pip install --no-index --no-deps /tmp/pip-dist/pip-26.2.2+pasturestack.2-py3-none-any.whl && \
    install -Dm0644 /tmp/pip-dist/build-evidence.json /usr/share/pasturestack/pip-build-evidence.json && \
    install -Dm0644 /tmp/pip-dist/pip-vendor.cdx.json /usr/share/pasturestack/pip-vendor.cdx.json && \
    dpkg-query -W -f='${binary:Package}\t${Version}\n' > /usr/share/pasturestack/python-builder-packages.tsv

FROM ubuntu:26.04@sha256:2260313b31c8c011cd2eebe728008efac1b3982be73eb71348ea2648d2c0e09b AS qualified_backports

ARG VCS_REF
LABEL org.opencontainers.image.source="https://github.com/PastureStack/server" \
      org.opencontainers.image.description="PastureStack node-agent compatibility base image." \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.version="v0.3.9" \
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

COPY --from=docker_cli /out/docker /usr/bin/docker
COPY --from=docker_cli /out/docker-go-version.txt /out/docker.sha256 /usr/share/pasturestack/
ARG UBUNTU_SNAPSHOT=20261023T000000Z

COPY --from=python-builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

RUN --mount=from=apt_security_inputs,source=/tmp,target=/opt/official-apt,ro \
    --mount=from=perl_security_inputs,source=/perl,target=/opt/official-perl,ro \
    rm -f /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources && \
    printf 'Types: deb\nURIs: https://snapshot.ubuntu.com/ubuntu/%s\nSuites: resolute resolute-updates resolute-backports resolute-security\nComponents: main universe restricted multiverse\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\nSnapshot: no\n' "${UBUNTU_SNAPSHOT}" > /etc/apt/sources.list.d/pasturestack-snapshot.sources && \
    printf 'Acquire::Retries "5";\nAcquire::https::CaInfo "/etc/ssl/certs/ca-certificates.crt";\nAcquire::https::Verify-Peer "true";\nAcquire::https::Verify-Host "true";\nAcquire::AllowInsecureRepositories "false";\nAPT::Get::AllowUnauthenticated "false";\n' > /etc/apt/apt.conf.d/80pasturestack-snapshot && \
    dpkg -i /opt/official-apt/libapt-pkg7.0.deb /opt/official-apt/apt.deb && \
    test "$(dpkg-query -W -f='${Version}' apt)" = 3.2.1ubuntu0.1 && \
    test "$(dpkg-query -W -f='${Version}' libapt-pkg7.0)" = 3.2.1ubuntu0.1 && \
    apt-get update --error-on=any && \
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
    dpkg -i /opt/official-perl/*.deb && \
    for package in libperl5.40 perl perl-base perl-modules-5.40; do \
        test "$(dpkg-query -W -f='${Version}' "$package")" = 5.40.1-7ubuntu0.4 || exit 1; \
    done && \
    dpkg -i /tmp/ca-certificates.deb && \
    test "$(dpkg-query -W -f='${Version}' ca-certificates)" = 20260816ubuntu0.26.04.2 && \
    rm -f /tmp/ca-certificates.deb && \
    ldconfig && \
    ln -sf /usr/local/bin/python3.14 /usr/local/bin/python3 && \
    ln -sf /usr/local/bin/python3 /usr/local/bin/python && \
    test "$(python3 --version)" = 'Python 3.14.9' && \
    python3 -c "import pip, ensurepip, pip._vendor.certifi as certifi, pip._vendor.urllib3 as urllib3; assert pip.__version__ == ensurepip.version() == '26.2.2+pasturestack.2'; assert urllib3.__version__ == '2.8.0'; assert certifi.__version__ == '2026.10.19'" && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/lib/cattle /var/lib/rancher && \
    chmod +x /usr/bin/share-mnt /usr/bin/r /usr/bin/update-platform-ssl && \
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
    printf '%s\n' 'ghcr.io/pasturestack/ubuntu-security-backports:v0.1.1@sha256:45d6b507b63a18459ae5cf76afd4d9731f8ef43b9c40e4c3dbb01899e1752b19' > "$evidence/bundle-image.txt"; \
    cd "$evidence"; \
    sha256sum manifest.json qualification.json openvex.json source-inputs.lock.json install.json verify.json bundle-image.txt > SHA256SUMS

FROM scratch AS official_glibc
ADD --checksum=sha256:be83aefc14597fba683031a520f303950a7338b95d74decbe625faa51c49933e https://security.ubuntu.com/ubuntu/pool/main/g/glibc/libc6_2.43-2ubuntu2.7_amd64.deb /tmp/official-glibc/libc6.deb
ADD --checksum=sha256:c0393ea4fa3c45cefe0351db369d3a4a459edc8045856f2e3612ca17e77b2797 https://security.ubuntu.com/ubuntu/pool/main/g/glibc/libc-bin_2.43-2ubuntu2.7_amd64.deb /tmp/official-glibc/libc-bin.deb
ADD --checksum=sha256:408ba056d39651c2489b59522a614276d7a96020c6a401e73cd0da7d771764b0 https://security.ubuntu.com/ubuntu/pool/main/g/glibc/libc-gconv-modules-extra_2.43-2ubuntu2.7_amd64.deb /tmp/official-glibc/libc-gconv-modules-extra.deb
FROM qualified_backports AS runtime
RUN --mount=from=official_glibc,source=/tmp/official-glibc,target=/tmp/official-glibc,ro \
    set -eux; \
    for package in libc6 libc-bin libc-gconv-modules-extra; do \
        archive="/tmp/official-glibc/$package.deb"; \
        test "$(dpkg-deb -f "$archive" Package)" = "$package"; \
        test "$(dpkg-deb -f "$archive" Source)" = glibc; \
        test "$(dpkg-deb -f "$archive" Architecture)" = amd64; \
        test "$(dpkg-deb -f "$archive" Version)" = 2.43-2ubuntu2.7; \
        dpkg --compare-versions "$(dpkg-query -W -f='${Version}' "$package")" lt 2.43-2ubuntu2.7; \
    done; \
    dpkg --path-include='/usr/share/doc/libc6/*' --path-include='/usr/share/man/man1/getconf.1.gz' \
        --path-include='/usr/share/man/man1/tzselect.1.gz' --install /tmp/official-glibc/*.deb; \
    audit="$(dpkg --audit)"; \
    test -z "$audit"; \
    for package in libc6 libc-bin libc-gconv-modules-extra; do \
        integrity="$(dpkg --verify "$package")"; \
        test -z "$integrity"; \
    done; \
    getent hosts localhost >/dev/null; \
    rm -f /var/cache/ldconfig/aux-cache /var/log/dpkg.log; \
    dpkg-query -W -f='${binary:Package}\t${Version}\n' | LC_ALL=C sort > /usr/share/pasturestack/ubuntu-security-packages.tsv

ENTRYPOINT ["/pasturestack-entrypoint.sh"]

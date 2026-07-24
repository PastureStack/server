# syntax=docker/dockerfile:1.7
FROM ubuntu:26.04

RUN rm -f /usr/bin/pebble

ENV DEBIAN_FRONTEND=noninteractive
ARG TEMURIN_JDK25_URL="https://api.adoptium.net/v3/binary/latest/25/ga/linux/x64/jdk/hotspot/normal/eclipse?project=jdk"
ARG UBUNTU_APT_MIRROR="http://tw.archive.ubuntu.com/ubuntu"
ARG SOURCE_DATE_EPOCH=1784851922
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=${JAVA_HOME}/bin:${PATH}

RUN set -eux; \
    apt_mirror="${UBUNTU_APT_MIRROR%/}"; \
    find /etc/apt -type f \( -name '*.list' -o -name '*.sources' \) -exec sed -i \
        -e "s|http://security.ubuntu.com/ubuntu|${apt_mirror}|g" \
        -e "s|http://archive.ubuntu.com/ubuntu|${apt_mirror}|g" {} +; \
    printf 'Acquire::Retries "5";\nAcquire::http::Timeout "30";\nAcquire::https::Timeout "30";\nAcquire::http::Pipeline-Depth "0";\n' > /etc/apt/apt.conf.d/80rc16-retries; \
    apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
                    bash \
                    ca-certificates \
                    curl \
                    fontconfig \
                    git \
                    gzip \
                    iproute2 \
                    iptables \
                    keychain \
                    libfreetype6 \
                    mariadb-client \
                    mariadb-server \
                    openssh-client \
                    procps \
                    tar \
                    tzdata \
                    unzip \
                    xz-utils \
    && rm -rf /var/lib/apt/lists/* \
                  /var/lib/mariadb \
                  /var/cache/fontconfig/* \
                  /var/cache/ldconfig/aux-cache \
                  /var/log/apt/* \
                  /var/log/alternatives.log \
                  /var/log/dpkg.log \
    && : > /etc/machine-id

RUN mkdir -p ${JAVA_HOME} /usr/lib/jvm && \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o /tmp/temurin-jdk25.tar.gz "${TEMURIN_JDK25_URL}" && \
    tar -xzf /tmp/temurin-jdk25.tar.gz -C ${JAVA_HOME} --strip-components=1 && \
    rm -f /tmp/temurin-jdk25.tar.gz && \
    ln -s ${JAVA_HOME} /usr/lib/jvm/temurin-25-amd64 && \
    ln -s ${JAVA_HOME}/bin/java /usr/bin/java && \
    ln -s ${JAVA_HOME}/bin/jar /usr/bin/jar && \
    ln -s ${JAVA_HOME}/bin/javac /usr/bin/javac && \
    update-ca-certificates -f && \
    java -version

COPY bin/* /usr/bin/

ENV CATTLE_HOME=/var/lib/cattle
ENV RC16_CATTLE_UID=10001
ENV RC16_CATTLE_GID=10001
ENV GMS_BIN_DIR=/var/lib/cattle/bin
RUN set -eux; \
    groupadd --gid "${RC16_CATTLE_GID}" cattle; \
    useradd --uid "${RC16_CATTLE_UID}" --gid cattle --home-dir "${CATTLE_HOME}" --create-home --shell /usr/sbin/nologin cattle; \
    mkdir -p "${CATTLE_HOME}/logs"; \
    chown -R "${RC16_CATTLE_UID}:${RC16_CATTLE_GID}" "${CATTLE_HOME}"
ENV CATTLE_DB_CATTLE_DATABASE=mysql
ENV CATTLE_DB_CATTLE_H2_URL=jdbc:h2:/var/lib/cattle/database/db-cattle;MODE=MySQL;DATABASE_TO_LOWER=TRUE;CASE_INSENSITIVE_IDENTIFIERS=TRUE;NON_KEYWORDS=KEY,VALUE
ENV CATTLE_USE_LOCAL_ARTIFACTS=true
ENV no_proxy=localhost,127.0.0.1,localaddress,.localdomain.com
COPY artifacts/ /usr/share/cattle/

COPY service/ /service/
ENV S6_SERVICE_DIR=/service

COPY target/*static.tar.gz /s6-statics/

EXPOSE 8080
ENV CATTLE_HOST_API_PROXY_MODE=embedded


# Environment variables commonly updated when performing a release
ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.276
ENV CATTLE_CATTLE_VERSION=v0.183.269
ENV CATTLE_RANCHER_CLI_VERSION=v0.6.14
ENV CATTLE_RANCHER_COMPOSE_VERSION=v0.14.31
ENV CATTLE_UI_VERSION=1.6.56
ENV CATTLE_API_UI_VERSION=1.1.14
ARG RC16_GO_AGENT_VERSION=0.13.21
ARG WINDOWS_AGENT_VERSION=0.13.21
ARG WINDOWS_AGENT_ARTIFACT_SHA256=f511a41c0eb410473e1a223b70f7e8046b38f99e64b5b01167a4ca8c09a496e7
ARG RC16_HOST_API_VERSION=0.38.4
ARG CATALOG_SERVICE_VERSION=0.20.6
ARG CATALOG_SERVICE_ARTIFACT_SHA256=5099bf0c69aad625dcd4c857b573496c88243c068891699293c99771859a414d
ARG AUTHENTICATION_SERVICE_VERSION=0.1.7
ARG AUTHENTICATION_SERVICE_ARTIFACT_SHA256=093ab5f5c7e733e56a7e5af5795bf49b4339234e2235ded36c5b854bc8b103bb
ARG COMPOSE_EXECUTOR_VERSION=0.14.31
ARG COMPOSE_EXECUTOR_BINARY_SHA256=04f6e5d165514daee28f225182ad813ca165edd8bac901e20476e8532cf656b2
ARG HOST_PROVISIONER_VERSION=0.39.4
ARG HOST_PROVISIONER_BINARY_SHA256=dba5fd4d423a49f35a443951ac274ea680305a5a7a5945623139417c2e60ada3
ARG MACHINE_DRIVER_BUNDLE_VERSION=0.14.0
ARG MACHINE_MANAGER_BINARY_SHA256=a4c69bffb78d3cfe103b89dae61c3ea11cc2d1a91c4ff86e630c9ae88244db02
ARG PACKET_DRIVER_BINARY_SHA256=e77c635969a76f498d7088904acd375f25b79a81632b87fa9e5cc5b8e2e72184
ARG VSPHERE_CLI_BUNDLE_VERSION=0.54.1
ARG GOVC_BINARY_SHA256=115af2599f9c9939ee44cbd8218e5fe70e42d7957fd66f1ecad4148a1b980e2a
ARG SECRET_DELIVERY_API_VERSION=0.2.2
ARG SECRET_DELIVERY_API_BINARY_SHA256=e62141d968cc5323bc53ad0cdc3630239b9e27e7ab5a212bf40a321c48e5dd1a
ARG USAGE_TELEMETRY_AGENT_VERSION=0.4.0-pasturestack.1
ARG USAGE_TELEMETRY_AGENT_BINARY_SHA256=3c587d14ffed4640090cf5c532a1844b41d1b3c225f51507053ec3bd77714093
ARG WEBHOOK_AUTOMATION_SERVICE_VERSION=0.9.15-pasturestack.1
ARG WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256=195cec94370e5ab61bcba1bbbad6b048dbc1dd3d5bf696fe690017b3bda57e9a
ARG PER_HOST_SUBNET_VERSION=0.2.4
ARG PER_HOST_SUBNET_WINDOWS_ARTIFACT_SHA256=2521cb61c0e001f2d6b4c16e920d2f62180a1bdf63e62f70544e2abdc24f9e2b
ARG GRAPHITE_EXPORTER_VERSION=0.2.0
ARG GRAPHITE_EXPORTER_ARTIFACT_SHA256=1058b72a73f568adc24191f74e972ed6be0d932b9a80f43a7043e4e3d0501388
ARG GRAPHITE_EXPORTER_BINARY_SHA256=a27df929e213a3e87adf057f3af2f9bb6d4b8c92d49c1795e6a79bd117f0e5d9
ARG RUNTIME_LICENSE_BUNDLE_VERSION=1.6.274
ARG RUNTIME_LICENSE_BUNDLE_SHA256=b854af190ed6c3519a8425b5d35ea8d2e734edc84cba711f5c284e7060064641
ARG PASTURESTACK_SERVER_REVISION=unknown
LABEL org.opencontainers.image.source="https://github.com/PastureStack/server" \
      org.opencontainers.image.description="PastureStack server compatibility image." \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.version="v1.6.276" \
      org.opencontainers.image.revision="${PASTURESTACK_SERVER_REVISION}"
ENV DEFAULT_CATTLE_AGENT_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.31@sha256:89a1703d236fb2ba34d568faef1cf0a41f91a2a5a7e6b8052415ba5a12f2d0e1
ENV DEFAULT_CATTLE_BOOTSTRAP_REQUIRED_IMAGE=ghcr.io/pasturestack/node-agent:v1.2.31@sha256:89a1703d236fb2ba34d568faef1cf0a41f91a2a5a7e6b8052415ba5a12f2d0e1
ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE=ghcr.io/pasturestack/load-balancer-service:v0.9.25@sha256:7a41ff94e6d6f2e8e08e5cd078243861bc74442ade4630f5d940c46a89a12f24
ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE_UUID=docker:ghcr.io/pasturestack/load-balancer-service:v0.9.25@sha256:7a41ff94e6d6f2e8e08e5cd078243861bc74442ade4630f5d940c46a89a12f24
ENV PASTURESTACK_CATALOG_COMMIT=91f5910a44cb181051be2adc4c14f0e6ec7842ef
ENV DEFAULT_CATTLE_CATALOG_URL='{"catalogs":{"pasturestack":{"url":"https://github.com/PastureStack/catalog-templates.git","branch":"main","pinnedCommit":"91f5910a44cb181051be2adc4c14f0e6ec7842ef"}}}'


ENV DEFAULT_CATTLE_RANCHER_COMPOSE_LINUX_URL=
ENV DEFAULT_CATTLE_RANCHER_COMPOSE_DARWIN_URL=
ENV DEFAULT_CATTLE_RANCHER_COMPOSE_WINDOWS_URL=
ENV DEFAULT_CATTLE_RANCHER_CLI_LINUX_URL=
ENV DEFAULT_CATTLE_RANCHER_CLI_DARWIN_URL=
ENV DEFAULT_CATTLE_RANCHER_CLI_WINDOWS_URL=

EXPOSE 3306
RUN --mount=type=secret,id=rc16_artifact_base_url \
    set -eu; \
    artifact_base="$(cat /run/secrets/rc16_artifact_base_url)"; \
    artifact_base="${artifact_base%/}"; \
    checksum_file=/usr/share/cattle/release-SHA256SUMS; \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o "${checksum_file}.tmp" "${artifact_base}/SHA256SUMS"; \
    mv "${checksum_file}.tmp" "${checksum_file}"; \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o /usr/share/cattle/cattle.jar "${artifact_base}/orchestration-engine-${CATTLE_CATTLE_VERSION#v}.jar"; \
    bash /usr/share/cattle/verify_release_asset "${checksum_file}" /usr/share/cattle/cattle.jar "orchestration-engine-${CATTLE_CATTLE_VERSION#v}.jar"
COPY artifacts/ /usr/share/cattle/
RUN sed -i 's/\r$//' /usr/share/cattle/*.sh /usr/share/cattle/install_cattle_binaries /usr/bin/entry /service/*/*

RUN --mount=type=secret,id=rc16_artifact_base_url \
    set -eu; \
    artifact_base="$(cat /run/secrets/rc16_artifact_base_url)"; \
    artifact_base="${artifact_base%/}"; \
    cd /; \
    for i in $(ls /s6-statics/*static.tar.gz); do tar -C /usr -zxvf "$i"; done; \
    rm -rf /s6-statics/*static.tar.gz; \
    mkdir -p "$CATTLE_HOME"; \
    cd /usr/share/cattle; \
    HASH="$(sha256sum cattle.jar | awk '{print $1}')"; \
    rm -rf "$HASH" war; \
    mkdir "$HASH"; \
    ln -s "$HASH" war; \
    cd war; \
    unzip -q ../cattle.jar; \
    if [ -f resources.jar ]; then unzip -oq resources.jar; rm -f resources.jar; fi; \
    test -d WEB-INF/lib; \
    test -f io/cattle/platform/launcher/Main.class; \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o /tmp/web-console.tar.gz "${artifact_base}/web-console-${CATTLE_UI_VERSION}.tar.gz"; \
    bash /usr/share/cattle/verify_release_asset /usr/share/cattle/release-SHA256SUMS /tmp/web-console.tar.gz "web-console-${CATTLE_UI_VERSION}.tar.gz"; \
    tar xzf /tmp/web-console.tar.gz -C /usr/share/cattle/war --strip-components=1; \
    mkdir -p /usr/share/cattle/war/api-ui; \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o /tmp/api-explorer.tar.gz "${artifact_base}/api-explorer-${CATTLE_API_UI_VERSION}.tar.gz"; \
    bash /usr/share/cattle/verify_release_asset /usr/share/cattle/release-SHA256SUMS /tmp/api-explorer.tar.gz "api-explorer-${CATTLE_API_UI_VERSION}.tar.gz"; \
    tar xzf /tmp/api-explorer.tar.gz -C /usr/share/cattle/war/api-ui --strip-components=1; \
    find /usr/share/cattle -path '*/translations/*.json' -type f -exec perl -0pi \
        -e 's/-{0,5}BEGIN RSA PRIV[A]TE[ ]KEY-{0,5}/[key material header]/g; s/-{0,5}END RSA PRIV[A]TE[ ]KEY-{0,5}/[key material footer]/g' {} +; \
    export RC16_ARTIFACT_BASE_URL="$artifact_base"; \
    export RC16_GO_AGENT_VERSION="${RC16_GO_AGENT_VERSION}"; \
    export RC16_WINDOWS_AGENT_VERSION="${WINDOWS_AGENT_VERSION}"; \
    export RC16_HOST_API_VERSION="${RC16_HOST_API_VERSION}"; \
    export RC16_COMPOSE_EXECUTOR_VERSION="${COMPOSE_EXECUTOR_VERSION}"; \
    export RC16_HOST_PROVISIONER_VERSION="${HOST_PROVISIONER_VERSION}"; \
    export RC16_MACHINE_DRIVER_BUNDLE_VERSION="${MACHINE_DRIVER_BUNDLE_VERSION}"; \
    export RC16_VSPHERE_CLI_BUNDLE_VERSION="${VSPHERE_CLI_BUNDLE_VERSION}"; \
    export RC16_SECRET_DELIVERY_API_VERSION="${SECRET_DELIVERY_API_VERSION}"; \
    export RC16_USAGE_TELEMETRY_AGENT_VERSION="${USAGE_TELEMETRY_AGENT_VERSION}"; \
    export RC16_WEBHOOK_AUTOMATION_SERVICE_VERSION="${WEBHOOK_AUTOMATION_SERVICE_VERSION}"; \
    export RC16_PER_HOST_SUBNET_VERSION="${PER_HOST_SUBNET_VERSION}"; \
    /usr/share/cattle/install_cattle_binaries; \
    test -x /usr/bin/compose-executor; \
    echo "${COMPOSE_EXECUTOR_BINARY_SHA256}  /usr/bin/compose-executor" | sha256sum -c -; \
    ln -sfn compose-executor /usr/bin/rancher-compose-executor; \
    test -x /usr/bin/host-provisioner; \
    echo "${HOST_PROVISIONER_BINARY_SHA256}  /usr/bin/host-provisioner" | sha256sum -c -; \
    ln -sfn host-provisioner /usr/bin/go-machine-service; \
    test -x /usr/bin/docker-machine; \
    echo "${MACHINE_MANAGER_BINARY_SHA256}  /usr/bin/docker-machine" | sha256sum -c -; \
    test -x /usr/bin/docker-machine-driver-packet; \
    echo "${PACKET_DRIVER_BINARY_SHA256}  /usr/bin/docker-machine-driver-packet" | sha256sum -c -; \
    /usr/bin/docker-machine version | grep -F "version ${MACHINE_DRIVER_BUNDLE_VERSION}" >/dev/null; \
    machine_license_dir=/usr/share/licenses/pasturestack/machine-driver-bundle; \
    mkdir -p "${machine_license_dir}"; \
    for name in machine-driver-bundle-LICENSES.txt machine-driver-bundle-SOURCES.txt machine-driver-bundle-THIRD-PARTY-NOTICES.txt; do \
        test -f "/usr/bin/${name}"; \
        mv "/usr/bin/${name}" "${machine_license_dir}/${name}"; \
    done; \
    test -x /usr/bin/govc; \
    echo "${GOVC_BINARY_SHA256}  /usr/bin/govc" | sha256sum -c -; \
    test "$(/usr/bin/govc version)" = "govc ${VSPHERE_CLI_BUNDLE_VERSION}"; \
    /usr/bin/govc version -l | grep -Fx 'Build Commit: e6cfff79a15f' >/dev/null; \
    vsphere_license_dir=/usr/share/licenses/pasturestack/vsphere-cli-bundle; \
    mkdir -p "${vsphere_license_dir}"; \
    for name in vsphere-cli-bundle-LICENSES.txt vsphere-cli-bundle-SOURCES.txt vsphere-cli-bundle-THIRD-PARTY-NOTICES.txt; do \
        test -f "/usr/bin/${name}"; \
        mv "/usr/bin/${name}" "${vsphere_license_dir}/${name}"; \
    done; \
    test -x /usr/bin/secret-delivery-api; \
    echo "${SECRET_DELIVERY_API_BINARY_SHA256}  /usr/bin/secret-delivery-api" | sha256sum -c -; \
    /usr/bin/secret-delivery-api --version | grep -F "v${SECRET_DELIVERY_API_VERSION}" >/dev/null; \
    ln -sfn secret-delivery-api /usr/bin/secrets-api; \
    secret_delivery_license_dir=/usr/share/licenses/pasturestack/secret-delivery-api; \
    mkdir -p "${secret_delivery_license_dir}"; \
    for name in secret-delivery-api-LICENSES.txt secret-delivery-api-SOURCES.txt secret-delivery-api-THIRD-PARTY-NOTICES.md; do \
        test -f "/usr/bin/${name}"; \
        mv "/usr/bin/${name}" "${secret_delivery_license_dir}/${name}"; \
    done; \
    test -x /usr/bin/usage-telemetry-agent; \
    echo "${USAGE_TELEMETRY_AGENT_BINARY_SHA256}  /usr/bin/usage-telemetry-agent" | sha256sum -c -; \
    /usr/bin/usage-telemetry-agent --version | grep -F "v${USAGE_TELEMETRY_AGENT_VERSION}" >/dev/null; \
    ln -sfn usage-telemetry-agent /usr/bin/telemetry; \
    usage_telemetry_license_dir=/usr/share/licenses/pasturestack/usage-telemetry-agent; \
    mkdir -p "${usage_telemetry_license_dir}"; \
    for name in usage-telemetry-agent-LICENSES.txt usage-telemetry-agent-PRIVACY.md usage-telemetry-agent-SOURCES.txt usage-telemetry-agent-THIRD-PARTY-NOTICES.md; do \
        test -f "/usr/bin/${name}"; \
        mv "/usr/bin/${name}" "${usage_telemetry_license_dir}/${name}"; \
    done; \
    test -x /usr/bin/webhook-automation-service; \
    echo "${WEBHOOK_AUTOMATION_SERVICE_BINARY_SHA256}  /usr/bin/webhook-automation-service" | sha256sum -c -; \
    /usr/bin/webhook-automation-service --version | grep -F "v${WEBHOOK_AUTOMATION_SERVICE_VERSION}" >/dev/null; \
    ln -sfn webhook-automation-service /usr/bin/webhook-service; \
    webhook_automation_license_dir=/usr/share/licenses/pasturestack/webhook-automation-service; \
    mkdir -p "${webhook_automation_license_dir}"; \
    for name in webhook-automation-service-COMPATIBILITY.md webhook-automation-service-LICENSES.txt webhook-automation-service-SOURCES.txt webhook-automation-service-THIRD-PARTY-NOTICES.md; do \
        test -f "/usr/bin/${name}"; \
        mv "/usr/bin/${name}" "${webhook_automation_license_dir}/${name}"; \
    done; \
    test -f "/usr/share/cattle/artifacts/per-host-subnet-${PER_HOST_SUBNET_VERSION}-windows-amd64.zip"; \
    echo "${PER_HOST_SUBNET_WINDOWS_ARTIFACT_SHA256}  /usr/share/cattle/artifacts/per-host-subnet-${PER_HOST_SUBNET_VERSION}-windows-amd64.zip" | sha256sum -c -; \
    test -f "/usr/share/cattle/artifacts/node-agent-${WINDOWS_AGENT_VERSION}-windows-amd64.zip"; \
    echo "${WINDOWS_AGENT_ARTIFACT_SHA256}  /usr/share/cattle/artifacts/node-agent-${WINDOWS_AGENT_VERSION}-windows-amd64.zip" | sha256sum -c -; \
    unset RC16_ARTIFACT_BASE_URL; \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o /tmp/graphite_exporter.tar.gz "${artifact_base}/graphite_exporter-${GRAPHITE_EXPORTER_VERSION}.linux-amd64.tar.gz"; \
    bash /usr/share/cattle/verify_release_asset /usr/share/cattle/release-SHA256SUMS /tmp/graphite_exporter.tar.gz "graphite_exporter-${GRAPHITE_EXPORTER_VERSION}.linux-amd64.tar.gz"; \
    echo "${GRAPHITE_EXPORTER_ARTIFACT_SHA256}  /tmp/graphite_exporter.tar.gz" | sha256sum -c -; \
    graphite_archive_root="graphite_exporter-${GRAPHITE_EXPORTER_VERSION}.linux-amd64"; \
    graphite_tmp_dir="$(mktemp -d)"; \
    tar -xzf /tmp/graphite_exporter.tar.gz -C "${graphite_tmp_dir}" -- \
        "${graphite_archive_root}/graphite_exporter" \
        "${graphite_archive_root}/LICENSE" \
        "${graphite_archive_root}/NOTICE"; \
    install -m 0755 "${graphite_tmp_dir}/${graphite_archive_root}/graphite_exporter" /usr/bin/graphite_exporter; \
    echo "${GRAPHITE_EXPORTER_BINARY_SHA256}  /usr/bin/graphite_exporter" | sha256sum -c -; \
    /usr/bin/graphite_exporter --version 2>&1 | grep -F "version ${GRAPHITE_EXPORTER_VERSION}" >/dev/null; \
    mkdir -p /usr/share/licenses/graphite-exporter; \
    install -m 0644 "${graphite_tmp_dir}/${graphite_archive_root}/LICENSE" /usr/share/licenses/graphite-exporter/LICENSE; \
    install -m 0644 "${graphite_tmp_dir}/${graphite_archive_root}/NOTICE" /usr/share/licenses/graphite-exporter/NOTICE; \
    rm -rf "${graphite_tmp_dir}"; \
    test -x /usr/bin/graphite_exporter; \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o /tmp/runtime-licenses.tar.xz "${artifact_base}/pasturestack-runtime-licenses-${RUNTIME_LICENSE_BUNDLE_VERSION}.tar.xz"; \
    bash /usr/share/cattle/verify_release_asset /usr/share/cattle/release-SHA256SUMS /tmp/runtime-licenses.tar.xz "pasturestack-runtime-licenses-${RUNTIME_LICENSE_BUNDLE_VERSION}.tar.xz"; \
    echo "${RUNTIME_LICENSE_BUNDLE_SHA256}  /tmp/runtime-licenses.tar.xz" | sha256sum -c -; \
    mkdir -p /usr/share/licenses/pasturestack-runtime; \
    tar -xJf /tmp/runtime-licenses.tar.xz -C /usr/share/licenses/pasturestack-runtime --strip-components=1; \
    (cd /usr/share/licenses/pasturestack-runtime && sha256sum -c FILES.sha256 >/dev/null); \
    test -f /usr/share/licenses/pasturestack-runtime/SOURCES.tsv; \
    test -f /usr/share/licenses/pasturestack-runtime/source-legal/server/LICENSE; \
    rm -f /tmp/web-console.tar.gz /tmp/api-explorer.tar.gz /tmp/graphite_exporter.tar.gz /tmp/runtime-licenses.tar.xz

RUN --mount=type=secret,id=rc16_artifact_base_url \
    set -eu; \
    artifact_base="$(cat /run/secrets/rc16_artifact_base_url)"; \
    artifact_base="${artifact_base%/}"; \
    auth_logic_target="$(find /usr/share/cattle/war/WEB-INF/lib -maxdepth 1 -type f -name 'cattle-iaas-auth-logic-*.jar' -print -quit)"; \
    test -n "${auth_logic_target}"; \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o /tmp/orchestration-engine-auth-logic.jar "${artifact_base}/orchestration-engine-auth-logic-${CATTLE_CATTLE_VERSION#v}.jar"; \
    bash /usr/share/cattle/verify_release_asset /usr/share/cattle/release-SHA256SUMS /tmp/orchestration-engine-auth-logic.jar "orchestration-engine-auth-logic-${CATTLE_CATTLE_VERSION#v}.jar"; \
    install -m 0644 /tmp/orchestration-engine-auth-logic.jar "${auth_logic_target}"; \
    rm -f /tmp/orchestration-engine-auth-logic.jar

COPY patches/service-auth.json /tmp/rc16-patches/schema/service/service-auth.json
COPY patches/bootstrap.sh /tmp/rc16-patches/config-content/bootstrap/bootstrap.sh
COPY patches/db/core-060.xml /tmp/rc16-patches/db/core-060.xml
COPY patches/db/core-124.xml /tmp/rc16-patches/db/core-124.xml

RUN set -eux; \
    cd /tmp/rc16-patches; \
    resources_jar="$(find /usr/share/cattle/war/WEB-INF/lib -maxdepth 1 -type f -name 'cattle-resources-*.jar' -print -quit)"; \
    test -n "${resources_jar}"; \
    source_date_iso="$(date -u -d "@${SOURCE_DATE_EPOCH}" '+%Y-%m-%dT%H:%M:%SZ')"; \
    jar --update --file "${resources_jar}" --date="${source_date_iso}" schema/service/service-auth.json config-content/bootstrap/bootstrap.sh db/core-060.xml db/core-124.xml; \
    rm -rf /tmp/rc16-patches

COPY patches/PatchV1GlobalSubscribe.java /tmp/rc16-patches/PatchV1GlobalSubscribe.java

RUN set -eux; \
    mkdir -p /tmp/rc16-patches/schema/v1; \
    cd /tmp/rc16-patches; \
    resources_jar="$(find /usr/share/cattle/war/WEB-INF/lib -maxdepth 1 -type f -name 'cattle-resources-*.jar' -print -quit)"; \
    test -n "${resources_jar}"; \
    jar xf "${resources_jar}" schema/v1/admin.ser schema/v1/project.ser schema/v1/service.ser; \
    javac -cp "/usr/share/cattle/war/WEB-INF/lib/*" PatchV1GlobalSubscribe.java; \
    java -cp ".:/usr/share/cattle/war/WEB-INF/lib/*" PatchV1GlobalSubscribe; \
    source_date_iso="$(date -u -d "@${SOURCE_DATE_EPOCH}" '+%Y-%m-%dT%H:%M:%SZ')"; \
    jar --update --file "${resources_jar}" --date="${source_date_iso}" schema/v1/admin.ser schema/v1/service.ser; \
    rm -rf /tmp/rc16-patches

COPY patches/websocket-proxy-wrapper.sh /tmp/rc16-patches/websocket-proxy-wrapper.sh

RUN set -eux; \
    install_service_wrapper() { \
        canonical="$1"; \
        legacy="${2:-}"; \
        if [ -x "/usr/bin/${canonical}" ]; then \
            if ! grep -F 'RC16_WRAPPER_REAL_DIR' "/usr/bin/${canonical}" >/dev/null 2>&1; then \
                mv -Tf "/usr/bin/${canonical}" "/usr/bin/${canonical}.real"; \
            fi; \
            cp /tmp/rc16-patches/websocket-proxy-wrapper.sh "/usr/bin/${canonical}"; \
            chmod 0755 "/usr/bin/${canonical}" "/usr/bin/${canonical}.real"; \
            if [ -n "${legacy}" ]; then \
                rm -f "/usr/bin/${legacy}" "/usr/bin/${legacy}.real"; \
                ln -sfn "${canonical}" "/usr/bin/${legacy}"; \
            fi; \
        fi; \
    }; \
    install_service_wrapper websocket-proxy; \
    install_service_wrapper compose-executor rancher-compose-executor; \
    install_service_wrapper host-provisioner go-machine-service; \
    rm -rf /tmp/rc16-patches

RUN --mount=type=secret,id=rc16_artifact_base_url \
    set -eu; \
    artifact_base="$(cat /run/secrets/rc16_artifact_base_url)"; \
    artifact_base="${artifact_base%/}"; \
    tmp_dir="$(mktemp -d)"; \
    catalog_archive="${tmp_dir}/catalog-service-${CATALOG_SERVICE_VERSION}.tar.xz"; \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o "${catalog_archive}" "${artifact_base}/catalog-service-${CATALOG_SERVICE_VERSION}.tar.xz"; \
    bash /usr/share/cattle/verify_release_asset /usr/share/cattle/release-SHA256SUMS "${catalog_archive}"; \
    echo "${CATALOG_SERVICE_ARTIFACT_SHA256}  ${catalog_archive}" | sha256sum -c -; \
    tar -xJf "${catalog_archive}" -C "${tmp_dir}"; \
    install -m 0755 "${tmp_dir}/catalog-service" /usr/bin/catalog-service; \
    install -m 0755 "${tmp_dir}/catalog-service-sqlite" /usr/bin/catalog-service-sqlite; \
    ln -sfn catalog-service /usr/bin/rancher-catalog-service; \
    ln -sfn catalog-service-sqlite /usr/bin/rancher-catalog-service-sqlite; \
    auth_archive="${tmp_dir}/authentication-service-${AUTHENTICATION_SERVICE_VERSION}-linux-amd64.tar.xz"; \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o "${auth_archive}" "${artifact_base}/authentication-service-${AUTHENTICATION_SERVICE_VERSION}-linux-amd64.tar.xz"; \
    bash /usr/share/cattle/verify_release_asset /usr/share/cattle/release-SHA256SUMS "${auth_archive}"; \
    echo "${AUTHENTICATION_SERVICE_ARTIFACT_SHA256}  ${auth_archive}" | sha256sum -c -; \
    tar -xJf "${auth_archive}" -C "${tmp_dir}"; \
    install -m 0755 "${tmp_dir}/authentication-service" /usr/bin/authentication-service; \
    ln -sfn authentication-service /usr/bin/rancher-auth-service; \
    rm -rf "${tmp_dir}"; \
    chmod 0755 /usr/bin/catalog-service /usr/bin/catalog-service-sqlite /usr/bin/authentication-service; \
    sha256sum /usr/bin/catalog-service /usr/bin/catalog-service-sqlite /usr/bin/authentication-service

RUN --mount=type=secret,id=rc16_artifact_base_url \
    set -eu; \
    artifact_base="$(cat /run/secrets/rc16_artifact_base_url)"; \
    artifact_base="${artifact_base%/}"; \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o "/usr/share/cattle/artifacts/node-agent-${RC16_GO_AGENT_VERSION}.tar.gz" "${artifact_base}/node-agent-${RC16_GO_AGENT_VERSION}.tar.gz"; \
    curl -fsSL --retry 5 --retry-all-errors --retry-delay 2 --connect-timeout 10 --max-time 300 -o "/usr/share/cattle/artifacts/host-api-${RC16_HOST_API_VERSION}.tar.gz" "${artifact_base}/host-api-${RC16_HOST_API_VERSION}.tar.gz"; \
    bash /usr/share/cattle/verify_release_asset /usr/share/cattle/release-SHA256SUMS "/usr/share/cattle/artifacts/node-agent-${RC16_GO_AGENT_VERSION}.tar.gz"; \
    bash /usr/share/cattle/verify_release_asset /usr/share/cattle/release-SHA256SUMS "/usr/share/cattle/artifacts/host-api-${RC16_HOST_API_VERSION}.tar.gz"; \
    ln -sf "node-agent-${RC16_GO_AGENT_VERSION}.tar.gz" /usr/share/cattle/artifacts/go-agent.tar.gz; \
    ln -sf "host-api-${RC16_HOST_API_VERSION}.tar.gz" /usr/share/cattle/artifacts/host-api.tar.gz; \
    sha256sum "/usr/share/cattle/artifacts/node-agent-${RC16_GO_AGENT_VERSION}.tar.gz" "/usr/share/cattle/artifacts/host-api-${RC16_HOST_API_VERSION}.tar.gz"

RUN set -eux; \
    cd "$CATTLE_HOME"; \
    echo "$DEFAULT_CATTLE_CATALOG_URL" | sed 's/${RELEASE}/'$(echo $CATTLE_RANCHER_SERVER_VERSION | sed -E 's/(v[0-9]+\.[0-9]+).*/\1-release/')/g > repo.json; \
    cat repo.json; \
    catalog-service-sqlite --sqlite --validate --config repo.json; \
    find cache -mindepth 2 -maxdepth 2 -type d -exec touch {}/.nopurge \; 2>/dev/null || true; \
    find cache -type f \( -path '*/.git/index' -o -path '*/.git/logs/*' \) -delete; \
    find cache -type d -path '*/.git/logs' -prune -exec rm -rf {} +; \
    rm -f local.db

RUN set -eux; \
    find /usr/share/cattle /usr/share/perl /var/lib/cattle -type f \
        \( -name '*.js' -o -name '*.json' -o -name '*.yml' -o -name '*.yaml' -o -name '*.db' -o -name '*.pm' \) \
        -exec perl -0pi -e 's/test:test\@/test-test\@/g; s/username:password\@/username-password\@/g; s/user:pass\@/user-pass\@/g; s/USER:PASS\@/USER-PASS\@/g; s/john%40example\.com:password\@/john%40example.com-password\@/g; $old_image = "ubuntu:" . "14" . ".04.3"; s/\Q$old_image\E/ubuntu:26.04/g' {} + && \
    find /usr/share/cattle -type f -name '*.map' -delete

COPY patches/websocket-proxy-wrapper.sh /tmp/rc16-patches/websocket-proxy-wrapper.sh

RUN set -eux; \
    install_service_wrapper() { \
        canonical="$1"; \
        legacy="$2"; \
        if [ -x "/usr/bin/${canonical}" ]; then \
            if ! grep -F 'RC16_WRAPPER_REAL_DIR' "/usr/bin/${canonical}" >/dev/null 2>&1; then \
                mv -Tf "/usr/bin/${canonical}" "/usr/bin/${canonical}.real"; \
            fi; \
            cp /tmp/rc16-patches/websocket-proxy-wrapper.sh "/usr/bin/${canonical}"; \
            chmod 0755 "/usr/bin/${canonical}" "/usr/bin/${canonical}.real"; \
            rm -f "/usr/bin/${legacy}" "/usr/bin/${legacy}.real"; \
            ln -sfn "${canonical}" "/usr/bin/${legacy}"; \
        fi; \
    }; \
    install_service_wrapper catalog-service rancher-catalog-service; \
    install_service_wrapper authentication-service rancher-auth-service; \
    rm -rf /tmp/rc16-patches

VOLUME /var/lib/mysql /var/log/mysql /var/lib/cattle

ENV PASTURESTACK_RELEASE_BASE_URL=https://github.com/PastureStack/server/releases/download/v1.6.276
ENV RC16_ARTIFACT_BASE_URL=https://github.com/PastureStack/server/releases/download/v1.6.276
ENV CATTLE_API_UI_URL=
ENV DEFAULT_CATTLE_API_UI_INDEX=local
ENV DEFAULT_CATTLE_API_UI_JS_URL=/api-ui/ui.min.js
ENV DEFAULT_CATTLE_API_UI_CSS_URL=/api-ui/ui.min.css
ENV DEFAULT_CATTLE_MACHINE_EXECUTE=true
ENV DEFAULT_CATTLE_COMPOSE_EXECUTOR_EXECUTE=true
ENV DEFAULT_CATTLE_CATALOG_EXECUTE=true
ENV DEFAULT_CATTLE_WEBHOOK_SERVICE_EXECUTE=true
ENV DEFAULT_CATTLE_SECRETS_API_EXECUTE=true
ENV CATTLE_RANCHER_SERVER_IMAGE=ghcr.io/pasturestack/server

RUN set -eux; \
    mkdir -p "${CATTLE_HOME}/logs"; \
    chown -R "${RC16_CATTLE_UID}:${RC16_CATTLE_GID}" "${CATTLE_HOME}"

ENTRYPOINT ["/usr/bin/entry"]
CMD ["/usr/bin/s6-svscan", "/service"]

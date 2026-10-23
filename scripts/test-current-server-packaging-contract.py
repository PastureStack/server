"""Focused source-only checks; no full gate, build, registry or runtime execution."""
import json
import pathlib
import re
import shlex
import unittest


REPO = pathlib.Path(__file__).resolve().parents[1]
GATE = (REPO / 'scripts/check-server-api-explorer-patch.sh').read_text(encoding='utf-8')
DOCKER = 'server/Dockerfile.web-compose-release'
BUILD = 'server/build-api-explorer-patch-image.sh'
VEX = 'server/security/openvex.json'
VENDOR = 'server/security/vendor-pending.json'
COMPATIBILITY = 'COMPATIBILITY.md'
COMPOSE = 'server/artifacts/compose/docker-compose.yml'
IMAGE_REFERENCES = 'scripts/check-server-runtime-image-references.sh'
FILES = {name: (REPO / name).read_text(encoding='utf-8') for name in (DOCKER, BUILD, VEX, VENDOR, COMPATIBILITY, COMPOSE, IMAGE_REFERENCES)}
LB_IMAGE = 'ghcr.io/pasturestack/load-balancer-service:v0.9.33'
LB_DEFAULT_MARKERS = [
    'ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE=' + LB_IMAGE,
    'ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE_UUID=docker:' + LB_IMAGE,
    'COPY artifacts/compose/ /usr/share/cattle/compose/',
]
LB_RUNTIME_MARKERS = [
    'DEFAULT_CATTLE_LB_INSTANCE_IMAGE=' + LB_IMAGE,
    'DEFAULT_CATTLE_LB_INSTANCE_IMAGE_UUID=docker:' + LB_IMAGE,
    'test -z "${CATTLE_LB_INSTANCE_IMAGE:-}${CATTLE_LB_INSTANCE_IMAGE_UUID:-}${RC16_LB_INSTANCE_IMAGE:-}${RC16_LB_INSTANCE_IMAGE_UUID:-}"',
    'test "$DEFAULT_CATTLE_LB_INSTANCE_IMAGE" = ' + LB_IMAGE,
    'test "$DEFAULT_CATTLE_LB_INSTANCE_IMAGE_UUID" = docker:' + LB_IMAGE,
    'test "$(grep -Fxc "  image: ' + LB_IMAGE + '" /usr/share/cattle/compose/docker-compose.yml)" = 2',
]
PUBLISHED_508 = 'Server `v1.6.508` 已正式發布，封裝 Web Console `1.6.171`。'
STALE_508_CANDIDATE = 'Server `v1.6.508` candidate packages Web Console `1.6.171`'
COMPATIBILITY_CODE = 'SERVER_CREATE_RESPONSE_ORDER_COMPATIBILITY_MISSING'
WEB_SHA = 'fe83f57dd1202766579b848f1bee75e7c05536db2fbb1f58de2bbb21829b1221'
WEB_SOURCE = 'f47283ff6d18516040c0ee0782ac0a0314b67538'
CATALOG_COMMIT = '28756cdf13f50380e907d37da501e33383a7c217'
ENGINE_SHA = 'f4889bfb8759a7664f07524bb129d0cda19f35604a06c877b6ca7033246df6fa'
ENGINE_SOURCE = 'dc5a8d7bc44131f609f72a6504483b692d47ce16'
OLD_COORDINATES = {
    'v1.6.546': 'v1.6.521',
    '1.6.194': '1.6.181',
    WEB_SHA: '9199681f2c4311f3fbe8727fcf0f6fa136c9bafe9fbe9d13878c55df442a7a03',
    WEB_SOURCE: '7f2bdad0c90a3241693c2ddd4475202ababba550',
    CATALOG_COMMIT: '7670ffd81d5f0b5570197fb03c7e55b46da45bf3',
}
# Engine353 and Web193 use the reviewed component input identities.
# Published521 component values remain mutation controls.
# Component coordinates do not establish Server545 artifact/runtime PASS.
CATALOG_FIELDS = (
    ('VERSION', 'version', '0.20.15'),
    ('COMMIT', 'commit', '6ea547594065f7f95d5877b82f0c1bc553e72640'),
    ('ARCHIVE_SHA256', 'archive_sha256', '7c059101265d897e4b176f503a9217b112946d37d91daa0c40f421fb16e4bb6b'),
    ('BINARY_SHA256', 'binary_sha256', '948a528987113a2d37f5ee519c4f682e09af4aa10ff64d490d9851ba7b633364'),
    ('SQLITE_BINARY_SHA256', 'sqlite_binary_sha256', 'b890cfc7941ad3ba1bde4038c0acde4098fa101512553159d4615e540f8bb659'),
    ('LICENSE_SHA256', 'license_sha256', '0d542e0c8804e39aa7f37eb00da5a762149dc682d7829451287e11b938e94594'),
)
LEGACY_ENGINE_COORDINATES = {
    '0.183.354': '0.183.337',
    ENGINE_SHA: '7e45189f2b57097efc7929c04ddf7767aebbe027d1b9f90023aa6711522c5c80',
    ENGINE_SOURCE: 'ba041fe312dfe97fc1e5144af576ddcf1b573d8e',
}
EXPECTED = {
    COMPATIBILITY_CODE: (COMPATIBILITY, PUBLISHED_508),
    'SERVER_INCREMENTAL_RELEASE_DEFAULT_MISSING': (DOCKER, 'ARG SERVER_RELEASE_TAG=v1.6.546'),
    'SERVER_INCREMENTAL_RELEASE_VERSION_MISSING': (DOCKER, 'org.opencontainers.image.version="${SERVER_RELEASE_TAG}"'),
    'SERVER_INCREMENTAL_RELEASE_RUNTIME_VERSION_MISSING': (DOCKER, 'ENV CATTLE_RANCHER_SERVER_VERSION=${SERVER_RELEASE_TAG}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_VERSION_MISSING': (DOCKER, 'ARG WEB_CONSOLE_RELEASE_TAG=1.6.194'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_ARTIFACT_MISSING': (DOCKER, 'ARG WEB_CONSOLE_ARTIFACT=web-console-1.6.194.tar.gz'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_HASH_MISSING': (DOCKER, 'ARG WEB_CONSOLE_ARTIFACT_SHA256=' + WEB_SHA),
    'SERVER_INCREMENTAL_WEB_CONSOLE_COMMIT_MISSING': (DOCKER, 'ARG WEB_CONSOLE_COMMIT=' + WEB_SOURCE),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_COMMIT_MISSING': (BUILD, 'web_console_commit=${WEB_CONSOLE_COMMIT:-' + WEB_SOURCE + '}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_VERSION_MISSING': (BUILD, 'web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-1.6.194}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_ARTIFACT_MISSING': (BUILD, 'web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.194.tar.gz}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_HASH_MISSING': (BUILD, 'web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:-' + WEB_SHA + '}'),
    'SERVER_INCREMENTAL_RELEASE_BUILD_VERSION_MISSING': (BUILD, 'image=${IMAGE:-pasturestack-validation/server:v1.6.546}'),
    'SERVER_INCREMENTAL_RELEASE_BUILD_DEFAULT_MISSING': (BUILD, 'server_release_tag=${SERVER_RELEASE_TAG:-v1.6.546}'),
    'SERVER_INCREMENTAL_RELEASE_BUILD_RUNTIME_VERSION_MISSING': (BUILD, 'CATTLE_RANCHER_SERVER_VERSION="${server_release_tag}"'),
    'SERVER_WEB_CONSOLE_RUNTIME_VERSION_GATE_MISSING': (BUILD, 'test "$(cat "${web_root}/VERSION.txt")" = "${WEB_CONSOLE_RELEASE_TAG}"'),
    'SERVER_VOLUME_NATIVE_READ_ONLY_BUILD_GATE_MISSING': (DOCKER, 'grep -F \'"volume.isNative" : "r"\' >/dev/null'),
    'SERVER_VOLUME_NATIVE_READ_ONLY_RUNTIME_GATE_MISSING': (BUILD, r'grep -F "\"volume.isNative\" : \"r\"" >/dev/null'),
    'SERVER_WEB_CREATE_IDENTITY_BUILD_GATE_MISSING': (DOCKER, "grep -aF 'createIdentity' \"${web_root}\"/assets/*.js >/dev/null"),
    'SERVER_WEB_CANONICAL_RECORD_BUILD_GATE_MISSING': (DOCKER, "grep -aF 'hasRecord' \"${web_root}\"/assets/*.js >/dev/null"),
    'SERVER_WEB_CREATE_IDENTITY_RUNTIME_GATE_MISSING': (BUILD, "grep -aF \"createIdentity\" \"${web_root}\"/assets/*.js >/dev/null"),
    'SERVER_WEB_CANONICAL_RECORD_RUNTIME_GATE_MISSING': (BUILD, "grep -aF \"hasRecord\" \"${web_root}\"/assets/*.js >/dev/null"),
    'SERVER_CATALOG_VERSION_LABEL_COMMIT_MISSING': (DOCKER, 'ENV PASTURESTACK_CATALOG_COMMIT=' + CATALOG_COMMIT),
    'SERVER_CATALOG_VERSION_LABEL_URL_MISSING': (DOCKER, '\"pinnedCommit\":\"' + CATALOG_COMMIT + '\"'),
    'SERVER_CATALOG_VERSION_LABEL_IMAGE_GATE_MISSING': (BUILD, 'PASTURESTACK_CATALOG_COMMIT=' + CATALOG_COMMIT),
}
for _upper, _lower, _value in CATALOG_FIELDS:
    EXPECTED['SERVER_INCREMENTAL_CATALOG_' + _upper + '_MISSING'] = (
        DOCKER, 'ARG CATALOG_SERVICE_' + _upper + '=' + _value)
    EXPECTED['SERVER_INCREMENTAL_CATALOG_BUILD_' + _upper + '_MISSING'] = (
        BUILD, 'catalog_service_' + _lower + '=${CATALOG_SERVICE_' + _upper + ':-' + _value + '}')
CREATE_RESPONSE_CODES = ['SERVER_WEB_CREATE_IDENTITY_BUILD_GATE_MISSING','SERVER_WEB_CANONICAL_RECORD_BUILD_GATE_MISSING','SERVER_WEB_CREATE_IDENTITY_RUNTIME_GATE_MISSING','SERVER_WEB_CANONICAL_RECORD_RUNTIME_GATE_MISSING']
ENGINE_EXPECTED = {
    'SERVER_INCREMENTAL_ENGINE_REPLACEMENT_MISSING': (DOCKER, 'release_engine_marker', (
        'ARG ORCHESTRATION_ENGINE_RELEASE_TAG=v0.183.354',
        'ARG ORCHESTRATION_ENGINE_ARTIFACT=cattle.jar',
        'ARG ORCHESTRATION_ENGINE_ARTIFACT_SHA256=' + ENGINE_SHA,
        'ARG ORCHESTRATION_ENGINE_COMMIT=' + ENGINE_SOURCE,
        'ARG ORCHESTRATION_ENGINE_VERSION=0.183.354',
        'grep -Fx "Implementation-Version: ${ORCHESTRATION_ENGINE_VERSION}"',
        'cattle-resources-${ORCHESTRATION_ENGINE_VERSION}.jar',
        'cattle-app-config-${ORCHESTRATION_ENGINE_VERSION}.jar',
        'ENV CATTLE_CATTLE_VERSION=${ORCHESTRATION_ENGINE_RELEASE_TAG}',
    )),
    'SERVER_INCREMENTAL_ENGINE_BUILD_COORDINATE_MISSING': (BUILD, 'release_engine_build_marker', (
        'orchestration_engine_release_tag=${ORCHESTRATION_ENGINE_RELEASE_TAG:-v0.183.354}',
        'orchestration_engine_artifact=${ORCHESTRATION_ENGINE_ARTIFACT:-cattle.jar}',
        'orchestration_engine_artifact_sha256=${ORCHESTRATION_ENGINE_ARTIFACT_SHA256:-' + ENGINE_SHA + '}',
        'orchestration_engine_commit=${ORCHESTRATION_ENGINE_COMMIT:-' + ENGINE_SOURCE + '}',
        'CATTLE_CATTLE_VERSION="${orchestration_engine_release_tag}"',
        'cattle-resources-${ORCHESTRATION_ENGINE_VERSION}.jar',
    )),
}


INCREMENTAL_CONTRACTS = [
    [
        "incremental_producer_marker",
        "server/Dockerfile.web-compose-release",
        [
            "ARG HOST_PROVISIONER_VERSION=0.39.10",
            "ARG HOST_PROVISIONER_COMMIT=d5f6d5c9f4f0599f4bf1bdc9d5d0cca2e2e0c1ba",
            "ARG HOST_PROVISIONER_ARCHIVE_SHA256=fd8a814c5810746091ba3192a9fd31699e6865a2598654b9bbb55eae90bef661",
            "ARG HOST_PROVISIONER_BINARY_SHA256=92c6d9ce1222a93802ff2c92b100eeb6c58286f3fca90698f9687b92d6fa9dff",
            "ARG SECRET_DELIVERY_API_VERSION=0.3.3",
            "ARG SECRET_DELIVERY_API_COMMIT=da196acba539fe7a0c04539f6f7537cdfb2d8d69",
            "ARG SECRET_DELIVERY_API_ARCHIVE_SHA256=026ba87f4c8fb7bfbf991f63a496db9c4a0837913ab56dc505c187f9b9598699",
            "ARG SECRET_DELIVERY_API_BINARY_SHA256=e4928ca7359975ba4ad73456296baace8ef0b428c0901055a0317244a17e4665",
            "ARG USAGE_TELEMETRY_AGENT_VERSION=0.4.4",
            "ARG USAGE_TELEMETRY_AGENT_COMMIT=4ee641bc1273cf582a77609af71d00b72f17b628",
            "ARG USAGE_TELEMETRY_AGENT_ARCHIVE_SHA256=6d482fed63734d4912174747ad1b70bc57ee0ac52e0cc60e7d43a12ad17d3866",
            "ARG USAGE_TELEMETRY_AGENT_BINARY_SHA256=90ed65f689c91801abd0cf482211c96a01e7c63ef695e4faecdf4713eff730be",
            "ARG COMPOSE_EXECUTOR_COMMIT=53a33bdc13ae99f4bc4a2dc5cc760b6b2d098388",
            "ARG COMPOSE_EXECUTOR_ARCHIVE_SHA256=4ab4685af67a8b8b11f3dd4996de9e087c26391ec401cf02cdcafe4c93094bab"
        ]
    ],
    [
        "incremental_producer_build_marker",
        "server/build-api-explorer-patch-image.sh",
        [
            "host_provisioner_version=${HOST_PROVISIONER_VERSION:-0.39.10}",
            "host_provisioner_commit=${HOST_PROVISIONER_COMMIT:-d5f6d5c9f4f0599f4bf1bdc9d5d0cca2e2e0c1ba}",
            "host_provisioner_archive_sha256=${HOST_PROVISIONER_ARCHIVE_SHA256:-fd8a814c5810746091ba3192a9fd31699e6865a2598654b9bbb55eae90bef661}",
            "host_provisioner_binary_sha256=${HOST_PROVISIONER_BINARY_SHA256:-92c6d9ce1222a93802ff2c92b100eeb6c58286f3fca90698f9687b92d6fa9dff}",
            "secret_delivery_api_version=${SECRET_DELIVERY_API_VERSION:-0.3.3}",
            "secret_delivery_api_commit=${SECRET_DELIVERY_API_COMMIT:-da196acba539fe7a0c04539f6f7537cdfb2d8d69}",
            "secret_delivery_api_archive_sha256=${SECRET_DELIVERY_API_ARCHIVE_SHA256:-026ba87f4c8fb7bfbf991f63a496db9c4a0837913ab56dc505c187f9b9598699}",
            "secret_delivery_api_binary_sha256=${SECRET_DELIVERY_API_BINARY_SHA256:-e4928ca7359975ba4ad73456296baace8ef0b428c0901055a0317244a17e4665}",
            "usage_telemetry_agent_version=${USAGE_TELEMETRY_AGENT_VERSION:-0.4.4}",
            "usage_telemetry_agent_commit=${USAGE_TELEMETRY_AGENT_COMMIT:-4ee641bc1273cf582a77609af71d00b72f17b628}",
            "usage_telemetry_agent_archive_sha256=${USAGE_TELEMETRY_AGENT_ARCHIVE_SHA256:-6d482fed63734d4912174747ad1b70bc57ee0ac52e0cc60e7d43a12ad17d3866}",
            "usage_telemetry_agent_binary_sha256=${USAGE_TELEMETRY_AGENT_BINARY_SHA256:-90ed65f689c91801abd0cf482211c96a01e7c63ef695e4faecdf4713eff730be}",
            "compose_executor_version=${COMPOSE_EXECUTOR_VERSION:-0.14.39}",
            "compose_executor_commit=${COMPOSE_EXECUTOR_COMMIT:-53a33bdc13ae99f4bc4a2dc5cc760b6b2d098388}",
            "compose_executor_archive_sha256=${COMPOSE_EXECUTOR_ARCHIVE_SHA256:-4ab4685af67a8b8b11f3dd4996de9e087c26391ec401cf02cdcafe4c93094bab}",
            "compose_executor_binary_sha256=${COMPOSE_EXECUTOR_BINARY_SHA256:-0f0c0ada23564572b569e1c73951ca363c0dc262fe7bba9c2474106650c4eac5}"
        ]
    ],
    [
        "incremental_producer_runtime_marker",
        "server/Dockerfile.web-compose-release",
        [
            "COPY --chmod=0755 artifacts/verify-runtime-producer.sh /usr/local/bin/verify-runtime-producer",
            "verify-runtime-producer \"$component\" \"$version\" \"$commit\" \"/tmp/${artifact}\" \"$binary_sha\" \"/out/$component\";",
            "install -m 0755 /out/host-provisioner/host-provisioner /out/runtime-bin/host-provisioner.real;",
            "cp -a /out/host-provisioner-licenses /out/runtime-licenses/host-provisioner;",
            "install -m 0755 /out/secret-delivery-api/secret-delivery-api /out/runtime-bin/secret-delivery-api;",
            "cp -a /out/secret-delivery-api-licenses /out/runtime-licenses/secret-delivery-api;",
            "install -m 0755 /out/usage-telemetry-agent/usage-telemetry-agent /out/runtime-bin/usage-telemetry-agent;",
            "cp -a /out/usage-telemetry-agent-licenses /out/runtime-licenses/usage-telemetry-agent;",
            "echo \"${HOST_PROVISIONER_BINARY_SHA256}  /usr/bin/host-provisioner.real\" | sha256sum -c -;",
            "/usr/bin/host-provisioner.real -v | grep -F \"${HOST_PROVISIONER_VERSION}\" >/dev/null;",
            "test -s /usr/share/licenses/pasturestack/host-provisioner/LICENSE;",
            "test -s /usr/share/licenses/pasturestack/host-provisioner/ORIGIN.md;",
            "test \"$(find /usr/share/licenses/pasturestack/host-provisioner/licenses -type f | wc -l)\" -eq 35;",
            "echo \"${SECRET_DELIVERY_API_BINARY_SHA256}  /usr/bin/secret-delivery-api\" | sha256sum -c -;",
            "/usr/bin/secret-delivery-api --version | grep -F \"v${SECRET_DELIVERY_API_VERSION}\" >/dev/null;",
            "test \"$(readlink -f /usr/bin/secrets-api)\" = /usr/bin/secret-delivery-api;",
            "echo \"${USAGE_TELEMETRY_AGENT_BINARY_SHA256}  /usr/bin/usage-telemetry-agent\" | sha256sum -c -;",
            "/usr/bin/usage-telemetry-agent --version | grep -F \"usage-telemetry-agent ${USAGE_TELEMETRY_AGENT_VERSION} (\" >/dev/null;",
            "test \"$(readlink -f /usr/bin/telemetry)\" = /usr/bin/usage-telemetry-agent;",
            "test ! -e \"${license_dir}/${component}\";",
            "grep -Fx 'Go compiler: 1.27.3' \"${license_dir}/SERVER-PRODUCER-SOURCES.txt\" >/dev/null;",
            "test -s \"${license_dir}/${component}-${suffix}\";",
            "test -s /usr/share/licenses/pasturestack/usage-telemetry-agent/usage-telemetry-agent-PRIVACY.md;"
        ]
    ],
    [
        "incremental_go_marker",
        "server/Dockerfile.web-compose-release",
        [
            "ARG ARTIFACT_HELPER_IMAGE=golang:1.27.3-bookworm@sha256:972b4110ba0f47539a975c31e52c64765e1ff19f2d74469ae4a595c6676e80a5",
            "test \"$(go version | awk '{print $3}')\" = go1.27.3;",
            "test \"$(go version -m /out/pasturestack-console-broker | awk 'NR==1 {print $2}')\" = go1.27.3;",
            "ENV PASTURESTACK_RUNTIME_GO_VERSION=1.27.3",
            "ENV PASTURESTACK_CONSOLE_BROKER_GO_VERSION=1.27.3",
            "ARG ENGINE_READONLY_SCHEMA_SHA256=7f274219e8dd9c6d750a408a6edec1448b564f4b16ba2204c425c5b45cec2233",
            "ARG ENGINE_RESTRICTED_SCHEMA_SHA256=f854ba99260f29e324ab7446a8592996946038920ac9bcf17689d98d1ebc5e51"
        ]
    ],
    [
        "incremental_go_build_marker",
        "server/build-api-explorer-patch-image.sh",
        [
            "PASTURESTACK_RUNTIME_GO_VERSION=1.27.3",
            "PASTURESTACK_CONSOLE_BROKER_GO_VERSION=1.27.3",
            "test -x /usr/bin/pasturestack-console-broker",
            "grep -aF \"go1.27.3\" /usr/bin/pasturestack-console-broker >/dev/null",
            "console_broker_go=1.27.3",
            "grep -aF \"go1.27.3\" \"${binary}\" >/dev/null",
            "runtime_go=1.27.3",
            "engine_readonly_schema_sha256=${ENGINE_READONLY_SCHEMA_SHA256:-7f274219e8dd9c6d750a408a6edec1448b564f4b16ba2204c425c5b45cec2233}",
            "engine_restricted_schema_sha256=${ENGINE_RESTRICTED_SCHEMA_SHA256:-f854ba99260f29e324ab7446a8592996946038920ac9bcf17689d98d1ebc5e51}"
        ]
    ],
    [
        "incremental_input_marker",
        "server/build-api-explorer-patch-image.sh",
        [
            "\"$orchestration_engine_artifact|$orchestration_engine_artifact_sha256\"",
            "\"$web_console_artifact|$web_console_artifact_sha256\"",
            "\"websocket-proxy-${websocket_proxy_version}-linux-amd64.tar.xz|$websocket_proxy_archive_sha256\"",
            "\"host-api-${host_api_version}.tar.gz|$host_api_archive_sha256\"",
            "\"node-agent-${node_agent_version}.tar.gz|$node_agent_archive_sha256\"",
            "\"per-host-subnet-${per_host_subnet_version}-windows-amd64.zip|$per_host_subnet_archive_sha256\"",
            "\"host-provisioner-${host_provisioner_version}-linux-amd64.tar.xz|$host_provisioner_archive_sha256\"",
            "\"secret-delivery-api-${secret_delivery_api_version}-linux-amd64.tar.xz|$secret_delivery_api_archive_sha256\"",
            "\"usage-telemetry-agent-${usage_telemetry_agent_version}-linux-amd64.tar.xz|$usage_telemetry_agent_archive_sha256\"",
            "\"catalog-service-${catalog_service_version}.tar.xz|$catalog_service_archive_sha256\"",
            "\"catalog-service-${catalog_service_version}-LICENSE.txt|$catalog_service_license_sha256\"",
            "\"authentication-service-${authentication_service_version}-linux-amd64.tar.xz|$authentication_service_archive_sha256\"",
            "\"webhook-automation-service-${webhook_automation_service_version}-linux-amd64.tar.xz|$webhook_automation_service_archive_sha256\"",
            "\"compose-executor-${compose_executor_version}-linux-amd64.gz|$compose_executor_archive_sha256\"",
            "\"vsphere-cli-bundle-${vsphere_cli_bundle_version}-linux-amd64.tar.xz|$vsphere_cli_bundle_archive_sha256\"",
            "[[ \"$actual_components\" == \"$expected_components\" ]]",
            "printf '%s  %s\\n' \"$component_sha256\" \"$component_directory/$component_name\" | sha256sum -c -"
        ]
    ]
]
INCREMENTAL_CONTRACTS += [
    ('api_explorer_release_marker', DOCKER, [
        'ARG API_EXPLORER_RELEASE_TAG=v1.1.20',
        'ARG API_EXPLORER_ARTIFACT=api-explorer-1.1.20.tar.gz',
        'ARG API_EXPLORER_ARTIFACT_SHA256=c989ee12a518f6d9d2b23b1f17f48d781aacf6ec31fb65291dd7de9b1661badb',
        'ARG API_EXPLORER_COMMIT=a586f0dc0aa50df579049a8d4bf26f04400fdf75',
        'COPY --chmod=0755 artifacts/prepare-api-explorer.sh /usr/local/bin/prepare-api-explorer',
        'fetch-server-component "${COMPONENT_ARTIFACT_MODE}" "${API_EXPLORER_RELEASE_BASE_URL%/}/${API_EXPLORER_RELEASE_TAG}/${API_EXPLORER_ARTIFACT}" "${API_EXPLORER_ARTIFACT}" "${API_EXPLORER_ARTIFACT_SHA256}" /tmp/api-explorer.tar.gz;',
        'prepare-api-explorer /tmp/api-explorer.tar.gz 1.1.20 "${API_EXPLORER_COMMIT}" /out/api-explorer;',
        'COPY --from=release_artifacts /out/api-explorer/ /tmp/pasturestack-api-ui/',
        'COPY --from=release_artifacts /out/api-explorer.sha256 /tmp/pasturestack-api-ui.sha256',
        'mv /tmp/pasturestack-api-ui api-ui;',
        '(cd api-ui && sha256sum -c /tmp/pasturestack-api-ui.sha256);',
        'ENV CATTLE_API_UI_VERSION=1.1.20',
        'ENV PASTURESTACK_API_EXPLORER_PACKAGE=1.1.20',
        'ENV PASTURESTACK_API_EXPLORER_COMMIT=${API_EXPLORER_COMMIT}',
        'ENV PASTURESTACK_API_EXPLORER_ARTIFACT_SHA256=${API_EXPLORER_ARTIFACT_SHA256}',
    ]),
]
EXACT_COMPONENT_INPUTS = [
    "\"$orchestration_engine_artifact|$orchestration_engine_artifact_sha256\"",
    "\"$api_explorer_artifact|$api_explorer_artifact_sha256\"",
    "\"$web_console_artifact|$web_console_artifact_sha256\"",
    "\"websocket-proxy-${websocket_proxy_version}-linux-amd64.tar.xz|$websocket_proxy_archive_sha256\"",
    "\"host-api-${host_api_version}.tar.gz|$host_api_archive_sha256\"",
    "\"node-agent-${node_agent_version}.tar.gz|$node_agent_archive_sha256\"",
    "\"node-agent-${node_agent_version}-windows-amd64.zip|$node_agent_windows_archive_sha256\"",
    "\"per-host-subnet-${per_host_subnet_version}-windows-amd64.zip|$per_host_subnet_archive_sha256\"",
    "\"host-provisioner-${host_provisioner_version}-linux-amd64.tar.xz|$host_provisioner_archive_sha256\"",
    "\"secret-delivery-api-${secret_delivery_api_version}-linux-amd64.tar.xz|$secret_delivery_api_archive_sha256\"",
    "\"usage-telemetry-agent-${usage_telemetry_agent_version}-linux-amd64.tar.xz|$usage_telemetry_agent_archive_sha256\"",
    "\"catalog-service-${catalog_service_version}.tar.xz|$catalog_service_archive_sha256\"",
    "\"catalog-service-${catalog_service_version}-LICENSE.txt|$catalog_service_license_sha256\"",
    "\"authentication-service-${authentication_service_version}-linux-amd64.tar.xz|$authentication_service_archive_sha256\"",
    "\"webhook-automation-service-${webhook_automation_service_version}-linux-amd64.tar.xz|$webhook_automation_service_archive_sha256\"",
    "\"compose-executor-${compose_executor_version}-linux-amd64.gz|$compose_executor_archive_sha256\"",
    "\"vsphere-cli-bundle-${vsphere_cli_bundle_version}-linux-amd64.tar.xz|$vsphere_cli_bundle_archive_sha256\"",
    "\"machine-driver-bundle-${machine_driver_bundle_version}-linux-amd64.tar.xz|$machine_driver_bundle_archive_sha256\""
]


RUNTIME_BINARIES = [
    [
        "/out/catalog-service/catalog-service",
        "/out/runtime-bin/catalog-service.real"
    ],
    [
        "/out/catalog-service/catalog-service-sqlite",
        "/out/runtime-bin/catalog-service-sqlite"
    ],
    [
        "/out/authentication-service/authentication-service",
        "/out/runtime-bin/authentication-service.real"
    ],
    [
        "/out/websocket-proxy/websocket-proxy",
        "/out/runtime-bin/websocket-proxy.real"
    ],
    [
        "/out/webhook-automation-service/webhook-automation-service",
        "/out/runtime-bin/webhook-automation-service"
    ],
    [
        "/out/compose-executor",
        "/out/runtime-bin/compose-executor.real"
    ],
    [
        "/out/vsphere-cli-bundle/govc",
        "/out/runtime-bin/govc"
    ],
    [
        "/out/host-provisioner/host-provisioner",
        "/out/runtime-bin/host-provisioner.real"
    ],
    [
        "/out/secret-delivery-api/secret-delivery-api",
        "/out/runtime-bin/secret-delivery-api"
    ],
    [
        "/out/usage-telemetry-agent/usage-telemetry-agent",
        "/out/runtime-bin/usage-telemetry-agent"
    ],
    [
        "/out/machine-driver-bundle/docker-machine",
        "/out/runtime-bin/docker-machine"
    ],
    [
        "/out/machine-driver-bundle/docker-machine-driver-packet",
        "/out/runtime-bin/docker-machine-driver-packet"
    ]
]
RUNTIME_LEGAL = [
    [
        "/out/machine-driver-bundle/licenses",
        "/out/runtime-licenses/machine-driver-bundle"
    ],
    [
        "/out/catalog-service-licenses",
        "/out/runtime-licenses/catalog-service"
    ],
    [
        "/out/host-provisioner-licenses",
        "/out/runtime-licenses/host-provisioner"
    ],
    [
        "/out/secret-delivery-api-licenses",
        "/out/runtime-licenses/secret-delivery-api"
    ],
    [
        "/out/usage-telemetry-agent-licenses",
        "/out/runtime-licenses/usage-telemetry-agent"
    ],
    [
        "/out/webhook-automation-service/webhook-automation-service-COMPATIBILITY.md",
        "/out/webhook-automation-service/webhook-automation-service-LICENSES.txt",
        "/out/webhook-automation-service/webhook-automation-service-SOURCES.txt",
        "/out/webhook-automation-service/webhook-automation-service-THIRD-PARTY-NOTICES.md",
        "/out/runtime-licenses/webhook-automation-service/"
    ],
    [
        "/out/vsphere-cli-bundle/vsphere-cli-bundle-LICENSES.txt",
        "/out/vsphere-cli-bundle/vsphere-cli-bundle-SOURCES.txt",
        "/out/vsphere-cli-bundle/vsphere-cli-bundle-THIRD-PARTY-NOTICES.txt",
        "/out/runtime-licenses/vsphere-cli-bundle/"
    ]
]
RUNTIME_LAYOUT_MARKERS = [
    "install -m 0755 /out/catalog-service/catalog-service /out/runtime-bin/catalog-service.real;",
    "install -m 0755 /out/catalog-service/catalog-service-sqlite /out/runtime-bin/catalog-service-sqlite;",
    "install -m 0755 /out/authentication-service/authentication-service /out/runtime-bin/authentication-service.real;",
    "install -m 0755 /out/websocket-proxy/websocket-proxy /out/runtime-bin/websocket-proxy.real;",
    "install -m 0755 /out/webhook-automation-service/webhook-automation-service /out/runtime-bin/webhook-automation-service;",
    "install -m 0755 /out/compose-executor /out/runtime-bin/compose-executor.real;",
    "install -m 0755 /out/vsphere-cli-bundle/govc /out/runtime-bin/govc;",
    "install -m 0755 /out/host-provisioner/host-provisioner /out/runtime-bin/host-provisioner.real;",
    "install -m 0755 /out/secret-delivery-api/secret-delivery-api /out/runtime-bin/secret-delivery-api;",
    "install -m 0755 /out/usage-telemetry-agent/usage-telemetry-agent /out/runtime-bin/usage-telemetry-agent;",
    "cp -a /out/catalog-service-licenses /out/runtime-licenses/catalog-service;",
    "cp -a /out/host-provisioner-licenses /out/runtime-licenses/host-provisioner;",
    "cp -a /out/secret-delivery-api-licenses /out/runtime-licenses/secret-delivery-api;",
    "cp -a /out/usage-telemetry-agent-licenses /out/runtime-licenses/usage-telemetry-agent;",
    "/out/webhook-automation-service/webhook-automation-service-COMPATIBILITY.md",
    "/out/webhook-automation-service/webhook-automation-service-LICENSES.txt",
    "/out/webhook-automation-service/webhook-automation-service-SOURCES.txt",
    "/out/webhook-automation-service/webhook-automation-service-THIRD-PARTY-NOTICES.md",
    "/out/runtime-licenses/webhook-automation-service/",
    "/out/vsphere-cli-bundle/vsphere-cli-bundle-LICENSES.txt",
    "/out/vsphere-cli-bundle/vsphere-cli-bundle-SOURCES.txt",
    "/out/vsphere-cli-bundle/vsphere-cli-bundle-THIRD-PARTY-NOTICES.txt",
    "/out/runtime-licenses/vsphere-cli-bundle/",
    "COPY --from=release_artifacts --chmod=0755 /out/runtime-bin/ /usr/bin/",
    "COPY --from=release_artifacts /out/runtime-licenses/ /usr/share/licenses/pasturestack/",
    "test \"$(find /out/runtime-bin -mindepth 1 -maxdepth 1 -type f | wc -l)\" -eq 12;",
    "test \"$(find /out/runtime-licenses -mindepth 1 -maxdepth 1 -type d | wc -l)\" -eq 7;",
    "test -z \"$(find /out/runtime-bin /out/runtime-licenses -type l -print -quit)\""
]


def stale(marker):
    for coordinate, old in OLD_COORDINATES.items():
        marker = marker.replace(coordinate, old)
    return marker


def stale_engine(marker):
    for coordinate, old in LEGACY_ENGINE_COORDINATES.items():
        marker = marker.replace(coordinate, old)
    return marker


def engine_gate_markers(gate, variable):
    header = 'for ' + variable + ' in '
    normalized = gate.replace('\\\n', ' ')
    if normalized.count(header) != 1:
        raise AssertionError('CURRENT_ENGINE_GATE_SHAPE_MISMATCH')
    values = normalized.split(header, 1)[1].split('; do\n', 1)[0]
    markers = shlex.split(values)
    if len(markers) != len(set(markers)):
        raise AssertionError('CURRENT_ENGINE_GATE_DUPLICATE')
    return markers


def verify_runtime_layout(files, gate=GATE):
    declared = engine_gate_markers(gate, 'incremental_layout_marker')
    if declared != RUNTIME_LAYOUT_MARKERS:
        raise AssertionError('CURRENT_RUNTIME_LAYOUT_GATE_MISMATCH')
    source = files[DOCKER].replace('\\\n', ' ')
    # Interpret executable statements; comments, wrong modes, destinations,
    # extra binaries and changed legal-source sets are not equivalent COPYs.
    installs = re.findall(r'(?:^|[;\n])\s*install -m 0755 (\S+) (\S+)(?=\s*;)', source)
    installs = [list(row) for row in installs if row[1].startswith('/out/runtime-bin/')]
    if installs != RUNTIME_BINARIES:
        raise AssertionError('CURRENT_RUNTIME_BINARY_LAYOUT_MISMATCH')
    copies = re.findall(r'(?:^|[;\n])\s*cp -a\s+([^;\n]+)(?=\s*;)', source)
    legal = [row.split() for row in copies if row.split()[-1].startswith('/out/runtime-licenses/')]
    if legal != RUNTIME_LEGAL:
        raise AssertionError('CURRENT_RUNTIME_LEGAL_LAYOUT_MISMATCH')
    for marker in RUNTIME_LAYOUT_MARKERS:
        if marker not in files[DOCKER]:
            raise AssertionError('CURRENT_RUNTIME_LAYOUT_SOURCE_MISMATCH')
        if marker.startswith('test '):
            command = marker.rstrip(';')
            if len(re.findall(r'(?:^|[;\n])\s*' + re.escape(command) + r'(?=\s*(?:;|\n|$))', source)) != 1:
                raise AssertionError('CURRENT_RUNTIME_LAYOUT_GUARD_BYPASS')
    expected = [
        'COPY --from=release_artifacts --chmod=0755 /out/runtime-bin/ /usr/bin/',
        'COPY --from=release_artifacts /out/runtime-licenses/ /usr/share/licenses/pasturestack/',
    ]
    actual = [line for line in files[DOCKER].splitlines()
              if line.startswith('COPY ') and re.search(r'/out/runtime-(?:bin|licenses)/', line)]
    stages = re.findall(r'^FROM .+$', files[DOCKER], re.M)
    expected_stages = [
        'FROM ${ARTIFACT_HELPER_IMAGE} AS temurin_security_runtime',
        'FROM ${ARTIFACT_HELPER_IMAGE} AS console_broker_build',
        'FROM scratch AS component_input',
        'FROM ${ARTIFACT_HELPER_IMAGE} AS release_artifacts',
        'FROM ${UBUNTU_SECURITY_IMAGE} AS runtime_security_packages',
        'FROM ${BASE_IMAGE}',
    ]
    if actual != expected or stages != expected_stages:
        raise AssertionError('CURRENT_RUNTIME_AGGREGATE_COPY_MISMATCH')
    if files[DOCKER].splitlines().count('COPY --from=temurin_security_runtime /out/java/ /opt/java/openjdk/') != 1:
        raise AssertionError('CURRENT_JDK_SECURITY_RUNTIME_COPY_MISMATCH')


def verify_incremental_contract(files, gate=GATE):
    for variable, name, markers in INCREMENTAL_CONTRACTS:
        declared = engine_gate_markers(gate, variable)
        if declared != markers:
            raise AssertionError('CURRENT_INCREMENTAL_GATE_CONTRACT_MISMATCH')
        for marker in markers:
            if marker not in files[name]:
                raise AssertionError('CURRENT_INCREMENTAL_SOURCE_CONTRACT_MISMATCH')
            if variable == 'api_explorer_release_marker' and marker.startswith(('ARG ', 'COPY ', 'ENV ')):
                occurrences = 2 if marker.startswith(('ARG API_EXPLORER_RELEASE_TAG=', 'ARG API_EXPLORER_ARTIFACT_SHA256=', 'ARG API_EXPLORER_COMMIT=')) else 1
                if files[name].splitlines().count(marker) != occurrences:
                    raise AssertionError('CURRENT_API_EXPLORER_STAGE_FLOW_MISMATCH')
            # Commands, unlike ARG/COPY/ENV text, must remain executable and
            # fail closed. A comment or "|| true" is not an equivalent guard.
            if marker.endswith(';'):
                source = files[name].replace('\\\n', ' ')
                command = marker[:-1]
                pattern = (r'(?:^|[;\n])\s*(?:(?:do|then)\s+)?' + re.escape(command)
                           + r'(?=\s*(?:;|\n|$))')
                if len(re.findall(pattern, source)) != 1:
                    raise AssertionError('CURRENT_INCREMENTAL_GUARD_BYPASS')
    verify_runtime_layout(files, gate)


def verify_load_balancer_contract(files, gate=GATE):
    try:
        defaults = engine_gate_markers(gate, 'current_lb_default_marker')
        runtime = engine_gate_markers(gate, 'current_lb_runtime_marker')
    except AssertionError as error:
        raise AssertionError('CURRENT_LB_GATE_CONTRACT_MISMATCH') from error
    if defaults != LB_DEFAULT_MARKERS or runtime != LB_RUNTIME_MARKERS:
        raise AssertionError('CURRENT_LB_GATE_CONTRACT_MISMATCH')
    final_stage = files[DOCKER].rsplit('\nFROM ', 1)[-1]
    if any(final_stage.splitlines().count(marker) != 1 for marker in LB_DEFAULT_MARKERS):
        raise AssertionError('CURRENT_LB_FINAL_STAGE_DEFAULT_MISMATCH')
    if re.search(r'^ENV (?:CATTLE|RC16)_LB_INSTANCE_IMAGE(?:_UUID)?=', final_stage, re.M):
        raise AssertionError('CURRENT_LB_OPERATOR_OVERRIDE_FORCED')
    for service in ('load-balancer-swarm', 'load-balancer'):
        block = files[COMPOSE].split('\n' + service + ':\n', 1)[-1].split('\n\n', 1)[0]
        images = re.findall(r'^  image: (.+)$', block, re.M)
        if images != [LB_IMAGE]:
            raise AssertionError('CURRENT_LB_COMPOSE_REFERENCE_MISMATCH')
    if any(marker not in files[BUILD] for marker in LB_RUNTIME_MARKERS):
        raise AssertionError('CURRENT_LB_RUNTIME_GATE_MISSING')
    readback = re.search(r'docker run --rm --network none --entrypoint sh "\$image" -eu -c \'\n(.*?)\n\'', files[BUILD], re.S)
    if not readback or readback[1].splitlines()[0].strip() != '. /usr/share/cattle/env_vars':
        raise AssertionError('CURRENT_LB_EFFECTIVE_ENV_READBACK_MISSING')
    for marker in LB_RUNTIME_MARKERS[2:]:
        if [line.strip() for line in readback[1].splitlines()].count(marker) != 1:
            raise AssertionError('CURRENT_LB_READBACK_GUARD_BYPASS')
    references = files[IMAGE_REFERENCES]
    for marker in (
        'approved_balancer="${approved_registry}/load-balancer-service:v0.9.33"',
        'historical_balancer="${approved_registry}/load-balancer-service:v0.9.27"',
        '"ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE=${approved_balancer}" \\\n    server/Dockerfile.web-compose-release',
        '"ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE=${historical_balancer}" \\\n    server/Dockerfile',
        '"APPROVED_LB_IMAGE=\\"${historical_balancer}\\""',
    ):
        present = marker in references.splitlines() if marker.startswith(('approved_balancer=', 'historical_balancer=')) else marker in references
        if not present:
            raise AssertionError('CURRENT_LB_HISTORICAL_REFERENCE_BOUNDARY_MISSING')


def verify(files, gate=GATE):
    # Extract the actual single-quoted require_marker calls. Membership has the
    # same fixed-string semantics as the unchanged gate's grep -Fq -- invocation.
    paths = {'$release_dockerfile': DOCKER, '$build_script': BUILD, COMPATIBILITY: COMPATIBILITY}
    actual = {}
    for line in gate.replace('\\\n', ' ').splitlines():
        if line.startswith('require_marker ') and any(code in line for code in EXPECTED):
            parts = shlex.split(line)
            if len(parts) != 4 or parts[3] in actual:
                raise AssertionError('CURRENT_MARKER_SHAPE_OR_DUPLICATE')
            actual[parts[3]] = (paths[parts[1]], parts[2])
    if actual != EXPECTED:
        raise AssertionError('CURRENT_GATE_PIN_MISMATCH')
    for code, (name, marker) in actual.items():
        if marker not in files[name]:
            raise AssertionError(code)
    for code, (name, variable, markers) in ENGINE_EXPECTED.items():
        declared = engine_gate_markers(gate, variable)
        if any(marker not in declared for marker in markers):
            raise AssertionError('CURRENT_ENGINE_GATE_PIN_MISMATCH')
        if any(marker not in files[name] for marker in markers):
            raise AssertionError(code)
    for code in ('SERVER_VOLUME_NATIVE_READ_ONLY_BUILD_GATE_MISSING',
                 'SERVER_VOLUME_NATIVE_READ_ONLY_RUNTIME_GATE_MISSING'):
        name, marker = EXPECTED[code]
        # Require the actual fail-closed pipeline, not a detached grep/comment.
        source = files[name].replace('\\\n', ' ')
        pipeline = (r'(?:^|[;\n])\s*unzip -p "\$\{resources_jar\}" '
                    r'schema/user/user-auth\.json\s*\|\s*' + re.escape(marker)
                    + r'(?=\s*(?:;|\n|$))')
        if len(re.findall(pipeline, source)) != 1:
            raise AssertionError(code)
    for code in CREATE_RESPONSE_CODES:
        name, marker = EXPECTED[code]
        source = files[name].replace('\\\n', ' ')
        pipeline = (r'(?:^|[;\n])\s*' + re.escape(marker)
                    + r'(?=\s*(?:;|\n|$))')
        if len(re.findall(pipeline, source)) != 1:
            raise AssertionError(code)
    for upper, lower, value in CATALOG_FIELDS:
        if files[DOCKER].splitlines().count('ARG CATALOG_SERVICE_' + upper + '=' + value) != 2:
            raise AssertionError('CURRENT_CATALOG_STAGE_PIN_MISMATCH')
    for variable, name in (('catalog_release_marker', DOCKER), ('catalog_build_marker', BUILD)):
        for marker in engine_gate_markers(gate, variable):
            if marker not in files[name]:
                raise AssertionError('CURRENT_CATALOG_FLOW_MISMATCH')
            if marker.startswith('echo ') and '| sha256sum -c -' in marker:
                source = files[name].replace('\\\n', ' ')
                pipeline = r'(?:^|[;\n])\s*' + re.escape(marker) + r'(?=\s*(?:;|\n|$))'
                if len(re.findall(pipeline, source)) != 1:
                    raise AssertionError('CURRENT_CATALOG_HASH_BYPASS')
    if 'and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.546"' not in gate:
        raise AssertionError('CURRENT_VEX_GATE_PIN_MISMATCH')
    if '"$vendor_pending_fixture" v1.6.546 >/dev/null' not in gate:
        raise AssertionError('CURRENT_VENDOR_GATE_PIN_MISMATCH')
    if json.loads(files[VEX]).get('@id') != 'https://github.com/PastureStack/server/security/openvex/v1.6.546':
        raise AssertionError('CURRENT_VEX_RELEASE_MISMATCH')
    if json.loads(files[VENDOR]).get('release') != 'v1.6.546':
        raise AssertionError('CURRENT_VENDOR_RELEASE_MISMATCH')
    if 'SERVER_API_EXPLORER_PATCH_OK release=v1.6.546 base=v1.6.460 engine=0.183.354 web_console=1.6.194 catalog_service=0.20.15 ' not in gate:
        raise AssertionError('CURRENT_SUMMARY_MISMATCH')
    verify_incremental_contract(files, gate)
    verify_load_balancer_contract(files, gate)


def previous_gate(gate=GATE):
    # Only quoted current markers are changed; unrelated gates may evolve freely.
    replacements = {}
    for name, marker in EXPECTED.values():
        if name == COMPATIBILITY:
            continue  # Published508 history does not become a stale candidate.
        if stale(marker) != marker:
            replacements["'" + marker + "' "] = "'" + stale(marker) + "' "
    replacements.update({
        'and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.546"':
            'and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.521"',
        '"$vendor_pending_fixture" v1.6.546 >/dev/null':
            '"$vendor_pending_fixture" v1.6.521 >/dev/null',
        'SERVER_API_EXPLORER_PATCH_OK release=v1.6.546 base=v1.6.460 engine=0.183.354 web_console=1.6.194 catalog_service=0.20.15 ':
            'SERVER_API_EXPLORER_PATCH_OK release=v1.6.521 base=v1.6.460 engine=0.183.340 web_console=1.6.181 catalog_service=0.20.12 ',
    })
    for marker, stale_marker in replacements.items():
        if gate.count(marker) != 1:
            raise AssertionError('UNEXPECTED_CURRENT_MARKER_SHAPE')
        gate = gate.replace(marker, stale_marker)
    # Synthetic mutation leaves current engine pins; separate tests reject337.
    return gate


class Tests(unittest.TestCase):
    def test_current_agent_defaults_keep_explicit_operator_overrides(self):
        image = 'ghcr.io/pasturestack/node-agent:v1.2.32'
        final_stage = FILES[DOCKER].rsplit('\nFROM ', 1)[-1]
        for name in ('DEFAULT_CATTLE_AGENT_IMAGE', 'DEFAULT_CATTLE_BOOTSTRAP_REQUIRED_IMAGE'):
            self.assertEqual(final_stage.splitlines().count('ENV ' + name + '=' + image), 1)
            self.assertIn(name + '=' + image, FILES[BUILD])
        self.assertIsNone(re.search(
            r'^ENV (CATTLE_AGENT_IMAGE|CATTLE_BOOTSTRAP_REQUIRED_IMAGE|RC16_AGENT_IMAGE)=',
            final_stage, re.M))
        startup = (REPO / 'server/artifacts/cattle.sh').read_text(encoding='utf-8')
        self.assertIn('CATTLE_BOOTSTRAP_REQUIRED_IMAGE="${CATTLE_BOOTSTRAP_REQUIRED_IMAGE:-$RC16_AGENT_IMAGE}"', startup)
        self.assertIn('SERVER_CURRENT_AGENT_OPERATOR_OVERRIDE_FORCED', FILES[IMAGE_REFERENCES])

    def test_load_balancer_source_defaults_compose_and_effective_readback(self):
        verify_load_balancer_contract(FILES)
        for path in ('server/Dockerfile', 'server/Dockerfile.runtime-hotfix', 'server/Dockerfile.api-explorer-patch'):
            source = (REPO / path).read_text(encoding='utf-8')
            self.assertIn('ENV DEFAULT_CATTLE_LB_INSTANCE_IMAGE=ghcr.io/pasturestack/load-balancer-service:v0.9.27', source)
        self.assertNotIn('UPDATE setting', FILES[DOCKER] + FILES[BUILD])

    def test_load_balancer_old_defaults_missing_copy_forced_override_and_disabled_readback_rejected(self):
        mutations = [
            (DOCKER, FILES[DOCKER].replace(LB_DEFAULT_MARKERS[0], LB_DEFAULT_MARKERS[0].replace('v0.9.33', 'v0.9.27'))),
            (DOCKER, FILES[DOCKER].replace(LB_DEFAULT_MARKERS[2], '# ' + LB_DEFAULT_MARKERS[2])),
            (DOCKER, FILES[DOCKER] + '\nENV CATTLE_LB_INSTANCE_IMAGE=' + LB_IMAGE + '\n'),
            (COMPOSE, FILES[COMPOSE].replace(LB_IMAGE, LB_IMAGE.replace('v0.9.33', 'v0.9.27'), 1)),
            (BUILD, FILES[BUILD].replace(LB_RUNTIME_MARKERS[2], '# ' + LB_RUNTIME_MARKERS[2])),
            (BUILD, FILES[BUILD].replace(LB_RUNTIME_MARKERS[-1], LB_RUNTIME_MARKERS[-1] + ' || true')),
            (BUILD, FILES[BUILD].replace('. /usr/share/cattle/env_vars', '# no inherited environment readback')),
            (IMAGE_REFERENCES, FILES[IMAGE_REFERENCES].replace('historical_balancer=', 'removed_historical_balancer=')),
        ]
        marker = LB_DEFAULT_MARKERS[0] + '\n'
        moved = FILES[DOCKER].replace(marker, '').replace('FROM ${BASE_IMAGE}', marker + 'FROM ${BASE_IMAGE}')
        mutations.append((DOCKER, moved))
        for path, source in mutations:
            with self.subTest(path=path, mutation=source[-80:]):
                with self.assertRaisesRegex(AssertionError, 'CURRENT_LB_'):
                    verify_load_balancer_contract(dict(FILES, **{path: source}))
        with self.assertRaisesRegex(AssertionError, 'CURRENT_LB_GATE_CONTRACT_MISMATCH'):
            verify_load_balancer_contract(FILES, GATE.replace('current_lb_default_marker', 'removed_lb_default_marker'))

    def test_ca_bootstrap_keeps_verified_official_security_package_bytes(self):
        url = ('https://archive.ubuntu.com/ubuntu/pool/main/c/'
               'ca-certificates/ca-certificates_20260816ubuntu0.26.04.1_all.deb')
        digest = '5b6326f1932cfd7be57130561dc78192f09ed9f58bfbe6606ed0c50510c3b6cd'
        pattern = re.compile(r'^ADD --checksum=sha256:' + digest + r'\s+'
                             + re.escape(url) + r'\s+/tmp/ca-certificates\.deb\s*$', re.M)
        for path in (DOCKER, 'server/Dockerfile', 'server/Dockerfile.api-explorer-patch'):
            source = (REPO / path).read_text(encoding='utf-8').replace('\\\n', ' ')
            with self.subTest(path=path):
                self.assertEqual(len(pattern.findall(source)), 1)
                self.assertNotIn('ca-certificates_20260601~26.04.1_all.deb', source)
                self.assertIsNone(pattern.search(source.replace(digest, '0' * 64)))
                self.assertIsNone(pattern.search(source.replace('20260816ubuntu0.26.04.1', 'latest')))
        self.assertIn("ca_bootstrap_url='" + url + "'", GATE)
        self.assertIn('SERVER_CA_CERTIFICATES_UNREVIEWED_BOOTSTRAP_SOURCE_BLOCKED', GATE)
        self.assertIn('SERVER_CA_CERTIFICATES_BOOTSTRAP_HASH_MISSING', GATE)
        recipe = FILES[DOCKER]
        self.assertEqual(recipe.count('ARG CA_CERTIFICATES_PACKAGE_VERSION=20260816ubuntu0.26.04.1'), 2)
        self.assertIn('cp /tmp/ca-certificates.deb "/out/packages/ca-certificates_${CA_CERTIFICATES_PACKAGE_VERSION}_all.deb"', recipe)
        self.assertIn('test "$(dpkg-query -W -f=\'${Version}\' ca-certificates)" = "${CA_CERTIFICATES_PACKAGE_VERSION}"', recipe)

    def test_official_curl_fixed_debs_are_pinned_outside_the_unchanged_snapshot(self):
        recipe, builder = FILES[DOCKER], FILES[BUILD]
        version = '8.18.0-1ubuntu2.8'
        expected = {
            'curl': '2c418a61d7165d0cde01d9cb05ae025cc41fc75ef6d3f095996bd045ba0945dc',
            'libcurl3t64-gnutls': '8db913e1fa5a694ca6ba7b828bd18c5204e6853ac07fe7ed9c6e1f94e3444d8e',
            'libcurl4t64': '7c0b37592f83a629cc22f0c98effa176da9edbd6d77b3f38184a9d0ddc5e0266',
        }
        declared = engine_gate_markers(GATE, 'release_curl_official_deb_marker')
        normalized = recipe.replace('\\\n', ' ')
        for package, digest in expected.items():
            url = 'https://security.ubuntu.com/ubuntu/pool/main/c/curl/' + package + '_' + version + '_amd64.deb'
            pattern = (r'^ADD --checksum=sha256:' + digest + r'\s+' + re.escape(url)
                       + r'\s+/tmp/' + re.escape(package) + r'[.]deb\s*$')
            self.assertRegex(normalized, re.compile(pattern, re.M))
            self.assertIn('ADD --checksum=sha256:' + digest, declared)
            self.assertIn(url, declared)
        self.assertEqual(recipe.count('ARG CURL_PACKAGE_VERSION=' + version), 2)
        self.assertEqual(recipe.count('ARG UBUNTU_RUNTIME_SECURITY_SNAPSHOT=20261002T000000Z'), 2)
        self.assertNotRegex(recipe, r'apt-get download\s+\\\s*\n\s*"curl=')
        copy = 'cp "/tmp/${package}.deb" "/out/packages/${package}_${CURL_PACKAGE_VERSION}_amd64.deb"'
        self.assertIn(copy, declared)
        self.assertIn(copy + ';', recipe)
        self.assertIn('PASTURESTACK_CURL_PACKAGE_VERSION=' + version, builder)
        self.assertIn('"' + version + '"', builder)
        self.assertNotIn('8.18.0-1ubuntu2.7', recipe + builder + FILES[VEX] + GATE)
        for field in ('Package', 'Version', 'Architecture'):
            self.assertIn('dpkg-deb -f "${package_file}" ' + field, recipe)
        fixed = next(item for item in json.loads(FILES[VEX])['statements']
                     if item['vulnerability']['name'] == 'CVE-2026-8932')
        self.assertEqual(fixed['status'], 'fixed')
        self.assertEqual({item['@id'] for item in fixed['products']},
                         {'pkg:deb/ubuntu/' + package + '@' + version + '?arch=amd64&distro=ubuntu-26.04'
                          for package in expected})

    def test_official_curl_gate_rejects_replaced_deb_inputs(self):
        declared = engine_gate_markers(GATE, 'release_curl_official_deb_marker')
        recipe = FILES[DOCKER]
        self.assertEqual(len(declared), 7)
        self.assertTrue(all(marker in recipe for marker in declared))
        for marker in declared:
            replacements = ['REMOVED_CURL_PIN']
            if '8.18.0-1ubuntu2.8' in marker:
                replacements.append(marker.replace('8.18.0-1ubuntu2.8', '8.18.0-1ubuntu2.7'))
            if 'ADD --checksum=sha256:' in marker:
                replacements.append('ADD --checksum=sha256:' + '0' * 64)
            for replacement in replacements:
                with self.subTest(marker=marker, replacement=replacement):
                    mutated = recipe.replace(marker, replacement)
                    self.assertFalse(all(required in mutated for required in declared),
                                     'the actual require_marker set rejects a removed, stale or wrong-hash input')

    def test_official_dbi_security_update_is_isolated_and_hash_pinned(self):
        recipe, builder = FILES[DOCKER], FILES[BUILD]
        digest = '3040f61cc06ebf363e5895db4cc2c7a2db8951296d39d4ef5fa0fc3fd364654e'
        url = 'https://security.ubuntu.com/ubuntu/pool/main/libd/libdbi-perl/libdbi-perl_1.647-1ubuntu0.26.04.4_amd64.deb'
        self.assertIn('ADD --checksum=sha256:' + digest, recipe)
        self.assertIn(url, recipe)
        self.assertEqual(recipe.count('ARG LIBDBI_PERL_PACKAGE_VERSION=1.647-1ubuntu0.26.04.4'), 2)
        self.assertNotIn('apt-get download "libdbi-perl=', recipe)
        self.assertIn('cp /tmp/libdbi-perl.deb "/out/packages/libdbi-perl_${LIBDBI_PERL_PACKAGE_VERSION}_amd64.deb"', recipe)
        self.assertIn('PASTURESTACK_LIBDBI_PERL_PACKAGE_VERSION=1.647-1ubuntu0.26.04.4', builder)
        self.assertIn('ARG UBUNTU_RUNTIME_SECURITY_SNAPSHOT=20261002T000000Z', recipe)
        self.assertNotIn('1.647-1ubuntu0.26.04.3', recipe + builder + GATE)
        for marker in ('Package)" = libdbi-perl', 'Architecture)" = amd64', 'Version)" = "${LIBDBI_PERL_PACKAGE_VERSION}"',
                       'sha256sum -c /usr/share/pasturestack/security/libdbi-perl-runtime.sha256', 'Unexpected DBI runtime version'):
            self.assertIn(marker, recipe)

    def test_runtime_aggregate_keeps_exact_twelve_binaries_seven_legal_dirs_and_two_copies(self):
        verify_runtime_layout(FILES)
        self.assertEqual(len(RUNTIME_BINARIES), 12)
        self.assertEqual(len(RUNTIME_LEGAL), 7)
        for command in (['install -m 0755 ' + ' '.join(row) + ';' for row in RUNTIME_BINARIES]
                        + ['cp -a ' + ' '.join(row) + ';' for row in RUNTIME_LEGAL]):
            normalized = FILES[DOCKER].replace('\\\n', ' ')
            pattern = r'\s+'.join(re.escape(part) for part in command.split())
            found = re.search(pattern, normalized)
            self.assertIsNotNone(found)
            for replacement in ('# ' + found.group(), found.group().replace('/out/', '/wrong/', 1),
                                found.group()[:-1] + ' || true;'):
                with self.subTest(command=command, replacement=replacement):
                    mutated = normalized[:found.start()] + replacement + normalized[found.end():]
                    with self.assertRaisesRegex(AssertionError, 'CURRENT_RUNTIME_.*(?:MISMATCH|BYPASS)'):
                        verify_runtime_layout(dict(FILES, **{DOCKER: mutated}))
        for marker in RUNTIME_LAYOUT_MARKERS:
            with self.subTest(gate=marker):
                with self.assertRaisesRegex(AssertionError, 'CURRENT_RUNTIME_LAYOUT_GATE_MISMATCH'):
                    verify_runtime_layout(FILES, GATE.replace(marker, 'REMOVED_LAYOUT_GATE'))
        for marker in (
            'COPY --from=release_artifacts --chmod=0755 /out/runtime-bin/ /usr/bin/',
            'COPY --from=release_artifacts /out/runtime-licenses/ /usr/share/licenses/pasturestack/',
            'test "$(find /out/runtime-bin -mindepth 1 -maxdepth 1 -type f | wc -l)" -eq 12;',
            'test "$(find /out/runtime-licenses -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 7;',
            'test -z "$(find /out/runtime-bin /out/runtime-licenses -type l -print -quit)"',
        ):
            for replacement in ('# ' + marker, marker.replace('0755', '0644').replace('-eq 12', '-eq 11').replace('-eq 7', '-eq 6'),
                                marker.rstrip(';') + ' || true;'):
                if replacement == marker:
                    continue
                with self.subTest(marker=marker, bypass=replacement):
                    with self.assertRaisesRegex(AssertionError, 'CURRENT_RUNTIME_.*(?:MISMATCH|BYPASS)'):
                        verify_runtime_layout(dict(FILES, **{DOCKER: FILES[DOCKER].replace(marker, replacement)}))

    def test_other_formal_component_coordinates_and_stale_inputs_fail_closed(self):
        coordinates = [
    [
        "AUTHENTICATION_SERVICE",
        "authentication_service",
        "0.4.46",
        "35333ee3e40d9de032c10307ee80113c980be00a",
        "15950344ac9cc688610eae6d1c023ae6ba66182de675f04445f4c98ced2f19ec",
        "e121cee8b7a6bd3c0eb6fe3e15ff304b78119b426642ed76f13e3d92be161192"
    ],
    [
        "WEBSOCKET_PROXY",
        "websocket_proxy",
        "0.23.18",
        "d3f71afb5945b8dedc1b6b80892be6145238cad1",
        "9b1cbb2eac08eafadc4e69aca728ca33787b58923abbf3b585db2aa729f09434",
        "72e67b9ff5ce6cf59a03860960ad59a06f6e6d7af9926f73c1f5dbec05dd97e7"
    ],
    [
        "WEBHOOK_AUTOMATION_SERVICE",
        "webhook_automation_service",
        "0.10.5",
        "4da77ccac464bc7f7cd2020e0659a666a5d1ff7e",
        "f2df8874d5a00a2d5713594609063256164ed624d29a733149d00cb271f0f66b",
        "b98e55db2739ab45119eacc94c8f65cb44371480ebcebec95e5470fd67c72a4c"
    ],
    [
        "COMPOSE_EXECUTOR",
        "compose_executor",
        "0.14.39",
        "53a33bdc13ae99f4bc4a2dc5cc760b6b2d098388",
        "4ab4685af67a8b8b11f3dd4996de9e087c26391ec401cf02cdcafe4c93094bab",
        "0f0c0ada23564572b569e1c73951ca363c0dc262fe7bba9c2474106650c4eac5"
    ],
    [
        "VSPHERE_CLI_BUNDLE",
        "vsphere_cli_bundle",
        "0.55.4",
        "35ca999b775a41e7fb34e9a6b6ceb4fa51f3f242",
        "abec8c22504adde66e2ccd89b7b764c8a643c5e1e4425dafb2964abde75806a0",
        None
    ]
]

        def check(files, gate=GATE):
            for upper, lower, version, commit, archive, binary in coordinates:
                values = dict(VERSION=version, COMMIT=commit, ARCHIVE_SHA256=archive)
                if binary is not None:
                    values['BINARY_SHA256'] = binary
                for field, value in values.items():
                    docker_marker = 'ARG ' + upper + '_' + field + '=' + value
                    build_marker = lower + '_' + field.lower() + '=$' + '{' + upper + '_' + field + ':-' + value + '}'
                    self.assertIn(docker_marker, files[DOCKER])
                    self.assertIn(build_marker, files[BUILD])
                    self.assertIn(docker_marker, gate)
                    # The proxy's version is bound by the Docker/runtime gate;
                    # its producer and hashes are also bound in the build gate.
                    if not (upper == 'WEBSOCKET_PROXY' and field == 'VERSION'):
                        self.assertIn(build_marker, gate)
            self.assertIn('ARG GOVC_BINARY_SHA256=8f43086cc85de88a93e510efe9375a1ff6e265ca12e764c1fc8ae4c35be69ded', files[DOCKER])

        check(FILES)
        for upper, lower, version, commit, archive, binary in coordinates:
            values = dict(VERSION=version, COMMIT=commit, ARCHIVE_SHA256=archive)
            if binary is not None:
                values['BINARY_SHA256'] = binary
            for field, value in values.items():
                markers = (
                    (DOCKER, 'ARG ' + upper + '_' + field + '=' + value),
                    (BUILD, lower + '_' + field.lower() + '=$' + '{' + upper + '_' + field + ':-' + value + '}'),
                )
                for name, marker in markers:
                    with self.subTest(component=upper, field=field, file=name):
                        with self.assertRaises(AssertionError):
                            check(dict(FILES, **{name: FILES[name].replace(marker, marker.replace(value, '0' * len(value)))}))
                        if marker in GATE:
                            with self.assertRaises(AssertionError):
                                check(FILES, GATE.replace(marker, 'REMOVED_FORMAL_PIN'))

    def test_current_go1273_producers_do_not_rewrite_historical_base_go(self):
        codeql = (REPO / '.github/workflows/codeql.yml').read_text(encoding='utf-8')
        compiler = codeql.split('- name: Set up the production Go compiler', 1)[1].split('- name:', 1)[0]
        self.assertIn("go-version: '1.27.3'", compiler)
        self.assertNotIn('1.27.2', compiler)
        self.assertIn('test "$(go env GOVERSION)" = \'go1.27.3\'', codeql)
        verify_incremental_contract(FILES)
        historical = (
            'ARG GO_BUILDER_IMAGE=golang:1.27.0-bookworm@sha256:ded31c68586d2e49e760acc2e65a884b23d032e9bbbed0ae0c55abd3fcaf4452',
            'ENV PASTURESTACK_RUNTIME_GO_VERSION=1.27.0',
        )
        base_patch = (REPO / 'server/Dockerfile.api-explorer-patch').read_text(encoding='utf-8')
        normalized = GATE.replace('\\\n', ' ')
        for marker in historical:
            self.assertIn(marker, base_patch)
            self.assertRegex(normalized, r'require_marker "\$dockerfile"\s+' + re.escape(shlex.quote(marker)))
        for name in (DOCKER, BUILD):
            with self.subTest(active=name):
                with self.assertRaisesRegex(AssertionError, 'CURRENT_INCREMENTAL_SOURCE_CONTRACT_MISMATCH'):
                    verify_incremental_contract(dict(FILES, **{name: FILES[name].replace('1.27.3', '1.27.2')}))

    def test_incremental_formal_producer_pins_and_every_missing_gate_rejected(self):
        verify_incremental_contract(FILES)
        for variable, name, markers in INCREMENTAL_CONTRACTS:
            for marker in markers:
                with self.subTest(name=name, missing=marker):
                    mutated = dict(FILES, **{name: FILES[name].replace(marker, 'REMOVED_INCREMENTAL_CONTRACT')})
                    with self.assertRaisesRegex(AssertionError, 'CURRENT_INCREMENTAL_SOURCE_CONTRACT_MISMATCH'):
                        verify_incremental_contract(mutated)
                with self.subTest(variable=variable, gate=marker):
                    shell_marker = shlex.quote(marker)
                    self.assertIn(shell_marker, GATE)
                    mutated_gate = GATE.replace(shell_marker, shlex.quote('REMOVED_GATE_CONTRACT'))
                    self.assertNotEqual(mutated_gate, GATE)
                    with self.assertRaisesRegex(AssertionError, 'CURRENT_INCREMENTAL_GATE_CONTRACT_MISMATCH'):
                        verify_incremental_contract(FILES, mutated_gate)
        producer_markers = INCREMENTAL_CONTRACTS[0][2]
        for marker in producer_markers:
            expected_count = 1 if marker.startswith('ARG COMPOSE_EXECUTOR_COMMIT=') else 2
            self.assertEqual(FILES[DOCKER].splitlines().count(marker), expected_count)
            field, value = marker.split('=', 1)
            for invalid in ('PENDING_OFFICIAL_SOURCE', '0' * len(value)):
                with self.subTest(field=field, invalid=invalid):
                    with self.assertRaisesRegex(AssertionError, 'CURRENT_INCREMENTAL_SOURCE_CONTRACT_MISMATCH'):
                        verify_incremental_contract(dict(FILES, **{DOCKER: FILES[DOCKER].replace(marker, field + '=' + invalid)}))

    def test_new_producer_binary_alias_version_and_legal_commands_fail_closed(self):
        verify_incremental_contract(FILES)
        commands = INCREMENTAL_CONTRACTS[2][2]
        for marker in commands:
            if not marker.endswith(';'):
                continue
            for replacement in ('# ' + marker, marker[:-1] + ' || true;', marker[:-1] + ' || :;'):
                with self.subTest(marker=marker, bypass=replacement):
                    with self.assertRaisesRegex(AssertionError, 'CURRENT_(?:INCREMENTAL|RUNTIME)_.*(?:MISMATCH|BYPASS)'):
                        verify_incremental_contract(dict(FILES, **{DOCKER: FILES[DOCKER].replace(marker, replacement)}))
        for upper, version, digest, binary in (
            ('HOST_PROVISIONER', '0.39.10', '92c6d9ce1222a93802ff2c92b100eeb6c58286f3fca90698f9687b92d6fa9dff', '/usr/bin/host-provisioner.real'),
            ('SECRET_DELIVERY_API', '0.3.3', 'e4928ca7359975ba4ad73456296baace8ef0b428c0901055a0317244a17e4665', '/usr/bin/secret-delivery-api'),
            ('USAGE_TELEMETRY_AGENT', '0.4.4', '90ed65f689c91801abd0cf482211c96a01e7c63ef695e4faecdf4713eff730be', '/usr/bin/usage-telemetry-agent'),
        ):
            self.assertIn(digest + '  ' + binary, FILES[BUILD])
            self.assertIn('PASTURESTACK_' + upper + '_VERSION="' + '$' + '{' + upper.lower() + '_version}"', FILES[BUILD])

    def test_compose_executor_artifact_and_real_binary_keep_distinct_version_contracts(self):
        source = FILES[DOCKER]
        artifact = 'compose_version_output="$(/out/compose-executor --version 2>&1)"; \\\n    test "${compose_version_output}" = "compose-executor version ${COMPOSE_EXECUTOR_VERSION}";'
        runtime = 'compose_version_output="$(/usr/bin/compose-executor.real --version 2>&1)"; \\\n    test "${compose_version_output}" = "pasturestack-compose version ${COMPOSE_EXECUTOR_VERSION}";'
        # The producer dispatches by executable basename. Only the unrenamed
        # artifact uses the executor name; the installed .real binary is the CLI.
        self.assertEqual(source.count(artifact), 1)
        self.assertEqual(source.count(runtime), 1)
        self.assertIn(shlex.quote('test "${compose_version_output}" = "compose-executor version ${COMPOSE_EXECUTOR_VERSION}"'), GATE)
        self.assertIn('"pasturestack-compose version ${PASTURESTACK_COMPOSE_EXECUTOR_VERSION}"', FILES[BUILD])

    def test_cni025_source_pins_typed_qualifier_and_final_env_override(self):
        cni = {
            'VERSION': '0.2.5',
            'PRODUCER_COMMIT': 'e102e0bb38d84b0a9cbf87e5458cf1bc74d01904',
            'ARCHIVE_SHA256': '7237e83e96a64e7f3de64eb86bff9721c4e879c35cda9e9de1e4cb1ba225f298',
            'BINARY_SHA256': '3d0e5b3f32eacf88cde9a8700432b64ad157810a053e59ebffe82a924a18ee30',
            'STARTUP_SHA256': 'f22b41f18d1733c037babed4d2e0474efeedc6017a96849d4309dd864f5f86d1',
            'PROVENANCE_SHA256': 'afa2db0e0755c6bd3ee28e111937c521a6d84e6d71d563e99202cf4693000eaf',
        }
        def exact_cni_sources(files):
            for suffix, value in cni.items():
                upper = 'PER_HOST_SUBNET_' + suffix
                lower = upper.lower()
                if 'ARG ' + upper + '=' + value + '\n' not in files[DOCKER]:
                    raise ValueError('CNI025_EXACT_RECIPE_PIN_REQUIRED')
                if lower + '=${' + upper + ':-' + value + '}\n' not in files[BUILD]:
                    raise ValueError('CNI025_EXACT_BUILD_PIN_REQUIRED')
            for marker in (
                'COPY --from=release_artifacts /out/per-host-subnet.zip /usr/share/cattle/artifacts/per-host-subnet-${PER_HOST_SUBNET_VERSION}-windows-amd64.zip',
                'ENV RC16_PER_HOST_SUBNET_VERSION=${PER_HOST_SUBNET_VERSION}',
                'CATTLE_AGENT_PACKAGE_PER_HOST_SUBNET_URL=/usr/share/cattle/artifacts/per-host-subnet-%s-windows-amd64.zip',
                '"${HOST_API_VERSION}" "${NODE_AGENT_VERSION}" "${PER_HOST_SUBNET_VERSION}"',
            ):
                if marker not in files[DOCKER]:
                    raise ValueError('CNI025_FINAL_IMAGE_OVERRIDE_REQUIRED')
        exact_cni_sources(FILES)
        for suffix, value in cni.items():
            for path in (DOCKER, BUILD):
                broken = dict(FILES)
                broken[path] = broken[path].replace(value, 'wrong-cni-pin')
                with self.subTest(suffix=suffix, path=path), self.assertRaises(ValueError):
                    exact_cni_sources(broken)
        qualifier = (REPO / 'server/artifacts/prepare-nested-agent-scan.py').read_text(encoding='utf-8')
        self.assertIn("'producerSource': producer, 'provenanceReceiptSha256': provenance", qualifier)
        self.assertIn("'vcsMetadata': 'ABSENT_BY_PRODUCER_BUILDVCS_FALSE_CONTRACT'", qualifier)
        self.assertIn("records.append(cni_payload(rootfs, pins, output))", qualifier)

    def test_current_host_node_coordinates_match_official_original_bytes(self):
        coordinates = {
            'HOST_API_VERSION': '0.38.8',
            'HOST_API_RELEASE_TAG': 'v0.38.8',
            'HOST_API_COMMIT': '4810ffbb4499c24d9f7066d64de3203f9a6771e4',
            'HOST_API_PACKAGE_ID': '4810ffbb4499c24d9f7066d64de3203f',
            'HOST_API_ARCHIVE_SHA256': '6903ffb6a618f5a9bc8c7c8997a1e0419c93a8bbdeaee6d288957366dccef444',
            'HOST_API_BINARY_SHA256': '85fceccc5e2724aa896560392123fc8927786915b03f6d42eb688e151a402b8a',
            'HOST_API_APPLY_SHA256': '8a21f63099832afb571755011bbcf8d97710994a50c419b20700cbc31efced0f',
            'NODE_AGENT_VERSION': '0.13.32',
            'NODE_AGENT_COMMIT': 'e3853e288702f59c76c318dd530abb508e9bd6cb',
            'NODE_AGENT_PACKAGE_ID': 'e3853e288702f59c76c318dd530abb50',
            'NODE_AGENT_ARCHIVE_SHA256': '9aae6de63b575fa26d88894a5dc811691293a70b155137dc861263c69ef73972',
            'NODE_AGENT_BINARY_SHA256': 'bd36e9edd606d2a73406ba68363f3bc96132cb611402622ea16aae8c15d50236',
            'NODE_AGENT_APPLY_SHA256': 'dd8cb342518a43e7468cc121db5c4e44b16731f2620b77ea0fd03c02c03766a9',
            'NODE_AGENT_WINDOWS_ARCHIVE_SHA256': '2fc565f6b36691d0ccd59cd4b6f1f65acf5495efabd9eae253f76a2700378a78',
            'NODE_AGENT_WINDOWS_BINARY_SHA256': 'fb3a59d8f14da0b4026daea3fdadb1be2f6a1188eac7fcaec730e6fdccc5ae81',
            'NODE_AGENT_WINDOWS_STARTUP_SHA256': 'e1e84e1c5125db2b8f0c1a83ada8294556cb2390de969398a2436d9481378fca',
        }
        repeated = {'HOST_API_VERSION', 'HOST_API_COMMIT', 'HOST_API_PACKAGE_ID',
                    'HOST_API_ARCHIVE_SHA256', 'NODE_AGENT_VERSION',
                    'NODE_AGENT_COMMIT', 'NODE_AGENT_ARCHIVE_SHA256'}

        def verify(files):
            for name, value in coordinates.items():
                rows = re.findall(r'^ARG ' + name + r'=(.+)$', files[DOCKER], re.M)
                if rows != [value] * (2 if name in repeated else 1):
                    raise ValueError('CURRENT_HOST_NODE_EXACT_RECIPE_COORDINATES')
                fallback = '${node_agent_commit:0:32}' if name == 'NODE_AGENT_PACKAGE_ID' else value
                marker = name.lower() + '=${' + name + ':-' + fallback + '}'
                if marker not in files[BUILD]:
                    raise ValueError('CURRENT_HOST_NODE_EXACT_BUILD_COORDINATES')
                if "'ARG " + name + '=' + value + "'" not in GATE:
                    raise ValueError('CURRENT_HOST_NODE_EXACT_SOURCE_GATE')

        verify(FILES)
        for name, value in coordinates.items():
            for path in (DOCKER, BUILD):
                broken = dict(FILES)
                broken[path] = broken[path].replace(value, 'stale-component-pin')
                with self.subTest(coordinate=name, path=path), self.assertRaises(ValueError):
                    verify(broken)

    def test_eighteen_component_inputs_keep_exact_sha_fetch_and_separate_jdk_stage(self):
        verify_incremental_contract(FILES)
        block = FILES[BUILD].split('    component_assets=(\n', 1)[1].split('    )', 1)[0]
        self.assertEqual([line.strip() for line in block.splitlines()], EXACT_COMPONENT_INPUTS)
        self.assertEqual(len(EXACT_COMPONENT_INPUTS), 18)
        self.assertEqual(len(re.findall(r'^FROM ', FILES[DOCKER], re.M)), 6)
        self.assertIn('FROM scratch AS component_input', FILES[DOCKER])
        final = FILES[DOCKER].rsplit('FROM ${BASE_IMAGE}', 1)[1]
        self.assertLessEqual(len(re.findall(r'^(RUN|COPY|ADD)\b', final, re.M)), 32)
        self.assertEqual(len(re.findall(r'^\s+fetch-server-component ', FILES[DOCKER], re.M)), 16)
        self.assertIn('"${release_url%/}/v${version}/${artifact}" "${artifact}" "${archive_sha}"', FILES[DOCKER])
        release_stage = FILES[DOCKER].split('FROM ${ARTIFACT_HELPER_IMAGE} AS release_artifacts', 1)[1].split('FROM ${UBUNTU_SECURITY_IMAGE}', 1)[0]
        self.assertNotIn('curl -fsSL', release_stage)
        self.assertIn('"catalog-service-${CATALOG_SERVICE_VERSION}-LICENSE.txt" "${CATALOG_SERVICE_LICENSE_SHA256}"', release_stage)
        fetch = (REPO / 'server/artifacts/fetch-server-component.sh').read_text(encoding='utf-8')
        hash_guard = 'printf \'%s  %s\\n\' "$expected" "$output" | sha256sum -c -'
        self.assertEqual(fetch.count(hash_guard), 1)
        self.assertIn('test -f "$input" && test ! -L "$input"', fetch)
        self.assertIn('https://*) ;;', fetch)
        self.assertIn('*) echo \'Unknown component artifact mode\' >&2; exit 2 ;;', fetch)
        for replacement in ('# ' + hash_guard, hash_guard + ' || true', hash_guard + ' || :'):
            source = fetch.replace(hash_guard, replacement)
            pattern = r'(?m)^' + re.escape(hash_guard) + r'$'
            self.assertEqual(len(re.findall(pattern, source)), 0)

    def test_producer_helper_keeps_original_package_metadata_and_legal_boundaries(self):
        source = (REPO / 'server/artifacts/verify-runtime-producer.sh').read_text(encoding='utf-8')
        for marker in (
            'echo "$binary_sha  $output/$type" | sha256sum -c -',
            'test "$(printf \'%s\\n\' "$metadata" | awk \'NR==1 {print $2}\')" = go1.27.3',
            "'CGO_ENABLED=0' 'GOOS=linux' 'GOARCH=amd64' 'GOAMD64=v1'",
            'test ! -s "$duplicates"',
            "if grep -Eq '^[lh]' \"$verbose\"; then",
            'tar --no-same-owner --no-same-permissions --strip-components=1 -xJf "$archive"',
            '[[ "$output" == "/out/$type" && ! -e "$output" ]]',
            'grep -Fx "Release source commit: $commit"',
            'test "$(find "$output/licenses" -type f | wc -l)" -eq 35',
            '"$type-PRIVACY.md"',
            'SERVER-PRODUCER-SOURCES.txt',
            'if [[ "${entry##*/}" != "$type" ]]',
        ):
            self.assertIn(marker, source)

    def test_catalog13_runtime_defaults_and_operator_override_boundary(self):
        verify(FILES)
        catalog = {'catalogs': {'pasturestack': {
            'url': 'https://github.com/PastureStack/catalog-templates.git',
            'branch': 'main', 'pinnedCommit': CATALOG_COMMIT,
        }}}
        literal = json.dumps(catalog, separators=(',', ':'))
        for name in ('DEFAULT_CATTLE_CATALOG_URL', 'CATTLE_CATALOG_URL'):
            marker = name + "='" + literal + "'"
            self.assertEqual(FILES[DOCKER].splitlines().count('ENV ' + marker), 1)
            self.assertEqual(FILES[BUILD].count("'" + name + '=' + literal + "'"), 1)
        # Only image defaults change. No startup/configuration/DB mutation is
        # introduced to override a user's explicit catalog setting.
        self.assertNotIn('UPDATE setting', FILES[BUILD])

    def test_freetype_official_deb_and_library_checks_fail_closed(self):
        version = '2.14.2+dfsg-1ubuntu0.2'
        archive_sha = '6d7d532b7d0c57639deb3b228f1f0d786cf5305d613ef7df9ba76c776a0f8373'
        archive_url = 'https://security.ubuntu.com/ubuntu/pool/main/f/freetype/libfreetype6_' + version + '_amd64.deb'
        archive = r'^ADD --checksum=sha256:' + archive_sha + r' \\\n\s+' + re.escape(archive_url) + r' \\\n\s+/tmp/libfreetype6\.deb$'
        hash_guard = 'sha256sum -c /usr/share/pasturestack/security/freetype-runtime.sha256'
        paths = ((DOCKER, 'release_freetype_security_marker'), (BUILD, 'runtime_freetype_security_marker'))

        def check(files):
            self.assertEqual(files[DOCKER].splitlines().count('ARG FREETYPE_PACKAGE_VERSION=' + version), 2)
            self.assertEqual(len(re.findall(archive, files[DOCKER], re.M)), 1)
            self.assertEqual(len(re.findall(r'^FROM ', files[DOCKER], re.M)), 6)
            self.assertIn('FROM scratch AS component_input', files[DOCKER])
            for name, variable in paths:
                for marker in engine_gate_markers(GATE, variable):
                    self.assertIn(marker, files[name])
                source = files[name].replace('\\\n', ' ')
                pipeline = r'(?:^|[;\n])\s*' + re.escape(hash_guard) + r'(?=\s*(?:;|\n|$))'
                self.assertEqual(len(re.findall(pipeline, source)), 1)

        check(FILES)
        for name, variable in paths:
            for marker in engine_gate_markers(GATE, variable):
                with self.subTest(name=name, missing=marker):
                    with self.assertRaises(AssertionError):
                        check(dict(FILES, **{name: FILES[name].replace(marker, 'REMOVED_FREETYPE_CONTRACT')}))
            for replacement in (hash_guard + ' || true', '# ' + hash_guard):
                with self.subTest(name=name, bypass=replacement):
                    with self.assertRaises(AssertionError):
                        check(dict(FILES, **{name: FILES[name].replace(hash_guard, replacement)}))
        for value, stale_value in ((version, '2.14.2+dfsg-1ubuntu0.1'), (archive_sha, '0' * 64)):
            with self.subTest(stale=value):
                with self.assertRaises(AssertionError):
                    check(dict(FILES, **{DOCKER: FILES[DOCKER].replace(value, stale_value)}))

    def test_actual_candidate_gate_and_five_files_agree(self):
        verify(FILES)

    def test_candidate_coordinates_and_pending_rejection_use_actual_pin_predicates(self):
        # Interpret the actual, unchanged shell regex predicates, not a second
        # hardcoded publication predicate. Source agreement is not release PASS.
        # PENDING_WEB0_ARCHIVE_SHA256 is a unit-only negative input, not a component pin.
        resolved = re.fullmatch(r'[0-9a-f]{64}', WEB_SHA) is not None
        patterns = re.findall(r'\[\[ "\$(web_console_(?:commit|artifact_sha256))" =~ ([^ ]+) \]\]', FILES[BUILD])
        self.assertEqual(len(patterns), 2)
        for variable, pattern in patterns:
            default = re.search(r'^' + variable + r'=\$\{[^:}]+:-([^}]+)\}$', FILES[BUILD], re.M).group(1)
            expected_valid = resolved if variable.endswith('artifact_sha256') else re.fullmatch(r'[0-9a-f]{40}', WEB_SOURCE) is not None
            self.assertEqual(re.fullmatch(pattern, default) is not None, expected_valid)
            self.assertIsNone(re.fullmatch(pattern, 'PENDING_WEB0_ARCHIVE_SHA256'))
            actual_guard = '[[ "$' + variable + '" =~ ' + pattern + ' ]]'
            self.assertEqual(FILES[BUILD].count(actual_guard), 1)
            self.assertLess(FILES[BUILD].index(actual_guard), FILES[BUILD].index('docker buildx build'))
        prefix = "if ! grep -Eq '^ARG WEB_CONSOLE_ARTIFACT_SHA256="
        actual = prefix + GATE.split(prefix, 1)[1].split('; then', 1)[0]
        gates = re.findall(r"grep -Eq '([^']+)' \"\$(release_dockerfile|build_script)\"", actual)
        self.assertEqual(len(gates), 4)
        paths = dict(release_dockerfile=DOCKER, build_script=BUILD)
        self.assertEqual(all(re.search(pattern, FILES[paths[variable]], re.M) for pattern, variable in gates), resolved)
        for name, old in ((DOCKER, WEB_SHA), (DOCKER, WEB_SOURCE), (BUILD, WEB_SHA), (BUILD, WEB_SOURCE)):
            mutated = dict(FILES)
            mutated[name] = mutated[name].replace(old, 'PENDING_WEB0_ARCHIVE_SHA256')
            self.assertFalse(all(re.search(pattern, mutated[paths[variable]], re.M) for pattern, variable in gates))
        pending = re.search(r"if grep -Eq '([^']+)' \"\$release_dockerfile\" \"\$build_script\"; then\n\s+echo 'SERVER_COMPONENT_RELEASE_COORDINATES_PENDING' >&2\n\s+exit 1\nfi", GATE)
        self.assertIsNotNone(pending)
        self.assertEqual(any(re.search(pending.group(1), FILES[name]) for name in (DOCKER, BUILD)), not resolved)
        self.assertTrue(re.search(pending.group(1), FILES[BUILD].replace(WEB_SHA, 'PENDING_WEB0_ARCHIVE_SHA256')))
        # Direct Docker invocation must also reject a remaining pending default.
        for variable, digits in (('WEB_CONSOLE_ARTIFACT_SHA256', 64), ('WEB_CONSOLE_COMMIT', 40)):
            marker = "printf '%s\\n' \"${" + variable + "}\" | grep -Eq '^[0-9a-f]{" + str(digits) + "}$'; \\\n"
            self.assertEqual(FILES[DOCKER].count(marker), 1)
        artifact_guard = "printf '%s\\n' \"${WEB_CONSOLE_ARTIFACT_SHA256}\" | grep -Eq '^[0-9a-f]{64}$';"
        self.assertLess(FILES[DOCKER].index(artifact_guard), FILES[DOCKER].index('fetch-server-component "${COMPONENT_ARTIFACT_MODE}"'))
        self.assertIn('"${WEB_CONSOLE_ARTIFACT}" "${WEB_CONSOLE_ARTIFACT_SHA256}" "${web_archive}";', FILES[DOCKER])

    def test_catalog_both_stages_build_defaults_and_pending_reject(self):
        verify(FILES)
        for upper, lower, value in CATALOG_FIELDS:
            marker = 'ARG CATALOG_SERVICE_' + upper + '=' + value
            for occurrence in (0, 1):
                with self.subTest(field=upper, stage=occurrence):
                    lines = FILES[DOCKER].splitlines()
                    places = [i for i, line in enumerate(lines) if line == marker]
                    lines[places[occurrence]] = marker.rsplit('=', 1)[0] + '=PENDING_OFFICIAL_SOURCE'
                    files = dict(FILES, **{DOCKER: '\n'.join(lines)})
                    with self.assertRaisesRegex(AssertionError, 'CURRENT_CATALOG_STAGE_PIN_MISMATCH'):
                        verify(files)
            code = 'SERVER_INCREMENTAL_CATALOG_BUILD_' + upper + '_MISSING'
            build_marker = EXPECTED[code][1]
            for invalid in ('PENDING_OFFICIAL_SOURCE', '0' * len(value)):
                files = dict(FILES)
                files[BUILD] = files[BUILD].replace(build_marker, build_marker.replace(value, invalid))
                with self.assertRaisesRegex(AssertionError, code):
                    verify(files)
            if upper == 'VERSION':
                continue
            pattern = '^[0-9a-f]{' + ('40' if upper == 'COMMIT' else '64') + '}$'
            actual_guard = '[[ "$catalog_service_' + lower + '" =~ ' + pattern + ' ]]'
            self.assertEqual(FILES[BUILD].count(actual_guard), 1)
            self.assertLess(FILES[BUILD].index(actual_guard), FILES[BUILD].index('docker buildx build'))
            self.assertIsNotNone(re.fullmatch(pattern, value))
            self.assertIsNone(re.fullmatch(pattern, 'PENDING_OFFICIAL_SOURCE'))
        self.assertEqual(len(re.findall(r'^FROM ', FILES[DOCKER], re.M)), 6)
        self.assertIn('FROM scratch AS component_input', FILES[DOCKER])
        self.assertIn('SERVER_COMPONENT_RELEASE_COORDINATES_PENDING', GATE)
        self.assertIn('PENDING_OFFICIAL_(SOURCE|ARCHIVE|BINARY|SQLITE_BINARY)', GATE)

    def test_catalog_original_download_vcs_wrapper_license_and_runtime_guards_reject(self):
        for variable, name in (('catalog_release_marker', DOCKER), ('catalog_build_marker', BUILD)):
            for marker in engine_gate_markers(GATE, variable):
                with self.subTest(name=name, marker=marker):
                    files = dict(FILES)
                    files[name] = files[name].replace(marker, 'REMOVED_CATALOG_CONTRACT')
                    with self.assertRaisesRegex(AssertionError, 'CURRENT_CATALOG_FLOW_MISMATCH'):
                        verify(files)
                if marker.startswith('echo ') and '| sha256sum -c -' in marker:
                    files = dict(FILES)
                    files[name] = files[name].replace(marker, marker + ' || true')
                    with self.assertRaisesRegex(AssertionError, 'CURRENT_CATALOG_HASH_BYPASS'):
                        verify(files)
        self.assertNotIn('eb3d7b5485466acbd81f2b496f595ab637d2792e268206b27d99e793bdb67549', FILES[DOCKER])

    def test_published_508_compatibility_matches_actual_document(self):
        self.assertIn(PUBLISHED_508, FILES[COMPATIBILITY].splitlines())
        self.assertNotIn(STALE_508_CANDIDATE, FILES[COMPATIBILITY])
        self.assertIn("require_marker COMPATIBILITY.md '" + PUBLISHED_508 + "'", GATE)
        self.assertIn("require_marker COMPATIBILITY.md '" + PUBLISHED_508 + "'", previous_gate())
        verify(FILES)

    def test_missing_stale_candidate_or_wrong_web_compatibility_rejected(self):
        for marker in ('', STALE_508_CANDIDATE, PUBLISHED_508.replace('1.6.171', '1.6.170')):
            with self.subTest(marker=marker):
                files = dict(FILES)
                files[COMPATIBILITY] = files[COMPATIBILITY].replace(PUBLISHED_508, marker)
                with self.assertRaisesRegex(AssertionError, COMPATIBILITY_CODE):
                    verify(files)

    def test_stale_508_candidate_gate_rejected_even_with_current_document(self):
        stale_gate = GATE.replace("'" + PUBLISHED_508 + "'", "'" + STALE_508_CANDIDATE + "'")
        self.assertNotEqual(stale_gate, GATE)
        with self.assertRaisesRegex(AssertionError, 'CURRENT_GATE_PIN_MISMATCH'):
            verify(FILES, stale_gate)

    def test_previous_gate_and_each_old_component_pin_rejected(self):
        with self.assertRaisesRegex(AssertionError, 'CURRENT_GATE_PIN_MISMATCH'):
            verify(FILES, previous_gate())
        for code, (name, marker) in EXPECTED.items():
            if stale(marker) == marker:
                continue  # The native read-field guard is unchanged.
            with self.subTest(code=code):
                stale_marker = stale(marker)
                self.assertNotEqual(marker, stale_marker)
                files = dict(FILES)
                files[name] = files[name].replace(marker, stale_marker)
                with self.assertRaisesRegex(AssertionError, code):
                    verify(files)

    def test_each_old_engine_coordinate_rejected(self):
        checked = 0
        for code, (name, _, markers) in ENGINE_EXPECTED.items():
            for marker in markers:
                if stale_engine(marker) == marker:
                    continue
                checked += 1
                with self.subTest(name=name, marker=marker):
                    files = dict(FILES)
                    files[name] = files[name].replace(marker, stale_engine(marker))
                    with self.assertRaisesRegex(AssertionError, code):
                        verify(files)
        self.assertGreater(checked, 0)

    def test_historical_engine340_cannot_be_packaged(self):
        old = {'0.183.354': '0.183.340',
               ENGINE_SHA: '5e5a1b908b43bf3824fc3bb2108bd661cd5199ce9bcfd187e0b18b5608a38cea',
               ENGINE_SOURCE: 'ff0a41e7676211043eb4f755a306a9e2a19abee1'}
        checked = 0
        for code, (name, _, markers) in ENGINE_EXPECTED.items():
            for marker in markers:
                previous = marker
                for current, stale_value in old.items():
                    previous = previous.replace(current, stale_value)
                if previous == marker:
                    continue
                checked += 1
                with self.subTest(name=name, marker=marker):
                    files = dict(FILES)
                    files[name] = files[name].replace(marker, previous)
                    with self.assertRaisesRegex(AssertionError, code):
                        verify(files)
        self.assertGreater(checked, 0)

    def test_engine352_actual_war_producer_and_previous351_350_boundary(self):
        candidate = (REPO / 'server/build-component-candidate.sh').read_text(encoding='utf-8')
        self.assertIn('export SERVER_RELEASE_TAG=${SERVER_RELEASE_TAG:-v1.6.546}', candidate)
        self.assertIn('export ORCHESTRATION_ENGINE_RELEASE_TAG=${ORCHESTRATION_ENGINE_RELEASE_TAG:-v0.183.354}', candidate)
        for old in (
            {'0.183.354': '0.183.351',
             ENGINE_SHA: 'efd0e826364c551f782b281f081d53cadb48faa7d5c37c2f101e6f9c7d7f9ea6',
             ENGINE_SOURCE: '1befd83278618f9a5b7cdaf96522004dd89918ba'},
            {'0.183.354': '0.183.350',
             ENGINE_SHA: '637ddaa42cd93c019b4d0813d7053b71dc42797a7f3ac2aa4b10fcc7e304cb31',
             ENGINE_SOURCE: '9c884710e5ea3d4136d80a870d9de9485674f3c3'},
            {ENGINE_SOURCE: '109f2623f00ca3a3a9079414a0f0f8bd23cd1eb2'},
        ):
            checked = 0
            for code, (name, _, markers) in ENGINE_EXPECTED.items():
                for marker in markers:
                    previous = marker
                    for current, prior in old.items():
                        previous = previous.replace(current, prior)
                    if previous == marker:
                        continue
                    checked += 1
                    with self.subTest(name=name, marker=marker, previous=previous):
                        files = dict(FILES)
                        files[name] = files[name].replace(marker, previous)
                        with self.assertRaisesRegex(AssertionError, code):
                            verify(files)
            self.assertGreater(checked, 0)


    def test_immediately_previous_engine341_cannot_be_packaged(self):
        old = {'0.183.354': '0.183.341',
               ENGINE_SHA: '3ede1ad28b7a7e0754c4c953bd486162f7ffe0b2f76ce384ec485632af6b8e6d',
               ENGINE_SOURCE: 'b245cf778479445ded0786d3898b03fea153212e'}
        checked = 0
        for code, (name, _, markers) in ENGINE_EXPECTED.items():
            for marker in markers:
                previous = marker
                for current, stale_value in old.items():
                    previous = previous.replace(current, stale_value)
                if previous == marker:
                    continue
                checked += 1
                with self.subTest(name=name, marker=marker):
                    files = dict(FILES)
                    files[name] = files[name].replace(marker, previous)
                    with self.assertRaisesRegex(AssertionError, code):
                        verify(files)
        self.assertGreater(checked, 0)


    def test_immediately_previous_engine342_cannot_be_packaged(self):
        old = {'0.183.354': '0.183.342',
               ENGINE_SHA: '3533f247392795329c92516a7966510aafbe81a52e3f922e5ec657a2071363b5',
               ENGINE_SOURCE: 'ddae4bb8e12806f70816f5782cd999eccd0f2ce6'}
        checked = 0
        for code, (name, _, markers) in ENGINE_EXPECTED.items():
            for marker in markers:
                previous = marker
                for current, stale_value in old.items():
                    previous = previous.replace(current, stale_value)
                if previous == marker:
                    continue
                checked += 1
                with self.subTest(name=name, marker=marker):
                    files = dict(FILES)
                    files[name] = files[name].replace(marker, previous)
                    with self.assertRaisesRegex(AssertionError, code):
                        verify(files)
        self.assertGreater(checked, 0)


    def test_immediately_previous_engine343_cannot_be_packaged(self):
        old = {'0.183.354': '0.183.343',
               ENGINE_SHA: 'b29c0057f96dbae38bfe2c663c63bbe4c8b5c755b3090f39414aa51f9813025f',
               ENGINE_SOURCE: '5aa9d8978c75a7fe63330453c399a92716d88568'}
        checked = 0
        for code, (name, _, markers) in ENGINE_EXPECTED.items():
            for marker in markers:
                previous = marker
                for current, stale_value in old.items():
                    previous = previous.replace(current, stale_value)
                if previous == marker:
                    continue
                checked += 1
                with self.subTest(name=name, marker=marker):
                    files = dict(FILES)
                    files[name] = files[name].replace(marker, previous)
                    with self.assertRaisesRegex(AssertionError, code):
                        verify(files)
        self.assertGreater(checked, 0)


    def test_immediately_previous_engine344_cannot_be_packaged(self):
        old = {'0.183.354': '0.183.344',
               ENGINE_SHA: 'ffafa4700156b74ec11bcae1b830738e49943f1a3b8b0565895ed6d7726eebf1',
               ENGINE_SOURCE: '72c42e6f2000301fe03ffd2442fb9ee89aee120c'}
        checked = 0
        for code, (name, _, markers) in ENGINE_EXPECTED.items():
            for marker in markers:
                previous = marker
                for current, stale_value in old.items():
                    previous = previous.replace(current, stale_value)
                if previous == marker:
                    continue
                checked += 1
                with self.subTest(name=name, marker=marker):
                    files = dict(FILES)
                    files[name] = files[name].replace(marker, previous)
                    with self.assertRaisesRegex(AssertionError, code):
                        verify(files)
        self.assertGreater(checked, 0)

    def test_immediately_previous_engine345_cannot_be_packaged(self):
        old = {'0.183.354': '0.183.345',
               ENGINE_SHA: '780263c4a884527fa80a28b998ad4bda88b9ad6002a687f9f074602ecad46e62',
               ENGINE_SOURCE: 'd27d4ac73fa05ae43b9ae0c32875780e8a3765b1'}
        checked = 0
        for code, (name, _, markers) in ENGINE_EXPECTED.items():
            for marker in markers:
                previous = marker
                for current, stale_value in old.items():
                    previous = previous.replace(current, stale_value)
                if previous == marker:
                    continue
                checked += 1
                with self.subTest(name=name, marker=marker):
                    files = dict(FILES)
                    files[name] = files[name].replace(marker, previous)
                    with self.assertRaisesRegex(AssertionError, code):
                        verify(files)
        self.assertGreater(checked, 0)

    def test_immediately_previous_engine346_cannot_be_packaged(self):
        old = {'0.183.354': '0.183.346',
               ENGINE_SHA: '9deeda5758b7f04135441a203092dd0308d90b65d25037b62ef4f9361d3cf806',
               ENGINE_SOURCE: 'e250e4a17958216c30c1f5d0d31f7b6418a968d5'}
        checked = 0
        for code, (name, _, markers) in ENGINE_EXPECTED.items():
            for marker in markers:
                previous = marker
                for current, stale_value in old.items():
                    previous = previous.replace(current, stale_value)
                if previous == marker:
                    continue
                checked += 1
                with self.subTest(name=name, marker=marker):
                    files = dict(FILES)
                    files[name] = files[name].replace(marker, previous)
                    with self.assertRaisesRegex(AssertionError, code):
                        verify(files)
        self.assertGreater(checked, 0)

    def test_previous_fixture_rejects_stale_web179_pins(self):
        gate = previous_gate()
        for code, (_, marker) in EXPECTED.items():
            if 'WEB_CONSOLE' in code:
                self.assertIn(marker, GATE)
                self.assertIn(stale(marker), gate)
        for _, variable, markers in ENGINE_EXPECTED.values():
            declared = engine_gate_markers(gate, variable)
            self.assertEqual(declared, engine_gate_markers(GATE, variable))
            for marker in markers:
                self.assertIn(marker, declared)

    def test_native_read_field_guard_fails_closed(self):
        for code in ('SERVER_VOLUME_NATIVE_READ_ONLY_BUILD_GATE_MISSING',
                     'SERVER_VOLUME_NATIVE_READ_ONLY_RUNTIME_GATE_MISSING'):
            name, marker = EXPECTED[code]
            for mutation in ('missing', 'writable', 'wrong-field', 'bypass', 'wrong-source'):
                with self.subTest(name=name, mutation=mutation):
                    files = dict(FILES)
                    if mutation == 'missing':
                        replacement = 'true'
                    elif mutation == 'writable':
                        replacement = marker.replace('"r"', '"cru"').replace(r'\"r\"', r'\"cru\"')
                    elif mutation == 'wrong-field':
                        replacement = marker.replace('volume.isNative', 'volume.isHostPath')
                    elif mutation == 'bypass':
                        replacement = marker + ' || true'
                    else:
                        replacement = marker
                        files[name] = files[name].replace('schema/user/user-auth.json', 'schema/base/volume.json')
                    files[name] = files[name].replace(marker, replacement)
                    with self.assertRaisesRegex(AssertionError, code):
                        verify(files)
            with self.subTest(name=name, mutation='gate-missing'):
                with self.assertRaisesRegex(AssertionError, 'CURRENT_GATE_PIN_MISMATCH'):
                    verify(FILES, GATE.replace(code, code + '_REMOVED'))

    def test_create_response_order_packaged_markers_fail_closed(self):
        for code in CREATE_RESPONSE_CODES:
            name, marker = EXPECTED[code]
            for mutation in ('missing', 'bypass', 'wrong-source', 'comment-only'):
                with self.subTest(code=code, mutation=mutation):
                    files = dict(FILES)
                    replacement = {
                        'missing': 'true',
                        'bypass': marker + ' || true',
                        'wrong-source': marker.replace('/assets/*.js', '/translations/*.json'),
                        'comment-only': '# ' + marker,
                    }[mutation]
                    files[name] = files[name].replace(marker, replacement)
                    with self.assertRaisesRegex(AssertionError, code):
                        verify(files)
            with self.subTest(code=code, mutation='gate-missing'):
                with self.assertRaisesRegex(AssertionError, 'CURRENT_GATE_PIN_MISMATCH'):
                    verify(FILES, GATE.replace(code, code + '_REMOVED'))

    def test_old_vex_or_vendor_release_rejected(self):
        for name, key, value in ((VEX, '@id', 'https://github.com/PastureStack/server/security/openvex/v1.6.515'),
                                 (VENDOR, 'release', 'v1.6.508')):
            with self.subTest(name=name):
                files = dict(FILES)
                data = json.loads(files[name])
                data[key] = value
                files[name] = json.dumps(data)
                with self.assertRaisesRegex(AssertionError, 'CURRENT_.*_RELEASE_MISMATCH'):
                    verify(files)

    def test_previous_pin_fixture_keeps_versioned_historical_markers(self):
        for marker in (
            "require_marker docs/releases/server-1.6.501.md '# Server v1.6.501'",
            "require_marker docs/releases/server-1.6.501.md 'No migration or runtime patch is required.'",
            "require_marker COMPATIBILITY.md 'Server `v1.6.501` packages Web Console `1.6.165`'",
        ):
            self.assertIn(marker, GATE)
            self.assertIn(marker, previous_gate())
        self.assertNotRegex(GATE, r"require_marker README\.md '## v[0-9]")

    def test_proxy_binary_readback_uses_the_verified_component_parameter(self):
        for field, value in (
            ('COMMIT', 'd3f71afb5945b8dedc1b6b80892be6145238cad1'),
            ('ARCHIVE_SHA256', '9b1cbb2eac08eafadc4e69aca728ca33787b58923abbf3b585db2aa729f09434'),
            ('BINARY_SHA256', '72e67b9ff5ce6cf59a03860960ad59a06f6e6d7af9926f73c1f5dbec05dd97e7'),
        ):
            docker_marker = 'ARG WEBSOCKET_PROXY_' + field + '=' + value
            build_marker = 'websocket_proxy_' + field.lower() + '=${WEBSOCKET_PROXY_' + field + ':-' + value + '}'
            self.assertEqual(2, FILES[DOCKER].count(docker_marker))
            self.assertIn(build_marker, FILES[BUILD])
            self.assertIn(docker_marker, GATE)
            self.assertIn(build_marker, GATE)
        markers = (
            'PASTURESTACK_WEBSOCKET_PROXY_BINARY_SHA256="${websocket_proxy_binary_sha256}"',
            'echo "${PASTURESTACK_WEBSOCKET_PROXY_BINARY_SHA256}  /usr/bin/websocket-proxy.real" | sha256sum -c -',
        )
        for marker in markers:
            self.assertIn(marker, FILES[BUILD])
            self.assertIn(marker, GATE)
        self.assertNotRegex(FILES[BUILD], r'(?m)^[0-9a-f]{64}  /usr/bin/websocket-proxy[.]real$')

    def test_govc_fixed_dependency_and_binary_readback_use_formal_pins(self):
        for upper, lower, value in (
            ('VSPHERE_CLI_BUNDLE_VERSION', 'vsphere_cli_bundle_version', '0.55.4'),
            ('VSPHERE_CLI_BUNDLE_COMMIT', 'vsphere_cli_bundle_commit', '35ca999b775a41e7fb34e9a6b6ceb4fa51f3f242'),
            ('VSPHERE_CLI_BUNDLE_ARCHIVE_SHA256', 'vsphere_cli_bundle_archive_sha256', 'abec8c22504adde66e2ccd89b7b764c8a643c5e1e4425dafb2964abde75806a0'),
            ('GOVC_BINARY_SHA256', 'govc_binary_sha256', '8f43086cc85de88a93e510efe9375a1ff6e265ca12e764c1fc8ae4c35be69ded'),
        ):
            docker_marker = 'ARG ' + upper + '=' + value
            build_marker = lower + '=${' + upper + ':-' + value + '}'
            self.assertEqual(1 if upper.endswith('_COMMIT') else 2, FILES[DOCKER].count(docker_marker))
            self.assertIn(build_marker, FILES[BUILD])
            self.assertIn(docker_marker, GATE)
            self.assertIn(build_marker, GATE)
        for marker in (
            'echo "${PASTURESTACK_GOVC_BINARY_SHA256}  /usr/bin/govc" | sha256sum -c -',
            'test "$(/usr/bin/govc version)" = "govc ${PASTURESTACK_VSPHERE_CLI_BUNDLE_VERSION}"',
            'Security dependency: golang.org/x/text v0.41.0',
        ):
            self.assertIn(marker, FILES[BUILD])
            self.assertIn(marker, GATE)
        self.assertNotRegex(FILES[BUILD], r'(?m)^[0-9a-f]{64}  /usr/bin/govc$')
        self.assertIn('Dependency-only override: govc/go.mod and govc/go.sum; upstream Go source unchanged', FILES[DOCKER])

    def test_current_readme_keeps_install_and_upgrade_contract(self):
        block = GATE.split('for current_readme_marker in ', 1)[1].split('; do', 1)[0]
        markers = shlex.split(block.replace('\\\n', ' '))
        for marker in ('## Quick start', '## Upgrade and rollback',
                       '[upgrade guide](docs/upgrades/README.md)',
                       'Do not replace existing volumes with new empty ones or run `docker compose down -v`.',
                       'rollback may require restoring matching data', '[release notes](docs/releases)'):
            self.assertIn(marker, markers)
        readme = (REPO / 'README.md').read_text(encoding='utf-8')
        for marker in markers:
            self.assertIn(marker, readme)

    def test_machine_actual_binary_package_and_retired_boundary_are_verified(self):
        for name, value in (
            ('MACHINE_DRIVER_BUNDLE_VERSION', '0.16.5'),
            ('MACHINE_DRIVER_BUNDLE_COMMIT', 'f8d9d86f896ca14a50f3788c2f6a200a1c3b6b21'),
            ('MACHINE_DRIVER_BUNDLE_ARCHIVE_SHA256', 'd9f33bcb16f478ceab44da4b185fb1fbadcab4f0f441f259c96a9805a854a28b'),
            ('MACHINE_DRIVER_BINARY_SHA256', '9d379214de116542cb0e2b1a09c17409fd59fd2b0109428896d81de9cf9c0d31'),
            ('PACKET_DRIVER_BINARY_SHA256', 'b3e5c71928fcebe1bb648f79ebbf38af9ad32d6f6dbb87587e1b92c6c331e100'),
        ):
            self.assertEqual(2, FILES[DOCKER].count('ARG ' + name + '=' + value))
            self.assertIn(name.lower() + '=${' + name + ':-' + value + '}', FILES[BUILD])
            self.assertIn('--build-arg "' + name + '=${' + name.lower() + '}"', FILES[BUILD])
        helper = (REPO / 'server/artifacts/verify-machine-driver-bundle.sh').read_text(encoding='utf-8')
        self.assertIn('LC_ALL=C sort "$listing" | cmp "$expected" -', helper)
        self.assertIn("if grep -Eq '^[^-]' \"$verbose\"; then", helper)
        self.assertIn('PACKET_DRIVER_NEW_INSTALL_DEFAULT=false', helper)
        self.assertIn('preserve-for-rollback', helper)
        self.assertIn('COPY --from=release_artifacts /out/machine-driver-bundle.tar.xz', FILES[DOCKER])
        self.assertIn('ENV DEFAULT_CATTLE_SERVICE_PACKAGE_DOCKER_MACHINE_URL=', FILES[DOCKER])
        self.assertNotIn("printf 'export DEFAULT_CATTLE_SERVICE_PACKAGE_DOCKER_MACHINE_URL=", FILES[DOCKER])
        self.assertNotRegex(FILES[DOCKER], r'(?m)^ENV CATTLE_SERVICE_PACKAGE_DOCKER_MACHINE_URL=')

    def test_current_readme_status_specific_prose_does_not_block_publication_transition(self):
        common = GATE.split('for current_readme_marker in ', 1)[1].split('; do', 1)[0]
        self.assertNotIn('candidate', common)
        self.assertNotIn('v1.6.546', common)
        self.assertIn("grep -Fqi 'keep all three named volumes' README.md", GATE)
        status = GATE.split("if grep -Fxq '## Current source candidate' README.md; then", 1)[1]
        candidate, published = status.split("elif grep -Fxq '## Current release' README.md; then", 1)
        published = published.split('else\n', 1)[0]
        self.assertIn('run them only after its official release', candidate)
        self.assertIn('This candidate is not yet available', candidate)
        self.assertIn('SERVER_CURRENT_PUBLISHED_README_MISSING', published)
        self.assertNotIn('candidate', published)
        self.assertNotIn('v1.6.546', published)


if __name__ == '__main__':
    unittest.main(verbosity=2)

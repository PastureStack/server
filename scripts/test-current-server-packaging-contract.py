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
FILES = {name: (REPO / name).read_text(encoding='utf-8') for name in (DOCKER, BUILD, VEX, VENDOR, COMPATIBILITY)}
PUBLISHED_508 = 'Server `v1.6.508` 已正式發布，封裝 Web Console `1.6.171`。'
STALE_508_CANDIDATE = 'Server `v1.6.508` candidate packages Web Console `1.6.171`'
COMPATIBILITY_CODE = 'SERVER_CREATE_RESPONSE_ORDER_COMPATIBILITY_MISSING'
WEB_SHA = 'db50f1f4f413ccbc6d9b2c3337e1979fb5ed4688f86978b885a48f30af342ad1'
WEB_SOURCE = '9f2869e08161db6550892039aea4ccf2c8a8016b'
CATALOG_COMMIT = 'b6b658888fce50d3ec217eb4eba0f26ab0113baf'
ENGINE_SHA = 'b0e3608b21ce405cdaf2f74699442b9420844384055f85acf88cfeb638600490'
ENGINE_SOURCE = '91f44685953f7cc72344a21cb47ca235c0bce53f'
OLD_COORDINATES = {
    'v1.6.519': 'v1.6.518',
    '1.6.181': '1.6.180',
    WEB_SHA: 'a367bd6907281298a8e2bf0f3ad0444083db06062f3a1521db573cc5606d274e',
    WEB_SOURCE: '637604b38401b19d2c9ef73d5729d356bb80c8e6',
    CATALOG_COMMIT: '7670ffd81d5f0b5570197fb03c7e55b46da45bf3',
}
# Engine334 version stays pinned; its verified-frame WAR/source are current.
# The previous518 Web180 values remain mutation controls.
# Component coordinates do not establish Server519 artifact/runtime PASS.
CATALOG_FIELDS = (
    ('VERSION', 'version', '0.20.13'),
    ('COMMIT', 'commit', '4c39c73a8131ba06e9ff0aaec3b95cc27e049324'),
    ('ARCHIVE_SHA256', 'archive_sha256', '29626181cb8489b016e5975ffaddc00b2a32d290b1c0066e833d27fa7a5edf83'),
    ('BINARY_SHA256', 'binary_sha256', '7224c76e5643130dee047e3f1888ce6845d024307bec74d72eebdc4baeae1aea'),
    ('SQLITE_BINARY_SHA256', 'sqlite_binary_sha256', '4aeda3e1ee1ca4c57f26938f3ef27651f9c8c129ee12957642960d22b95034ce'),
    ('LICENSE_SHA256', 'license_sha256', '0d542e0c8804e39aa7f37eb00da5a762149dc682d7829451287e11b938e94594'),
)
LEGACY_ENGINE_COORDINATES = {
    '0.183.334': '0.183.333',
    ENGINE_SHA: '8c42c0982cbc2f4569fa265ad320b341551758cb4fc0bc6d79ba06d70e20d328',
    ENGINE_SOURCE: '0d94f7d879d314235e582a7f4062914a27b82709',
}
EXPECTED = {
    COMPATIBILITY_CODE: (COMPATIBILITY, PUBLISHED_508),
    'SERVER_INCREMENTAL_RELEASE_DEFAULT_MISSING': (DOCKER, 'ARG SERVER_RELEASE_TAG=v1.6.519'),
    'SERVER_INCREMENTAL_RELEASE_VERSION_MISSING': (DOCKER, 'org.opencontainers.image.version="${SERVER_RELEASE_TAG}"'),
    'SERVER_INCREMENTAL_RELEASE_RUNTIME_VERSION_MISSING': (DOCKER, 'ENV CATTLE_RANCHER_SERVER_VERSION=${SERVER_RELEASE_TAG}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_VERSION_MISSING': (DOCKER, 'ARG WEB_CONSOLE_RELEASE_TAG=1.6.181'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_ARTIFACT_MISSING': (DOCKER, 'ARG WEB_CONSOLE_ARTIFACT=web-console-1.6.181.tar.gz'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_HASH_MISSING': (DOCKER, 'ARG WEB_CONSOLE_ARTIFACT_SHA256=' + WEB_SHA),
    'SERVER_INCREMENTAL_WEB_CONSOLE_COMMIT_MISSING': (DOCKER, 'ARG WEB_CONSOLE_COMMIT=' + WEB_SOURCE),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_COMMIT_MISSING': (BUILD, 'web_console_commit=${WEB_CONSOLE_COMMIT:-' + WEB_SOURCE + '}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_VERSION_MISSING': (BUILD, 'web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-1.6.181}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_ARTIFACT_MISSING': (BUILD, 'web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.181.tar.gz}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_HASH_MISSING': (BUILD, 'web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:-' + WEB_SHA + '}'),
    'SERVER_INCREMENTAL_RELEASE_BUILD_VERSION_MISSING': (BUILD, 'image=${IMAGE:-pasturestack-validation/server:v1.6.519}'),
    'SERVER_INCREMENTAL_RELEASE_BUILD_DEFAULT_MISSING': (BUILD, 'server_release_tag=${SERVER_RELEASE_TAG:-v1.6.519}'),
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
        'ARG ORCHESTRATION_ENGINE_RELEASE_TAG=v0.183.334',
        'ARG ORCHESTRATION_ENGINE_ARTIFACT=cattle.jar',
        'ARG ORCHESTRATION_ENGINE_ARTIFACT_SHA256=' + ENGINE_SHA,
        'ARG ORCHESTRATION_ENGINE_COMMIT=' + ENGINE_SOURCE,
        'ARG ORCHESTRATION_ENGINE_VERSION=0.183.334',
        'grep -Fx "Implementation-Version: ${ORCHESTRATION_ENGINE_VERSION}"',
        'cattle-resources-${ORCHESTRATION_ENGINE_VERSION}.jar',
        'cattle-app-config-${ORCHESTRATION_ENGINE_VERSION}.jar',
        'ENV CATTLE_CATTLE_VERSION=${ORCHESTRATION_ENGINE_RELEASE_TAG}',
    )),
    'SERVER_INCREMENTAL_ENGINE_BUILD_COORDINATE_MISSING': (BUILD, 'release_engine_build_marker', (
        'orchestration_engine_release_tag=${ORCHESTRATION_ENGINE_RELEASE_TAG:-v0.183.334}',
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
            "ARG HOST_PROVISIONER_VERSION=0.39.8",
            "ARG HOST_PROVISIONER_COMMIT=385e5b536c108f17fdfcdec84c01750a5be5ab1c",
            "ARG HOST_PROVISIONER_ARCHIVE_SHA256=d775f36a613b1a486a5e60d6ad61fdbd1ebb4bd22422cbb6dcb70fdd7c4abf0c",
            "ARG HOST_PROVISIONER_BINARY_SHA256=1d37e20a7a1cf4f3e36036a15ff7699ef22cd8809fd14a20892034dd054fd1fc",
            "ARG SECRET_DELIVERY_API_VERSION=0.3.2",
            "ARG SECRET_DELIVERY_API_COMMIT=53060369b29946b1f1b62e5fabbcfc8778c55bb6",
            "ARG SECRET_DELIVERY_API_ARCHIVE_SHA256=8a5e6da29db8f7b55ab3291b0270e843a5c15e67154fa075575d8b84f4bc0ae9",
            "ARG SECRET_DELIVERY_API_BINARY_SHA256=c263f61fd01423da30e06addc4385817fe683df42c299e53f27a812d8621e777",
            "ARG USAGE_TELEMETRY_AGENT_VERSION=0.4.2",
            "ARG USAGE_TELEMETRY_AGENT_COMMIT=40f9af7ca932fedacdb87e30b4ef1c60a4a7444e",
            "ARG USAGE_TELEMETRY_AGENT_ARCHIVE_SHA256=5ce031c84f76b3e62dafdb04fb4ed014aa1921e83be056c2d5dd712acbce25a8",
            "ARG USAGE_TELEMETRY_AGENT_BINARY_SHA256=e62a21270142181315293d7e11482288ffe8fc4d91cc8fe07dacc90b461f3709",
            "ARG COMPOSE_EXECUTOR_COMMIT=88e991e823f06d2334c07d5370595aae3c48ee99",
            "ARG COMPOSE_EXECUTOR_ARCHIVE_SHA256=5ff465601930218f531885a384f231d969033e4cef794ce33d16bfe24e5c1c81"
        ]
    ],
    [
        "incremental_producer_build_marker",
        "server/build-api-explorer-patch-image.sh",
        [
            "host_provisioner_version=${HOST_PROVISIONER_VERSION:-0.39.8}",
            "host_provisioner_commit=${HOST_PROVISIONER_COMMIT:-385e5b536c108f17fdfcdec84c01750a5be5ab1c}",
            "host_provisioner_archive_sha256=${HOST_PROVISIONER_ARCHIVE_SHA256:-d775f36a613b1a486a5e60d6ad61fdbd1ebb4bd22422cbb6dcb70fdd7c4abf0c}",
            "host_provisioner_binary_sha256=${HOST_PROVISIONER_BINARY_SHA256:-1d37e20a7a1cf4f3e36036a15ff7699ef22cd8809fd14a20892034dd054fd1fc}",
            "secret_delivery_api_version=${SECRET_DELIVERY_API_VERSION:-0.3.2}",
            "secret_delivery_api_commit=${SECRET_DELIVERY_API_COMMIT:-53060369b29946b1f1b62e5fabbcfc8778c55bb6}",
            "secret_delivery_api_archive_sha256=${SECRET_DELIVERY_API_ARCHIVE_SHA256:-8a5e6da29db8f7b55ab3291b0270e843a5c15e67154fa075575d8b84f4bc0ae9}",
            "secret_delivery_api_binary_sha256=${SECRET_DELIVERY_API_BINARY_SHA256:-c263f61fd01423da30e06addc4385817fe683df42c299e53f27a812d8621e777}",
            "usage_telemetry_agent_version=${USAGE_TELEMETRY_AGENT_VERSION:-0.4.2}",
            "usage_telemetry_agent_commit=${USAGE_TELEMETRY_AGENT_COMMIT:-40f9af7ca932fedacdb87e30b4ef1c60a4a7444e}",
            "usage_telemetry_agent_archive_sha256=${USAGE_TELEMETRY_AGENT_ARCHIVE_SHA256:-5ce031c84f76b3e62dafdb04fb4ed014aa1921e83be056c2d5dd712acbce25a8}",
            "usage_telemetry_agent_binary_sha256=${USAGE_TELEMETRY_AGENT_BINARY_SHA256:-e62a21270142181315293d7e11482288ffe8fc4d91cc8fe07dacc90b461f3709}",
            "compose_executor_version=${COMPOSE_EXECUTOR_VERSION:-0.14.37}",
            "compose_executor_commit=${COMPOSE_EXECUTOR_COMMIT:-88e991e823f06d2334c07d5370595aae3c48ee99}",
            "compose_executor_archive_sha256=${COMPOSE_EXECUTOR_ARCHIVE_SHA256:-5ff465601930218f531885a384f231d969033e4cef794ce33d16bfe24e5c1c81}",
            "compose_executor_binary_sha256=${COMPOSE_EXECUTOR_BINARY_SHA256:-a9bf9f0f77e914fe557d3e178a73c31526b0ca0adc4afbf17bf68d8d75c7ee27}"
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
            "grep -Fx 'Go compiler: 1.27.2' \"${license_dir}/SERVER-PRODUCER-SOURCES.txt\" >/dev/null;",
            "test -s \"${license_dir}/${component}-${suffix}\";",
            "test -s /usr/share/licenses/pasturestack/usage-telemetry-agent/usage-telemetry-agent-PRIVACY.md;"
        ]
    ],
    [
        "incremental_go_marker",
        "server/Dockerfile.web-compose-release",
        [
            "ARG ARTIFACT_HELPER_IMAGE=golang:1.27.2-bookworm@sha256:5cf287a799e6b94384bad13d16b14904c531f51ba65792237e122ce42b392f61",
            "test \"$(go version | awk '{print $3}')\" = go1.27.2;",
            "ENV PASTURESTACK_RUNTIME_GO_VERSION=1.27.2",
            "ENV PASTURESTACK_CONSOLE_BROKER_GO_VERSION=1.27.2",
            "ARG ENGINE_READONLY_SCHEMA_SHA256=7f274219e8dd9c6d750a408a6edec1448b564f4b16ba2204c425c5b45cec2233",
            "ARG ENGINE_RESTRICTED_SCHEMA_SHA256=f854ba99260f29e324ab7446a8592996946038920ac9bcf17689d98d1ebc5e51"
        ]
    ],
    [
        "incremental_go_build_marker",
        "server/build-api-explorer-patch-image.sh",
        [
            "PASTURESTACK_RUNTIME_GO_VERSION=1.27.2",
            "PASTURESTACK_CONSOLE_BROKER_GO_VERSION=1.27.2",
            "grep -aF \"go1.27.2\" \"${binary}\" >/dev/null",
            "runtime_go=1.27.2",
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
EXACT_COMPONENT_INPUTS = [
    "\"$orchestration_engine_artifact|$orchestration_engine_artifact_sha256\"",
    "\"$web_console_artifact|$web_console_artifact_sha256\"",
    "\"websocket-proxy-${websocket_proxy_version}-linux-amd64.tar.xz|$websocket_proxy_archive_sha256\"",
    "\"host-api-${host_api_version}.tar.gz|$host_api_archive_sha256\"",
    "\"node-agent-${node_agent_version}.tar.gz|$node_agent_archive_sha256\"",
    "\"host-provisioner-${host_provisioner_version}-linux-amd64.tar.xz|$host_provisioner_archive_sha256\"",
    "\"secret-delivery-api-${secret_delivery_api_version}-linux-amd64.tar.xz|$secret_delivery_api_archive_sha256\"",
    "\"usage-telemetry-agent-${usage_telemetry_agent_version}-linux-amd64.tar.xz|$usage_telemetry_agent_archive_sha256\"",
    "\"catalog-service-${catalog_service_version}.tar.xz|$catalog_service_archive_sha256\"",
    "\"catalog-service-${catalog_service_version}-LICENSE.txt|$catalog_service_license_sha256\"",
    "\"authentication-service-${authentication_service_version}-linux-amd64.tar.xz|$authentication_service_archive_sha256\"",
    "\"webhook-automation-service-${webhook_automation_service_version}-linux-amd64.tar.xz|$webhook_automation_service_archive_sha256\"",
    "\"compose-executor-${compose_executor_version}-linux-amd64.gz|$compose_executor_archive_sha256\"",
    "\"vsphere-cli-bundle-${vsphere_cli_bundle_version}-linux-amd64.tar.xz|$vsphere_cli_bundle_archive_sha256\""
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
    ]
]
RUNTIME_LEGAL = [
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
    "test \"$(find /out/runtime-bin -mindepth 1 -maxdepth 1 -type f | wc -l)\" -eq 10;",
    "test \"$(find /out/runtime-licenses -mindepth 1 -maxdepth 1 -type d | wc -l)\" -eq 6;",
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
    if actual != expected or len(re.findall(r'^FROM ', files[DOCKER], re.M)) != 5:
        raise AssertionError('CURRENT_RUNTIME_AGGREGATE_COPY_MISMATCH')


def verify_incremental_contract(files, gate=GATE):
    for variable, name, markers in INCREMENTAL_CONTRACTS:
        declared = engine_gate_markers(gate, variable)
        if declared != markers:
            raise AssertionError('CURRENT_INCREMENTAL_GATE_CONTRACT_MISMATCH')
        for marker in markers:
            if marker not in files[name]:
                raise AssertionError('CURRENT_INCREMENTAL_SOURCE_CONTRACT_MISMATCH')
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
    if 'and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.519"' not in gate:
        raise AssertionError('CURRENT_VEX_GATE_PIN_MISMATCH')
    if '"$vendor_pending_fixture" v1.6.519 >/dev/null' not in gate:
        raise AssertionError('CURRENT_VENDOR_GATE_PIN_MISMATCH')
    if json.loads(files[VEX]).get('@id') != 'https://github.com/PastureStack/server/security/openvex/v1.6.519':
        raise AssertionError('CURRENT_VEX_RELEASE_MISMATCH')
    if json.loads(files[VENDOR]).get('release') != 'v1.6.519':
        raise AssertionError('CURRENT_VENDOR_RELEASE_MISMATCH')
    if 'SERVER_API_EXPLORER_PATCH_OK release=v1.6.519 base=v1.6.460 engine=0.183.334 web_console=1.6.181 catalog_service=0.20.13 ' not in gate:
        raise AssertionError('CURRENT_SUMMARY_MISMATCH')
    verify_incremental_contract(files, gate)


def previous_gate(gate=GATE):
    # Only quoted current markers are changed; unrelated gates may evolve freely.
    replacements = {}
    for name, marker in EXPECTED.values():
        if name == COMPATIBILITY:
            continue  # Published508 history does not become a stale candidate.
        if stale(marker) != marker:
            replacements["'" + marker + "' "] = "'" + stale(marker) + "' "
    replacements.update({
        'and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.519"':
            'and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.518"',
        '"$vendor_pending_fixture" v1.6.519 >/dev/null':
            '"$vendor_pending_fixture" v1.6.518 >/dev/null',
        'SERVER_API_EXPLORER_PATCH_OK release=v1.6.519 base=v1.6.460 engine=0.183.334 web_console=1.6.181 catalog_service=0.20.13 ':
            'SERVER_API_EXPLORER_PATCH_OK release=v1.6.518 base=v1.6.460 engine=0.183.334 web_console=1.6.180 catalog_service=0.20.12 ',
    })
    for marker, stale_marker in replacements.items():
        if gate.count(marker) != 1:
            raise AssertionError('UNEXPECTED_CURRENT_MARKER_SHAPE')
        gate = gate.replace(marker, stale_marker)
    # Synthetic mutation leaves current engine pins; separate tests reject333.
    return gate


class Tests(unittest.TestCase):
    def test_runtime_aggregate_keeps_exact_ten_binaries_six_legal_dirs_and_two_copies(self):
        verify_runtime_layout(FILES)
        self.assertEqual(len(RUNTIME_BINARIES), 10)
        self.assertEqual(len(RUNTIME_LEGAL), 6)
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
            'test "$(find /out/runtime-bin -mindepth 1 -maxdepth 1 -type f | wc -l)" -eq 10;',
            'test "$(find /out/runtime-licenses -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 6;',
            'test -z "$(find /out/runtime-bin /out/runtime-licenses -type l -print -quit)"',
        ):
            for replacement in ('# ' + marker, marker.replace('0755', '0644').replace('-eq 10', '-eq 11').replace('-eq 6', '-eq 7'),
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
        "0.4.43",
        "cae736f377019bd9743648a8e9aa469a0e21b5e0",
        "e9218771af8dd68323c8c6fdab149c40a3ad02da9ff23f8aad6f0b2977740273",
        "fe11eec4b31b43863b49a582b1dbbe309eae08fb78adc150037981174f0622da"
    ],
    [
        "WEBSOCKET_PROXY",
        "websocket_proxy",
        "0.23.15",
        "1928f602b66443cdab40c8cdb450c811548d2749",
        "4657338973f672f6ae4d6e5510d06e811b9951afea1baa27a9caa3034e487f2a",
        "9111d5a569b6326d7cd71fc3384251d9684972492a22e1e9dbbb9863019fbaaa"
    ],
    [
        "WEBHOOK_AUTOMATION_SERVICE",
        "webhook_automation_service",
        "0.10.4",
        "400118b893843d2a7d7c65cc70c3449d76c4a8d8",
        "49c4579829a04e758045fae02a5a9fca12bb0ba3af0d5e979cf9eb97f23a88a9",
        "98c7faea665b7eb95206b8c73a6f47d644c5d2d0eae53f274f6a15faf5205744"
    ],
    [
        "COMPOSE_EXECUTOR",
        "compose_executor",
        "0.14.37",
        "88e991e823f06d2334c07d5370595aae3c48ee99",
        "5ff465601930218f531885a384f231d969033e4cef794ce33d16bfe24e5c1c81",
        "a9bf9f0f77e914fe557d3e178a73c31526b0ca0adc4afbf17bf68d8d75c7ee27"
    ],
    [
        "VSPHERE_CLI_BUNDLE",
        "vsphere_cli_bundle",
        "0.55.3",
        "f48ab9fd9990132c85845fc162186a04f1e0418d",
        "31be702e515741686e2c665d387562e5e993c5d2ffbdb2d614ed287243b166e4",
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
                    # Proxy version is unchanged and is already bound by its
                    # Docker/runtime version gate, not a duplicated build marker.
                    if not (upper == 'WEBSOCKET_PROXY' and field == 'VERSION'):
                        self.assertIn(build_marker, gate)
            self.assertIn('ARG GOVC_BINARY_SHA256=d3c4f4fab44403ec4110743b52da99f5ce3d7e3773c4661db8a87dec3ead8990', files[DOCKER])

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

    def test_active_incremental_go1272_does_not_rewrite_historical_base_go1270(self):
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
                    verify_incremental_contract(dict(FILES, **{name: FILES[name].replace('1.27.2', '1.27.0')}))

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
            ('HOST_PROVISIONER', '0.39.8', '1d37e20a7a1cf4f3e36036a15ff7699ef22cd8809fd14a20892034dd054fd1fc', '/usr/bin/host-provisioner.real'),
            ('SECRET_DELIVERY_API', '0.3.2', 'c263f61fd01423da30e06addc4385817fe683df42c299e53f27a812d8621e777', '/usr/bin/secret-delivery-api'),
            ('USAGE_TELEMETRY_AGENT', '0.4.2', 'e62a21270142181315293d7e11482288ffe8fc4d91cc8fe07dacc90b461f3709', '/usr/bin/usage-telemetry-agent'),
        ):
            self.assertIn(digest + '  ' + binary, FILES[BUILD])
            self.assertIn('PASTURESTACK_' + upper + '_VERSION="' + '$' + '{' + upper.lower() + '_version}"', FILES[BUILD])

    def test_original_fourteen_component_inputs_keep_exact_sha_fetch_and_five_stages(self):
        verify_incremental_contract(FILES)
        block = FILES[BUILD].split('    component_assets=(\n', 1)[1].split('    )', 1)[0]
        self.assertEqual([line.strip() for line in block.splitlines()], EXACT_COMPONENT_INPUTS)
        self.assertEqual(len(EXACT_COMPONENT_INPUTS), 14)
        self.assertEqual(len(re.findall(r'^FROM ', FILES[DOCKER], re.M)), 5)
        self.assertIn('FROM scratch AS component_input', FILES[DOCKER])
        self.assertEqual(len(re.findall(r'^\s+fetch-server-component ', FILES[DOCKER], re.M)), 12)
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
            'test "$(printf \'%s\\n\' "$metadata" | awk \'NR==1 {print $2}\')" = go1.27.2',
            "'CGO_ENABLED=0' 'GOOS=linux' 'GOARCH=amd64' 'GOAMD64=v1'",
            'test ! -s "$duplicates"',
            "! grep -Eq '^[lh]' \"$verbose\"",
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
            self.assertEqual(len(re.findall(r'^FROM ', files[DOCKER], re.M)), 5)
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
            expected_valid = resolved if variable.endswith('artifact_sha256') else True
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
        self.assertEqual(len(re.findall(r'^FROM ', FILES[DOCKER], re.M)), 5)
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
            ('COMMIT', '1928f602b66443cdab40c8cdb450c811548d2749'),
            ('ARCHIVE_SHA256', '4657338973f672f6ae4d6e5510d06e811b9951afea1baa27a9caa3034e487f2a'),
            ('BINARY_SHA256', '9111d5a569b6326d7cd71fc3384251d9684972492a22e1e9dbbb9863019fbaaa'),
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
            ('VSPHERE_CLI_BUNDLE_VERSION', 'vsphere_cli_bundle_version', '0.55.3'),
            ('VSPHERE_CLI_BUNDLE_COMMIT', 'vsphere_cli_bundle_commit', 'f48ab9fd9990132c85845fc162186a04f1e0418d'),
            ('VSPHERE_CLI_BUNDLE_ARCHIVE_SHA256', 'vsphere_cli_bundle_archive_sha256', '31be702e515741686e2c665d387562e5e993c5d2ffbdb2d614ed287243b166e4'),
            ('GOVC_BINARY_SHA256', 'govc_binary_sha256', 'd3c4f4fab44403ec4110743b52da99f5ce3d7e3773c4661db8a87dec3ead8990'),
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
        for marker in ('## Current release', '## Quick start', '## Upgrade and rollback',
                       '[upgrade guide](docs/upgrades/README.md)',
                       'Do not replace existing volumes with new empty ones or run `docker compose down -v`.',
                       'rollback may require restoring matching data', '[release notes](docs/releases)'):
            self.assertIn(marker, markers)
        readme = (REPO / 'README.md').read_text(encoding='utf-8')
        for marker in markers:
            self.assertIn(marker, readme)


if __name__ == '__main__':
    unittest.main(verbosity=2)

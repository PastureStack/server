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
FILES = {name: (REPO / name).read_text(encoding='utf-8') for name in (DOCKER, BUILD, VEX, VENDOR)}
WEB_SHA = '900974b07bb20ba5b2e7c1dede7012a53c6e2c96cd094c67cb7019434c4f27c9'
WEB_SOURCE = '09df1480c5f4b58c6a9a9060ff94d980792f7015'
ENGINE_SHA = '31090699e214f8e357f7fe413ce307e722b9b53177003e5de0bbbca1bc7bc3f5'
ENGINE_SOURCE = '7a625eee58fb2bdba83d2f008bdf7dd3c0ae4295'
OLD_COORDINATES = {
    'v1.6.507': 'v1.6.506',
    '1.6.170': '1.6.169',
    WEB_SHA: 'e2bcb97b0da810f2ff216f9738739235e3c6f29ef46f1d99b623cf9c9f7258e2',
    WEB_SOURCE: '5962f57fccb4062a65b5921646c06b4663713b9b',
}
# Previous Server506 keeps Engine332; legacy Engine331 is a separate negative.
LEGACY_ENGINE_COORDINATES = {
    '0.183.332': '0.183.331',
    ENGINE_SHA: '0c8310d9e9a872589972658d2fd8cb88f59f473ab8072a4746df5b0f4ef9e70e',
    ENGINE_SOURCE: '515a5d37a1194f827bc3ffde34db729905ecb2b1',
}
EXPECTED = {
    'SERVER_INCREMENTAL_RELEASE_VERSION_MISSING': (DOCKER, 'org.opencontainers.image.version="v1.6.507"'),
    'SERVER_INCREMENTAL_RELEASE_RUNTIME_VERSION_MISSING': (DOCKER, 'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.507'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_VERSION_MISSING': (DOCKER, 'ARG WEB_CONSOLE_RELEASE_TAG=1.6.170'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_ARTIFACT_MISSING': (DOCKER, 'ARG WEB_CONSOLE_ARTIFACT=web-console-1.6.170.tar.gz'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_HASH_MISSING': (DOCKER, 'ARG WEB_CONSOLE_ARTIFACT_SHA256=' + WEB_SHA),
    'SERVER_INCREMENTAL_WEB_CONSOLE_COMMIT_MISSING': (DOCKER, 'ARG WEB_CONSOLE_COMMIT=' + WEB_SOURCE),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_COMMIT_MISSING': (BUILD, 'web_console_commit=${WEB_CONSOLE_COMMIT:-' + WEB_SOURCE + '}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_VERSION_MISSING': (BUILD, 'web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-1.6.170}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_ARTIFACT_MISSING': (BUILD, 'web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.170.tar.gz}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_HASH_MISSING': (BUILD, 'web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:-' + WEB_SHA + '}'),
    'SERVER_INCREMENTAL_RELEASE_BUILD_VERSION_MISSING': (BUILD, 'image=${IMAGE:-pasturestack-validation/server:v1.6.507}'),
    'SERVER_INCREMENTAL_RELEASE_BUILD_RUNTIME_VERSION_MISSING': (BUILD, 'CATTLE_RANCHER_SERVER_VERSION=v1.6.507'),
    'SERVER_WEB_CONSOLE_RUNTIME_VERSION_GATE_MISSING': (BUILD, 'test "$(cat "${web_root}/VERSION.txt")" = "1.6.170"'),
    'SERVER_VOLUME_NATIVE_READ_ONLY_BUILD_GATE_MISSING': (DOCKER, 'grep -F \'"volume.isNative" : "r"\' >/dev/null'),
    'SERVER_VOLUME_NATIVE_READ_ONLY_RUNTIME_GATE_MISSING': (BUILD, r'grep -F "\"volume.isNative\" : \"r\"" >/dev/null'),
}
ENGINE_EXPECTED = {
    'SERVER_INCREMENTAL_ENGINE_REPLACEMENT_MISSING': (DOCKER, 'release_engine_marker', (
        'ARG ORCHESTRATION_ENGINE_RELEASE_TAG=v0.183.332',
        'ARG ORCHESTRATION_ENGINE_ARTIFACT=cattle.jar',
        'ARG ORCHESTRATION_ENGINE_ARTIFACT_SHA256=' + ENGINE_SHA,
        'ARG ORCHESTRATION_ENGINE_COMMIT=' + ENGINE_SOURCE,
        "grep -Fx 'Implementation-Version: 0.183.332'",
        'cattle-resources-0.183.332.jar',
        'cattle-app-config-0.183.332.jar',
        'ENV CATTLE_CATTLE_VERSION=v0.183.332',
    )),
    'SERVER_INCREMENTAL_ENGINE_BUILD_COORDINATE_MISSING': (BUILD, 'release_engine_build_marker', (
        'orchestration_engine_release_tag=${ORCHESTRATION_ENGINE_RELEASE_TAG:-v0.183.332}',
        'orchestration_engine_artifact=${ORCHESTRATION_ENGINE_ARTIFACT:-cattle.jar}',
        'orchestration_engine_artifact_sha256=${ORCHESTRATION_ENGINE_ARTIFACT_SHA256:-' + ENGINE_SHA + '}',
        'orchestration_engine_commit=${ORCHESTRATION_ENGINE_COMMIT:-' + ENGINE_SOURCE + '}',
        'CATTLE_CATTLE_VERSION=v0.183.332',
        'cattle-resources-0.183.332.jar',
    )),
}


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
    values = normalized.split(header, 1)[1].split('; do', 1)[0]
    markers = shlex.split(values)
    if len(markers) != len(set(markers)):
        raise AssertionError('CURRENT_ENGINE_GATE_DUPLICATE')
    return markers


def verify(files, gate=GATE):
    # Extract the actual single-quoted require_marker calls. Membership has the
    # same fixed-string semantics as the unchanged gate's grep -Fq -- invocation.
    paths = {'$release_dockerfile': DOCKER, '$build_script': BUILD}
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
    if 'and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.507"' not in gate:
        raise AssertionError('CURRENT_VEX_GATE_PIN_MISMATCH')
    if '"$vendor_pending_fixture" v1.6.507 >/dev/null' not in gate:
        raise AssertionError('CURRENT_VENDOR_GATE_PIN_MISMATCH')
    if json.loads(files[VEX]).get('@id') != 'https://github.com/PastureStack/server/security/openvex/v1.6.507':
        raise AssertionError('CURRENT_VEX_RELEASE_MISMATCH')
    if json.loads(files[VENDOR]).get('release') != 'v1.6.507':
        raise AssertionError('CURRENT_VENDOR_RELEASE_MISMATCH')
    if 'SERVER_API_EXPLORER_PATCH_OK release=v1.6.507 base=v1.6.460 engine=0.183.332 web_console=1.6.170 ' not in gate:
        raise AssertionError('CURRENT_SUMMARY_MISMATCH')


def previous_gate(gate=GATE):
    # Only quoted current markers are changed; unrelated gates may evolve freely.
    replacements = {}
    for _, marker in EXPECTED.values():
        if stale(marker) != marker:
            replacements["'" + marker + "' "] = "'" + stale(marker) + "' "
    replacements.update({
        'and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.507"':
            'and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.506"',
        '"$vendor_pending_fixture" v1.6.507 >/dev/null':
            '"$vendor_pending_fixture" v1.6.506 >/dev/null',
        'SERVER_API_EXPLORER_PATCH_OK release=v1.6.507 base=v1.6.460 engine=0.183.332 web_console=1.6.170 ':
            'SERVER_API_EXPLORER_PATCH_OK release=v1.6.506 base=v1.6.460 engine=0.183.332 web_console=1.6.169 ',
    })
    for marker, stale_marker in replacements.items():
        if gate.count(marker) != 1:
            raise AssertionError('UNEXPECTED_CURRENT_MARKER_SHAPE')
        gate = gate.replace(marker, stale_marker)
    # Previous Server506 uses the same Engine332 source and WAR.
    return gate


class Tests(unittest.TestCase):
    def test_actual_current_gate_and_four_files_agree(self):
        verify(FILES)

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

    def test_previous_fixture_rejects_stale_web169_pins(self):
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

    def test_old_vex_or_vendor_release_rejected(self):
        for name, key, value in ((VEX, '@id', 'https://github.com/PastureStack/server/security/openvex/v1.6.506'),
                                 (VENDOR, 'release', 'v1.6.506')):
            with self.subTest(name=name):
                files = dict(FILES)
                data = json.loads(files[name])
                data[key] = value
                files[name] = json.dumps(data)
                with self.assertRaisesRegex(AssertionError, 'CURRENT_.*_RELEASE_MISMATCH'):
                    verify(files)

    def test_previous_pin_fixture_keeps_four_historical_markers(self):
        for marker in (
            "require_marker docs/releases/server-1.6.501.md '# Server v1.6.501'",
            "require_marker docs/releases/server-1.6.501.md 'No migration or runtime patch is required.'",
            "require_marker README.md '## v1.6.501' SERVER_HOST_NAME_LAYOUT_README_MISSING",
            "require_marker COMPATIBILITY.md 'Server `v1.6.501` packages Web Console `1.6.165`'",
        ):
            self.assertIn(marker, GATE)
            self.assertIn(marker, previous_gate())


if __name__ == '__main__':
    unittest.main(verbosity=2)

"""Focused source-only checks; no full gate, build, registry or runtime execution."""
import json
import pathlib
import shlex
import unittest


REPO = pathlib.Path(__file__).resolve().parents[1]
GATE = (REPO / 'scripts/check-server-api-explorer-patch.sh').read_text(encoding='utf-8')
DOCKER = 'server/Dockerfile.web-compose-release'
BUILD = 'server/build-api-explorer-patch-image.sh'
VEX = 'server/security/openvex.json'
VENDOR = 'server/security/vendor-pending.json'
FILES = {name: (REPO / name).read_text(encoding='utf-8') for name in (DOCKER, BUILD, VEX, VENDOR)}
WEB_SHA = 'fdd1d33d47b032eef8b5b6d5dbb1401110daf860d84a6c17003577463d3d2cb5'
WEB_SOURCE = '2120e0416fd4a0efb5d351f9da4ec632ac8eacdc'
OLD_COORDINATES = {
    'v1.6.504': 'v1.6.503',
    '1.6.168': '1.6.167',
    WEB_SHA: 'e8e714fc06282de75a3570aac1d4d4d04a3c9478d982d0d5aaeae14efa8ebbaf',
    WEB_SOURCE: 'dff35fc4bce340e21cac7204146a7bcb20a7b60b',
}
EXPECTED = {
    'SERVER_INCREMENTAL_RELEASE_VERSION_MISSING': (DOCKER, 'org.opencontainers.image.version="v1.6.504"'),
    'SERVER_INCREMENTAL_RELEASE_RUNTIME_VERSION_MISSING': (DOCKER, 'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.504'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_VERSION_MISSING': (DOCKER, 'ARG WEB_CONSOLE_RELEASE_TAG=1.6.168'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_ARTIFACT_MISSING': (DOCKER, 'ARG WEB_CONSOLE_ARTIFACT=web-console-1.6.168.tar.gz'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_HASH_MISSING': (DOCKER, 'ARG WEB_CONSOLE_ARTIFACT_SHA256=' + WEB_SHA),
    'SERVER_INCREMENTAL_WEB_CONSOLE_COMMIT_MISSING': (DOCKER, 'ARG WEB_CONSOLE_COMMIT=' + WEB_SOURCE),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_COMMIT_MISSING': (BUILD, 'web_console_commit=${WEB_CONSOLE_COMMIT:-' + WEB_SOURCE + '}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_VERSION_MISSING': (BUILD, 'web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-1.6.168}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_ARTIFACT_MISSING': (BUILD, 'web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.168.tar.gz}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_HASH_MISSING': (BUILD, 'web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:-' + WEB_SHA + '}'),
    'SERVER_INCREMENTAL_RELEASE_BUILD_VERSION_MISSING': (BUILD, 'image=${IMAGE:-pasturestack-validation/server:v1.6.504}'),
    'SERVER_INCREMENTAL_RELEASE_BUILD_RUNTIME_VERSION_MISSING': (BUILD, 'CATTLE_RANCHER_SERVER_VERSION=v1.6.504'),
    'SERVER_WEB_CONSOLE_RUNTIME_VERSION_GATE_MISSING': (BUILD, 'test "$(cat "${web_root}/VERSION.txt")" = "1.6.168"'),
}


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
    if 'and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.504"' not in gate:
        raise AssertionError('CURRENT_VEX_GATE_PIN_MISMATCH')
    if '"$vendor_pending_fixture" v1.6.504 >/dev/null' not in gate:
        raise AssertionError('CURRENT_VENDOR_GATE_PIN_MISMATCH')
    if json.loads(files[VEX]).get('@id') != 'https://github.com/PastureStack/server/security/openvex/v1.6.504':
        raise AssertionError('CURRENT_VEX_RELEASE_MISMATCH')
    if json.loads(files[VENDOR]).get('release') != 'v1.6.504':
        raise AssertionError('CURRENT_VENDOR_RELEASE_MISMATCH')
    if 'SERVER_API_EXPLORER_PATCH_OK release=v1.6.504 base=v1.6.460 engine=0.183.331 web_console=1.6.168 ' not in gate:
        raise AssertionError('CURRENT_SUMMARY_MISMATCH')


def previous_gate(gate=GATE):
    # Only quoted current markers are changed; unrelated gates may evolve freely.
    replacements = {}
    for _, marker in EXPECTED.values():
        stale_marker = marker
        for coordinate, old in OLD_COORDINATES.items():
            stale_marker = stale_marker.replace(coordinate, old)
        replacements["'" + marker + "' "] = "'" + stale_marker + "' "
    replacements.update({
        'and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.504"':
            'and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.503"',
        '"$vendor_pending_fixture" v1.6.504 >/dev/null':
            '"$vendor_pending_fixture" v1.6.503 >/dev/null',
        'SERVER_API_EXPLORER_PATCH_OK release=v1.6.504 base=v1.6.460 engine=0.183.331 web_console=1.6.168 ':
            'SERVER_API_EXPLORER_PATCH_OK release=v1.6.503 base=v1.6.460 engine=0.183.331 web_console=1.6.167 ',
    })
    for marker, stale_marker in replacements.items():
        if gate.count(marker) != 1:
            raise AssertionError('UNEXPECTED_CURRENT_MARKER_SHAPE')
        gate = gate.replace(marker, stale_marker)
    return gate


class Tests(unittest.TestCase):
    def test_actual_current_gate_and_four_files_agree(self):
        verify(FILES)

    def test_previous_gate_and_each_old_component_pin_rejected(self):
        with self.assertRaisesRegex(AssertionError, 'CURRENT_GATE_PIN_MISMATCH'):
            verify(FILES, previous_gate())
        for code, (name, marker) in EXPECTED.items():
            with self.subTest(code=code):
                stale_marker = marker
                for coordinate, old in OLD_COORDINATES.items():
                    stale_marker = stale_marker.replace(coordinate, old)
                self.assertNotEqual(marker, stale_marker)
                files = dict(FILES)
                files[name] = files[name].replace(marker, stale_marker)
                with self.assertRaisesRegex(AssertionError, code):
                    verify(files)

    def test_old_vex_or_vendor_release_rejected(self):
        for name, key, value in ((VEX, '@id', 'https://github.com/PastureStack/server/security/openvex/v1.6.503'),
                                 (VENDOR, 'release', 'v1.6.503')):
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

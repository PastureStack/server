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
WEB_SHA = 'a367bd6907281298a8e2bf0f3ad0444083db06062f3a1521db573cc5606d274e'
WEB_SOURCE = '637604b38401b19d2c9ef73d5729d356bb80c8e6'
CATALOG_COMMIT = 'b6b658888fce50d3ec217eb4eba0f26ab0113baf'
ENGINE_SHA = '8c42c0982cbc2f4569fa265ad320b341551758cb4fc0bc6d79ba06d70e20d328'
ENGINE_SOURCE = '0d94f7d879d314235e582a7f4062914a27b82709'
OLD_COORDINATES = {
    'v1.6.518': 'v1.6.517',
    '1.6.180': '1.6.179',
    WEB_SHA: '1bb7e0acf7040738f2c6413046553609cbbaf14b833abb6ef2c7237b453eaf90',
    WEB_SOURCE: '826bff55b8885efc9ff1faec0272ef442e4ff702',
    CATALOG_COMMIT: '7670ffd81d5f0b5570197fb03c7e55b46da45bf3',
}
# Engine333 stays pinned. The stale517 Web179 values are mutation controls.
# Published component coordinates do not establish Server518 artifact/runtime PASS.
CATALOG_FIELDS = (
    ('VERSION', 'version', '0.20.12'),
    ('COMMIT', 'commit', 'd708579092eae0fd03b2750ac594ff0396cf563b'),
    ('ARCHIVE_SHA256', 'archive_sha256', '34b76c121270c603501664f7146d41916c7f45da983e326861ed4c5b9614372d'),
    ('BINARY_SHA256', 'binary_sha256', '3deb43f9760d7cbb07f818dd108ab35abf9efc6908d5d7fcaf5c44a185f2fba9'),
    ('SQLITE_BINARY_SHA256', 'sqlite_binary_sha256', '8805af3c0b5968a02f994d65de715c525b73637aa2dc398a0648feeeaf2fd397'),
    ('LICENSE_SHA256', 'license_sha256', '0d542e0c8804e39aa7f37eb00da5a762149dc682d7829451287e11b938e94594'),
)
LEGACY_ENGINE_COORDINATES = {
    '0.183.333': '0.183.332',
    ENGINE_SHA: '31090699e214f8e357f7fe413ce307e722b9b53177003e5de0bbbca1bc7bc3f5',
    ENGINE_SOURCE: '7a625eee58fb2bdba83d2f008bdf7dd3c0ae4295',
}
EXPECTED = {
    COMPATIBILITY_CODE: (COMPATIBILITY, PUBLISHED_508),
    'SERVER_INCREMENTAL_RELEASE_VERSION_MISSING': (DOCKER, 'org.opencontainers.image.version="v1.6.518"'),
    'SERVER_INCREMENTAL_RELEASE_RUNTIME_VERSION_MISSING': (DOCKER, 'ENV CATTLE_RANCHER_SERVER_VERSION=v1.6.518'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_VERSION_MISSING': (DOCKER, 'ARG WEB_CONSOLE_RELEASE_TAG=1.6.180'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_ARTIFACT_MISSING': (DOCKER, 'ARG WEB_CONSOLE_ARTIFACT=web-console-1.6.180.tar.gz'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_HASH_MISSING': (DOCKER, 'ARG WEB_CONSOLE_ARTIFACT_SHA256=' + WEB_SHA),
    'SERVER_INCREMENTAL_WEB_CONSOLE_COMMIT_MISSING': (DOCKER, 'ARG WEB_CONSOLE_COMMIT=' + WEB_SOURCE),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_COMMIT_MISSING': (BUILD, 'web_console_commit=${WEB_CONSOLE_COMMIT:-' + WEB_SOURCE + '}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_VERSION_MISSING': (BUILD, 'web_console_release_tag=${WEB_CONSOLE_RELEASE_TAG:-1.6.180}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_ARTIFACT_MISSING': (BUILD, 'web_console_artifact=${WEB_CONSOLE_ARTIFACT:-web-console-1.6.180.tar.gz}'),
    'SERVER_INCREMENTAL_WEB_CONSOLE_BUILD_HASH_MISSING': (BUILD, 'web_console_artifact_sha256=${WEB_CONSOLE_ARTIFACT_SHA256:-' + WEB_SHA + '}'),
    'SERVER_INCREMENTAL_RELEASE_BUILD_VERSION_MISSING': (BUILD, 'image=${IMAGE:-pasturestack-validation/server:v1.6.518}'),
    'SERVER_INCREMENTAL_RELEASE_BUILD_RUNTIME_VERSION_MISSING': (BUILD, 'CATTLE_RANCHER_SERVER_VERSION=v1.6.518'),
    'SERVER_WEB_CONSOLE_RUNTIME_VERSION_GATE_MISSING': (BUILD, 'test "$(cat "${web_root}/VERSION.txt")" = "1.6.180"'),
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
        'ARG ORCHESTRATION_ENGINE_RELEASE_TAG=v0.183.333',
        'ARG ORCHESTRATION_ENGINE_ARTIFACT=cattle.jar',
        'ARG ORCHESTRATION_ENGINE_ARTIFACT_SHA256=' + ENGINE_SHA,
        'ARG ORCHESTRATION_ENGINE_COMMIT=' + ENGINE_SOURCE,
        "grep -Fx 'Implementation-Version: 0.183.333'",
        'cattle-resources-0.183.333.jar',
        'cattle-app-config-0.183.333.jar',
        'ENV CATTLE_CATTLE_VERSION=v0.183.333',
    )),
    'SERVER_INCREMENTAL_ENGINE_BUILD_COORDINATE_MISSING': (BUILD, 'release_engine_build_marker', (
        'orchestration_engine_release_tag=${ORCHESTRATION_ENGINE_RELEASE_TAG:-v0.183.333}',
        'orchestration_engine_artifact=${ORCHESTRATION_ENGINE_ARTIFACT:-cattle.jar}',
        'orchestration_engine_artifact_sha256=${ORCHESTRATION_ENGINE_ARTIFACT_SHA256:-' + ENGINE_SHA + '}',
        'orchestration_engine_commit=${ORCHESTRATION_ENGINE_COMMIT:-' + ENGINE_SOURCE + '}',
        'CATTLE_CATTLE_VERSION=v0.183.333',
        'cattle-resources-0.183.333.jar',
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
    values = normalized.split(header, 1)[1].split('; do\n', 1)[0]
    markers = shlex.split(values)
    if len(markers) != len(set(markers)):
        raise AssertionError('CURRENT_ENGINE_GATE_DUPLICATE')
    return markers


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
    if 'and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.518"' not in gate:
        raise AssertionError('CURRENT_VEX_GATE_PIN_MISMATCH')
    if '"$vendor_pending_fixture" v1.6.518 >/dev/null' not in gate:
        raise AssertionError('CURRENT_VENDOR_GATE_PIN_MISMATCH')
    if json.loads(files[VEX]).get('@id') != 'https://github.com/PastureStack/server/security/openvex/v1.6.518':
        raise AssertionError('CURRENT_VEX_RELEASE_MISMATCH')
    if json.loads(files[VENDOR]).get('release') != 'v1.6.518':
        raise AssertionError('CURRENT_VENDOR_RELEASE_MISMATCH')
    if 'SERVER_API_EXPLORER_PATCH_OK release=v1.6.518 base=v1.6.460 engine=0.183.333 web_console=1.6.180 catalog_service=0.20.12 ' not in gate:
        raise AssertionError('CURRENT_SUMMARY_MISMATCH')


def previous_gate(gate=GATE):
    # Only quoted current markers are changed; unrelated gates may evolve freely.
    replacements = {}
    for name, marker in EXPECTED.values():
        if name == COMPATIBILITY:
            continue  # Published508 history does not become a stale candidate.
        if stale(marker) != marker:
            replacements["'" + marker + "' "] = "'" + stale(marker) + "' "
    replacements.update({
        'and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.518"':
            'and .["@id"] == "https://github.com/PastureStack/server/security/openvex/v1.6.517"',
        '"$vendor_pending_fixture" v1.6.518 >/dev/null':
            '"$vendor_pending_fixture" v1.6.517 >/dev/null',
        'SERVER_API_EXPLORER_PATCH_OK release=v1.6.518 base=v1.6.460 engine=0.183.333 web_console=1.6.180 catalog_service=0.20.12 ':
            'SERVER_API_EXPLORER_PATCH_OK release=v1.6.517 base=v1.6.460 engine=0.183.333 web_console=1.6.179 catalog_service=0.20.12 ',
    })
    for marker, stale_marker in replacements.items():
        if gate.count(marker) != 1:
            raise AssertionError('UNEXPECTED_CURRENT_MARKER_SHAPE')
        gate = gate.replace(marker, stale_marker)
    # Synthetic mutation leaves current engine pins; separate tests reject332.
    return gate


class Tests(unittest.TestCase):
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
            self.assertEqual(len(re.findall(r'^FROM ', files[DOCKER], re.M)), 4)
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
        self.assertLess(FILES[DOCKER].index(artifact_guard), FILES[DOCKER].index('curl -fsSL --retry 5'))

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
        self.assertEqual(len(re.findall(r'^FROM ', FILES[DOCKER], re.M)), 4)
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

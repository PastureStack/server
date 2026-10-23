"""Exercise the production Bash identity readback without Docker or a build."""
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
BUILD = (ROOT / 'server/build-api-explorer-patch-image.sh').read_text()
CURRENT_COMMIT = 'a586f0dc0aa50df579049a8d4bf26f04400fdf75'
START = BUILD.index('docker run --rm --env "ORCHESTRATION_ENGINE_VERSION=')
HEADER, BLOCK = BUILD[START:].split("-lc '\n", 1)
LINES = BLOCK.splitlines()
OPTIONS = next(line.strip() for line in LINES if line.strip().startswith('set -'))
TRAP = next(line.strip() for line in LINES if line.strip().startswith('trap '))
IDENTITY = [line.strip() for line in LINES
            if 'grep -F ' in line and '"${api_dir}/version.json"' in line]


def run_identity(metadata, commit=CURRENT_COMMIT, tag='v1.1.20', missing=()):
    """Use the actual production grep/trap lines against temporary JSON bytes."""
    with tempfile.TemporaryDirectory() as temp:
        (Path(temp) / 'version.json').write_bytes(metadata)
        env = {name: value for name, value in os.environ.items()
               if name not in ('API_EXPLORER_COMMIT', 'API_EXPLORER_RELEASE_TAG')}
        env.update(API_EXPLORER_COMMIT=commit, API_EXPLORER_RELEASE_TAG=tag,
                   CONTRACT_TEST_SECRET='do-not-print-contract-sentinel-7f906e')
        for name in missing:
            env.pop(name)
        script = '\n'.join([OPTIONS, TRAP, 'api_dir=$1', *IDENTITY]) + '\n'
        return subprocess.run(['bash', '-c', script, 'contract-readback', temp],
                              env=env, capture_output=True, text=True, timeout=10)


def identity(version='1.1.20', commit='a586f0d'):
    return (json.dumps({'version': version, 'commit': commit}, indent=2) + '\n').encode()


def run_guard(name, argument, package_state='absent'):
    match = re.search(r'(?m)^    ' + re.escape(name) + r'\(\)\n    \{\n.*?^    \}',
                      BLOCK, re.S)
    if not match:
        raise AssertionError('Missing production guard: ' + name)
    # Stub only package inventory; execute the original guard as a standalone
    # command under production errexit/trap semantics, never inside if or !.
    script = '\n'.join([
        OPTIONS, TRAP,
        'package_is_installed() { test "$PACKAGE_TEST_STATE" = installed; }',
        match.group(0),
        name + ' "$1"',
        'printf "GUARD_SENTINEL_REACHED\\n"',
    ]) + '\n'
    return subprocess.run(['bash', '-c', script, 'guard-readback', argument],
                          env=dict(os.environ, PACKAGE_TEST_STATE=package_state),
                          capture_output=True, text=True, timeout=10)


def run_zlib_guard(old_library=False, wrong_link=False, verify_output='', verify_status=0,
                   version='1.3.1', package_version='1:1.3.dfsg+really1.3.1-1ubuntu3.2'):
    start = BLOCK.index('    test "$(dpkg-query -W ', BLOCK.index('    cmp /tmp/uniq-expected'))
    end = BLOCK.index('    ldd /usr/sbin/mariadbd', start)
    # Decode the outer shell's single-quote escape, leaving the inner Bash
    # commands unchanged. Only the fixed library prefix is relocated.
    guard = BLOCK[start:end].replace("'\"'\"'", "'")
    with tempfile.TemporaryDirectory() as temp:
        directory = Path(temp)
        (directory / 'libz.so.1.3.1').write_bytes(b'fixture, not a native ELF')
        target = 'libz.so.wrong' if wrong_link else 'libz.so.1.3.1'
        if wrong_link:
            (directory / target).write_bytes(b'wrong fixture')
        (directory / 'libz.so.1').symlink_to(target)
        if old_library:
            (directory / 'libz.so.1.3.2').write_bytes(b'old fixture')
        guard = guard.replace('/usr/lib/x86_64-linux-gnu', temp)
        env = dict(os.environ, PASTURESTACK_ZLIB_VERSION=version,
                   PASTURESTACK_ZLIB_PACKAGE_VERSION=package_version,
                   ZLIB_TEST_VERIFY_OUTPUT=verify_output,
                   ZLIB_TEST_VERIFY_STATUS=str(verify_status))
        # Query/verification are controlled substitutes. Real deb hashes and
        # native linkage are validated separately, not claimed by this test.
        query = r'''dpkg-query() {
    test "$#" -eq 3
    test "$1" = -W
    test "$2" = '-f=${Version}'
    test "$3" = zlib1g
    printf '%s' '1:1.3.dfsg+really1.3.1-1ubuntu3.2'
}'''
        verify = r'''dpkg() {
    test "$#" -eq 2
    test "$1" = --verify
    test "$2" = zlib1g
    printf '%s' "$ZLIB_TEST_VERIFY_OUTPUT"
    return "$ZLIB_TEST_VERIFY_STATUS"
}'''
        script = '\n'.join([OPTIONS, TRAP, query, verify, guard,
                            'printf "ZLIB_SENTINEL_REACHED\\n"'])
        return subprocess.run(['bash', '-c', script, 'zlib-readback'], env=env,
                              capture_output=True, text=True, timeout=10)


class RuntimeContractReadback(unittest.TestCase):
    def test_current_formal_identity(self):
        result = run_identity(identity())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout + result.stderr, '')

    def test_other_matching_commit_and_version_are_not_hardcoded(self):
        result = run_identity(identity('1.1.21', '0123456'),
                              commit='0123456789abcdef0123456789abcdef01234567', tag='v1.1.21')
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_stale_version_is_rejected(self):
        self.assertNotEqual(run_identity(identity('1.1.19')).returncode, 0)

    def test_stale_commit_is_rejected(self):
        self.assertNotEqual(run_identity(identity(commit='dda3fe8')).returncode, 0)

    def test_missing_identity_environment_is_rejected(self):
        for name in ('API_EXPLORER_COMMIT', 'API_EXPLORER_RELEASE_TAG'):
            with self.subTest(missing=name):
                result = run_identity(identity(), missing=(name,))
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn('do-not-print-contract-sentinel-7f906e', result.stderr)

    def test_production_environment_and_exact_two_checks_are_wired(self):
        self.assertIn('--env "API_EXPLORER_COMMIT=${api_explorer_commit}"', HEADER)
        self.assertIn('--env "API_EXPLORER_RELEASE_TAG=${api_explorer_release_tag}"', HEADER)
        self.assertEqual(len(IDENTITY), 2)
        self.assertIn('${API_EXPLORER_RELEASE_TAG#v}', IDENTITY[0])
        self.assertIn('${API_EXPLORER_COMMIT:0:7}', IDENTITY[1])
        self.assertEqual(OPTIONS, 'set -Eeuo pipefail')

    def test_failure_diagnostic_is_only_line_number_not_command_or_secret(self):
        # Even a rejected value containing a secret must not appear in ERR.
        result = run_identity(identity(), commit='secret-producer-do-not-print-7f906e')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, '')
        self.assertRegex(result.stderr, r'^SERVER_RUNTIME_CONTRACT_FAILED line=[0-9]+\n$')
        self.assertNotIn('secret-producer', result.stderr)
        self.assertNotIn('do-not-print-contract-sentinel-7f906e', result.stderr)
        self.assertNotIn('BASH_COMMAND', TRAP)
        self.assertNotRegex(OPTIONS, r'(?:^|[ -])x')

    def test_installed_package_stops_before_sentinel(self):
        result = run_guard('require_package_absent', 'unexpected-fixture', 'installed')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Unexpected runtime package: unexpected-fixture', result.stderr)
        self.assertNotIn('GUARD_SENTINEL_REACHED', result.stdout + result.stderr)

    def test_absent_package_reaches_sentinel(self):
        result = run_guard('require_package_absent', 'absent-fixture')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, 'GUARD_SENTINEL_REACHED\n')

    def test_unresolved_linkage_stops_before_sentinel(self):
        for linkage in ('libmissing.so => not found', 'target: undefined symbol: missing'):
            with self.subTest(linkage=linkage):
                result = run_guard('require_resolved_linkage', linkage)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('Unresolved runtime linkage', result.stderr)
                self.assertNotIn('GUARD_SENTINEL_REACHED', result.stdout + result.stderr)

    def test_resolved_linkage_reaches_sentinel(self):
        result = run_guard('require_resolved_linkage', 'libc.so.6 => /usr/lib/libc.so.6 (0x1234)')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, 'GUARD_SENTINEL_REACHED\n')

    def assert_zlib_rejected(self, **kwargs):
        result = run_zlib_guard(**kwargs)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('ZLIB_SENTINEL_REACHED', result.stdout + result.stderr)

    def test_zlib_matching_package_env_and_link_reach_sentinel(self):
        result = run_zlib_guard()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, 'ZLIB_SENTINEL_REACHED\n')

    def test_zlib_old_library_stops_before_sentinel(self):
        self.assert_zlib_rejected(old_library=True)

    def test_zlib_wrong_link_stops_before_sentinel(self):
        self.assert_zlib_rejected(wrong_link=True)

    def test_zlib_verify_changes_stop_before_sentinel(self):
        self.assert_zlib_rejected(verify_output='??5?????? /usr/lib/libz.so.1.3.1\n')

    def test_zlib_verify_nonzero_empty_output_stops_before_sentinel(self):
        self.assert_zlib_rejected(verify_status=1)

    def test_zlib_wrong_environment_stops_before_sentinel(self):
        for kwargs in ({'version': '1.3.2'},
                       {'package_version': '1:1.3.dfsg+really1.3.1-1ubuntu3.1'}):
            with self.subTest(kwargs=kwargs):
                self.assert_zlib_rejected(**kwargs)


if __name__ == '__main__':
    unittest.main(verbosity=2)

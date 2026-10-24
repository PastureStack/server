"""Network-free guards for source identity, unsuppressed tests and GID QA."""
import copy
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('rust_backport', HERE / 'build-rust-coreutils-backport.py')
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)


class RustBackport(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='rust-backport-contract-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.lock = M.load_lock(HERE / 'rust-coreutils.lock.json')

    def test_lock_rejects_widened_scope_unpinned_sources_and_wrong_identity(self):
        for field, bad in [('architecture', 'arm64'), ('ubuntuSourceVersion', '0.12.0'),
                           ('runtimePackages', ['coreutils']), ('sourceDateEpoch', True)]:
            with self.subTest(field=field):
                altered = copy.deepcopy(self.lock)
                altered[field] = bad
                file = self.root / 'bad.json'
                file.write_text(json.dumps(altered), encoding='utf-8')
                with self.assertRaises(ValueError): M.load_lock(file)
        for bad in ['../outside.patch', 'http://example.invalid/patch', 'bad-hash']:
            altered = copy.deepcopy(self.lock)
            key = 'name' if bad.startswith('..') else ('url' if bad.startswith('http') else 'sha256')
            altered['patches'][0][key] = bad
            file.write_text(json.dumps(altered), encoding='utf-8')
            with self.assertRaises(ValueError): M.load_lock(file)

    def test_poisoned_cache_is_not_silently_refetched(self):
        cache, inputs = self.root / 'cache', self.root / 'inputs'
        cache.mkdir(); inputs.mkdir()
        item = self.lock['patches'][0]
        (cache / item['name']).write_bytes(b'poison')
        with mock.patch.object(M.urllib.request, 'build_opener') as opener:
            with self.assertRaises(ValueError): M.download(item, inputs, cache)
            opener.assert_not_called()

    def test_source_control_manifest_must_match_all_three_pinned_archives(self):
        entries = [x for x in self.lock['sourceFiles'] if not x['name'].endswith('.dsc')]
        text = ('Format: 3.0 (quilt)\nSource: rust-coreutils\nVersion: ' + M.VERSION +
                '\nChecksums-Sha256:\n' + ''.join(' ' + x['sha256'] + ' ' + str(x['size']) +
                ' ' + x['name'] + '\n' for x in entries))
        file = self.root / ('rust-coreutils_' + M.VERSION + '.dsc')
        file.write_text(text, encoding='utf-8')
        M.verify_source_control(self.lock, self.root)
        file.write_text(text.replace(entries[0]['sha256'], '0' * 64), encoding='utf-8')
        with self.assertRaises(ValueError): M.verify_source_control(self.lock, self.root)

    def test_patch_cannot_modify_packaging_or_other_utilities(self):
        file = self.root / 'patch'
        text = 'From ' + M.COMMIT + ' Mon Sep 17 00:00:00 2001\n' + ''.join(
            'diff --git a/' + p + ' b/' + p + '\n' for p in M.PATHS)
        file.write_text(text, encoding='utf-8')
        M.verify_patch(self.lock['patches'][0], file)
        file.write_text(text + 'diff --git a/debian/rules b/debian/rules\n', encoding='utf-8')
        with self.assertRaises(ValueError): M.verify_patch(self.lock['patches'][0], file)

    def test_build_environment_discards_test_and_compiler_overrides(self):
        with mock.patch.dict(os.environ, {'DEB_BUILD_OPTIONS': 'nocheck', 'CARGOFLAGS': '--test id',
                                         'RUSTFLAGS': '-C opt-level=0', 'TESTS': 'id'}):
            env = M.build_environment(self.lock, 2, self.root)
        self.assertEqual('parallel=2', env['DEB_BUILD_OPTIONS'])
        self.assertEqual('', env['DEB_BUILD_MAINT_OPTIONS'])
        self.assertEqual('true', env['CARGO_NET_OFFLINE'])
        self.assertTrue(all(x not in env for x in ['CARGOFLAGS', 'RUSTFLAGS', 'TESTS', 'SKIP_UTILS']))

    def test_root_cannot_accidentally_run_the_build_or_full_suite(self):
        with mock.patch.object(Path, 'read_text', return_value='ID=ubuntu\nVERSION_ID="26.04"\n'), \
                mock.patch.object(M.os, 'geteuid', create=True, return_value=0):
            with self.assertRaisesRegex(ValueError, 'must run as non-root'):
                M.build(None, self.lock)

    def test_strict_receipt_requires_real_suite_and_official_regression(self):
        file = self.root / 'strict.log'
        good = ('test test_id::test_id_groups_ordering ... ok\n'
                'test result: ok. 12 passed; 0 failed; 2 ignored; 0 measured; 0 filtered out;\n')
        file.write_text(good, encoding='utf-8')
        self.assertEqual('PASS', M.strict_test_receipt(file)['status'])
        for bad in [good.replace('groups_ordering', 'unrelated'),
                    good.replace('0 failed', '1 failed'), good + 'test result: FAILED\n', '']:
            file.write_text(bad, encoding='utf-8')
            with self.assertRaises(ValueError): M.strict_test_receipt(file)

    def test_native_command_failure_cannot_be_swallowed(self):
        with self.assertRaises(ValueError):
            M.run([sys.executable, '-c', 'raise SystemExit(3)'], self.root, dict(os.environ),
                  self.root / 'failed.log')

    def test_distinct_gid_fixture_detects_original_effective_first_bug(self):
        binary = self.root / 'id'
        binary.write_bytes(b'fixture')
        def output(command, *_):
            real = int(next(x.split('=')[1] for x in command if x.startswith('--rgid=')))
            effective = int(next(x.split('=')[1] for x in command if x.startswith('--egid=')))
            extra = sorted(map(int, next(x.split('=')[1] for x in command if x.startswith('--groups=')).split(',')))
            args = command[command.index(str(binary)) + 1:]
            if '-G' in args: return ' '.join(map(str, dict.fromkeys([real, effective] + extra)))
            if '-g' in args: return str(real if '-r' in args else effective)
            return 'uid=65534(nobody) gid=' + str(real) + ' groups=' + ','.join(
                str(x) + '(group)' for x in dict.fromkeys([effective] + extra))
        with mock.patch.object(M, 'capture', side_effect=output):
            self.assertEqual(3, len(M.verify_id(binary, [], {}, self.root)))
        with mock.patch.object(M, 'capture', return_value='1 2'):
            with self.assertRaises(ValueError): M.verify_id(binary, [], {}, self.root)


if __name__ == '__main__':
    unittest.main()

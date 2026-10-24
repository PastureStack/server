"""Network-free guards for the official stable source/Ubuntu packaging boundary."""
import contextlib
import copy
import importlib.util
import io
import json
from pathlib import Path
import sys
import tarfile
import tempfile
import unittest
from unittest import mock

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('jq_release', HERE / 'build-jq-release.py')
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)


class JqStable(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='jq-source-contract-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.lock = M.load_lock()

    def read_altered(self, field, value):
        lock = copy.deepcopy(self.lock)
        lock[field] = value
        file = self.root / 'fixture.json'
        file.write_text(json.dumps(lock), encoding='utf-8')
        with mock.patch.object(M, 'LOCK', file):
            return M.load_lock()

    def test_official_release_and_complete_security_inventory(self):
        self.assertEqual('71b8d6e8f5fe81f6c6d0d110e3892251f6ce76ed095abd315e26e6e1193af3af',
                         self.lock['upstream']['sha256'])
        self.assertEqual(16, len(self.lock['upstream']['releaseSecurityCves']))
        self.assertEqual(6, len(self.lock['removedUbuntuPatches']))
        self.assertEqual(4, len(self.lock['retainedUbuntuPatches']))

    def test_other_versions_architectures_packages_and_incomplete_coverage_fail(self):
        for key, bad in [('upstreamVersion', '1.8.1'), ('architecture', 'arm64'),
                         ('runtimePackages', ['jq']), ('owningTests', ['jqtest'])]:
            with self.subTest(key=key):
                with self.assertRaises(ValueError): self.read_altered(key, bad)

    def test_foreign_url_or_unpinned_release_fails(self):
        for key, bad in [('url', 'https://example.invalid/jq.tar.gz'), ('sha256', ''),
                         ('name', '../outside.tar.gz')]:
            upstream = copy.deepcopy(self.lock['upstream'])
            upstream[key] = bad
            with self.assertRaises(ValueError): self.read_altered('upstream', upstream)

    def test_removal_requires_exact_original_fix_ancestry(self):
        removed = copy.deepcopy(self.lock['removedUbuntuPatches'])
        removed[0]['mergeBase'] = '0' * 40
        with self.assertRaises(ValueError): self.read_altered('removedUbuntuPatches', removed)

    def test_tampered_cached_source_is_not_refetched(self):
        inputs, cache = self.root / 'inputs', self.root / 'cache'
        inputs.mkdir(); cache.mkdir()
        item = self.lock['upstream']
        (cache / item['name']).write_bytes(b'tampered')
        with mock.patch.object(M.C.urllib.request, 'build_opener') as opener:
            with self.assertRaises(ValueError): M.download(item, inputs, cache)
            opener.assert_not_called()

    def test_archive_cannot_extract_outside_pinned_source_root(self):
        archive = self.root / 'bad.tar.gz'
        with tarfile.open(archive, 'w:gz') as source:
            info = tarfile.TarInfo('../outside')
            info.size = 1
            source.addfile(info, io.BytesIO(b'x'))
        with self.assertRaises(ValueError): M.safe_unpack(archive, self.root)
        self.assertFalse((self.root.parent / 'outside').exists())

    def test_all_nine_owning_suites_must_pass_without_new_skip(self):
        for name in M.TESTS:
            (self.root / (name + '.trs')).write_text(':test-result: PASS\n', encoding='utf-8')
        self.assertEqual(9, len(M.test_receipts(self.root)))
        (self.root / 'onigtest.trs').write_text(':test-result: SKIP\n', encoding='utf-8')
        with self.assertRaises(ValueError): M.test_receipts(self.root)
        (self.root / 'onigtest.trs').unlink()
        with self.assertRaises(ValueError): M.test_receipts(self.root)

    def test_original_packaging_cannot_change_silently(self):
        file = self.root / 'rules'
        file.write_bytes(b'original')
        hashes = {'rules': M.digest(file)}
        M.verify_hashes(self.root, hashes)
        file.write_bytes(b'changed')
        with self.assertRaises(ValueError): M.verify_hashes(self.root, hashes)

    def test_root_cannot_run_the_build_or_full_suite(self):
        with mock.patch.object(Path, 'read_text', return_value='ID=ubuntu\nVERSION_ID="26.04"\n'), \
                mock.patch.object(M.os, 'geteuid', create=True, return_value=0):
            with self.assertRaisesRegex(ValueError, 'non-root'):
                M.build(None, self.lock)

    def test_cli_cannot_select_a_lock_or_arbitrary_jobs(self):
        for args in [['--lock', '/tmp/untrusted'], ['--jobs', '8']]:
            with mock.patch.object(sys, 'argv', ['build-jq-release.py'] + args), \
                    contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as error: M.main()
                self.assertEqual(2, error.exception.code)

    def test_source_field_may_only_be_omitted_for_same_name_binary(self):
        M.verify_source_identity('jq', '')
        M.verify_source_identity('libjq1', 'jq')
        for package, value in [('libjq1', ''), ('jq', 'foreign'), ('libjq1', 'jq (1.8.1)')]:
            with self.assertRaises(ValueError): M.verify_source_identity(package, value)


if __name__ == '__main__':
    unittest.main()

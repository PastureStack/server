"""Network-free guards; native build/test execution belongs to isolated CI."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock
import sys

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('module_backport', HERE / 'build-libxrender-backport.py')
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)
H = M.H


class Backport(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='official-source-unit-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.lock = H.load_lock(HERE / 'libxrender.lock.json', 'libxrender', '1:0.9.12-1build1', M.COMMITS)

    def altered(self, key, value):
        lock = copy.deepcopy(self.lock)
        lock[key] = value
        file = self.root / 'bad.json'
        file.write_text(json.dumps(lock), encoding='utf-8')
        return H.load_lock(file, 'libxrender', '1:0.9.12-1build1', M.COMMITS)

    def test_version_architecture_and_commit_boundary_cannot_change(self):
        for key, value in [('architecture', 'arm64'), ('ubuntuSourceVersion', 'other'),
                           ('patches', []), ('runtimePackages', [])]:
            with self.assertRaises(ValueError): self.altered(key, value)

    def test_foreign_url_or_unpinned_source_cannot_be_downloaded(self):
        for key, value in [('url', 'https://example.invalid/source'), ('sha256', ''),
                           ('name', '../outside')]:
            sources = copy.deepcopy(self.lock['sourceFiles'])
            sources[0][key] = value
            with self.assertRaises(ValueError): self.altered('sourceFiles', sources)

    def test_poisoned_cache_fails_closed_without_refetch(self):
        cache, dest = self.root / 'cache', self.root / 'inputs'
        cache.mkdir(); dest.mkdir()
        item = self.lock['sourceFiles'][0]
        (cache / item['name']).write_bytes(b'poison')
        with mock.patch.object(H.COMMON.urllib.request, 'build_opener') as opener:
            with self.assertRaises(ValueError): H.COMMON.download(item, dest, cache)
            opener.assert_not_called()

    def test_source_and_packaging_hash_mismatch_is_fatal(self):
        file = self.root / 'input'
        file.write_bytes(b'original')
        expected = {'input': H.digest(file)}
        H.verify_hashes(self.root, expected)
        file.write_bytes(b'changed')
        with self.assertRaises(ValueError): H.verify_hashes(self.root, expected)

    def test_root_cannot_run_build_or_owning_tests(self):
        with mock.patch.object(Path, 'read_text', return_value='ID=ubuntu\nVERSION_ID="26.04"\n'), \
                mock.patch.object(H.os, 'geteuid', create=True, return_value=0):
            with self.assertRaisesRegex(ValueError, 'non-root'):
                H.build(None, self.lock, HERE, M.verify, [])

    def test_old_negative_control_must_fail_for_the_specific_reply_boundary(self):
        M.check_result(2, 'malformed header reached allocation: 1\n', True)
        for code, output in [(0, 'PASS'), (2, 'unrelated failure'), (-11, 'crashed')]:
            with self.assertRaises(ValueError): M.check_result(code, output, True)

    def test_candidate_and_packaged_controls_must_pass(self):
        M.check_result(0, 'valid control: PASS', False)
        with self.assertRaises(ValueError): M.check_result(2, 'PASS', False)

    def test_original_ubuntu_abi_binary_is_exactly_scoped(self):
        baseline = copy.deepcopy(self.lock['baselineBinary'])
        baseline['version'] = 'other'
        with self.assertRaises(ValueError): self.altered('baselineBinary', baseline)

    def test_actual_ubuntu_relro_baseline_does_not_require_new_bind_now_flags(self):
        dynamic = '0x000000000000000e (SONAME) Library soname: [libXrender.so.1]'
        self.assertEqual({'RELRO': True, 'BIND_NOW': False, 'originalBIND_NOW': False},
                         M.verify_hardening(dynamic, 'GNU_RELRO', dynamic))

    def test_existing_relro_and_bind_now_cannot_regress(self):
        for original in ['BIND_NOW', 'FLAGS_1 Flags: NOW']:
            with self.subTest(original=original):
                with self.assertRaises(ValueError): M.verify_hardening('', 'GNU_RELRO', original)
                self.assertTrue(M.verify_hardening(original, 'GNU_RELRO', original)['BIND_NOW'])
        with self.assertRaises(ValueError): M.verify_hardening('', '', '')


if __name__ == '__main__':
    unittest.main()

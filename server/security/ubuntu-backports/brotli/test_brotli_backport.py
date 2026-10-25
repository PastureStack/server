"""Focused source/receipt guards; no local compilation, install or malformed data."""
import copy
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('brotli_backport', HERE / 'build-brotli-backport.py')
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)


class BrotliBackport(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='brotli-unit-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.lock = M.load_lock(HERE / 'brotli.lock.json')

    def altered(self, key, value):
        lock = copy.deepcopy(self.lock); lock[key] = value
        p = self.root / 'lock.json'; p.write_text(json.dumps(lock))
        return M.load_lock(p)

    def test_locked_official_boundary(self):
        for k, v in [('architecture', 'arm64'), ('runtimePackages', ['libbrotli-dev']),
                     ('sourcePackage', 'other'), ('ubuntuSourceVersion', '1.2.1'),
                     ('patches', []), ('baselineSha256', {})]:
            with self.subTest(key=k), self.assertRaises(ValueError): self.altered(k, v)
        for key, value in [('url', 'https://example.invalid/source'), ('sha256', ''), ('name', '../outside')]:
            entries = copy.deepcopy(self.lock['sourceFiles']); entries[0][key] = value
            with self.subTest(key=key), self.assertRaises(ValueError): self.altered('sourceFiles', entries)

    def test_three_library_abi_contract_rejects_any_change(self):
        dynamic = 'SONAME [libbrotlidec.so.1]\nNEEDED [libbrotlicommon.so.1]\nNEEDED [libc.so.6]'
        symbols = '0 T BrotliDecoderDecompress\n1 W extra@VERSION_1'
        self.assertEqual(M.abi(dynamic, symbols, dynamic, symbols, 'libbrotlidec.so.1')['status'], 'PASS')
        for new, exports in [(dynamic.replace('so.1]', 'so.2]', 1), symbols),
                             (dynamic + '\nNEEDED [unknown.so.1]', symbols),
                             (dynamic.replace('\nNEEDED [libc.so.6]', ''), symbols),
                             (dynamic, symbols.replace('VERSION_1', 'VERSION_2')),
                             (dynamic, '0 T BrotliDecoderDecompress')]:
            with self.assertRaises(ValueError): M.abi(new, exports, dynamic, symbols, 'libbrotlidec.so.1')

    def test_owning_receipt_requires_real_cases_and_no_failures_or_skips(self):
        xml = '<testsuites><testsuite>' + '<testcase status="run"/>' * 14 + '</testsuite></testsuites>'
        log = 'Ran 21 tests in 0.1s\n\nOK\n'
        self.assertEqual(M.owning_results(xml, log)['cmakeCases'], 14)
        for badxml, badlog in [(xml.replace('/>', '><failure/></testcase>', 1), log),
                               (xml.replace('/>', '><skipped/></testcase>', 1), log),
                               ('<testsuites/>', log), (xml, 'Ran 0 tests in 0.0s\nOK'),
                               (xml, log.replace('OK', 'OK (skipped=1)')), (xml, log.replace('OK', 'FAILED'))]:
            with self.assertRaises(ValueError): M.owning_results(badxml, badlog)

    def test_common_build_reaches_verified_download_then_stops_before_build(self):
        args = type('Args', (), {'output_dir': self.root / 'out', 'work_dir': self.root / 'work',
                                 'cache_dir': None, 'jobs': 2})()
        real_read = Path.read_text
        def read(path, *a, **kw):
            return 'ID=ubuntu\nVERSION_ID="26.04"\n' if path.as_posix() == '/etc/os-release' else real_read(path, *a, **kw)
        class DownloadReached(Exception): pass
        with mock.patch.object(Path, 'read_text', read), mock.patch.object(M.H.os, 'geteuid', create=True, return_value=10001), \
                mock.patch.object(M.H.shutil, 'which', return_value='/usr/bin/tool'), \
                mock.patch.object(M.H, 'capture', return_value='amd64'), \
                mock.patch.object(M.H.COMMON, 'download', side_effect=DownloadReached) as download, \
                mock.patch.object(M.H, 'run') as run:
            with self.assertRaises(DownloadReached): M.H.build(args, self.lock, HERE, M.verify, [])
            self.assertEqual(download.call_args.args[0], self.lock['sourceFiles'][0])
            run.assert_not_called()

    def test_root_and_foreign_distribution_cannot_build(self):
        for release, uid in [('ID=ubuntu\nVERSION_ID="26.04"\n', 0), ('ID=debian\nVERSION_ID="13"\n', 10001)]:
            with mock.patch.object(Path, 'read_text', return_value=release), \
                    mock.patch.object(M.H.os, 'geteuid', create=True, return_value=uid):
                with self.assertRaisesRegex(ValueError, 'non-root'): M.H.build(None, self.lock, HERE, M.verify, [])

    def test_only_exact_official_two_file_patch_is_accepted(self):
        for item in M.H.inputs(self.lock):
            (self.root / item['name']).write_bytes(b'changed')
        with self.assertRaises(ValueError): M.H.verify_inputs(self.lock, self.root)
        # The real official patch and DSC are validated by source/native checks;
        # this test proves poisoned input never reaches source preparation.


if __name__ == '__main__':
    unittest.main()

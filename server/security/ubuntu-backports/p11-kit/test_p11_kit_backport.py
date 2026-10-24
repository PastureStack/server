"""Network-free guards; native build/test execution belongs to isolated CI."""
import copy
import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest import mock
import sys

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('module_backport', HERE / 'build-p11-kit-backport.py')
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)
H = M.H


class Backport(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='official-source-unit-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.lock = H.load_lock(HERE / 'p11-kit.lock.json', 'p11-kit', '0.26.2-2', M.COMMITS)

    def altered(self, key, value):
        lock = copy.deepcopy(self.lock)
        lock[key] = value
        file = self.root / 'bad.json'
        file.write_text(json.dumps(lock), encoding='utf-8')
        return H.load_lock(file, 'p11-kit', '0.26.2-2', M.COMMITS)

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

    def test_server_access_prerequisite_is_required_before_compilation(self):
        self.assertIn('gnutls-bin', self.lock['buildContract']['extraCiOnlyDependencies'])
        args = SimpleNamespace(output_dir=self.root / 'out', work_dir=self.root / 'work',
                               cache_dir=None, jobs=2)
        with mock.patch.object(Path, 'read_text', return_value='ID=ubuntu\nVERSION_ID="26.04"\n'), \
                mock.patch.object(H.os, 'geteuid', create=True, return_value=10001), \
                mock.patch.object(H.shutil, 'which', side_effect=lambda tool, **_: None if tool == 'p11tool' else '/usr/bin/' + tool), \
                mock.patch.object(H, 'run') as native:
            with self.assertRaisesRegex(ValueError, 'prerequisite missing: p11tool'):
                H.build(args, self.lock, HERE, M.verify, M.EXTRA_TOOLS)
            native.assert_not_called()

    def test_build_reaches_first_download_after_native_preflight(self):
        args = SimpleNamespace(output_dir=self.root / 'output', work_dir=self.root / 'work',
                               cache_dir=None, jobs=2)
        with mock.patch.object(Path, 'read_text', return_value='ID=ubuntu\nVERSION_ID="26.04"\n'), \
                mock.patch.object(H.os, 'geteuid', create=True, return_value=10001), \
                mock.patch.object(H.shutil, 'which', return_value='/usr/bin/mock-tool'), \
                mock.patch.object(H, 'capture', return_value='amd64') as capture, \
                mock.patch.object(H, 'run') as run, \
                mock.patch.object(H.COMMON, 'download',
                                  side_effect=RuntimeError('download boundary reached')) as download:
            with self.assertRaisesRegex(RuntimeError, 'download boundary reached'):
                H.build(args, self.lock, HERE, M.verify, [])
        capture.assert_called_once_with(['dpkg', '--print-architecture'], args.work_dir, mock.ANY)
        download.assert_called_once_with(self.lock['sourceFiles'][0], args.work_dir / 'inputs', None)
        run.assert_not_called()

    def suite(self):
        tests = {'test-rpc': 3, 'test-rpc-message': 2, 'test-control': 1}
        self.test_logs = [name + '.log' for name in tests]
        for name, cases in tests.items():
            (self.root / (name + '.trs')).write_text(':global-test-result: PASS\n' +
                ':test-result: PASS\n' * cases, encoding='utf-8')
            (self.root / (name + '.log')).write_text('ok 1 /control\n', encoding='utf-8')
        (self.root / 'test-rpc.log').write_text(
            '1..3\nok 1 /rpc3/control\nok 2 /rpc3/recursion-limit\nok 3 /rpc3/another-control\n',
            encoding='utf-8')
        (self.root / 'test-rpc-message.log').write_text(
            '1..2\nok 1 /rpc-message/control\nok 2 /rpc-message/attribute-recursion-limit\n',
            encoding='utf-8')
        (self.root / 'test-suite.log').write_text(
            '# TOTAL: 6\n# PASS: 6\n# SKIP: 0\n# XFAIL: 0\n# FAIL: 0\n# XPASS: 0\n# ERROR: 0\n',
            encoding='utf-8')

    def test_multi_case_trs_totals_match_full_summary(self):
        self.suite()
        result = M.full_suite(self.root, self.test_logs)[0]
        self.assertEqual('PASS', result['status'])
        self.assertEqual(6, result['counts']['TOTAL'])
        self.assertEqual(3, len(result['receipts']))
        self.assertEqual(6, sum(r['caseCounts']['PASS'] for r in result['receipts']))

    def test_skips_and_incomplete_suite_never_become_pass(self):
        self.suite()
        summary = self.root / 'test-suite.log'
        summary.write_text(summary.read_text().replace('# PASS: 6', '# PASS: 5').replace('# SKIP: 0', '# SKIP: 1'))
        with self.assertRaises(ValueError): M.full_suite(self.root, self.test_logs)
        self.suite()
        (self.root / 'test-control.trs').unlink()
        with self.assertRaises(ValueError): M.full_suite(self.root, self.test_logs)

    def test_case_total_and_each_summary_state_must_match(self):
        for old, new in [('# TOTAL: 6', '# TOTAL: 7'), ('# PASS: 6', '# PASS: 5')] + [
                ('# ' + state + ': 0', '# ' + state + ': 1')
                for state in ['SKIP', 'XFAIL', 'FAIL', 'XPASS', 'ERROR']]:
            with self.subTest(summary=new):
                self.suite()
                summary = self.root / 'test-suite.log'
                summary.write_text(summary.read_text().replace(old, new), encoding='utf-8')
                with self.assertRaises(ValueError): M.full_suite(self.root, self.test_logs)

    def test_nonpass_trs_case_cannot_hide_among_other_pass_cases(self):
        for state in ['SKIP', 'XFAIL', 'FAIL', 'XPASS', 'ERROR', 'UNKNOWN']:
            with self.subTest(state=state):
                self.suite()
                report = self.root / 'test-rpc.trs'
                report.write_text(report.read_text().replace(':test-result: PASS',
                    ':test-result: ' + state, 1), encoding='utf-8')
                if state != 'UNKNOWN':
                    summary = self.root / 'test-suite.log'
                    summary.write_text(summary.read_text().replace('# PASS: 6', '# PASS: 5').replace(
                        '# ' + state + ': 0', '# ' + state + ': 1'), encoding='utf-8')
                with self.assertRaises(ValueError): M.full_suite(self.root, self.test_logs)

    def test_required_case_needs_single_unqualified_tap_ok(self):
        for file, case in [('test-rpc.log', '/rpc3/recursion-limit'),
                           ('test-rpc-message.log', '/rpc-message/attribute-recursion-limit')]:
            for text in [case, '# ' + case, 'not ok 2 ' + case, 'ok 2 ' + case + ' # SKIP unavailable',
                         'ok 2 ' + case + ' # TODO later', 'ok 2 ' + case + '-other',
                         'ok 2 ' + case + '\nnot ok 3 ' + case,
                         'ok 2 ' + case + '\nok 3 ' + case]:
                with self.subTest(file=file, log=text):
                    self.suite()
                    (self.root / file).write_text(text + '\n', encoding='utf-8')
                    with self.assertRaises(ValueError): M.full_suite(self.root, self.test_logs)

    def test_configured_duplicate_logs_preserve_summary_and_unique_case_counts(self):
        self.suite()
        # Automake counts a configured TEST_LOGS entry twice, while the file and
        # actual testcase execution exist only once. No skip or failure is hidden.
        manifest = self.test_logs + ['test-rpc-message.log']
        summary = self.root / 'test-suite.log'
        summary.write_text(summary.read_text().replace('# TOTAL: 6', '# TOTAL: 8').replace(
            '# PASS: 6', '# PASS: 8'), encoding='utf-8')
        result = M.full_suite(self.root, manifest)[0]
        self.assertEqual(8, result['counts']['TOTAL'])
        self.assertEqual(6, result['uniqueCaseTotal'])
        self.assertEqual(2, next(r for r in result['receipts']
                                if r['path'] == 'test-rpc-message.trs')['summaryOccurrences'])
        with self.assertRaises(ValueError): M.full_suite(self.root, self.test_logs)

    def test_configured_manifest_cannot_omit_or_add_native_trs_files(self):
        self.suite()
        for manifest in [self.test_logs[:-1], self.test_logs + ['missing.log'],
                         self.test_logs + ['../outside.log'], []]:
            with self.subTest(manifest=manifest), self.assertRaises(ValueError):
                M.full_suite(self.root, manifest)

    def test_test_log_query_preserves_configured_order_and_duplicates(self):
        with mock.patch.object(H, 'capture', return_value='test-rpc.log\ntest-oid.log\ntest-oid.log') as query:
            self.assertEqual(['test-rpc.log', 'test-oid.log', 'test-oid.log'],
                             M.configured_test_logs(self.root, {}))
        command = query.call_args[0][0]
        self.assertEqual('make', command[0])
        self.assertIn('$(TEST_LOGS)', command[3])
        self.assertEqual('pasturestack-print-test-logs', command[-1])

    def test_cve18938_retains_32bit_qualification(self):
        self.assertTrue(any('32-bit' in value for value in self.lock['limitations']))


if __name__ == '__main__':
    unittest.main()

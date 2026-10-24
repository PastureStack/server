"""Focused network-free tar backport contracts; no native compilation."""
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import urllib.request

HERE = Path(__file__).resolve().parent
sys.dont_write_bytecode = True
SPEC = importlib.util.spec_from_file_location('tar_backport', HERE / 'build-tar-backport.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class TarBackport(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='tar-backport-contract-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.lock = MODULE.load_lock()

    def load(self, lock):
        file = self.root / 'fixture.json'; file.write_text(json.dumps(lock), encoding='utf-8')
        return MODULE.load_lock(file)

    def test_fixed_source_and_single_cve_scope(self):
        self.assertEqual(['CVE-2026-18477'], self.lock['fixedCves'])
        self.assertEqual(['CVE-2026-18508'], [x['id'] for x in self.lock['blockedCves']])
        self.assertEqual([], self.lock['prerequisites']['additionalPatches'])
        self.assertEqual(['NEWS'], self.lock['patches'][0]['excludedDocumentationPaths'])

    def test_foreign_version_architecture_or_cve_scope_fails(self):
        for field, value in [('sourcePackage', 'gtar'), ('ubuntuSourceVersion', '1.35-13.el10'),
                             ('customVersion', MODULE.VERSION), ('architecture', 'arm64'),
                             ('runtimePackages', ['tar', 'tar-scripts']),
                             ('fixedCves', ['CVE-2026-18477', 'CVE-2026-18508']), ('sourceDateEpoch', True)]:
            value_lock = copy.deepcopy(self.lock); value_lock[field] = value
            with self.subTest(field=field), self.assertRaises(ValueError): self.load(value_lock)

    def test_source_set_url_hash_length_are_fixed(self):
        for mutation in ['missing', 'duplicate', 'url', 'sha256', 'size']:
            lock = copy.deepcopy(self.lock)
            if mutation == 'missing': lock['sourceFiles'].pop()
            elif mutation == 'duplicate': lock['sourceFiles'][1] = lock['sourceFiles'][0]
            else: lock['sourceFiles'][0][mutation] = {'url': 'https://example.invalid/tar', 'sha256': '0' * 64, 'size': 1}[mutation]
            with self.subTest(mutation=mutation), self.assertRaises(ValueError): self.load(lock)

    def test_only_full_accepted_released_vendor_patch_is_allowed(self):
        for mutation in ['extra', 'url', 'sha256', 'commit', 'prerequisite']:
            lock = copy.deepcopy(self.lock)
            if mutation == 'extra': lock['patches'].append(copy.deepcopy(lock['patches'][0]))
            if mutation == 'url': lock['patches'][0]['url'] = lock['patches'][0]['url'].replace(MODULE.VENDOR, 'rawhide')
            if mutation == 'sha256': lock['patches'][0]['sha256'] = '0' * 64
            if mutation == 'commit': lock['patches'][0]['upstreamAcceptedCommits'][0] = '0' * 40
            if mutation == 'prerequisite': lock['prerequisites']['additionalPatches'] = ['18508-api.patch']
            with self.subTest(mutation=mutation), self.assertRaises(ValueError): self.load(lock)

    def test_code_test_or_thanks_exclusions_are_rejected(self):
        for path in ['src/incremen.c', 'tests/rename08.at', 'THANKS', 'doc/tar.texi']:
            lock = copy.deepcopy(self.lock); lock['patches'][0]['excludedDocumentationPaths'].append(path)
            with self.subTest(path=path), self.assertRaises(ValueError): self.load(lock)

    def test_derived_patch_preserves_all_non_news_diff_bytes(self):
        blocks = [('diff --git a/{0} b/{0}\n--- a/{0}\n+++ b/{0}\n@@ -1 +1 @@\n-old {0}\n+new {0}\n'.format(n)).encode()
                  for n in ['NEWS'] + MODULE.APPLIED]
        file = self.root / MODULE.PATCH_NAME; file.write_bytes(b''.join(blocks))
        expected = b''.join(blocks[1:])
        with mock.patch.object(MODULE.COMMON, 'verify_input'), mock.patch.object(MODULE, 'DERIVED_SHA', hashlib.sha256(expected).hexdigest()):
            self.assertEqual(expected, MODULE.derived_patch(self.lock, file))
            file.write_bytes(b''.join(blocks[:-1]))
            with self.assertRaises(ValueError): MODULE.derived_patch(self.lock, file)

    def test_original_patch_tamper_fails_before_document_filtering(self):
        file = self.root / MODULE.PATCH_NAME; file.write_bytes(b'diff --git a/NEWS b/NEWS\n')
        with self.assertRaises(ValueError): MODULE.derived_patch(self.lock, file)

    def test_dsc_binds_original_source_and_packaging(self):
        text = 'Format: 3.0 (quilt)\nSource: tar\nVersion: ' + MODULE.VERSION + '\nChecksums-Sha256:\n' + ''.join(
            ' {sha256} {size} {name}\n'.format(**i) for i in self.lock['sourceFiles'][1:])
        file = self.root / ('tar_' + MODULE.VERSION + '.dsc')
        file.write_text(text, encoding='utf-8'); MODULE.verify_source_control(self.lock, self.root)
        for bad in [text.replace('Source: tar', 'Source: foreign'), text.replace('3.0 (quilt)', '1.0'),
                    text.replace(MODULE.VERSION, '1.35-13.el10'), text.rsplit('\n', 2)[0] + '\n',
                    text + text.splitlines()[-1] + '\n', text.replace(self.lock['sourceFiles'][1]['sha256'], '0' * 64)]:
            file.write_text(bad, encoding='utf-8')
            with self.assertRaises(ValueError): MODULE.verify_source_control(self.lock, self.root)

    def test_poisoned_cache_fails_without_fetching_replacement(self):
        cache, output = self.root / 'cache', self.root / 'out'; cache.mkdir(); output.mkdir()
        data = b'official bytes'; file = cache / 'fixture.patch'; file.write_bytes(data)
        item = {'name': file.name, 'url': 'https://example.invalid/input', 'size': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
        with mock.patch.object(urllib.request, 'build_opener') as network:
            MODULE.COMMON.download(item, output, cache)
            file.write_bytes(data + b'tamper')
            with self.assertRaises(ValueError): MODULE.COMMON.download(item, output, cache)
            network.assert_not_called()

    def test_environment_cannot_filter_tests_or_override_compilers(self):
        with mock.patch.dict(os.environ, {'DEB_BUILD_OPTIONS': 'nocheck', 'TESTSUITEFLAGS': '1', 'FULL_TEST': '1',
                                         'TARTEST_SKIP_LARGE_FILES': '1', 'CC': 'unsafe', 'CFLAGS': '-O0'}):
            env = MODULE.build_environment(self.lock, 2)
        self.assertEqual('parallel=2', env['DEB_BUILD_OPTIONS'])
        self.assertEqual('', env['DEB_BUILD_PROFILES'])
        for name in ['TESTSUITEFLAGS', 'TARTEST_SKIP_LARGE_FILES', 'FULL_TEST', 'CC', 'CFLAGS', 'DEB_BUILD_MAINT_OPTIONS']:
            self.assertNotIn(name, env)
        self.assertEqual('-j2', MODULE.COMMON.job_option(2)); self.assertEqual('-j4', MODULE.COMMON.job_option(4))
        with self.assertRaises(ValueError): MODULE.build_environment(self.lock, 8)

    def suite_fixture(self):
        directory = self.root / 'tests'; directory.mkdir()
        names = {str(i): 'test%04d.at' % i for i in range(1, 206)}
        names['204'], names['205'] = 'rename08.at', 'rename09.at'
        script = ''.join(f'{i};{name}:25;description;keyword;\n' for i, name in names.items())
        log = ''.join(f'{i}. description ({name}:25): ' + ('skipped (fixture)' if i == '1' else 'expected failure (fixture)' if i == '2' else 'ok') + '\n'
                      for i, name in names.items())
        (directory / 'testsuite').write_text(script, encoding='utf-8')
        file = directory / 'testsuite.log'; file.write_text(log, encoding='utf-8')
        return file, log

    def test_complete_suite_preserves_original_xfail_skip_semantics(self):
        self.suite_fixture(); result = MODULE.test_receipt(self.root)
        self.assertEqual(205, result['configuredGroups'])
        self.assertEqual({'PASS': 203, 'XFAIL': 1, 'SKIP': 1}, result['counts'])
        self.assertEqual(0, result['addedSkips'])

    def test_filtered_ambiguous_or_unexpected_native_results_fail(self):
        file, original = self.suite_fixture()
        for bad in [original.split('\n', 1)[1], original + original.splitlines()[-1] + '\n',
                    original.replace('): ok', '): FAILED (fixture)', 1),
                    original.replace('): ok', '): UNEXPECTED PASS', 1),
                    original.replace('): ok', '): UNKNOWN', 1), original.replace('rename09.at:25): ok', 'rename09.at:25): skipped (fixture)')]:
            file.write_text(bad, encoding='utf-8')
            with self.assertRaises(ValueError): MODULE.test_receipt(self.root)

    def test_source_prerequisite_hash_mismatch_and_missing_smoke_binary_fail(self):
        file = self.root / 'input'; file.write_bytes(b'original')
        expected = {'input': MODULE.digest(file)}; MODULE.verify_sources(self.root, expected)
        file.write_bytes(b'tamper')
        with self.assertRaises(ValueError): MODULE.verify_sources(self.root, expected)
        with self.assertRaises(ValueError): MODULE.tar_smoke(self.root / 'missing', self.root, {}, self.root / 'log')

    def test_output_must_not_overlap_build_or_download_cache(self):
        for directory in [self.root / 'out', self.root / 'out/nested', self.root]:
            with self.assertRaises(ValueError): MODULE.COMMON.require_separate_paths(self.root / 'out', directory, None)
            with self.assertRaises(ValueError): MODULE.COMMON.require_separate_paths(self.root / 'out', None, directory)

    def test_quilt_addition_preserves_order_and_existing_bytes_with_trailing_blank_lines(self):
        original = '# original comment\nfirst.patch\nlast.patch\n\n'
        added = MODULE.DERIVED_NAME + '\n'
        MODULE.verify_series(original, original + added)
        MODULE.verify_series(original, original[:-1] + added + '\n')
        for bad in [added + original, original.replace('first.patch', 'foreign.patch') + added,
                    original.replace('# original comment\n', '') + added, original + added + added]:
            with self.assertRaises(ValueError): MODULE.verify_series(original, bad)

    def cli(self, *args):
        return subprocess.run([sys.executable, '-B', str(HERE / 'build-tar-backport.py'), *args], cwd=self.root,
                              text=True, encoding='utf-8', capture_output=True)

    def test_cli_uses_here_lock_independently_of_working_directory(self):
        result = self.cli('--validate-lock')
        self.assertEqual(0, result.returncode, result.stderr); self.assertIn('TAR_BACKPORT_LOCK_OK', result.stdout)

    def test_cli_rejects_lock_override_jobs_other_than_two_four_and_external_input_reader(self):
        for args in [('--validate-lock', '--lock', 'foreign.json'), ('--validate-lock', '--jobs', '8'),
                     ('--validate-lock', '--jobs', '0'), ('--validate-lock', '--jobs', '-j2'),
                     ('--validate-inputs', '--cache-dir', str(self.root))]:
            with self.subTest(args=args):
                result = self.cli(*args)
                self.assertNotEqual(0, result.returncode)
                if args[0] == '--validate-inputs':
                    self.assertIn('unrecognized arguments', result.stderr)


if __name__ == '__main__':
    unittest.main()

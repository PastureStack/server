"""Network-free input, negative boundary and CLI checks; no glibc compilation."""
import copy
import hashlib
import importlib.util
import io
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
SPEC = importlib.util.spec_from_file_location('glibc_backport', HERE / 'build-glibc-backport.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class GlibcBackport(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='glibc-backport-contract-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.lock = MODULE.load_lock(HERE / 'glibc.lock.json')

    def load(self, value):
        file = self.root / 'fixture.lock.json'
        file.write_text(json.dumps(value), encoding='utf-8')
        return MODULE.load_lock(file)

    def test_lock_has_exact_source_fix_regression_and_native_boundary(self):
        self.assertEqual(4, len(self.lock['sourceFiles']))
        self.assertEqual([MODULE.FIX, MODULE.REGRESSION], [p['commit'] for p in self.lock['patches']])
        self.assertEqual(['nobiarch', 'noudeb'], self.lock['buildProfiles'])
        self.assertEqual(['CVE-2026-18374'], self.lock['fixedCves'])

    def test_foreign_identity_architecture_profile_or_runtime_set_fails(self):
        for field, value in [('sourcePackage', 'eglibc'), ('ubuntuSourceVersion', '2.44-1'),
                             ('customVersion', '2.43-2ubuntu2.4'), ('architecture', 'arm64'),
                             ('buildProfiles', ['nocheck']), ('runtimePackages', ['libc6']),
                             ('optionalDevPackages', ['libc6-dev']), ('sourceDateEpoch', True),
                             ('identity', 'Official Canonical update')]:
            with self.subTest(field=field):
                lock = copy.deepcopy(self.lock); lock[field] = value
                with self.assertRaises(ValueError): self.load(lock)

    def test_missing_duplicate_or_tampered_source_pin_fails(self):
        for mutation in ['missing', 'duplicate', 'sha256', 'size', 'url', 'name']:
            lock = copy.deepcopy(self.lock)
            if mutation == 'missing': lock['sourceFiles'].pop()
            elif mutation == 'duplicate': lock['sourceFiles'][1] = lock['sourceFiles'][0]
            else: lock['sourceFiles'][0][mutation] = {'sha256': '0' * 64, 'size': 9079,
                    'url': 'https://example.invalid/source', 'name': '../outside.dsc'}[mutation]
            with self.subTest(mutation=mutation), self.assertRaises(ValueError): self.load(lock)

    def test_other_branch_reordered_missing_or_rehashed_patch_fails(self):
        for mutation in ['branch', 'order', 'missing', 'duplicate', 'sha256', 'url']:
            lock = copy.deepcopy(self.lock)
            if mutation == 'branch': lock['patches'][0]['commit'] = '9765a538ebf8661a6e5578e01e35a3dd30db7eb4'
            if mutation == 'order': lock['patches'].reverse()
            if mutation == 'missing': lock['patches'].pop()
            if mutation == 'duplicate': lock['patches'][1] = lock['patches'][0]
            if mutation == 'sha256': lock['patches'][0]['sha256'] = '0' * 64
            if mutation == 'url': lock['patches'][0]['url'] = 'http://sourceware.org/patch'
            with self.subTest(mutation=mutation), self.assertRaises(ValueError): self.load(lock)

    def test_dsc_binds_quilt_format_and_all_three_original_inputs(self):
        text = 'Format: 3.0 (quilt)\nSource: glibc\nVersion: 2.43-2ubuntu2.4\nChecksums-Sha256:\n' + ''.join(
            ' {sha256} {size} {name}\n'.format(**item) for item in self.lock['sourceFiles'][1:])
        file = self.root / 'glibc_2.43-2ubuntu2.4.dsc'
        file.write_text(text, encoding='utf-8'); MODULE.verify_source_control(self.lock, self.root)
        for bad in [text.replace('3.0 (quilt)', '1.0'), text.replace('Source: glibc', 'Source: other'),
                    text.replace('2.43-2ubuntu2.4\n', '2.44-1\n'), text.rsplit('\n', 2)[0] + '\n',
                    text + text.splitlines()[-1] + '\n',
                    text.replace(self.lock['sourceFiles'][1]['sha256'], '0' * 64)]:
            file.write_text(bad, encoding='utf-8')
            with self.assertRaises(ValueError): MODULE.verify_source_control(self.lock, self.root)

    def test_poisoned_cache_fails_without_network_fallback(self):
        cache, output = self.root / 'cache', self.root / 'input'
        cache.mkdir(); output.mkdir(); data = b'official pinned bytes\n'
        item = {'name': 'input.patch', 'url': 'https://example.invalid/never',
                'size': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
        cached = cache / item['name']; cached.write_bytes(data)
        with mock.patch.object(urllib.request, 'build_opener') as network:
            self.assertEqual(data, MODULE.download(item, output, cache).read_bytes())
            cached.write_bytes(data + b'tampered')
            with self.assertRaises(ValueError): MODULE.download(item, output, cache)
            network.assert_not_called()

    def test_download_limit_uses_exact_pin_instead_of_generic_cap(self):
        class Response(io.BytesIO):
            url = 'https://sourceware.org/patch'
        item = {'name': 'input.patch', 'url': Response.url, 'size': 3,
                'sha256': hashlib.sha256(b'abc').hexdigest()}
        opener = mock.Mock(); opener.open.return_value = Response(b'abcd')
        with mock.patch.object(urllib.request, 'build_opener', return_value=opener):
            with self.assertRaisesRegex(ValueError, 'pinned size'): MODULE.download(item, self.root, None)

    def test_https_redirect_downgrade_fails(self):
        with self.assertRaises(ValueError):
            MODULE.COMMON.HttpsRedirect().redirect_request(urllib.request.Request('https://sourceware.org/patch'),
                None, 302, 'Found', {}, 'http://example.invalid/patch')

    def test_patch_commit_paths_metadata_and_bytes_are_verified(self):
        file = self.root / 'fix.patch'
        original = 'From ' + MODULE.FIX + ' Mon Sep 17 00:00:00 2001\ndiff --git a/libio/fileops.c b/libio/fileops.c\n'
        for text, valid in [(original, True), (original.replace(MODULE.FIX, '0' * 40), False),
                            (original.replace('libio/fileops.c', 'debian/rules'), False),
                            (original.replace('libio/fileops.c', 'libio/../../outside'), False),
                            (original + 'new mode 100755\n', False)]:
            file.write_text(text, encoding='utf-8')
            item = {'name': file.name, 'commit': MODULE.FIX, 'size': len(file.read_bytes()),
                    'sha256': MODULE.digest(file)}
            if valid: MODULE.verify_patch(item, file)
            else:
                with self.assertRaises(ValueError): MODULE.verify_patch(item, file)
        file.write_text(original, encoding='utf-8')
        with self.assertRaises(ValueError): MODULE.verify_patch(item, file)

    def test_environment_cannot_skip_tests_replace_compilers_or_expand_abis(self):
        with mock.patch.dict(os.environ, {'DEB_BUILD_OPTIONS': 'nocheck noopt', 'DEB_BUILD_PROFILES': 'stage1',
                                         'RUN_TESTSUITE': 'no', 'CC': 'unsafe', 'CFLAGS': '-O0'}):
            environment = MODULE.build_environment(self.lock, 4)
        self.assertEqual('parallel=4', environment['DEB_BUILD_OPTIONS'])
        self.assertEqual('nobiarch noudeb', environment['DEB_BUILD_PROFILES'])
        self.assertEqual('hardening=+all', environment['DEB_BUILD_MAINT_OPTIONS'])
        for name in ['RUN_TESTSUITE', 'CC', 'CFLAGS']: self.assertNotIn(name, environment)

    def test_source_closure_rejects_old_fallback_or_unregistered_regression(self):
        directory = self.root / 'libio'; directory.mkdir()
        source = directory / 'fileops.c'; source.write_text(MODULE.NEW_CALL, encoding='utf-8')
        (directory / 'Makefile').write_text('tst-fopen-ccs-empty', encoding='utf-8')
        (directory / 'tst-fopen-ccs-empty.c').write_text('official fixture', encoding='utf-8')
        self.assertEqual(3, len(MODULE.source_closure(self.root)))
        source.write_text(MODULE.NEW_CALL + MODULE.OLD_CALL, encoding='utf-8')
        with self.assertRaises(ValueError): MODULE.source_closure(self.root)
        source.write_text(MODULE.NEW_CALL, encoding='utf-8')
        (directory / 'Makefile').write_text('', encoding='utf-8')
        with self.assertRaises(ValueError): MODULE.source_closure(self.root)

    def native_fixture(self):
        directory = self.root / 'build-tree/amd64-libc'; directory.mkdir(parents=True)
        (self.root / 'stamp-dir').mkdir()
        (self.root / 'stamp-dir/check_libc_passed').touch()
        text = '\t\t=== glibc tests ===\n\nRunning . ...\n\n' + ''.join('PASS: ' + name + '\n' for name in MODULE.CONTROLS) + ''.join(
            'PASS: ' + component + '/ordinary-control\n' for component in
            ['stdio-common', 'iconv', 'wcsmbs', 'malloc', 'elf', 'nptl', 'nss'])
        text += 'XFAIL: elf/known-failure\nUNSUPPORTED: nss/unsupported-environment\nXPASS: elf/known-xpass\n'
        file = directory / 'tests.sum'; file.write_text(text, encoding='utf-8')
        return file, text

    def test_full_native_receipt_preserves_xfail_unsupported_xpass_semantics(self):
        self.native_fixture()
        result = MODULE.test_receipt(self.root)
        self.assertEqual({'PASS': 10, 'XFAIL': 1, 'UNSUPPORTED': 1, 'XPASS': 1}, result['counts'])

    def test_native_summary_requires_canonical_framing_and_rejects_unknown_lines(self):
        good = '\t\t=== glibc tests ===\n\nRunning libio ...\nPASS: libio/control\n'
        self.assertEqual([('PASS', 'libio/control')], MODULE.parse_test_summary(good))
        for bad in [good.replace('=== glibc tests ===', '=== another suite ==='),
                    good.replace('Running libio ...', 'Running libio unexpectedly'),
                    good + 'unexpected diagnostic\n', good + 'Running libio ...\n',
                    good + 'SKIP: libio/unknown-state\n', 'PASS: libio/control\n']:
            with self.subTest(summary=bad), self.assertRaises(ValueError): MODULE.parse_test_summary(bad)

    def packaging_fixture(self):
        debian = self.root / 'debian'
        (debian / 'control.in').mkdir(parents=True)
        (debian / 'rules.d').mkdir()
        for name, text in [('control', 'Maintainer: Ubuntu Developers\n'),
                           ('control.in/main', 'Maintainer: GNU Libc Maintainers\n'),
                           ('rules', 'original rules\n'), ('rules.d/control.mk', 'original control generator\n')]:
            (debian / name).write_text(text, encoding='utf-8')
        return debian

    def test_original_control_metadata_remains_bound_to_the_packaging_snapshot(self):
        debian = self.packaging_fixture()
        approved = MODULE.COMMON.packaging_snapshot(self.root)
        MODULE.verify_packaging_inputs(self.root, approved)
        (debian / 'control').write_bytes((debian / 'control.in/main').read_bytes())
        with self.assertRaisesRegex(ValueError, 'debian/control'):
            MODULE.verify_packaging_inputs(self.root, approved)

    def test_generated_control_only_accepts_the_approved_original_template_bytes(self):
        debian = self.packaging_fixture()
        original = MODULE.digest(debian / 'control')
        generated = MODULE.digest(debian / 'control.in/main')
        def generate(*_):
            (debian / 'control').write_bytes((debian / 'control.in/main').read_bytes())
        with mock.patch.object(MODULE, 'CONTROL_ORIGINAL_SHA256', original), \
                mock.patch.object(MODULE, 'CONTROL_GENERATED_SHA256', generated), \
                mock.patch.object(MODULE, 'run', side_effect=generate):
            receipt = MODULE.prepare_generated_control(self.root, {}, self.root / 'build.log')
            self.assertEqual(original, receipt['originalSha256'])
            self.assertEqual(generated, receipt['generatedSha256'])
            self.assertIn('debian/control.in/main', receipt['inputSha256'])
            approved = MODULE.COMMON.packaging_snapshot(self.root)
            MODULE.verify_packaging_inputs(self.root, approved)
            with self.assertRaisesRegex(ValueError, 'Fresh original'):
                MODULE.prepare_generated_control(self.root, {}, self.root / 'build.log')

    def test_control_generation_rejects_extra_field_or_packaging_changes(self):
        debian = self.packaging_fixture()
        original_bytes = (debian / 'control').read_bytes()
        original, generated = MODULE.digest(debian / 'control'), MODULE.digest(debian / 'control.in/main')
        for change_other in [False, True]:
            (debian / 'control').write_bytes(original_bytes)
            def generate(*_):
                (debian / 'control').write_bytes((debian / 'control.in/main').read_bytes())
                if change_other:
                    (debian / 'rules').write_text('changed rules\n', encoding='utf-8')
                else:
                    with (debian / 'control').open('a', encoding='utf-8') as stream:
                        stream.write('Depends: unapproved\n')
            with mock.patch.object(MODULE, 'CONTROL_ORIGINAL_SHA256', original), \
                    mock.patch.object(MODULE, 'CONTROL_GENERATED_SHA256', generated), \
                    mock.patch.object(MODULE, 'run', side_effect=generate), \
                    self.assertRaisesRegex(ValueError, 'debian/rules|approved original-template'):
                MODULE.prepare_generated_control(self.root, {}, self.root / 'build.log')

    def test_generated_control_policy_cannot_be_widened(self):
        for field, value in [('originalControlSha256', '0' * 64),
                             ('generatedControlSha256', '0' * 64),
                             ('approvedChangedFields', ['Maintainer', 'Depends'])]:
            lock = copy.deepcopy(self.lock)
            lock['packagingMetadataPolicy'][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError): self.load(lock)

    def test_native_failure_skipped_cve_component_or_extra_abi_fails(self):
        file, text = self.native_fixture()
        for bad in [text + 'FAIL: libio/surviving-bug\n', text + 'ERROR: elf/error\n',
                    text + 'NEW_UNKNOWN_STATE: libio/unknown\n',
                    text.replace('PASS: ' + MODULE.CONTROLS[0], 'UNSUPPORTED: ' + MODULE.CONTROLS[0]),
                    text.replace('PASS: malloc/ordinary-control\n', ''), text + 'PASS: ' + MODULE.CONTROLS[0] + '\n']:
            file.write_text(bad, encoding='utf-8')
            with self.assertRaises(ValueError): MODULE.test_receipt(self.root)
        file.write_text(text, encoding='utf-8'); (self.root / 'stamp-dir/check_libc_failed').touch()
        with self.assertRaises(ValueError): MODULE.test_receipt(self.root)
        (self.root / 'stamp-dir/check_libc_failed').unlink()
        (self.root / 'build-tree/amd64-x32').mkdir()
        with self.assertRaises(ValueError): MODULE.test_receipt(self.root)

    def test_original_packaging_and_disjoint_output_guards_are_reused(self):
        debian = self.root / 'debian'; debian.mkdir()
        (debian / 'rules').write_text('original tests and flags', encoding='utf-8')
        (debian / 'changelog').write_text('original', encoding='utf-8')
        snapshot = MODULE.COMMON.packaging_snapshot(self.root)
        (debian / 'changelog').write_text('custom version', encoding='utf-8')
        self.assertEqual(snapshot, MODULE.COMMON.packaging_snapshot(self.root))
        (debian / 'rules').write_text('nocheck', encoding='utf-8')
        self.assertNotEqual(snapshot, MODULE.COMMON.packaging_snapshot(self.root))
        for directory in [self.root / 'out', self.root / 'out/nested', self.root]:
            with self.assertRaises(ValueError):
                MODULE.COMMON.require_separate_paths(self.root / 'out', directory, None)

    def cli(self, *args):
        return subprocess.run([sys.executable, '-B', str(HERE / 'build-glibc-backport.py'), *args],
                              capture_output=True, text=True, encoding='utf-8')

    def test_cli_validate_lock_is_network_and_linux_build_independent(self):
        result = self.cli('--validate-lock')
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn('GLIBC_BACKPORT_LOCK_OK', result.stdout)
        self.assertNotIn('GLIBC_BACKPORT_BUILT', result.stdout)

    def test_cli_rejects_duplicate_foreign_dev_export_invalid_jobs_and_external_input_mode(self):
        for args in [('--validate-lock', '--jobs', '0'), ('--validate-lock', '--jobs', '33'),
                     ('--validate-lock', '--export-dev-package', 'libc6-dev', '--export-dev-package', 'libc6-dev'),
                     ('--validate-lock', '--export-dev-package', 'gcc'), ('--validate-inputs',),
                     ('--validate-lock', '--lock', 'untrusted.json')]:
            with self.subTest(args=args): self.assertNotEqual(0, self.cli(*args).returncode)


if __name__ == '__main__':
    unittest.main()

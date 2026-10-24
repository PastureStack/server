"""Focused, network-free checks for the pinned PCRE2 source-build boundary."""
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock
import urllib.request

HERE = Path(__file__).resolve().parent
sys.dont_write_bytecode = True
SPEC = importlib.util.spec_from_file_location('pcre2_backport', HERE / 'build-pcre2-backport.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class Pcre2Backport(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='pcre2-backport-contract-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.lock = MODULE.load_lock(HERE / 'pcre2.lock.json')

    def load(self, value):
        file = self.root / 'fixture.lock.json'
        file.write_text(json.dumps(value), encoding='utf-8')
        return MODULE.load_lock(file)

    def test_locked_official_sources_and_complete_approved_boundary(self):
        self.assertEqual('0e10c366d10e72b6940fcf37b61c2309d0136e05edff7adb1843030c0765f155',
                         self.lock['sourceFiles'][0]['sha256'])
        self.assertEqual(12, len(self.lock['patches']))
        self.assertEqual(8, len(self.lock['fixedCves']))
        self.assertEqual(MODULE.PACKAGES, self.lock['runtimePackages'])
        self.assertEqual('947809f11e9c9744aa0974b4b630a1ae461733dd',
                         self.lock['patches'][-1]['commit'])

    def test_foreign_source_version_architecture_or_package_set_fails(self):
        for field, bad in [('ubuntuSourceVersion', '10.49-1'), ('customVersion', '10.46-1build1'),
                           ('architecture', 'arm64'), ('runtimePackages', ['libpcre2-8-0']),
                           ('fixedCves', ['CVE-2026-103111']),
                           ('sourceDateEpoch', True)]:
            with self.subTest(field=field):
                altered = copy.deepcopy(self.lock)
                altered[field] = bad
                with self.assertRaises(ValueError): self.load(altered)

    def test_missing_duplicate_or_unpinned_patch_is_rejected(self):
        for mutation in ['missing', 'duplicate', 'hash', 'commit', 'path', 'url']:
            with self.subTest(mutation=mutation):
                altered = copy.deepcopy(self.lock)
                if mutation == 'missing': altered['patches'].pop(0)
                if mutation == 'duplicate': altered['patches'][1] = altered['patches'][0]
                if mutation == 'hash': altered['patches'][0]['sha256'] = ''
                if mutation == 'commit': altered['patches'][0]['commit'] = '16c1b6f'
                if mutation == 'path': altered['patches'][0]['name'] = '../outside.patch'
                if mutation == 'url': altered['patches'][0]['url'] = 'http://untrusted.invalid/patch'
                with self.assertRaises(ValueError): self.load(altered)

    def test_source_set_and_source_url_cannot_be_replaced(self):
        for mutation in ['missing', 'url', 'duplicate']:
            with self.subTest(mutation=mutation):
                altered = copy.deepcopy(self.lock)
                if mutation == 'missing': altered['sourceFiles'].pop()
                if mutation == 'duplicate': altered['sourceFiles'][1] = altered['sourceFiles'][0]
                if mutation == 'url': altered['sourceFiles'][0]['url'] = 'https://example.invalid/source.dsc'
                with self.assertRaises(ValueError): self.load(altered)

    def test_cached_bytes_are_verified_and_tamper_never_fetches(self):
        cache, output = self.root / 'cache', self.root / 'input'
        cache.mkdir(); output.mkdir()
        data = b'official fixture bytes\n'
        item = {'name': 'input.patch', 'url': 'https://example.invalid/never-requested',
                'sha256': hashlib.sha256(data).hexdigest(), 'size': len(data)}
        cached = cache / item['name']; cached.write_bytes(data)
        with mock.patch.object(urllib.request, 'build_opener') as network:
            self.assertEqual(data, MODULE.download(item, output, cache).read_bytes())
            cached.write_bytes(data + b'tampered')
            with self.assertRaises(ValueError): MODULE.download(item, output, cache)
            network.assert_not_called()

    def test_https_redirect_cannot_downgrade(self):
        request = urllib.request.Request('https://github.com/official/patch')
        with self.assertRaises(ValueError):
            MODULE.HttpsRedirect().redirect_request(request, None, 302, 'Found', {},
                                                    'http://example.invalid/patch')

    def source_control(self):
        inputs = [item for item in self.lock['sourceFiles'] if not item['name'].endswith('.dsc')]
        return ('Format: 1.0\nSource: pcre2\nVersion: 10.46-1build1\nChecksums-Sha256:\n' +
                ''.join(' {sha256} {size} {name}\n'.format(**item) for item in inputs))

    def test_dsc_binds_original_and_debian_source_checksums(self):
        file = self.root / 'pcre2_10.46-1build1.dsc'
        original = self.source_control()
        file.write_text(original, encoding='utf-8')
        MODULE.verify_source_control(self.lock, self.root)
        for altered in [original.replace('10.46-1build1\n', '10.49-1\n'),
                        original.replace(self.lock['sourceFiles'][1]['sha256'], '0' * 64),
                        original.replace('Source: pcre2', 'Source: other'),
                        original.rsplit('\n', 2)[0] + '\n']:
            with self.subTest(altered=altered):
                file.write_text(altered, encoding='utf-8')
                with self.assertRaises(ValueError): MODULE.verify_source_control(self.lock, self.root)

    def test_lifecycle_set_and_order_must_match(self):
        section = ('### PCRE2 10.46 release\nBackports to apply:\n' + ''.join(
            '* `patches/' + item['name'] + '`\n' for item in self.lock['patches']) + '### PCRE2 10.47\n')
        MODULE.verify_supported_patches(self.lock, section)
        with self.assertRaises(ValueError):
            MODULE.verify_supported_patches(self.lock, section.replace(
                self.lock['patches'][0]['name'], 'unapproved.patch'))
        reversed_lock = copy.deepcopy(self.lock)
        reversed_lock['patches'].reverse()
        with self.assertRaises(ValueError): MODULE.verify_supported_patches(reversed_lock, section)

    def test_patch_identity_and_packaging_boundary(self):
        item = self.lock['patches'][0]
        file = self.root / 'input.patch'
        original = ('From ' + item['commit'] + ' Mon Sep 17 00:00:00 2001\n'
                    'diff --git a/src/pcre2_match.c b/src/pcre2_match.c\n')
        file.write_text(original, encoding='utf-8')
        MODULE.verify_patch(item, file)
        for altered in [original.replace(item['commit'], '0' * 40),
                        original.replace('src/pcre2_match.c', 'debian/rules'),
                        original.replace('src/pcre2_match.c', 'src/../../outside')]:
            file.write_text(altered, encoding='utf-8')
            with self.assertRaises(ValueError): MODULE.verify_patch(item, file)

    def test_inherited_environment_cannot_skip_tests_or_replace_flags(self):
        with mock.patch.dict(os.environ, {'DEB_BUILD_OPTIONS': 'nocheck noopt',
                                         'DEB_BUILD_PROFILES': 'nocheck', 'CFLAGS': '-O0',
                                         'DEB_CFLAGS_MAINT_APPEND': '-Dunsafe=1'}):
            environment = MODULE.build_environment(self.lock, 2)
        self.assertEqual('parallel=2', environment['DEB_BUILD_OPTIONS'])
        self.assertEqual('', environment['DEB_BUILD_PROFILES'])
        self.assertEqual('hardening=+all', environment['DEB_BUILD_MAINT_OPTIONS'])
        self.assertEqual(str(self.lock['sourceDateEpoch']), environment['SOURCE_DATE_EPOCH'])
        self.assertNotIn('CFLAGS', environment)
        self.assertNotIn('DEB_CFLAGS_MAINT_APPEND', environment)

    def test_native_pass_receipt_requires_every_real_test_report(self):
        for name in MODULE.TESTS:
            (self.root / (name + '.trs')).write_text(':test-result: PASS\n', encoding='utf-8')
        self.assertEqual(3, len(MODULE.test_receipt(self.root)))
        file = self.root / 'RunTest.trs'
        for result in ['FAIL', 'SKIP', 'XFAIL', 'ERROR']:
            file.write_text(':test-result: ' + result + '\n', encoding='utf-8')
            with self.assertRaises(ValueError): MODULE.test_receipt(self.root)
        file.unlink()
        with self.assertRaises(ValueError): MODULE.test_receipt(self.root)

    def test_original_packaging_snapshot_excludes_only_changelog(self):
        debian = self.root / 'debian'; debian.mkdir()
        (debian / 'rules').write_bytes(b'original rules\n')
        (debian / 'copyright').write_bytes(b'original copyright\n')
        (debian / 'changelog').write_bytes(b'original changelog\n')
        before = MODULE.packaging_snapshot(self.root)
        (debian / 'changelog').write_bytes(b'first-party rebuild entry\n')
        self.assertEqual(before, MODULE.packaging_snapshot(self.root))
        (debian / 'rules').write_bytes(b'--disable-jit\n')
        self.assertNotEqual(before, MODULE.packaging_snapshot(self.root))

    def test_output_cannot_overlap_build_or_download_cache(self):
        MODULE.require_separate_paths(self.root / 'out', self.root / 'build', self.root / 'cache')
        for other in [self.root / 'out', self.root / 'out/nested', self.root]:
            with self.subTest(other=other):
                with self.assertRaises(ValueError):
                    MODULE.require_separate_paths(self.root / 'out', other, None)
                with self.assertRaises(ValueError):
                    MODULE.require_separate_paths(self.root / 'out', None, other)


if __name__ == '__main__':
    unittest.main()

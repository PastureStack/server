#!/usr/bin/env python3
import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('package_consistency', Path(__file__).with_name('check-agent-package-consistency.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PackageConsistencyTests(unittest.TestCase):
    def setUp(self):
        self.data = {}
        self.versions = {'libc6': '2.43-2ubuntu2.4+pasturestack.1', 'libc-bin': '2.43-2ubuntu2.4+pasturestack.1',
                         'libc-gconv-modules-extra': '2.43-2ubuntu2.4+pasturestack.1',
                         'libpcre2-8-0': '10.46-1build1+pasturestack.1', 'libpcre2-posix3': '10.46-1build1+pasturestack.1',
                         'rust-coreutils': '0.10.0-1ubuntu2~26.04.1+pasturestack.1', 'jq': '1.8.2-0pasturestack1~26.04.1',
                         'libjq1': '1.8.2-0pasturestack1~26.04.1', 'p11-kit': '0.26.2-2+pasturestack.1',
                         'p11-kit-modules': '0.26.2-2+pasturestack.1', 'libp11-kit0': '0.26.2-2+pasturestack.1',
                         'libxrender1': '1:0.9.12-1build1+pasturestack.1'}
        self.builder = {'libc6': '2.43-2ubuntu2.4', 'libpcre2-8-0': '10.46-1build1',
                        'libssl3t64': '3.5.5-1ubuntu3.7', 'curl': '8.18.0-1ubuntu2.8',
                        'ca-certificates': '20260816ubuntu0.26.04.1', 'zlib1g': '1.3.1'}
        self.runtime = dict(self.builder, libc6=self.versions['libc6'])
        self.runtime['libpcre2-8-0'] = self.versions['libpcre2-8-0']
        self.receipt = {'schemaVersion': 1, 'bundleVersion': '0.1.0', 'status': 'installed-and-verified',
                        'providerPreserved': True, 'configurationPreserved': True,
                        'packages': ['libc6', 'libpcre2-8-0']}
        qualification = {'status': 'qualified', 'consumerFixtures': [
            {'provider': 'gnu', 'status': 'PASS'}, {'provider': 'uutils', 'status': 'PASS'}]}
        content = (json.dumps(qualification) + '\n').encode()
        self.data['backports-qualification.json'] = content.decode('utf-8')
        self.manifest = {'schemaVersion': 1, 'bundleVersion': '0.1.0',
                         'platform': {'distribution': 'ubuntu', 'release': '26.04', 'architecture': 'amd64'},
                         'qualification': {'sha256': hashlib.sha256(content).hexdigest()},
                         'packages': [{'name': name, 'version': version} for name, version in self.versions.items()]}

    def verify(self):
        for filename, data in [('backports-manifest.json', self.manifest), ('backports-install.json', self.receipt)]:
            self.data[filename] = json.dumps(data)
        for filename, data in [('builder-packages.tsv', self.builder), ('runtime-packages.tsv', self.runtime)]:
            self.data[filename] = ''.join(name + '\t' + version + '\n' for name, version in data.items())
        return module.verify(self.data)

    def test_only_qualified_final_runtime_differences_pass(self):
        self.assertEqual(self.verify()['qualified_runtime_deltas'], ['libc6', 'libpcre2-8-0'])
        self.assertEqual(self.builder['libc6'], '2.43-2ubuntu2.4')

    def test_unrelated_drift_is_rejected(self):
        self.runtime['zlib1g'] = 'unexpected'
        with self.assertRaisesRegex(ValueError, 'Unrelated'): self.verify()

    def test_nonqualified_library_version_is_rejected(self):
        self.runtime['libc6'] = '2.44'
        with self.assertRaisesRegex(ValueError, 'Unqualified'): self.verify()

    def test_builder_changes_are_not_a_workaround(self):
        self.builder['libc6'] = self.versions['libc6']
        with self.assertRaisesRegex(ValueError, 'Python-builder'): self.verify()

    def test_false_selection_or_provider_proof_is_rejected(self):
        original = copy.deepcopy(self.receipt)
        for mutate in [lambda r: r['packages'].append('jq'), lambda r: r.update(providerPreserved=False)]:
            self.receipt = copy.deepcopy(original)
            mutate(self.receipt)
            with self.assertRaises(ValueError): self.verify()

    def test_changed_qualification_is_rejected(self):
        self.data['backports-qualification.json'] = '{}'
        with self.assertRaisesRegex(ValueError, 'checksum'): self.verify()

    def test_published_wrapper_keeps_its_original_strict_contract(self):
        self.runtime = dict(self.builder)
        self.verify_files_only()
        self.assertTrue(module.verify_legacy_wrapper(self.data)['expected_security_packages'])
        self.runtime['libc6'] = self.versions['libc6']
        self.verify_files_only()
        with self.assertRaisesRegex(ValueError, 'drift'):
            module.verify_legacy_wrapper(self.data)

    def verify_files_only(self):
        for filename, data in [('builder-packages.tsv', self.builder), ('runtime-packages.tsv', self.runtime)]:
            self.data[filename] = ''.join(name + '\t' + version + '\n' for name, version in data.items())

    def test_inventory_text_preserves_bytes_and_rejects_malformed_rows(self):
        result = self.verify()
        self.assertEqual(result['backport_manifest_sha256'], hashlib.sha256(
            self.data['backports-manifest.json'].encode('utf-8')).hexdigest())
        with self.assertRaisesRegex(ValueError, 'Malformed'):
            module.inventory('libc6\tversion\textra\n')
        with self.assertRaisesRegex(ValueError, 'Duplicate'):
            module.inventory('libc6\tversion\nlibc6:amd64\tversion\n')


if __name__ == '__main__':
    unittest.main(verbosity=2)

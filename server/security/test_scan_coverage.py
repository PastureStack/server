import copy
import hashlib
import re
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from check_scan_coverage import (validate_coverage, validate_vex_payloads,
    ROOT_BINARIES, NESTED_BINARIES, OPENPGP_VEX_SCOPE, OPENPGP_VEX_BINARY_SHA256)


class CoverageTest(unittest.TestCase):
    def fixture(self, names):
        return {'SchemaVersion': 2, 'Results': [
            {'Target': 'usr/bin/' + name, 'Type': 'gobinary',
             'Packages': [{'Name': 'stdlib', 'Version': 'v1.27.3'}]}
            for name in sorted(names)
        ]}

    def test_expected_root_and_nested_are_analyzed(self):
        for names in (ROOT_BINARIES, NESTED_BINARIES):
            self.assertEqual(validate_coverage(self.fixture(names), names), len(names))

    def test_missing_go_binary_blocks(self):
        report = self.fixture(ROOT_BINARIES)
        report['Results'].pop()
        with self.assertRaisesRegex(ValueError, 'Missing active'):
            validate_coverage(report, ROOT_BINARIES)

    def test_machine_and_packet_payloads_cannot_escape_scanning(self):
        machines = {'docker-machine', 'docker-machine-driver-packet'}
        self.assertTrue(machines.issubset(ROOT_BINARIES))
        for missing in machines:
            with self.subTest(missing=missing), self.assertRaisesRegex(ValueError, 'Missing active'):
                validate_coverage(self.fixture(ROOT_BINARIES - {missing}), ROOT_BINARIES)

    def test_empty_or_missing_packages_blocks(self):
        for packages in (None, [], {}):
            report = self.fixture(NESTED_BINARIES)
            report['Results'][0]['Packages'] = packages
            with self.assertRaisesRegex(ValueError, 'dependency analysis'):
                validate_coverage(report, NESTED_BINARIES)

    def test_os_only_scan_cannot_pass(self):
        report = {'SchemaVersion': 2, 'Results': [
            {'Target': '/rootfs', 'Type': 'ubuntu', 'Packages': [{'Name': 'libc6'}]}]}
        with self.assertRaisesRegex(ValueError, 'Missing active'):
            validate_coverage(report, ROOT_BINARIES)

    def test_schema_or_empty_results_blocks(self):
        for report in ({}, {'SchemaVersion': 2, 'Results': []}):
            with self.assertRaises(ValueError):
                validate_coverage(report, ROOT_BINARIES)

    def test_scan_is_not_mutated(self):
        report = self.fixture(ROOT_BINARIES)
        original = copy.deepcopy(report)
        validate_coverage(report, ROOT_BINARIES)
        self.assertEqual(report, original)

    def test_reviewed_openpgp_module_occurrences_are_allowed(self):
        report = self.fixture(ROOT_BINARIES)
        for target, purl in OPENPGP_VEX_SCOPE:
            result = next(item for item in report['Results'] if item['Target'] == target)
            result['Vulnerabilities'] = [{'VulnerabilityID': 'GO-2026-5932',
                                         'PkgIdentifier': {'PURL': purl}}]
        self.assertEqual(validate_coverage(report, ROOT_BINARIES), len(ROOT_BINARIES))

    def test_unreviewed_openpgp_target_or_version_blocks_before_vex(self):
        for target, purl in (
                ('usr/bin/govc', 'pkg:golang/golang.org/x/crypto@v0.57.0'),
                ('usr/bin/docker-machine', 'pkg:golang/golang.org/x/crypto@v0.57.0'),
                ('usr/bin/docker-machine', 'pkg:golang/golang.org/x/crypto@v0.59.0'),
                ('tmp/docker-machine', 'pkg:golang/golang.org/x/crypto@v0.57.0'),
                ('usr/bin/docker-machine', None)):
            with self.subTest(target=target, purl=purl):
                report = self.fixture(ROOT_BINARIES)
                report['Results'].append({'Target': target, 'Type': 'gobinary',
                    'Packages': [{'Name': 'golang.org/x/crypto', 'Version': 'v0.57.0'}],
                    'Vulnerabilities': [{'VulnerabilityID': 'GO-2026-5932',
                                        'PkgIdentifier': {'PURL': purl}}]})
                with self.assertRaisesRegex(ValueError, 'Unreviewed OpenPGP'):
                    validate_coverage(report, ROOT_BINARIES)

    def test_vex_requires_reviewed_binary_bytes_and_path(self):
        target = 'usr/bin/docker-machine'
        report = {'Results': [{'Target': target, 'Vulnerabilities': [
            {'VulnerabilityID': 'GO-2026-5932'}]}]}
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            payload = root / target
            payload.parent.mkdir(parents=True)
            payload.write_bytes(b'reviewed-fixture')
            expected = hashlib.sha256(b'reviewed-fixture').hexdigest()
            with patch.dict('check_scan_coverage.OPENPGP_VEX_BINARY_SHA256', {target: expected}):
                self.assertEqual(validate_vex_payloads(report, root), 1)
                payload.write_bytes(b'changed-fixture')
                with self.assertRaisesRegex(ValueError, 'Changed OpenPGP'):
                    validate_vex_payloads(report, root)
                payload.unlink()
                with self.assertRaisesRegex(ValueError, 'Unreviewed OpenPGP'):
                    validate_vex_payloads(report, root)
            report['Results'][0]['Target'] = '../unreviewed'
            with self.assertRaisesRegex(ValueError, 'Unreviewed OpenPGP'):
                validate_vex_payloads(report, root)

    def test_reviewed_openpgp_hashes_match_the_actual_producer_pins(self):
        recipe = (Path(__file__).resolve().parents[1] / 'Dockerfile.web-compose-release').read_text(encoding='utf-8')
        pins = {
            'usr/bin/authentication-service.real': 'AUTHENTICATION_SERVICE_BINARY_SHA256',
            'usr/bin/docker-machine': 'MACHINE_DRIVER_BINARY_SHA256',
            'usr/bin/docker-machine-driver-packet': 'PACKET_DRIVER_BINARY_SHA256',
            'usr/bin/compose-executor.real': 'COMPOSE_EXECUTOR_BINARY_SHA256',
            'usr/bin/host-provisioner.real': 'HOST_PROVISIONER_BINARY_SHA256',
        }
        self.assertEqual(set(OPENPGP_VEX_BINARY_SHA256), set(pins))
        for target, name in pins.items():
            with self.subTest(target=target):
                actual = set(re.findall(r'^ARG ' + name + r'=([0-9a-f]{64})$', recipe, re.M))
                self.assertEqual({OPENPGP_VEX_BINARY_SHA256[target]}, actual)

    def test_clean_null_vulnerabilities_need_no_exception(self):
        report = self.fixture(ROOT_BINARIES)
        for result in report['Results']:
            result['Vulnerabilities'] = None
        self.assertEqual(validate_coverage(report, ROOT_BINARIES), len(ROOT_BINARIES))
        with tempfile.TemporaryDirectory() as folder:
            self.assertEqual(validate_vex_payloads(report, Path(folder)), 0)


if __name__ == '__main__':
    unittest.main()

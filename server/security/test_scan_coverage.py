import copy
import unittest

from check_scan_coverage import validate_coverage, ROOT_BINARIES, NESTED_BINARIES


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


if __name__ == '__main__':
    unittest.main()

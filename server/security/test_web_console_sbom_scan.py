import copy
import json
from pathlib import Path
import subprocess
import tempfile
import sys
import unittest

from check_web_console_sbom_scan import inspect, TRIVY_IMAGE


ROOT = Path(__file__).resolve().parents[2]


class BrowserScanCoverage(unittest.TestCase):
    def fixture(self):
        sbom = {'bomFormat': 'CycloneDX', 'metadata': {'properties': [
            {'name': 'pasturestack:phase', 'value': 'runtime'},
            {'name': 'pasturestack:coverage', 'value': 'incomplete'}]},
            'components': [
                {'type': 'library', 'name': '@example/library', 'version': '1.2.3',
                 'bom-ref': 'npm:library', 'purl': 'pkg:npm/%40example/library@1.2.3'},
                {'type': 'library', 'name': 'opaque-vendor', 'version': 'snapshot-sha256-' + 'b' * 64,
                 'bom-ref': 'vendor:opaque', 'properties': [
                     {'name': 'pasturestack:source-set-sha256', 'value': 'b' * 64}]},
                {'type': 'file', 'name': 'assets/application.js', 'bom-ref': 'file:application',
                 'hashes': [{'alg': 'SHA-256', 'content': 'c' * 64}]},
            ]}
        report = {'SchemaVersion': 2, 'CreatedAt': '2026-10-24T05:00:00Z',
                  'Trivy': {'Version': '0.74.0'}, 'Results': [
            {'Type': 'node-pkg', 'Target': 'Node.js', 'Packages': [
                {'Name': '@example/library', 'Version': '1.2.3',
                 'Identifier': {'PURL': 'pkg:npm/%40example/library@1.2.3'}}]}]}
        db = {'Version': 2, 'UpdatedAt': '2026-10-24T04:00:00Z',
              'NextUpdate': '2026-10-25T04:00:00Z'}
        return sbom, report, db

    def analyze(self, sbom=None, report=None, db=None, image=TRIVY_IMAGE):
        original = self.fixture()
        return inspect(sbom or original[0], report or original[1], db or original[2],
                       scanner_image=image, database_sha256='d' * 64)

    def test_npm_lookup_and_unsupported_snapshot_are_distinguished(self):
        source = self.fixture()
        retained = copy.deepcopy(source)
        coverage, rows = self.analyze(*source)
        self.assertEqual(coverage['blockingErrors'], [])
        self.assertEqual(coverage['npm']['recognizedComponentCount'], 1)
        self.assertEqual(coverage['coverage'], 'incomplete')
        self.assertEqual(coverage['unsupportedComponents'][0]['name'], 'opaque-vendor')
        self.assertEqual(coverage['unsupportedComponents'][0]['ref'], 'vendor:opaque')
        self.assertEqual(coverage['unsupportedComponents'][0]['sourceHashProperties'][0]['value'], 'b' * 64)
        self.assertEqual(coverage['artifactFiles']['count'], 1)
        self.assertEqual(rows, [])
        self.assertEqual(source, retained)

    def test_empty_or_wrong_type_or_wrong_version_lookup_blocks(self):
        for mutation in ('empty', 'type', 'version', 'purl'):
            sbom, report, db = self.fixture()
            if mutation == 'empty':
                report['Results'] = []
            elif mutation == 'type':
                report['Results'][0]['Type'] = 'ubuntu'
            elif mutation == 'version':
                report['Results'][0]['Packages'][0]['Identifier']['PURL'] = 'pkg:npm/%40example/library@1.2.4'
            else:
                del report['Results'][0]['Packages'][0]['Identifier']
            with self.subTest(mutation=mutation):
                coverage, _ = self.analyze(sbom, report, db)
                self.assertIn('Missing npm purl vulnerability lookup coverage', coverage['blockingErrors'])

    def test_unknown_schema_or_scanner_or_stale_db_blocks(self):
        for mutation in ('schema', 'scanner', 'db-expired', 'db-future', 'db-no-time', 'image'):
            sbom, report, db = self.fixture()
            image = TRIVY_IMAGE
            if mutation == 'schema': report['SchemaVersion'] = 1
            if mutation == 'scanner': report['Trivy']['Version'] = '0.73.0'
            if mutation == 'db-expired': db['NextUpdate'] = '2026-10-24T04:30:00Z'
            if mutation == 'db-future': db['UpdatedAt'] = '2026-10-24T06:00:00Z'
            if mutation == 'db-no-time': db.pop('NextUpdate')
            if mutation == 'image': image = 'trivy:latest'
            with self.subTest(mutation=mutation):
                self.assertTrue(self.analyze(sbom, report, db, image)[0]['blockingErrors'])

    def test_build_inventory_or_duplicate_ref_blocks(self):
        for mutation in ('phase', 'component-phase', 'duplicate'):
            sbom, report, db = self.fixture()
            if mutation == 'phase': sbom['metadata']['properties'][0]['value'] = 'build'
            if mutation == 'component-phase': sbom['components'][0]['properties'] = [
                {'name': 'pasturestack:phase', 'value': 'build'}]
            if mutation == 'duplicate': sbom['components'].append(copy.deepcopy(sbom['components'][0]))
            with self.subTest(mutation=mutation):
                self.assertTrue(self.analyze(sbom, report, db)[0]['blockingErrors'])

    def test_all_findings_keep_browser_target_and_original_fix_status(self):
        sbom, report, db = self.fixture()
        report['Results'][0]['Vulnerabilities'] = [{
            'Severity': 'HIGH', 'VulnerabilityID': 'CVE-2026-99999',
            'PkgName': '@example/library', 'InstalledVersion': '1.2.3', 'FixedVersion': '1.2.4'}]
        coverage, rows = self.analyze(sbom, report, db)
        self.assertEqual(coverage['blockingErrors'], [])
        self.assertEqual(rows, ['HIGH\tCVE-2026-99999\t@example/library\t1.2.3\t1.2.4\tbrowser-runtime-sbom/node-pkg/Node.js'])
        self.assertEqual(coverage['effectiveDisposition'], 'identical-to-raw; no browser exceptions or OS VEX applied')

    def test_browser_findings_cannot_inherit_an_os_ledger_exception(self):
        tracker = json.loads((ROOT / 'server/security/vendor-pending.json').read_text())
        expected = []
        for finding in tracker['findings']:
            for package in finding['packages']:
                expected.append('\t'.join([finding['severity'], finding['vulnerabilityId'],
                    package['name'], package['installedVersion'], '', tracker['policy']['trivyTarget']]))
        first = expected[0].split('\t')
        for severity, fixed in (('HIGH', ''), ('CRITICAL', ''), ('LOW', 'official-fix'), ('LOW', ''), ('MEDIUM', '')):
            row = first.copy()
            row[0], row[4], row[5] = severity, fixed, 'browser-runtime-sbom/node-pkg/Node.js'
            with self.subTest(severity=severity, fixed=fixed), tempfile.TemporaryDirectory() as folder:
                unresolved = Path(folder) / 'unresolved.tsv'
                unresolved.write_text('\n'.join(expected + ['\t'.join(row)]) + '\n')
                result = subprocess.run(['bash', str(ROOT / 'scripts/validate-vendor-pending-findings.sh'),
                    str(ROOT / 'server/security/vendor-pending.json'), str(unresolved), tracker['release']],
                    capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_cli_preserves_raw_bytes_and_retains_missing_coverage_failure(self):
        with tempfile.TemporaryDirectory() as folder:
            directory = Path(folder)
            sbom, report, db = self.fixture()
            for name, data in (('bom.json', sbom), ('scan.json', report), ('db.json', db)):
                (directory / name).write_text(json.dumps(data) + '\n')
            (directory / 'db.bin').write_bytes(b'fixture-database')
            command = [sys.executable, str(Path(__file__).with_name('check_web_console_sbom_scan.py')),
                '--sbom', str(directory / 'bom.json'), '--scan', str(directory / 'scan.json'),
                '--effective', str(directory / 'effective.json'), '--coverage', str(directory / 'coverage.json'),
                '--findings', str(directory / 'findings.tsv'), '--db-metadata', str(directory / 'db.json'),
                '--db-file', str(directory / 'db.bin'), '--scanner-image', TRIVY_IMAGE]
            result = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((directory / 'effective.json').read_bytes(), (directory / 'scan.json').read_bytes())
            saved = json.loads((directory / 'coverage.json').read_text())
            self.assertEqual(saved['rawReportSha256'], saved['effectiveReportSha256'])
            self.assertEqual(saved['coverage'], 'incomplete')
            report['Results'][0]['Packages'] = []
            (directory / 'scan.json').write_text(json.dumps(report) + '\n')
            result = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(result.returncode, 1)
            self.assertIn('Missing npm purl', result.stderr)
            saved = json.loads((directory / 'coverage.json').read_text())
            self.assertTrue(saved['blockingErrors'])


if __name__ == '__main__':
    unittest.main(verbosity=2)

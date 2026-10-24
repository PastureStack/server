"""Exercise exact Web Console archive/SBOM identity and fail-closed handling."""

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
VERIFIER = ROOT / 'server/artifacts/verify-web-console-sbom.py'
spec = importlib.util.spec_from_file_location('verify_web_console_sbom', VERIFIER)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class WebConsoleSbom(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.sbom = Path(self.temp.name) / 'runtime.cdx.json'
        self.archive = Path(self.temp.name) / 'web-console-1.6.195.tar.gz'
        self.archive.write_bytes(b'exact Web195 archive fixture')
        self.archive_hash = hashlib.sha256(self.archive.read_bytes()).hexdigest()
        self.version = '1.6.195'
        self.source = '1' * 40
        self.lock = '2' * 64
        self.data = {
            'bomFormat': 'CycloneDX', 'specVersion': '1.6', 'version': 1,
            'metadata': {
                'component': {
                    'type': 'application', 'name': '@pasturestack/web-console',
                    'version': self.version,
                    'purl': f'pkg:npm/%40pasturestack/web-console@{self.version}',
                    'bom-ref': f'artifact:{self.archive.name}',
                    'hashes': [{'alg': 'SHA-256', 'content': self.archive_hash}],
                },
                'properties': [{'name': name, 'value': value} for name, value in {
                    'pasturestack:source-commit': self.source,
                    'pasturestack:lock-sha256': self.lock,
                    'pasturestack:archive-name': self.archive.name,
                    'pasturestack:archive-sha256': self.archive_hash,
                    'pasturestack:phase': 'runtime',
                    'pasturestack:coverage': 'incomplete',
                }.items()],
            },
            'components': [{'type': 'library', 'name': 'observed-browser-module'}],
            'compositions': [{'aggregate': 'incomplete'}],
        }
        self.write()

    def write(self, data=None):
        self.sbom.write_text(json.dumps(data or self.data) + '\n', encoding='utf-8')
        self.options = {
            'sbom_sha256': hashlib.sha256(self.sbom.read_bytes()).hexdigest(),
            'version': self.version, 'source_commit': self.source,
            'archive_name': self.archive.name, 'archive_sha256': self.archive_hash,
            'lock_sha256': self.lock, 'archive': self.archive,
        }

    def verify(self, **changes):
        return module.verify(self.sbom, **(self.options | changes))

    def test_matching_bytes_and_incomplete_coverage_are_preserved(self):
        original = self.sbom.read_bytes()
        result = self.verify()
        self.assertEqual(result['coverage'], 'incomplete')
        self.assertEqual(result['phase'], 'runtime')
        self.assertEqual(self.sbom.read_bytes(), original)

    def test_missing_download_fails(self):
        self.sbom.unlink()
        with self.assertRaisesRegex(ValueError, 'MISSING_OR_LINKED'):
            self.verify()

    def test_tampered_download_fails(self):
        self.sbom.write_bytes(self.sbom.read_bytes() + b' ')
        with self.assertRaisesRegex(ValueError, 'SBOM_SHA256_MISMATCH'):
            self.verify()

    def test_tampered_archive_fails(self):
        self.archive.write_bytes(b'changed archive')
        with self.assertRaisesRegex(ValueError, 'ARCHIVE_SHA256_MISMATCH'):
            self.verify()

    def test_missing_archive_fails(self):
        self.archive.unlink()
        with self.assertRaisesRegex(ValueError, 'ARCHIVE_MISSING_OR_LINKED'):
            self.verify()

    def test_metadata_cannot_substitute_another_release_identity(self):
        changes = {
            'version': '1.6.194', 'source_commit': '3' * 40,
            'lock_sha256': '4' * 64, 'archive_sha256': '5' * 64,
            'archive_name': 'wrong.tar.gz',
        }
        for field, value in changes.items():
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.verify(**{field: value})

    def test_wrong_metadata_fails_even_with_matching_sbom_checksum(self):
        for name in ('pasturestack:source-commit', 'pasturestack:lock-sha256',
                     'pasturestack:archive-name', 'pasturestack:archive-sha256',
                     'pasturestack:phase'):
            with self.subTest(property=name):
                changed = copy.deepcopy(self.data)
                next(item for item in changed['metadata']['properties']
                     if item['name'] == name)['value'] = 'wrong'
                self.write(changed)
                with self.assertRaisesRegex(ValueError, 'PROPERTY_MISMATCH'):
                    self.verify()

    def test_wrong_component_version_or_archive_hash_fails(self):
        for field in ('version', 'purl', 'bom-ref', 'hashes'):
            with self.subTest(field=field):
                changed = copy.deepcopy(self.data)
                changed['metadata']['component'][field] = 'wrong'
                self.write(changed)
                with self.assertRaisesRegex(ValueError, 'COMPONENT_'):
                    self.verify()

    def test_build_phase_and_ambiguous_properties_fail(self):
        changed = copy.deepcopy(self.data)
        changed['metadata']['properties'].append({
            'name': 'pasturestack:phase', 'value': 'build'})
        self.write(changed)
        with self.assertRaisesRegex(ValueError, 'DUPLICATE_PROPERTY'):
            self.verify()

    def test_unpinned_sbom_and_missing_inventory_fail(self):
        with self.assertRaisesRegex(ValueError, 'INVALID_SHA256_PIN'):
            self.verify(sbom_sha256='')
        changed = copy.deepcopy(self.data)
        changed['components'] = []
        self.write(changed)
        with self.assertRaisesRegex(ValueError, 'INVENTORY_MISSING'):
            self.verify()

    def test_cli_success_and_failure_status(self):
        command = [sys.executable, str(VERIFIER), '--sbom', str(self.sbom)]
        for key, value in self.options.items():
            command.extend(['--' + key.replace('_', '-'), str(value)])
        result = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('phase=runtime coverage=incomplete', result.stdout)
        self.sbom.unlink()
        result = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn('WEB_CONSOLE_SBOM_REJECTED', result.stderr)


if __name__ == '__main__':
    unittest.main(verbosity=2)

#!/usr/bin/env python3
"""Offline nested-payload qualification, including fail-closed negative cases."""
import hashlib
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('nested', ROOT / 'server/artifacts/prepare-nested-agent-scan.py')
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)
SOURCE = 'a' * 40
PACKAGE = SOURCE[:32]
BINARY = b'controlled binary fixture, not executable'
INSTALL = b'controlled installer fixture, never executed'
CNI_BINARY = b'MZ' + b'\0' * 58 + (64).to_bytes(4, 'little') + b'PE\0\0\x64\x86' + b'\0' * 18 + b'\x0b\x02'


class NestedPayloads(unittest.TestCase):
    def test_entrypoint_rejects_arbitrary_path_arguments_before_filesystem_io(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'must-not-be-created'
            result = subprocess.run([sys.executable, str(SPEC.origin), temporary,
                                     temporary, str(target)], capture_output=True, text=True)
            self.assertNotEqual(0, result.returncode)
            self.assertIn('NO_PATH_ARGUMENTS_ACCEPTED', result.stderr)
            self.assertFalse(target.exists())

    def fixture(self, parent, duplicate=False):
        rootfs = parent / 'rootfs'
        folder = rootfs / 'usr/share/cattle/artifacts'
        folder.mkdir(parents=True)
        pins = {}
        for component, prefix, windows in (('host-api', 'HOST_API', False),
                ('node-agent', 'NODE_AGENT', False), ('node-agent', 'NODE_AGENT', True)):
            version = '0.38.6' if prefix == 'HOST_API' else '0.13.30'
            archive = folder / (component + '-' + version + ('-windows-amd64.zip' if windows else '.tar.gz'))
            if windows:
                with zipfile.ZipFile(archive, 'w') as stream:
                    stream.writestr('pasturestack/', b'')
                    stream.writestr('pasturestack/node-agent.exe', BINARY)
                    stream.writestr('pasturestack/startup_node-agent.ps1', INSTALL)
            else:
                with tarfile.open(archive, 'w:gz') as stream:
                    for name, data in ((PACKAGE + '/bin/' + component, BINARY), (PACKAGE + '/apply.sh', INSTALL)):
                        item = tarfile.TarInfo(name)
                        item.size = len(data)
                        stream.addfile(item, io.BytesIO(data))
                        if duplicate and component == 'host-api' and '/bin/' in name:
                            stream.addfile(item, io.BytesIO(data))
            pins.update({prefix + '_VERSION': version, prefix + '_COMMIT': SOURCE,
                         prefix + '_PACKAGE_ID': PACKAGE})
            key = prefix + ('_WINDOWS' if windows else '')
            pins[key + '_ARCHIVE_SHA256'] = M.digest(archive.read_bytes())
            pins[key + '_BINARY_SHA256'] = M.digest(BINARY)
            pins[key + ('_STARTUP_SHA256' if windows else '_APPLY_SHA256')] = M.digest(INSTALL)
        cni = folder / 'per-host-subnet-0.2.5-windows-amd64.zip'
        with zipfile.ZipFile(cni, 'w') as stream:
            stream.writestr('rancher/', b'')
            stream.writestr('rancher/per-host-subnet.exe', CNI_BINARY)
            stream.writestr('rancher/startup_per-host-subnet.ps1', INSTALL)
        pins.update(PER_HOST_SUBNET_VERSION='0.2.5', PER_HOST_SUBNET_PRODUCER_COMMIT=SOURCE,
                    PER_HOST_SUBNET_PROVENANCE_SHA256='b' * 64,
                    PER_HOST_SUBNET_ARCHIVE_SHA256=M.digest(cni.read_bytes()),
                    PER_HOST_SUBNET_BINARY_SHA256=M.digest(CNI_BINARY),
                    PER_HOST_SUBNET_STARTUP_SHA256=M.digest(INSTALL))
        return rootfs, pins

    def test_exact_four_final_payloads_without_execution(self):
        with tempfile.TemporaryDirectory() as temp:
            parent = Path(temp)
            rootfs, pins = self.fixture(parent)
            with patch.object(M, 'defaults', return_value=pins), patch.object(M, 'metadata') as inspect, patch.object(M, 'cni_metadata') as inspect_cni:
                result = M.prepare(rootfs, '', parent / 'out')
            self.assertEqual(result['payloadCount'], 4)
            self.assertEqual(inspect_cni.call_count, 1)
            self.assertEqual(inspect.call_count, 3)
            self.assertEqual({row['platform'] for row in result['records']}, {'linux/amd64', 'windows/amd64'})
            self.assertTrue(all(not row['payloadExecuted'] and row['binarySha256'] == M.digest(CNI_BINARY if row['component'] == 'per-host-subnet' else BINARY)
                                for row in result['records']))

    @unittest.skipUnless(os.name == 'posix', 'Executable mode is enforced by the Linux release gate')
    def test_prepared_files_have_owner_only_analyzer_mode(self):
        with tempfile.TemporaryDirectory() as temp:
            parent = Path(temp)
            rootfs, pins = self.fixture(parent)
            with patch.object(M, 'defaults', return_value=pins), patch.object(M, 'metadata'), patch.object(M, 'cni_metadata'):
                result = M.prepare(rootfs, '', parent / 'out')
            for row in result['records']:
                self.assertEqual((parent / 'out' / row['binary']).stat().st_mode & 0o777, 0o700)

    def test_actual_binary_scanner_and_inventory_count_are_mandatory(self):
        workflow = (ROOT / '.github/workflows/publish-current-server.yml').read_text(encoding='utf-8')
        self.assertIn('"$TRIVY_IMAGE" rootfs --scanners vuln,secret --format json', workflow)
        self.assertIn('"$TRIVY_IMAGE" rootfs --format cyclonedx', workflow)
        self.assertIn('select(.Type == "gobinary")] | length) == 4', workflow)

    def test_wrong_archive_binary_and_installer_hashes_rejected(self):
        for suffix in ('_ARCHIVE_SHA256', '_BINARY_SHA256', '_APPLY_SHA256'):
            with self.subTest(suffix=suffix), tempfile.TemporaryDirectory() as temp:
                parent = Path(temp)
                rootfs, pins = self.fixture(parent)
                pins['HOST_API' + suffix] = '0' * 64
                with patch.object(M, 'defaults', return_value=pins), patch.object(M, 'metadata'), self.assertRaisesRegex(ValueError, 'SHA256_MISMATCH'):
                    M.prepare(rootfs, '', parent / 'out')

    def test_duplicate_tar_binary_rejected_before_adoption(self):
        with tempfile.TemporaryDirectory() as temp:
            parent = Path(temp)
            rootfs, pins = self.fixture(parent, duplicate=True)
            with patch.object(M, 'defaults', return_value=pins), self.assertRaisesRegex(ValueError, 'UNIQUE_REGULAR'):
                M.prepare(rootfs, '', parent / 'out')

    def test_existing_output_and_non_numeric_version_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            parent = Path(temp)
            rootfs, pins = self.fixture(parent)
            output = parent / 'out'
            output.mkdir()
            with patch.object(M, 'defaults', return_value=pins), self.assertRaisesRegex(ValueError, 'NEW_PRIVATE_OUTPUT_REQUIRED'):
                M.prepare(rootfs, '', output)
            pins['HOST_API_VERSION'] = '../other'
            with patch.object(M, 'defaults', return_value=pins), self.assertRaisesRegex(ValueError, 'ONLY_ACTIVE_AGENT_BUNDLES_REQUIRED'):
                M.prepare(rootfs, '', parent / 'second')

    def test_superseded_or_missing_bundles_are_not_silently_unscanned(self):
        with tempfile.TemporaryDirectory() as temp:
            parent = Path(temp)
            rootfs, pins = self.fixture(parent)
            old = rootfs / 'usr/share/cattle/artifacts/host-api-0.38.5.tar.gz'
            old.write_bytes(b'old bundle that must not be silently delivered')
            with patch.object(M, 'defaults', return_value=pins), self.assertRaisesRegex(ValueError, 'ONLY_ACTIVE_AGENT_BUNDLES_REQUIRED'):
                M.prepare(rootfs, '', parent / 'out')
            old.unlink()
            (rootfs / 'usr/share/cattle/artifacts/node-agent-0.13.30-windows-amd64.zip').unlink()
            with patch.object(M, 'defaults', return_value=pins), self.assertRaisesRegex(ValueError, 'ONLY_ACTIVE_AGENT_BUNDLES_REQUIRED'):
                M.prepare(rootfs, '', parent / 'second')

    def test_conflicting_recipe_defaults_rejected(self):
        with self.assertRaisesRegex(ValueError, 'CONFLICTING_RECIPE_DEFAULT'):
            M.defaults('ARG HOST_API_VERSION=0.38.6\nARG HOST_API_VERSION=0.38.5\n')

    def test_old_go_wrong_source_platform_and_dirty_binary_rejected(self):
        expected = ['CGO_ENABLED=0', 'GOARCH=amd64', 'vcs.modified=false',
                    'vcs.revision=' + SOURCE, 'GOOS=linux']
        for bad in ('compiler', *expected):
            with self.subTest(bad=bad):
                fields = [field for field in expected if field != bad]
                text = 'fixture: go1.27.' + ('2' if bad == 'compiler' else '3') + '\n'
                text += ''.join('\tbuild\t' + value + '\n' for value in fields)
                with patch.object(M.subprocess, 'check_output', return_value=text), self.assertRaises(ValueError):
                    M.metadata(Path('not-executed'), SOURCE, False)

    def test_cni_metadata_requires_explicit_no_vcs_contract_without_relaxing_host_node(self):
        fields = ['CGO_ENABLED=0', 'GOARCH=amd64', 'GOOS=windows', 'GOAMD64=v1']
        text = 'cni.exe: go1.27.3\n' + ''.join('\tbuild\t' + field + '\n' for field in fields)
        with patch.object(M.subprocess, 'check_output', return_value=text):
            M.cni_metadata(Path('not-executed'))
            with self.assertRaisesRegex(ValueError, 'EXACT_BINARY_PRODUCER'):
                M.metadata(Path('host-node-not-executed'), SOURCE, True)
        for stamp in ('vcs=git', 'vcs.revision=' + SOURCE, 'vcs.modified=false', 'vcs.time=synthetic'):
            with patch.object(M.subprocess, 'check_output', return_value=text + '\tbuild\t' + stamp + '\n'):
                with self.assertRaisesRegex(ValueError, 'CNI_PRODUCER_NO_VCS'):
                    M.cni_metadata(Path('not-executed'))
        for bad in ('go1.27.2', 'GOOS=linux', 'GOARCH=arm64', 'CGO_ENABLED=1'):
            wrong = text.replace('go1.27.3', bad) if bad.startswith('go') else text.replace(
                next(field for field in fields if field.split('=')[0] == bad.split('=')[0]), bad)
            with patch.object(M.subprocess, 'check_output', return_value=wrong), self.assertRaises(ValueError):
                M.cni_metadata(Path('not-executed'))

    def test_cni_typed_legacy_layout_provenance_and_three_hashes_are_mandatory(self):
        for key in ('PER_HOST_SUBNET_ARCHIVE_SHA256', 'PER_HOST_SUBNET_BINARY_SHA256', 'PER_HOST_SUBNET_STARTUP_SHA256'):
            with self.subTest(key=key), tempfile.TemporaryDirectory() as temp:
                parent = Path(temp); rootfs, pins = self.fixture(parent); pins[key] = '0' * 64
                with patch.object(M, 'defaults', return_value=pins), patch.object(M, 'metadata'), self.assertRaisesRegex(ValueError, 'SHA256_MISMATCH'):
                    M.prepare(rootfs, '', parent / 'out')
        for key in ('PER_HOST_SUBNET_PRODUCER_COMMIT', 'PER_HOST_SUBNET_PROVENANCE_SHA256'):
            with self.subTest(key=key), tempfile.TemporaryDirectory() as temp:
                parent = Path(temp); rootfs, pins = self.fixture(parent); pins[key] = 'unverified'
                with patch.object(M, 'defaults', return_value=pins), patch.object(M, 'metadata'), self.assertRaisesRegex(ValueError, 'FORMAL_CNI_PROVENANCE_PINS_REQUIRED'):
                    M.prepare(rootfs, '', parent / 'out')
        with tempfile.TemporaryDirectory() as temp:
            parent = Path(temp); rootfs, pins = self.fixture(parent)
            with patch.object(M, 'defaults', return_value=pins), patch.object(M, 'metadata'), patch.object(M, 'cni_metadata'):
                records = M.prepare(rootfs, '', parent / 'out')['records']
            row = next(row for row in records if row['component'] == 'per-host-subnet')
            self.assertNotIn('source', row)
            self.assertEqual(row['producerSource'], SOURCE)
            self.assertEqual(row['provenanceReceiptSha256'], 'b' * 64)
            self.assertEqual(row['vcsMetadata'], 'ABSENT_BY_PRODUCER_BUILDVCS_FALSE_CONTRACT')
        with tempfile.TemporaryDirectory() as temp:
            parent = Path(temp); rootfs, pins = self.fixture(parent)
            archive = rootfs / 'usr/share/cattle/artifacts/per-host-subnet-0.2.5-windows-amd64.zip'
            with zipfile.ZipFile(archive, 'w') as stream:
                stream.writestr('../escape.exe', CNI_BINARY)
            pins['PER_HOST_SUBNET_ARCHIVE_SHA256'] = M.digest(archive.read_bytes())
            with patch.object(M, 'defaults', return_value=pins), patch.object(M, 'metadata'), self.assertRaisesRegex(ValueError, 'EXACT_WINDOWS_PACKAGE_LAYOUT'):
                M.prepare(rootfs, '', parent / 'out')
        for old_or_missing in ('old', 'missing'):
            with tempfile.TemporaryDirectory() as temp:
                parent = Path(temp); rootfs, pins = self.fixture(parent)
                folder = rootfs / 'usr/share/cattle/artifacts'
                if old_or_missing == 'old':
                    (folder / 'per-host-subnet-0.2.4-windows-amd64.zip').write_bytes(b'unscanned old CNI')
                else:
                    (folder / 'per-host-subnet-0.2.5-windows-amd64.zip').unlink()
                with patch.object(M, 'defaults', return_value=pins), self.assertRaisesRegex(ValueError, 'ONLY_ACTIVE_AGENT_BUNDLES'):
                    M.prepare(rootfs, '', parent / 'out')

    def test_windows_metadata_is_read_not_executed(self):
        text = 'fixture.exe: go1.27.3\n' + ''.join('\tbuild\t' + field + '\n' for field in (
            'CGO_ENABLED=0', 'GOARCH=amd64', 'vcs.modified=false', 'vcs.revision=' + SOURCE, 'GOOS=windows'))
        with patch.object(M.subprocess, 'check_output', return_value=text) as inspect:
            M.metadata(Path('fixture.exe'), SOURCE, True)
        self.assertEqual(inspect.call_args.args[0], ['go', 'version', '-m', 'fixture.exe'])


if __name__ == '__main__':
    unittest.main(verbosity=2)

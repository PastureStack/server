"""Only the new exact official replacement seam; a real checksum-pinned deb is required."""
import copy
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
BUNDLE = ROOT / 'server/security/ubuntu-backports/bundle'
spec = importlib.util.spec_from_file_location('existing_consumer_fixture', BUNDLE / 'test_verify_consumer_evidence.py')
fixture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fixture)
guard = fixture.guard


class OfficialBrotliTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='official-brotli-seam-')
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.root = self.work / 'rootfs'
        self.deb = (Path.cwd() / 'libbrotli1.deb').resolve(strict=True)
        self.lock = ROOT / 'server/security/official-brotli.lock.json'
        lock = json.loads(self.lock.read_bytes())
        self.assertEqual(guard.sha(self.deb.read_bytes()), lock['archiveSha256'])
        subprocess.run(['dpkg-deb', '-x', str(self.deb), str(self.root)], check=True)
        control = self.work / 'control'
        subprocess.run(['dpkg-deb', '-e', str(self.deb), str(control)], check=True)
        info = self.root / 'var/lib/dpkg/info'
        info.mkdir(parents=True)
        shutil.copyfile(control / 'md5sums', info / 'libbrotli1:amd64.md5sums')
        (info.parent / 'status').write_text('Package: libbrotli1\nStatus: install ok installed\n'
            'Source: brotli\nVersion: 1.2.0-3ubuntu0.1\nArchitecture: amd64\nDepends: libc6 (>= 2.29)\n\n')
        history = self.root / 'usr/share/pasturestack/security/brotli-official'
        history.mkdir(parents=True)
        (history / 'install.json').write_text(json.dumps({'schemaVersion': 1, 'status': 'installed-and-verified',
            'beforeVersion': lock['previousVersion'], 'version': lock['version'],
            'packageSetUnchanged': True, 'dpkgConfigurationUnchanged': True}))
        self.receipt = self.work / 'runtime.json'
        self.receipt.write_text(json.dumps({'schemaVersion': 1, 'status': 'verified', 'package': 'libbrotli1',
            'source': 'brotli', 'version': lock['version'], 'architecture': 'amd64', 'archiveSha256': lock['archiveSha256'],
            'dpkgVerify': 'PASS', 'linkage': 'PASS', 'sonames': {Path(p).name: lock['payloadSha256'][
                (Path(p).parent / target).as_posix()] for p, target in lock['symlinks'].items()}}))
        self.proof = {'rootfs': self.root, 'lock': self.lock, 'receipt': self.receipt, 'deb': self.deb,
                      'signedIndex': ROOT / 'server/security/official-brotli-evidence'}
        self.files, self.sbom = fixture.fixture()
        manifest = json.loads(self.files['manifest.json'])
        for family in manifest['families']:
            if family['name'] == 'brotli': family['version'] = lock['previousVersion']
        for package in manifest['packages']:
            if package['name'] == 'libbrotli1': package['version'] = lock['previousVersion']
        self.files['manifest.json'] = fixture.encoded(manifest)
        fixture.change(self.files, 'openvex.json', lambda value: value['statements'][0].update(
            products=[{'@id': guard.package_purl(p)} for p in manifest['packages']]))
        names = sorted(p['name'] for p in manifest['packages'])
        for name in ('install.json', 'verify.json'):
            fixture.change(self.files, name, lambda value: value.update(packages=names))
        self.old_sbom = {'bomFormat': 'CycloneDX', 'components': [{'name': p['name'], 'version': p['version'],
            'purl': guard.package_purl(p)} for p in manifest['packages']]}
        self.sbom = copy.deepcopy(self.old_sbom)
        package = next(p for p in self.sbom['components'] if p['name'] == 'libbrotli1')
        package.update(version=lock['version'], purl=guard.package_purl({'name': 'libbrotli1', 'version': lock['version']}))

    def verify(self, sbom=None, proof=None, files=None, producer=None):
        files = self.files if files is None else files
        return guard.verify(files, fixture.checksums(files), self.sbom if sbom is None else sbom,
            fixture.DIGEST, fixture.producer_checksums(files) if producer is None else producer,
            official_brotli=self.proof if proof is None else proof)

    def test_exact_real_deb_payload_and_final_sbom_pass_without_mutation(self):
        original = copy.deepcopy((self.files, self.sbom))
        result = self.verify()
        self.assertEqual(len(result['selectedPackages']), 13)
        self.assertEqual(result['officialReplacements'][0]['version'], '1.2.0-3ubuntu0.1')
        self.assertEqual((self.files, self.sbom), original)

    def test_boolean_incomplete_changed_lock_or_changed_deb_is_rejected(self):
        for proof in (True, False, {}, {'rootfs': self.root}):
            with self.subTest(proof=proof), self.assertRaises(ValueError): self.verify(proof=proof)
        changed = self.work / 'changed-lock.json'
        changed.write_bytes(self.lock.read_bytes() + b' ')
        with self.assertRaises(ValueError): self.verify(proof={**self.proof, 'lock': changed})
        changed = self.work / 'changed.deb'
        changed.write_bytes(b'not the official deb')
        with self.assertRaises(ValueError): self.verify(proof={**self.proof, 'deb': changed})
        changed = self.work / 'changed-index'
        shutil.copytree(self.proof['signedIndex'], changed)
        (changed / 'InRelease').write_bytes((changed / 'InRelease').read_bytes() + b' ')
        with self.assertRaises(ValueError): self.verify(proof={**self.proof, 'signedIndex': changed})

    def test_each_library_dpkg_state_or_final_receipt_tamper_is_rejected(self):
        lock = json.loads(self.lock.read_bytes())
        for relative in lock['payloadSha256']:
            path = self.root / relative
            original = path.read_bytes()
            path.write_bytes(original + b'corrupt')
            with self.subTest(path=relative), self.assertRaises(ValueError): self.verify()
            path.write_bytes(original)
        for path in (self.root / 'var/lib/dpkg/status', self.root / 'var/lib/dpkg/info/libbrotli1:amd64.md5sums', self.receipt):
            original = path.read_bytes()
            path.write_bytes(b'{}')
            with self.subTest(path=path.name), self.assertRaises(ValueError): self.verify()
            path.write_bytes(original)

    def test_symlink_escape_unverified_install_and_receipt_boolean_are_rejected(self):
        path = self.root / next(iter(json.loads(self.lock.read_bytes())['symlinks']))
        original = path.readlink()
        path.unlink(); path.symlink_to('/etc/passwd')
        with self.assertRaises(ValueError): self.verify()
        path.unlink(); path.symlink_to(original)
        install = self.root / 'usr/share/pasturestack/security/brotli-official/install.json'
        value = json.loads(install.read_text()); value['packageSetUnchanged'] = False
        install.write_text(json.dumps(value))
        with self.assertRaises(ValueError): self.verify()
        self.receipt.write_text('true')
        with self.assertRaises(ValueError): self.verify()

    def test_other_twelve_package_versions_and_official_scope_remain_exact(self):
        for index, package in enumerate(self.sbom['components']):
            changed = copy.deepcopy(self.sbom)
            changed['components'][index]['version'] = 'wrong-version'
            with self.subTest(package=package['name']), self.assertRaises(ValueError): self.verify(sbom=changed)
        changed = copy.deepcopy(self.sbom)
        changed['components'].append(copy.deepcopy(next(p for p in changed['components'] if p['name'] == 'libbrotli1')))
        with self.assertRaises(ValueError): self.verify(sbom=changed)
        changed = copy.deepcopy(self.sbom)
        next(p for p in changed['components'] if p['name'] == 'libbrotli1')['purl'] = 'pkg:deb/ubuntu/libbrotli1@1.2.0-3ubuntu0.1?arch=arm64&distro=ubuntu-26.04'
        with self.assertRaises(ValueError): self.verify(sbom=changed)

    def test_default_producer_and_original_seven_file_binding_are_unchanged(self):
        result = guard.verify(self.files, fixture.checksums(self.files), self.old_sbom, fixture.DIGEST, fixture.producer_checksums(self.files))
        self.assertNotIn('officialReplacements', result)
        with self.assertRaises(ValueError):
            guard.verify(self.files, fixture.checksums(self.files), self.sbom, fixture.DIGEST, fixture.producer_checksums(self.files))
        original = fixture.producer_checksums(self.files)
        changed = copy.deepcopy(self.files)
        fixture.change(changed, 'manifest.json', lambda value: value['packages'][0]['archive'].update(sha256='f'*64))
        with self.assertRaisesRegex(ValueError, 'immutable OCI producer'): self.verify(files=changed, producer=original)


if __name__ == '__main__': unittest.main(verbosity=2)

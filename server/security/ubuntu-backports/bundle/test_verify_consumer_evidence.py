"""Narrow metadata closure tests; no package install, Trivy invocation or filtering."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest

SPEC = importlib.util.spec_from_file_location('consumer_evidence', Path(__file__).with_name('verify-consumer-evidence.py'))
guard = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(guard)
DIGEST = 'sha256:' + 'a' * 64


def encoded(value):
    return (json.dumps(value, sort_keys=True) + '\n').encode()


def fixture():
    source = {'schemaVersion': 1, 'bundleVersion': '0.1.0', 'platform': guard.PLATFORM}
    manifest = dict(source, families=[], packages=[])
    qualification = dict(source, status='qualified', sourceLockSha256=guard.sha(encoded(source)), families=[])
    for family, names in guard.FAMILIES.items():
        provenance = '1' * 64
        manifest['families'].append({'name': family, 'source': family, 'version': '2.0+pasturestack.1',
            'provenance': {'path': 'provenance/' + family + '/provenance.json', 'sha256': provenance}})
        qualification['families'].append({'name': family, 'status': 'qualified', 'provenanceSha256': provenance,
            'nativeInput': {'lockSha256': '2' * 64, 'fixedVulnerabilities': ['CVE-2026-35370']}})
        for name in sorted(names):
            manifest['packages'].append({'name': name, 'family': family, 'source': family,
                'version': '2.0+pasturestack.1', 'architecture': 'amd64',
                'archive': {'sha256': '3' * 64}, 'payload': {'sha256': '4' * 64}})
    manifest['qualification'] = {'path': 'qualification.json', 'sha256': guard.sha(encoded(qualification))}
    selected = ['libc6', 'libc-bin', 'libc-gconv-modules-extra', 'libpcre2-8-0', 'rust-coreutils']
    install = {'schemaVersion': 1, 'bundleVersion': '0.1.0', 'status': 'installed-and-verified',
               'providerPreserved': True, 'configurationPreserved': True, 'packages': selected}
    verified = {'schemaVersion': 1, 'bundleVersion': '0.1.0', 'status': 'verified', 'packages': selected}
    vex = {'@context': 'https://openvex.dev/ns/v0.2.0', 'statements': [
        {'vulnerability': {'name': 'CVE-2026-35370'}, 'status': 'fixed', 'action_statement': 'Exact official patch qualified.',
         'products': [{'@id': guard.package_purl(p)} for p in manifest['packages']]}]}
    files = {name: encoded(value) for name, value in [('manifest.json', manifest), ('qualification.json', qualification),
             ('source-inputs.lock.json', source), ('install.json', install), ('verify.json', verified), ('openvex.json', vex)]}
    files['bundle-image.txt'] = ('ghcr.io/pasturestack/ubuntu-security-backports:v0.1.0@' + DIGEST + '\n').encode()
    sbom = {'bomFormat': 'CycloneDX', 'components': [{'name': p['name'], 'version': p['version'],
            'purl': guard.package_purl(p)} for p in manifest['packages'] if p['name'] in selected]}
    return files, sbom


def checksums(files):
    return ''.join(guard.sha(files[name]) + '  ' + name + '\n' for name in guard.FILES).encode()


def producer_checksums(files):
    return ''.join(guard.sha(files[name]) + '  ' + name + '\n' for name in guard.PRODUCER_FILES).encode()


def change(files, name, mutation):
    doc = json.loads(files[name]); mutation(doc); files[name] = encoded(doc)


class ConsumerEvidenceTests(unittest.TestCase):
    def test_debian_epoch_matches_native_trivy_purl(self):
        self.assertEqual(guard.package_purl({'name': 'libxrender1',
            'version': '1:0.9.12-1build1+pasturestack.1'}),
            'pkg:deb/ubuntu/libxrender1@0.9.12-1build1%2Bpasturestack.1?arch=amd64&distro=ubuntu-26.04&epoch=1')
        with self.assertRaises(ValueError):
            guard.package_purl({'name': 'libxrender1', 'version': 'bad:1.0'})

    def test_valid_partial_package_set_does_not_claim_absent_packages(self):
        files, sbom = fixture(); original = copy.deepcopy((files, sbom))
        result = guard.verify(files, checksums(files), sbom, DIGEST, producer_checksums(files))
        self.assertEqual(result['selectedPackages'], sorted(c['name'] for c in sbom['components']))
        self.assertNotIn('jq', result['selectedPackages'])
        self.assertFalse(result['findingsFilteredByThisTool'])
        self.assertEqual((files, sbom), original)

    def test_wrong_digest_or_tampered_evidence_rejected(self):
        files, sbom = fixture()
        for pin in ['__BUNDLE_DIGEST_PENDING__', 'sha256:' + 'b' * 64]:
            with self.subTest(pin=pin), self.assertRaises(ValueError):
                guard.verify(files, checksums(files), sbom, pin, producer_checksums(files))
        sums = checksums(files); files['install.json'] += b' '
        with self.assertRaises(ValueError): guard.verify(files, sums, sbom, DIGEST, producer_checksums(files))

    def test_receipt_sbom_versions_and_exact_selection_are_required(self):
        for kind in ['old-version', 'wrong-purl', 'missing', 'extra', 'duplicate', 'receipt']:
            with self.subTest(kind=kind):
                files, sbom = fixture()
                if kind == 'old-version': sbom['components'][0]['version'] = '1.0'
                if kind == 'wrong-purl': sbom['components'][0]['purl'] = 'pkg:deb/ubuntu/libc6'
                if kind == 'missing': sbom['components'].pop()
                if kind == 'extra':
                    p = next(p for p in json.loads(files['manifest.json'])['packages'] if p['name'] == 'jq')
                    sbom['components'].append({'name': 'jq', 'version': p['version'], 'purl': guard.package_purl(p)})
                if kind == 'duplicate': sbom['components'].append(sbom['components'][0])
                if kind == 'receipt': change(files, 'verify.json', lambda d: d['packages'].pop())
                with self.assertRaises(ValueError): guard.verify(files, checksums(files), sbom, DIGEST, producer_checksums(files))

    def test_blanket_or_unqualified_vex_is_rejected(self):
        for kind in ['no-version', 'wildcard', 'oci', 'subcomponent', 'unqualified-id', 'not-affected', 'duplicate']:
            with self.subTest(kind=kind):
                files, sbom = fixture()
                vex = json.loads(files['openvex.json']); row = vex['statements'][0]
                if kind == 'no-version': row['products'][0]['@id'] = 'pkg:deb/ubuntu/libc6'
                if kind == 'wildcard': row['products'][0]['@id'] = 'pkg:deb/ubuntu/libc6@*'
                if kind == 'oci': row['products'][0]['@id'] = 'pkg:oci/consumer'
                if kind == 'subcomponent': row['products'][0]['subcomponents'] = []
                if kind == 'unqualified-id': row['vulnerability']['name'] = 'CVE-2026-89092'
                if kind == 'not-affected': row['status'] = 'not_affected'
                if kind == 'duplicate': row['products'].append(row['products'][0])
                files['openvex.json'] = encoded(vex)
                with self.assertRaises(ValueError): guard.verify(files, checksums(files), sbom, DIGEST, producer_checksums(files))

    def test_manifest_qualification_binding_is_required(self):
        files, sbom = fixture(); change(files, 'qualification.json', lambda d: d.update(status='pending'))
        with self.assertRaises(ValueError): guard.verify(files, checksums(files), sbom, DIGEST, producer_checksums(files))

    def test_self_rehashed_candidate_metadata_cannot_replace_immutable_producer_bytes(self):
        for name in guard.PRODUCER_FILES:
            with self.subTest(name=name):
                files, sbom = fixture(); producer = producer_checksums(files)
                image = files['bundle-image.txt']
                files[name] += b' '
                if name == 'source-inputs.lock.json':
                    change(files, 'qualification.json', lambda q: q.update(sourceLockSha256=guard.sha(files[name])))
                if name in ('source-inputs.lock.json', 'qualification.json'):
                    change(files, 'manifest.json', lambda m: m['qualification'].update(sha256=guard.sha(files['qualification.json'])))
                # This candidate remains internally consistent, including its
                # rewritten checksums and unchanged bundle-image identity text.
                guard.verify(files, checksums(files), sbom, DIGEST, producer_checksums(files))
                self.assertEqual(files['bundle-image.txt'], image)
                with self.assertRaisesRegex(ValueError, 'differs from immutable OCI producer'):
                    guard.verify(files, checksums(files), sbom, DIGEST, producer)


if __name__ == '__main__':
    unittest.main()

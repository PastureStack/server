"""Narrow metadata closure tests; no package install, Trivy invocation or filtering."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest
import tempfile
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('consumer_evidence', Path(__file__).with_name('verify-consumer-evidence.py'))
guard = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(guard)
TRIVY_SPEC = importlib.util.spec_from_file_location('trivy_semantic_fixture',
    Path(__file__).with_name('test-trivy-glibc-vex.py'))
trivy_fixture = importlib.util.module_from_spec(TRIVY_SPEC)
TRIVY_SPEC.loader.exec_module(trivy_fixture)
DIGEST = 'sha256:' + 'a' * 64


def encoded(value):
    return (json.dumps(value, sort_keys=True) + '\n').encode()


def semantic_receipt(vex_sha, source_lock_sha):
    return {'schemaVersion': 1, 'status': 'PASS', 'vulnerability': guard.GLIBC_NSCD_CVE,
        'nativeTrivyVersion': '0.74.0', 'inputOpenVexSha256': vex_sha,
        'inputKind': 'qualified-bundle', 'inputSourceLockSha256': source_lock_sha,
        'sourceClosureSha256': guard.GLIBC_NSCD_PROOF_SHA256,
        'rawRetainedUnchanged': True, 'findingsFilteredByThisHelper': False,
        'removedPairs': [{'cve': guard.GLIBC_NSCD_CVE, 'purl': trivy_fixture.purl(n)}
                         for n in sorted(guard.FAMILIES['glibc'])],
        'retainedNegativeControlPURLs': sorted([trivy_fixture.purl('nscd'),
                                               trivy_fixture.purl('libc6', '2.43-2ubuntu2.4')]),
        'rawFindings': 6, 'effectiveFindings': 3,
        **{k: 'a' * 64 for k in ('rawSha256', 'effectiveSha256', 'fixtureSbomSha256', 'scopedOpenVexSha256')}}


def fixture(absence=False):
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
    if absence:
        here = Path(__file__).parent
        native = json.loads((here / 'source-inputs.lock.json').read_text())['nativeInputs']['glibc']
        public = json.loads((here / guard.GLIBC_NSCD_PROOF_FILE).read_text())
        source['nativeInputs'] = {'glibc': copy.deepcopy(native)}
        family = next(f for f in manifest['families'] if f['name'] == 'glibc')
        family.update(version=guard.GLIBC_NSCD_VERSION)
        family['provenance']['sha256'] = native['evidence']['provenance.json']
        q = next(f for f in qualification['families'] if f['name'] == 'glibc')
        q.update(nativeInput=copy.deepcopy(native), provenanceSha256=native['evidence']['provenance.json'])
        audited = {p['name']: p for p in public['audit']['packages']}
        q['codeAbsence'] = {'sourceClosure': public, 'sourceClosureSha256': guard.GLIBC_NSCD_PROOF_SHA256, 'packages': {}}
        for p in manifest['packages']:
            if p['family'] != 'glibc': continue
            p['version'] = guard.GLIBC_NSCD_VERSION
            p['archive']['sha256'] = public['debs'][p['name']]['sha256']
            p['payload']['sha256'] = audited[p['name']]['qualifierPayload']['sha256']
            q['codeAbsence']['packages'][p['name']] = {'purl': guard.package_purl(p),
                'archiveSha256': p['archive']['sha256'], 'payloadSha256': p['payload']['sha256'], 'nscdDaemonPaths': []}
        vex['statements'][0]['products'] = [{'@id': guard.package_purl(p)} for p in manifest['packages'] if p['family'] != 'glibc']
        vex['statements'].append({'vulnerability': {'name': 'CVE-2026-18374'}, 'status': 'fixed',
            'action_statement': 'Exact native official fix.',
            'products': [{'@id': trivy_fixture.purl(n)} for n in sorted(guard.FAMILIES['glibc'])]})
        vex['statements'].append(guard.glibc_nscd_statement(sorted(trivy_fixture.purl(n) for n in guard.FAMILIES['glibc'])))
        qualification['sourceLockSha256'] = guard.sha(encoded(source))
        qualification['glibcNscdVexSemanticTest'] = semantic_receipt(guard.sha(encoded(vex)), guard.sha(encoded(source)))
        manifest['qualification']['sha256'] = guard.sha(encoded(qualification))
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


def refresh_bindings(files):
    change(files, 'qualification.json', lambda q: q.update(sourceLockSha256=guard.sha(files['source-inputs.lock.json'])))
    change(files, 'manifest.json', lambda m: m['qualification'].update(sha256=guard.sha(files['qualification.json'])))


class ConsumerEvidenceTests(unittest.TestCase):
    def test_source_native_fixture_requires_no_debs_and_uses_production_generator(self):
        with tempfile.TemporaryDirectory(prefix='glibc-vex-source-unit-') as directory:
            work = Path(directory); target = work / 'fixture'
            with patch.object(trivy_fixture, 'FIXTURE', target), patch.object(trivy_fixture, 'WORK', work):
                trivy_fixture.prepare(source_only=True)
            doc = json.loads((target / 'scoped.openvex.json').read_bytes())
            pins = json.loads((target / 'input.json').read_bytes())
            self.assertEqual(doc['statements'], [guard.glibc_nscd_statement(sorted(
                trivy_fixture.purl(n) for n in guard.FAMILIES['glibc']))])
            self.assertEqual(pins['inputKind'], 'source-lock-public-proof')
            self.assertEqual({p.name for p in target.iterdir()}, {'fixture.cdx.json', 'scoped.openvex.json', 'input.json'})

    def test_exact_source_bound_glibc_absence_is_distinct_from_fixed(self):
        files, sbom = fixture(absence=True); original = copy.deepcopy((files, sbom))
        result = guard.verify(files, checksums(files), sbom, DIGEST, producer_checksums(files))
        self.assertEqual(result['qualifiedCodeAbsentVexPairs'], 3)
        self.assertEqual(result['qualifiedFixedVexPairs'], 12)
        self.assertEqual((files, sbom), original)
        self.assertEqual(len(guard.FILES), 7)

    def test_glibc_absence_cannot_expand_cve_package_version_arch_distro_or_status(self):
        for kind in ['cve', 'alias', 'fixed', 'justification', 'impact', 'nscd', 'dev', 'old-version',
                     'arch', 'distro', 'missing-product', 'extra-product', 'missing-statement', 'duplicate']:
            with self.subTest(kind=kind):
                files, sbom = fixture(absence=True); doc = json.loads(files['openvex.json']); row = doc['statements'][-1]
                if kind == 'cve': row['vulnerability']['name'] = 'CVE-2026-89093'
                if kind == 'alias': row['vulnerability']['aliases'] = ['CVE-2026-89093']
                if kind == 'fixed': row['status'] = 'fixed'
                if kind == 'justification': row['justification'] = 'vulnerable_code_not_in_execute_path'
                if kind == 'impact': row['impact_statement'] = 'Whole image is safe.'
                if kind == 'nscd': row['products'][0]['@id'] = trivy_fixture.purl('nscd')
                if kind == 'dev': row['products'][0]['@id'] = trivy_fixture.purl('libc6-dev')
                if kind == 'old-version': row['products'][0]['@id'] = trivy_fixture.purl('libc6', '2.43-2ubuntu2.4')
                if kind == 'arch': row['products'][0]['@id'] = row['products'][0]['@id'].replace('amd64', 'arm64')
                if kind == 'distro': row['products'][0]['@id'] = row['products'][0]['@id'].replace('26.04', '24.04')
                if kind == 'missing-product': row['products'].pop()
                if kind == 'extra-product': row['products'].append({'@id': trivy_fixture.purl('nscd')})
                if kind == 'missing-statement': doc['statements'].pop()
                if kind == 'duplicate': doc['statements'].append(copy.deepcopy(row))
                files['openvex.json'] = encoded(doc)
                with self.assertRaises(ValueError): guard.verify(files, checksums(files), sbom, DIGEST, producer_checksums(files))

    def test_absent_changed_or_self_rehashed_glibc_source_proof_is_rejected(self):
        for kind in ['absent', 'pending', 'source', 'native', 'deb', 'payload', 'fixed-id', 'semantic', 'source-only-semantic']:
            with self.subTest(kind=kind):
                files, sbom = fixture(absence=True); q = json.loads(files['qualification.json'])
                glibc = next(f for f in q['families'] if f['name'] == 'glibc')
                if kind == 'absent': glibc.pop('codeAbsence')
                if kind in ('pending', 'source', 'native', 'deb'):
                    proof = glibc['codeAbsence']['sourceClosure']
                    if kind == 'pending': proof['status'] = 'pending-source-closure'
                    if kind == 'source': proof['sourceIdentity']['sourceFiles'][0]['sha256'] = '0' * 64
                    if kind == 'native': proof['nativeIdentity']['zipSha256'] = '0' * 64
                    if kind == 'deb': proof['debs']['libc6']['sha256'] = '0' * 64
                    digest = guard.sha(guard.canonical_json(proof))
                    glibc['codeAbsence']['sourceClosureSha256'] = digest
                    glibc['nativeInput']['codeAbsenceProof']['sha256'] = digest
                if kind == 'payload': glibc['codeAbsence']['packages']['libc6']['payloadSha256'] = '0' * 64
                if kind == 'fixed-id': glibc['nativeInput']['fixedVulnerabilities'].append(guard.GLIBC_NSCD_CVE)
                if kind == 'semantic': q.pop('glibcNscdVexSemanticTest')
                if kind == 'source-only-semantic': q['glibcNscdVexSemanticTest']['inputKind'] = 'source-lock-public-proof'
                files['qualification.json'] = encoded(q)
                change(files, 'source-inputs.lock.json', lambda l: l['nativeInputs'].update(glibc=copy.deepcopy(glibc['nativeInput'])))
                refresh_bindings(files)
                with self.assertRaises(ValueError): guard.verify(files, checksums(files), sbom, DIGEST, producer_checksums(files))

    def test_native_fixture_keeps_distinct_multi_version_ubuntu_components(self):
        doc = trivy_fixture.fixture_document()
        rows = [c for c in doc['components'] if c['type'] == 'library']
        self.assertEqual(len(rows), 5)
        self.assertEqual(len({c['bom-ref'] for c in rows}), 5)
        self.assertEqual({c['purl'] for c in rows}, set(doc['dependencies'][1]['dependsOn']))
        self.assertEqual(len([c for c in rows if c['name'] == 'libc6']), 2)
        self.assertTrue(all(c['bom-ref'] == c['purl'] for c in rows))

    def test_native_semantic_oracle_rejects_loss_of_any_negative_control(self):
        pairs = [(trivy_fixture.CVE, trivy_fixture.purl(n)) for n in trivy_fixture.NAMES]
        controls = [(trivy_fixture.CVE, trivy_fixture.purl('nscd')),
                    (trivy_fixture.CVE, trivy_fixture.purl('libc6', '2.43-2ubuntu2.4')),
                    ('CVE-2026-18374', trivy_fixture.purl('libc6'))]
        def report(rows):
            return {'Results': [{'Vulnerabilities': [{'VulnerabilityID': c, 'PkgIdentifier': {'PURL': p}}
                                                     for c, p in rows]}]}
        raw = report(pairs + controls); original = copy.deepcopy(raw)
        result = trivy_fixture.assert_effective(raw, report(controls))
        self.assertEqual((result['rawFindings'], result['effectiveFindings']), (6, 3))
        self.assertEqual(raw, original)
        for missing in controls:
            with self.subTest(missing=missing), self.assertRaises(ValueError):
                trivy_fixture.assert_effective(raw, report([p for p in controls if p != missing]))
        with self.assertRaises(ValueError): trivy_fixture.assert_raw(report(pairs + controls[1:]))
        with self.assertRaises(ValueError): trivy_fixture.assert_effective(raw, raw)

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

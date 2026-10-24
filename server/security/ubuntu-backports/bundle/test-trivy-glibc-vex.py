#!/usr/bin/env python3
"""Assert native Trivy OpenVEX semantics in an isolated publisher fixture.

This helper never filters findings or invokes a scanner. The workflow runs
the pinned native Trivy image and retains both reports without rewriting them.
No host, installed-package or production-image inspection is performed here.
"""
import argparse
from collections import Counter
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile

HERE = Path(__file__).resolve().parent
GUARD_SPEC = importlib.util.spec_from_file_location('semantic_metadata_guard', HERE / 'verify-consumer-evidence.py')
GUARD = importlib.util.module_from_spec(GUARD_SPEC)
GUARD_SPEC.loader.exec_module(GUARD)
WORK = Path(tempfile.gettempdir()) / 'pasturestack-ubuntu-security-backports-v0.1.0'
FIXTURE = WORK / 'glibc-vex-semantic'
CVE = GUARD.GLIBC_NSCD_CVE
VERSION = GUARD.GLIBC_NSCD_VERSION
NAMES = tuple(sorted(GUARD.FAMILIES['glibc']))


def require(ok, message):
    if not ok:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return (json.dumps(value, indent=2, sort_keys=True) + '\n').encode()


def purl(name, version=VERSION):
    return GUARD.package_purl({'name': name, 'version': version})


def fixture_document():
    rows = [(name, VERSION) for name in NAMES] + [('nscd', VERSION), ('libc6', '2.43-2ubuntu2.4')]
    packages = [{'type': 'library', 'name': name, 'version': version,
                 'purl': purl(name, version), 'bom-ref': purl(name, version),
                 'properties': [{'name': 'aquasecurity:trivy:SrcName', 'value': 'glibc'},
                                {'name': 'aquasecurity:trivy:SrcVersion', 'value': version},
                                {'name': 'aquasecurity:trivy:PkgID', 'value': name + '@' + version}]}
                for name, version in rows]
    return {'bomFormat': 'CycloneDX', 'specVersion': '1.6', 'version': 1,
            'metadata': {'component': {'type': 'file', 'name': 'glibc-vex-semantic-fixture', 'bom-ref': 'fixture'}},
            'components': [{'type': 'operating-system', 'name': 'ubuntu', 'version': '26.04',
                            'bom-ref': 'ubuntu-26.04'}] + packages,
            'dependencies': [{'ref': 'fixture', 'dependsOn': ['ubuntu-26.04']},
                             {'ref': 'ubuntu-26.04', 'dependsOn': [p['bom-ref'] for p in packages]}]}


def findings(report):
    rows = Counter()
    for result in report.get('Results', []):
        for row in result.get('Vulnerabilities') or []:
            identifier = row.get('PkgIdentifier', {}).get('PURL')
            require(isinstance(identifier, str) and identifier.startswith('pkg:deb/ubuntu/'),
                    'Native Trivy finding lacks its exact Ubuntu package PURL')
            rows[(row['VulnerabilityID'], identifier)] += 1
    return rows


def assert_raw(report):
    rows = findings(report)
    expected = {purl(name) for name in NAMES} | {purl('nscd'), purl('libc6', '2.43-2ubuntu2.4')}
    require({p for (c, p) in rows if c == CVE} == expected
            and all(rows[(CVE, p)] == 1 for p in expected),
            'Native multi-version Ubuntu SBOM/DB did not retain all five exact 89092 controls')
    require(any(c != CVE for c, _ in rows), 'Native raw report lacks an independent vulnerability control')
    return rows


def assert_effective(raw, effective):
    before, after = assert_raw(raw), findings(effective)
    removed = Counter({(CVE, purl(name)): 1 for name in NAMES})
    require(after == before - removed,
            'Native OpenVEX must remove only the three qualified pairs; nscd, old libc and other findings must remain')
    return {'rawFindings': sum(before.values()), 'effectiveFindings': sum(after.values()),
            'removedPairs': [{'cve': c, 'purl': p} for c, p in sorted(removed)],
            'retainedNegativeControlPURLs': sorted([purl('nscd'), purl('libc6', '2.43-2ubuntu2.4')])}


def prepare(source_only=False):
    require(not FIXTURE.exists(), 'Semantic fixture output must be new')
    source_lock = (HERE / 'source-inputs.lock.json').read_bytes()
    lock = json.loads(source_lock); item = lock['nativeInputs']['glibc']
    proof_bytes = (HERE / GUARD.GLIBC_NSCD_PROOF_FILE).read_bytes()
    require(sha(proof_bytes) == item['codeAbsenceProof']['sha256'], 'Source fixture proof bytes differ from lock')
    GUARD.validate_glibc_nscd_source(json.loads(proof_bytes), item)
    expected = GUARD.glibc_nscd_statement(sorted(GUARD.package_purl(p) for p in item['packages']))
    if source_only:
        doc = {'@context': 'https://openvex.dev/ns/v0.2.0',
               '@id': 'https://github.com/PastureStack/server/ubuntu-security-backports/semantic-fixture',
               'author': 'PastureStack native semantic fixture', 'timestamp': lock['vexTimestamp'],
               'version': 1, 'statements': [expected]}
        candidate = encoded(doc)
    else:
        candidate = (WORK / 'context/out/openvex.json').read_bytes()
        doc = json.loads(candidate)
    rows = [s for s in doc['statements'] if s['vulnerability']['name'] == CVE]
    require(rows == [expected],
            'Candidate does not contain the exact qualified code-absence statement')
    doc['statements'] = rows
    FIXTURE.mkdir(parents=True)
    (FIXTURE / 'fixture.cdx.json').write_bytes(encoded(fixture_document()))
    (FIXTURE / 'scoped.openvex.json').write_bytes(encoded(doc))
    (FIXTURE / 'input.json').write_bytes(encoded({'inputOpenVexSha256': sha(candidate),
        'inputKind': 'source-lock-public-proof' if source_only else 'qualified-bundle',
        'inputSourceLockSha256': sha(source_lock), 'sourceClosureSha256': sha(proof_bytes),
        'fixtureSbomSha256': sha((FIXTURE / 'fixture.cdx.json').read_bytes()),
        'scopedOpenVexSha256': sha((FIXTURE / 'scoped.openvex.json').read_bytes())}))


def check_inputs():
    pins = json.loads((FIXTURE / 'input.json').read_bytes())
    for name, key in [('fixture.cdx.json', 'fixtureSbomSha256'), ('scoped.openvex.json', 'scopedOpenVexSha256')]:
        require(sha((FIXTURE / name).read_bytes()) == pins[key], 'Semantic fixture input changed: ' + name)
    require(sha((HERE / 'source-inputs.lock.json').read_bytes()) == pins['inputSourceLockSha256']
            and sha((HERE / GUARD.GLIBC_NSCD_PROOF_FILE).read_bytes()) == pins['sourceClosureSha256'],
            'Source lock/public proof changed during native semantic test')
    candidate = WORK / 'context/out/openvex.json' if pins['inputKind'] == 'qualified-bundle' else FIXTURE / 'scoped.openvex.json'
    require(sha(candidate.read_bytes()) == pins['inputOpenVexSha256'], 'Producer/fixture VEX changed during native semantic test')
    require((FIXTURE / 'trivy-version.txt').read_text().splitlines()[0] == 'Version: 0.74.0',
            'Semantic test must use native Trivy 0.74.0')
    return pins


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    for name in ('prepare', 'prepare-source', 'record-raw', 'verify'): modes.add_argument('--' + name, action='store_true')
    args = parser.parse_args()
    if args.prepare or args.prepare_source: prepare(source_only=args.prepare_source); return
    pins = check_inputs(); raw_bytes = (FIXTURE / 'raw.json').read_bytes(); raw = json.loads(raw_bytes)
    assert_raw(raw)
    if args.record_raw:
        require(not (FIXTURE / 'raw-pin.json').exists(), 'Native raw pin must be new')
        (FIXTURE / 'raw-pin.json').write_bytes(encoded({'rawSha256': sha(raw_bytes)})); return
    require(sha(raw_bytes) == json.loads((FIXTURE / 'raw-pin.json').read_bytes())['rawSha256'],
            'Native raw report was modified after its first retained read')
    effective_bytes = (FIXTURE / 'effective.json').read_bytes()
    result = dict(assert_effective(raw, json.loads(effective_bytes)), schemaVersion=1, status='PASS',
                  vulnerability=CVE, nativeTrivyVersion='0.74.0', **pins, rawSha256=sha(raw_bytes),
                  effectiveSha256=sha(effective_bytes), rawRetainedUnchanged=True,
                  findingsFilteredByThisHelper=False)
    require(not (FIXTURE / 'result.json').exists(), 'Native semantic receipt must be new')
    (FIXTURE / 'result.json').write_bytes(encoded(result))
    print('GLIBC_NSCD_NATIVE_VEX_SEMANTICS_PASS')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, UnicodeError) as error:
        print('GLIBC_NSCD_VEX_SEMANTICS_FAILED: ' + str(error), file=sys.stderr)
        sys.exit(1)

#!/usr/bin/env python3
"""Read-only closure of qualified backport metadata against a consumer SBOM.

This does not read, filter or rewrite vulnerability findings. Trivy's native
local OpenVEX handling remains the only VEX interpretation step.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
from urllib.parse import quote

PLATFORM = {'distribution': 'ubuntu', 'release': '26.04', 'architecture': 'amd64'}
FAMILIES = {
    'pcre2': {'libpcre2-8-0', 'libpcre2-posix3'},
    'glibc': {'libc6', 'libc-bin', 'libc-gconv-modules-extra'},
    'rust-coreutils': {'rust-coreutils'}, 'jq': {'jq', 'libjq1'},
    'p11-kit': {'libp11-kit0', 'p11-kit', 'p11-kit-modules'},
    'libxrender': {'libxrender1'}, 'brotli': {'libbrotli1'},
}
FILES = ('manifest.json', 'qualification.json', 'openvex.json',
         'source-inputs.lock.json', 'install.json', 'verify.json', 'bundle-image.txt')
PRODUCER_FILES = ('manifest.json', 'qualification.json', 'openvex.json', 'source-inputs.lock.json')
SHA256 = re.compile(r'[0-9a-f]{64}')
DIGEST = re.compile(r'sha256:[0-9a-f]{64}')
VULNERABILITY = re.compile(r'(?:CVE-[0-9]{4}-[0-9]+|GHSA-[23456789cfghjmpqrvwx]{4}(?:-[23456789cfghjmpqrvwx]{4}){2})')
GLIBC_NSCD_CVE = 'CVE-2026-89092'
GLIBC_NSCD_VERSION = '2.43-2ubuntu2.4+pasturestack.1'
GLIBC_NSCD_PROOF_FILE = 'glibc-nscd-source-closure.json'
# Set only after review of the complete public source/object/package audit.
# Pending progress evidence cannot authorize a not_affected statement.
GLIBC_NSCD_PROOF_SHA256 = 'dcc574c006f401e1169e5a73c01ed32598f13fa917c448e215fc0fb76aad2657'
GLIBC_NSCD_SOURCES = ['nscd/aicache.c', 'nscd/hstcache.c']
GLIBC_NSCD_IMPACT = ('The two vulnerable nscd daemon modules are absent from these exact runtime packages. '
    'libc nscd IPC client helpers may be present. This statement does not cover the separate nscd daemon/package '
    'or claim that a whole consumer image is not affected.')


def require(ok, message):
    if not ok:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def package_purl(package):
    version = package['version']
    epoch = None
    if ':' in version:
        epoch, version = version.split(':', 1)
        require(re.fullmatch('[0-9]+', epoch) and version, 'Malformed Debian epoch')
    result = ('pkg:deb/ubuntu/' + package['name'] + '@' + quote(version, safe='')
              + '?arch=amd64&distro=ubuntu-26.04')
    return result + ('&epoch=' + epoch if epoch is not None else '')


def unique_names(values, label):
    require(isinstance(values, list) and values and all(isinstance(v, str) for v in values),
            label + ' must be a nonempty package-name list')
    require(len(set(values)) == len(values), label + ' has duplicates')
    return set(values)


def canonical_json(value):
    return (json.dumps(value, indent=2, sort_keys=True) + '\n').encode()


def glibc_nscd_statement(exact_purls):
    expected = sorted(package_purl({'name': n, 'version': GLIBC_NSCD_VERSION}) for n in FAMILIES['glibc'])
    require(exact_purls == expected, 'glibc absence statement requires exactly three approved PURLs')
    return {'vulnerability': {'@id': 'https://www.cve.org/CVERecord?id=' + GLIBC_NSCD_CVE, 'name': GLIBC_NSCD_CVE},
            'products': [{'@id': p} for p in expected], 'status': 'not_affected',
            'justification': 'vulnerable_code_not_present', 'impact_statement': GLIBC_NSCD_IMPACT}


def native_glibc_identity(item):
    return {key: item[key] for key in ('sourceCommit', 'runId', 'jobId', 'artifactId', 'zipSha256', 'lockSha256')} | {
        'provenanceSha256': item['evidence']['provenance.json']}


def validate_glibc_nscd_source(proof, item):
    """One reviewed proof, one CVE, three exact binary packages; no generic waiver."""
    ref = item.get('codeAbsenceProof', {})
    require(GLIBC_NSCD_PROOF_SHA256 is not None
            and ref == {'path': GLIBC_NSCD_PROOF_FILE, 'sha256': GLIBC_NSCD_PROOF_SHA256}
            and sha(canonical_json(proof)) == GLIBC_NSCD_PROOF_SHA256,
            'glibc nscd complete reviewed source proof is absent or changed')
    require(proof['schemaVersion'] == 1 and proof['status'] == 'validated'
            and proof['cve'] == GLIBC_NSCD_CVE and proof['platform'] == PLATFORM
            and proof['nativeIdentity'] == native_glibc_identity(item)
            and item['status'] == 'qualified' and GLIBC_NSCD_CVE not in item['fixedVulnerabilities'],
            'glibc nscd audit does not bind this exact qualified native input')
    require(proof['scope'] == {'verdict': 'component-code-absence-only',
                'customVersion': GLIBC_NSCD_VERSION, 'runtimePackages': sorted(FAMILIES['glibc']),
                'vulnerableSources': GLIBC_NSCD_SOURCES, 'standaloneDaemonPackage': 'nscd',
                'libcNscdIpcClientsMayBePresent': True, 'wholeImageUnaffectedClaimed': False}
            and SHA256.fullmatch(proof['originalReceiptSha256'])
            and sha(canonical_json(proof['audit'])) == proof['auditProjectionSha256']
            and proof['audit']['status'] == 'qualified' and proof['audit']['cve'] == GLIBC_NSCD_CVE,
            'glibc nscd source audit scope/authority is not complete')
    audit = proof['audit']; native = audit['nativeIdentity']
    require(all(native[k] == item[k] for k in ('sourceCommit', 'runId', 'jobId', 'artifactId'))
            and native['artifactZipSha256'] == item['zipSha256']
            and native['sourceLockSha256'] == item['lockSha256']
            and native['provenanceSha256'] == item['evidence']['provenance.json']
            and native['sourceRecipeFiles'] == item['sourceFiles']
            and audit['sourceIdentity']['sourceFiles'] == proof['sourceIdentity']['sourceFiles']
            and audit['sourceIdentity']['sourceLockSha256'] == item['lockSha256']
            and audit['effectiveSourceClosure']['status'] == 'validated'
            and audit['buildObjectClosure']['allNativeLinkCommandsMentioningTheseObjectsTargetOnlyNscd'] is True
            and audit['buildObjectClosure']['libcClientRoutinesAreTheVulnerableDaemonModules'] is False
            and audit['excludedNscdPackage']['name'] == 'nscd'
            and audit['excludedNscdPackage']['qualifiedExport'] is False,
            'glibc source/object/package audit does not close the selected native boundary')
    require(len(item['packages']) == 3 and {p['name'] for p in item['packages']} == FAMILIES['glibc']
            and all(p['version'] == GLIBC_NSCD_VERSION and p['source'] == 'glibc' for p in item['packages'])
            and proof['debs'] == {p['name']: {'file': p['file'], 'sha256': p['sha256']} for p in item['packages']},
            'glibc nscd source audit does not cover the exact three deb archives')


def validate_glibc_nscd_qualification(qualified, packages, lock):
    family = qualified['glibc']; item = family['nativeInput']
    require(item == lock.get('nativeInputs', {}).get('glibc'), 'glibc absence proof differs from immutable source lock')
    absence = family.get('codeAbsence', {})
    validate_glibc_nscd_source(absence.get('sourceClosure', {}), item)
    require(absence.get('sourceClosureSha256') == GLIBC_NSCD_PROOF_SHA256,
            'glibc source-closure hash mismatch')
    expected = {name: {'purl': package_purl(packages[name]),
                      'archiveSha256': packages[name]['archive']['sha256'],
                      'payloadSha256': packages[name]['payload']['sha256'], 'nscdDaemonPaths': []}
                for name in sorted(FAMILIES['glibc'])}
    audited = {p['name']: p for p in absence['sourceClosure']['audit']['packages']}
    require(absence.get('packages') == expected
            and all(packages[n]['version'] == GLIBC_NSCD_VERSION
                    and packages[n]['archive']['sha256'] == absence['sourceClosure']['debs'][n]['sha256']
                    and packages[n]['payload']['sha256'] == audited[n]['qualifierPayload']['sha256']
                    for n in FAMILIES['glibc']), 'glibc absence package/payload binding mismatch')
    return sorted(row['purl'] for row in expected.values())


def validate_glibc_vex_semantics(receipt, vex_sha, source_lock_sha):
    require(isinstance(receipt, dict) and {'schemaVersion', 'status', 'vulnerability', 'nativeTrivyVersion',
            'inputOpenVexSha256', 'rawRetainedUnchanged', 'findingsFilteredByThisHelper', 'removedPairs',
            'retainedNegativeControlPURLs', 'rawFindings', 'effectiveFindings', 'rawSha256',
            'effectiveSha256', 'fixtureSbomSha256', 'scopedOpenVexSha256', 'inputKind',
            'inputSourceLockSha256', 'sourceClosureSha256'} <= receipt.keys(),
            'Native Trivy glibc/nscd semantic receipt is absent')
    expected = sorted(package_purl({'name': n, 'version': GLIBC_NSCD_VERSION}) for n in FAMILIES['glibc'])
    require(receipt['schemaVersion'] == 1 and receipt['status'] == 'PASS'
            and receipt['vulnerability'] == GLIBC_NSCD_CVE and receipt['nativeTrivyVersion'] == '0.74.0'
            and receipt['inputKind'] == 'qualified-bundle'
            and receipt['inputSourceLockSha256'] == source_lock_sha
            and receipt['sourceClosureSha256'] == GLIBC_NSCD_PROOF_SHA256
            and receipt['inputOpenVexSha256'] == vex_sha and receipt['rawRetainedUnchanged'] is True
            and receipt['findingsFilteredByThisHelper'] is False
            and receipt['removedPairs'] == [{'cve': GLIBC_NSCD_CVE, 'purl': p} for p in expected]
            and receipt['retainedNegativeControlPURLs'] == sorted([
                package_purl({'name': 'nscd', 'version': GLIBC_NSCD_VERSION}),
                package_purl({'name': 'libc6', 'version': '2.43-2ubuntu2.4'})])
            and type(receipt['rawFindings']) is int and type(receipt['effectiveFindings']) is int
            and receipt['rawFindings'] - receipt['effectiveFindings'] == 3 and receipt['effectiveFindings'] >= 3
            and all(SHA256.fullmatch(receipt[k]) for k in
                ('rawSha256', 'effectiveSha256', 'fixtureSbomSha256', 'scopedOpenVexSha256')),
            'Native Trivy exact glibc/nscd VEX semantic qualification is missing or changed')


def verify(files, checksums, sbom, expected_digest, bundle_checksums):
    require(DIGEST.fullmatch(expected_digest) is not None, 'Expected bundle digest is not immutable')
    expected_image = 'ghcr.io/pasturestack/ubuntu-security-backports:v0.1.1@' + expected_digest
    require(files['bundle-image.txt'].decode().strip() == expected_image, 'Consumer bundle identity mismatch')
    pins = {}
    for line in checksums.decode().splitlines():
        digest, separator, name = line.partition('  ')
        require(separator and name in FILES and name not in pins and SHA256.fullmatch(digest),
                'Unexpected/duplicate checksum entry')
        pins[name] = digest
    require(set(pins) == set(FILES) and all(sha(files[n]) == pins[n] for n in FILES),
            'Retained consumer evidence checksum mismatch')
    producer = {}
    for line in bundle_checksums.decode().splitlines():
        digest, separator, name = line.partition('  ')
        require(separator and name and SHA256.fullmatch(digest), 'Malformed immutable OCI producer checksum entry')
        if name in PRODUCER_FILES:
            require(name not in producer, 'Duplicate immutable OCI producer metadata checksum')
            producer[name] = digest
    require(set(producer) == set(PRODUCER_FILES), 'Immutable OCI producer metadata checksums are incomplete')
    for name in PRODUCER_FILES:
        require(sha(files[name]) == producer[name], 'Consumer metadata differs from immutable OCI producer: ' + name)
    docs = {name: json.loads(files[name]) for name in FILES if name.endswith('.json')}
    manifest, qualification = docs['manifest.json'], docs['qualification.json']
    for name in ('manifest.json', 'qualification.json', 'source-inputs.lock.json'):
        item = docs[name]
        require(item['schemaVersion'] == 1 and item['bundleVersion'] == '0.1.1'
                and item['platform'] == PLATFORM, 'Unexpected qualified bundle schema/platform')
    require(manifest['qualification'] == {'path': 'qualification.json',
                'sha256': sha(files['qualification.json'])}, 'Manifest qualification binding mismatch')
    require(qualification['status'] == 'qualified'
            and qualification['sourceLockSha256'] == sha(files['source-inputs.lock.json']),
            'Qualification/source-lock binding mismatch')
    families = {f['name']: f for f in manifest['families']}
    qualified = {f['name']: f for f in qualification['families']}
    require(len(manifest['families']) == len(qualification['families']) == 7
            and set(families) == set(qualified) == set(FAMILIES), 'Invalid qualified family set')
    for name, family in families.items():
        q = qualified[name]
        require(family['source'] == name and q['status'] == 'qualified'
                and q['provenanceSha256'] == family['provenance']['sha256']
                and SHA256.fullmatch(q['provenanceSha256'])
                and SHA256.fullmatch(q['nativeInput']['lockSha256']), 'Unqualified family provenance')
    packages = {p['name']: p for p in manifest['packages']}
    require(len(manifest['packages']) == 13 and set(packages) == set().union(*FAMILIES.values()),
            'Invalid runtime package catalog')
    purls = {}
    for name, package in packages.items():
        family = package['family']
        require(family in families and name in FAMILIES[family]
                and package['source'] == family and package['architecture'] == 'amd64'
                and package['version'] == families[family]['version']
                and re.fullmatch(r'[0-9][A-Za-z0-9.+:~\-]*', package['version']),
                'Package differs from qualified family version/source/architecture')
        require(SHA256.fullmatch(package['archive']['sha256'])
                and SHA256.fullmatch(package['payload']['sha256']), 'Invalid package archive/payload SHA')
        purls[package_purl(package)] = package
    install, installed = docs['install.json'], docs['verify.json']
    require(install['schemaVersion'] == installed['schemaVersion'] == 1
            and install['bundleVersion'] == installed['bundleVersion'] == '0.1.1'
            and install['status'] == 'installed-and-verified' and installed['status'] == 'verified'
            and install['providerPreserved'] is True and install['configurationPreserved'] is True,
            'Installation/installed-verifier did not succeed')
    selected = unique_names(install['packages'], 'install packages')
    require(selected == unique_names(installed['packages'], 'verified packages')
            and selected <= packages.keys(), 'Install/verify selected packages disagree')
    require(sbom.get('bomFormat') == 'CycloneDX' and isinstance(sbom.get('components'), list),
            'Actual consumer CycloneDX SBOM is missing')
    actual = {}
    for component in sbom['components']:
        name = component.get('name')
        if name not in packages:
            continue
        require(name not in actual, 'Duplicate consumer runtime package in SBOM')
        require(component.get('version') == packages[name]['version']
                and component.get('purl') == package_purl(packages[name]),
                'Actual SBOM package is not the selected qualified version/PURL: ' + name)
        actual[name] = component['purl']
    require(set(actual) == selected, 'Actual SBOM and installed selected-package set differ')
    vex = docs['openvex.json']
    require(vex.get('@context') == 'https://openvex.dev/ns/v0.2.0'
            and isinstance(vex.get('statements'), list) and vex['statements'], 'Invalid OpenVEX document')
    pairs = set()
    absence_statements = 0
    for statement in vex['statements']:
        identifier = statement['vulnerability']['name']
        if identifier == GLIBC_NSCD_CVE:
            expected = validate_glibc_nscd_qualification(qualified, packages, docs['source-inputs.lock.json'])
            require(statement == glibc_nscd_statement(expected),
                    'Only the exact qualified glibc component-code-absence statement is accepted')
            validate_glibc_vex_semantics(qualification.get('glibcNscdVexSemanticTest', {}), sha(files['openvex.json']),
                                         sha(files['source-inputs.lock.json']))
            absence_statements += 1
            require(absence_statements == 1, 'Duplicate glibc code-absence statement')
        else:
            require(VULNERABILITY.fullmatch(identifier) and statement['status'] == 'fixed'
                    and statement.get('action_statement') and statement['products'],
                    'Only explicit qualified fixed statements are accepted')
        for product in statement['products']:
            require(set(product) == {'@id'} and product['@id'] in purls,
                    'OpenVEX product is not a complete qualified exact-version PURL')
            package = purls[product['@id']]
            if identifier != GLIBC_NSCD_CVE:
                require(identifier in qualified[package['family']]['nativeInput']['fixedVulnerabilities'],
                        'OpenVEX CVE is outside the native qualified fix set')
            pair = (identifier, product['@id'])
            require(pair not in pairs, 'Duplicate OpenVEX vulnerability/package statement')
            pairs.add(pair)
    require('codeAbsenceProof' not in qualified['glibc']['nativeInput'] or absence_statements == 1,
            'Qualified glibc code-absence statement is missing')
    return {'schemaVersion': 1, 'status': 'PASS', 'bundleDigest': expected_digest,
            'manifestSha256': sha(files['manifest.json']), 'openvexSha256': sha(files['openvex.json']),
            'bundleChecksumsSha256': sha(bundle_checksums), 'producerMetadataSha256': producer,
            'selectedPackages': sorted(selected), 'selectedPURLs': sorted(actual.values()),
            'qualifiedVexPairs': len(pairs), 'qualifiedCodeAbsentVexPairs': 3 * absence_statements,
            'qualifiedFixedVexPairs': len(pairs) - 3 * absence_statements, 'findingsFilteredByThisTool': False}


def bounded_read(path):
    require(path.is_file() and not path.is_symlink() and path.stat().st_size <= 32 * 1024 * 1024,
            'Input is not a bounded regular metadata file: ' + str(path))
    return path.read_bytes()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--evidence-dir', type=Path, required=True)
    parser.add_argument('--sbom', type=Path, required=True)
    parser.add_argument('--bundle-checksums', type=Path, required=True,
                        help='SHA256SUMS extracted from the pinned immutable OCI /out, independently of the candidate')
    parser.add_argument('--expected-bundle-digest', required=True)
    args = parser.parse_args()
    files = {name: bounded_read(args.evidence_dir / name) for name in FILES}
    result = verify(files, bounded_read(args.evidence_dir / 'SHA256SUMS'),
                    json.loads(bounded_read(args.sbom)), args.expected_bundle_digest,
                    bounded_read(args.bundle_checksums))
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, UnicodeError) as error:
        print('BACKPORT_CONSUMER_EVIDENCE_FAILED: ' + str(error), file=sys.stderr)
        sys.exit(1)

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
    'libxrender': {'libxrender1'},
}
FILES = ('manifest.json', 'qualification.json', 'openvex.json',
         'source-inputs.lock.json', 'install.json', 'verify.json', 'bundle-image.txt')
SHA256 = re.compile(r'[0-9a-f]{64}')
DIGEST = re.compile(r'sha256:[0-9a-f]{64}')
VULNERABILITY = re.compile(r'(?:CVE-[0-9]{4}-[0-9]+|GHSA-[23456789cfghjmpqrvwx]{4}(?:-[23456789cfghjmpqrvwx]{4}){2})')


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


def verify(files, checksums, sbom, expected_digest):
    require(DIGEST.fullmatch(expected_digest) is not None, 'Expected bundle digest is not immutable')
    expected_image = 'ghcr.io/pasturestack/ubuntu-security-backports:v0.1.0@' + expected_digest
    require(files['bundle-image.txt'].decode().strip() == expected_image, 'Consumer bundle identity mismatch')
    pins = {}
    for line in checksums.decode().splitlines():
        digest, separator, name = line.partition('  ')
        require(separator and name in FILES and name not in pins and SHA256.fullmatch(digest),
                'Unexpected/duplicate checksum entry')
        pins[name] = digest
    require(set(pins) == set(FILES) and all(sha(files[n]) == pins[n] for n in FILES),
            'Retained consumer evidence checksum mismatch')
    docs = {name: json.loads(files[name]) for name in FILES if name.endswith('.json')}
    manifest, qualification = docs['manifest.json'], docs['qualification.json']
    for name in ('manifest.json', 'qualification.json', 'source-inputs.lock.json'):
        item = docs[name]
        require(item['schemaVersion'] == 1 and item['bundleVersion'] == '0.1.0'
                and item['platform'] == PLATFORM, 'Unexpected qualified bundle schema/platform')
    require(manifest['qualification'] == {'path': 'qualification.json',
                'sha256': sha(files['qualification.json'])}, 'Manifest qualification binding mismatch')
    require(qualification['status'] == 'qualified'
            and qualification['sourceLockSha256'] == sha(files['source-inputs.lock.json']),
            'Qualification/source-lock binding mismatch')
    families = {f['name']: f for f in manifest['families']}
    qualified = {f['name']: f for f in qualification['families']}
    require(len(manifest['families']) == len(qualification['families']) == 6
            and set(families) == set(qualified) == set(FAMILIES), 'Invalid qualified family set')
    for name, family in families.items():
        q = qualified[name]
        require(family['source'] == name and q['status'] == 'qualified'
                and q['provenanceSha256'] == family['provenance']['sha256']
                and SHA256.fullmatch(q['provenanceSha256'])
                and SHA256.fullmatch(q['nativeInput']['lockSha256']), 'Unqualified family provenance')
    packages = {p['name']: p for p in manifest['packages']}
    require(len(manifest['packages']) == 12 and set(packages) == set().union(*FAMILIES.values()),
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
            and install['bundleVersion'] == installed['bundleVersion'] == '0.1.0'
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
    for statement in vex['statements']:
        identifier = statement['vulnerability']['name']
        require(VULNERABILITY.fullmatch(identifier) and statement['status'] == 'fixed'
                and statement.get('action_statement') and statement['products'],
                'Only explicit qualified fixed statements are accepted')
        for product in statement['products']:
            require(set(product) == {'@id'} and product['@id'] in purls,
                    'OpenVEX product is not a complete qualified exact-version PURL')
            package = purls[product['@id']]
            require(identifier in qualified[package['family']]['nativeInput']['fixedVulnerabilities'],
                    'OpenVEX CVE is outside the native qualified fix set')
            pair = (identifier, product['@id'])
            require(pair not in pairs, 'Duplicate OpenVEX vulnerability/package statement')
            pairs.add(pair)
    return {'schemaVersion': 1, 'status': 'PASS', 'bundleDigest': expected_digest,
            'manifestSha256': sha(files['manifest.json']), 'openvexSha256': sha(files['openvex.json']),
            'selectedPackages': sorted(selected), 'selectedPURLs': sorted(actual.values()),
            'qualifiedVexPairs': len(pairs), 'findingsFilteredByThisTool': False}


def bounded_read(path):
    require(path.is_file() and not path.is_symlink() and path.stat().st_size <= 32 * 1024 * 1024,
            'Input is not a bounded regular metadata file: ' + str(path))
    return path.read_bytes()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--evidence-dir', type=Path, required=True)
    parser.add_argument('--sbom', type=Path, required=True)
    parser.add_argument('--expected-bundle-digest', required=True)
    args = parser.parse_args()
    files = {name: bounded_read(args.evidence_dir / name) for name in FILES}
    result = verify(files, bounded_read(args.evidence_dir / 'SHA256SUMS'),
                    json.loads(bounded_read(args.sbom)), args.expected_bundle_digest)
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, UnicodeError) as error:
        print('BACKPORT_CONSUMER_EVIDENCE_FAILED: ' + str(error), file=sys.stderr)
        sys.exit(1)

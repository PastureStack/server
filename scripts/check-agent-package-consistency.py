#!/usr/bin/env python3
"""Compare the real Python builder/runtime inventories and qualified deltas."""
import hashlib
import json
import sys


def require(value, message):
    if not value:
        raise ValueError(message)


def inventory(text):
    require(isinstance(text, str), 'Package inventory must be text')
    rows = [line.split('\t') for line in text.splitlines()]
    require(all(len(row) == 2 for row in rows), 'Malformed package inventory')
    result = {name.split(':', 1)[0]: version for name, version in rows}
    require(len(result) == len(rows), 'Duplicate/multiarch package inventory')
    return result


def verify(data):
    builder = inventory(data['builder-packages.tsv'])
    runtime = inventory(data['runtime-packages.tsv'])
    manifest_bytes = data['backports-manifest.json'].encode('utf-8')
    manifest = json.loads(manifest_bytes)
    qualification_bytes = data['backports-qualification.json'].encode('utf-8')
    qualification = json.loads(qualification_bytes)
    receipt = json.loads(data['backports-install.json'])
    require(manifest['schemaVersion'] == 1 and manifest['bundleVersion'] == '0.1.1'
            and manifest['platform'] == {'distribution': 'ubuntu', 'release': '26.04', 'architecture': 'amd64'},
            'Unexpected backport manifest identity')
    require(manifest['qualification']['sha256'] == hashlib.sha256(qualification_bytes).hexdigest(),
            'Backport qualification checksum mismatch')
    fixtures = qualification['consumerFixtures']
    require(qualification['status'] == 'qualified' and len(fixtures) == 2
            and {item['provider'] for item in fixtures} == {'gnu', 'uutils'}
            and all(item['status'] == 'PASS' for item in fixtures),
            'Backport consumer qualification is incomplete')
    allowed = {'libc6', 'libc-bin', 'libc-gconv-modules-extra', 'libpcre2-8-0', 'libpcre2-posix3',
               'rust-coreutils', 'jq', 'libjq1', 'p11-kit', 'p11-kit-modules', 'libp11-kit0', 'libxrender1',
               'libbrotli1'}
    packages = manifest['packages']
    qualified = {p['name']: p['version'] for p in packages}
    require(len(packages) == len(qualified) == 13 and set(qualified) == allowed,
            'Unexpected qualified package catalog')
    require(receipt['schemaVersion'] == 1 and receipt['bundleVersion'] == '0.1.1'
            and receipt['status'] == 'installed-and-verified'
            and receipt['providerPreserved'] is True and receipt['configurationPreserved'] is True,
            'Runtime installation did not preserve its provider/configuration')
    selected = set(receipt['packages'])
    require(len(selected) == len(receipt['packages']) and selected == allowed & runtime.keys(),
            'Installation receipt does not match the existing runtime package selection')
    for name in selected:
        require(runtime[name] == qualified[name], 'Unqualified runtime version: ' + name)
    common = builder.keys() & runtime.keys()
    changed = {name for name in common if builder[name] != runtime[name]}
    require(changed <= selected, 'Unrelated builder/runtime package drift: ' + ', '.join(sorted(changed - selected)))
    # Keep the original compiler inputs. Only final-runtime library versions
    # may differ, and only by the exact qualified manifest above.
    require(builder.get('libc6') == '2.43-2ubuntu2.4', 'Unexpected Python-builder libc version')
    expected = {'libssl3t64': '3.5.5-1ubuntu3.7', 'curl': '8.18.0-1ubuntu2.8',
                'ca-certificates': '20260816ubuntu0.26.04.1'}
    for name, version in expected.items():
        require(runtime.get(name) == version, 'Unexpected unchanged security package: ' + name)
    return {'builder_packages': len(builder), 'runtime_packages': len(runtime),
            'common_packages_same_versions': len(common - changed),
            'qualified_runtime_deltas': sorted(changed), 'expected_security_packages': True,
            'backport_manifest_sha256': hashlib.sha256(manifest_bytes).hexdigest()}


if __name__ == '__main__':
    require(not sys.argv[1:], 'Unsupported arguments')
    data = json.load(sys.stdin)
    report = verify(data)
    print(json.dumps(report, indent=2))

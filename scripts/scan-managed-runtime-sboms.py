"""Fresh immutable-artifact inventory. A collected scan is not release acceptance."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('manifest', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    rows = json.loads(args.manifest.read_text())
    assert isinstance(rows, list) and 0 < len(rows) <= 64
    identities = set()
    for row in rows:
        assert re.fullmatch(r'ghcr\.io/pasturestack/[a-z0-9-]+:v[0-9]+\.[0-9]+\.[0-9]+', row['image'])
        assert re.fullmatch(r'sha256:[0-9a-f]{64}', row['digest'])
        assert row['image'] not in identities
        identities.add(row['image'])
    args.output.mkdir(parents=True, exist_ok=False)
    scanner = 'ghcr.io/aquasecurity/trivy:0.76.2@sha256:8f6bb947dbc528902e11f2f5be52f7b519f6a39d5d148f41166f2040499768fb'
    cache = args.output / 'cache'
    cache.mkdir()
    run = ['docker', 'run', '--rm', '--cpus', '2', '--memory', '4g', '-e', 'GOMAXPROCS=2', '-e', 'GOMEMLIMIT=2GiB',
           '-v', str(args.output.resolve()) + ':/evidence', '-v', str(cache.resolve()) + ':/root/.cache/trivy', scanner]
    subprocess.run(run + ['image', '--download-db-only', '--no-progress'], check=True)
    summary = {'accepted': False, 'status': 'COLLECTED_REQUIRES_PACKAGE_QUALIFICATION',
               'scanner': scanner, 'manifestSha256': hashlib.sha256(args.manifest.read_bytes()).hexdigest(), 'images': []}
    for row in rows:
        name = row['image'].rsplit('/', 1)[1].replace(':', '-')
        image = row['image'].rsplit(':', 1)[0] + '@' + row['digest']
        # Read the exact immutable OCI artifact, including images whose release
        # assets did not publish a runtime SBOM. No target Host is contacted.
        subprocess.run(run + ['image', '--image-src', 'remote', '--skip-db-update', '--offline-scan', '--no-progress',
                               '--format', 'cyclonedx', '--output', '/evidence/' + name + '.cdx.json', image], check=True)
        subprocess.run(run + ['sbom', '--skip-db-update', '--scanners', 'vuln', '--list-all-pkgs', '--format', 'json',
                               '--output', '/evidence/' + name + '.raw.json', '/evidence/' + name + '.cdx.json'], check=True)
        bom_path = args.output / (name + '.cdx.json')
        bom = json.loads(bom_path.read_text())
        assert bom.get('bomFormat') == 'CycloneDX' and bom.get('components')
        result = json.loads((args.output / (name + '.raw.json')).read_text())
        vulnerabilities = [v for x in result.get('Results', []) for v in x.get('Vulnerabilities', [])]
        fields = ('VulnerabilityID', 'PkgName', 'InstalledVersion', 'FixedVersion', 'Severity', 'PrimaryURL')
        summary['images'].append({**row, 'sbomSha256': hashlib.sha256(bom_path.read_bytes()).hexdigest(),
                                  'rawOccurrences': len(vulnerabilities),
                                  'fixedAvailable': [{k: v.get(k) for k in fields} for v in vulnerabilities if v.get('FixedVersion')],
                                  'unfixed': [{k: v.get(k) for k in fields} for v in vulnerabilities if not v.get('FixedVersion')]})
        (args.output / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    metadata = json.loads((cache / 'db/metadata.json').read_text())
    (args.output / 'scanner-db.json').write_text(json.dumps(metadata, indent=2) + '\n')
    print(json.dumps({'imagesCollected': len(summary['images']), 'accepted': False}))


if __name__ == '__main__':
    main()

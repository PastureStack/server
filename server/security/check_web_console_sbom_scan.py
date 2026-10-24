"""Bind browser SBOM vulnerability lookup to recognized npm components and a fresh DB."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import sys
from urllib.parse import unquote


TRIVY_IMAGE = 'ghcr.io/aquasecurity/trivy:0.74.0@sha256:62b1e65e8869bc4b4c6aa4fa2b21595256c7c2f6018a9d9ad61caf87187c1969'


def sha256(payload):
    return hashlib.sha256(payload).hexdigest()


def canonical_purl(value):
    return unquote(value.split('#', 1)[0].split('?', 1)[0]) if isinstance(value, str) else None


def properties(component):
    return {item['name']: item['value'] for item in component.get('properties', [])}


def flatten(components):
    for component in components:
        yield component
        yield from flatten(component.get('components', []))


def component_identity(component):
    return {
        'name': component.get('name'),
        'versionOrSnapshot': component.get('version'),
        'ref': component.get('bom-ref'),
        'purl': component.get('purl'),
        'hashes': component.get('hashes', []),
        'sourceHashProperties': [item for item in component.get('properties', [])
                                 if 'sha256' in item.get('name', '').lower()],
    }


def instant(value):
    if not isinstance(value, str):
        raise ValueError('Missing database/scan timestamp')
    result = datetime.fromisoformat(value.replace('Z', '+00:00'))
    if result.tzinfo is None:
        raise ValueError('Timestamp must include timezone')
    return result


def inspect(sbom, report, database, *, scanner_image, database_sha256):
    errors = []
    metadata = properties(sbom.get('metadata', {}))
    if sbom.get('bomFormat') != 'CycloneDX' or metadata.get('pasturestack:phase') != 'runtime':
        errors.append('Input must be the independent browser runtime CycloneDX BOM')
    if report.get('SchemaVersion') != 2 or not isinstance(report.get('Results', []), list):
        errors.append('Invalid Trivy report schema')
    if scanner_image != TRIVY_IMAGE or report.get('Trivy', {}).get('Version') != '0.74.0':
        errors.append('Unexpected scanner image/version')
    try:
        scan_time = instant(report.get('CreatedAt'))
        if database.get('Version') != 2 or not (
                instant(database.get('UpdatedAt')) <= scan_time < instant(database.get('NextUpdate'))):
            errors.append('Vulnerability DB was not fresh when this report was created')
    except (ValueError, TypeError):
        errors.append('Database freshness could not be established')
    if not isinstance(database_sha256, str) or len(database_sha256) != 64:
        errors.append('Missing exact vulnerability DB checksum')

    all_components = list(flatten(sbom.get('components', [])))
    if not all_components:
        errors.append('Input component inventory is empty')
    refs = [item.get('bom-ref') for item in all_components]
    if any(not ref for ref in refs) or len(refs) != len(set(refs)):
        errors.append('Input component references are missing or duplicated')
    if any(properties(item).get('pasturestack:phase') == 'build' for item in all_components):
        errors.append('Build components must not enter the browser runtime scan')
    input_npm = [item for item in all_components
                 if (canonical_purl(item.get('purl')) or '').startswith('pkg:npm/')]
    files = [item for item in all_components if item.get('type') == 'file']
    unsupported = [component_identity(item) | {
        'reason': 'No supported npm ecosystem lookup identity; source/file hashes are provenance, not a vulnerability lookup result.'}
        for item in all_components if item not in input_npm and item.get('type') != 'file']
    recognized_purls = set()
    rows = []
    result_targets = []
    for result in report.get('Results') or []:
        result_targets.append({'type': result.get('Type'), 'target': result.get('Target'),
                               'packages': len(result.get('Packages') or [])})
        # Trivy 0.74 SBOM npm lookup uses node-pkg; lockfile reports may use npm.
        if result.get('Type') in ('node-pkg', 'npm'):
            for package in result.get('Packages') or []:
                purl = canonical_purl(package.get('Identifier', {}).get('PURL'))
                if purl:
                    recognized_purls.add(purl)
        for finding in result.get('Vulnerabilities') or []:
            values = [finding.get('Severity'), finding.get('VulnerabilityID'),
                      finding.get('PkgName'), finding.get('InstalledVersion'),
                      finding.get('FixedVersion') or '',
                      'browser-runtime-sbom/' + str(result.get('Type', 'unknown'))
                      + '/' + str(result.get('Target', 'unknown'))]
            if any(not isinstance(value, str) or any(char in value for char in '\t\r\n')
                   for value in values) or not all(values[index] for index in (0, 1, 2, 3)):
                errors.append('Malformed browser vulnerability row')
            else:
                rows.append('\t'.join(values))
    missing = [component_identity(item) for item in input_npm
               if canonical_purl(item.get('purl')) not in recognized_purls]
    if missing:
        errors.append('Missing npm purl vulnerability lookup coverage')
    coverage = {
        'schemaVersion': 1,
        'scope': 'independent-browser-runtime-bom',
        'phase': 'runtime',
        'inputCoverage': metadata.get('pasturestack:coverage'),
        'coverage': 'incomplete' if unsupported or metadata.get('pasturestack:coverage') != 'complete' else 'npm-component-lookup-covered',
        'inputLimitations': metadata.get('pasturestack:coverage-limitations'),
        'scanner': {'image': scanner_image, 'version': report.get('Trivy', {}).get('Version')},
        'database': dict(database, sha256=database_sha256),
        'scanCreatedAt': report.get('CreatedAt'),
        'npm': {'componentCount': len(input_npm),
                'uniquePurlCount': len({canonical_purl(item.get('purl')) for item in input_npm}),
                'recognizedComponentCount': len(input_npm) - len(missing), 'missing': missing},
        'unsupportedComponents': unsupported,
        'artifactFiles': {'count': len(files), 'role': 'Hashed delivered payloads; not separately identified ecosystem packages.'},
        'reportTargets': result_targets,
        'findingOccurrences': len(rows),
        'effectiveDisposition': 'identical-to-raw; no browser exceptions or OS VEX applied',
        'findingGate': 'Every row is appended to the existing exact-set release gate with a browser-specific target; no new allowance.',
        'blockingErrors': errors,
        'claimBoundary': 'Recognized npm identities received database lookup. Trivy warns that third-party SBOMs may produce inaccurate detection. Unsupported snapshots and opaque inputs remain unknown; zero reported findings is not full coverage or zero risk.',
    }
    return coverage, sorted(set(rows))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for option in ('sbom', 'scan', 'effective', 'coverage', 'findings', 'db-metadata', 'db-file'):
        parser.add_argument('--' + option, type=Path, required=True)
    parser.add_argument('--scanner-image', required=True)
    args = parser.parse_args()
    raw = args.scan.read_bytes()
    document = args.sbom.read_bytes()
    db_hash = hashlib.sha256()
    with args.db_file.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            db_hash.update(chunk)
    coverage, rows = inspect(json.loads(document), json.loads(raw),
        json.loads(args.db_metadata.read_text(encoding='utf-8')),
        scanner_image=args.scanner_image, database_sha256=db_hash.hexdigest())
    coverage.update(sbomSha256=sha256(document), rawReportSha256=sha256(raw),
                    effectiveReportSha256=sha256(raw))
    # Preserve exact scanner bytes. No OS VEX or implicit browser suppression.
    args.effective.write_bytes(raw)
    args.findings.write_text(''.join(row + '\n' for row in rows), encoding='utf-8')
    args.coverage.write_text(json.dumps(coverage, indent=2) + '\n', encoding='utf-8')
    if coverage['blockingErrors']:
        print('BROWSER_RUNTIME_SBOM_SCAN_REJECTED ' + '; '.join(coverage['blockingErrors']), file=sys.stderr)
        return 1
    print('BROWSER_RUNTIME_SBOM_SCAN_READY npm_recognized=%d unsupported=%d findings=%d coverage=%s exact_finding_gate=pending' % (
        coverage['npm']['recognizedComponentCount'], len(coverage['unsupportedComponents']),
        coverage['findingOccurrences'], coverage['coverage']))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

#!/usr/bin/env python3
"""Verify the independent browser SBOM against the exact Web Console release."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError('WEB_CONSOLE_SBOM_DUPLICATE_JSON_KEY')
        result[key] = value
    return result


def verify(sbom, *, sbom_sha256, version, source_commit, archive_name,
           archive_sha256, lock_sha256, archive=None):
    for value in (sbom_sha256, archive_sha256, lock_sha256):
        if not re.fullmatch(r'[0-9a-f]{64}', value):
            raise ValueError('WEB_CONSOLE_SBOM_INVALID_SHA256_PIN')
    if not re.fullmatch(r'[0-9a-f]{40}', source_commit):
        raise ValueError('WEB_CONSOLE_SBOM_INVALID_SOURCE_PIN')
    if not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', version):
        raise ValueError('WEB_CONSOLE_SBOM_INVALID_VERSION_PIN')
    if archive_name != f'web-console-{version}.tar.gz':
        raise ValueError('WEB_CONSOLE_SBOM_ARCHIVE_NAME_MISMATCH')
    filename = Path(sbom)
    if filename.is_symlink() or not filename.is_file():
        raise ValueError('WEB_CONSOLE_SBOM_MISSING_OR_LINKED')
    payload = filename.read_bytes()
    if hashlib.sha256(payload).hexdigest() != sbom_sha256:
        raise ValueError('WEB_CONSOLE_SBOM_SHA256_MISMATCH')
    if archive is not None:
        archive_path = Path(archive)
        if archive_path.is_symlink() or not archive_path.is_file():
            raise ValueError('WEB_CONSOLE_SBOM_ARCHIVE_MISSING_OR_LINKED')
        if hashlib.sha256(archive_path.read_bytes()).hexdigest() != archive_sha256:
            raise ValueError('WEB_CONSOLE_SBOM_ARCHIVE_SHA256_MISMATCH')
    data = json.loads(payload.decode('utf-8'), object_pairs_hook=unique_object)
    if (data.get('bomFormat'), data.get('specVersion'), data.get('version')) != (
            'CycloneDX', '1.6', 1):
        raise ValueError('WEB_CONSOLE_SBOM_FORMAT_MISMATCH')
    metadata = data.get('metadata', {})
    component = metadata.get('component', {})
    expected_component = {
        'type': 'application',
        'name': '@pasturestack/web-console',
        'version': version,
        'purl': f'pkg:npm/%40pasturestack/web-console@{version}',
        'bom-ref': f'artifact:{archive_name}',
    }
    for field, expected in expected_component.items():
        if component.get(field) != expected:
            raise ValueError(f'WEB_CONSOLE_SBOM_COMPONENT_{field.upper()}_MISMATCH')
    if component.get('hashes') != [{'alg': 'SHA-256', 'content': archive_sha256}]:
        raise ValueError('WEB_CONSOLE_SBOM_COMPONENT_ARCHIVE_SHA256_MISMATCH')
    properties = {}
    for item in metadata.get('properties', []):
        name, value = item['name'], item['value']
        if name in properties:
            raise ValueError('WEB_CONSOLE_SBOM_DUPLICATE_PROPERTY')
        properties[name] = value
    expected_properties = {
        'pasturestack:source-commit': source_commit,
        'pasturestack:lock-sha256': lock_sha256,
        'pasturestack:archive-name': archive_name,
        'pasturestack:archive-sha256': archive_sha256,
        'pasturestack:phase': 'runtime',
    }
    for name, expected in expected_properties.items():
        if properties.get(name) != expected:
            raise ValueError(f'WEB_CONSOLE_SBOM_PROPERTY_MISMATCH {name}')
    coverage = properties.get('pasturestack:coverage')
    if coverage not in ('complete', 'incomplete'):
        raise ValueError('WEB_CONSOLE_SBOM_COVERAGE_MISSING')
    if not isinstance(data.get('components'), list) or not data['components']:
        raise ValueError('WEB_CONSOLE_SBOM_COMPONENT_INVENTORY_MISSING')
    return {
        'version': version,
        'source': source_commit,
        'archive_sha256': archive_sha256,
        'sbom_sha256': sbom_sha256,
        'lock_sha256': lock_sha256,
        'phase': 'runtime',
        'coverage': coverage,
        'components': len(data['components']),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sbom', required=True)
    parser.add_argument('--sbom-sha256', required=True)
    parser.add_argument('--version', required=True)
    parser.add_argument('--source-commit', required=True)
    parser.add_argument('--archive-name', required=True)
    parser.add_argument('--archive-sha256', required=True)
    parser.add_argument('--lock-sha256', required=True)
    parser.add_argument('--archive')
    args = vars(parser.parse_args())
    try:
        result = verify(**args)
    except (ValueError, OSError, KeyError, TypeError, AttributeError) as error:
        print(f'WEB_CONSOLE_SBOM_REJECTED {error}', file=sys.stderr)
        return 1
    print('WEB_CONSOLE_RUNTIME_SBOM_OK ' + ' '.join(
        f'{name}={value}' for name, value in result.items()))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

#!/usr/bin/env python3
"""Verify the released default Catalog by indexed commit and exact API identity."""
import argparse
import json
import re
import subprocess
import time
from pathlib import Path


def verify_source(source, catalog_name, platform_version, read):
    catalog = read('/v1-catalog/catalogs/' + catalog_name)
    if catalog.get('commit') != source['pinnedCommit']:
        raise RuntimeError('Catalog indexed commit differs from the release pin')
    if catalog.get('url') != source['url'] or (catalog.get('branch') or 'master') != source['branch']:
        raise RuntimeError('Catalog source differs from the release identity')
    count = 0
    for required in source['requiredTemplates']:
        folder = (required['base'] + '*' if required.get('base') else '') + required['name']
        # Existing Stack externalIds retain library:infra*container-crontab.
        # A canonical-only read cannot prove the read-only legacy alias works.
        namespaces = (catalog_name, 'library') if folder == 'infra*container-crontab' else (catalog_name,)
        for namespace in namespaces:
            template_id = namespace + ':' + folder
            version_id = template_id + ':' + str(required['revision'])
            for kind, identity in (('templates', template_id), ('templateversions', version_id)):
                body = read('/v1-catalog/' + kind + '/' + identity + '?rancherVersion=' + platform_version)
                if body.get('id') != identity:
                    raise RuntimeError('Catalog exact API response identity mismatch')
                count += 1
    if not count:
        raise RuntimeError('Release manifest declares no required Catalog versions')
    return count


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--container', required=True)
    parser.add_argument('--manifest', type=Path, required=True)
    parser.add_argument('--version', required=True)
    parser.add_argument('--timeout', type=float, default=120)
    args = parser.parse_args()
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]*', args.container) or not re.fullmatch(r'v[0-9]+\.[0-9]+\.[0-9]+', args.version):
        parser.error('Invalid candidate identity')
    if not 0 < args.timeout <= 600:
        parser.error('Timeout must be between 0 and 600 seconds')
    manifest = json.loads(args.manifest.read_text(encoding='utf-8'))
    sources = manifest['sources']
    if manifest['version'] != 1 or len(sources) != 1:
        raise RuntimeError('Default release verification requires one exact bundled source')
    source = sources[0]
    deadline = time.monotonic() + args.timeout

    def read(path):
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise RuntimeError('Catalog release verification deadline elapsed')
        response = subprocess.run([
            'docker', 'exec', args.container, 'curl', '-sS', '--connect-timeout', '2',
            '--max-time', str(min(5, remaining)), '-H', 'X-Api-Project-Id: global',
            '-w', '\n%{http_code}', 'http://127.0.0.1:8088' + path,
        ], capture_output=True, text=True, timeout=min(8, remaining + 1))
        body, separator, status = response.stdout.rpartition('\n')
        if response.returncode or not separator or status != '200':
            raise RuntimeError('Catalog exact API is not HTTP 200')
        try:
            return json.loads(body)
        except ValueError:
            raise RuntimeError('Catalog exact API is not JSON') from None

    last_error = 'Catalog not available'
    while time.monotonic() < deadline:
        try:
            count = verify_source(source, 'pasturestack', args.version, read)
            print('CATALOG_RELEASE_READY_OK commit=' + source['pinnedCommit'] + ' exact_api_reads=' + str(count))
            return
        except (RuntimeError, subprocess.TimeoutExpired) as error:
            last_error = str(error) if isinstance(error, RuntimeError) else 'Catalog query exceeded its deadline'
            time.sleep(min(1, max(0, deadline - time.monotonic())))
    raise RuntimeError(last_error)


if __name__ == '__main__':
    main()

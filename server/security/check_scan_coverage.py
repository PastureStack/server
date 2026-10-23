"""Reject a clean-looking scan that did not analyze the active Go payloads."""
import json
from pathlib import Path, PurePosixPath

ROOT_BINARIES = frozenset({
    'pasturestack-console-broker', 'authentication-service.real',
    'catalog-service.real', 'catalog-service-sqlite', 'websocket-proxy.real',
    'host-provisioner.real', 'usage-telemetry-agent', 'compose-executor.real',
    'secret-delivery-api', 'webhook-automation-service', 'govc',
})
NESTED_BINARIES = frozenset({
    'host-api-linux-amd64', 'node-agent-linux-amd64',
    'node-agent-windows-amd64.exe', 'per-host-subnet-windows-amd64.exe',
})


def validate_coverage(report, expected):
    if not isinstance(report, dict) or report.get('SchemaVersion') != 2:
        raise ValueError('Missing Trivy schema')
    results = report.get('Results')
    if not isinstance(results, list) or not results:
        raise ValueError('Missing scan results')
    found = set()
    for result in results:
        if result.get('Type') != 'gobinary':
            continue
        packages = result.get('Packages')
        if not isinstance(packages, list) or not packages:
            raise ValueError('Go binary dependency analysis is missing')
        found.add(PurePosixPath(result['Target']).name)
    missing = expected - found
    if missing:
        raise ValueError('Missing active Go binary coverage: ' + ', '.join(sorted(missing)))
    return len(found)


if __name__ == '__main__':
    # The publisher runs from its evidence directory. No user-supplied file paths.
    root = json.loads(Path('server-security-scan-raw.json').read_text(encoding='utf-8'))
    nested = json.loads(Path('server-nested-scan-raw.json').read_text(encoding='utf-8'))
    root_count = validate_coverage(root, ROOT_BINARIES)
    nested_count = validate_coverage(nested, NESTED_BINARIES)
    print('SERVER_GO_SCAN_COVERAGE_OK root=%d nested=%d' % (root_count, nested_count))

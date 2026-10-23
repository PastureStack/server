"""Reject a clean-looking scan that did not analyze the active Go payloads."""
import hashlib
import json
from pathlib import Path, PurePosixPath

ROOT_BINARIES = frozenset({
    'pasturestack-console-broker', 'authentication-service.real',
    'catalog-service.real', 'catalog-service-sqlite', 'websocket-proxy.real',
    'host-provisioner.real', 'usage-telemetry-agent', 'compose-executor.real',
    'secret-delivery-api', 'webhook-automation-service', 'govc',
    'docker-machine', 'docker-machine-driver-packet',
})
NESTED_BINARIES = frozenset({
    'host-api-linux-amd64', 'node-agent-linux-amd64',
    'node-agent-windows-amd64.exe', 'per-host-subnet-windows-amd64.exe',
})
# The module-level VEX must not silently apply to a new OpenPGP consumer.
# These exact shipped executables have separately verified source/binary
# dependency graphs; the image builder pins their producer and payload SHA256.
OPENPGP_VEX_SCOPE = frozenset({
    ('usr/bin/authentication-service.real', 'pkg:golang/golang.org/x/crypto@v0.57.0'),
    ('usr/bin/docker-machine', 'pkg:golang/golang.org/x/crypto@v0.57.0'),
    ('usr/bin/docker-machine-driver-packet', 'pkg:golang/golang.org/x/crypto@v0.57.0'),
    ('usr/bin/compose-executor.real', 'pkg:golang/golang.org/x/crypto@v0.56.0'),
    ('usr/bin/host-provisioner.real', 'pkg:golang/golang.org/x/crypto@v0.56.0'),
})
OPENPGP_VEX_BINARY_SHA256 = {
    'usr/bin/authentication-service.real': 'e121cee8b7a6bd3c0eb6fe3e15ff304b78119b426642ed76f13e3d92be161192',
    'usr/bin/docker-machine': '9d379214de116542cb0e2b1a09c17409fd59fd2b0109428896d81de9cf9c0d31',
    'usr/bin/docker-machine-driver-packet': 'b3e5c71928fcebe1bb648f79ebbf38af9ad32d6f6dbb87587e1b92c6c331e100',
    'usr/bin/compose-executor.real': '0f0c0ada23564572b569e1c73951ca363c0dc262fe7bba9c2474106650c4eac5',
    'usr/bin/host-provisioner.real': '92c6d9ce1222a93802ff2c92b100eeb6c58286f3fca90698f9687b92d6fa9dff',
}


def validate_vex_payloads(report, rootfs):
    """Bind a component-absence claim to the reviewed binary, not just its name."""
    rootfs = rootfs.resolve()
    checked = set()
    for result in report['Results']:
        if not any(v.get('VulnerabilityID') == 'GO-2026-5932'
                   for v in result.get('Vulnerabilities') or []):
            continue
        target = result['Target']
        expected = OPENPGP_VEX_BINARY_SHA256.get(target)
        payload = (rootfs / target).resolve()
        if not expected or rootfs not in payload.parents or not payload.is_file():
            raise ValueError('Unreviewed OpenPGP payload: ' + target)
        checksum = hashlib.sha256()
        with payload.open('rb') as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b''):
                checksum.update(chunk)
        if checksum.hexdigest() != expected:
            raise ValueError('Changed OpenPGP VEX payload: ' + target)
        checked.add(target)
    return len(checked)


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
        for finding in result.get('Vulnerabilities') or []:
            if finding.get('VulnerabilityID') == 'GO-2026-5932':
                identity = (result.get('Target'), finding.get('PkgIdentifier', {}).get('PURL'))
                if identity not in OPENPGP_VEX_SCOPE:
                    raise ValueError('Unreviewed OpenPGP VEX scope: ' + str(identity))
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
    validate_vex_payloads(root, Path('../server-rootfs'))
    print('SERVER_GO_SCAN_COVERAGE_OK root=%d nested=%d' % (root_count, nested_count))

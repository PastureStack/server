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
    ('usr/bin/docker-machine', 'pkg:golang/golang.org/x/crypto@v0.58.0'),
    ('usr/bin/docker-machine-driver-packet', 'pkg:golang/golang.org/x/crypto@v0.58.0'),
    ('usr/bin/compose-executor.real', 'pkg:golang/golang.org/x/crypto@v0.56.0'),
    ('usr/bin/host-provisioner.real', 'pkg:golang/golang.org/x/crypto@v0.56.0'),
})
OPENPGP_VEX_BINARY_SHA256 = {
    'usr/bin/docker-machine': 'f77366c8460baf78798dcaaa675cdd5f656c9670b79c651983129c55bb41dd37',
    'usr/bin/docker-machine-driver-packet': '601e958704a2eea7bd3872db99b54007fe2b04cd0c66e96ccf15c50133f4dba0',
    'usr/bin/compose-executor.real': 'a22985547fea122edd12606728d3bc5f98d9457ae5724d65a21ef3c36d62cab5',
    'usr/bin/host-provisioner.real': '54c22fa95bb16ce9b49df6bec012b9103f3e1b0eafc947d205eaef49e11b45a8',
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

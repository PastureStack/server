"""Focused source contracts only: no image build, install, scan or publication."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
DOCKER = 'server/Dockerfile.web-compose-release'
BUILD = 'server/build-api-explorer-patch-image.sh'
PUBLISH = '.github/workflows/publish-current-server.yml'
FILES = {name: (ROOT / name).read_text(encoding='utf-8') for name in (DOCKER, BUILD, PUBLISH)}


def require(value, message):
    if not value:
        raise AssertionError(message)


def verify(files):
    docker, build, publisher = (files[name] for name in (DOCKER, BUILD, PUBLISH))
    image = re.findall(r'^FROM (ghcr.io/pasturestack/ubuntu-security-backports:v0\.1\.0@sha256:'
                       r'[0-9a-f]{64}) AS ubuntu_security_backports$', docker, re.M)
    require(len(image) == 1 and docker.count("'" + image[0] + "'") == 1, 'Bundle image/retained identity mismatch')
    native = docker.split('AS runtime_security_packages', 1)[1].split('FROM ${BASE_IMAGE}', 1)[0]
    require('build-pcre2-backport.py' not in docker and 'build-essential' not in native,
            'Server consumer must not compile qualified PCRE2 again')
    for marker in ['source=/out,target=/bundle,ro',
                   'sha256sum --check --status SHA256SUMS', 'dpkg-deb --extract "${archive}" /tmp/pcre2-runtime',
                   '/bundle/provenance/pcre2/provenance.json', '/bundle/provenance/pcre2/pcre2.lock.json',
                   'sha256sum usr/lib/x86_64-linux-gnu/libpcre2-8.so.0 usr/lib/x86_64-linux-gnu/libpcre2-posix.so.3']:
        require(marker in native, 'Missing producer-derived PCRE compatibility receipt: ' + marker)
    for marker in ['ARG GLIBC_PACKAGE_VERSION=2.43-2ubuntu2.4\n',
                   'ARG GLIBC_RUNTIME_PACKAGE_VERSION=2.43-2ubuntu2.4+pasturestack.1',
                   'ENV PASTURESTACK_GLIBC_OFFICIAL_PACKAGE_VERSION=${GLIBC_PACKAGE_VERSION}',
                   'ENV PASTURESTACK_GLIBC_PACKAGE_VERSION=${GLIBC_RUNTIME_PACKAGE_VERSION}',
                   'ENV PASTURESTACK_GLIBC_CVE_2026_18374_FIX=official-source-backport']:
        require(marker in docker, 'Official download/custom runtime version boundary changed')
    require('PASTURESTACK_GLIBC_PACKAGE_VERSION=2.43-2ubuntu2.4+pasturestack.1' in build,
            'Runtime readback still expects the original libc version')
    runtime = docker.split('source=/out,target=/opt/pasturestack/ubuntu-security-backports,ro', 1)[1]
    positions = [runtime.index(marker) for marker in [
        'sh /tmp/pasturestack-security-input/install-ubuntu-security-updates.sh',
        'rm -f /usr/lib/x86_64-linux-gnu/libexpat.so.1',
        '"${data}/install-existing-backports" --install-in-docker-build',
        '"${data}/install-existing-backports" --verify-installed',
        '\n    sh /usr/local/libexec/pasturestack/verify-pcre2-runtime.sh',
        'libpng_linkage="$(ldd -r /usr/lib/x86_64-linux-gnu/libpng16.so.16']]
    require(positions == sorted(positions), 'Final libraries/install/verification order changed')
    require('for package in rust-coreutils jq libjq1 libc6-dev libc-dev-bin libpcre2-dev libp11-kit-dev libxrender-dev;' in runtime,
            'Server absent-package boundary is missing')
    require('install -m 0644 pcre2-backport-provenance.json pcre2-backport.lock.json pcre2-runtime.sha256 /usr/share/pasturestack/security/' in runtime,
            'Legacy verifier metadata is not installed')
    require('sha256sum manifest.json qualification.json openvex.json source-inputs.lock.json install.json verify.json bundle-image.txt > SHA256SUMS' in runtime,
            'Seven retained consumer evidence files are not bound')
    require('/opt/java/openjdk/bin/java -version 2>&1 | grep -F' in runtime, 'Final Java/libc readback is missing')
    raw_end = publisher.index('--output /evidence/server-security-scan-raw.json')
    raw = publisher[publisher.rfind('          docker run --rm', 0, raw_end):raw_end]
    require('--scanners vuln,secret --list-all-pkgs' in raw and not any(
        option in raw for option in ['--vex', '--offline-scan', '--network none', '--ignorefile']),
        'Original full raw scanner capability changed')
    require('--bundle-checksums' in publisher, 'Producer checksum binding is missing')
    require(publisher.index('--output /evidence/server.cdx.json') < publisher.index('--bundle-checksums')
            < publisher.index('--vex /evidence/ubuntu-backports/openvex.json'), 'Producer/SBOM closure must precede native VEX')
    for marker in ['--bundle-checksums "$evidence/bundle-tools/SHA256SUMS"',
                   '--expected-bundle-digest "${bundle_image##*@}"',
                   '--vex /evidence/server.openvex.json', '--vex /evidence/ubuntu-backports/openvex.json',
                   '"$evidence/ubuntu-backports-evidence.tar"', '              ubuntu-backports-evidence.tar']:
        require(marker in publisher, 'Missing retained producer/native VEX gate: ' + marker)
    ledger = publisher.split('bash source/scripts/validate-vendor-pending-findings.sh', 1)[1].split('\n\n', 1)[0]
    require('ubuntu-backports-evidence.tar' not in ledger
            and '"$evidence/server-vulnerabilities-unresolved.tsv"' in ledger,
            'Original vendor-pending validation arguments changed')
    release = publisher.split('gh release create "$RELEASE_TAG"', 1)[1].split('\n\n', 1)[0]
    require('"$evidence/ubuntu-backports-evidence.tar"' in release, 'Producer evidence is not a release asset')


class ServerBackportContract(unittest.TestCase):
    def test_current_source_contract(self):
        verify(FILES)

    def test_source_compile_or_absent_package_boundary_regression_is_rejected(self):
        for old, new in [('target=/bundle,ro', 'target=/bundle,ro # build-pcre2-backport.py'),
                         ('for package in rust-coreutils jq libjq1 libc6-dev', 'for package in libc6-dev')]:
            with self.subTest(old=old), self.assertRaises(AssertionError):
                verify(dict(FILES, **{DOCKER: FILES[DOCKER].replace(old, new)}))

    def test_official_runtime_version_conflation_is_rejected(self):
        with self.assertRaises(AssertionError):
            verify(dict(FILES, **{DOCKER: FILES[DOCKER].replace(
                'ENV PASTURESTACK_GLIBC_PACKAGE_VERSION=${GLIBC_RUNTIME_PACKAGE_VERSION}',
                'ENV PASTURESTACK_GLIBC_PACKAGE_VERSION=${GLIBC_PACKAGE_VERSION}')}))

    def test_unbound_vex_or_narrowed_raw_scan_is_rejected(self):
        for old, new in [('--bundle-checksums', '--candidate-checksums'),
                         ('--scanners vuln,secret --list-all-pkgs', '--scanners vuln,secret --list-all-pkgs --offline-scan')]:
            with self.subTest(old=old), self.assertRaises(AssertionError):
                verify(dict(FILES, **{PUBLISH: FILES[PUBLISH].replace(old, new)}))

    def test_unresolved_bundle_identity_is_rejected(self):
        broken = re.sub(r'(ubuntu-security-backports:v0\.1\.0@sha256:)[0-9a-f]{64}',
                        r'\1__BUNDLE_DIGEST_PENDING__', FILES[DOCKER])
        with self.assertRaises(AssertionError):
            verify(dict(FILES, **{DOCKER: broken}))


if __name__ == '__main__':
    unittest.main(verbosity=2)

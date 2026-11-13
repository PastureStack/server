#!/usr/bin/env python3
"""Server-only official replacement closure; no SBOM or finding transformation."""
import argparse
import subprocess
import importlib.util
import json
from pathlib import Path


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


GLIBC_VERSION = '2.43-2ubuntu2.7'
GLIBC_PACKAGES = ('libc6', 'libc-bin', 'libc-gconv-modules-extra')


def verify_glibc(root, verifier):
    root = root.resolve(strict=True)
    status = verifier.bounded_read(root / 'var/lib/dpkg/status').decode()
    rows = {}
    for stanza in status.split('\n\n'):
        fields = dict(line.split(': ', 1) for line in stanza.splitlines() if ': ' in line and not line.startswith(' '))
        name = fields.get('Package')
        if name in GLIBC_PACKAGES:
            verifier.require(name not in rows, 'Duplicate libc package in the final image')
            rows[name] = fields
    proof = {}
    for name in GLIBC_PACKAGES:
        row = rows.get(name, {})
        verifier.require(row.get('Status') == 'install ok installed'
                         and row.get('Version') == GLIBC_VERSION
                         and row.get('Architecture') == 'amd64'
                         and row.get('Source') == 'glibc',
                         'Final Ubuntu glibc identity mismatch: ' + name)
        integrity = subprocess.run(['dpkg', '--root=' + str(root), '--verify', name],
                                   capture_output=True, text=True, timeout=30)
        verifier.require(integrity.returncode == 0 and not integrity.stdout.strip()
                         and not integrity.stderr.strip(), 'Final Ubuntu glibc payload verification failed: ' + name)
        proof[name] = {'name': name, 'version': GLIBC_VERSION,
                       'purl': verifier.package_purl({'name': name, 'version': GLIBC_VERSION})}
    return proof


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('evidence-dir', 'sbom', 'bundle-checksums', 'legacy-helper', 'rootfs', 'official-brotli-dir'):
        parser.add_argument('--' + name, type=Path, required=True)
    parser.add_argument('--expected-bundle-digest', required=True)
    args = parser.parse_args()
    current = load(Path(__file__).parent / 'ubuntu-backports/bundle/verify-consumer-evidence.py', 'server_consumer')
    sums = current.bounded_read(args.bundle_checksums)
    helper_sha = [line.split('  ')[0] for line in sums.decode().splitlines()
                  if line.endswith('  verify-consumer-evidence.py')]
    current.require(len(helper_sha) == 1 and current.sha(current.bounded_read(args.legacy_helper)) == helper_sha[0],
                    'Original immutable OCI helper bytes do not match its checksum')
    original = load(args.legacy_helper, 'immutable_consumer')
    current.require(original.FILES == current.FILES and len(original.FILES) == 7, 'Original seven-file evidence boundary changed')
    files = {name: current.bounded_read(args.evidence_dir / name) for name in original.FILES}
    retained_sums = current.bounded_read(args.evidence_dir / 'SHA256SUMS')
    expected = {name: digest for line in retained_sums.decode().splitlines()
                for digest, separator, name in [line.partition('  ')] if separator}
    current.require(set(expected) == set(original.FILES) and all(current.sha(files[n]) == expected[n] for n in original.FILES),
                    'Original seven evidence bytes differ')
    directory = args.official_brotli_dir
    result = current.verify(files, retained_sums, json.loads(current.bounded_read(args.sbom)),
        args.expected_bundle_digest, sums, official_brotli={'rootfs': args.rootfs,
        'lock': directory / 'lock.json', 'receipt': directory / 'runtime.json', 'deb': directory / 'libbrotli1.deb',
        'signedIndex': directory / 'signed-index'}, official_glibc=verify_glibc(args.rootfs, current))
    result.update(originalHelperSha256=helper_sha[0], serverHelperSha256=current.sha(Path(current.__file__).read_bytes()),
                  serverWrapperSha256=current.sha(Path(__file__).read_bytes()), originalEvidencePreserved=True)
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == '__main__':
    main()

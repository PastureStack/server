#!/usr/bin/env python3
"""Server-only official replacement closure; no SBOM or finding transformation."""
import argparse
import importlib.util
import json
from pathlib import Path


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


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
        'signedIndex': directory / 'signed-index'})
    result.update(originalHelperSha256=helper_sha[0], serverHelperSha256=current.sha(Path(current.__file__).read_bytes()),
                  serverWrapperSha256=current.sha(Path(__file__).read_bytes()), originalEvidencePreserved=True)
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == '__main__':
    main()

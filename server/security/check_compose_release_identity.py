"""Bind packaged Compose metadata to the reviewed original release artifact."""
import argparse
import json
from pathlib import Path
import re

def load_review(version):
    # Release recipes can select a registered coordinate, never an arbitrary
    # command-line file. New releases require their reviewed record in source.
    if version != '0.14.45':
        raise ValueError('ComposeReleaseIdentityReviewRequired')
    path = Path(__file__).resolve().parent / 'reviews/compose-0.14.45-openpgp.json'
    if not path.is_file() or path.is_symlink() or path.stat().st_size > 65536:
        raise ValueError('ComposeReleaseIdentityReviewRequired')
    return json.loads(path.read_text(encoding='utf-8'))


def validate(review, version, source, archive, binary):
    artifact = review.get('artifact', {})
    actual = {'releaseVersion': version, 'source': source,
              'releaseGzipSha256': archive, 'binarySha256': binary}
    patterns = {'releaseVersion': r'[0-9]+\.[0-9]+\.[0-9]+',
                'source': r'[0-9a-f]{40}', 'releaseGzipSha256': r'[0-9a-f]{64}',
                'binarySha256': r'[0-9a-f]{64}'}
    for field, value in actual.items():
        if not isinstance(value, str) or not re.fullmatch(patterns[field], value) or artifact.get(field) != value:
            raise ValueError('ComposeReleaseIdentityMismatch:' + field)
    return actual


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for field in ('version', 'source', 'archive', 'binary'):
        parser.add_argument('--' + field, required=True)
    args = parser.parse_args()
    result = validate(load_review(args.version),
                      args.version, args.source, args.archive, args.binary)
    print(json.dumps({'status': 'COMPOSE_RELEASE_IDENTITY_OK', **result}))


if __name__ == '__main__':
    main()

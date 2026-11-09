"""Bind packaged Compose metadata to the reviewed original release artifact."""
import argparse
import json
from pathlib import Path
import re


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
    for field in ('review', 'version', 'source', 'archive', 'binary'):
        parser.add_argument('--' + field, required=True)
    args = parser.parse_args()
    path = Path(args.review)
    if not path.is_file() or path.is_symlink() or path.stat().st_size > 65536:
        raise ValueError('ComposeReleaseIdentityReviewRequired')
    result = validate(json.loads(path.read_text(encoding='utf-8')),
                      args.version, args.source, args.archive, args.binary)
    print(json.dumps({'status': 'COMPOSE_RELEASE_IDENTITY_OK', **result}))


if __name__ == '__main__':
    main()

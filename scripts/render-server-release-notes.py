"""Render publication-time identity without claiming deployment acceptance."""
import argparse
from pathlib import Path
import re


def render(source, tag, digest, revision):
    if not re.fullmatch(r'v\d+\.\d+\.\d+', tag):
        raise ValueError('Expected numeric release tag')
    if not re.fullmatch(r'sha256:[0-9a-f]{64}', digest):
        raise ValueError('Published image digest required')
    if not re.fullmatch(r'[0-9a-f]{40}', revision):
        raise ValueError('Exact source revision required')
    if not source.startswith('# Server ' + tag + ' candidate\n'):
        raise ValueError('Candidate notes do not match published version')
    heading = '## Verified component inputs\n'
    if source.count(heading) != 1:
        raise ValueError('Missing component evidence boundary')
    body = heading + source.split(heading, 1)[1]
    # Only candidate-boundary text is discarded by rendering. Do not publish a
    # contradictory prospective Server status from the retained evidence body.
    pending_server = (r'\bServer build(?:,\s+publication| and publication)'
                      r'(?:,\s+deployment and affected native/UI workflows)?'
                      r'\s+(?:remain|remains|is|are)\s+pending\b')
    for paragraph in re.split(r'\n[ \t]*\n', body):
        if re.search(pending_server, ' '.join(paragraph.split()), re.IGNORECASE):
            raise ValueError('Server build/publication pending text must move to '
                             'Candidate boundary before ## Verified component inputs')
    return (f'# Server {tag}\n\n'
            f'Published image: `ghcr.io/pasturestack/server:{tag}@{digest}`.\n\n'
            f'Source commit: `{revision}`.\n\n'
            'The release workflow passed its source, security, startup and restart '
            'checks before publishing this image. Deployment-specific acceptance '
            'is separate and is not claimed by these build results.\n\n' + body)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    parser.add_argument('tag')
    parser.add_argument('digest')
    parser.add_argument('revision')
    args = parser.parse_args()
    print(render(args.source.read_text(encoding='utf-8'), args.tag, args.digest, args.revision), end='')

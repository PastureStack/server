"""Offline, in-memory checks of the changed published-install contract only."""
import pathlib
import re
import unittest
from unittest.mock import patch

REPO = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = (REPO / 'scripts/check-server-api-explorer-patch.sh').read_text(encoding='utf-8')
MARKER = '# Install examples must follow the highest actually published numeric release;'
ADAPTER = SCRIPT.split(MARKER, 1)[1].split("python3 - <<'PY'\n", 1)[1].split('\nPY\n', 1)[0]
FILES = {name: (REPO / name).read_text(encoding='utf-8') for name in
         ('README.md', 'COMPATIBILITY.md', 'docs/releases/server-1.6.498.md')}
IMAGE = 'ghcr.io/pasturestack/server:v1.6.498@sha256:bd8671e99fbf3661f91d6667f6cb04b16ade89a8d463ae872ffd84ce1e65a6e7'


def verify(files):
    def read(file, **_):
        return files[file.as_posix()]
    with patch.object(pathlib.Path, 'read_text', read), patch('builtins.print'):
        exec(compile(ADAPTER, 'published-install-contract', 'exec'), {})


class Tests(unittest.TestCase):
    def test_current_published498_and_preparing499_are_distinct(self):
        verify(FILES)

    def test_previous_install_target_rejected(self):
        files = dict(FILES)
        first, quick = files['README.md'].split('## Quick start', 1)
        files['README.md'] = first + '## Quick start' + quick.replace(IMAGE, IMAGE.replace('v1.6.498', 'v1.6.497'))
        with self.assertRaisesRegex(SystemExit, 'QUICK_START_MISMATCH'):
            verify(files)

    def test_docker_compose_identity_mismatch_rejected(self):
        files = dict(FILES)
        files['README.md'] = files['README.md'].replace('    image: ' + IMAGE, '    image: ' + IMAGE[:-1] + '0')
        with self.assertRaisesRegex(SystemExit, 'QUICK_START_MISMATCH'):
            verify(files)

    def test_suffix_cannot_hide_digest_mismatch(self):
        files = dict(FILES)
        files['README.md'] = files['README.md'].replace('    image: ' + IMAGE, '    image: ' + IMAGE + '-unexpected')
        with self.assertRaisesRegex(SystemExit, 'QUICK_START_MISMATCH'):
            verify(files)

    def test_next_published_numeric_release_without_gate_relabel(self):
        files = dict(FILES)
        next_image = 'ghcr.io/pasturestack/server:v1.6.500@sha256:' + 'a' * 64
        files['README.md'] = ('## v1.6.500\n\nThe immutable image is `' + next_image + '`.\n\n' +
                              files['README.md'])
        first, quick = files['README.md'].split('## Quick start', 1)
        files['README.md'] = first + '## Quick start' + quick.replace(IMAGE, next_image).replace('/tag/v1.6.498', '/tag/v1.6.500')
        files['COMPATIBILITY.md'] += '\n' + next_image
        files['docs/releases/server-1.6.500.md'] = '# Server v1.6.500\n\n' + next_image
        verify(files)


if __name__ == '__main__':
    unittest.main(verbosity=2)

"""Offline, in-memory checks of the changed published-install contract only."""
import pathlib
import re
import unittest
from unittest.mock import patch

REPO = pathlib.Path(__file__).resolve().parents[1]
SCRIPT = (REPO / 'scripts/check-server-api-explorer-patch.sh').read_text(encoding='utf-8')
MARKER = '# Install examples must follow the highest actually published numeric release;'
ADAPTER = SCRIPT.split(MARKER, 1)[1].split("python3 - <<'PY'\n", 1)[1].split('\nPY\n', 1)[0]
INSTALL_IMAGE = 'ghcr.io/pasturestack/server:v1.6.498'
PUBLISHED_IMAGE = INSTALL_IMAGE + '@sha256:bd8671e99fbf3661f91d6667f6cb04b16ade89a8d463ae872ffd84ce1e65a6e7'
PERFORMANCE = 'docs/performance/README.md'
FILES = {
    'README.md': ('## Current release\n\n'
                  '[Server v1.6.498](https://github.com/PastureStack/server/releases/tag/v1.6.498)\n'
                  '[release note](docs/releases/server-1.6.498.md)\n\n## Quick start\n\n'
                  '```sh\ndocker run\n  ' + INSTALL_IMAGE + '\n```\n\n```yaml\nservices:\n  server:\n    image: ' + INSTALL_IMAGE + '\n```\n'),
    PERFORMANCE: '```yaml\nservices:\n  server:\n    image: ' + INSTALL_IMAGE + '\n```\n',
    'COMPATIBILITY.md': 'Server v1.6.499 preparing; no published digest.\nPublished Server v1.6.498\n' + PUBLISHED_IMAGE,
    'docs/releases/server-1.6.498.md': '# Server v1.6.498\n\nOfficially published: ' + PUBLISHED_IMAGE,
}


def verify(files):
    def read(file, **_):
        return files[file.as_posix()]
    with patch.object(pathlib.Path, 'read_text', read), patch('builtins.print'):
        exec(compile(ADAPTER, 'published-install-contract', 'exec'), {})


class Tests(unittest.TestCase):
    def test_checked_out_install_documents_match_actual_latest_publication(self):
        readme = (REPO / 'README.md').read_text(encoding='utf-8')
        tags = set(re.findall(r'https://github\.com/PastureStack/server/releases/tag/(v[0-9]+\.[0-9]+\.[0-9]+)', readme))
        files = {'README.md': readme, 'COMPATIBILITY.md': (REPO / 'COMPATIBILITY.md').read_text(encoding='utf-8'),
                 PERFORMANCE: (REPO / PERFORMANCE).read_text(encoding='utf-8')}
        for tag in tags:
            notes = REPO / ('docs/releases/server-' + tag[1:] + '.md')
            if notes.is_file():
                files['docs/releases/server-' + tag[1:] + '.md'] = notes.read_text(encoding='utf-8')
        verify(files)

    def test_current_release_and_quick_start_need_no_readme_history(self):
        self.assertNotRegex(FILES['README.md'], r'(?m)^## v[0-9]')
        verify(FILES)

    def test_preparing_higher_release_without_digest_is_not_installable(self):
        files = dict(FILES)
        files['COMPATIBILITY.md'] = '## Server v1.6.999 preparing\n\nNo publication yet.\n\n' + files['COMPATIBILITY.md']
        verify(files)

    def test_missing_or_ambiguous_current_release_link_rejected(self):
        for readme in (FILES['README.md'].replace('## Current release', '## Release'),
                       FILES['README.md'].replace('[release note]', '[other](https://github.com/PastureStack/server/releases/tag/v1.6.497)\n[release note]')):
            with self.subTest(readme=readme):
                files = dict(FILES)
                files['README.md'] = readme
                with self.assertRaisesRegex(SystemExit, 'IDENTITY_MISSING'):
                    verify(files)

    def test_previous_install_target_rejected(self):
        files = dict(FILES)
        first, quick = files['README.md'].split('## Quick start', 1)
        files['README.md'] = first + '## Quick start' + quick.replace(INSTALL_IMAGE, INSTALL_IMAGE.replace('v1.6.498', 'v1.6.497'))
        with self.assertRaisesRegex(SystemExit, 'QUICK_START_MISMATCH'):
            verify(files)

    def test_entire_previous_install_target_rejected_by_publication_evidence(self):
        files = dict(FILES)
        old_image = PUBLISHED_IMAGE.replace('v1.6.498', 'v1.6.497')
        files['README.md'] = files['README.md'].replace('v1.6.498', 'v1.6.497').replace('server-1.6.498.md', 'server-1.6.497.md')
        files[PERFORMANCE] = files[PERFORMANCE].replace('v1.6.498', 'v1.6.497')
        files['COMPATIBILITY.md'] += '\n' + old_image
        files['docs/releases/server-1.6.497.md'] = '# Server v1.6.497\n' + old_image
        with self.assertRaisesRegex(SystemExit, 'QUICK_START_MISMATCH'):
            verify(files)

    def test_release_notes_link_and_heading_must_match_current_release(self):
        for name, old, new in (
                ('README.md', 'docs/releases/server-1.6.498.md', 'docs/releases/server-1.6.497.md'),
                ('docs/releases/server-1.6.498.md', '# Server v1.6.498', '# Server v1.6.497')):
            with self.subTest(name=name):
                files = dict(FILES)
                files[name] = files[name].replace(old, new)
                with self.assertRaisesRegex(SystemExit, 'QUICK_START_MISMATCH'):
                    verify(files)

    def test_docker_compose_identity_mismatch_rejected(self):
        files = dict(FILES)
        files['README.md'] = files['README.md'].replace('    image: ' + INSTALL_IMAGE, '    image: ' + INSTALL_IMAGE[:-1] + '0')
        with self.assertRaisesRegex(SystemExit, 'QUICK_START_MISMATCH'):
            verify(files)

    def test_each_install_example_rejects_invalid_or_missing_reference(self):
        invalid = (
            INSTALL_IMAGE.replace('v1.6.498', 'v1.6.497'),
            PUBLISHED_IMAGE,
            'ghcr.io/pasturestack/server:' + 'a' * 40,
            'ghcr.io/pasturestack/server:sha-' + 'a' * 40,
            INSTALL_IMAGE + '-unexpected',
            INSTALL_IMAGE + ')unexpected',
            INSTALL_IMAGE + ';unexpected',
            'ghcr.io/pasturestack/server:latest',
            'ghcr.io/pasturestack/server:${SERVER_VERSION}',
            'ghcr.io/pasturestack/server:<version>',
            'ghcr.io/pasturestack/server:v1.6.x',
            '',
        )
        for name, prefix, error in (
                ('README.md', '  ', 'QUICK_START_MISMATCH'),
                ('README.md', '    image: ', 'QUICK_START_MISMATCH'),
                (PERFORMANCE, '    image: ', 'PERFORMANCE_MISMATCH')):
            for replacement in invalid:
                with self.subTest(name=name, prefix=prefix, replacement=replacement):
                    files = dict(FILES)
                    files[name] = files[name].replace(prefix + INSTALL_IMAGE, prefix + replacement)
                    with self.assertRaisesRegex(SystemExit, error):
                        verify(files)

    def test_duplicate_performance_install_reference_rejected(self):
        files = dict(FILES)
        files[PERFORMANCE] += '\n' + FILES[PERFORMANCE]
        with self.assertRaisesRegex(SystemExit, 'PERFORMANCE_MISMATCH'):
            verify(files)

    def test_versioned_publication_identity_must_match_without_suffix(self):
        for name in ('COMPATIBILITY.md', 'docs/releases/server-1.6.498.md'):
            for replacement in (PUBLISHED_IMAGE[:-1] + '0', PUBLISHED_IMAGE + '-unexpected', ''):
                with self.subTest(name=name, replacement=replacement):
                    files = dict(FILES)
                    files[name] = files[name].replace(PUBLISHED_IMAGE, replacement)
                    with self.assertRaisesRegex(SystemExit, 'MISMATCH|IDENTITY_MISSING'):
                        verify(files)

    def test_next_published_numeric_release_without_gate_relabel(self):
        files = dict(FILES)
        next_image = 'ghcr.io/pasturestack/server:v1.6.500@sha256:' + 'a' * 64
        files['README.md'] = files['README.md'].replace('v1.6.498', 'v1.6.500').replace('server-1.6.498.md', 'server-1.6.500.md')
        files[PERFORMANCE] = files[PERFORMANCE].replace('v1.6.498', 'v1.6.500')
        files['COMPATIBILITY.md'] += '\n' + next_image
        files['docs/releases/server-1.6.500.md'] = '# Server v1.6.500\n\n' + next_image
        verify(files)


if __name__ == '__main__':
    unittest.main(verbosity=2)

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
CANDIDATE_IMAGE = 'ghcr.io/pasturestack/server:v1.6.537'
CANDIDATE_FILES = dict(FILES)
intro, quick = FILES['README.md'].split('## Quick start', 1)
CANDIDATE_FILES['README.md'] = (
    '<a id="current-release"></a>\n\n' +
    intro.replace('## Current release', '## Current source candidate') +
    'Server `v1.6.537` is a prepared source candidate, not a published image.\n'
    '[candidate note](docs/releases/server-1.6.537.md)\n\n## Quick start\n\n'
    'run them only after its official release\nThis candidate is not yet available\n' +
    quick.replace(INSTALL_IMAGE, CANDIDATE_IMAGE))
CANDIDATE_FILES[PERFORMANCE] = (
    'run it only after its official release and image have been published and read back.\n'
    'is not yet available from GHCR\n[candidate note](../releases/server-1.6.537.md)\n' +
    FILES[PERFORMANCE].replace(INSTALL_IMAGE, CANDIDATE_IMAGE))
CANDIDATE_FILES['COMPATIBILITY.md'] = (
    '## Server v1.6.537 prepared, not published\n\n' + FILES['COMPATIBILITY.md'])
CANDIDATE_FILES['docs/releases/server-1.6.537.md'] = (
    '# Server v1.6.537 candidate\n\n'
    'Prepared source only; no Server image or release has been published.\n')


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
        note_paths = {'docs/releases/server-' + tag[1:] + '.md' for tag in tags}
        note_paths.update(re.findall(r'\((docs/releases/server-[0-9.]+\.md)\)', readme))
        for name in note_paths:
            notes = REPO / name
            if notes.is_file():
                files[name] = notes.read_text(encoding='utf-8')
        verify(files)

    def test_explicit_537_candidate_keeps_publication_evidence_and_numeric_examples(self):
        verify(CANDIDATE_FILES)
        files = dict(CANDIDATE_FILES)
        files['COMPATIBILITY.md'] = files['COMPATIBILITY.md'].replace(PUBLISHED_IMAGE, '')
        with self.assertRaisesRegex(SystemExit, 'IDENTITY_MISSING'):
            verify(files)

    def test_numeric_candidate_advances_without_relabeling_the_gate(self):
        for version in ('1.6.538', '1.6.539'):
            files = {name.replace('1.6.537', version): value.replace('1.6.537', version)
                     for name, value in CANDIDATE_FILES.items()}
            verify(files)

    def test_candidate_cannot_hide_warning_mismatch_or_fabricate_publication(self):
        for name, old, new, error in (
                ('README.md', '<a id="current-release"></a>', '', 'DISCLOSURE_MISSING'),
                ('README.md', 'run them only after its official release', '', 'DISCLOSURE_MISSING'),
                (PERFORMANCE, 'is not yet available from GHCR', '', 'DISCLOSURE_MISSING'),
                (PERFORMANCE, CANDIDATE_IMAGE, INSTALL_IMAGE, 'PERFORMANCE_MISMATCH'),
                ('docs/releases/server-1.6.537.md', '# Server v1.6.537 candidate', '# Server v1.6.537', 'NOTES_MISMATCH'),
                ('README.md', 'Server `v1.6.537` is a prepared source candidate, not a published image.',
                 'Server `v1.6.537` is a prepared source candidate, not a published image.\n' +
                 CANDIDATE_IMAGE + '@sha256:' + 'a' * 64, 'PUBLICATION_MISMATCH'),
                ('COMPATIBILITY.md', '## Server v1.6.537 prepared, not published',
                 '## Server v1.6.537 published\n' + CANDIDATE_IMAGE + '@sha256:' + 'a' * 64,
                 'PUBLICATION_MISMATCH')):
            with self.subTest(name=name, old=old):
                files = dict(CANDIDATE_FILES)
                files[name] = files[name].replace(old, new)
                with self.assertRaisesRegex(SystemExit, error):
                    verify(files)

    def test_actual_537_publication_needs_correct_docs_not_a_gate_code_change(self):
        files = dict(FILES)
        files['README.md'] = files['README.md'].replace('v1.6.498', 'v1.6.537').replace('server-1.6.498.md', 'server-1.6.537.md')
        files[PERFORMANCE] = files[PERFORMANCE].replace('v1.6.498', 'v1.6.537')
        image = CANDIDATE_IMAGE + '@sha256:' + 'a' * 64
        files['COMPATIBILITY.md'] += '\n' + image
        files['docs/releases/server-1.6.537.md'] = '# Server v1.6.537\n\nOfficially published: ' + image
        verify(files)
        files['docs/releases/server-1.6.537.md'] = CANDIDATE_FILES['docs/releases/server-1.6.537.md']
        with self.assertRaisesRegex(SystemExit, 'QUICK_START_MISMATCH'):
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

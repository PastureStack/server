import importlib.util
from pathlib import Path
import re
import unittest

spec = importlib.util.spec_from_file_location('notes', Path(__file__).with_name('render-server-release-notes.py'))
notes = importlib.util.module_from_spec(spec)
spec.loader.exec_module(notes)


class PublicationNotes(unittest.TestCase):
    source = '# Server v1.6.546 candidate\n\nNot published.\n\n## Verified component inputs\n\n- Exact input.\n'

    def test_actual_current_release_note_has_the_required_evidence_boundary(self):
        root = Path(__file__).resolve().parents[1]
        recipe = (root / 'server/Dockerfile.web-compose-release').read_text(encoding='utf-8')
        tags = set(re.findall(r'^ARG SERVER_RELEASE_TAG=(v[0-9]+\.[0-9]+\.[0-9]+)$', recipe, re.M))
        self.assertEqual(1, len(tags))
        tag = tags.pop()
        body = (root / ('docs/releases/server-' + tag[1:] + '.md')).read_text(encoding='utf-8')
        self.assertEqual(1, body.count('## Verified component inputs\n'))
        if body.startswith('# Server ' + tag + ' candidate\n'):
            # In-memory format validation only; these fixture identities are
            # never written to release assets or presented as a real image.
            notes.render(body, tag, 'sha256:' + 'a' * 64, 'b' * 40)
        else:
            self.assertTrue(body.startswith('# Server ' + tag + '\n'))
            # A published heading is valid only after the installation docs
            # identify that release. An unpublished candidate must render.
            readme = (root / 'README.md').read_text(encoding='utf-8')
            self.assertIn('ghcr.io/pasturestack/server:' + tag + '\n', readme)

    def test_server574_recovery_canonicalizes_only_the_exact_original_heading(self):
        path = Path(__file__).with_name('complete-server574-publication.py')
        spec = importlib.util.spec_from_file_location('recovery574', path)
        recovery = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(recovery)
        root = Path(__file__).resolve().parents[1]
        original = (root / 'docs/releases/server-1.6.574.md').read_bytes()
        original = original.replace(b'# Server v1.6.574 candidate\n', b'# Server v1.6.574\n', 1)
        result = recovery.canonical_candidate(original)
        self.assertEqual(b'# Server v1.6.574 candidate\n', result.splitlines(keepends=True)[0])
        self.assertEqual(original.split(b'\n', 1)[1], result.split(b'\n', 1)[1])
        for changed in (original.replace(b'574', b'575', 1), original + b'\n', result):
            with self.assertRaises(ValueError):
                recovery.canonical_candidate(changed)

    def test_publication_identity_is_exact_and_deployment_is_not_claimed(self):
        result = notes.render(self.source, 'v1.6.546', 'sha256:' + 'a' * 64, 'b' * 40)
        self.assertIn('server:v1.6.546@sha256:' + 'a' * 64, result)
        self.assertIn('`' + 'b' * 40 + '`', result)
        self.assertIn('Deployment-specific acceptance is separate', result)
        self.assertTrue(result.endswith('## Verified component inputs\n\n- Exact input.\n'))
        self.assertNotIn('Not published.', result)
        self.assertNotIn('candidate', result)

    def test_wrong_or_missing_identity_rejected(self):
        for tag, digest, revision in (
            ('v1.6.545', 'sha256:' + 'a' * 64, 'b' * 40),
            ('v1.6.546', 'unknown', 'b' * 40),
            ('v1.6.546', 'sha256:' + 'a' * 64, 'main'),
        ):
            with self.assertRaises(ValueError):
                notes.render(self.source, tag, digest, revision)

    def test_missing_or_ambiguous_evidence_boundary_rejected(self):
        for source in (self.source.replace('## Verified component inputs', '## Inputs'),
                       self.source + '## Verified component inputs\n'):
            with self.assertRaises(ValueError):
                notes.render(source, 'v1.6.546', 'sha256:' + 'a' * 64, 'b' * 40)


if __name__ == '__main__':
    unittest.main()

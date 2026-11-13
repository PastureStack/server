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
        # Pin the failed producer's original note, independent of later
        # publication/deployment documentation edits to the current note.
        original = b'# Server v1.6.574\n\n## Candidate boundary\n\nThis source candidate is not a published Server image or deployment result.\nThe normal Server workflow must build, scan and qualify the image before use.\n\n## Verified component inputs\n\nPackages the original published Orchestration Engine v0.183.375 and Web Console\n1.6.215 with Bridge 0.2.17. Compose CLI v0.14.43 and Catalog Service v0.20.18\nremain unchanged from Server573.\n\nProject metadata processing preserves fresh owner and API Key authorization\nwhile its exact captured native update is in the updating-active transition.\nA failed native update records a terminal failure; persisted field values alone\ndo not establish successful completion. New changes still require an active\nProject, and inactive, removed and foreign targets retain their checks.\n\nService upgrade continuation uses the existing typed preview, human approval,\napply and operation observation flow. Native state, role and API Key scope\nremain authoritative; this does not expose arbitrary HTTP or raw payloads.\n\nOriginal component CI and signed release evidence are component source and\nartifact qualifications. They do not establish Project, LB, Process, Catalog,\nweak-model or whole frontend workflow acceptance on this Server cohort.\n\nExisting feature opt-ins, networking and storage defaults, official APT pins,\ntracking policy for 13 runtime Medium findings, severity gates and archive verification\nremain unchanged. Preserve Server573 as the immediate rollback and reuse the\noriginal mounts and operator configuration when upgrading.\n'
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

    def test_prospective_server_build_publication_pending_cannot_enter_published_body(self):
        # Exact source6ff failure: the retained payload contradicted the new
        # publication prefix. Whitespace wrapping does not change its meaning.
        actual = ('Server build, publication, deployment and affected native/UI workflows remain\n'
                  'pending.')
        heading = '## Verified component inputs\n'
        prefix = self.source.split(heading, 1)[0]
        for status in (actual, actual.replace('\n', ' '),
                       'Server build and publication are pending.'):
            source = self.source + '\n' + status + '\n'
            with self.subTest(status=status):
                with self.assertRaisesRegex(ValueError, 'Candidate boundary before ## Verified component inputs'):
                    notes.render(source, 'v1.6.546', 'sha256:' + 'a' * 64, 'b' * 40)
                self.assertTrue(source.endswith(status + '\n'))
        # A candidate-only statement belongs above the evidence boundary.
        moved = prefix + '## Candidate boundary\n\n' + actual + '\n\n' + heading + '\n- Exact input.\n'
        result = notes.render(moved, 'v1.6.546', 'sha256:' + 'a' * 64, 'b' * 40)
        self.assertNotIn(actual, result)
        self.assertTrue(result.endswith(heading + '\n- Exact input.\n'))

    def test_native_and_deployment_pending_remain_exact_publication_payload(self):
        body = ('Server deployment and affected native/UI workflows remain\n'
                'pending.\n\n'
                'Native acceptance remains pending; component publication does not prove it.\n\n'
                'Server build and publication are complete; deployment remains pending.\n')
        source = self.source + '\n' + body
        result = notes.render(source, 'v1.6.546', 'sha256:' + 'a' * 64, 'b' * 40)
        self.assertTrue(result.endswith(body))
        self.assertTrue(result.endswith('## Verified component inputs\n\n- Exact input.\n\n' + body))

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

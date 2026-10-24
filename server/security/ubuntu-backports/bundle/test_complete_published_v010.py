"""Completion metadata/CLI mutations only; no CI, build, scanner or registry calls."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('completion', HERE / 'complete-published-v0.1.0.py')
C = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(C)


def encoded(value):
    return (json.dumps(value, indent=2, sort_keys=True) + '\n').encode()


def api_fixture(lock):
    i, p = lock['identity'], lock['producer']
    run = {'id': i['runId'], 'head_sha': i['producerCommit'], 'head_branch': 'main', 'event': 'workflow_dispatch',
           'path': p['workflow'], 'run_attempt': 1, 'status': 'completed', 'conclusion': 'failure',
           'repository': {'full_name': C.Q.REPO}}
    jobs = {'total_count': 2, 'jobs': [{'name': name, 'id': p[name + 'JobId'], 'run_id': i['runId'],
            'head_sha': i['producerCommit'], 'status': 'completed', 'conclusion': conclusion,
            'steps': copy.deepcopy(p['steps']) if name == 'publish' else []}
            for name, conclusion in [('checks', 'success'), ('publish', 'failure')]]}
    artifact = {'id': i['artifactId'], 'name': lock['artifact']['name'], 'expired': False,
                'size_in_bytes': lock['artifact']['bytes'], 'digest': 'sha256:' + i['artifactZipSha256'],
                'workflow_run': {'id': i['runId'], 'head_sha': i['producerCommit']}}
    return run, jobs, artifact


def metadata_fixture():
    # Synthetic byte bodies exercise the metadata validator independently of
    # the production loader's immutable real-candidate pins.
    lock = copy.deepcopy(C.load_lock()); document = copy.deepcopy(lock['sbomDocument']); files = {}
    qualification = {'schemaVersion': 1, 'bundleVersion': '0.1.0', 'platform': C.Q.PLATFORM,
                     'status': 'qualified', 'installer': {}}
    manifest = {'schemaVersion': 1, 'bundleVersion': '0.1.0', 'platform': C.Q.PLATFORM,
                'families': [], 'packages': []}
    for component in document['components']:
        name = component['name']; body = ('unit-fixture-' + name).encode(); digest = C.Q.sha(body)
        component['hashes'] = [{'alg': 'SHA-256', 'content': digest}]
        if name == 'install-existing-backports':
            files[name] = body; qualification['installer']['sha256'] = digest; continue
        archive = 'debs/' + name + '.deb'; files[archive] = body
        manifest['packages'].append({'name': name, 'version': component['version'], 'archive': {'path': archive, 'sha256': digest}})
    files['qualification.json'] = encoded(qualification)
    manifest['qualification'] = {'path': 'qualification.json', 'sha256': C.Q.sha(files['qualification.json'])}
    files['manifest.json'] = encoded(manifest); files['sbom.cdx.json'] = encoded(document)
    lock['sbomDocument'] = document; lock['identity']['sbomSha256'] = C.Q.sha(files['sbom.cdx.json'])
    lock['outMetadataSha256'] = {n: C.Q.sha(files[n]) for n in ['manifest.json', 'qualification.json']}
    return lock, files


class CompletionBoundaries(unittest.TestCase):
    def test_single_published_candidate_has_no_generic_subject_or_version_input(self):
        lock = C.load_lock(); self.assertEqual(lock['identity'], C.IDENTITY)
        self.assertEqual(len(lock['sbomDocument']['components']), 13)
        self.assertNotIn('serialNumber', lock['sbomDocument'])
        for kind in ('digest', 'producerCommit', 'runId', 'artifactId', 'sbomSha256', 'unknown-metadata'):
            changed = copy.deepcopy(lock)
            if kind == 'unknown-metadata': changed['unknown'] = 'unreviewed'
            else: changed['identity'][kind] = 'wrong'
            with tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / C.LOCK.name; path.write_bytes(encoded(changed))
                with self.subTest(kind=kind), patch.object(C, 'LOCK', path), self.assertRaises(ValueError): C.load_lock()

    def test_original_failure_is_preserved_with_all_prior_required_steps_passed(self):
        lock = C.load_lock(); run, jobs, artifact = api_fixture(lock); original = copy.deepcopy((run, jobs, artifact))
        C.verify_api(lock, run, jobs, artifact)
        self.assertEqual((run, jobs, artifact), original)
        failed = [s['name'] for s in jobs['jobs'][1]['steps'] if s['conclusion'] == 'failure']
        self.assertEqual(failed, ['Attest payload SBOM'])

    def test_wrong_source_job_or_original_required_failure_is_rejected(self):
        for kind in ('source', 'run-green', 'checks', 'native', 'provider', 'push', 'provenance', 'extra-step', 'artifact'):
            lock = C.load_lock(); run, jobs, artifact = api_fixture(lock)
            if kind == 'source': run['head_sha'] = '0' * 40
            if kind == 'run-green': run['conclusion'] = 'success'
            if kind == 'checks': jobs['jobs'][0]['conclusion'] = 'failure'
            number = {'native': 6, 'provider': 11, 'push': 12, 'provenance': 13}.get(kind)
            if number:
                next(s for s in jobs['jobs'][1]['steps'] if s['number'] == number)['conclusion'] = 'failure'
            if kind == 'extra-step': jobs['jobs'][1]['steps'].append({'number': 99, 'name': 'unknown', 'status': 'completed', 'conclusion': 'success'})
            if kind == 'artifact': artifact['digest'] = 'sha256:' + '0' * 64
            with self.subTest(kind=kind), self.assertRaises(ValueError): C.verify_api(lock, run, jobs, artifact)

    def test_exact_thirteen_components_bind_every_archive_and_installer(self):
        lock, files = metadata_fixture(); original = copy.deepcopy(files)
        self.assertEqual(len(C.verify_metadata(lock, files)['components']), 13)
        self.assertEqual(files, original)

    def test_truncated_unknown_metadata_and_changed_package_bytes_are_rejected(self):
        for kind in ('truncated', 'unknown', 'component', 'archive', 'installer', 'manifest-metadata'):
            lock, files = metadata_fixture()
            if kind == 'truncated': files['sbom.cdx.json'] = files['sbom.cdx.json'][:20]
            if kind in ('unknown', 'component'):
                doc = json.loads(files['sbom.cdx.json'])
                if kind == 'unknown': doc['metadata']['unreviewed'] = True
                else: doc['components'].pop()
                files['sbom.cdx.json'] = encoded(doc)
                lock['identity']['sbomSha256'] = C.Q.sha(files['sbom.cdx.json'])
            if kind == 'archive': files[next(n for n in files if n.endswith('.deb'))] += b'tamper'
            if kind == 'installer': files['install-existing-backports'] += b'tamper'
            if kind == 'manifest-metadata':
                doc = json.loads(files['manifest.json']); doc['unknown'] = True; files['manifest.json'] = encoded(doc)
                lock['outMetadataSha256']['manifest.json'] = C.Q.sha(files['manifest.json'])
            with self.subTest(kind=kind), self.assertRaises(ValueError): C.verify_metadata(lock, files)

    def test_native_verified_predicate_must_be_original_ast_and_subject(self):
        document = C.load_lock()['sbomDocument']
        statement = {'predicateType': C.PREDICATE, 'predicate': document,
                     'subject': [{'name': C.IDENTITY['image'], 'digest': {'sha256': C.IDENTITY['digest'][7:]}}]}
        C.verify_attestation([{'verificationResult': {'statement': statement}}], C.PREDICATE, document)
        for kind in ('digest', 'predicate', 'type'):
            wrong = copy.deepcopy(statement)
            if kind == 'digest': wrong['subject'][0]['digest']['sha256'] = '0' * 64
            if kind == 'predicate': wrong['predicate']['metadata']['unreviewed'] = True
            if kind == 'type': wrong['predicateType'] = 'https://spdx.dev/Document'
            with self.subTest(kind=kind), self.assertRaises(ValueError):
                C.verify_attestation([{'verificationResult': {'statement': wrong}}], C.PREDICATE, document)
        provenance = copy.deepcopy(statement)
        provenance.update(predicateType='https://slsa.dev/provenance/v1',
                          predicate={'runDetails': {'metadata': {'invocationId': C.ORIGINAL_INVOCATION}}})
        C.verify_attestation([{'verificationResult': {'statement': provenance}}], 'https://slsa.dev/provenance/v1')
        for invocation in ('https://github.com/PastureStack/server/actions/runs/40138193718/attempts/1',
                           'https://github.com/PastureStack/server/actions/runs/40138193717/attempts/2'):
            provenance['predicate']['runDetails']['metadata']['invocationId'] = invocation
            with self.subTest(invocation=invocation), self.assertRaises(ValueError):
                C.verify_attestation([{'verificationResult': {'statement': provenance}}], 'https://slsa.dev/provenance/v1')

    def test_workflow_cannot_rebuild_or_repush_and_explicit_predicate_is_used(self):
        root = HERE.parents[3]
        source = (root / '.github/workflows/complete-ubuntu-security-backports-v0.1.0.yml').read_text()
        for forbidden in ('docker build', 'docker push', 'docker tag', 'buildx', 'inputs:', 'sbom-path:'):
            self.assertNotIn(forbidden, source)
        self.assertIn("github.ref == 'refs/heads/main'", source)
        self.assertIn('needs: checks', source)
        self.assertIn('--source-digest "$PRODUCER" --signer-digest "$PRODUCER"', source)
        self.assertIn('--source-digest "$GITHUB_SHA" --signer-digest "$GITHUB_SHA"', source)
        normal = (root / '.github/workflows/publish-ubuntu-security-backports.yml').read_text()
        for text in (source, normal):
            self.assertIn('predicate-type: https://cyclonedx.org/bom', text)
            self.assertIn('predicate-path:', text)
            self.assertNotIn('sbom-path:', text)


if __name__ == '__main__':
    unittest.main(verbosity=2)

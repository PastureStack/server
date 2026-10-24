#!/usr/bin/env python3
"""Complete one already-pushed candidate; never build, push or change payloads."""
import argparse
import importlib.metadata
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import urllib.request

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('original_qualifier', HERE / 'qualify-native-packages.py')
Q = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(Q)
LOCK = HERE / 'published-v0.1.0-candidate.lock.json'
IDENTITY = {
    'image': 'ghcr.io/pasturestack/ubuntu-security-backports',
    'digest': 'sha256:2742a3d429e4e14bc587f6dedc51ded4246cf90bbaedcd86c67d0885e32a6f2a',
    'producerCommit': '59f4ec1f31e510361c4635023c08fcf2a2b2133c',
    'runId': 40138193717, 'artifactId': 12577573510,
    'artifactZipSha256': '635c5cddec48776278061c47084062518cd6f1c173f862f9b9b49dbe29441f72',
    'sbomSha256': '6ae4fb736a8df63dc3db6dd74b753cf9008379f8414f05c7bd30ae7b2cafd470',
}
PREDICATE = 'https://cyclonedx.org/bom'
ORIGINAL_INVOCATION = 'https://github.com/PastureStack/server/actions/runs/40138193717/attempts/1'
require = Q.require


def load_lock():
    lock = json.loads(LOCK.read_bytes())
    require(set(lock) == {'schemaVersion', 'scope', 'repository', 'publicationState', 'identity', 'producer',
                         'artifact', 'outMetadataSha256', 'sbomDocument', 'officialSchemas'}
            and lock['schemaVersion'] == 1 and lock['scope'] == 'completion-only-existing-v0.1.0'
            and lock['repository'] == Q.REPO and lock['identity'] == IDENTITY,
            'This completion is restricted to the single reviewed published candidate')
    return lock


def verify_api(lock, run, jobs, artifact):
    identity, producer = lock['identity'], lock['producer']
    require(run['id'] == identity['runId'] and run['head_sha'] == identity['producerCommit']
            and run['head_branch'] == 'main' and run['event'] == 'workflow_dispatch'
            and run['path'] == producer['workflow'] and run['run_attempt'] == 1
            and run['status'] == 'completed' and run['conclusion'] == 'failure'
            and run['repository']['full_name'] == Q.REPO, 'Original run identity/status changed')
    by_name = {j['name']: j for j in jobs['jobs']}
    require(jobs['total_count'] == len(jobs['jobs']) == 2 and set(by_name) == {'checks', 'publish'},
            'Original checks/publish job set changed')
    for name, conclusion, job_id in [('checks', 'success', producer['checksJobId']),
                                      ('publish', 'failure', producer['publishJobId'])]:
        job = by_name[name]
        require(job['id'] == job_id and job['run_id'] == identity['runId']
                and job['head_sha'] == identity['producerCommit']
                and job['status'] == 'completed' and job['conclusion'] == conclusion,
                'Original job identity/outcome changed: ' + name)
    require([{k: s[k] for k in ('number', 'name', 'status', 'conclusion')}
             for s in by_name['publish']['steps']] == producer['steps'],
            'Original native/qualification/providers/push/provenance or sole SBOM failure changed')
    require(artifact['id'] == identity['artifactId'] and artifact['name'] == lock['artifact']['name']
            and artifact['size_in_bytes'] == lock['artifact']['bytes'] and artifact['expired'] is False
            and artifact['digest'] == 'sha256:' + identity['artifactZipSha256']
            and artifact['workflow_run']['id'] == identity['runId']
            and artifact['workflow_run']['head_sha'] == identity['producerCommit'],
            'Original artifact is not bound to the reviewed producer')


def verify_metadata(lock, files):
    for name, digest in lock['outMetadataSha256'].items():
        require(Q.sha(files[name]) == digest, 'Original metadata bytes changed: ' + name)
    sbom = json.loads(files['sbom.cdx.json'])
    require(Q.sha(files['sbom.cdx.json']) == lock['identity']['sbomSha256']
            and sbom == lock['sbomDocument'] and len(sbom['components']) == 13,
            'SBOM bytes/format/13-component identity differs from original')
    manifest, qualification = json.loads(files['manifest.json']), json.loads(files['qualification.json'])
    require(set(manifest) == {'schemaVersion', 'bundleVersion', 'platform', 'qualification', 'families', 'packages'}
            and manifest['schemaVersion'] == qualification['schemaVersion'] == 1
            and manifest['bundleVersion'] == qualification['bundleVersion'] == '0.1.0'
            and manifest['platform'] == qualification['platform'] == Q.PLATFORM
            and qualification['status'] == 'qualified' and len(manifest['packages']) == 12
            and manifest['qualification'] == {'path': 'qualification.json', 'sha256': Q.sha(files['qualification.json'])},
            'Original qualified package identity is incomplete')
    components = {c['purl']: c for c in sbom['components']}
    require(len(components) == 13 and len({p['name'] for p in manifest['packages']}) == 12,
            'Duplicate SBOM component/package')
    for package in manifest['packages']:
        path = str(Q.safe_name(package['archive']['path'])); c = components[Q.purl(package)]
        require(c['name'] == package['name'] and c['version'] == package['version'] and c['type'] == 'library'
                and c['bom-ref'] == c['purl']
                and c['hashes'] == [{'alg': 'SHA-256', 'content': package['archive']['sha256']}]
                and Q.sha(files[path]) == package['archive']['sha256'], 'SBOM component/deb archive mismatch')
    installer = components['pkg:generic/pasturestack/backport-installer@0.1.0']
    require(installer['name'] == 'install-existing-backports' and installer['type'] == 'application'
            and installer['hashes'] == [{'alg': 'SHA-256', 'content': Q.sha(files['install-existing-backports'])}]
            and qualification['installer']['sha256'] == Q.sha(files['install-existing-backports']),
            'SBOM installer hash/identity mismatch')
    return sbom


def out_files(directory):
    require(directory.is_dir() and not any(p.is_symlink() for p in directory.rglob('*')), 'Unsafe/missing out directory')
    return {p.relative_to(directory).as_posix(): p.read_bytes() for p in directory.rglob('*') if p.is_file()}


def prepare(lock):
    require(not Q.WORK.exists(), 'Completion work directory must be new')
    Q.WORK.mkdir(); publisher = Q.WORK / 'publisher'; publisher.mkdir()
    run = Q.gh_json('actions/runs/' + str(IDENTITY['runId']))
    jobs = Q.gh_json('actions/runs/' + str(IDENTITY['runId']) + '/jobs?per_page=100')
    artifact = Q.gh_json('actions/artifacts/' + str(IDENTITY['artifactId']))
    verify_api(lock, run, jobs, artifact)
    Q.write_json(publisher / 'original-api.json', {'run': run, 'jobs': jobs, 'artifact': artifact})
    archive = publisher / 'original.zip'
    archive.write_bytes(subprocess.check_output(['gh', 'api', 'repos/' + Q.REPO + '/actions/artifacts/'
                                                + str(IDENTITY['artifactId']) + '/zip']))
    entries = Q.read_zip(archive, IDENTITY['artifactZipSha256'])
    files = {n.removeprefix('context/out/'): b for n, b in entries.items() if n.startswith('context/out/')}
    verify_metadata(lock, files)
    require(Q.sha(entries['publisher/published-manifest.json']) == IDENTITY['digest'].removeprefix('sha256:')
            and json.loads(entries['publisher/image-metadata.json'])['containerimage.digest'] == IDENTITY['digest'],
            'Original push metadata is not the immutable subject')
    for name, data in files.items():
        path = Q.WORK / 'context/out' / str(Q.safe_name(name))
        path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(data)


def verify_schema(lock, document):
    from jsonschema import Draft7Validator
    from referencing import Registry, Resource
    require(importlib.metadata.version('jsonschema') == '4.25.1', 'Exact reviewed schema validator is required')
    schemas = []
    for pin in lock['officialSchemas']:
        with urllib.request.urlopen(pin['url'], timeout=30) as response:
            data = response.read(2 * 1024 * 1024 + 1)
        require(len(data) <= 2 * 1024 * 1024 and Q.sha(data) == pin['sha256'], 'Official schema bytes changed')
        schemas.append(json.loads(data))
    registry = Registry().with_resources((s['$id'], Resource.from_contents(s)) for s in schemas)
    Draft7Validator.check_schema(schemas[0]); validator = Draft7Validator(schemas[0], registry=registry)
    validator.validate(document)
    mutations = []
    for kind in ('format', 'type', 'name'):
        changed = json.loads(json.dumps(document))
        if kind == 'format': changed['bomFormat'] = 'NOT-CYCLONEDX'
        if kind == 'type': changed['metadata']['component']['type'] = 'invalid-component-type'
        if kind == 'name': changed['components'][0].pop('name')
        require(not validator.is_valid(changed), 'Official schema negative control was accepted: ' + kind)
        mutations.append(kind)
    Q.write_json(Q.WORK / 'publisher/schema-validation.json', {'status': 'PASS', 'validator': 'jsonschema 4.25.1',
        'sbomSha256': IDENTITY['sbomSha256'], 'officialSchemas': lock['officialSchemas'], 'rejectedControls': mutations})


def verify_attestation(results, predicate_type, predicate=None):
    require(isinstance(results, list) and results, 'Native gh verification did not return verified statements')
    for result in results:
        statement = result['verificationResult']['statement']
        require(statement['predicateType'] == predicate_type
                and statement['subject'] == [{'name': IDENTITY['image'],
                    'digest': {'sha256': IDENTITY['digest'].removeprefix('sha256:')}}]
                and (predicate is None or statement['predicate'] == predicate),
                'Native verified predicate/subject is not the exact original artifact')
        if predicate_type == 'https://slsa.dev/provenance/v1':
            require(statement['predicate']['runDetails']['metadata']['invocationId'] == ORIGINAL_INVOCATION,
                    'Original provenance belongs to a different producer run/attempt')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    for mode in ('prepare', 'check-sbom', 'check-provenance', 'finish', 'print-work-root'):
        modes.add_argument('--' + mode, action='store_true')
    args = parser.parse_args(); lock = load_lock()
    if args.print_work_root: print(Q.WORK); return
    if args.prepare: prepare(lock); return
    publisher = Q.WORK / 'publisher'
    if args.check_provenance:
        verify_attestation(json.loads((publisher / 'original-provenance-verified.json').read_bytes()),
                           'https://slsa.dev/provenance/v1'); return
    document = verify_metadata(lock, out_files(Q.WORK / 'readback/out'))
    if args.check_sbom: verify_schema(lock, document); return
    require(json.loads((publisher / 'schema-validation.json').read_bytes())['status'] == 'PASS', 'Schema gate missing')
    verify_attestation(json.loads((publisher / 'sbom-verified.json').read_bytes()), PREDICATE, document)
    Q.verify_readback()
    Q.write_json(publisher / 'completion-receipt.json', {'schemaVersion': 1, 'status': 'PASS_COMPLETION_ONLY',
        'identity': IDENTITY, 'originalRunConclusion': 'failure', 'completionSourceCommit': os.environ['GITHUB_SHA'],
        'sbomBytesUnchanged': True, 'anonymousFullOutReadback': 'PASS', 'rebuiltOrRepushedImage': False,
        'verificationSha256': {n: Q.file_sha(publisher / n) for n in
            ('original-api.json', 'original-provenance-verified.json', 'schema-validation.json', 'sbom-verified.json')}})


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print('PUBLISHED_V010_COMPLETION_FAILED: ' + str(error), file=sys.stderr)
        sys.exit(1)

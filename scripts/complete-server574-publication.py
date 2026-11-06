"""Complete one exact publication whose final note rendering failed.

This fixed recovery consumes the original official artifact and existing image.
It cannot build, retag, push an image, select another run, or replace a release.
"""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import zipfile

REPOSITORY = 'PastureStack/server'
TAG = 'v1.6.574'
SOURCE = '1cf5e90ff06c3e37e5babcf2ad6c5753fd55a910'
RUN = 42146869143
ARTIFACT = 13471290080
ARTIFACT_BYTES = 6661312
ARTIFACT_SHA = '2d91eda8b9d40c875b0b8254e9b5d1977564db9fdfbbd74ece78509410ea7883'
DIGEST = 'sha256:c0c7348ad2cfa372ca8fb65cc409b6bd97dc301fa576350e03535ec40cae6651'
NOTE_SHA = '2542ccb0362fa09f3930252c69745a76407186d857bee1f961989b9f51648d0a'
RENDERER_SHA = 'df54ad3163696bc491eb7739e33bcaea482a5de69159a0ed4ca7b89cce73195b'
NAMES = (
    'SHA256SUMS', 'build.log', 'brotli-runtime.txt', 'candidate.log',
    'candidate-smoke.txt', 'host-api-0.38.8.tar.gz', 'host-api-package-check.txt',
    'image-inspect.txt', 'java-security-runtime.txt', 'mfa-policy-api-smoke.txt',
    'registration-basic-api-smoke.txt', 'published.txt', 'push.log',
    'release-notes.md', 'reverse-proxy-after-restart.txt',
    'reverse-proxy-before-restart.txt', 'sbom-identity.txt', 'security-summary.txt',
    'server.openvex.json', 'server.vendor-pending.json', 'ubuntu-backports-evidence.tar',
    'server-security-scan-raw.json', 'server-security-scan.json',
    'server-nested-payloads.json', 'server-vulnerabilities-raw.tsv',
    'server-vulnerabilities-unresolved.tsv', 'server.cdx.json',
    'vendor-pending-summary.txt', 'web-console-runtime.cdx.json',
    'web-console-runtime.cdx.json.sha256', 'web-console-sbom-identity.txt',
    'web-console-runtime-scan-raw.json', 'web-console-runtime-scan-effective.json',
    'web-console-runtime-scan-coverage.json', 'web-console-runtime-vulnerabilities.tsv.gz',
)


def need(condition, reason):
    if not condition:
        raise ValueError(reason)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical_candidate(original):
    prefix = b'# Server v1.6.574\n'
    need(sha(original) == NOTE_SHA and original.startswith(prefix),
         'Exact original Server574 source note required')
    return b'# Server v1.6.574 candidate\n' + original[len(prefix):]


def command(*args):
    return subprocess.check_output(list(args), timeout=120)


def api(path):
    return json.loads(command('gh', 'api', 'repos/' + REPOSITORY + '/' + path))


def original_source(path):
    return command('gh', 'api', '--header', 'Accept: application/vnd.github.raw+json',
                   'repos/' + REPOSITORY + '/contents/' + path + '?ref=' + SOURCE)


def absent(path):
    result = subprocess.run(['gh', 'api', 'repos/' + REPOSITORY + '/' + path],
                            capture_output=True, timeout=60)
    if result.returncode == 0:
        raise ValueError('Preserve existing Server574 release or tag')
    try:
        body = json.loads(result.stdout)
    except (ValueError, TypeError):
        raise ValueError('Exact GitHub absence response required') from None
    need(str(body.get('status')) == '404', 'Exact GitHub 404 required')


def main():
    need(os.environ.get('GITHUB_REPOSITORY') == REPOSITORY
         and os.environ.get('GITHUB_REF') == 'refs/heads/main', 'Official main workflow only')
    root = Path(__file__).resolve().parents[1]
    work = Path(os.environ['RUNNER_TEMP']) / 'server574-publication-completion'
    work.mkdir(exist_ok=False)
    run = api('actions/runs/' + str(RUN))
    need((run['id'], run['head_sha'], run['run_attempt'], run['event'], run['path'], run['conclusion']) ==
         (RUN, SOURCE, 1, 'workflow_dispatch', '.github/workflows/publish-current-server.yml', 'failure'),
         'Exact original official failed publication required')
    jobs = api('actions/runs/' + str(RUN) + '/jobs')['jobs']
    need(len(jobs) == 1 and jobs[0]['name'] == 'publish', 'One original publisher job required')
    steps = jobs[0]['steps']
    failed = [s for s in steps if s['conclusion'] == 'failure']
    need(len(failed) == 1 and failed[0]['name'] == 'Create immutable GitHub Release'
         and all(s['conclusion'] == 'success' for s in steps if s['number'] < failed[0]['number']),
         'All original build security startup restart push and attest steps must pass')
    for required in ('Run source gates', 'Scan the final merged runtime and create SBOM',
                     'Publish semantic image', 'Attest image provenance', 'Attest image SBOM'):
        need(sum(s['name'] == required and s['conclusion'] == 'success' for s in steps) == 1,
             'Original required publisher step missing')
    artifact = api('actions/artifacts/' + str(ARTIFACT))
    need((artifact['id'], artifact['name'], artifact['size_in_bytes'], artifact['digest'],
          artifact['workflow_run']['id'], artifact['workflow_run']['head_sha'], artifact['expired']) ==
         (ARTIFACT, 'server-v1.6.574-publication-42146869143', ARTIFACT_BYTES,
          'sha256:' + ARTIFACT_SHA, RUN, SOURCE, False), 'Exact original artifact identity required')
    absent('releases/tags/' + TAG)
    absent('git/ref/tags/' + TAG)
    for predicate, name in ((None, 'oci-provenance.json'), ('https://cyclonedx.org/bom', 'oci-sbom.json')):
        args = ['gh', 'attestation', 'verify', 'oci://ghcr.io/pasturestack/server@' + DIGEST,
                '--repo', REPOSITORY, '--format', 'json']
        if predicate:
            args += ['--predicate-type', predicate]
        proof = command(*args)
        need(json.loads(proof), 'Existing original image native attestation required')
        (work / name).write_bytes(proof)
    raw = command('gh', 'api', 'repos/' + REPOSITORY + '/actions/artifacts/' + str(ARTIFACT) + '/zip')
    need(len(raw) == ARTIFACT_BYTES and sha(raw) == ARTIFACT_SHA, 'Original ZIP bytes must match')
    archive = work / 'original-publication.zip'
    archive.write_bytes(raw)
    evidence = work / 'original-evidence'
    evidence.mkdir()
    with zipfile.ZipFile(archive) as bundle:
        entries = bundle.infolist()
        need(len(entries) <= 150 and len({r.filename for r in entries}) == len(entries)
             and sum(r.file_size for r in entries) <= 64 * 1024**2, 'Bounded original evidence required')
        # Extract only these compile-time fixed flat filenames. Archive paths,
        # links and additional reports can never choose a filesystem target.
        source_names = set(NAMES[1:-1]) | {'web-console-runtime-vulnerabilities.tsv'}
        for name in sorted(source_names):
            need(name in bundle.namelist(), 'Required original evidence file missing')
            (evidence / name).write_bytes(bundle.read(name))
    original = original_source('docs/releases/server-1.6.574.md')
    canonical = canonical_candidate(original)
    need((root / 'docs/releases/server-1.6.574.md').read_bytes() == canonical,
         'Reviewed current note must equal only the fixed original heading')
    renderer = root / 'scripts/render-server-release-notes.py'
    need(sha(renderer.read_bytes()) == RENDERER_SHA, 'Original renderer bytes required')
    spec = importlib.util.spec_from_file_location('original_notes', renderer)
    notes = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(notes)
    note = evidence / 'release-notes.md'
    need(note.read_bytes() == b'', 'Original failed render must have produced no note body')
    note.write_text(notes.render(canonical.decode('utf-8'), TAG, DIGEST, SOURCE), encoding='utf-8')
    need(DIGEST in (evidence / 'published.txt').read_text(encoding='utf-8'), 'Original published image digest required')
    recipe = original_source('server/Dockerfile.web-compose-release').decode('utf-8')
    host_sha = set(re.findall(r'^ARG HOST_API_ARCHIVE_SHA256=([0-9a-f]{64})$', recipe, re.M))
    need(len(host_sha) == 1 and sha((evidence / 'host-api-0.38.8.tar.gz').read_bytes()) in host_sha,
         'Original immutable host producer bytes required')
    with (evidence / NAMES[-1]).open('xb') as output:
        subprocess.run(['gzip', '-n', '-c', str(evidence / 'web-console-runtime-vulnerabilities.tsv')],
                       stdout=output, check=True, timeout=30)
    need(all((evidence / n).is_file() and (evidence / n).stat().st_size > 0 for n in NAMES[1:]),
         'All exact original publication assets required')
    sums = ''.join(sha((evidence / n).read_bytes()) + '  ' + n + '\n' for n in NAMES[1:])
    (evidence / 'SHA256SUMS').write_text(sums, encoding='utf-8')
    expected = {n: ('sha256:' + sha((evidence / n).read_bytes()), (evidence / n).stat().st_size) for n in NAMES}
    # Recheck absence immediately before the only publication mutation.
    absent('releases/tags/' + TAG)
    absent('git/ref/tags/' + TAG)
    subprocess.run(['gh', 'release', 'create', TAG, '--repo', REPOSITORY, '--target', SOURCE,
                    '--title', 'PastureStack Server ' + TAG, '--notes-file', str(note),
                    *[str(evidence / n) for n in NAMES]], check=True, timeout=180)
    release = api('releases/tags/' + TAG)
    actual = {a['name']: (a['digest'], a['size']) for a in release['assets']}
    need(not release['draft'] and not release['prerelease'] and len(release['assets']) == 35
         and actual == expected, 'Exact 35 original asset names sizes and digests required')
    ref = api('git/ref/tags/' + TAG)['object']
    need(ref['type'] == 'commit' and ref['sha'] == SOURCE, 'Original publisher source tag required')
    report = {'status': 'PASS_EXACT_SERVER574_PUBLICATION_COMPLETION', 'originalRun': RUN,
              'originalConclusion': 'failure', 'originalFailure': 'release-note heading only',
              'originalArtifactId': ARTIFACT, 'originalArtifactSha256': ARTIFACT_SHA,
              'originalSource': SOURCE, 'imageDigest': DIGEST, 'releaseId': release['id'],
              'recoveryRun': os.environ['GITHUB_RUN_ID'], 'recoverySource': os.environ['GITHUB_SHA'],
              'docOnlyTransformation': {'sourceSha256': NOTE_SHA, 'canonicalSha256': sha(canonical),
                                        'onlyFirstHeadingChanged': True, 'remainingBytesEqual': True},
              'assetCount': 35, 'assets': actual, 'imageBuilds': 0, 'imagePushes': 0,
              'runtimeQaRequests': 0, 'newDeploymentAcceptance': 'PENDING'}
    (work / 'publication-completion.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print('PASS: exact Server574 publication completed; original build failure preserved')


if __name__ == '__main__':
    main()

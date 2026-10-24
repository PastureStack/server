#!/usr/bin/env python3
"""Qualify exact native package inputs for a build-only OCI bundle; never install.

CLI inputs are the checked-in lock, current checkout and a fixed disposable
staging directory. A pending native artifact blocks qualification/publication.
"""
import argparse
import base64
from collections import Counter
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import struct
import subprocess
import sys
import tarfile
import tempfile
from urllib.parse import quote
import urllib.error
import urllib.request
import zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
LOCK_FILE = HERE / 'source-inputs.lock.json'
RUST_AUDIT_FILE = HERE / 'rust-coreutils-original18-source-closure.json'
RUST_AUDIT_RECEIPT_SHA = '73189028622c0a0fc074067b4c5b8521094921531f95cf3e68073baaebd2fbbd'
WORK = Path(tempfile.gettempdir()) / 'pasturestack-ubuntu-security-backports-v0.1.0'
REPO = 'PastureStack/server'
PLATFORM = {'distribution': 'ubuntu', 'release': '26.04', 'architecture': 'amd64'}
FAMILIES = {
    'pcre2': ['libpcre2-8-0', 'libpcre2-posix3'],
    'glibc': ['libc6', 'libc-bin', 'libc-gconv-modules-extra'],
    'rust-coreutils': ['rust-coreutils'], 'jq': ['jq', 'libjq1'],
    'p11-kit': ['libp11-kit0', 'p11-kit', 'p11-kit-modules'], 'libxrender': ['libxrender1'],
}
BASE = 'server/security/ubuntu-backports/'
PCRE2_STAGE_STEPS = [
    {'number': 8, 'name': 'Build only the released PCRE2 producer and static installer', 'conclusion': 'success'},
    {'number': 9, 'name': 'Qualify package bytes, native receipts, payload metadata, SBOM and exact-package VEX', 'conclusion': 'success'},
    {'number': 10, 'name': 'Require real installation in both isolated Ubuntu provider fixtures', 'conclusion': 'failure'},
    {'number': 11, 'name': 'Publish the new build-only OCI data artifact', 'conclusion': 'skipped'},
]
PCRE2_STAGE_RECEIPTS = {name: 'context/out/' + name for name in
                       ['manifest.json', 'qualification.json', 'source-inputs.lock.json']}


def require(ok, message):
    if not ok:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def file_sha(path):
    return sha(path.read_bytes())


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n', encoding='utf-8')


def safe_name(name):
    require(isinstance(name, str) and name and '\\' not in name and not any(ord(c) < 32 for c in name),
            'Unsafe artifact path')
    path = PurePosixPath(name)
    require(path.parts and not path.is_absolute() and '..' not in path.parts and ':' not in name
            and str(path) == name.rstrip('/'),
            'Artifact path escapes its root')
    return path


def read_zip(path, digest):
    require(file_sha(path) == digest, 'Native ZIP differs from the reviewed artifact pin')
    result, names, total = {}, set(), 0
    with zipfile.ZipFile(path) as archive:
        require(len(archive.infolist()) <= 10000, 'Too many native artifact entries')
        for info in archive.infolist():
            safe_name(info.orig_filename)
            safe_name(info.filename)
            key = info.filename.rstrip('/').casefold()
            require(key not in names and not info.flag_bits & 1, 'Duplicate/encrypted ZIP entry')
            names.add(key)
            mode = info.external_attr >> 16
            require(not stat.S_ISLNK(mode) and stat.S_IFMT(mode) in (0, stat.S_IFREG, stat.S_IFDIR),
                    'ZIP special files are forbidden')
            total += info.file_size
            require(info.file_size <= 256 * 1024 * 1024 and total <= 1024 * 1024 * 1024,
                    'Native ZIP exceeds bounded evidence size')
            require('unqualified' not in info.filename.lower(), 'Unqualified diagnostics cannot be inputs')
            if not info.is_dir():
                result[info.filename] = archive.read(info)
    return result


def load_lock(ready=False):
    lock = json.loads(LOCK_FILE.read_text(encoding='utf-8'))
    require(lock['schemaVersion'] == 1 and lock['repository'] == REPO
            and lock['bundleVersion'] == '0.1.0' and lock['platform'] == PLATFORM,
            'Unexpected bundle identity')
    require(set(lock['nativeInputs']) == set(FAMILIES) - {'pcre2'}, 'Wrong native family set')
    for family, item in lock['nativeInputs'].items():
        require(item['runtimePackages'] == FAMILIES[family], 'Unexpected native runtime package set')
        require(re.fullmatch('[0-9a-f]{40}', item['sourceCommit']) and type(item['runId']) is int,
                'Native run/source must be immutable')
        if item['status'] == 'pending':
            require(family == 'glibc' and item['artifactId'] is None and item['zipSha256'] is None,
                    'Pending input must not invent an artifact')
            require(not ready, 'glibc native artifact is pending; publication is blocked')
            continue
        require(item['status'] == 'qualified' and type(item['artifactId']) is int
                and type(item['jobId']) is int and re.fullmatch('[0-9a-f]{64}', item['zipSha256']),
                'Native artifact is not pinned/qualified')
        require(len(item['packages']) == len(FAMILIES[family])
                and {p['name'] for p in item['packages']} == set(FAMILIES[family]), 'Wrong pinned deb set')
        for package in item['packages']:
            require(re.fullmatch('[0-9a-f]{64}', package['sha256']) and
                    safe_name(package['file']).name == package['file'] and package['source'] == family
                    and package['version'] == item['packages'][0]['version'], 'Unpinned/unsafe deb')
    require(lock['pcre2']['kind'] == 'qualified-production-stage'
            and lock['pcre2']['runtimePackages'] == FAMILIES['pcre2']
            and lock['pcre2']['target'] == 'runtime_security_packages'
            and lock['pcre2']['sourceTag'] == 'v1.6.551'
            and re.fullmatch('[0-9a-f]{40}', lock['pcre2']['sourceCommit'])
            and re.fullmatch('[0-9a-f]{64}', lock['pcre2']['lockSha256'])
            and re.fullmatch('[0-9a-f]{64}', lock['pcre2']['copyrightSha256']), 'Wrong PCRE2 build contract')
    stage = lock['pcre2']['stageInput']
    require(stage['status'] == 'pcre2-qualified-before-consumer-failure'
            and re.fullmatch('[0-9a-f]{40}', stage['publisherCommit'])
            and all(type(stage[key]) is int for key in ['runId', 'jobId', 'artifactId'])
            and re.fullmatch('[0-9a-f]{64}', stage['zipSha256'])
            and stage['runConclusion'] == stage['jobConclusion'] == 'failure'
            and stage['stepOutcomes'] == PCRE2_STAGE_STEPS
            and set(stage['metadataSha256']) == set(PCRE2_STAGE_RECEIPTS)
            and set(stage['sourceFiles']) == {'.github/workflows/publish-ubuntu-security-backports.yml',
                    BASE + 'bundle/qualify-native-packages.py', BASE + 'bundle/source-inputs.lock.json'}
            and stage['metadataSha256']['source-inputs.lock.json'] == stage['sourceFiles'][BASE + 'bundle/source-inputs.lock.json']
            and [p['name'] for p in stage['packages']] == FAMILIES['pcre2'], 'PCRE2 stage evidence is not precisely pinned')
    require(all(re.fullmatch('[0-9a-f]{64}', digest) for digest in
                [*stage['metadataSha256'].values(), *stage['sourceFiles'].values(), *stage['evidence'].values(), stage['buildLogSha256']]),
            'PCRE2 stage source/evidence SHA pin is malformed')
    for p in stage['packages']:
        require(p['source'] == 'pcre2' and p['version'] == lock['pcre2']['version']
                and safe_name(p['file']).name == p['file'] and re.fullmatch('[0-9a-f]{64}', p['sha256']),
                'Unexpected pinned PCRE2 package')
    load_rust_source_audit(lock['nativeInputs']['rust-coreutils'])
    return lock


def load_rust_source_audit(item, provenance=None):
    ref = item.get('sourceAudit', {})
    require(ref.get('path') == RUST_AUDIT_FILE.name
            and ref.get('originalReceiptSha256') == RUST_AUDIT_RECEIPT_SHA
            and file_sha(RUST_AUDIT_FILE) == ref.get('sha256'), 'Rust original18 source audit is missing or changed')
    public = json.loads(RUST_AUDIT_FILE.read_text(encoding='utf-8')); audit = public['audit']
    require(public['schemaVersion'] == 1 and public['originalReceiptSha256'] == RUST_AUDIT_RECEIPT_SHA
            and public['projection']['excludedFields'] == ['identity.originalZip']
            and 'originalZip' not in audit['identity'] and audit['schemaVersion'] == 1
            and audit['status'] == 'PASS_ORIGINAL18_SOURCE_CLOSURE', 'Unapproved Rust audit projection/status')
    native = json.loads((HERE.parent / 'rust-coreutils' / 'rust-coreutils.lock.json').read_text(encoding='utf-8'))
    identity, package = audit['identity'], item['packages'][0]
    for field, expected in {'ciRun': item['runId'], 'ciJob': item['jobId'], 'artifactId': item['artifactId'],
            'producerCommit': item['sourceCommit'], 'originalZipSha256': item['zipSha256'],
            'lockSha256': item['lockSha256'], 'provenanceSha256': item['evidence']['provenance.json'],
            'packageSha256': package['sha256'], 'upstreamCommit': native['upstream']['baseCommit'],
            'ubuntuSourceVersion': native['ubuntuSourceVersion'], 'sourcePublication': native['sourcePublication']}.items():
        require(identity[field] == expected, 'Rust source audit native identity mismatch: ' + field)
    require(audit['scope']['componentPackage'] == package['file']
            and audit['scope']['customVersion'] == package['version']
            and [{k: f[k] for k in ('name', 'url', 'sha256', 'size')} for f in identity['sourceFiles']] == native['sourceFiles']
            and all(f['verified'] is True for f in identity['sourceFiles'])
            and identity['officialUpstreamArchive']['freshlyReadEqualsUbuntuOrig'] is True
            and identity['officialUpstreamArchive']['sha256'] == native['upstream']['archiveSha256'],
            'Rust source audit original Ubuntu/upstream inputs disagree')
    original = {r['id']: r for r in native['alreadyPresentFixes']}
    rows = {r['id']: r for r in audit['results']}
    new = {c for p in native['patches'] for c in p['fixedCves']}
    require(len(audit['results']) == len(original) == 18 and set(rows) == set(original)
            and len(item['fixedVulnerabilities']) == len(set(item['fixedVulnerabilities']))
            and set(item['fixedVulnerabilities']) == set(original) | new, 'Rust fixed set lacks exact original18 audit coverage')
    commits = {c['commit']: c for c in audit['officialCommitPatchEvidence']}
    for identifier, row in rows.items():
        require(row['status'] == 'fixed' and row['sourceFixPresent'] is True and row['effectiveRevertFound'] is False
                and row['verdictScope'] == 'qualified-component-source-closure-only'
                and row['lockMergeOrCompletionAnchor'] == original[identifier]['commit']
                and row['additionalLockCommits'] == original[identifier].get('additionalCommits', [])
                and row['sourceEvidence'] and row['officialCodeCommits']
                and all(c in commits and re.fullmatch('[0-9a-f]{64}', commits[c]['officialPatchSha256'])
                        for c in row['officialCodeCommits'])
                and row['existingNativeLog']['reused'] is True
                and row['existingNativeLog']['completeCveSpecificDynamicCoverageClaimed'] is False,
                'Rust CVE lacks source/control/official-commit evidence: ' + identifier)
        for evidence in row['sourceEvidence']:
            safe_name(evidence['path'])
            require(re.fullmatch('[0-9a-f]{64}', evidence['sha256'])
                    and type(evidence['lineStart']) is int and 0 < evidence['lineStart'] <= evidence['lineEnd']
                    and (evidence['path'] not in native['baselineSha256']
                         or evidence['sha256'] == native['baselineSha256'][evidence['path']]), 'Rust source evidence pin/line mismatch')
    validation = audit['validation']; boundary = audit['sourceBuildBoundary']['customPatch']
    require(validation['status'] == 'PASS' and validation['originalCves'] == validation['nativeSourcePinsMatched'] == 18
            and all(validation[k] is True for k in ['rawPackageShaMatched', 'producerLockBytesMatch',
                    'ubuntuOrigEqualsFreshOfficialArchive', 'originalUbuntuQuiltSourceControlsReviewed'])
            and validation['newBuildTestScanExecuted'] is False
            and audit['ubuntuQuilt']['matchedNativeBaselineFilePins'] == 18
            and audit['ubuntuQuilt']['originalRulesAndPackagingPreserved'] is True
            and boundary['sha256'] == native['patches'][0]['sha256']
            and boundary['onlyTargetPaths'] == ['src/uu/id/src/id.rs', 'tests/by-util/test_id.rs']
            and boundary['original18SourceUntouched'] is True, 'Rust bounded source/quilt validation is incomplete')
    if provenance is not None:
        reused, actual = audit['nativeEvidenceReused']['strictOwningSuite'], provenance['strictOwningSuite']
        require(reused['observedTotals'] == actual['observedTotals']
                and reused['strictLogSha256'] == actual['sha256']
                and reused['lognameCoverage'] == actual['lognameCoverage']
                and reused['originalUbuntuRulesSha256'] == actual['owningTestContract']['rulesSha256']
                and audit['ubuntuQuilt']['seriesSha256'] == provenance['packagingPreserved']['debian/patches/series']
                and all(p['sha256'] == provenance['packagingPreserved']['debian/patches/' + p['patch']]
                        for p in audit['ubuntuQuilt']['enabledPatches']), 'Rust audit/native limits or quilt receipt mismatch')
    return public


def check_source_files(root, expected):
    for name, digest in expected.items():
        safe_name(name)
        require(re.fullmatch('[0-9a-f]{64}', digest), 'Invalid source SHA-256')
        if file_sha(root / name) != digest:
            # Windows checkouts may apply core.autocrlf. Accept only the exact
            # repository clean-filter result, not arbitrary text normalization.
            canonical = subprocess.check_output(['git', 'show', 'HEAD:' + name], cwd=root)
            actual = subprocess.check_output(['git', 'hash-object', '--path=' + name, name], cwd=root).strip()
            committed = subprocess.check_output(['git', 'rev-parse', 'HEAD:' + name], cwd=root).strip()
            require(sha(canonical) == digest and actual == committed,
                    'Current module/CI source closure changed: ' + name)


def check_current_source(lock):
    # Squash merging and deleting a candidate branch must not make its exact
    # reviewed producer commit disappear from a fresh main checkout.
    ensure_native_sources(lock)
    for item in lock['nativeInputs'].values():
        check_source_files(ROOT, item['sourceFiles'])
        for name, digest in item['sourceFiles'].items():
            original = command(['git', 'show', item['sourceCommit'] + ':' + name])
            require(sha(original) == digest, 'Module source differs from the qualified native commit: ' + name)
        for name, proof in item['ciClosure'].items():
            check_source_files(ROOT, {name: proof['currentSha256']})
            original = subprocess.check_output(['git', 'show', item['sourceCommit'] + ':' + name], cwd=ROOT)
            require(sha(original) == proof['nativeSha256'], 'Native CI source pin changed')
    stage = lock['pcre2']['stageInput']
    for name, digest in stage['sourceFiles'].items():
        safe_name(name)
        require(sha(command(['git', 'show', stage['publisherCommit'] + ':' + name])) == digest,
                'Original PCRE2 build/qualification recipe changed: ' + name)


def ensure_native_sources(lock):
    commits = {item['sourceCommit'] for item in lock['nativeInputs'].values()}
    commits.add(lock['pcre2']['stageInput']['publisherCommit'])
    for commit in sorted(commits):
        require(re.fullmatch('[0-9a-f]{40}', commit), 'Native producer must be an exact commit SHA')
        probe = ['git', 'cat-file', '-e', commit + '^{commit}']
        if subprocess.run(probe, cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
            subprocess.run(['git', 'fetch', '--no-tags', 'origin', commit], cwd=ROOT, check=True)
            subprocess.run(probe, cwd=ROOT, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def check_pcre2_source(lock):
    source = ROOT.parent / 'pcre2-source'
    require(command(['git', '-C', str(source), 'rev-parse', 'HEAD']).decode().strip() == lock['pcre2']['sourceCommit'],
            'Wrong production PCRE2 checkout')
    check_source_files(source, lock['pcre2']['sourceFiles'])


def gh_json(endpoint):
    return json.loads(subprocess.check_output(['gh', 'api', 'repos/' + REPO + '/' + endpoint]))


def verify_api(family, item, run, job, artifact):
    require(run['id'] == item['runId'] and run['status'] == 'completed'
            and run['head_sha'] == item['sourceCommit']
            and run['conclusion'] == item['runConclusion']
            and run['path'] == '.github/workflows/ubuntu-backport-native.yml', 'Native run API mismatch')
    # jq's selected job passed in a matrix run whose other jobs failed. Preserve
    # that run conclusion; never promote the whole run to success.
    require(job['id'] == item['jobId'] and job['name'] == 'Native (' + family + ')'
            and job['status'] == 'completed' and job['conclusion'] == 'success'
            and job['head_sha'] == item['sourceCommit'] and job['run_id'] == item['runId'],
            'Selected native job did not succeed')
    require(artifact['id'] == item['artifactId'] and not artifact['expired']
            and artifact['digest'] == 'sha256:' + item['zipSha256']
            and artifact['name'] == item['artifactName']
            and artifact['workflow_run']['id'] == item['runId']
            and artifact['workflow_run']['head_sha'] == item['sourceCommit'], 'Artifact API ownership mismatch')


def verify_pcre2_api(stage, run, job, artifact):
    require(run['id'] == stage['runId'] and run['status'] == 'completed' and run['conclusion'] == 'failure'
            and run['head_sha'] == stage['publisherCommit'] and run['event'] == 'workflow_dispatch'
            and run['path'] == '.github/workflows/publish-ubuntu-security-backports.yml', 'PCRE2 publisher run mismatch')
    require(job['id'] == stage['jobId'] and job['run_id'] == stage['runId'] and job['name'] == 'publish'
            and job['status'] == 'completed' and job['conclusion'] == 'failure'
            and job['head_sha'] == stage['publisherCommit'], 'Original publisher job failure must be retained')
    for expected in PCRE2_STAGE_STEPS:
        matches = [s for s in job['steps'] if s['name'] == expected['name']]
        require(len(matches) == 1 and matches[0]['number'] == expected['number']
                and matches[0]['status'] == 'completed' and matches[0]['conclusion'] == expected['conclusion'],
                'PCRE2/qualification/consumer/publication step outcome mismatch: ' + expected['name'])
    require(artifact['id'] == stage['artifactId'] and not artifact['expired']
            and artifact['name'] == stage['artifactName'] and artifact['digest'] == 'sha256:' + stage['zipSha256']
            and artifact['workflow_run']['id'] == stage['runId']
            and artifact['workflow_run']['head_sha'] == stage['publisherCommit'], 'PCRE2 stage artifact ownership mismatch')


def fetch_native(lock):
    require(not WORK.exists(), 'Bundle staging directory must be new')
    (WORK / 'inputs').mkdir(parents=True)
    inputs = list(lock['nativeInputs'].items()) + [('pcre2', lock['pcre2']['stageInput'])]
    for family, item in inputs:
        run = gh_json('actions/runs/' + str(item['runId']))
        job = gh_json('actions/jobs/' + str(item['jobId']))
        artifact = gh_json('actions/artifacts/' + str(item['artifactId']))
        if family == 'pcre2': verify_pcre2_api(item, run, job, artifact)
        else: verify_api(family, item, run, job, artifact)
        write_json(WORK / 'inputs' / (family + '-api.json'), {'run': run, 'job': job, 'artifact': artifact})
        with (WORK / 'inputs' / (family + '.zip')).open('xb') as stream:
            subprocess.run(['gh', 'api', 'repos/' + REPO + '/actions/artifacts/' +
                            str(item['artifactId']) + '/zip'], stdout=stream, check=True)
        require(file_sha(WORK / 'inputs' / (family + '.zip')) == item['zipSha256'], 'Downloaded ZIP pin mismatch')


def registry_manifest(mode):
    headers = {}
    if mode != 'anonymous':
        credentials = (os.environ['GITHUB_ACTOR'] + ':' + os.environ['REGISTRY_TOKEN']).encode()
        headers['Authorization'] = 'Basic ' + base64.b64encode(credentials).decode()
    scope = 'pull' if mode == 'anonymous' else 'pull,push'
    request = urllib.request.Request('https://ghcr.io/token?service=ghcr.io&scope=repository:pasturestack/ubuntu-security-backports:' + scope,
                                     headers=headers)
    with urllib.request.urlopen(request, timeout=30) as response:
        token = json.load(response)['token']
    headers = {'Authorization': 'Bearer ' + token,
               'Accept': 'application/vnd.oci.image.index.v1+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json'}
    request = urllib.request.Request('https://ghcr.io/v2/pasturestack/ubuntu-security-backports/manifests/v0.1.0', headers=headers)
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            data = response.read(4 * 1024 * 1024 + 1)
            require(len(data) <= 4 * 1024 * 1024, 'Registry manifest exceeds size bound')
    except urllib.error.HTTPError as error:
        body = json.load(error); codes = {entry['code'] for entry in body.get('errors', [])}
        require(mode == 'absent' and error.code == 404 and codes
                and codes <= {'MANIFEST_UNKNOWN', 'NAME_UNKNOWN'}, 'Registry response does not prove tag absence/public visibility')
        print('NEW_NUMERIC_TAG_CONFIRMED'); return
    require(mode != 'absent', 'Refusing to overwrite existing v0.1.0')
    digest = json.loads((WORK / 'publisher' / 'image-metadata.json').read_text())['containerimage.digest']
    require(re.fullmatch('sha256:[0-9a-f]{64}', digest) and 'sha256:' + sha(data) == digest,
            'Registry manifest differs from the exact pushed digest')
    (WORK / 'publisher' / (mode + '-manifest.json')).write_bytes(data)


def module_helper(family):
    script = 'build-jq-release.py' if family == 'jq' else 'build-' + family + '-backport.py'
    file = ROOT / BASE / family / script
    spec = importlib.util.spec_from_file_location('qualified_' + family.replace('-', '_'), file)
    module = importlib.util.module_from_spec(spec)
    sys.dont_write_bytecode = True
    spec.loader.exec_module(module)
    return module


def check_owning_tests(family, files, provenance, directory):
    directory.mkdir()
    if family in ('jq', 'pcre2'):
        expected = ['pcre2_jit_test', 'RunTest', 'RunGrepTest'] if family == 'pcre2' else [
            'mantest', 'jqtest', 'shtest', 'utf8test', 'base64test', 'uritest', 'optionaltest', 'onigtest', 'manonigtest']
        tests = provenance['tests']
        require([row['test'] for row in tests] == expected, 'Owning test set changed')
        for row in tests:
            data = files[row['test'] + '.trs']
            require(sha(data) == row['sha256'] and row['status'] == 'PASS'
                    and re.findall(rb'^:test-result: (\S+)$', data, re.M) == [b'PASS']
                    and re.findall(rb'^:global-test-result: (\S+)$', data, re.M) == [b'PASS']
                    and row['test'] + '.log' in files, 'Native owning test did not pass')
        if family == 'jq':
            smoke = provenance['packageSmoke']
            require(smoke['status'] == 'PASS' and smoke['validInputCases'] == 4
                    and smoke['soname'] == 'libjq.so.1' and smoke['systemOniguruma'] == 'libonig.so.5'
                    and smoke['publicAbiSymbols'] > 0, 'jq original ABI/system oniguruma smoke missing')
        return {'status': 'qualified', 'owningTests': expected}
    helper = module_helper(family)
    if family == 'p11-kit':
        suite = provenance['tests']['fullOwningSuite']
        (directory / 'test-suite.log').write_bytes(files['test-suite.log'])
        for row in suite['receipts']:
            path = safe_name(row['path'])
            for suffix in ('.trs', '.log'):
                name = str(path.with_suffix(suffix))
                target = directory / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(files[name.replace('/', '__')])
        result = helper.full_suite(directory, suite['configuredTestLogs'])[0]
        require(result['counts'] == suite['counts'] and result['uniqueCaseTotal'] == suite['uniqueCaseTotal'],
                'P11 actual owning evidence disagrees with provenance')
        require(provenance['tests']['packagedCliAndPkcs11'] == 'PASS', 'P11 package smoke missing')
        return {'status': 'qualified', 'counts': result['counts'], 'uniqueCaseTotal': result['uniqueCaseTotal'],
                'architectureCaveat': provenance['tests']['cve18938ArchitectureCaveat']}
    if family == 'rust-coreutils':
        log = directory / 'strict-tests.log'; log.write_bytes(files['strict-tests.log'])
        suite = provenance['strictOwningSuite']
        result = helper.strict_test_receipt(log, suite['owningTestContract'],
                                           'true' if suite['lognameCoverage']['ciMarkerForwarded'] else None)
        require(result['sha256'] == suite['sha256'] and len(result['idCasesReportedOk']) == 19,
                'Rust owning-test evidence changed')
        credentials = provenance['distinctCredentialBinaryTests']
        cases = [(65534, 1, [2]), (1, 65534, [1, 2, 65534]), (65534, 65534, [2])]
        require([(c['realGid'], c['effectiveGid'], c['supplementaryGids']) for c in credentials] == cases,
                'Packaged distinct-GID case set changed')
        for case in credentials:
            real, effective, groups = case['realGid'], case['effectiveGid'], case['supplementaryGids']
            outputs = case['outputs']; expected = list(dict.fromkeys([real, effective] + sorted(groups)))
            require(case['status'] == 'PASS' and all(list(map(int, outputs[flag].split())) == expected
                    for flag in ['-G', '-G -r']) and outputs['-g'] == str(effective)
                    and outputs['-g -r'] == str(real), 'Packaged distinct-GID numeric outputs failed')
            match = re.search(r' groups=([^\s]+)', outputs[''])
            actual = [int(x.split('(')[0]) for x in match[1].split(',')] if match else []
            require(actual == list(dict.fromkeys([effective] + sorted(groups))), 'Packaged default GID ordering failed')
        return {'status': 'qualified', 'idCases': 19, 'credentialCases': 3,
                'owningTestContract': suite['owningTestContract'], 'lognameCoverage': suite['lognameCoverage']}
    if family == 'libxrender':
        cases = json.loads(files['reply-boundary.json'])
        require([row['test'] for row in cases] == ['patched', 'original', 'packaged'], 'XRender fixture set changed')
        for row in cases:
            helper.check_result(row['exitCode'], row['output'], row['test'] == 'original')
        require(provenance['tests']['owningCheck'] == 'PASS'
                and provenance['tests']['upstreamDefinedTestCases'] == 0, 'XRender owning contract changed')
        return {'status': 'qualified', 'upstreamDefinedTestCases': 0, 'replyBoundaryCases': cases}
    require(family == 'glibc', 'Unknown owning-test family')
    before, approved = provenance['debianPackagingInputSha256'], provenance['approvedPackagingSha256']
    generated = provenance['generatedControlMetadata']
    # The original quilt series is extended by exactly the two approved patches.
    additions = {'debian/patches/' + p['name']: p['sha256'] for p in provenance['patches']}
    require(set(approved) == set(before) | set(additions)
            and all(approved[name] == digest for name, digest in additions.items())
            and sorted(name for name in before if before[name] != approved[name]) == ['debian/control', 'debian/patches/series']
            and before['debian/control'] == helper.CONTROL_ORIGINAL_SHA256 == generated['originalSha256']
            and approved['debian/control'] == helper.CONTROL_GENERATED_SHA256 == generated['generatedSha256']
            and sha(files['generated-debian-control']) == helper.CONTROL_GENERATED_SHA256
            and all(before[name] == digest for name, digest in generated['inputSha256'].items()),
            'glibc original-template control generation proof changed')
    entries = helper.parse_test_summary(files['tests.sum'].decode('utf-8'))
    counts = dict(Counter(state for state, _ in entries)); states = {name: state for state, name in entries}
    require(not any(counts.get(s, 0) for s in ['FAIL', 'ERROR', 'UNRESOLVED'])
            and all(states.get(name) == 'PASS' for name in helper.CONTROLS)
            and counts == provenance['tests']['counts']
            and sha(files['tests.sum']) == provenance['tests']['sha256']
            and provenance['tests']['ubuntuGate'] == 'check_libc_passed', 'glibc native test contract failed')
    for component in ['libio', 'stdio-common', 'iconv', 'wcsmbs', 'malloc', 'elf', 'nptl', 'nss']:
        require(any(state == 'PASS' and name.startswith(component + '/') for state, name in entries),
                'glibc component suite did not execute: ' + component)
    for name in helper.CONTROLS:
        require(name.rsplit('/', 1)[-1] + '.out' in files
                and b'PASS' in files[name.rsplit('/', 1)[-1] + '.test-result'], 'glibc control output is missing')
    return {'status': 'qualified', 'counts': counts, 'controls': provenance['tests']['controls']}


def validate_native(family, item, archive, api, root, test_directory):
    verify_api(family, item, api['run'], api['job'], api['artifact'])
    check_source_files(root, item['sourceFiles'])
    contents = read_zip(archive, item['zipSha256'])
    require(contents['source-sha.txt'].decode().strip() == item['sourceCommit'], 'Artifact checkout identity mismatch')
    result = json.loads(contents['export/result.json'])
    require(result['module'] == family and result['sourceSha'] == item['sourceCommit']
            and result['status'] == 'passed'
            and all(type(result[k]) is int and result[k] == 0 for k in ['exitCode', 'helperExitCode', 'logExitCode'])
            and result['sourceLockSha256'] == item['lockSha256'], 'Native exit/lock receipt failed')
    files = {name.removeprefix('export/package/'): data for name, data in contents.items()
             if name.startswith('export/package/')}
    for name, digest in item['evidence'].items():
        require(name in files and sha(files[name]) == digest, 'Native evidence pin mismatch: ' + name)
    require(sha(files[item['copyright']['file']]) == item['copyright']['sha256'], 'Original COPYRIGHT pin mismatch')
    provenance = json.loads(files['provenance.json'])
    require(provenance.get('sourceLockSha256', provenance.get('lockSha256')) == item['lockSha256']
            and sha(files[family + '.lock.json']) == item['lockSha256'], 'Native source lock mismatch')
    records = provenance.get('runtimePackages') or [{'package': family, 'file': provenance['package'],
                                                  'sha256': provenance['packageSha256']}]
    require({r['package'] for r in records} == set(item['runtimePackages']), 'Unexpected native runtime package catalog')
    for package in item['packages']:
        require(sha(files[package['file']]) == package['sha256']
                and any(r['package'] == package['name'] and r['file'] == package['file']
                        and r['sha256'] == package['sha256'] for r in records), 'Deb differs from reviewed native bytes')
    require({name for name in files if name.endswith('.deb')} == {p['file'] for p in item['packages']},
            'Extra native debs are forbidden')
    tests = check_owning_tests(family, files, provenance, test_directory)
    if family == 'rust-coreutils': load_rust_source_audit(item, provenance)
    return files, provenance, tests


def command(args):
    return subprocess.check_output(args, cwd=ROOT, stderr=subprocess.PIPE)


def pcre2_evidence(stage):
    return dict(stage['evidence'], **{'production-stage-' + name: digest
                for name, digest in stage['metadataSha256'].items()}, **{'production-stage-build.log': stage['buildLogSha256']})


def validate_pcre2(item, archive, api, test_directory):
    stage = item['stageInput']; verify_pcre2_api(stage, api['run'], api['job'], api['artifact'])
    contents = read_zip(archive, stage['zipSha256'])
    documents = {}
    for name, path in PCRE2_STAGE_RECEIPTS.items():
        require(sha(contents[path]) == stage['metadataSha256'][name], 'Original PCRE2 qualification metadata changed')
        documents[name] = json.loads(contents[path])
    original = documents['source-inputs.lock.json']['pcre2']
    require(original['kind'] == 'fresh-production-target' and all(original[key] == item[key] for key in
            ['sourceCommit', 'sourceTag', 'target', 'version', 'sourceFiles', 'lockSha256', 'copyrightSha256',
             'runtimePackages', 'fixedVulnerabilities']), 'Original PCRE2 released551 source/recipe closure mismatch')
    manifest, qualification = documents['manifest.json'], documents['qualification.json']
    require(manifest['schemaVersion'] == qualification['schemaVersion'] == 1
            and manifest['platform'] == qualification['platform'] == PLATFORM
            and manifest['qualification'] == {'path': 'qualification.json', 'sha256': stage['metadataSha256']['qualification.json']}
            and qualification['status'] == 'qualified' and 'consumerFixtures' not in qualification
            and qualification['sourceLockSha256'] == stage['metadataSha256']['source-inputs.lock.json'],
            'PCRE2 stage was not qualified before the failed consumer fixture')
    families = [f for f in qualification['families'] if f['name'] == 'pcre2']
    require(len(families) == 1 and families[0]['status'] == 'qualified' and families[0]['nativeInput'] == original
            and families[0]['provenanceSha256'] == stage['evidence']['provenance.json'], 'Original PCRE2 family qualification mismatch')
    prefix = 'context/out/provenance/pcre2/'
    files = {name.removeprefix(prefix): data for name, data in contents.items() if name.startswith(prefix)}
    require(set(files) == set(stage['evidence']) and all(sha(files[n]) == h for n, h in stage['evidence'].items()),
            'PCRE2 native evidence differs from pinned stage bytes')
    require(sha(files['pcre2.lock.json']) == item['lockSha256'] and sha(files['COPYRIGHT']) == item['copyrightSha256'],
            'PCRE2 production source lock/COPYRIGHT mismatch')
    provenance = json.loads(files['provenance.json']); source_lock = json.loads(files['pcre2.lock.json'])
    require(provenance['sourceLockSha256'] == item['lockSha256'] and provenance['sourceFiles'] == source_lock['sourceFiles']
            and provenance['patches'] == source_lock['patches'] and provenance['fixedCves'] == item['fixedVulnerabilities']
            and provenance['debianPackagingInputSha256']['debian/copyright'] == item['copyrightSha256'],
            'PCRE2 native source/packaging proof changed')
    records = provenance['runtimePackages']; selected = stage['packages']
    require([r['package'] for r in records] == item['runtimePackages'], 'Unexpected original PCRE2 runtime catalog')
    actual = [p for p in manifest['packages'] if p['family'] == 'pcre2']
    require([p['name'] for p in actual] == item['runtimePackages'], 'Original manifest PCRE2 catalog mismatch')
    for p, record, entry in zip(selected, records, actual):
        require(record['package'] == entry['name'] == p['name'] and record['version'] == entry['version'] == p['version']
                and record['architecture'] == entry['architecture'] == 'amd64' and entry['source'] == 'pcre2'
                and record['file'] == p['file'] and entry['archive'] == {'path': 'debs/' + p['file'], 'sha256': p['sha256']}
                and record['sha256'] == p['sha256'], 'PCRE2 archive/provenance/original manifest mismatch')
        files[p['file']] = contents['context/out/debs/' + p['file']]
        require(sha(files[p['file']]) == p['sha256'], 'PCRE2 deb differs from the reviewed stage pin')
    tests = check_owning_tests('pcre2', files, provenance, test_directory)
    require(families[0]['owningChecks'] == tests, 'Original PCRE2 owning receipt was not qualified')
    for name, path in PCRE2_STAGE_RECEIPTS.items(): files['production-stage-' + name] = contents[path]
    files['production-stage-build.log'] = contents['publisher/pcre2-build.log']
    require(sha(files['production-stage-build.log']) == stage['buildLogSha256']
            and ('PCRE2_BACKPORT_BUILT packages=2 tests=3 lock=' + item['lockSha256']).encode()
                in files['production-stage-build.log'], 'Original native PCRE2 build completion receipt is missing')
    tests['originalPublisherScope'] = {'runConclusion': 'failure', 'jobConclusion': 'failure',
                                      'consumerConclusion': 'failure', 'publicationConclusion': 'skipped',
                                      'scope': 'PCRE2 source/package/owning-test qualification only'}
    return files, provenance, tests


def package_payload(archive, expected, directory):
    fields = {key: command(['dpkg-deb', '--field', str(archive), key]).decode().strip()
              for key in ['Package', 'Version', 'Architecture', 'Source']}
    require(fields['Package'] == expected['name'] and fields['Version'] == expected['version']
            and fields['Architecture'] == 'amd64' and fields['Source'] in
            ['', expected['source'], expected['source'] + ' (' + expected['version'] + ')'], 'Deb control identity mismatch')
    require(fields['Source'] or expected['name'] == expected['source'], 'Deb Source omission is not permitted here')
    data = command(['dpkg-deb', '--fsys-tarfile', str(archive)])
    files, blobs, pending, elf, members, elf_cache = [], {}, [], [], {}, {}
    with tarfile.open(fileobj=io.BytesIO(data)) as source:
        require(sum(m.size for m in source.getmembers()) < 1024 * 1024 * 1024, 'Deb payload exceeds size bound')
        for member in source.getmembers():
            name = member.name.removeprefix('./').rstrip('/')
            if name == '.' and member.isdir(): continue
            if not name and member.isdir(): continue
            path = str(safe_name(name))
            require(path not in members, 'Duplicate deb payload path')
            members[path] = member
            if member.isdir(): continue
            item = {'path': path, 'mode': stat.S_IMODE(member.mode), 'uid': member.uid, 'gid': member.gid}
            if member.issym():
                item.update(type='symlink', target=member.linkname)
            elif member.isreg():
                content = source.extractfile(member).read(); blobs[path] = content
                item.update(type='file', sha256=sha(content))
            elif member.islnk():
                item.update(type='file'); pending.append((item, str(safe_name(member.linkname.removeprefix('./')))))
            else:
                raise ValueError('Special deb payload entries are forbidden')
            files.append(item)
    while pending:
        next_pending = []
        for item, target in pending:
            if target in blobs:
                blobs[item['path']] = blobs[target]; item['sha256'] = sha(blobs[target])
            else: next_pending.append((item, target))
        require(len(next_pending) < len(pending), 'Unresolved/cyclic deb hardlink')
        pending = next_pending
    for item in files:
        require(not any(parent.as_posix() in members and not members[parent.as_posix()].isdir()
                        for parent in PurePosixPath(item['path']).parents), 'Deb entry has a non-directory parent')
        if item['type'] != 'file' or not blobs[item['path']].startswith(b'\x7fELF'): continue
        content = blobs[item['path']]
        require(len(content) >= 64 and content[4:6] == b'\x02\x01' and struct.unpack_from('<H', content, 18)[0] == 62,
                'Runtime payload is not native amd64 ELF64')
        digest = sha(content)
        if digest not in elf_cache:
            probe = directory / digest; probe.write_bytes(content)
            dynamic = command(['readelf', '--dynamic', str(probe)]).decode()
            symbols = command(['nm', '--dynamic', '--defined-only', '--extern-only', str(probe)]).decode()
            sonames = re.findall(r'SONAME.*\[(.+?)\]', dynamic)
            require(len(sonames) <= 1, 'Ambiguous ELF SONAME')
            elf_cache[digest] = {'soname': sonames[0] if sonames else None,
                                'needed': sorted(set(re.findall(r'NEEDED.*\[(.+?)\]', dynamic))),
                                'definedSymbols': sorted({line.split()[-1].split('@')[0]
                                                          for line in symbols.splitlines() if line.split()})}
        elf.append(dict(elf_cache[digest], path=item['path'], sha256=digest, elfClass=64, machine=62))
    return dict(schemaVersion=1, package=expected['name'], version=expected['version'], architecture='amd64',
                source=expected['source'], files=sorted(files, key=lambda x: x['path']), elf=sorted(elf, key=lambda x: x['path']))


def purl(package):
    version, epoch = package['version'], None
    if ':' in version:
        epoch, version = version.split(':', 1)
        require(re.fullmatch('[0-9]+', epoch) and version, 'Invalid Debian epoch/version')
    return ('pkg:deb/ubuntu/' + package['name'] + '@' + quote(version, safe='') +
            '?arch=amd64&distro=ubuntu-26.04' + ('&epoch=' + epoch if epoch is not None else ''))


def write_checksums(output):
    (output / 'SHA256SUMS').write_text(''.join(file_sha(file) + '  ' + file.relative_to(output).as_posix() + '\n'
        for file in sorted(output.rglob('*')) if file.is_file() and file.name != 'SHA256SUMS'), encoding='utf-8')


def export_metadata_guard(output):
    guard = HERE / 'verify-consumer-evidence.py'
    shutil.copyfile(guard, output / guard.name)
    return {'path': guard.name, 'sha256': file_sha(guard),
            'sourcePath': BASE + 'bundle/' + guard.name,
            'scope': 'Read-only metadata guard; findings are never filtered. Consumers use native Trivy --vex.'}


def qualify(lock):
    check_current_source(lock)
    check_pcre2_source(lock)
    output = WORK / 'context' / 'out'
    require(not output.exists(), 'Qualified bundle output must be new')
    output.mkdir(parents=True)
    (WORK / 'owning-replay').mkdir()
    (WORK / 'elf-probes').mkdir()
    installer = WORK / 'installer-export' / 'install-existing-backports'
    binary = installer.read_bytes()
    require(len(binary) >= 64 and binary[:6] == b'\x7fELF\x02\x01'
            and struct.unpack_from('<H', binary, 18)[0] == 62, 'Installer is not native amd64 ELF64')
    require('INTERP' not in command(['readelf', '--program-headers', str(installer)]).decode()
            and 'NEEDED' not in command(['readelf', '--dynamic', str(installer)]).decode(),
            'Installer must be a static binary with no runtime library dependencies')
    shutil.copyfile(installer, output / 'install-existing-backports')
    (output / 'install-existing-backports').chmod(0o755)
    installer_proof = {'path': 'install-existing-backports', 'sha256': sha(binary), 'toolchain': 'go1.27.3',
                       'sourceFiles': {file.relative_to(ROOT).as_posix(): file_sha(file)
                          for file in sorted((HERE / 'installer').rglob('*')) if file.is_file()}}
    guard_proof = export_metadata_guard(output)
    families, packages, qualifications = [], [], []
    for family in FAMILIES:
        if family == 'pcre2':
            item = lock['pcre2']
            api = json.loads((WORK / 'inputs' / 'pcre2-api.json').read_text())
            files, provenance, tests = validate_pcre2(item, WORK / 'inputs' / 'pcre2.zip', api,
                                                     WORK / 'owning-replay' / family)
            selected, evidence = item['stageInput']['packages'], pcre2_evidence(item['stageInput'])
        else:
            item = lock['nativeInputs'][family]
            api = json.loads((WORK / 'inputs' / (family + '-api.json')).read_text())
            files, provenance, tests = validate_native(family, item, WORK / 'inputs' / (family + '.zip'), api,
                                                      ROOT, WORK / 'owning-replay' / family)
            selected, evidence = item['packages'], item['evidence']
        destination = output / 'provenance' / family; destination.mkdir(parents=True)
        for name, digest in evidence.items():
            require(safe_name(name).name == name and sha(files[name]) == digest, 'Unsafe/mutated output evidence')
            (destination / name).write_bytes(files[name])
        write_json(destination / 'artifact-api.json', api)
        if family != 'pcre2':
            raw = read_zip(WORK / 'inputs' / (family + '.zip'), item['zipSha256'])
            (destination / 'native-result.json').write_bytes(raw['export/result.json'])
        if family == 'rust-coreutils':
            load_rust_source_audit(item, provenance)
            shutil.copyfile(RUST_AUDIT_FILE, output / RUST_AUDIT_FILE.name)
        prov_sha = sha(files['provenance.json'])
        families.append({'name': family, 'source': family, 'version': selected[0]['version'],
                         'provenance': {'path': 'provenance/' + family + '/provenance.json', 'sha256': prov_sha}})
        qualifications.append({'name': family, 'status': 'qualified', 'provenanceSha256': prov_sha,
                               'nativeInput': item, 'owningChecks': tests})
        for package in selected:
            require(sha(files[package['file']]) == package['sha256'], 'Runtime deb pin mismatch')
            archive = output / 'debs' / package['file']; archive.parent.mkdir(exist_ok=True)
            archive.write_bytes(files[package['file']])
            payload = package_payload(archive, package, WORK / 'elf-probes')
            payload_path = output / 'payload' / (package['name'] + '.json'); write_json(payload_path, payload)
            packages.append({'name': package['name'], 'family': family, 'version': package['version'],
                             'architecture': 'amd64', 'source': family,
                             'archive': {'path': 'debs/' + package['file'], 'sha256': package['sha256']},
                             'payload': {'path': 'payload/' + package['name'] + '.json', 'sha256': file_sha(payload_path)}})
    write_json(output / 'qualification.json', {'schemaVersion': 1, 'bundleVersion': '0.1.0', 'platform': PLATFORM,
               'status': 'qualified', 'families': qualifications, 'sourceLockSha256': file_sha(LOCK_FILE),
               'installer': installer_proof,
               'consumerEvidenceVerifier': guard_proof,
               'consumerStatus': 'Package inputs only; consumer installation, rootfs scan and product acceptance remain required.'})
    shutil.copyfile(LOCK_FILE, output / 'source-inputs.lock.json')
    write_json(output / 'manifest.json', {'schemaVersion': 1, 'bundleVersion': '0.1.0', 'platform': PLATFORM,
               'qualification': {'path': 'qualification.json', 'sha256': file_sha(output / 'qualification.json')},
               'families': families, 'packages': packages})
    components = [{'type': 'library', 'name': p['name'], 'version': p['version'], 'purl': purl(p),
                   'bom-ref': purl(p), 'hashes': [{'alg': 'SHA-256', 'content': p['archive']['sha256']}]} for p in packages]
    components.append({'type': 'application', 'name': 'install-existing-backports', 'version': '0.1.0',
                       'bom-ref': 'pkg:generic/pasturestack/backport-installer@0.1.0',
                       'purl': 'pkg:generic/pasturestack/backport-installer@0.1.0',
                       'hashes': [{'alg': 'SHA-256', 'content': sha(binary)}],
                       'properties': [{'name': 'pasturestack:go-toolchain', 'value': 'go1.27.3'}]})
    write_json(output / 'sbom.cdx.json', {'bomFormat': 'CycloneDX', 'specVersion': '1.6', 'version': 1,
               'metadata': {'component': {'type': 'data', 'name': 'ubuntu-security-backports', 'version': '0.1.0'}},
               'components': components})
    statements = []
    for family in FAMILIES:
        item = lock['pcre2'] if family == 'pcre2' else lock['nativeInputs'][family]
        for vulnerability in item['fixedVulnerabilities']:
            statements.append({'vulnerability': {'@id': ('https://github.com/advisories/' if vulnerability.startswith('GHSA-')
                                else 'https://www.cve.org/CVERecord?id=') + vulnerability, 'name': vulnerability},
                               'products': [{'@id': purl(p)} for p in packages if p['family'] == family],
                               'status': 'fixed', 'action_statement': item['vexScope']})
    write_json(output / 'openvex.json', {'@context': 'https://openvex.dev/ns/v0.2.0',
               '@id': 'https://github.com/PastureStack/server/ubuntu-security-backports/0.1.0',
               'author': 'PastureStack', 'timestamp': lock['vexTimestamp'], 'version': 1, 'statements': statements})
    write_json(output / 'tracked-scopes.json', lock['trackedScopes'])
    write_checksums(output)


def record_consumer_tests():
    output = WORK / 'context' / 'out'
    qualification = json.loads((output / 'qualification.json').read_text())
    require('consumerFixtures' not in qualification, 'Consumer qualification cannot be overwritten')
    manifest_sha = file_sha(output / 'manifest.json')
    records = []
    checks = ['batch-install', 'verify-installed', 'package-set', 'provider', 'docs-restored',
              'glibc-loader', 'jq', 'libjq-RTLD_NOW-TLS-threads', 'id', 'p11-kit', 'grep', 'getent']
    for provider in ['gnu', 'uutils']:
        source = WORK / ('consumer-' + provider)
        result = json.loads((source / 'result.json').read_text())
        selected = sorted(name for names in FAMILIES.values() for name in names
                          if provider == 'uutils' or name != 'rust-coreutils')
        require(result['schemaVersion'] == 1 and result['provider'] == provider and result['status'] == 'PASS'
                and result['inputManifestSha256'] == manifest_sha and sorted(result['selectedPackages']) == selected
                and result['checks'] == checks, 'Actual consumer fixture receipt failed: ' + provider)
        destination = output / 'provenance' / 'consumer' / provider
        destination.mkdir(parents=True)
        evidence = {}
        for file in sorted(source.iterdir()):
            require(file.is_file() and not file.is_symlink() and file.suffix in ['.json', '.log', '.tsv', '.txt', '.sha256'],
                    'Unexpected consumer evidence file')
            shutil.copyfile(file, destination / file.name)
            evidence[file.name] = file_sha(file)
        require(len(evidence) >= 4, 'Consumer install/verify/console evidence is missing')
        records.append({'provider': provider, 'status': 'PASS', 'inputManifestSha256': manifest_sha,
                        'selectedPackages': selected, 'checks': checks, 'evidence': evidence})
    qualification['consumerFixtures'] = records
    qualification['consumerStatus'] = ('Both isolated provider fixtures passed actual installation and verification; '
                                       'real consumer image rootfs scanning and product acceptance remain required.')
    write_json(output / 'qualification.json', qualification)
    manifest = json.loads((output / 'manifest.json').read_text())
    manifest['qualification']['sha256'] = file_sha(output / 'qualification.json')
    write_json(output / 'manifest.json', manifest)
    write_checksums(output)
    print('BOTH_CONSUMER_INSTALL_FIXTURES_PASS')


def verify_readback():
    expected, actual = WORK / 'context' / 'out', WORK / 'readback' / 'out'
    inventory = lambda root: {file.relative_to(root).as_posix(): file_sha(file)
                              for file in root.rglob('*') if file.is_file() and not file.is_symlink()}
    require(expected.is_dir() and actual.is_dir() and inventory(expected) == inventory(actual),
            'Anonymous OCI readback differs from qualified producer bytes')
    require(not any(p.is_symlink() for p in actual.rglob('*')), 'OCI data readback contains a symlink')
    require(file_sha(WORK / 'readback' / 'bundle-installer') == file_sha(expected / 'install-existing-backports'),
            'OCI installer copies differ')
    print('ANONYMOUS_OCI_READBACK_OK')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    for option in ['check-lock', 'require-ready', 'print-work-root', 'fetch', 'check-pcre2-source', 'qualify',
                   'verify-readback', 'check-new-tag', 'verify-published-manifest', 'verify-anonymous-manifest',
                   'record-consumer-tests']:
        mode.add_argument('--' + option, action='store_true')
    args = parser.parse_args()
    if args.print_work_root: print(WORK); return
    if args.verify_readback: verify_readback(); return
    if args.record_consumer_tests: record_consumer_tests(); return
    if args.check_new_tag: registry_manifest('absent'); return
    if args.verify_published_manifest: registry_manifest('published'); return
    if args.verify_anonymous_manifest: registry_manifest('anonymous'); return
    lock = load_lock(ready=args.require_ready or args.fetch or args.qualify)
    if args.check_lock or args.require_ready:
        check_current_source(lock); print('BUNDLE_SOURCE_LOCK_OK'); return
    if args.fetch: fetch_native(lock); return
    if args.check_pcre2_source: check_pcre2_source(lock); return
    qualify(lock)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, subprocess.SubprocessError, zipfile.BadZipFile) as error:
        print('BUNDLE_QUALIFICATION_FAILED: ' + str(error), file=sys.stderr)
        sys.exit(1)

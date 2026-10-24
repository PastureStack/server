#!/usr/bin/env python3
"""First-party Ubuntu tar 1.35 CVE-2026-18477 backport; native CI only.

Keep original Ubuntu packaging and full configured Autotest suite. The complete
released vendor patch is retained; only its NEWS documentation section is omitted
from application. CVE-2026-18508 is tracked and has no patch in this module.
"""
import argparse
import collections
import datetime
import email.utils
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
LOCK_FILE = HERE / 'tar.lock.json'
SPEC = importlib.util.spec_from_file_location('tar_backport_common', HERE.parent / 'build-pcre2-backport.py')
COMMON = importlib.util.module_from_spec(SPEC)
_bytecode = sys.dont_write_bytecode
sys.dont_write_bytecode = True
try:
    SPEC.loader.exec_module(COMMON)
finally:
    sys.dont_write_bytecode = _bytecode
require, digest, run, capture = COMMON.require, COMMON.digest, COMMON.run, COMMON.capture
VERSION = '1.35+dfsg-4ubuntu0.4'
VENDOR = '60b4d64ef2d933d3c14cbf8844268e88a90dc69f'
PATCH_NAME = 'tar-1.35-CVE-2026-18477.patch'
PATCH_SHA = 'aea389d8ca495bc0474c00a339f137c00e159ffc28caed65b02823be4f5046af'
DERIVED_SHA = 'd8190f7ff8faa6c6fbe0f3df4bb464d440b9af6cdd678049a7a4dbbb98bf62c6'
DERIVED_NAME = 'tar-18477-ubuntu-doc-context.patch'
APPLIED = ['THANKS', 'lib/Makefile.am', 'lib/mkdtempat.c', 'lib/mkdtempat.h',
           'src/incremen.c', 'tests/Makefile.am', 'tests/rename08.at',
           'tests/rename09.at', 'tests/testsuite.at']
PINS = {'tar_' + VERSION + '.dsc': ('e42458c1675ec7ba43cca2ea8e085231337e7a4553d7c6e2c21d2003761e5d43', 2124),
        'tar_1.35+dfsg.orig.tar.xz': ('9ae57e981c1e73c0eebc2b26c9b0c4497fe310ef1d516ea430efb5470b71f7a8', 2111608),
        'tar_' + VERSION + '.debian.tar.xz': ('25d8e50e31629e85baef5da32b3030e5ad0c9148ab3ee6b1428212a10e307e4d', 52824)}


def load_lock(file=LOCK_FILE):
    lock = json.loads(file.read_text(encoding='utf-8'))
    expected = {'schemaVersion': 1, 'sourcePackage': 'tar', 'ubuntuSourceVersion': VERSION,
                'customVersion': VERSION + '+pasturestack.1', 'distribution': 'resolute',
                'osVersion': '26.04', 'architecture': 'amd64', 'runtimePackages': ['tar'],
                'fixedCves': ['CVE-2026-18477']}
    require(all(lock.get(k) == v for k, v in expected.items()), 'Unsupported tar source/output identity')
    require(type(lock['sourceDateEpoch']) is int and lock['sourceDateEpoch'] > 0, 'Invalid source date')
    require(len(lock['sourceFiles']) == 3 and {i['name'] for i in lock['sourceFiles']} == set(PINS),
            'Exactly the original Ubuntu DSC/orig/packaging are required')
    for item in lock['sourceFiles']:
        require(item['url'] == 'https://archive.ubuntu.com/ubuntu/pool/main/t/tar/' + item['name']
                and (item['sha256'], item['size']) == PINS[item['name']]
                and type(item['size']) is int, 'Unexpected Ubuntu source URL/hash/size')
    require(len(lock['patches']) == 1, 'Only the released 18477 vendor backport is supported')
    patch = lock['patches'][0]
    require(patch['name'] == PATCH_NAME and patch['sha256'] == PATCH_SHA and patch['size'] == 11055
            and patch['url'] == 'https://gitlab.com/redhat/centos-stream/rpms/tar/-/raw/' + VENDOR + '/' + PATCH_NAME
            and patch['excludedDocumentationPaths'] == ['NEWS']
            and patch['derivedPatchSha256'] == DERIVED_SHA and patch['appliedPaths'] == APPLIED,
            'Unexpected vendor patch, documentation exclusion or derived bytes')
    require(patch['upstreamAcceptedCommits'] == ['0714d2f082104005a1c70ee6ec4175194943ea88',
            'd479b2cc9160d9c2fb61afbc9ee70c2faadf80db', 'b17665b2c0548c77b6cd8d2d5b61e4c4fcc4f770'],
            'Unexpected accepted upstream commits')
    require(lock['vendorBackport']['distGitCommit'] == VENDOR
            and lock['vendorBackport']['version'] == '2:1.35-13.el10'
            and lock['prerequisites']['additionalPatches'] == []
            and lock['prerequisites']['no18508PrerequisitesApplied'] is True
            and [i['id'] for i in lock['blockedCves']] == ['CVE-2026-18508'], 'Unexpected vendor/prerequisite scope')
    require(set(lock['patchedSha256']) == set(APPLIED), 'Incomplete applied-source closure')
    for name, sha in {**lock['baselineSha256'], **lock['patchedSha256']}.items():
        require(not Path(name).is_absolute() and '..' not in Path(name).parts
                and re.fullmatch('[0-9a-f]{64}', sha), 'Unsafe source proof entry')
    return lock


def verify_source_control(lock, directory):
    text = (directory / ('tar_' + VERSION + '.dsc')).read_text(encoding='utf-8')
    require(all(re.search('^' + re.escape(line) + '$', text, re.M) for line in
                ['Format: 3.0 (quilt)', 'Source: tar', 'Version: ' + VERSION]), 'Wrong Ubuntu source control')
    block = re.search(r'^Checksums-Sha256:\n((?: .+\n)+)', text, re.M)
    require(block, 'Missing source checksum manifest')
    rows = re.findall(r'^ ([0-9a-f]{64}) (\d+) (\S+)$', block[1], re.M)
    require(len(rows) == 2 and {n: (s, int(z)) for s, z, n in rows}
            == {i['name']: (i['sha256'], i['size']) for i in lock['sourceFiles'] if not i['name'].endswith('.dsc')},
            'DSC/source lock mismatch')


def derived_patch(lock, file):
    COMMON.verify_input(lock['patches'][0], file)
    data = file.read_bytes()
    blocks = re.findall(rb'(?ms)^diff --git .*?(?=^diff --git |\Z)', data)
    paths = [re.match(rb'diff --git a/(\S+) b/(\S+)\n', b).groups() for b in blocks]
    require(paths == [(p.encode(), p.encode()) for p in ['NEWS'] + APPLIED], 'Unexpected vendor patch paths/order')
    # Entire diff sections are copied unchanged. No code/test hunk is edited,
    # dropped, rebased or fuzzed; existing Ubuntu NEWS remains in place.
    result = b''.join(blocks[1:])
    import hashlib
    require(hashlib.sha256(result).hexdigest() == DERIVED_SHA, 'Derived patch bytes changed')
    return result


def validate_inputs(lock, directory):
    for item in lock['sourceFiles'] + lock['patches']:
        COMMON.verify_input(item, directory / item['name'])
    verify_source_control(lock, directory)
    derived_patch(lock, directory / PATCH_NAME)


def verify_sources(source, expected):
    for name, sha in expected.items():
        file = source / name
        require(file.is_file(), 'Missing source/prerequisite file: ' + name)
        actual = digest(file)
        require(actual == sha, 'Source/prerequisite SHA-256 mismatch: ' + name
                + ' (expected=' + sha + ', actual=' + actual + ')')


def verify_series(original, updated):
    lines = updated.splitlines(keepends=True)
    added = [line for line in lines if line.strip() == DERIVED_NAME]
    require(len(added) == 1 and ''.join(line for line in lines if line.strip() != DERIVED_NAME) == original,
            'Existing quilt series bytes changed')
    active = lambda text: [line.strip() for line in text.splitlines() if line.strip() and not line.lstrip().startswith('#')]
    require(active(updated) == active(original) + [DERIVED_NAME], 'Existing quilt patch order changed')


def build_environment(lock, jobs):
    COMMON.job_option(jobs)
    env = COMMON.build_environment(lock, jobs)
    # Preserve Ubuntu's own future=+lfs and compiler/hardening policy in debian/rules.
    env.pop('DEB_BUILD_MAINT_OPTIONS', None)
    return env


def test_receipt(source):
    script = source / 'tests/testsuite'
    log = source / 'tests/testsuite.log'
    require(script.is_file() and log.is_file(), 'Missing full native Autotest script/log')
    expected = dict(re.findall(r'^(\d+);([^;]+\.at):\d+;', script.read_text(encoding='utf-8'), re.M))
    rows = re.findall(r'^(\d+)\. .*? \(([^()]+\.at):\d+\): (.+)$', log.read_text(encoding='utf-8', errors='replace'), re.M)
    require(len(expected) > 200 and len(rows) == len(expected) and len({i for i, _, _ in rows}) == len(rows),
            'Configured native suite was missing, filtered or ambiguous')
    actual, counts = {}, collections.Counter()
    for number, name, text in rows:
        require(expected.get(number) == name, 'Autotest identity mismatch')
        if text.startswith('ok'):
            state = 'PASS'
        elif text.startswith('skipped ('):
            state = 'SKIP'
        elif text.startswith('expected failure ('):
            state = 'XFAIL'
        else:
            raise ValueError('Unexpected native result: ' + text)
        actual[number] = state
        counts[state] += 1
    controls = {}
    for name in ['rename08.at', 'rename09.at']:
        matches = [i for i, f in expected.items() if f == name]
        require(len(matches) == 1 and actual[matches[0]] == 'PASS', 'CVE regression did not PASS: ' + name)
        controls[name] = matches[0]
    return {'configuredGroups': len(expected), 'counts': dict(counts), 'regressionGroups': controls,
            'logSha256': digest(log), 'suiteSha256': digest(script), 'addedSkips': 0,
            'scope': 'All groups in the original Ubuntu configured suite; original SKIP/XFAIL are recorded. Optional external check-full corpus is not enabled by original packaging.'}


def tar_smoke(binary, work, env, log):
    require(binary.is_file(), 'Packaged tar is missing')
    directory = work / 'tar-smoke'
    source, restored = directory / 'source', directory / 'restored'
    tree = source / 'tree'; (tree / 'dir').mkdir(parents=True)
    restored.mkdir()
    payload = tree / 'dir/file'; payload.write_bytes(b'first-party tar roundtrip\n')
    os.link(payload, tree / 'hard')
    os.symlink('dir/file', tree / 'relative-link')
    archive, delta, snapshot = directory / 'base.tar', directory / 'delta.tar', directory / 'state.snar'
    run([str(binary), '--create', '--listed-incremental=' + str(snapshot), '--file', str(archive),
         '--directory', str(source), 'tree'], work, env, log)
    listing = capture([str(binary), '--list', '--file', str(archive)], work, env)
    require(all(n in listing.splitlines() for n in ['tree/dir/file', 'tree/hard', 'tree/relative-link']), 'Archive listing changed')
    run([str(binary), '--extract', '--listed-incremental=/dev/null', '--file', str(archive),
         '--directory', str(restored)], work, env, log)
    require((restored / 'tree/dir/file').read_bytes() == payload.read_bytes()
            and os.readlink(restored / 'tree/relative-link') == 'dir/file'
            and os.stat(restored / 'tree/hard').st_ino == os.stat(restored / 'tree/dir/file').st_ino,
            'Extracted file/link semantics changed')
    (tree / 'dir').rename(tree / 'moved')
    (tree / 'moved/file').write_bytes(b'incremental rename roundtrip\n')
    run([str(binary), '--create', '--listed-incremental=' + str(snapshot), '--file', str(delta),
         '--directory', str(source), 'tree'], work, env, log)
    run([str(binary), '--extract', '--listed-incremental=/dev/null', '--file', str(delta),
         '--directory', str(restored)], work, env, log)
    require((restored / 'tree/moved/file').read_bytes() == (tree / 'moved/file').read_bytes()
            and not (restored / 'tree/dir').exists(), 'Incremental directory rename semantics changed')
    return {'status': 'PASS', 'checks': ['create/list/extract', 'hardlink inode', 'relative symlink',
            'incremental directory rename/restore'], 'binarySha256': digest(binary),
            'version': capture([str(binary), '--version'], work, env).splitlines()[0]}


def build(args, lock):
    release = dict(re.findall(r'^(\w+)=["\']?([^"\'\n]+)', Path('/etc/os-release').read_text(encoding='utf-8'), re.M))
    require(release.get('ID') == 'ubuntu' and release.get('VERSION_ID') == '26.04', 'Use an isolated Ubuntu 26.04 builder')
    require(os.geteuid() != 0, 'Original Ubuntu tar full tests require a non-root builder')
    env = build_environment(lock, args.jobs)
    for tool in ['dpkg', 'dpkg-source', 'dpkg-buildpackage', 'dpkg-checkbuilddeps', 'dpkg-deb',
                 'dpkg-query', 'quilt', 'readelf', 'fakeroot']:
        require(shutil.which(tool, path=env['PATH']), 'Missing builder tool: ' + tool)
    require(capture(['dpkg', '--print-architecture'], HERE, env) == 'amd64', 'Native amd64 required')
    output = args.output_dir.resolve(); cache = args.cache_dir.resolve() if args.cache_dir else None
    require(not output.exists(), 'Output directory must be new')
    COMMON.require_separate_paths(output, args.work_dir.resolve() if args.work_dir else None, cache)
    work = args.work_dir.resolve() if args.work_dir else Path(tempfile.mkdtemp(prefix='tar-backport-'))
    if args.work_dir: work.mkdir(parents=True, exist_ok=False)
    print('TAR_BACKPORT_WORK_DIR=' + str(work), flush=True)
    inputs = work / 'inputs'; inputs.mkdir()
    if cache: cache.mkdir(parents=True, exist_ok=True)
    for item in lock['sourceFiles'] + lock['patches']: COMMON.download(item, inputs, cache)
    validate_inputs(lock, inputs)
    patch = inputs / DERIVED_NAME; patch.write_bytes(derived_patch(lock, inputs / PATCH_NAME))
    source, log = work / 'source', work / 'build.log'
    run(['dpkg-source', '--extract', str(inputs / ('tar_' + VERSION + '.dsc')), str(source)], work, env, log)
    verify_sources(source, lock['baselineSha256'])
    packaging = COMMON.packaging_snapshot(source)
    news = digest(source / 'NEWS')
    original_series = (source / 'debian/patches/series').read_text(encoding='utf-8')
    env['QUILT_PATCHES'] = 'debian/patches'
    run(['quilt', 'import', '-P', DERIVED_NAME, str(patch)], source, env, log)
    run(['quilt', 'push', '--fuzz=0'], source, env, log)
    verify_sources(source, lock['patchedSha256'])
    require(digest(source / 'NEWS') == news, 'Existing Ubuntu NEWS changed')
    require(all(digest(source / n) == sha for n, sha in packaging.items() if n != 'debian/patches/series'),
            'Original packaging inputs changed')
    verify_series(original_series, (source / 'debian/patches/series').read_text(encoding='utf-8'))
    approved = COMMON.packaging_snapshot(source)
    changelog = source / 'debian/changelog'
    date = email.utils.format_datetime(datetime.datetime.fromtimestamp(lock['sourceDateEpoch'], datetime.timezone.utc))
    changelog.write_text('tar (' + lock['customVersion'] + ') resolute; urgency=high\n\n'
                        '  * First-party rebuild, not issued by Canonical or Red Hat.\n'
                        '  * Apply released CVE-2026-18477 source/tests; preserve Ubuntu NEWS.\n'
                        '  * CVE-2026-18508 remains tracked and is not patched here.\n\n'
                        ' -- PastureStack maintainers <pasturestack@users.noreply.github.com>  ' + date + '\n\n'
                        + changelog.read_text(encoding='utf-8'), encoding='utf-8')
    run(['dpkg-checkbuilddeps'], source, env, log)
    command = ['dpkg-buildpackage', '-b', '-us', '-uc', COMMON.job_option(args.jobs)]
    run(command, source, env, log)
    verify_sources(source, approved); verify_sources(source, lock['patchedSha256'])
    tests = test_receipt(source)
    matches = list(work.glob('tar_' + lock['customVersion'] + '_amd64.deb'))
    require(len(matches) == 1, 'Missing/ambiguous selected runtime tar package')
    deb = matches[0]
    for field, value in [('Package', 'tar'), ('Version', lock['customVersion']), ('Architecture', 'amd64')]:
        require(COMMON.deb_field(deb, field, work, env) == value, 'Wrong package ' + field)
    # Debian permits omission when binary and source names/versions are equal;
    # the exact Package/Version above and original DSC already bind this case.
    require(COMMON.deb_field(deb, 'Source', work, env) in ['', 'tar', 'tar (' + lock['customVersion'] + ')'], 'Wrong Source identity')
    extracted = work / 'extracted'
    run(['dpkg-deb', '--extract', str(deb), str(extracted)], work, env, log)
    candidates = [extracted / n for n in ['usr/bin/tar', 'bin/tar'] if (extracted / n).is_file()]
    require(len(candidates) == 1 and candidates[0].resolve().is_relative_to(extracted.resolve()), 'Ambiguous/unsafe packaged binary')
    binary = candidates[0]
    header = capture(['readelf', '--file-header', str(binary)], work, env)
    program = capture(['readelf', '--program-headers', str(binary)], work, env)
    dynamic = capture(['readelf', '--dynamic', str(binary)], work, env)
    require('ELF64' in header and 'X86-64' in header.upper() and 'DYN' in header and 'GNU_RELRO' in program,
            'Native ELF/PIE/RELRO baseline changed')
    smoke = tar_smoke(binary, work, env, log)
    require(smoke['version'] == 'tar (GNU tar) 1.35', 'Unexpected GNU tar version')
    require(digest(extracted / 'usr/share/doc/tar/copyright') == digest(source / 'debian/copyright'),
            'Packaged copyright differs from the original Ubuntu source')
    output.mkdir(parents=True)
    for f, name in [(deb, deb.name), (log, 'build.log'), (LOCK_FILE, 'tar.lock.json'),
                    (inputs / PATCH_NAME, PATCH_NAME), (patch, DERIVED_NAME),
                    (source / 'tests/testsuite.log', 'testsuite.log'), (source / 'config.log', 'config.log'),
                    (source / 'debian/copyright', 'COPYRIGHT')]: shutil.copyfile(f, output / name)
    for pattern in ['tar_*.buildinfo', 'tar_*.changes']:
        files = list(work.glob(pattern)); require(len(files) == 1, 'Missing native build receipt')
        shutil.copyfile(files[0], output / files[0].name)
    selected = {'package': 'tar', 'version': lock['customVersion'], 'architecture': 'amd64', 'file': deb.name, 'sha256': digest(deb)}
    (output / 'builder-packages.tsv').write_text(capture(
        ['dpkg-query', '--show', '--showformat=${binary:Package}\t${Version}\n'], work, env) + '\n', encoding='utf-8')
    provenance = {'schemaVersion': 1, 'identity': lock['identity'], 'sourceLockSha256': digest(LOCK_FILE),
                  'sourceDateEpoch': lock['sourceDateEpoch'],
                  'sourceFiles': lock['sourceFiles'], 'vendorBackport': lock['vendorBackport'], 'patches': lock['patches'],
                  'documentationPolicy': lock['documentationPolicy'], 'fixedCves': lock['fixedCves'],
                  'blockedCves': lock['blockedCves'], 'prerequisites': lock['prerequisites'],
                  'debianPackagingInputSha256': packaging, 'approvedPackagingSha256': approved,
                  'patchedSourceSha256': lock['patchedSha256'], 'buildCommand': command, 'buildEnvironment': env,
                  'tests': tests, 'tarSmoke': smoke, 'runtimePackages': [selected],
                  'hardening': {'PIE': True, 'RELRO': True, 'BIND_NOW': 'BIND_NOW' in dynamic or bool(re.search(r'FLAGS_1.*NOW', dynamic)),
                                'policy': 'Original Ubuntu debian/rules, compiler flags and ABI retained; no new hardening flags or test exceptions.'},
                  'signaturePolicy': 'Official source SHA pins; custom output is not issued or signed by Canonical/Red Hat.',
                  'runtimeInstalled': False}
    (output / 'tar_smoke.json').write_text(json.dumps(smoke, indent=2) + '\n', encoding='utf-8')
    (output / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n', encoding='utf-8')
    (output / 'manifest.tsv').write_text('lock-sha256\t' + digest(LOCK_FILE) + '\n' + '\t'.join(
        [selected[k] for k in ['package', 'version', 'architecture', 'sha256', 'file']]) + '\n', encoding='utf-8')
    (output / 'SHA256SUMS').write_text(''.join(digest(f) + '  ' + f.name + '\n' for f in sorted(output.iterdir()) if f.is_file()), encoding='utf-8')
    print('TAR_BACKPORT_BUILT packages=1 fixedCves=CVE-2026-18477 lock=' + digest(LOCK_FILE), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--validate-lock', action='store_true')
    parser.add_argument('--output-dir', type=Path)
    parser.add_argument('--work-dir', type=Path)
    parser.add_argument('--cache-dir', type=Path)
    parser.add_argument('--jobs', type=int, choices=(2, 4), default=2)
    args = parser.parse_args()
    lock = load_lock(LOCK_FILE)
    if args.validate_lock: print('TAR_BACKPORT_LOCK_OK sha256=' + digest(LOCK_FILE))
    else:
        require(args.output_dir is not None, '--output-dir is required')
        build(args, lock)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as error:
        print('TAR_BACKPORT_FAILED: ' + str(error), file=sys.stderr)
        sys.exit(1)

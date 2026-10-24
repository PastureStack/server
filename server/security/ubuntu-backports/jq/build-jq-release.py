#!/usr/bin/env python3
"""Build official stable jq 1.8.2 using preserved Ubuntu 26.04 packaging.

Run non-root in an isolated native amd64 builder with the original Build-Depends.
Only changelog and already-upstream security-patch series entries are adjusted.
No runtime installation occurs. Native full tests, ABI, system-onig linkage and
extracted-package smoke must pass before exporting the two runtime packages.
"""
import argparse
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
import tarfile
import tempfile

HERE = Path(__file__).resolve().parent
LOCK = HERE / 'jq.lock.json'
sys.dont_write_bytecode = True
SPEC = importlib.util.spec_from_file_location('pcre2_source_helpers', HERE.parent / 'build-pcre2-backport.py')
C = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(C)
require, digest, download, run, capture = C.require, C.digest, C.download, C.run, C.capture
UBUNTU = '1.8.1-4ubuntu2'
VERSION = '1.8.2-0pasturestack1~26.04.1'
KEPT = ['get-version.patch', 'dont-distribute-duplicate-docs.patch',
        '0008-Do-not-use-venderized-oniguruma.patch', '0006-Do-not-use-pipenv-to-build-docs.patch']
DROPPED = ['CVE-2026-' + x + '.patch' for x in ['32316', '33947', '33948', '39956', '39979', '40164']]
TESTS = ['mantest', 'jqtest', 'shtest', 'utf8test', 'base64test', 'uritest',
         'optionaltest', 'onigtest', 'manonigtest']


def load_lock():
    lock = json.loads(LOCK.read_text(encoding='utf-8'))
    expected = {'schemaVersion': 1, 'sourcePackage': 'jq', 'ubuntuSourceVersion': UBUNTU,
                'upstreamVersion': '1.8.2', 'customVersion': VERSION, 'distribution': 'resolute',
                'osVersion': '26.04', 'architecture': 'amd64', 'runtimePackages': ['jq', 'libjq1'],
                'owningTests': TESTS}
    require(all(lock.get(k) == v for k, v in expected.items()), 'Unexpected jq lock identity')
    require(type(lock['sourceDateEpoch']) is int and lock['sourceDateEpoch'] > 0,
            'Invalid source date')
    source_names = {'jq_' + UBUNTU + '.dsc', 'jq_1.8.1.orig.tar.gz',
                    'jq_' + UBUNTU + '.debian.tar.xz'}
    require(len(lock['sourceFiles']) == 3 and
            {x['name'] for x in lock['sourceFiles']} == source_names, 'Wrong Ubuntu source inputs')
    require([p['name'] for p in lock['retainedUbuntuPatches']] == KEPT and
            [p['patch'] for p in lock['removedUbuntuPatches']] == DROPPED,
            'Unexpected Ubuntu packaging patch boundary')
    upstream = lock['upstream']
    require(upstream['commit'] == '34f7186b86743a083a589741b6cea95293524108'
            and upstream['tag'] == 'jq-1.8.2'
            and upstream['name'] == 'jq-1.8.2.tar.gz', 'Unexpected official stable source')
    require(len(upstream['releaseSecurityCves']) == 16 and
            set(upstream['additionalAdvisories']) ==
            {'GHSA-gf4g-95wj-4q4r', 'GHSA-hj52-j2c9-r8r4'}, 'Incomplete release security inventory')
    for item in lock['sourceFiles'] + [upstream, upstream['checksumFile']]:
        require(re.fullmatch(r'[A-Za-z0-9._~+-]+', item['name'])
                and re.fullmatch(r'[0-9a-f]{64}', item['sha256'])
                and type(item['size']) is int and 0 < item['size'] < 8 * 1024 * 1024,
                'Unpinned or unsafe source')
        expected_url = ('https://archive.ubuntu.com/ubuntu/pool/main/j/jq/' + item['name']
                        if item in lock['sourceFiles'] else
                        'https://github.com/jqlang/jq/releases/download/jq-1.8.2/' +
                        ('sha256sum.txt' if item == upstream['checksumFile'] else item['name']))
        require(item['url'] == expected_url, 'Unexpected source URL')
    for proof in lock['removedUbuntuPatches']:
        require(proof['status'] == 'ahead' and proof['mergeBase'] == proof['officialFixCommit']
                and proof['officialReleaseCommit'] == upstream['commit']
                and re.fullmatch(r'[0-9a-f]{40}', proof['officialFixCommit'])
                and re.fullmatch(r'[0-9a-f]{64}', proof['originalPatchSha256']),
                'Old security patch lacks official inclusion proof')
    for group in ['releaseSourceSha256', 'ubuntuPackagingSha256', 'postUbuntuPatchSha256']:
        for name, sha in lock[group].items():
            require(not Path(name).is_absolute() and '..' not in Path(name).parts
                    and re.fullmatch(r'[0-9a-f]{64}', sha), 'Unsafe/unpinned source path')
    return lock


def verify_hashes(root, expected):
    require(all((root / name).is_file() and digest(root / name) == sha
                for name, sha in expected.items()), 'Source or packaging digest mismatch')


def verify_inputs(lock, inputs):
    for item in lock['sourceFiles'] + [lock['upstream'], lock['upstream']['checksumFile']]:
        file = inputs / item['name']
        require(file.is_file() and file.stat().st_size == item['size']
                and digest(file) == item['sha256'], 'Pinned input mismatch: ' + item['name'])
    text = (inputs / ('jq_' + UBUNTU + '.dsc')).read_text(encoding='utf-8')
    require(all(re.search('^' + re.escape(line) + '$', text, re.M) for line in
                ['Format: 3.0 (quilt)', 'Source: jq', 'Version: ' + UBUNTU]), 'Wrong Ubuntu source')
    block = re.search(r'^Checksums-Sha256:\n((?: .+\n)+)', text, re.M)
    require(block, 'Missing .dsc SHA-256 manifest')
    actual = {n: (h, int(s)) for h, s, n in
              re.findall(r'^ ([0-9a-f]{64}) (\d+) (\S+)$', block[1], re.M)}
    require(actual == {x['name']: (x['sha256'], x['size']) for x in lock['sourceFiles']
                       if not x['name'].endswith('.dsc')}, 'Ubuntu .dsc/lock manifest mismatch')
    text = (inputs / lock['upstream']['checksumFile']['name']).read_text(encoding='utf-8')
    require(re.search(r'^' + lock['upstream']['sha256'] +
                      r'\s+\*?jq-1\.8\.2\.tar\.gz$', text, re.M),
            'Official release checksum list disagrees')


def safe_unpack(archive, work):
    with tarfile.open(archive) as source:
        require(all(Path(p.name).parts and Path(p.name).parts[0] == 'jq-1.8.2'
                    and not Path(p.name).is_absolute() and '..' not in Path(p.name).parts
                    for p in source.getmembers()), 'Unsafe release archive layout')
        source.extractall(work, filter='data')
    return work / 'jq-1.8.2'


def prepare(lock, inputs, work, env, log):
    old = work / 'ubuntu-packaging-source'
    run(['dpkg-source', '--extract', str(inputs / ('jq_' + UBUNTU + '.dsc')), str(old)],
        work, env, log)
    verify_hashes(old, lock['ubuntuPackagingSha256'])
    for patch in lock['retainedUbuntuPatches']:
        require(digest(old / 'debian/patches' / patch['name']) == patch['sha256'],
                'Ubuntu packaging patch changed')
    for proof in lock['removedUbuntuPatches']:
        require(digest(old / 'debian/patches' / proof['patch']) == proof['originalPatchSha256'],
                'Old Ubuntu security patch changed')
    source = safe_unpack(inputs / lock['upstream']['name'], work)
    verify_hashes(source, lock['releaseSourceSha256'])
    shutil.copytree(old / 'debian', source / 'debian', symlinks=True)
    series = source / 'debian/patches/series'
    require(series.read_text(encoding='utf-8').splitlines() == KEPT + DROPPED,
            'Unexpected original Ubuntu series')
    series.write_text(''.join(p + '\n' for p in KEPT), encoding='utf-8')
    changelog = source / 'debian/changelog'
    date = email.utils.format_datetime(datetime.datetime.fromtimestamp(
        lock['sourceDateEpoch'], datetime.timezone.utc))
    changelog.write_text('jq (' + VERSION + ') resolute; urgency=high\n\n'
        '  * First-party PastureStack rebuild; not issued by Canonical.\n'
        '  * Use official stable jq 1.8.2, including all published security fixes.\n'
        '  * Preserve Ubuntu packaging; omit six series entries already upstream.\n\n'
        ' -- PastureStack maintainers <pasturestack@users.noreply.github.com>  ' + date +
        '\n\n' + changelog.read_text(encoding='utf-8'), encoding='utf-8')
    # dpkg-source uses zero-fuzz quilt application and tracks the retained patches.
    run(['dpkg-source', '--before-build', str(source)], work, env, log)
    verify_hashes(source, lock['postUbuntuPatchSha256'])
    original = C.packaging_snapshot(old)
    original.pop('debian/patches/series')
    verify_hashes(source, original)
    return source, C.packaging_snapshot(source)


def test_receipts(source):
    receipts = []
    for name in TESTS:
        reports = list(source.rglob(name + '.trs'))
        require(len(reports) == 1, 'Missing/ambiguous owning test receipt: ' + name)
        report = reports[0]
        require(re.search(r'^:test-result: PASS$', report.read_text(encoding='utf-8'), re.M),
                'Native owning test did not PASS: ' + name)
        receipts.append({'test': name, 'status': 'PASS', 'path': report.relative_to(source).as_posix(),
                         'sha256': digest(report)})
    return receipts


def verify_source_identity(package, value):
    require(value in ['jq', 'jq (' + VERSION + ')'] or (package == 'jq' and value == ''),
            'Source package identity changed')


def verify_packages(lock, source, work, env, log):
    extracted = work / 'extracted'
    selected = []
    for package in ['jq', 'libjq1']:
        files = list(work.glob(package + '_' + VERSION + '_amd64.deb'))
        require(len(files) == 1, 'Missing/ambiguous package: ' + package)
        file = files[0]
        for field, expected in [('Package', package), ('Version', VERSION), ('Architecture', 'amd64')]:
            require(capture(['dpkg-deb', '--field', str(file), field], work, env) == expected,
                    'Package identity changed: ' + field)
        verify_source_identity(package, capture(['dpkg-deb', '--field', str(file), 'Source'], work, env))
        run(['dpkg-deb', '--extract', str(file), str(extracted)], work, env, log)
        selected.append({'package': package, 'version': VERSION, 'architecture': 'amd64',
                         'file': file.name, 'sha256': digest(file)})
    binary, library = extracted / 'usr/bin/jq', extracted / 'usr/lib/x86_64-linux-gnu/libjq.so.1'
    require(binary.is_file() and library.is_file(), 'Expected runtime entry point/SONAME missing')
    dynamic = capture(['readelf', '--dynamic', str(library)], work, env)
    require('[libjq.so.1]' in dynamic and re.search(r'NEEDED.*\[libonig\.so\.5\]', dynamic),
            'libjq ABI/system-oniguruma linkage changed')
    required = re.findall(r'^ ([A-Za-z0-9_]+)@Base ', (source / 'debian/libjq1.symbols').read_text(), re.M)
    symbols = capture(['nm', '--dynamic', '--defined-only', str(library)], work, env)
    exports = {line.split()[-1].split('@')[0] for line in symbols.splitlines() if line.split()}
    require(required and set(required) <= exports, 'An original Ubuntu public ABI symbol is missing')
    for file in [binary, library]:
        dyn = capture(['readelf', '--dynamic', str(file)], work, env)
        headers = capture(['readelf', '--program-headers', str(file)], work, env)
        require('GNU_RELRO' in headers and ('BIND_NOW' in dyn or re.search(r'FLAGS_1.*NOW', dyn)),
                'Ubuntu hardening missing')
    child_env = dict(env, LD_LIBRARY_PATH=str(library.parent))
    require(capture([str(binary), '--version'], work, child_env) == 'jq-1.8.2', 'Wrong packaged version')
    for expression, expected in [('{ok: (1+2)}', '{"ok":3}'),
                                 ('"abc" | test("^a")', 'true'),
                                 ('{a:{b:1}} * {a:{c:2}}', '{"a":{"b":1,"c":2}}'),
                                 ('[1,[2]] | contains([[2]])', 'true')]:
        require(capture([str(binary), '-nc', expression], work, child_env) == expected,
                'Packaged valid-input smoke failed')
    require(digest(extracted / 'usr/share/doc/jq/copyright') ==
            digest(source / 'debian/copyright'), 'Copyright changed')
    return selected, {'validInputCases': 4, 'status': 'PASS', 'publicAbiSymbols': len(required),
                      'soname': 'libjq.so.1', 'systemOniguruma': 'libonig.so.5'}


def build(args, lock):
    release = dict(re.findall(r'^(\w+)=["\']?([^"\'\n]+)',
                              Path('/etc/os-release').read_text(encoding='utf-8'), re.M))
    require(release.get('ID') == 'ubuntu' and release.get('VERSION_ID') == '26.04'
            and os.geteuid() != 0, 'Use a non-root isolated Ubuntu 26.04 native builder')
    require(sys.version_info >= (3, 12), 'Python 3.12 or later is required for safe tar extraction')
    output = args.output_dir.resolve()
    cache = args.cache_dir.resolve() if args.cache_dir else None
    C.require_separate_paths(output, args.work_dir.resolve() if args.work_dir else None, cache)
    require(not output.exists(), 'Output directory must be new')
    work = args.work_dir.resolve() if args.work_dir else Path(tempfile.mkdtemp(prefix='jq-stable-'))
    if args.work_dir: work.mkdir(parents=True, exist_ok=False)
    home = work / 'home'
    home.mkdir(mode=0o700)
    # CLI job choice never becomes an arbitrary command argument or compiler override.
    jobs, job_arg = (2, '-j2') if args.jobs == 2 else (4, '-j4')
    env = C.build_environment(lock, jobs)
    env.update(HOME=str(home), DEB_BUILD_MAINT_OPTIONS='')
    for tool in ['dpkg-source', 'dpkg-buildpackage', 'dpkg-checkbuilddeps', 'dpkg-deb', 'dpkg-query',
                 'readelf', 'nm', 'patch', 'make', 'valgrind']:
        require(shutil.which(tool, path=env['PATH']), 'Builder dependency missing: ' + tool)
    require(capture(['dpkg', '--print-architecture'], work, env) == 'amd64', 'Native amd64 required')
    print('JQ_STABLE_WORK_DIR=' + str(work), flush=True)
    inputs = work / 'inputs'
    inputs.mkdir()
    if cache: cache.mkdir(parents=True, exist_ok=True)
    for item in lock['sourceFiles'] + [lock['upstream'], lock['upstream']['checksumFile']]:
        download(item, inputs, cache)
    verify_inputs(lock, inputs)
    log = work / 'build.log'
    source, packaging = prepare(lock, inputs, work, env, log)
    run(['dpkg-checkbuilddeps'], source, env, log)
    run(['dpkg-buildpackage', '-b', '-us', '-uc', job_arg], source, env, log)
    verify_hashes(source, packaging)
    tests = test_receipts(source)
    packages, smoke = verify_packages(lock, source, work, env, log)
    output.mkdir(parents=True)
    for package in packages:
        shutil.copyfile(work / package['file'], output / package['file'])
    shutil.copyfile(LOCK, output / 'jq.lock.json')
    shutil.copyfile(log, output / 'build.log')
    shutil.copyfile(source / 'debian/copyright', output / 'COPYRIGHT')
    for receipt in tests:
        for suffix in ['.trs', '.log']:
            report = (source / receipt['path']).with_suffix(suffix)
            require(report.is_file(), 'Test log missing')
            shutil.copyfile(report, output / (receipt['test'] + suffix))
    for pattern in ['jq_*.buildinfo', 'jq_*.changes']:
        matches = list(work.glob(pattern))
        require(len(matches) == 1, 'Package build receipt missing/ambiguous')
        shutil.copyfile(matches[0], output / matches[0].name)
    (output / 'builder-packages.tsv').write_text(capture(
        ['dpkg-query', '--show', '--showformat=' + '$' + '{binary:Package}\t' + '$' + '{Version}\n'],
        work, env) + '\n', encoding='utf-8')
    provenance = {'schemaVersion': 1, 'identity': lock['identity'], 'sourceLockSha256': digest(LOCK),
                  'sourceFiles': lock['sourceFiles'], 'upstream': lock['upstream'],
                  'sharedHelpersSha256': digest(HERE.parent / 'build-pcre2-backport.py'),
                  'packagingPreserved': packaging, 'tests': tests, 'packageSmoke': smoke,
                  'runtimePackages': packages, 'runtimeInstalled': False,
                  'removedSeriesEntries': lock['removedUbuntuPatches'],
                  'buildCommand': ['dpkg-buildpackage', '-b', '-us', '-uc', job_arg]}
    (output / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n', encoding='utf-8')
    (output / 'manifest.tsv').write_text('lock-sha256\t' + digest(LOCK) + '\n' + ''.join(
        '\t'.join([p['package'], p['version'], p['architecture'], p['sha256'], p['file']]) + '\n'
        for p in packages), encoding='utf-8')
    (output / 'SHA256SUMS').write_text(''.join(digest(p) + '  ' + p.name + '\n'
        for p in sorted(output.iterdir()) if p.is_file()), encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--validate-lock', action='store_true')
    parser.add_argument('--output-dir', type=Path)
    parser.add_argument('--work-dir', type=Path)
    parser.add_argument('--cache-dir', type=Path)
    parser.add_argument('--jobs', type=int, choices=(2, 4), default=2)
    args = parser.parse_args()
    lock = load_lock()
    if args.validate_lock:
        print('JQ_STABLE_LOCK_OK sha256=' + digest(LOCK))
        return
    require(args.output_dir is not None, '--output-dir is required for native build')
    build(args, lock)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print('JQ_STABLE_FAILED: ' + str(error), file=sys.stderr)
        sys.exit(1)

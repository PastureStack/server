"""Small shared source/deb operations for the p11-kit and libXrender backports.

This imports the already reviewed PCRE2 pure helpers. It does not change any
existing module or perform package installation.
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
import tempfile

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('ubuntu_backport_common', HERE / 'build-pcre2-backport.py')
COMMON = importlib.util.module_from_spec(SPEC)
_bytecode = sys.dont_write_bytecode
sys.dont_write_bytecode = True
try:
    SPEC.loader.exec_module(COMMON)
finally:
    sys.dont_write_bytecode = _bytecode
require, digest, run, capture = COMMON.require, COMMON.digest, COMMON.run, COMMON.capture


def inputs(lock):
    return lock['sourceFiles'] + lock['patches'] + ([lock['baselineBinary']] if 'baselineBinary' in lock else [])


def load_lock(file, package, version, commits):
    lock = json.loads(file.read_text(encoding='utf-8'))
    require(all(lock.get(k) == v for k, v in {
        'schemaVersion': 1, 'sourcePackage': package, 'ubuntuSourceVersion': version,
        'customVersion': version + '+pasturestack.1', 'distribution': 'resolute',
        'osVersion': '26.04', 'architecture': 'amd64'}.items()), 'Wrong backport identity')
    require(type(lock['sourceDateEpoch']) is int and lock['sourceDateEpoch'] > 0, 'Invalid source date')
    require([p['commit'] for p in lock['patches']] == commits, 'Unexpected security commit set/order')
    expected_names = ({'p11-kit_0.26.2-2.dsc', 'p11-kit_0.26.2.orig.tar.xz',
                       'p11-kit_0.26.2.orig.tar.xz.asc', 'p11-kit_0.26.2-2.debian.tar.xz'}
                      if package == 'p11-kit' else
                      {'libxrender_0.9.12-1build1.dsc', 'libxrender_0.9.12.orig.tar.gz',
                       'libxrender_0.9.12.orig.tar.gz.asc', 'libxrender_0.9.12-1build1.diff.gz'})
    require(len(lock['sourceFiles']) == 4 and {p['name'] for p in lock['sourceFiles']} == expected_names,
            'Wrong original Ubuntu source set')
    expected_packages = (['libp11-kit0', 'p11-kit', 'p11-kit-modules'] if package == 'p11-kit'
                         else ['libxrender1'])
    require(lock['runtimePackages'] == expected_packages, 'Unexpected exported package set')
    require(('baselineBinary' in lock) == (package == 'libxrender'), 'Unexpected baseline binary scope')
    if package == 'libxrender':
        require(lock['baselineBinary']['name'] == 'libxrender1_0.9.12-1build1_amd64.deb'
                and lock['baselineBinary']['version'] == version, 'Wrong original Ubuntu ABI baseline')
    pool = 'p/p11-kit' if package == 'p11-kit' else 'libx/libxrender'
    for item in inputs(lock):
        require(re.fullmatch(r'[A-Za-z0-9._~+-]+', item['name'])
                and re.fullmatch(r'[0-9a-f]{64}', item['sha256'])
                and type(item['size']) is int and 0 < item['size'] < 8 * 1024 * 1024,
                'Unpinned/unsafe source')
        if item in lock['sourceFiles'] or item == lock.get('baselineBinary'):
            url = 'https://archive.ubuntu.com/ubuntu/pool/main/' + pool + '/' + item['name']
        else:
            require(item['name'] == item['commit'] + '.patch', 'Patch filename/commit mismatch')
            url = ('https://github.com/p11-glue/p11-kit/commit/' + item['commit'] + '.patch'
                   if package == 'p11-kit' else
                   'https://gitlab.freedesktop.org/xorg/lib/libxrender/-/commit/' +
                   item['commit'] + '.patch')
        require(item['url'] == url, 'Unexpected official source URL')
    require(set(lock['baselineSha256']) == set(lock['patchedSha256']), 'Changed patch boundary')
    for group in ['baselineSha256', 'patchedSha256', 'ubuntuPackagingSha256']:
        for name, sha in lock[group].items():
            require(not Path(name).is_absolute() and '..' not in Path(name).parts
                    and re.fullmatch(r'[0-9a-f]{64}', sha), 'Unsafe/unpinned source path')
    return lock


def verify_hashes(root, values):
    require(all((root / name).is_file() and digest(root / name) == sha
                for name, sha in values.items()), 'Source/packaging bytes changed')


def verify_inputs(lock, directory):
    for item in inputs(lock):
        file = directory / item['name']
        require(file.is_file() and file.stat().st_size == item['size']
                and digest(file) == item['sha256'], 'Input mismatch: ' + item['name'])
    file = next(p for p in lock['sourceFiles'] if p['name'].endswith('.dsc'))
    text = (directory / file['name']).read_text(encoding='utf-8')
    require(all(re.search('^' + re.escape(value) + '$', text, re.M) for value in
                ['Source: ' + lock['sourcePackage'], 'Version: ' + lock['ubuntuSourceVersion']]),
            'Wrong Ubuntu source control identity')
    block = re.search(r'^Checksums-Sha256:\n((?: .+\n)+)', text, re.M)
    require(block, 'Missing .dsc SHA-256 manifest')
    require({n: (h, int(s)) for h, s, n in
             re.findall(r'^ ([0-9a-f]{64}) (\d+) (\S+)$', block[1], re.M)} ==
            {p['name']: (p['sha256'], p['size']) for p in lock['sourceFiles']
             if not p['name'].endswith('.dsc')}, 'Ubuntu .dsc/lock manifest mismatch')
    for patch in lock['patches']:
        text = (directory / patch['name']).read_text(encoding='utf-8')
        require(text.startswith('From ' + patch['commit'] + ' '), 'Wrong upstream patch commit')
        paths = re.findall(r'^diff --git a/(\S+) b/(\S+)$', text, re.M)
        require(paths and all(a == b and a in lock['baselineSha256'] for a, b in paths),
                'Patch changed unapproved source/test paths')


def prepare(lock, directory, work, env, log):
    source = work / 'source'
    dsc = next(p['name'] for p in lock['sourceFiles'] if p['name'].endswith('.dsc'))
    run(['dpkg-source', '--extract', str(directory / dsc), str(source)], work, env, log)
    verify_hashes(source, lock['baselineSha256'])
    verify_hashes(source, lock['ubuntuPackagingSha256'])
    packaging = COMMON.packaging_snapshot(source)
    if lock['sourcePackage'] == 'libxrender':
        shutil.copyfile(source / 'src/Xrender.c', work / 'original-Xrender.c')
    for patch in lock['patches']:
        run(['patch', '-p1', '--fuzz=0', '--batch', '--forward', '--input',
             str(directory / patch['name'])], source, env, log)
    verify_hashes(source, lock['patchedSha256'])
    verify_hashes(source, packaging)
    changelog = source / 'debian/changelog'
    date = email.utils.format_datetime(datetime.datetime.fromtimestamp(
        lock['sourceDateEpoch'], datetime.timezone.utc))
    changelog.write_text(lock['sourcePackage'] + ' (' + lock['customVersion'] +
        ') resolute; urgency=high\n\n'
        '  * First-party PastureStack rebuild; not issued by Canonical.\n'
        '  * Apply exact upstream security commits; preserve Ubuntu packaging.\n\n'
        ' -- PastureStack maintainers <pasturestack@users.noreply.github.com>  ' +
        date + '\n\n' + changelog.read_text(encoding='utf-8'), encoding='utf-8')
    return source, packaging


def extract_packages(lock, source, work, env, log):
    extracted, selected = work / 'extracted', []
    version = lock['customVersion'].split(':')[-1]
    for name in lock['runtimePackages']:
        matches = list(work.glob(name + '_' + version + '_amd64.deb'))
        require(len(matches) == 1, 'Missing/ambiguous runtime package: ' + name)
        file = matches[0]
        for field, value in [('Package', name), ('Version', lock['customVersion']), ('Architecture', 'amd64')]:
            require(capture(['dpkg-deb', '--field', str(file), field], work, env) == value,
                    'Runtime package metadata changed: ' + field)
        identity = capture(['dpkg-deb', '--field', str(file), 'Source'], work, env)
        require(identity in [lock['sourcePackage'], lock['sourcePackage'] + ' (' +
                            lock['customVersion'] + ')'] or
                (name == lock['sourcePackage'] and identity == ''), 'Wrong Source identity')
        run(['dpkg-deb', '--extract', str(file), str(extracted)], work, env, log)
        selected.append({'package': name, 'version': lock['customVersion'], 'architecture': 'amd64',
                         'file': file.name, 'sha256': digest(file)})
    return extracted, selected


def verify_abi(library, soname, symbols_file, work, env):
    require(library.is_file(), 'Missing expected SONAME')
    dynamic = capture(['readelf', '--dynamic', str(library)], work, env)
    headers = capture(['readelf', '--program-headers', str(library)], work, env)
    require('[' + soname + ']' in dynamic and 'GNU_RELRO' in headers and
            ('BIND_NOW' in dynamic or re.search(r'FLAGS_1.*NOW', dynamic)), 'ABI/hardening changed')
    required = re.findall(r'^ ([A-Za-z_][A-Za-z0-9_]*)@\S+ ',
                          symbols_file.read_text(encoding='utf-8'), re.M)
    exports = {line.split()[-1].split('@')[0] for line in
               capture(['nm', '--dynamic', '--defined-only', str(library)], work, env).splitlines()
               if line.split()}
    require(required and set(required) <= exports, 'Original Ubuntu ABI symbol missing')
    return {'soname': soname, 'originalAbiSymbols': len(required), 'RELRO': True, 'BIND_NOW': True}


def build(args, lock, here, verify, extra_tools):
    release = dict(re.findall(r'^(\w+)=["\']?([^"\'\n]+)',
                              Path('/etc/os-release').read_text(encoding='utf-8'), re.M))
    require(release.get('ID') == 'ubuntu' and release.get('VERSION_ID') == '26.04'
            and os.geteuid() != 0, 'Use a non-root isolated Ubuntu 26.04 native builder')
    output = args.output_dir.resolve()
    cache = args.cache_dir.resolve() if args.cache_dir else None
    work = args.work_dir.resolve() if args.work_dir else Path(tempfile.mkdtemp(prefix='official-backport-'))
    COMMON.require_separate_paths(output, work, cache)
    require(not output.exists(), 'Output directory must be new')
    if args.work_dir: work.mkdir(parents=True, exist_ok=False)
    home = work / 'home'
    home.mkdir(mode=0o700)
    jobs, job_arg = (2, '-j2') if args.jobs == 2 else (4, '-j4')
    env = COMMON.build_environment(lock, jobs)
    env.update(HOME=str(home), DEB_BUILD_MAINT_OPTIONS='')
    for tool in ['dpkg-source', 'dpkg-buildpackage', 'dpkg-checkbuilddeps', 'dpkg-deb',
                 'dpkg-query', 'patch', 'make', 'readelf', 'nm'] + extra_tools:
        require(shutil.which(tool, path=env['PATH']), 'Native builder prerequisite missing: ' + tool)
    require(capture(['dpkg', '--print-architecture'], work, env) == 'amd64', 'Native amd64 required')
    print('OFFICIAL_BACKPORT_WORK_DIR=' + str(work), flush=True)
    input_dir = work / 'inputs'
    input_dir.mkdir()
    if cache: cache.mkdir(parents=True, exist_ok=True)
    for item in inputs(lock):
        COMMON.download(item, input_dir, cache)
    verify_inputs(lock, input_dir)
    log = work / 'build.log'
    source, packaging = prepare(lock, input_dir, work, env, log)
    run(['dpkg-checkbuilddeps'], source, env, log)
    run(['dpkg-buildpackage', '-b', '-us', '-uc', job_arg], source, env, log)
    verify_hashes(source, packaging)
    verify_hashes(source, lock['patchedSha256'])
    extracted, packages = extract_packages(lock, source, work, env, log)
    tests, evidence = verify(lock, source, extracted, work, env, log)
    output.mkdir(parents=True)
    for package in packages: shutil.copyfile(work / package['file'], output / package['file'])
    lock_file = here / (lock['sourcePackage'] + '.lock.json')
    for file, name in [(lock_file, lock_file.name), (log, 'build.log'),
                       (source / 'debian/copyright', 'COPYRIGHT')] + evidence:
        shutil.copyfile(file, output / name)
    for pattern in [lock['sourcePackage'] + '_*.buildinfo', lock['sourcePackage'] + '_*.changes']:
        matches = list(work.glob(pattern))
        require(len(matches) == 1, 'Missing/ambiguous native package receipt')
        shutil.copyfile(matches[0], output / matches[0].name)
    (output / 'builder-packages.tsv').write_text(capture(
        ['dpkg-query', '--show', '--showformat=' + '$' + '{binary:Package}\t' + '$' + '{Version}\n'],
        work, env) + '\n', encoding='utf-8')
    provenance = {'schemaVersion': 1, 'identity': lock['identity'], 'sourceLockSha256': digest(lock_file),
                  'sourceFiles': lock['sourceFiles'], 'patches': lock['patches'],
                  'sharedHelpersSha256': digest(Path(__file__)),
                  'pcre2CommonSha256': digest(HERE / 'build-pcre2-backport.py'), 'tests': tests,
                  'packagingPreserved': packaging, 'runtimePackages': packages,
                  'runtimeInstalled': False, 'buildCommand': ['dpkg-buildpackage', '-b', '-us', '-uc', job_arg]}
    (output / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n', encoding='utf-8')
    (output / 'manifest.tsv').write_text('lock-sha256\t' + digest(lock_file) + '\n' + ''.join(
        '\t'.join([p['package'], p['version'], p['architecture'], p['sha256'], p['file']]) + '\n'
        for p in packages), encoding='utf-8')
    (output / 'SHA256SUMS').write_text(''.join(digest(p) + '  ' + p.name + '\n'
        for p in sorted(output.iterdir()) if p.is_file()), encoding='utf-8')


def entry(here, package, version, commits, verify, extra_tools):
    parser = argparse.ArgumentParser(description='Official security backport with preserved Ubuntu packaging')
    parser.add_argument('--validate-lock', action='store_true')
    parser.add_argument('--output-dir', type=Path)
    parser.add_argument('--work-dir', type=Path)
    parser.add_argument('--cache-dir', type=Path)
    parser.add_argument('--jobs', type=int, choices=(2, 4), default=2)
    args = parser.parse_args()
    lock = load_lock(here / (package + '.lock.json'), package, version, commits)
    if args.validate_lock:
        print('OFFICIAL_SOURCE_LOCK_OK ' + package)
        return
    require(args.output_dir is not None, '--output-dir is required')
    build(args, lock, here, verify, extra_tools)

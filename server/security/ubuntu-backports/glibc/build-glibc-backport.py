#!/usr/bin/env python3
"""Build selected first-party glibc debs in a disposable Ubuntu 26.04 amd64 CI builder.

Uses original Ubuntu packaging, native tests and hardening. Never installs debs.
Native compilation is intentionally separate from --validate-lock/--validate-inputs.
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
import urllib.request

HERE = Path(__file__).resolve().parent
LOCK_FILE = HERE / 'glibc.lock.json'
_spec = importlib.util.spec_from_file_location('ubuntu_backport_common', HERE.parent / 'build-pcre2-backport.py')
COMMON = importlib.util.module_from_spec(_spec)
_bytecode = sys.dont_write_bytecode
sys.dont_write_bytecode = True
try:
    _spec.loader.exec_module(COMMON)
finally:
    sys.dont_write_bytecode = _bytecode
require, digest, run, capture = COMMON.require, COMMON.digest, COMMON.run, COMMON.capture
PACKAGES = ['libc6', 'libc-bin', 'libc-gconv-modules-extra']
DEV_PACKAGES = ['libc6-dev', 'libc-dev-bin']
FIX = '72351055c6a1328c1ce2c06b72b8a4e3ebe0ef08'
REGRESSION = '20b3e8717652bdc2f89c99c4cc6e38d56a754866'
SOURCE_PINS = {
    'glibc_2.43-2ubuntu2.4.dsc': ('da10d551ca51076bf7bf663de38369d04e267386b8211c283c2814e68e482ed3', 9078),
    'glibc_2.43.orig.tar.xz': ('d9c86c6b5dbddb43a3e08270c5844fc5177d19442cf5b8df4be7c07cd5fa3831', 20297012),
    'glibc_2.43.orig.tar.xz.asc': ('0a725eb20ceb526abf52d3129f03e0399afa0d97ffa1dd779bed42958ab23326', 1018),
    'glibc_2.43-2ubuntu2.4.debian.tar.xz': ('28103a7cf808c29901c6053d89a4e8299880abfbb850c0d97a09c8df8533e306', 530764)}
PATCH_PINS = {FIX: ('73ca6cb57d78c89785cd2bdd5c15cf7e5fdee873599bb8f1623035a2692915f1', 2175),
              REGRESSION: ('bf4de5ac1937b76fd21ce003c77f5681b899edb8a42326ff3a13bf1ba4ab4ba1', 3183)}
OLD_CALL = "? upstr (ccs, cs + 5) : ccs) != 0)"
NEW_CALL = "if (ccs[2] == '\\0' || __wcsmbs_named_conv (&fcts, ccs) != 0)"
CONTROLS = ['libio/tst-fopen-ccs-empty', 'libio/tst-fopenloc', 'libio/tst-fopenloc2']


def load_lock(file):
    lock = json.loads(file.read_text(encoding='utf-8'))
    expected = {'schemaVersion': 1, 'sourcePackage': 'glibc', 'ubuntuSourceVersion': '2.43-2ubuntu2.4',
                'customVersion': '2.43-2ubuntu2.4+pasturestack.1', 'distribution': 'resolute',
                'osVersion': '26.04', 'architecture': 'amd64', 'buildProfiles': ['nobiarch', 'noudeb'],
                'runtimePackages': PACKAGES, 'optionalDevPackages': DEV_PACKAGES,
                'fixedCves': ['CVE-2026-18374']}
    require(all(lock.get(k) == v for k, v in expected.items()), 'Unsupported glibc lock identity/profiles')
    require(type(lock.get('sourceDateEpoch')) is int and lock['sourceDateEpoch'] > 0,
            'SOURCE_DATE_EPOCH must be a positive integer')
    upstream = lock['upstream']
    require(upstream['repository'] == 'https://sourceware.org/git/glibc.git'
            and upstream['backportBranch'] == 'release/2.43/master'
            and upstream['fixCommit'] == FIX and upstream['regressionCommit'] == REGRESSION,
            'Only the official 2.43 fix and its regression backport are supported')
    sources, patches = lock['sourceFiles'], lock['patches']
    require(len(sources) == 4 and {i['name'] for i in sources} == set(SOURCE_PINS),
            'Exactly the original Ubuntu DSC/tarballs/signature are required')
    require([i['commit'] for i in patches] == [FIX, REGRESSION], 'Unexpected patch set/order/branch')
    for item in sources + patches:
        name = item['name']
        require(Path(name).name == name and '/' not in name and '\\' not in name, 'Unsafe input filename')
        if item in sources:
            pin, size = SOURCE_PINS[name]
            url = 'https://archive.ubuntu.com/ubuntu/pool/main/g/glibc/' + name
        else:
            pin, size = PATCH_PINS[item['commit']]
            require(name == item['commit'] + '.sourceware.patch', 'Unexpected patch filename')
            url = 'https://sourceware.org/git/?p=glibc.git;a=patch;h=' + item['commit']
        require(item['sha256'] == pin and type(item['size']) is int and item['size'] == size,
                'Input differs from approved source SHA-256/length')
        require(item['url'] == url, 'Unexpected official source URL')
    require('First-party' in lock['identity'] and 'not issued by Canonical' in lock['identity'],
            'Custom output must not claim Canonical provenance')
    return lock


def download(item, directory, cache):
    """Reuse common HTTPS/hash checks; glibc's 20MiB input needs its own pinned-size bound."""
    destination = directory / item['name']
    cached = cache / item['name'] if cache else None
    if cached and cached.exists():
        COMMON.verify_input(item, cached)
        shutil.copyfile(cached, destination)
    else:
        opener = urllib.request.build_opener(COMMON.HttpsRedirect())
        with opener.open(item['url'], timeout=60) as response, destination.open('xb') as output:
            require(response.url.startswith('https://'), 'Refusing non-HTTPS input')
            size = 0
            while True:
                chunk = response.read(65536)
                if not chunk:
                    break
                size += len(chunk)
                require(size <= item['size'], 'Input exceeds its pinned size')
                output.write(chunk)
        COMMON.verify_input(item, destination)
        if cached:
            shutil.copyfile(destination, cached)
    COMMON.verify_input(item, destination)
    return destination


def verify_source_control(lock, directory):
    text = (directory / 'glibc_2.43-2ubuntu2.4.dsc').read_text(encoding='utf-8')
    require(all(re.search('^' + re.escape(line) + '$', text, re.M) for line in
                ['Source: glibc', 'Version: 2.43-2ubuntu2.4', 'Format: 3.0 (quilt)']),
            'Unexpected Ubuntu source control')
    block = re.search(r'^Checksums-Sha256:\n((?: .+\n)+)', text, re.M)
    require(block is not None, 'DSC lacks source checksums')
    rows = re.findall(r'^ ([0-9a-f]{64}) (\d+) (\S+)$', block[1], re.M)
    expected = {i['name']: (i['sha256'], i['size']) for i in lock['sourceFiles'] if not i['name'].endswith('.dsc')}
    require(len(rows) == 3 and {name: (sha, int(size)) for sha, size, name in rows} == expected,
            'DSC does not bind exactly the approved original tarball, signature and packaging')


def verify_patch(item, file):
    COMMON.verify_input(item, file)
    text = file.read_text(encoding='utf-8')
    require(text.startswith('From ' + item['commit'] + ' '), 'Patch commit identity mismatch')
    expected = ['libio/fileops.c'] if item['commit'] == FIX else ['libio/Makefile', 'libio/tst-fopen-ccs-empty.c']
    paths = re.findall(r'^diff --git a/(\S+) b/(\S+)$', text, re.M)
    require(paths == [(p, p) for p in expected], 'Patch must stay within its approved upstream paths')
    require(not re.search(r'^(?:old mode|new mode|rename from|rename to|GIT binary patch)', text, re.M),
            'Unexpected patch metadata')


def validate_inputs(lock, directory):
    for item in lock['sourceFiles'] + lock['patches']:
        COMMON.verify_input(item, directory / item['name'])
    verify_source_control(lock, directory)
    for item in lock['patches']:
        verify_patch(item, directory / item['name'])


def build_environment(lock, jobs):
    # Package rules supply their existing flags/CET/symbol policy. Inherited
    # compiler/profile/test overrides cannot weaken those settings.
    env = COMMON.build_environment(lock, jobs)
    env['DEB_BUILD_PROFILES'] = 'nobiarch noudeb'
    return env


def source_closure(source):
    text = (source / 'libio/fileops.c').read_text(encoding='utf-8')
    require(NEW_CALL in text and OLD_CALL not in text, 'Official source closure is absent')
    require('tst-fopen-ccs-empty' in (source / 'libio/Makefile').read_text(encoding='utf-8')
            and (source / 'libio/tst-fopen-ccs-empty.c').is_file(), 'Official regression is not registered')
    return {p: digest(source / p) for p in
            ['libio/fileops.c', 'libio/Makefile', 'libio/tst-fopen-ccs-empty.c']}


def test_receipt(source):
    report = source / 'build-tree/amd64-libc/tests.sum'
    require(report.is_file(), 'Missing full native tests.sum')
    text = report.read_text(encoding='utf-8')
    entries = re.findall(r'^(PASS|FAIL|XFAIL|XPASS|UNSUPPORTED|UNRESOLVED|ERROR): (\S+)$', text, re.M)
    require(entries and len(entries) == len([line for line in text.splitlines() if line.strip()])
            and len({name for _, name in entries}) == len(entries), 'Ambiguous native test results')
    states = dict((name, state) for state, name in entries)
    counts = collections.Counter(state for state, _ in entries)
    require(not any(counts[s] for s in ['FAIL', 'ERROR', 'UNRESOLVED']), 'Unexpected native test failure')
    require(all(states.get(name) == 'PASS' for name in CONTROLS), 'CVE regression/valid charset controls did not PASS')
    for component in ['libio', 'stdio-common', 'iconv', 'wcsmbs', 'malloc', 'elf', 'nptl', 'nss']:
        require(any(state == 'PASS' and name.startswith(component + '/') for state, name in entries),
                'Native component suite did not execute: ' + component)
    require((source / 'stamp-dir/check_libc_passed').is_file()
            and not (source / 'stamp-dir/check_libc_failed').exists(), 'Ubuntu native test gate did not pass')
    require(not (source / 'build-tree/amd64-i386').exists()
            and not (source / 'build-tree/amd64-x32').exists(), 'Unexpected extra ABI build')
    return {'report': 'build-tree/amd64-libc/tests.sum', 'sha256': digest(report), 'counts': dict(counts),
            'controls': {name: states[name] for name in CONTROLS}, 'ubuntuGate': 'check_libc_passed',
            'semantics': 'XFAIL/UNSUPPORTED/XPASS are retained verbatim under unchanged Ubuntu rules; they are not zero failures or universal coverage.'}


def verify_debs(lock, work, source, environment, log, dev_packages):
    selected = []
    extracted = work / 'verify-runtime'
    extracted.mkdir()
    for package in PACKAGES + dev_packages:
        matches = list(work.glob(package + '_' + lock['customVersion'] + '_amd64.deb'))
        require(len(matches) == 1, 'Missing/ambiguous selected deb: ' + package)
        deb = matches[0]
        for field, value in [('Package', package), ('Version', lock['customVersion']), ('Architecture', 'amd64')]:
            require(COMMON.deb_field(deb, field, work, environment) == value, 'Unexpected deb metadata: ' + field)
        require(COMMON.deb_field(deb, 'Source', work, environment) in
                ['glibc', 'glibc (' + lock['customVersion'] + ')'], 'Unexpected deb Source identity')
        run(['dpkg-deb', '--extract', str(deb), str(extracted)], work, environment, log)
        selected.append({'package': package, 'version': lock['customVersion'], 'architecture': 'amd64',
                         'file': deb.name, 'sha256': digest(deb),
                         'role': 'runtime' if package in PACKAGES else 'explicit-consumer-dev-compatibility'})
    libc = extracted / 'usr/lib/x86_64-linux-gnu/libc.so.6'
    require(libc.is_file() and libc.resolve().is_relative_to(extracted.resolve()), 'Candidate libc is absent or escapes extraction')
    dynamic = capture(['readelf', '--dynamic', str(libc)], work, environment)
    headers = capture(['readelf', '--program-headers', str(libc)], work, environment)
    elf = capture(['readelf', '--file-header', str(libc)], work, environment)
    require('ELF64' in elf and 'X86-64' in elf.upper(), 'Candidate libc is not native amd64 ELF64')
    require('[libc.so.6]' in dynamic and 'GNU_RELRO' in headers
            and ('BIND_NOW' in dynamic or re.search(r'FLAGS_1.*NOW', dynamic)), 'libc SONAME/hardening changed')
    symbols = capture(['nm', '--dynamic', '--defined-only', str(libc)], work, environment)
    require(all(re.search(r'\b' + name + r'@@?GLIBC_[0-9.]+$', symbols, re.M)
                for name in ['fopen', 'fopen64', 'malloc', '__libc_start_main']), 'Required versioned libc ABI missing')
    require((extracted / 'usr/sbin/ldconfig').is_file(), 'Selected libc-bin lacks ldconfig')
    require(list((extracted / 'usr/lib/x86_64-linux-gnu/gconv').glob('*.so')), 'Selected gconv-extra has no modules')
    return selected


def build(args, lock):
    os_release = dict(re.findall(r'^(\w+)=["\']?([^"\'\n]+)', Path('/etc/os-release').read_text(encoding='utf-8'), re.M))
    require(os_release.get('ID') == 'ubuntu' and os_release.get('VERSION_ID') == '26.04', 'Use an isolated Ubuntu 26.04 builder')
    environment = build_environment(lock, args.jobs)
    for command in ['dpkg', 'dpkg-source', 'dpkg-buildpackage', 'dpkg-deb', 'dpkg-buildflags', 'dpkg-checkbuilddeps',
                    'dpkg-query', 'quilt', 'readelf', 'nm', 'fakeroot']:
        require(shutil.which(command, path=environment['PATH']), 'Missing builder dependency: ' + command)
    require(capture(['dpkg', '--print-architecture'], HERE, environment) == 'amd64', 'Use a native amd64 builder')
    output = args.output_dir.resolve()
    require(not output.exists(), 'Output directory must be new')
    cache = args.cache_dir.resolve() if args.cache_dir else None
    COMMON.require_separate_paths(output, args.work_dir.resolve() if args.work_dir else None, cache)
    work = args.work_dir.resolve() if args.work_dir else Path(tempfile.mkdtemp(prefix='glibc-ubuntu-backport-'))
    if args.work_dir:
        work.mkdir(parents=True, exist_ok=False)
    print('GLIBC_BACKPORT_WORK_DIR=' + str(work), flush=True)
    inputs = work / 'inputs'
    inputs.mkdir()
    if cache:
        cache.mkdir(parents=True, exist_ok=True)
    for item in lock['sourceFiles'] + lock['patches']:
        download(item, inputs, cache)
    validate_inputs(lock, inputs)
    log = work / 'build.log'
    source = work / 'glibc-source'
    run(['dpkg-source', '--extract', str(inputs / 'glibc_2.43-2ubuntu2.4.dsc'), str(source)], work, environment, log)
    packaging = COMMON.packaging_snapshot(source)
    original_series = (source / 'debian/patches/series').read_text(encoding='utf-8')
    require(OLD_CALL in (source / 'libio/fileops.c').read_text(encoding='utf-8'), 'Original source boundary changed')
    environment['QUILT_PATCHES'] = 'debian/patches'
    for item in lock['patches']:
        run(['quilt', 'import', '-P', item['name'], str(inputs / item['name'])], source, environment, log)
        run(['quilt', 'push', '--fuzz=0'], source, environment, log)
    require(all(digest(source / name) == sha for name, sha in packaging.items()
                if name != 'debian/patches/series'), 'Official backports changed Ubuntu packaging rules')
    series = (source / 'debian/patches/series').read_text(encoding='utf-8')
    require(series.startswith(original_series) and series[len(original_series):].split()
            == [item['name'] for item in lock['patches']], 'Existing quilt series changed or extra patches added')
    source_proof = source_closure(source)
    approved_packaging = COMMON.packaging_snapshot(source)
    changelog = source / 'debian/changelog'
    date = email.utils.format_datetime(datetime.datetime.fromtimestamp(lock['sourceDateEpoch'], datetime.timezone.utc))
    changelog.write_text('glibc (' + lock['customVersion'] + ') resolute; urgency=high\n\n'
                        '  * First-party PastureStack rebuild; not issued by Canonical.\n'
                        '  * Apply official glibc 2.43 CVE-2026-18374 fix and regression test.\n\n'
                        ' -- PastureStack maintainers <pasturestack@users.noreply.github.com>  ' + date + '\n\n'
                        + changelog.read_text(encoding='utf-8'), encoding='utf-8')
    # -G emits custom source provenance plus arch-specific binaries. Original
    # tarballs stay beside the new DSC; no distro-independent docs are built.
    for item in lock['sourceFiles']:
        if '.orig.tar.' in item['name']:
            shutil.copyfile(inputs / item['name'], work / item['name'])
    run(['dpkg-checkbuilddeps', '-B', '-P' + ','.join(lock['buildProfiles'])], source, environment, log)
    command = ['dpkg-buildpackage', '-G', '-us', '-uc', '-P' + ','.join(lock['buildProfiles']), COMMON.job_option(args.jobs)]
    run(command, source, environment, log)
    require(all((source / name).is_file() and digest(source / name) == sha
                for name, sha in approved_packaging.items()), 'Build changed approved Ubuntu packaging inputs')
    require(source_closure(source) == source_proof, 'Built source no longer matches the approved fix')
    tests = test_receipt(source)
    # Return package names from the fixed catalog, never CLI-derived path tokens.
    dev_exports = [package for package in DEV_PACKAGES if package in args.export_dev_package]
    selected = verify_debs(lock, work, source, environment, log, dev_exports)
    output.mkdir(parents=True)
    for item in selected:
        shutil.copyfile(work / item['file'], output / item['file'])
    for pattern in ['glibc_*.buildinfo', 'glibc_*.changes', 'glibc_' + lock['customVersion'] + '.dsc',
                    'glibc_' + lock['customVersion'] + '.debian.tar.*']:
        files = list(work.glob(pattern))
        require(len(files) == 1, 'Missing/ambiguous custom package/source receipt: ' + pattern)
        shutil.copyfile(files[0], output / files[0].name)
    for file, name in [(log, 'build.log'), (LOCK_FILE, 'glibc.lock.json'),
                       (source / 'debian/copyright', 'COPYRIGHT'),
                       (source / tests['report'], 'tests.sum'),
                       (source / 'build-tree/amd64-libc/configparms', 'native-configparms'),
                       (source / 'build-tree/amd64-libc/config.make', 'native-config.make')]:
        shutil.copyfile(file, output / name)
    for name in CONTROLS:
        for suffix in ['.out', '.test-result']:
            report = source / 'build-tree/amd64-libc' / (name + suffix)
            require(report.is_file(), 'Missing native control output: ' + name + suffix)
            shutil.copyfile(report, output / (Path(name).name + suffix))
    (output / 'builder-packages.tsv').write_text(capture(
        ['dpkg-query', '--show', '--showformat=${binary:Package}\t${Version}\n'], work, environment) + '\n', encoding='utf-8')
    provenance = {'schemaVersion': 1, 'identity': lock['identity'], 'sourceLockSha256': digest(LOCK_FILE),
                  'sourceDateEpoch': lock['sourceDateEpoch'], 'sourceFiles': lock['sourceFiles'],
                  'upstream': lock['upstream'], 'patches': lock['patches'], 'fixedCves': lock['fixedCves'],
                  'debianPackagingInputSha256': packaging, 'approvedPackagingSha256': approved_packaging,
                  'sourceClosure': source_proof, 'buildEnvironment': environment, 'buildCommand': command,
                  'dpkgBuildflagsContext': capture(['dpkg-buildflags', '--export=sh'], work, environment),
                  'actualCompilerConfiguration': ['native-configparms', 'native-config.make', 'build.log'],
                  'tests': tests, 'runtimePackages': [i for i in selected if i['role'] == 'runtime'],
                  'compatibilityPackages': [i for i in selected if i['role'] != 'runtime'],
                  'devPackagePolicy': 'Explicitly requested exports only; consumers may install a dev package only if already present. This helper installs no packages.',
                  'scope': 'Native amd64 original Ubuntu packaging; nobiarch/noudeb; full native upstream suite and original expected-failure/ABI/hardening rules.',
                  'signaturePolicy': 'Official input bytes SHA-256 pinned; custom outputs are not issued or signed by Canonical.'}
    (output / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n', encoding='utf-8')
    (output / 'manifest.tsv').write_text('lock-sha256\t' + digest(LOCK_FILE) + '\n' + ''.join(
        '\t'.join([i['package'], i['version'], i['architecture'], i['sha256'], i['file']]) + '\n' for i in selected), encoding='utf-8')
    (output / 'SHA256SUMS').write_text(''.join(digest(f) + '  ' + f.name + '\n' for f in sorted(output.iterdir()) if f.is_file()), encoding='utf-8')
    print('GLIBC_BACKPORT_BUILT packages=' + str(len(selected)) + ' lock=' + digest(LOCK_FILE), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--validate-lock', action='store_true')
    parser.add_argument('--output-dir', type=Path)
    parser.add_argument('--work-dir', type=Path)
    parser.add_argument('--cache-dir', type=Path)
    parser.add_argument('--jobs', type=int, choices=(2, 4), default=2)
    parser.add_argument('--export-dev-package', action='append', choices=DEV_PACKAGES, default=[])
    args = parser.parse_args()
    require(1 <= args.jobs <= 32, 'Build jobs must be between 1 and 32')
    require(len(set(args.export_dev_package)) == len(args.export_dev_package), 'Duplicate dev export')
    lock = load_lock(LOCK_FILE)
    if args.validate_lock:
        print('GLIBC_BACKPORT_LOCK_OK sha256=' + digest(LOCK_FILE))
    else:
        require(args.output_dir is not None, '--output-dir is required for a native build')
        build(args, lock)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as error:
        print('GLIBC_BACKPORT_FAILED: ' + str(error), file=sys.stderr)
        sys.exit(1)

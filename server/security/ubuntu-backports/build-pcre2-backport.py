#!/usr/bin/env python3
"""Build first-party PCRE2 .debs with Ubuntu packaging and pinned upstream fixes.

Run in a disposable Ubuntu 26.04 amd64 builder with the original Build-Depends,
build-essential, fakeroot, patch, binutils, Python 3 and trusted CA certificates.
This helper never installs packages. Only the two selected runtime .debs leave
the build directory; the unchanged Debian rules run all upstream tests first.
"""
import argparse
import datetime
import email.utils
import hashlib
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
PACKAGES = ['libpcre2-8-0', 'libpcre2-posix3']
SOURCE_FILES = {'pcre2_10.46-1build1.dsc', 'pcre2_10.46.orig.tar.gz',
                'pcre2_10.46-1build1.diff.gz'}
TESTS = ['pcre2_jit_test', 'RunTest', 'RunGrepTest']
CVES = ['CVE-2026-103111', 'CVE-2026-86145', 'CVE-2026-89156', 'CVE-2026-89157',
        'CVE-2026-89158', 'CVE-2026-89160', 'CVE-2026-89161', 'CVE-2026-89162']


def require(condition, message):
    if not condition:
        raise ValueError(message)


def digest(file):
    return hashlib.sha256(file.read_bytes()).hexdigest()


def load_lock(file):
    lock = json.loads(file.read_text(encoding='utf-8'))
    expected = {'schemaVersion': 1, 'sourcePackage': 'pcre2',
                'ubuntuSourceVersion': '10.46-1build1',
                'customVersion': '10.46-1build1+pasturestack.1',
                'distribution': 'resolute', 'osVersion': '26.04',
                'architecture': 'amd64', 'runtimePackages': PACKAGES, 'fixedCves': CVES}
    require(all(lock.get(key) == value for key, value in expected.items()),
            'Unsupported PCRE2 lock identity')
    require(type(lock.get('sourceDateEpoch')) is int and lock['sourceDateEpoch'] > 0,
            'SOURCE_DATE_EPOCH must be a positive integer')
    sources, patches = lock['sourceFiles'], lock['patches']
    require(len(sources) == 3 and {item['name'] for item in sources} == SOURCE_FILES,
            'Exactly the Ubuntu .dsc, original tarball and Debian diff are required')
    require(len(patches) == 12 and len({item['name'] for item in patches}) == 12
            and len({item['commit'] for item in patches}) == 12,
            'Exactly twelve distinct approved backports are required')
    upstream = lock['upstream']
    require(upstream['baseTag'] == 'pcre2-10.46'
            and upstream['baseCommit'] == 'b2bd4254b379b9d7dc9a3dda060a7e27009ccdff'
            and upstream['backportBranch'] == 'release/pcre2-10.46'
            and upstream['backportCommit'] == '947809f11e9c9744aa0974b4b630a1ae461733dd'
            and patches[-1]['commit'] == upstream['backportCommit'],
            'Unexpected upstream release/backport boundary')
    for item in sources + patches:
        require(Path(item['name']).name == item['name'] and '/' not in item['name']
                and '\\' not in item['name'], 'Unsafe input filename')
        require(re.fullmatch('[0-9a-f]{64}', item['sha256']) is not None,
                'Every source and patch needs a SHA-256 pin')
        require(type(item['size']) is int and 0 < item['size'] < 8 * 1024 * 1024,
                'Invalid input size')
        if item in sources:
            expected_url = 'https://archive.ubuntu.com/ubuntu/pool/main/p/pcre2/' + item['name']
        else:
            require(re.fullmatch('[0-9a-f]{40}', item['commit']) is not None,
                    'Every patch needs a complete commit pin')
            expected_url = 'https://github.com/PCRE2Project/pcre2/commit/' + item['commit'] + '.patch'
        require(item['url'] == expected_url, 'Unexpected source or patch URL')
    require(upstream['lifecycleUrl'] == 'https://raw.githubusercontent.com/PCRE2Project/pcre2/'
            'pcre2-10.49/SUPPORT-LIFECYCLE.md'
            and re.fullmatch('[0-9a-f]{64}', upstream['lifecycleSha256']) is not None,
            'The official supported-backport list must be pinned')
    return lock


class HttpsRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, file, code, message, headers, new_url):
        require(new_url.startswith('https://'), 'Refusing HTTPS downgrade')
        return super().redirect_request(request, file, code, message, headers, new_url)


def verify_input(item, file):
    require(file.is_file() and digest(file) == item['sha256'],
            'SHA-256 mismatch: ' + item['name'])
    if 'size' in item:
        require(file.stat().st_size == item['size'], 'Size mismatch: ' + item['name'])


def download(item, directory, cache):
    destination = directory / item['name']
    cached = cache / item['name'] if cache else None
    if cached and cached.exists():
        # A poisoned cache fails closed instead of silently fetching other bytes.
        verify_input(item, cached)
        shutil.copyfile(cached, destination)
    else:
        opener = urllib.request.build_opener(HttpsRedirect())
        with opener.open(item['url'], timeout=60) as response, destination.open('xb') as output:
            require(response.url.startswith('https://'), 'Refusing non-HTTPS input')
            size = 0
            while True:
                chunk = response.read(65536)
                if not chunk:
                    break
                size += len(chunk)
                require(size < 8 * 1024 * 1024, 'Input exceeds download limit')
                output.write(chunk)
        verify_input(item, destination)
        if cached:
            shutil.copyfile(destination, cached)
    verify_input(item, destination)
    return destination


def verify_source_control(lock, directory):
    text = (directory / 'pcre2_10.46-1build1.dsc').read_text(encoding='utf-8')
    require(re.search(r'^Source: pcre2$', text, re.M)
            and re.search(r'^Version: 10\.46-1build1$', text, re.M)
            and re.search(r'^Format: 1\.0$', text, re.M), 'Unexpected Ubuntu source control')
    block = re.search(r'^Checksums-Sha256:\n((?: .+\n)+)', text, re.M)
    require(block is not None, 'Source control has no SHA-256 manifest')
    actual = {name: (sha, int(size)) for sha, size, name in
              re.findall(r'^ ([0-9a-f]{64}) (\d+) (\S+)$', block[1], re.M)}
    expected = {item['name']: (item['sha256'], item['size']) for item in lock['sourceFiles']
                if not item['name'].endswith('.dsc')}
    require(actual == expected, '.dsc source manifest does not match the lock')


def verify_supported_patches(lock, lifecycle):
    section = re.search(r'(?s)### PCRE2 10\.46 .*?(?=### PCRE2)', lifecycle)
    require(section is not None, 'Official lifecycle has no PCRE2 10.46 section')
    names = re.findall(r'`patches/([^`]+)`', section[0])
    require(names == [item['name'] for item in lock['patches']],
            'Patch set/order differs from the official supported 10.46 backports')


def verify_patch(item, file):
    text = file.read_text(encoding='utf-8')
    require(text.startswith('From ' + item['commit'] + ' '), 'Patch commit identity mismatch')
    paths = re.findall(r'^diff --git a/(\S+) b/(\S+)$', text, re.M)
    require(paths and all(left == right and left.startswith(('src/', 'testdata/'))
                          and '..' not in Path(left).parts for left, right in paths),
            'Approved patches may only change upstream source and regression tests')


def build_environment(lock, jobs):
    # Inherited DEB_BUILD_OPTIONS, compiler overrides or build profiles must not
    # suppress tests, hardening, widths or JIT. No runtime APT is performed here.
    return {'PATH': '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
            'HOME': os.environ.get('HOME', '/tmp'), 'LANG': 'C.UTF-8', 'LC_ALL': 'C.UTF-8',
            'TZ': 'UTC', 'SOURCE_DATE_EPOCH': str(lock['sourceDateEpoch']),
            'DEB_BUILD_OPTIONS': 'parallel=' + str(jobs),
            'DEB_BUILD_MAINT_OPTIONS': 'hardening=+all', 'DEB_BUILD_PROFILES': '',
            'DPKG_COLORS': 'never'}


def run(command, directory, environment, log):
    with log.open('ab') as stream:
        stream.write(('\n$ ' + json.dumps(command) + '\n').encode())
        stream.flush()
        process = subprocess.Popen(command, cwd=directory, env=environment,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        for line in process.stdout:
            stream.write(line)
            stream.flush()
            sys.stdout.buffer.write(line)
            sys.stdout.buffer.flush()
        require(process.wait() == 0, 'Command failed; see ' + str(log))


def capture(command, directory, environment):
    return subprocess.check_output(command, cwd=directory, env=environment,
                                   text=True, encoding='utf-8').strip()


def packaging_snapshot(source):
    return {file.relative_to(source).as_posix(): digest(file)
            for file in sorted((source / 'debian').rglob('*'))
            if file.is_file() and file.name != 'changelog'}


def test_receipt(source):
    results = []
    for name in TESTS:
        reports = list(source.rglob(name + '.trs'))
        require(len(reports) == 1, 'Missing or ambiguous native test result: ' + name)
        result = reports[0].read_text(encoding='utf-8')
        require(re.search(r'^:test-result: PASS$', result, re.M) is not None,
                'Native test did not PASS: ' + name)
        results.append({'test': name, 'status': 'PASS',
                        'path': reports[0].relative_to(source).as_posix(),
                        'sha256': digest(reports[0])})
    return results


def deb_field(file, field, directory, environment):
    return capture(['dpkg-deb', '--field', str(file), field], directory, environment)


def require_separate_paths(output, work, cache):
    for directory in [work, cache]:
        if directory:
            require(output != directory and output not in directory.parents
                    and directory not in output.parents,
                    'Output must be separate from build/cache directories')


def verify_debs(lock, work, source, environment, log):
    selected = []
    extracted = work / 'verify-runtime'
    extracted.mkdir()
    for package, soname in zip(PACKAGES, ['libpcre2-8.so.0', 'libpcre2-posix.so.3']):
        matches = list(work.glob(package + '_' + lock['customVersion'] + '_amd64.deb'))
        require(len(matches) == 1, 'Missing or ambiguous runtime .deb: ' + package)
        deb = matches[0]
        for field, expected in [('Package', package), ('Version', lock['customVersion']),
                                ('Architecture', 'amd64')]:
            require(deb_field(deb, field, work, environment) == expected,
                    'Unexpected .deb metadata: ' + field)
        source_identity = deb_field(deb, 'Source', work, environment)
        require(source_identity in ('pcre2', 'pcre2 (' + lock['customVersion'] + ')'),
                'Unexpected .deb Source identity')
        run(['dpkg-deb', '--extract', str(deb), str(extracted)], work, environment, log)
        library = extracted / 'usr/lib/x86_64-linux-gnu' / soname
        require(library.is_file(), 'Expected runtime SONAME is absent: ' + soname)
        dynamic = capture(['readelf', '--dynamic', str(library)], work, environment)
        headers = capture(['readelf', '--program-headers', str(library)], work, environment)
        require('[' + soname + ']' in dynamic, 'Runtime SONAME changed')
        require('BIND_NOW' in dynamic or re.search(r'FLAGS_1.*NOW', dynamic),
                'Runtime library lacks immediate binding hardening')
        require('GNU_RELRO' in headers, 'Runtime library lacks RELRO hardening')
        copyright_file = extracted / 'usr/share/doc' / package / 'copyright'
        require(copyright_file.is_file() and digest(copyright_file) == digest(source / 'debian/copyright'),
                'Original copyright must remain in each runtime package')
        selected.append({'package': package, 'version': lock['customVersion'],
                         'architecture': 'amd64', 'file': deb.name, 'sha256': digest(deb),
                         'soname': soname, 'hardening': ['RELRO', 'BIND_NOW']})
    symbols = capture(['nm', '--dynamic', '--defined-only',
                       str(extracted / 'usr/lib/x86_64-linux-gnu/libpcre2-posix.so.3')], work, environment)
    require(all(re.search(r'\bpcre2_' + name + r'(?:@@?\S+)?$', symbols, re.M)
                for name in ['regcomp', 'regexec', 'regfree', 'regerror']),
            'Ubuntu POSIX wrapper ABI is missing')
    return selected


def build(args, lock):
    os_release = dict(re.findall(r'^(\w+)=["\']?([^"\'\n]+)',
                                Path('/etc/os-release').read_text(encoding='utf-8'), re.M))
    require(os_release.get('ID') == 'ubuntu' and os_release.get('VERSION_ID') == '26.04',
            'Use an isolated Ubuntu 26.04 builder')
    environment = build_environment(lock, args.jobs)
    for command in ['dpkg', 'dpkg-source', 'dpkg-buildpackage', 'dpkg-deb',
                    'dpkg-buildflags', 'dpkg-checkbuilddeps', 'dpkg-query', 'patch', 'readelf', 'nm', 'fakeroot']:
        require(shutil.which(command, path=environment['PATH']), 'Builder dependency missing: ' + command)
    require(capture(['dpkg', '--print-architecture'], HERE, environment) == 'amd64',
            'Use an amd64 builder')
    output = args.output_dir.resolve()
    require(not output.exists(), 'Output directory must be new')
    cache = args.cache_dir.resolve() if args.cache_dir else None
    require_separate_paths(output, args.work_dir.resolve() if args.work_dir else None, cache)
    if args.work_dir:
        work = args.work_dir.resolve()
        work.mkdir(parents=True, exist_ok=False)
    else:
        work = Path(tempfile.mkdtemp(prefix='pcre2-ubuntu-backport-'))
    print('PCRE2_BACKPORT_WORK_DIR=' + str(work), flush=True)
    inputs = work / 'inputs'
    inputs.mkdir()
    if cache:
        cache.mkdir(parents=True, exist_ok=True)
    for item in lock['sourceFiles'] + lock['patches']:
        download(item, inputs, cache)
    lifecycle = {'name': 'pcre2-10.49-SUPPORT-LIFECYCLE.md',
                 'url': lock['upstream']['lifecycleUrl'],
                 'sha256': lock['upstream']['lifecycleSha256']}
    lifecycle_file = download(lifecycle, inputs, cache)
    verify_supported_patches(lock, lifecycle_file.read_text(encoding='utf-8'))
    verify_source_control(lock, inputs)
    log = work / 'build.log'
    source = work / 'pcre2-source'
    run(['dpkg-source', '--extract', str(inputs / 'pcre2_10.46-1build1.dsc'), str(source)],
        work, environment, log)
    packaging = packaging_snapshot(source)
    for item in lock['patches']:
        patch = inputs / item['name']
        verify_input(item, patch)
        verify_patch(item, patch)
        run(['patch', '-p1', '--fuzz=0', '--batch', '--forward', '--input', str(patch)],
            source, environment, log)
    require(packaging_snapshot(source) == packaging, 'Upstream patches changed Debian packaging')
    changelog = source / 'debian/changelog'
    date = email.utils.format_datetime(datetime.datetime.fromtimestamp(
        lock['sourceDateEpoch'], datetime.timezone.utc))
    entry = ('pcre2 (' + lock['customVersion'] + ') resolute; urgency=high\n\n'
             '  * First-party PastureStack rebuild; not issued by Canonical.\n'
             '  * Apply all twelve approved upstream 10.46 backports through\n'
             '    947809f11e9c9744aa0974b4b630a1ae461733dd, with regression tests.\n\n'
             ' -- PastureStack maintainers <pasturestack@users.noreply.github.com>  ' + date + '\n\n')
    changelog.write_text(entry + changelog.read_text(encoding='utf-8'), encoding='utf-8')
    run(['dpkg-checkbuilddeps'], source, environment, log)
    run(['dpkg-buildpackage', '-b', '-us', '-uc', '-j' + str(args.jobs)], source, environment, log)
    require({name: digest(source / name) for name in packaging} == packaging,
            'Build changed Debian packaging inputs')
    tests = test_receipt(source)
    selected = verify_debs(lock, work, source, environment, log)
    output.mkdir(parents=True)
    for item in selected:
        shutil.copyfile(work / item['file'], output / item['file'])
    shutil.copyfile(log, output / 'build.log')
    shutil.copyfile(args.lock, output / 'pcre2.lock.json')
    shutil.copyfile(lifecycle_file, output / lifecycle['name'])
    shutil.copyfile(source / 'debian/copyright', output / 'COPYRIGHT')
    for result in tests:
        report = source / result['path']
        shutil.copyfile(report, output / (result['test'] + '.trs'))
        test_log = report.with_suffix('.log')
        require(test_log.is_file(), 'Native test output is missing')
        shutil.copyfile(test_log, output / (result['test'] + '.log'))
    for pattern in ['pcre2_*.buildinfo', 'pcre2_*.changes']:
        files = list(work.glob(pattern))
        require(len(files) == 1, 'Native package build receipt is absent or ambiguous')
        shutil.copyfile(files[0], output / files[0].name)
    (output / 'builder-packages.tsv').write_text(capture(
        ['dpkg-query', '--show', '--showformat=${binary:Package}\t${Version}\n'],
        work, environment) + '\n', encoding='utf-8')
    provenance = {'schemaVersion': 1, 'identity': lock['identity'], 'sourceLockSha256': digest(args.lock),
                  'sourceDateEpoch': lock['sourceDateEpoch'], 'sourceFiles': lock['sourceFiles'],
                  'upstream': lock['upstream'], 'patches': lock['patches'], 'fixedCves': lock['fixedCves'],
                  'debianPackagingInputSha256': packaging, 'buildEnvironment': environment,
                  'buildCommand': ['dpkg-buildpackage', '-b', '-us', '-uc', '-j' + str(args.jobs)],
                  'tests': tests, 'runtimePackages': selected,
                  'scope': 'Ubuntu packaging built all configured widths/JIT; only two runtime .debs exported',
                  'signaturePolicy': 'Source bytes are SHA-256 pinned from official Ubuntu HTTPS; no Canonical signing claim for custom outputs.'}
    (output / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n', encoding='utf-8')
    (output / 'manifest.tsv').write_text('lock-sha256\t' + digest(args.lock) + '\n' + ''.join(
        '\t'.join([item['package'], item['version'], item['architecture'], item['sha256'], item['file']]) + '\n'
        for item in selected), encoding='utf-8')
    (output / 'SHA256SUMS').write_text(''.join(digest(file) + '  ' + file.name + '\n'
        for file in sorted(output.iterdir()) if file.is_file()), encoding='utf-8')
    print('PCRE2_BACKPORT_BUILT packages=2 tests=3 lock=' + digest(args.lock), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lock', type=Path, default=HERE / 'pcre2.lock.json')
    parser.add_argument('--validate-lock', action='store_true')
    parser.add_argument('--output-dir', type=Path)
    parser.add_argument('--work-dir', type=Path)
    parser.add_argument('--cache-dir', type=Path)
    parser.add_argument('--jobs', type=int, default=2)
    args = parser.parse_args()
    require(1 <= args.jobs <= 32, 'Build jobs must be between 1 and 32')
    lock = load_lock(args.lock)
    if args.validate_lock:
        print('PCRE2_BACKPORT_LOCK_OK sha256=' + digest(args.lock))
        return
    require(args.output_dir is not None, '--output-dir is required for a native build')
    build(args, lock)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print('PCRE2_BACKPORT_FAILED: ' + str(error), file=sys.stderr)
        sys.exit(1)

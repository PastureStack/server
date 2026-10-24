#!/usr/bin/env python3
"""Build a first-party rust-coreutils security backport in Ubuntu 26.04 amd64.

Uses the unchanged Ubuntu 0.10 packaging and vendored crates; backports only the
official id fix. No runtime package installation or alternatives changes occur.
The original non-gating test recipe is supplemented by a strict, unfiltered
owning-suite run and real/effective-GID tests of the extracted package.
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
LOCK_FILE = HERE / 'rust-coreutils.lock.json'
VERSION = '0.10.0-1ubuntu2~26.04.1'
COMMIT = 'ff382f527994b8a021ec0a086dec4c5cafa34f2a'
PATHS = ['src/uu/id/src/id.rs', 'tests/by-util/test_id.rs']


def require(condition, message):
    if not condition:
        raise ValueError(message)


def job_option(jobs):
    if jobs == 2:
        return '-j2'
    if jobs == 4:
        return '-j4'
    raise ValueError('Build jobs must be 2 or 4')


def digest(file):
    sha = hashlib.sha256()
    with file.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            sha.update(chunk)
    return sha.hexdigest()


def load_lock(file):
    lock = json.loads(file.read_text(encoding='utf-8'))
    expected = {'schemaVersion': 1, 'sourcePackage': 'rust-coreutils',
                'ubuntuSourceVersion': VERSION, 'customVersion': VERSION + '+pasturestack.1',
                'distribution': 'resolute', 'osVersion': '26.04', 'architecture': 'amd64',
                'runtimePackages': ['rust-coreutils']}
    require(all(lock.get(k) == v for k, v in expected.items()), 'Unsupported lock identity')
    require(type(lock['sourceDateEpoch']) is int and lock['sourceDateEpoch'] > 0,
            'Invalid source date')
    names = {'rust-coreutils_' + VERSION + '.dsc',
             'rust-coreutils_0.10.0.orig.tar.gz', 'rust-coreutils_0.10.0.orig-l10n.tar.gz',
             'rust-coreutils_' + VERSION + '.debian.tar.xz'}
    require(len(lock['sourceFiles']) == 4 and
            {x['name'] for x in lock['sourceFiles']} == names, 'Wrong Ubuntu source set')
    require(len(lock['patches']) == 1 and lock['patches'][0]['commit'] == COMMIT
            and lock['patches'][0]['paths'] == PATHS
            and lock['patches'][0]['fixedCves'] == ['CVE-2026-35370', 'CVE-2026-35371'],
            'Only the approved two-CVE patch is supported')
    for item in lock['sourceFiles'] + lock['patches']:
        require(re.fullmatch(r'[A-Za-z0-9._~+-]+', item['name']), 'Unsafe input name')
        require(re.fullmatch(r'[0-9a-f]{64}', item['sha256'])
                and type(item['size']) is int and 0 < item['size'] < 32 * 1024 * 1024,
                'Invalid SHA-256/size')
        expected_url = ('https://archive.ubuntu.com/ubuntu/pool/main/r/rust-coreutils/' +
                        item['name'] if item in lock['sourceFiles'] else
                        'https://github.com/uutils/coreutils/commit/' + COMMIT + '.patch')
        require(item['url'] == expected_url, 'Unexpected download URL')
    require(len(lock['alreadyPresentFixes']) == 18 and
            len({x['id'] for x in lock['alreadyPresentFixes']}) == 18 and
            all(x['status'] == 'already_in_original_ubuntu_source'
                and x['sourcePath'] in lock['baselineSha256']
                for x in lock['alreadyPresentFixes']), 'Wrong already-present fix inventory')
    require(set(lock['patchedSha256']) == set(PATHS), 'Unexpected patched paths')
    for name, sha in {**lock['baselineSha256'], **lock['patchedSha256']}.items():
        require(not Path(name).is_absolute() and '..' not in Path(name).parts
                and re.fullmatch(r'[0-9a-f]{64}', sha), 'Invalid source digest entry')
    return lock


class HttpsRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, file, code, message, headers, new_url):
        require(new_url.startswith('https://'), 'Refusing HTTPS downgrade')
        return super().redirect_request(request, file, code, message, headers, new_url)


def verify_input(item, file):
    require(file.is_file() and file.stat().st_size == item['size']
            and digest(file) == item['sha256'], 'Source identity mismatch: ' + item['name'])


def download(item, inputs, cache):
    file = inputs / item['name']
    cached = cache / item['name'] if cache else None
    if cached and cached.exists():
        verify_input(item, cached)  # A poisoned cache fails closed.
        shutil.copyfile(cached, file)
    else:
        with urllib.request.build_opener(HttpsRedirect()).open(item['url'], timeout=60) as response:
            require(response.url.startswith('https://'), 'Refusing non-HTTPS input')
            with file.open('xb') as output:
                size = 0
                for chunk in iter(lambda: response.read(65536), b''):
                    size += len(chunk)
                    require(size <= item['size'], 'Download exceeds pinned size')
                    output.write(chunk)
        verify_input(item, file)
        if cached:
            shutil.copyfile(file, cached)
    verify_input(item, file)


def verify_source_control(lock, inputs):
    text = (inputs / ('rust-coreutils_' + VERSION + '.dsc')).read_text(encoding='utf-8')
    require(all(re.search('^' + re.escape(line) + '$', text, re.M) for line in
                ['Format: 3.0 (quilt)', 'Source: rust-coreutils', 'Version: ' + VERSION]),
            'Unexpected Ubuntu source control')
    block = re.search(r'^Checksums-Sha256:\n((?: .+\n)+)', text, re.M)
    require(block, 'No source SHA-256 manifest')
    actual = {name: (sha, int(size)) for sha, size, name in
              re.findall(r'^ ([0-9a-f]{64}) (\d+) (\S+)$', block[1], re.M)}
    require(actual == {x['name']: (x['sha256'], x['size']) for x in lock['sourceFiles']
                       if not x['name'].endswith('.dsc')}, '.dsc/lock mismatch')


def verify_patch(item, file):
    text = file.read_text(encoding='utf-8')
    require(text.startswith('From ' + COMMIT + ' '), 'Patch commit identity mismatch')
    paths = re.findall(r'^diff --git a/(\S+) b/(\S+)$', text, re.M)
    require(paths == [(p, p) for p in PATHS], 'Patch changed unapproved paths')


def verify_sources(source, expected):
    require(all((source / name).is_file() and digest(source / name) == sha
                for name, sha in expected.items()), 'Unexpected source/packaging bytes')


def build_environment(lock, jobs, home):
    # Do not inherit test suppressors, Cargo profiles, compiler flags or registries.
    return {'PATH': '/usr/sbin:/usr/bin:/sbin:/bin', 'HOME': str(home),
            'LANG': 'C.UTF-8', 'LC_ALL': 'C.UTF-8', 'TZ': 'UTC', 'TERM': 'dumb',
            'SOURCE_DATE_EPOCH': str(lock['sourceDateEpoch']),
            'DEB_BUILD_OPTIONS': 'parallel=' + str(jobs), 'DEB_BUILD_PROFILES': '',
            'DEB_BUILD_MAINT_OPTIONS': '', 'DPKG_COLORS': 'never',
            'CARGO_NET_OFFLINE': 'true', 'CARGO_TERM_COLOR': 'never',
            'CARGO_BUILD_JOBS': str(jobs)}


def capture(command, work, env):
    return subprocess.check_output(command, cwd=work, env=env,
                                   text=True, encoding='utf-8').strip()


def run(command, work, env, log):
    print('Running: ' + json.dumps(command), flush=True)
    with log.open('ab') as output:
        output.write(('\n$ ' + json.dumps(command) + '\n').encode())
        output.flush()
        result = subprocess.run(command, cwd=work, env=env,
                                stdout=output, stderr=subprocess.STDOUT)
    require(result.returncode == 0, 'Command failed; retained log: ' + str(log))


def packaging_snapshot(source):
    # Original packaging applies its own vendor quilt patches during configure.
    return {p.relative_to(source).as_posix(): digest(p)
            for p in sorted((source / 'debian').rglob('*'))
            if p.is_file() and p.name != 'changelog'
            and 'rust-vendor' not in p.relative_to(source / 'debian').parts}


def strict_test_receipt(log):
    text = log.read_text(encoding='utf-8', errors='replace')
    results = re.findall(r'test result: ok\. (\d+) passed; (\d+) failed; (\d+) ignored;', text)
    require(results and all(int(failed) == 0 for _, failed, _ in results)
            and sum(int(passed) for passed, _, _ in results) > 0
            and re.search(r'test (?:test_id::)?test_id_groups_ordering \.\.\. ok', text),
            'Missing strict owning-suite/id regression PASS receipt')
    require('test result: FAILED' not in text, 'Owning test failure in log')
    return {'status': 'PASS', 'addedSkips': 0, 'cargoResults': [
        {'passed': int(p), 'failed': int(f), 'upstreamIgnored': int(i)} for p, f, i in results],
        'officialIdRegression': 'PASS', 'sha256': digest(log)}


def credential_prefix(env, work):
    prefix = [] if os.geteuid() == 0 else ['sudo', '-n', '--']
    command = prefix + ['/usr/bin/setpriv', '--reuid=65534', '--rgid=65534',
                        '--egid=1', '--groups=2', '/usr/bin/python3', '-c',
                        'import os; print(os.getuid(),os.getgid(),os.getegid(),os.getgroups())']
    require(capture(command, work, env) == '65534 65534 1 [2]',
            'Isolated QA needs SETUID/SETGID privileges; no persistent user/group edits')
    probe = prefix + ['/usr/bin/setpriv', '--reuid=65534', '--rgid=65534', '--egid=1',
                      '--groups=2', '/usr/bin/python3', '-c',
                      'import os,sys; sys.exit(0 if os.access(sys.argv[1], os.X_OK) else 1)',
                      str(work)]
    capture(probe, work, env)
    return prefix


def verify_id(binary, prefix, env, work):
    require(binary.is_file(), 'Packaged id entry point missing')
    # The directory must be traversable by this bounded unprivileged child.
    cases = [(65534, 1, [2]), (1, 65534, [1, 2, 65534]), (65534, 65534, [2])]
    receipts = []
    for real, effective, supplementary in cases:
        command = prefix + ['/usr/bin/setpriv', '--reuid=65534', '--rgid=' + str(real),
                            '--egid=' + str(effective),
                            '--groups=' + ','.join(map(str, supplementary)), str(binary)]
        expected = list(dict.fromkeys([real, effective] + sorted(supplementary)))
        outputs = {flag: capture(command + flag.split(), work, env)
                   for flag in ['-G', '-G -r', '-g', '-g -r', '']}
        require(all(list(map(int, outputs[flag].split())) == expected
                    for flag in ['-G', '-G -r']), 'Incorrect real/effective/supplementary GID order')
        require(outputs['-g'] == str(effective) and outputs['-g -r'] == str(real),
                'Single-GID semantics regressed')
        match = re.search(r' groups=([^\s]+)', outputs[''])
        actual = [int(x.split('(')[0]) for x in match[1].split(',')] if match else []
        require(actual == list(dict.fromkeys([effective] + sorted(supplementary))),
                'Default groups ordering changed')
        receipts.append({'realGid': real, 'effectiveGid': effective,
                         'supplementaryGids': supplementary, 'outputs': outputs, 'status': 'PASS'})
    return receipts


def build(args, lock):
    release = dict(re.findall(r'^(\w+)=["\']?([^"\'\n]+)',
                              Path('/etc/os-release').read_text(encoding='utf-8'), re.M))
    require(release.get('ID') == 'ubuntu' and release.get('VERSION_ID') == '26.04',
            'Use a disposable Ubuntu 26.04 amd64 builder')
    require(os.geteuid() != 0,
            'Build and full owning suite must run as non-root; grant sudo -n for bounded credential QA')
    output = args.output_dir.resolve()
    cache = args.cache_dir.resolve() if args.cache_dir else None
    work = args.work_dir.resolve() if args.work_dir else Path(tempfile.mkdtemp(prefix='rust-backport-'))
    require(not output.exists(), 'Output directory must be new')
    for other in [work, cache]:
        require(not other or (output != other and output not in other.parents
                             and other not in output.parents), 'Output overlaps build/cache directory')
    if args.work_dir:
        work.mkdir(parents=True, exist_ok=False)
    work.chmod(0o755)  # Public source/binaries only; needed for the isolated UID fixture.
    print('RUST_COREUTILS_BACKPORT_WORK_DIR=' + str(work), flush=True)
    home = work / 'home'
    home.mkdir(mode=0o700)
    env = build_environment(lock, args.jobs, home)
    for tool in ['dpkg', 'dpkg-source', 'dpkg-buildpackage', 'dpkg-deb', 'dpkg-query',
                 'dpkg-checkbuilddeps', 'fakeroot', 'make', 'cargo', 'rustc', 'patch', 'readelf', 'setpriv']:
        require(shutil.which(tool, path=env['PATH']), 'Builder dependency missing: ' + tool)
    require(capture(['dpkg', '--print-architecture'], work, env) == 'amd64', 'Native amd64 required')
    rust = capture(['rustc', '--version'], work, env)
    require(tuple(map(int, re.search(r'rustc (\d+)\.(\d+)\.(\d+)', rust).groups())) >= (1, 88, 0),
            'Upstream MSRV is Rust 1.88')
    prefix = credential_prefix(env, work)  # Fail before expensive compilation.
    inputs = work / 'inputs'
    inputs.mkdir()
    if cache:
        cache.mkdir(parents=True, exist_ok=True)
    for item in lock['sourceFiles'] + lock['patches']:
        download(item, inputs, cache)
    verify_source_control(lock, inputs)
    source, log = work / 'source', work / 'build.log'
    run(['dpkg-source', '--extract', str(inputs / ('rust-coreutils_' + VERSION + '.dsc')),
         str(source)], work, env, log)
    verify_sources(source, lock['baselineSha256'])
    packaging = packaging_snapshot(source)
    item = lock['patches'][0]
    patch = inputs / item['name']
    verify_patch(item, patch)
    run(['patch', '-p1', '--fuzz=0', '--batch', '--forward', '--input', str(patch)], source, env, log)
    verify_sources(source, lock['patchedSha256'])
    verify_sources(source, packaging)
    changelog = source / 'debian/changelog'
    date = email.utils.format_datetime(datetime.datetime.fromtimestamp(
        lock['sourceDateEpoch'], datetime.timezone.utc))
    changelog.write_text('rust-coreutils (' + lock['customVersion'] + ') resolute; urgency=high\n\n'
                        '  * First-party PastureStack rebuild; not issued by Canonical.\n'
                        '  * Backport upstream ff382f527994b8a021ec0a086dec4c5cafa34f2a\n'
                        '    for CVE-2026-35370 and CVE-2026-35371; preserve Ubuntu packaging.\n\n'
                        ' -- PastureStack maintainers <pasturestack@users.noreply.github.com>  ' +
                        date + '\n\n' + changelog.read_text(encoding='utf-8'), encoding='utf-8')
    run(['dpkg-checkbuilddeps'], source, env, log)
    run(['dpkg-buildpackage', '-b', '-us', '-uc', job_option(args.jobs)], source, env, log)
    strict_log = work / 'strict-tests.log'
    run(['make', '-f', str(HERE / 'native-tests.mk'), 'pasturestack-strict-test'],
        source, env, strict_log)
    tests = strict_test_receipt(strict_log)
    verify_sources(source, packaging)
    verify_sources(source, lock['patchedSha256'])
    debs = list(work.glob('rust-coreutils_' + lock['customVersion'] + '_amd64.deb'))
    require(len(debs) == 1, 'Missing/ambiguous runtime package')
    deb = debs[0]
    for field, expected in [('Package', 'rust-coreutils'), ('Version', lock['customVersion']),
                            ('Architecture', 'amd64')]:
        require(capture(['dpkg-deb', '--field', str(deb), field], work, env) == expected,
                'Wrong package ' + field)
    require(capture(['dpkg-deb', '--field', str(deb), 'Source'], work, env) in
            ['', 'rust-coreutils', 'rust-coreutils (' + lock['customVersion'] + ')'], 'Wrong Source identity')
    extracted = work / 'extracted'
    run(['dpkg-deb', '--extract', str(deb), str(extracted)], work, env, log)
    binary = extracted / 'usr/lib/cargo/bin/coreutils/id'
    credentials = verify_id(binary, prefix, env, work)
    require(capture([str(binary), '--version'], work, env).startswith('id (uutils coreutils) 0.10.0'),
            'Unexpected upstream binary version')
    copyright_file = extracted / 'usr/share/doc/rust-coreutils/copyright'
    require(copyright_file.is_file() and digest(copyright_file) == digest(source / 'debian/copyright'),
            'Original copyright changed')
    headers = capture(['readelf', '--program-headers', str(binary)], work, env)
    dynamic = capture(['readelf', '--dynamic', str(binary)], work, env)
    require('GNU_RELRO' in headers and ('BIND_NOW' in dynamic or re.search(r'FLAGS_1.*NOW', dynamic)),
            'Package binary lacks RELRO/immediate-binding hardening')
    output.mkdir(parents=True)
    for file in [deb, log, strict_log, source / 'debian/copyright']:
        shutil.copyfile(file, output / file.name)
    shutil.copyfile(LOCK_FILE, output / 'rust-coreutils.lock.json')
    for pattern in ['rust-coreutils_*.buildinfo', 'rust-coreutils_*.changes']:
        matches = list(work.glob(pattern))
        require(len(matches) == 1, 'Missing/ambiguous package receipt: ' + pattern)
        shutil.copyfile(matches[0], output / matches[0].name)
    (output / 'builder-packages.tsv').write_text(capture(
        ['dpkg-query', '--show', '--showformat=${binary:Package}\t${Version}\n'], work, env) + '\n',
        encoding='utf-8')
    receipt = {'schemaVersion': 1, 'status': 'native_build_and_required_tests_passed',
               'builtAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
               'identity': 'first-party rebuild; not issued by Canonical',
               'lockSha256': digest(LOCK_FILE), 'package': deb.name, 'packageSha256': digest(deb),
               'rustc': rust, 'strictOwningSuite': tests, 'distinctCredentialBinaryTests': credentials,
               'alreadyPresentFixes': lock['alreadyPresentFixes'],
               'newlyBackportedCves': item['fixedCves'], 'packagingPreserved': packaging,
               'runtimeInstalled': False, 'alternativesChanged': False}
    (output / 'provenance.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
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
    try:
        lock = load_lock(LOCK_FILE)
        require(1 <= args.jobs <= 64, 'Invalid job count')
        if args.validate_lock:
            print('Rust-coreutils source/patch lock: PASS')
            return
        require(args.output_dir is not None, '--output-dir is required')
        build(args, lock)
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        parser.exit(1, str(error) + '\n')


if __name__ == '__main__':
    main()

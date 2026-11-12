#!/usr/bin/env python3
"""Source/mock guards only: no downloads, package installs or image builds."""
import copy
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import tempfile


REPO = Path(__file__).resolve().parents[1]
VERSION = '3.2.1ubuntu0.1'
PACKAGES = {
    'apt': ('0de729b8fe0e1c67c04e8e8d5bd6e0420dbd47f75b93f0b71c8e740edc2d5ffc', 1506688),
    'libapt-pkg7.0': ('94e5d41303265b66af0f8c70ade18bfb77260ad286edee6c8045faddef82b94c', 1139022),
}


def shell_path(path):
    text = Path(path).resolve().as_posix()
    return '/' + text[0].lower() + text[2:] if re.match(r'^[A-Za-z]:/', text) else text


def source_guards():
    source = (REPO / 'server/Dockerfile.web-compose-release').read_text(encoding='utf-8')
    lock = json.loads((REPO / 'server/security/official-apt.lock.json').read_bytes())
    assert lock['version'] == VERSION and lock['architecture'] == 'amd64'
    assert lock['distribution'] == 'ubuntu-26.04' and lock['cve'] == 'CVE-2026-109518'
    assert lock['notice'] == 'https://ubuntu.com/security/notices/USN-8996-1'
    assert len(lock['packages']) == 2 and {row['package'] for row in lock['packages']} == set(PACKAGES)
    stage = source.split('FROM ${UBUNTU_SECURITY_IMAGE} AS runtime_security_packages', 1)[1]
    stage, final = stage.split('FROM ${BASE_IMAGE}', 1)
    assert source.count('ARG APT_PACKAGE_VERSION=' + VERSION) == 2
    for row in lock['packages']:
        package = row['package']
        digest, size = PACKAGES[package]
        url = 'https://security.ubuntu.com/ubuntu/pool/main/a/apt/' + package + '_' + VERSION + '_amd64.deb'
        assert (row['archiveSha256'], row['archiveBytes'], row['archiveUrl']) == (digest, size, url)
        assert (row['version'], row['architecture']) == (VERSION, 'amd64')
        assert 'ADD --checksum=sha256:' + digest in stage and url in stage
        assert stage.count(digest) == 3 and str(size) in stage
    assert stage.index('dpkg -i /tmp/libapt-pkg7.0.deb /tmp/apt.deb') < stage.index('    sh /usr/local/libexec/pasturestack/download-ubuntu-security-updates.sh')
    assert stage.index('sha256sum -c -') < stage.index('dpkg-deb -f') < stage.index('dpkg -i /tmp/')
    assert 'cp "/tmp/${package}.deb" "/out/packages/${package}_${APT_PACKAGE_VERSION}_amd64.deb"' in stage
    assert 'official-apt/*' in stage and 'COPY --from=runtime_security_packages /out/' in final
    assert 'install -D -m 0644 official-apt/lock.json' in final
    assert 'apt-official/runtime-packages.tsv' in final
    assert final.index('sha256sum -c SHA256SUMS') < final.index('dpkg -i packages/*.deb')
    builder = stage.split('RUN set -eux; \\\n', 1)[1].split('    mkdir -p /tmp/ca-bootstrap', 1)[0]
    runtime = final.split('    sha256sum -c SHA256SUMS;', 1)[1]
    runtime = 'sha256sum -c SHA256SUMS;' + runtime.split('    install -D -m 0644 official-apt/lock.json', 1)[0]
    bodies = {'builder': builder, 'runtime': runtime}
    for name, body in bodies.items():
        assert body.index('dpkg-deb -f') < body.index('dpkg -i '), name
        for marker in ("-f='${db:Status-Status}'", "-f='${Architecture}'", 'dpkg --compare-versions',
                       ' le "${APT_PACKAGE_VERSION}"', 'Package)', 'Version)', 'Architecture)',
                       'test "$ID:$VERSION_ID" = ubuntu:26.04', 'dpkg --print-architecture',
                       'apt_configuration_before=', '= "$apt_configuration_before"'):
            assert marker in body, (name, marker)
        assert body.count('dpkg -i ') == 1 and '--force' not in body
        bodies[name] = 'set -eu\n' + body.replace('\\\n', '\n')
    return bodies


STUBS = {
    'dpkg-query': '''for item do package=$item; done
test "$MISSING" != "$package" || exit 1
case "$*" in
 *db:Status-Status*) printf installed;;
 *Architecture*) if test "$BAD_INSTALLED_ARCH" = "$package"; then printf arm64; else printf amd64; fi;;
 *Version*) if test -e "$STATE"; then printf '%s' "$POST_VERSION"; else printf '%s' "$OLD_VERSION"; fi;;
 *) exit 2;;
esac
''',
    'dpkg-deb': '''case "$2" in *libapt-pkg7.0*) package=libapt-pkg7.0;; *apt*) package=apt;; *) exit 2;; esac
case "$3" in
 Package) if test "$BAD_PACKAGE" = "$package"; then printf unrelated; else printf '%s' "$package"; fi;;
 Version) if test "$BAD_VERSION" = "$package"; then printf 3.2.0; else printf 3.2.1ubuntu0.1; fi;;
 Architecture) if test "$BAD_ARCH" = "$package"; then printf arm64; else printf amd64; fi;;
 *) exit 2;;
esac
''',
    'dpkg': '''case "$1" in
 --print-architecture) printf amd64;;
 --compare-versions) test "$3" = le; test "$4" = 3.2.1ubuntu0.1; test "$2" != 3.3.0;;
 -i) printf '%s\\n' "$*" >> "$CALLS"; : > "$STATE"; if test "$CONFIG_DRIFT" = yes; then printf changed > "$CONFIG/settings"; fi;;
 *) exit 2;;
esac
''',
    'install': 'exit 0\n',  # The runtime fragment's existing tar install is never performed.
}
SHA_HELPER = '''import hashlib, re, sys
from pathlib import Path
def path(s):
 if re.match(r'^/[A-Za-z]/', s): s=s[1]+':'+s[2:]
 return Path(s)
if sys.argv[1:2]==['-c']:
 rows=sys.stdin if sys.argv[2]=='-' else path(sys.argv[2]).read_text().splitlines()
 ok=True
 for row in rows:
  digest, filename=row.rstrip('\\n').split('  ',1)
  ok=(hashlib.sha256(path(filename).read_bytes()).hexdigest()==digest) and ok
 sys.exit(0 if ok else 1)
for filename in sys.argv[1:]:
 print(hashlib.sha256(path(filename).read_bytes()).hexdigest()+'  '+filename)
'''
CASES = [
    ('existing-pair', {}, True, 1), ('checksum', {}, False, 0), ('size', {}, False, 0),
    ('missing-package', {'MISSING': 'libapt-pkg7.0'}, False, 0),
    ('installed-architecture', {'BAD_INSTALLED_ARCH': 'libapt-pkg7.0'}, False, 0),
    ('package', {'BAD_PACKAGE': 'libapt-pkg7.0'}, False, 0),
    ('version', {'BAD_VERSION': 'libapt-pkg7.0'}, False, 0),
    ('architecture', {'BAD_ARCH': 'libapt-pkg7.0'}, False, 0),
    ('no-downgrade', {'OLD_VERSION': '3.3.0'}, False, 0),
    ('post-version', {'POST_VERSION': '3.2.0'}, False, 1),
    ('configuration', {'CONFIG_DRIFT': 'yes'}, False, 1), ('distribution', {}, False, 0),
]


def run(shell):
    bodies = source_guards()
    with tempfile.TemporaryDirectory(prefix='official-apt-source-') as temporary:
        root = Path(temporary)
        binaries = root / 'bin'
        binaries.mkdir()
        helper = root / 'sha-helper.py'
        helper.write_text(SHA_HELPER, encoding='utf-8', newline='\n')
        scripts = dict(STUBS, sha256sum='exec ' + shlex.quote(shell_path(sys.executable)) + ' ' +
                       shlex.quote(shell_path(helper)) + ' "$@"\n')
        for name, body in scripts.items():
            stub = binaries / name
            stub.write_text('#!/bin/sh\nset -eu\n' + body, encoding='utf-8', newline='\n')
            stub.chmod(0o755)
        for name, changes, accepted, calls in CASES:
            for phase, original in bodies.items():
                case = root / (name + '-' + phase)
                case.mkdir()
                config = case / 'config'
                config.mkdir()
                (config / 'settings').write_text('unchanged')
                release = case / 'os-release'
                release.write_text('ID=' + ('debian' if name == 'distribution' else 'ubuntu') + '\nVERSION_ID=26.04\n')
                packages = case / 'packages'
                packages.mkdir()
                body = original.replace('/tmp/', shell_path(packages) + '/')
                body = body.replace('/etc/os-release', shell_path(release)).replace('/etc/apt', shell_path(config))
                sums = []
                for package, (digest, size) in PACKAGES.items():
                    payload = ('fixture-' + package).encode()
                    fixture_sha = hashlib.sha256(payload).hexdigest()
                    body = body.replace(digest, fixture_sha).replace(str(size), str(len(payload)))
                    filename = package + ('_' + VERSION + '_amd64' if phase == 'runtime' else '') + '.deb'
                    (packages / filename).write_bytes(payload + (b'x' if name == 'size' and phase == 'runtime' and package == 'apt' else b''))
                    sums.append(fixture_sha + '  packages/' + filename)
                if name == 'checksum':
                    body = body.replace(fixture_sha, '0' * 64)
                    sums = [line.replace(fixture_sha, '0' * 64) for line in sums]
                if name == 'size' and phase == 'builder':
                    body = body.replace('-eq 11;', '-eq 12;', 1)
                (case / 'SHA256SUMS').write_text('\n'.join(sums) + '\n')
                script = case / 'run.sh'
                script.write_text(body + '\nprintf approved > approved\n', encoding='utf-8', newline='\n')
                env = dict(os.environ, **dict.fromkeys(('MISSING', 'BAD_INSTALLED_ARCH', 'BAD_PACKAGE', 'BAD_VERSION', 'BAD_ARCH', 'CONFIG_DRIFT'), ''))
                env.update(APT_PACKAGE_VERSION=VERSION, OLD_VERSION='3.2.0', POST_VERSION=VERSION,
                           STATE=shell_path(case / 'installed'), CALLS=shell_path(case / 'calls'), CONFIG=shell_path(config))
                env.update(changes)
                path = ':'.join((shell_path(binaries), shell_path(Path(shell).parent), '/usr/bin', '/bin'))
                command = 'export PATH=' + shlex.quote(path) + '; exec ' + shlex.quote(shell_path(shell)) + ' ' + shlex.quote(shell_path(script))
                result = subprocess.run([shell, '-c', command], cwd=case, env=env, capture_output=True, timeout=15)
                count = len((case / 'calls').read_text().splitlines()) if (case / 'calls').exists() else 0
                assert (result.returncode == 0) == accepted, (name, phase, result.returncode, result.stderr.decode(errors='replace')[:800])
                assert count == calls and (case / 'approved').exists() == accepted, (name, phase, count)
    print('PASS: 12 APT source/mock controls, both stages; no package installation or image build')


def run_vex():
    gate = (REPO / 'scripts/check-server-api-explorer-patch.sh').read_text(encoding='utf-8')
    expressions = re.findall(r"jq -e '(\n.*?)\n' \"\$runtime_vex\" >/dev/null", gate, re.S)
    assert len(expressions) == 1, 'Expected the single actual production VEX predicate'
    document = json.loads((REPO / 'server/security/openvex.json').read_bytes())
    assert len(document['statements']) == 58
    indices = [i for i, row in enumerate(document['statements']) if row['vulnerability']['name'] == 'CVE-2026-109518']
    assert len(indices) == 1
    index = indices[0]
    statement = document['statements'][index]
    assert statement['status'] == 'fixed' and 'justification' not in statement
    expected = {'pkg:deb/ubuntu/' + package + '@' + VERSION + '?arch=amd64&distro=ubuntu-26.04' for package in PACKAGES}
    assert len(statement['products']) == 2 and {row['@id'] for row in statement['products']} == expected
    cases = [('actual-official-fixed-pair', document, True)]

    def change(name, mutate, accepted=False):
        candidate = copy.deepcopy(document)
        mutate(candidate['statements'][index], candidate)
        cases.append((name, candidate, accepted))

    change('equivalent-qualifier-order', lambda row, _: [item.update({'@id': item['@id'].replace('?arch=amd64&distro=ubuntu-26.04', '?distro=ubuntu-26.04&arch=amd64')}) for item in row['products']], True)
    change('not-affected', lambda row, _: row.update(status='not_affected', justification='vulnerable_code_not_present'))
    change('under-investigation', lambda row, _: row.update(status='under_investigation'))
    change('fixed-with-justification', lambda row, _: row.update(justification='vulnerable_code_not_present'))
    for package in range(2):
        change('old-version-' + str(package), lambda row, _, p=package: row['products'][p].update({'@id': row['products'][p]['@id'].replace('@' + VERSION, '@3.2.0')}))
    for name, old, new in [('package', '/apt@', '/unrelated@'), ('distro', 'ubuntu-26.04', 'ubuntu-24.04'),
                           ('architecture', 'arch=amd64', 'arch=arm64'), ('wildcard', '@' + VERSION, '@*')]:
        change(name, lambda row, _, a=old, b=new: row['products'][0].update({'@id': row['products'][0]['@id'].replace(a, b)}))
    change('missing-package', lambda row, _: row['products'].pop())
    change('duplicate-package', lambda row, _: row['products'].__setitem__(1, copy.deepcopy(row['products'][0])))
    change('unknown-cve', lambda row, _: row['vulnerability'].update(name='CVE-2026-99999999'))
    change('extra-unknown-cve', lambda row, doc: doc['statements'].append(dict(copy.deepcopy(row), vulnerability={'name': 'CVE-2026-99999999'})))
    for marker in ('https://ubuntu.com/security/notices/USN-8996-1', VERSION, *(row[0] for row in PACKAGES.values())):
        change('missing-evidence-' + marker[-8:], lambda row, _, value=marker: row.update(impact_statement=row['impact_statement'].replace(value, 'REMOVED')))
    jq = shutil.which('jq')
    assert jq, 'jq required for the actual production predicate; no skip/fallback'
    for name, candidate, accepted in cases:
        result = subprocess.run([jq, '-e', expressions[0]], input=json.dumps(candidate), text=True, capture_output=True, timeout=5)
        assert 'jq: error:' not in result.stderr, (name, result.stderr[:800])
        assert (result.returncode == 0) == accepted, (name, result.returncode)
    print('PASS: ' + str(len(cases)) + ' APT VEX controls through the actual production jq predicate')


if __name__ == '__main__':
    assert len(sys.argv) == 1, 'Command-line overrides are not accepted'
    shell = shutil.which('sh')
    assert shell and Path(shell).is_file(), 'POSIX shell required; no skip/fallback'
    run(shell)
    run_vex()

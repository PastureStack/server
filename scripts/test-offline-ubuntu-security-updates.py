"""Bounded fixtures for the signed-download / network-free runtime boundary."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
INSTALL = ROOT / 'server/scripts/install-ubuntu-security-updates.sh'
DOWNLOAD = ROOT / 'server/scripts/download-ubuntu-security-updates.sh'
RECIPE = ROOT / 'server/Dockerfile.web-compose-release'
REAL_DPKG = shutil.which('dpkg')
REAL_DEB = shutil.which('dpkg-deb')

FAKE = r'''
import hashlib, json, os, pathlib, shutil, subprocess, sys
args=sys.argv[1:]; name=pathlib.Path(sys.argv[0]).name
state_path=pathlib.Path(os.environ['FIXTURE_STATE'])
state=json.loads(state_path.read_text())
if name == 'dpkg-query':
    if len(args) == 2:
        for package, item in sorted(state.items()):
            print(package+'\t'+item['status'])
    else:
        item=state.get(args[-1])
        if item is None: sys.exit(1)
        print(item['version'] if '${Version}' in args[1] else item['status'], end='')
elif name == 'dpkg':
    if args[0] != '--install':
        sys.exit(subprocess.call([os.environ['REAL_DPKG']]+args))
    selected=[]
    for file in args[1:]:
        package=subprocess.check_output([os.environ['REAL_DEB'],'-f',file,'Package'],text=True).strip()
        version=subprocess.check_output([os.environ['REAL_DEB'],'-f',file,'Version'],text=True).strip()
        state[package]={'version':version,'status':'installed'}; selected.append(package)
    changed=os.environ.get('FIXTURE_CHANGE_SET')
    if changed == 'add': state['unexpected']={'version':'1','status':'installed'}
    if changed == 'remove': state.pop('b')
    if changed == 'status': state['b']['status']='unpacked'
    state_path.write_text(json.dumps(state))
    pathlib.Path(os.environ['FIXTURE_TRANSACTION']).write_text(json.dumps(selected))
elif name == 'apt-get':
    if not os.environ.get('FIXTURE_DOWNLOAD'): raise SystemExit('Unexpected runtime network/APT use')
    required=('Acquire::https::Verify-Peer=true','Acquire::https::Verify-Host=true',
              'Acquire::AllowInsecureRepositories=false','APT::Get::AllowUnauthenticated=false')
    if not all(option in args for option in required): raise SystemExit('Missing secure APT options')
    if 'update' in args: sys.exit(0)
    package=args[-1].split('=')[0]
    source=pathlib.Path(os.environ['FIXTURE_DEBS'])/(package+'.deb')
    digest=hashlib.sha256(source.read_bytes()).hexdigest()
    if os.environ.get('FIXTURE_BAD_HASH'): digest='0'*64
    if '--print-uris' in args:
        origin='https://snapshot.ubuntu.com/ubuntu/20261023T000000Z/'
        if os.environ.get('FIXTURE_BAD_URI'): origin='http://untrusted.invalid/'
        kind='SHA256'
        if 'Acquire::ForceHash=sha256' not in args:
            kind='MD5Sum'; digest='0'*32
        print("'"+origin+'pool/'+package+".deb' "+package+'.deb '+str(source.stat().st_size)+' '+kind+':'+digest)
    else: shutil.copyfile(source,pathlib.Path.cwd()/(package+'.deb'))
'''


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


class OfflineSecurityUpdates(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='server-offline-security-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.bin = self.root / 'bin'; self.bin.mkdir()
        self.bundle = self.root / 'bundle'; self.bundle.mkdir()
        self.lock = self.root / 'security.lock'
        self.lock.write_text('# Fixture exact pins\na=2.0\nb=2.0\nc=2.0\n')
        self.state = self.root / 'state.json'
        self.initial = {'a': {'version': '1.0', 'status': 'installed'},
                        'b': {'version': '3.0', 'status': 'installed'}}
        self.state.write_text(json.dumps(self.initial))
        self.transaction = self.root / 'transaction.json'
        for package in ('a', 'b', 'c'):
            tree = self.root / ('deb-' + package)
            (tree / 'DEBIAN').mkdir(parents=True)
            (tree / 'DEBIAN/control').write_text(
                f'Package: {package}\nVersion: 2.0\nArchitecture: amd64\n'
                'Maintainer: Fixture <fixture@example.invalid>\nDescription: isolated fixture\n')
            subprocess.run([REAL_DEB, '--build', str(tree), str(self.bundle / (package + '.deb'))],
                           check=True, capture_output=True)
        self.manifest = self.bundle / 'manifest.tsv'
        self.manifest.write_text('lock-sha256\t' + sha(self.lock) + '\n' + ''.join(
            f'{package}\t2.0\tamd64\t{sha(self.bundle / (package + ".deb"))}\t{package}.deb\n'
            for package in ('a', 'b', 'c')))
        # Only the OS-release fixture is substituted. Native Ubuntu validation is
        # separately exercised with the unchanged helpers in an isolated image.
        os_release = self.root / 'os-release'; os_release.write_text('ID=ubuntu\nVERSION_ID=26.04\n')
        self.helpers = {}
        for source in (INSTALL, DOWNLOAD):
            text = source.read_text()
            self.assertEqual(text.count('. /etc/os-release'), 1)
            target = self.root / source.name
            target.write_text(text.replace('. /etc/os-release', '. "$FIXTURE_OS_RELEASE"'))
            self.helpers[source] = target
        # A deliberately bounded PATH has no gpgv, curl, wget, or real apt-get.
        for command in ('sha256sum', 'cut', 'grep', 'mktemp', 'mkdir', 'rm', 'sort', 'uniq',
                        'cmp', 'find', 'awk', 'wc', 'mv', 'tar', 'dpkg-deb'):
            (self.bin / command).symlink_to(shutil.which(command))
        for command in ('dpkg', 'dpkg-query', 'apt-get'):
            target = self.bin / command
            target.write_text('#!' + sys.executable + '\n' + FAKE)
            target.chmod(0o755)
        self.env = dict(os.environ, PATH=str(self.bin), FIXTURE_OS_RELEASE=str(os_release),
                        FIXTURE_STATE=str(self.state), FIXTURE_TRANSACTION=str(self.transaction),
                        FIXTURE_DEBS=str(self.bundle), REAL_DPKG=REAL_DPKG, REAL_DEB=REAL_DEB)

    def install(self, **extra):
        return subprocess.run(['/bin/sh', str(self.helpers[INSTALL]), str(self.lock), str(self.bundle)],
                              env=dict(self.env, **extra), text=True, capture_output=True)

    def rejected_before_transaction(self):
        result = self.install()
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(self.transaction.exists())
        self.assertEqual(json.loads(self.state.read_text()), self.initial)

    def test_missing_gpgv_final_upgrades_only_installed_older_package(self):
        self.assertNotEqual(0, subprocess.run(['/bin/sh', '-c', 'command -v gpgv'],
                                            env=self.env, capture_output=True).returncode)
        result = self.install()
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        self.assertEqual(['a'], json.loads(self.transaction.read_text()))
        state = json.loads(self.state.read_text())
        self.assertEqual('2.0', state['a']['version'])
        self.assertEqual('3.0', state['b']['version'])
        self.assertNotIn('c', state)

    def test_equal_or_newer_packages_do_not_create_transaction(self):
        state = dict(self.initial, a={'version': '2.0', 'status': 'installed'})
        self.state.write_text(json.dumps(state))
        result = self.install()
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        self.assertFalse(self.transaction.exists())
        self.assertEqual(state, json.loads(self.state.read_text()))

    def test_tampered_deb_including_an_uninstalled_package_is_rejected(self):
        with (self.bundle / 'c.deb').open('ab') as stream: stream.write(b'tampered')
        self.rejected_before_transaction()

    def test_tampered_lock_is_rejected(self):
        self.lock.write_text(self.lock.read_text() + '# Different lock bytes\n')
        self.rejected_before_transaction()

    def test_tampered_manifest_lock_hash_is_rejected(self):
        self.manifest.write_text(self.manifest.read_text().replace(sha(self.lock), '0' * 64))
        self.rejected_before_transaction()

    def test_manifest_header_kind_cannot_bypass_set_e(self):
        self.manifest.write_text(self.manifest.read_text().replace('lock-sha256\t', 'wrong-header\t'))
        self.rejected_before_transaction()

    def test_tampered_deb_hash_is_rejected(self):
        self.manifest.write_text(self.manifest.read_text().replace(sha(self.bundle / 'a.deb'), '0' * 64))
        self.rejected_before_transaction()

    def test_metadata_mismatch_cannot_be_fixed_by_rehashing(self):
        old_hash = sha(self.bundle / 'b.deb')
        shutil.copyfile(self.bundle / 'a.deb', self.bundle / 'b.deb')
        self.manifest.write_text(self.manifest.read_text().replace(old_hash, sha(self.bundle / 'b.deb')))
        self.rejected_before_transaction()

    def test_missing_duplicate_extra_or_foreign_architecture_are_rejected(self):
        original = self.manifest.read_text()
        for mutation in (original.rsplit('\n', 2)[0] + '\n',
                         original + original.splitlines()[1] + '\n',
                         original.replace('\tamd64\t', '\tarm64\t')):
            with self.subTest(mutation=mutation):
                self.manifest.write_text(mutation)
                self.rejected_before_transaction()
        self.manifest.write_text(original)
        shutil.copyfile(self.bundle / 'a.deb', self.bundle / 'extra.deb')
        self.rejected_before_transaction()

    def test_any_package_set_or_status_change_fails(self):
        for change in ('add', 'remove', 'status'):
            with self.subTest(change=change):
                self.state.write_text(json.dumps(self.initial))
                result = self.install(FIXTURE_CHANGE_SET=change)
                self.assertNotEqual(0, result.returncode, result.stdout + result.stderr)
                self.assertNotIn('UBUNTU_SECURITY_MICRO_UPDATES_OK', result.stdout)

    def download(self, **extra):
        trusted = self.root / 'trusted.pem'; trusted.write_text('fixture CA')
        output = self.root / 'downloaded'
        return subprocess.run(['/bin/sh', str(self.helpers[DOWNLOAD]), str(self.lock), str(trusted), str(output)],
                              env=dict(self.env, FIXTURE_DOWNLOAD='1', **extra), text=True, capture_output=True)

    def test_downloader_checks_signed_index_hashes_and_binds_lock(self):
        result = self.download()
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        self.assertEqual(self.manifest.read_text(), (self.root / 'downloaded/manifest.tsv').read_text())

    def test_downloader_rejects_bad_index_hash(self):
        self.assertNotEqual(0, self.download(FIXTURE_BAD_HASH='1').returncode)

    def test_default_apt_print_uri_md5_is_not_accepted_as_sha256(self):
        helper = self.helpers[DOWNLOAD]
        helper.write_text(helper.read_text().replace('-o Acquire::ForceHash=sha256', ''))
        result = self.download()
        self.assertNotEqual(0, result.returncode)
        self.assertIn('did not provide exactly one SHA256', result.stderr)

    def test_downloader_rejects_non_snapshot_or_plain_http_uri(self):
        self.assertNotEqual(0, self.download(FIXTURE_BAD_URI='1').returncode)

    def test_production_wiring_and_ldd_guards_are_fail_closed(self):
        recipe = RECIPE.read_text().replace('\\\n', ' ')
        builder, final = recipe.split('FROM ${UBUNTU_SECURITY_IMAGE} AS runtime_security_packages', 1)[1].split('FROM ${BASE_IMAGE}', 1)
        self.assertIn('download-ubuntu-security-updates.sh', builder)
        self.assertNotIn('download-ubuntu-security-updates.sh', final)
        self.assertIn('/tmp/pasturestack-runtime-security/security-updates', final)
        self.assertNotIn('apt-get', INSTALL.read_text())
        for library in ('libpng', 'freetype'):
            marker = 'if printf \'%s\\n\' "${' + library + '_linkage}"'
            self.assertEqual(recipe.count(marker), 1)
            block = recipe[recipe.index(marker):].split('fi;', 1)[0] + 'fi;'
            for output, success in (('libc.so => /lib/libc.so', True),
                                    ('libc.so => not found', False), ('undefined symbol: png_error', False)):
                with self.subTest(library=library, output=output):
                    result = subprocess.run(['/bin/sh', '-ec', block + ' printf AFTER_GUARD'],
                                            env=dict(self.env, **{library + '_linkage': output}), capture_output=True)
                    self.assertEqual(result.returncode == 0, success)
                    self.assertEqual(b'AFTER_GUARD' in result.stdout, success)


if __name__ == '__main__':
    unittest.main(verbosity=2)

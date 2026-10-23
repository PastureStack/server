"""Focused archive rejection tests; the build validates the real producer bytes."""
import io
import os
import pathlib
import re
import subprocess
import tarfile
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / 'server/artifacts/verify-machine-driver-bundle.sh'
MEMBERS = ['docker-machine', 'docker-machine-driver-packet'] + [
    'machine-driver-bundle-' + name for name in (
        'DEPENDENCY-LICENSES.txt', 'LICENSES.txt', 'PROVIDER-LIFECYCLE.json',
        'SECURITY-VEX.json', 'SOURCES.txt', 'THIRD-PARTY-NOTICES.txt')]


class ArchiveRejectionTests(unittest.TestCase):
    def reject(self, extra=None, link=None, omit=None, before_extraction=True):
        with tempfile.TemporaryDirectory(prefix='pst-machine-') as directory:
            base = pathlib.Path(directory)
            archive = base / 'candidate.tar.xz'
            with tarfile.open(archive, 'w:xz') as tar:
                for name in MEMBERS + ([extra] if extra else []):
                    if name == omit:
                        continue
                    info = tarfile.TarInfo(name)
                    data = b'not the authenticated producer binary'
                    if name == link:
                        info.type = tarfile.SYMTYPE
                        info.linkname = '/etc/passwd'
                        tar.addfile(info)
                    else:
                        info.size = len(data)
                        tar.addfile(info, io.BytesIO(data))
            result = subprocess.run(['bash', str(SCRIPT), '0.16.5', 'f' * 40,
                                     str(archive), '0' * 64, '0' * 64,
                                     str(base / 'machine-driver-bundle')],
                                    text=True, capture_output=True, check=False)
            self.assertNotEqual(result.returncode, 0)
            if before_extraction:
                # A later checksum failure cannot stand in for archive safety.
                # Removing either member/type guard must fail this assertion.
                self.assertFalse((base / 'machine-driver-bundle').exists(),
                                 'Malformed archives must fail before creating the extraction directory')
            self.assertFalse((base / 'machine-driver-bundle/licenses/SERVER-PRODUCER-SOURCES.txt').exists())

    def test_wrong_binary_hash(self):
        self.reject(before_extraction=False)

    def test_duplicate_member(self):
        self.reject(extra='docker-machine')

    def test_path_traversal(self):
        self.reject(extra='../outside')

    def test_symlink(self):
        self.reject(link='docker-machine')

    def test_unlisted_payload(self):
        self.reject(extra='unreviewed-driver')

    def test_missing_legal_metadata(self):
        self.reject(omit='machine-driver-bundle-LICENSES.txt')


class MachineUrlSettingsTests(unittest.TestCase):
    def evaluate(self, overrides):
        repo = SCRIPT.parents[2]
        recipe = (repo / 'server/Dockerfile.web-compose-release').read_text(encoding='utf-8')
        cattle = (repo / 'server/artifacts/cattle.sh').read_text(encoding='utf-8')
        function = re.search(r'^setup_local_agents\(\)\n\{.*?^\}', cattle, re.M | re.S).group()
        removal = next(line.strip().removesuffix(' \\') for line in recipe.splitlines()
                       if line.strip().startswith("sed -i '/^export ")
                       and 'CATTLE_SERVICE_PACKAGE_DOCKER_MACHINE_URL=/d' in line)
        default = '/usr/share/cattle/artifacts/machine-driver-bundle-0.16.5-linux-amd64.tar.xz,docker-machine'
        key = 'CATTLE_SERVICE_PACKAGE_DOCKER_MACHINE_URL'
        with tempfile.TemporaryDirectory() as directory:
            env_file = pathlib.Path(directory) / 'env_vars'
            env_file.write_text('export DEFAULT_' + key + '=old-package\nexport ' + key + '=old-package\n', encoding='utf-8')
            script = 'set -eu\n' + removal + '\n' + function + '\nsetup_local_agents\nprintf "%s\\n%s\\n" "${DEFAULT_' + key + '}" "${' + key + '-unset}"'
            script = script.replace('/usr/share/cattle/env_vars', str(env_file))
            env = {**os.environ, 'CATTLE_USE_LOCAL_ARTIFACTS': 'true', 'DEFAULT_' + key: default, **overrides}
            result = subprocess.run(['bash', '-c', script], env=env, capture_output=True, text=True, check=True)
            return result.stdout.splitlines(), default

    def test_new_image_default_is_not_reset_by_inherited_env_file(self):
        values, default = self.evaluate({})
        self.assertEqual(values, [default, 'unset'])

    def test_operator_default_and_active_overrides_survive(self):
        key = 'CATTLE_SERVICE_PACKAGE_DOCKER_MACHINE_URL'
        values, _ = self.evaluate({'DEFAULT_' + key: 'https://mirror.example/default',
                                   key: 'https://mirror.example/active'})
        self.assertEqual(values, ['https://mirror.example/default', 'https://mirror.example/active'])


class CompanionArchiveGuardTests(unittest.TestCase):
    def check_guard(self, helper, member, link, message):
        with tempfile.TemporaryDirectory(prefix='pst-archive-guard-') as directory:
            base = pathlib.Path(directory)
            source = SCRIPT.with_name(helper).read_text(encoding='utf-8')
            # Keep all extraction destinations in this test's disposable tree.
            source = source.replace('/out/', str(base / 'out') + '/')
            agent = helper == 'verify-agent-package.sh'
            archive = base / ('fixture.tar.gz' if agent else 'fixture.tar.xz')
            with tarfile.open(archive, 'w:gz' if agent else 'w:xz') as tar:
                info = tarfile.TarInfo(member)
                if link:
                    info.type = tarfile.SYMTYPE
                    info.linkname = 'missing-test-target'
                    tar.addfile(info)
                else:
                    info.size = 1
                    tar.addfile(info, io.BytesIO(b'x'))
            args = (['host-api', str(archive), 'a' * 32, '0' * 64, '0' * 64] if agent
                    else ['secret-delivery-api', '0.3.3', 'a' * 40, str(archive),
                          '0' * 64, str(base / 'out/secret-delivery-api')])
            result = subprocess.run(['bash', '-c', source, 'archive-fixture', *args],
                                    text=True, capture_output=True, check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(message, result.stderr,
                          'A later manifest/checksum error must not hide a bypassed safety guard')
            self.assertFalse((base / 'out/secret-delivery-api').exists())

    def test_runtime_producer_rejects_links_before_extract(self):
        self.check_guard('verify-runtime-producer.sh', 'secret-delivery-api', True,
                         'Runtime producer archive may not contain links')

    def test_runtime_producer_rejects_parent_paths_before_extract(self):
        self.check_guard('verify-runtime-producer.sh', '../outside', False,
                         'Unsafe runtime producer archive path')

    def test_agent_rejects_links_before_manifest(self):
        self.check_guard('verify-agent-package.sh', 'a' * 32 + '/bin/host-api', True,
                         'Agent archive may not contain links')

    def test_agent_rejects_parent_paths_before_manifest(self):
        self.check_guard('verify-agent-package.sh', 'a' * 32 + '/../outside', False,
                         'Unsafe agent archive path')


if __name__ == '__main__':
    unittest.main(verbosity=2)

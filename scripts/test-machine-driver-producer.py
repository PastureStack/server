"""Focused archive rejection tests; the build validates the real producer bytes."""
import io
import pathlib
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
    def reject(self, extra=None, link=None, omit=None):
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
            self.assertFalse((base / 'machine-driver-bundle/licenses/SERVER-PRODUCER-SOURCES.txt').exists())

    def test_wrong_binary_hash(self):
        self.reject()

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


if __name__ == '__main__':
    unittest.main(verbosity=2)

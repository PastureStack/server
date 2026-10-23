"""Direct archive rejection tests; no download, image build or runtime changes."""
import hashlib
from pathlib import Path
import re
import subprocess
import tempfile
import unittest
import warnings
import zipfile


ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'server/artifacts/verify-engine-archive.sh'
HAZELCAST_SHA = '825b5fc9526a10549bcb580f2d6c03bf1f5667625661722c0406ea6f796e83f2'
HAZELCAST_ENTRY = 'WEB-INF/lib/hazelcast-5.7.6.jar'
FREEMARKER_ENTRY = 'WEB-INF/lib/freemarker-2.3.35.jar'
PAYLOAD = b'small nested Hazelcast fixture'


class EngineArchiveContract(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        source = HELPER.read_text()
        self.assertEqual(source.count(HAZELCAST_SHA), 1)
        # Only substitute the nested fixture bytes' hash. Every production
        # guard executes unchanged; the unmodified helper is also tested
        # separately against the exact published 88 MB Engine archive.
        self.helper = self.directory / 'verify.sh'
        self.helper.write_text(source.replace(HAZELCAST_SHA, hashlib.sha256(PAYLOAD).hexdigest()))

    def run_archive(self, extra=(), omitted=(), manifest='0.183.354', payload=PAYLOAD, wrong_hash=False):
        entries = [
            ('META-INF/MANIFEST.MF', ('Manifest-Version: 1.0\r\nImplementation-Version: ' + manifest + '\r\n').encode()),
            (FREEMARKER_ENTRY, b'Freemarker fixture'),
            (HAZELCAST_ENTRY, payload),
        ]
        archive = self.directory / 'engine.jar'
        with warnings.catch_warnings():
            warnings.simplefilter('ignore', UserWarning)
            with zipfile.ZipFile(archive, 'w') as bundle:
                for name, content in entries + list(extra):
                    if name not in omitted:
                        bundle.writestr(name, content)
        # Recompute each mutated archive's outer hash, so rejection cannot
        # accidentally be attributed to an unrelated whole-file mismatch.
        digest = '0' * 64 if wrong_hash else hashlib.sha256(archive.read_bytes()).hexdigest()
        return subprocess.run(['sh', str(self.helper), str(archive), '0.183.354', digest],
                              capture_output=True, text=True, timeout=15)

    def reject(self, marker, **kwargs):
        result = self.run_archive(**kwargs)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(marker, result.stdout + result.stderr)
        self.assertNotIn('ENGINE_ARCHIVE_CONTRACT_OK', result.stdout)

    def test_current_archive(self):
        result = self.run_archive()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('ENGINE_ARCHIVE_CONTRACT_OK', result.stdout)

    def test_outer_hash(self):
        self.reject('FAILED', wrong_hash=True)

    def test_manifest(self):
        self.reject('implementation version mismatch', manifest='0.183.353')

    def test_old_hazelcast_alone_and_alongside(self):
        for omitted in ((), (HAZELCAST_ENTRY,)):
            with self.subTest(omitted=omitted):
                self.reject('Rejected old Hazelcast dependency', omitted=omitted,
                            extra=[('WEB-INF/lib/hazelcast-5.7.5.jar', b'old')])

    def test_old_freemarker(self):
        self.reject('Rejected old Freemarker dependency',
                    extra=[('WEB-INF/lib/freemarker-2.3.34.jar', b'old')])

    def test_unexpected_dependency_version(self):
        for name, marker in [('WEB-INF/lib/hazelcast-5.7.7.jar', 'Hazelcast'),
                             ('WEB-INF/lib/freemarker-2.3.36.jar', 'Freemarker')]:
            with self.subTest(name=name):
                self.reject(marker + ' archive contract mismatch', extra=[(name, b'other')])

    def test_duplicate_entry(self):
        self.reject('Duplicate Orchestration Engine JAR path', extra=[(HAZELCAST_ENTRY, PAYLOAD)])

    def test_unsafe_paths(self):
        for path in ('/absolute', '../escape', 'WEB-INF/../escape'):
            with self.subTest(path=path):
                self.reject('Unsafe Orchestration Engine JAR path', extra=[(path, b'unsafe')])

    def test_nested_hazelcast_hash(self):
        self.reject('FAILED', payload=b'altered nested bytes')

    def test_shared_wiring_and_no_extra_layer_or_stale_variable(self):
        docker = (ROOT / 'server/Dockerfile.web-compose-release').read_text()
        build = (ROOT / 'server/build-api-explorer-patch-image.sh').read_text()
        self.assertIn('sh /usr/share/cattle/verify-engine-archive.sh "${archive}" "${ORCHESTRATION_ENGINE_VERSION}" "${ORCHESTRATION_ENGINE_ARTIFACT_SHA256}"', docker)
        self.assertIn('artifacts/performance-env.sh artifacts/verify-engine-archive.sh /usr/share/cattle/', docker)
        self.assertIn('rm -f /usr/share/cattle/verify-engine-archive.sh;', docker)
        self.assertIn('< "${server_dir}/artifacts/verify-engine-archive.sh"', build)
        self.assertIn('/usr/share/cattle/cattle.jar "${orchestration_engine_version}" "${orchestration_engine_artifact_sha256}"', build)
        engine_run = docker.split('archive=/tmp/orchestration-engine.jar;', 1)[1].split('\nRUN ', 1)[0]
        self.assertNotIn('${listing}', engine_run)
        self.assertNotIn('listing=', engine_run)
        final = re.split(r'(?m)^FROM ', docker)[-1]
        self.assertLessEqual(1 + len(re.findall(r'(?m)^(?:RUN|COPY|ADD) ', final)), 32)
        self.assertNotIn('COPY --from=runtime_security_packages /out/tar /usr/bin/tar', final)
        self.assertIn('sha256sum -c SHA256SUMS; \\\n    install -m 0755 tar /usr/bin/tar; \\\n    dpkg -i packages/*.deb;', final)


if __name__ == '__main__':
    unittest.main(verbosity=2)

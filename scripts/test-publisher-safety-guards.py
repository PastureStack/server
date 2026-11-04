"""Exercise release guards themselves, not only the eventual command exit code."""
from pathlib import Path
import gzip
import hashlib
import os
import subprocess
import tempfile
import textwrap
import unittest

WORKFLOW = Path(__file__).resolve().parents[1] / '.github/workflows/publish-current-server.yml'
JAVA_PATCH_GATE = WORKFLOW.parents[2] / 'scripts/check-server-java-patches-jdk25.sh'
COMMONS_IO_SHA256 = '2b9a7b1f726fb86216dbd2c8321eabe0221dbd5b1be81c18e1cb53811b104758'
COMMONS_IO_FIXTURE_BYTES = b'fixture Commons IO bytes; not a Java runtime acceptance result\n'


class PublisherSafetyGuards(unittest.TestCase):
    def test_browser_report_upload_is_nonempty_lossless_and_keeps_internal_gate_bytes(self):
        source = WORKFLOW.read_text()
        release = source.split('      - name: Create immutable GitHub Release', 1)[1]
        command = ('gzip -n -c "$evidence/web-console-runtime-vulnerabilities.tsv" \\\n'
                   '            >"$evidence/web-console-runtime-vulnerabilities.tsv.gz"')
        self.assertEqual(source.count(command), 1)
        self.assertLess(release.index(command), release.index('            sha256sum \\\n'))
        checksum = release.split('            sha256sum \\\n', 1)[1].split('              >SHA256SUMS', 1)[0]
        upload = release.split('          gh release create "$RELEASE_TAG"', 1)[1].split('\n\n', 1)[0]
        self.assertIn('              web-console-runtime-vulnerabilities.tsv.gz \\\n', checksum)
        self.assertNotIn('              web-console-runtime-vulnerabilities.tsv \\\n', checksum)
        self.assertIn('"$evidence/web-console-runtime-vulnerabilities.tsv.gz"', upload)
        self.assertNotIn('"$evidence/web-console-runtime-vulnerabilities.tsv"', upload)
        self.assertEqual(source.count('cat "$evidence/web-console-runtime-vulnerabilities.tsv"'), 2)
        for report in (b'', b'LOW\tCVE-2026-99999\tfixture\t1.0.0\t\tbrowser-runtime-sbom/node-pkg/Node.js\n'):
            with self.subTest(empty=not report), tempfile.TemporaryDirectory() as temporary:
                evidence = Path(temporary)
                internal = evidence / 'web-console-runtime-vulnerabilities.tsv'
                internal.write_bytes(report)
                archive = evidence / 'host-api-0.38.8.tar.gz'
                producer_bytes = gzip.compress(b'unchanged producer package', mtime=0)
                archive.write_bytes(producer_bytes)
                result = subprocess.run(['bash', '-c', 'set -euo pipefail; evidence="$1"; ' + command,
                                         'upload-fixture', temporary], capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                public = evidence / 'web-console-runtime-vulnerabilities.tsv.gz'
                self.assertGreater(public.stat().st_size, 0)
                self.assertEqual(gzip.decompress(public.read_bytes()), report)
                self.assertEqual(gzip.decompress(gzip.compress(report, mtime=0)), report)
                self.assertEqual(internal.read_bytes(), report)
                self.assertEqual(archive.read_bytes(), producer_bytes)

    def test_empty_gzip_cannot_replace_the_producer_host_package(self):
        source = WORKFLOW.read_text()
        release = source.split('      - name: Create immutable GitHub Release', 1)[1]
        start = release.index('          host_archive_sha=')
        end = release.index('\n          (', start)
        guard = textwrap.dedent(release[start:end])
        self.assertLess(start, release.index('          gh release create'))
        import hashlib
        for replace in (False, True):
            with self.subTest(empty_gzip=replace), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                (root / 'source/server').mkdir(parents=True)
                original = gzip.compress(b'unchanged producer package', mtime=0)
                (root / 'source/server/Dockerfile.web-compose-release').write_text(
                    'ARG HOST_API_ARCHIVE_SHA256=' + hashlib.sha256(original).hexdigest() + '\n')
                archive = root / 'host-api-0.38.8.tar.gz'
                archive.write_bytes(gzip.compress(b'', mtime=0) if replace else original)
                result = subprocess.run(['bash', '-c',
                    'set -euo pipefail; evidence="$1"; HOST_API_VERSION=0.38.8; ' + guard,
                    'asset-fixture', temporary], cwd=temporary, capture_output=True, text=True)
                self.assertEqual(result.returncode, int(replace), result.stderr)

    def guard(self, prefix):
        lines = [line.strip() for line in WORKFLOW.read_text().splitlines()
                 if line.strip().startswith(prefix)]
        self.assertEqual(len(lines), 1)
        return lines[0]

    def test_existing_run_object_stops_before_using_it(self):
        command = self.guard('if docker inspect "$object"')
        for existing in (False, True):
            script = ('set -euo pipefail; object=owned-fixture; '
                      f'docker() {{ return {0 if existing else 1}; }}; '
                      + command + '; echo NEXT_COMMAND')
            result = subprocess.run(['bash', '-c', script], capture_output=True, text=True)
            self.assertEqual(result.returncode, int(existing))
            self.assertEqual('NEXT_COMMAND' in result.stdout, not existing)
            if existing:
                self.assertIn('Run-owned object already exists', result.stderr)

    def test_database_authentication_error_stops_before_publication(self):
        command = self.guard('if grep -Fq "mysql_native_password')
        for failed in (False, True):
            with tempfile.TemporaryDirectory() as temporary:
                (Path(temporary) / 'candidate.log').write_text(
                    "mysql_native_password': this user requires mysql native password authentication\n"
                    if failed else 'Database ready\n')
                result = subprocess.run(['bash', '-c',
                    'set -euo pipefail; evidence="$1"; ' + command + '; echo NEXT_COMMAND',
                    'guard-test', temporary], capture_output=True, text=True)
                self.assertEqual(result.returncode, int(failed))
                self.assertEqual('NEXT_COMMAND' in result.stdout, not failed)
                if failed:
                    self.assertIn('Candidate database authentication failed', result.stderr)

    def test_collision_never_arms_cleanup_or_removes_existing_objects(self):
        source = WORKFLOW.read_text()
        block = source.split('          capture_candidate_evidence() {', 1)[1]
        block = '          capture_candidate_evidence() {' + block.split('          wait_for_pong() {', 1)[0]
        block = textwrap.dedent(block)
        for collision in ('candidate', 'cattle', 'mysql', 'mysqllog', ''):
            with self.subTest(collision=collision), tempfile.TemporaryDirectory() as temporary:
                script = '''set -Eeuo pipefail
evidence="$1"
collision="$2"
CANDIDATE_NAME=candidate
CANDIDATE_IMAGE=image
CATTLE_VOLUME=cattle
MYSQL_VOLUME=mysql
MYSQL_LOG_VOLUME=mysqllog
docker() {
  if [[ "$1" == inspect ]]; then
    if [[ "$2" == "$collision" ]]; then return 0; else return 1; fi
  fi
  printf '%s\\n' "$*" >>"$evidence/commands"
  if [[ "$1 $2" == 'image inspect' ]]; then
    printf '%s\\n' 'JAVA_OPTS=--add-opens=java.base/java.lang=ALL-UNNAMED'
  fi
}
''' + block
                result = subprocess.run(['bash', '-c', script, 'guard-test', temporary, collision],
                                        capture_output=True, text=True)
                commands = Path(temporary) / 'commands'
                if collision:
                    self.assertEqual(result.returncode, 1)
                    self.assertIn('Run-owned object already exists', result.stderr)
                    self.assertFalse(commands.exists(), 'Collision must not run or clean any object')
                else:
                    self.assertEqual(result.returncode, 0, result.stderr)
                    calls = commands.read_text().splitlines()
                    self.assertTrue(calls[0].startswith('image inspect image --format '))
                    self.assertTrue(calls[1].startswith('run -d --name candidate '))
                    self.assertIn('JAVA_OPTS=--add-opens=java.base/java.lang=ALL-UNNAMED '
                                  '-Dapi.ai.bridge.enabled=true -Dapi.ai.service.upgrade.enabled=true '
                                  '-Dapi.ai.resource.change.enabled=true', calls[1])
                    self.assertEqual(calls[2:], ['rm -f candidate', 'volume rm cattle mysql mysqllog'])


class CandidateCommonsIoGuards(unittest.TestCase):
    """Exercise only dependency input routing; Java checks are not stubbed as PASS."""

    def dependency_input(self, image='candidate:fixture', local_jdk=False,
                         payload=None, docker_status=0, use_candidate=True):
        source = JAVA_PATCH_GATE.read_text()
        boundary = 'cat > "$tmp/src/io/github/ibuildthecloud/gdapi/model/Filter.java"'
        self.assertEqual(source.count(boundary), 1)
        self.assertEqual(source.count('commons_io_sha256=' + COMMONS_IO_SHA256), 1)
        self.assertIn('commons_io_version=2.22.0', source)
        prefix = source.split(boundary, 1)[0]
        # Tiny deterministic fixture bytes keep this test offline on a fresh CI runner.
        # The actual hardcoded release hash is asserted above; use real sha256sum below.
        # Local qualification can supply cached release bytes without changing the prefix.
        prefix = prefix.replace(COMMONS_IO_SHA256, hashlib.sha256(COMMONS_IO_FIXTURE_BYTES).hexdigest())
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / 'scripts').mkdir()
            (root / 'server/patches').mkdir(parents=True)
            (root / 'server/patches/PatchV1GlobalSubscribe.java').write_text('class PatchV1GlobalSubscribe {}\n')
            for name in ('Dockerfile', 'Dockerfile.auth-hotfix'):
                (root / 'server' / name).write_text(
                    'javac -cp "/usr/share/cattle/war/WEB-INF/lib/*" PatchV1GlobalSubscribe.java\n')
            (root / 'payload').write_bytes(COMMONS_IO_FIXTURE_BYTES if payload is None else payload)
            jdk = root / 'jdk'
            (jdk / 'bin').mkdir(parents=True)
            for name in ('java', 'javac', 'javap'):
                path = jdk / 'bin' / name
                path.write_text('#!/bin/sh\nexit 97\n')
                path.chmod(0o755)
            environment = os.environ.copy()
            for name in ('RC16_JDK25_CHECK_IMAGE', 'RC16_JDK25_COMMONS_IO_IMAGE', 'RC16_JDK25_HOME'):
                environment.pop(name, None)
            environment.update(RC16_JDK25_CHECK_IMAGE='candidate:fixture', FIXTURE_ROOT=temporary,
                               FIXTURE_DOCKER_STATUS=str(docker_status))
            if use_candidate:
                environment['RC16_JDK25_COMMONS_IO_IMAGE'] = image
            if local_jdk:
                environment['RC16_JDK25_HOME'] = str(jdk)
            stubs = r'''docker() {
  printf 'docker' >>"$FIXTURE_ROOT/calls"
  printf '\t%s' "$@" >>"$FIXTURE_ROOT/calls"
  printf '\n' >>"$FIXTURE_ROOT/calls"
  if [ "$FIXTURE_DOCKER_STATUS" -ne 0 ]; then return "$FIXTURE_DOCKER_STATUS"; fi
  cat "$FIXTURE_ROOT/payload"
}
curl() {
  printf 'curl' >>"$FIXTURE_ROOT/calls"
  printf '\t%s' "$@" >>"$FIXTURE_ROOT/calls"
  printf '\n' >>"$FIXTURE_ROOT/calls"
  local output=
  while [ "$#" -gt 0 ]; do
    if [ "$1" = -o ]; then output=$2; shift; fi
    shift
  done
  test -n "$output"
  cat "$FIXTURE_ROOT/payload" >"$output"
}
'''
            result = subprocess.run(['bash', '-c', stubs + prefix + '\necho DEPENDENCY_INPUT_READY\n',
                                     str(root / 'scripts/check-server-java-patches-jdk25.sh')],
                                    env=environment, capture_output=True, text=True)
            calls = (root / 'calls').read_text().splitlines() if (root / 'calls').exists() else []
            return result, [line.split('\t') for line in calls]

    def test_candidate_commons_io_uses_same_image_offline_and_checks_bytes(self):
        result, calls = self.dependency_input()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('DEPENDENCY_INPUT_READY', result.stdout)
        self.assertEqual(calls, [['docker', 'run', '--rm', '--pull=never', '--network', 'none',
                                 '--entrypoint', '/bin/cat', 'candidate:fixture',
                                 '/usr/share/cattle/war/WEB-INF/lib/commons-io-2.22.0.jar']])

    def test_candidate_commons_io_missing_or_wrong_bytes_never_fall_back(self):
        for payload, status in ((b'', 0), (b'wrong bytes', 0), (None, 1)):
            with self.subTest(payload=payload, status=status):
                result, calls = self.dependency_input(payload=payload, docker_status=status)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn('DEPENDENCY_INPUT_READY', result.stdout)
                self.assertEqual(len(calls), 1)
                self.assertEqual(calls[0][0], 'docker')
                if status == 0:
                    self.assertIn('FAILED', result.stdout)

    def test_candidate_commons_io_rejects_wrong_empty_or_local_jdk_image_before_io(self):
        for image, local_jdk in (('different:fixture', False), ('', False), ('candidate:fixture', True)):
            with self.subTest(image=image, local_jdk=local_jdk):
                result, calls = self.dependency_input(image=image, local_jdk=local_jdk)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('JDK25_COMMONS_IO_IMAGE_INVALID', result.stderr)
                self.assertEqual(calls, [])

    def test_candidate_commons_io_default_jdk_and_local_modes_keep_pinned_curl(self):
        for local_jdk in (False, True):
            with self.subTest(local_jdk=local_jdk):
                result, calls = self.dependency_input(local_jdk=local_jdk, use_candidate=False)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(len(calls), 1)
                self.assertEqual(calls[0][0:2], ['curl', '-fsSL'])
                self.assertEqual(calls[0][-1], 'https://repo.maven.apache.org/maven2/commons-io/commons-io/2.22.0/commons-io-2.22.0.jar')
                self.assertIn('--retry-all-errors', calls[0])
                self.assertIn('DEPENDENCY_INPUT_READY', result.stdout)

    def test_candidate_commons_io_publisher_binds_the_actual_check_image(self):
        source = WORKFLOW.read_text()
        binding = ('RC16_JDK25_COMMONS_IO_IMAGE="$CANDIDATE_IMAGE" \\\n'
                   '              RC16_JDK25_CHECK_IMAGE="$CANDIDATE_IMAGE" bash scripts/check-server-java-patches-jdk25.sh')
        self.assertEqual(source.count(binding), 1)


if __name__ == '__main__':
    unittest.main()

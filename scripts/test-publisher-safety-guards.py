"""Exercise release guards themselves, not only the eventual command exit code."""
from pathlib import Path
import gzip
import subprocess
import tempfile
import textwrap
import unittest

WORKFLOW = Path(__file__).resolve().parents[1] / '.github/workflows/publish-current-server.yml'


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
                    self.assertTrue(calls[0].startswith('run -d --name candidate '))
                    self.assertEqual(calls[1:], ['rm -f candidate', 'volume rm cattle mysql mysqllog'])


if __name__ == '__main__':
    unittest.main()

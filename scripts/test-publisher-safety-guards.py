"""Exercise release guards themselves, not only the eventual command exit code."""
from pathlib import Path
import subprocess
import tempfile
import unittest

WORKFLOW = Path(__file__).resolve().parents[1] / '.github/workflows/publish-current-server.yml'


class PublisherSafetyGuards(unittest.TestCase):
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


if __name__ == '__main__':
    unittest.main()

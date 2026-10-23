"""Validate local COPY inputs against the production Server build context."""
from pathlib import Path
import shlex
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONTEXT = ROOT / 'server'
RECIPE = CONTEXT / 'Dockerfile.web-compose-release'


def copy_inputs(source):
    for line in source.replace('\\\n', ' ').splitlines():
        words = shlex.split(line, comments=True)
        if not words or words[0].upper() != 'COPY':
            continue
        if any(word.startswith('--from=') for word in words[1:]):
            continue
        yield from [word for word in words[1:-1] if not word.startswith('--')]


def missing_inputs(source, context=CONTEXT):
    missing = []
    for name in copy_inputs(source):
        path = (context / name).resolve()
        matches = list(context.glob(name)) if path.is_relative_to(context.resolve()) else []
        if not matches or any(not item.resolve().is_relative_to(context.resolve()) for item in matches):
            missing.append(name)
    return missing


class ServerBuildContext(unittest.TestCase):
    def test_every_local_copy_input_exists_in_production_context(self):
        build = (CONTEXT / 'build-api-explorer-patch-image.sh').read_text()
        self.assertIn('--file server/Dockerfile.web-compose-release server',
                      ' '.join(build.replace('\\\n', ' ').split()))
        source = RECIPE.read_text()
        self.assertIn('scripts/install-ubuntu-security-updates.sh', list(copy_inputs(source)))
        self.assertIn('security/ubuntu-security-packages.lock', list(copy_inputs(source)))
        self.assertEqual(missing_inputs(source), [])

    def test_repository_relative_prefix_is_rejected(self):
        wrong = 'COPY server/scripts/install-ubuntu-security-updates.sh server/security/ubuntu-security-packages.lock /tmp/'
        self.assertEqual(missing_inputs(wrong), [
            'server/scripts/install-ubuntu-security-updates.sh',
            'server/security/ubuntu-security-packages.lock'])

    def test_stage_copy_is_not_confused_with_local_input(self):
        self.assertEqual(missing_inputs('COPY --from=builder /generated/file /out/'), [])
        self.assertEqual(missing_inputs('COPY ../README.md /out/'), ['../README.md'])


if __name__ == '__main__':
    unittest.main()

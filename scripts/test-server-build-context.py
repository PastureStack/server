"""Validate local COPY inputs against the production Server build context."""
from pathlib import Path
import shlex
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
CONTEXT = ROOT / 'server'
RECIPE = CONTEXT / 'Dockerfile.web-compose-release'
LAUNCHERS = {'websocket-proxy', 'catalog-service', 'rancher-catalog-service',
             'authentication-service', 'rancher-auth-service', 'compose-executor',
             'rancher-compose-executor', 'host-provisioner', 'go-machine-service'}


def current_launcher_flow(source, build):
    normalized = source.replace('\\\n', ' ')
    producer = normalized.split(' AS rsync_security_package', 1)[0]
    if 'COPY patches/websocket-proxy-wrapper.sh /out/service-launcher.sh' not in producer:
        return False
    loop = re.search(r'for launcher in (.*?); do\s+install -m 0755 /out/service-launcher.sh "/out/runtime-bin/\$\{launcher\}";', producer)
    names = shlex.split(loop[1]) if loop else []
    if len(names) != len(LAUNCHERS) or set(names) != LAUNCHERS:
        return False
    if 'COPY --from=release_artifacts --chmod=0755 /out/runtime-bin/ /usr/bin/' not in normalized:
        return False
    check = re.search(r'wrapper_paths=\((.*?)\)', build, re.S)
    paths = shlex.split(check[1]) if check else []
    return (len(paths) == len(LAUNCHERS) and set(paths) == {'/usr/bin/' + n for n in LAUNCHERS}
            and 'launcher_wrapper_sha256=$(sha256sum server/patches/websocket-proxy-wrapper.sh' in build)


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

    def test_current_source_reaches_all_runtime_launchers_and_hash_checks(self):
        self.assertTrue(current_launcher_flow(RECIPE.read_text(encoding='utf-8'),
                                             (CONTEXT / 'build-api-explorer-patch-image.sh').read_text(encoding='utf-8')))

    def test_inherited_partial_or_unchecked_launcher_rejected(self):
        source = RECIPE.read_text(encoding='utf-8')
        build = (CONTEXT / 'build-api-explorer-patch-image.sh').read_text(encoding='utf-8')
        cases = [(source.replace('COPY patches/websocket-proxy-wrapper.sh /out/service-launcher.sh', ''), build),
                 (source.replace('catalog-service rancher-catalog-service', 'catalog-service'), build),
                 (source.replace('COPY --from=release_artifacts --chmod=0755 /out/runtime-bin/ /usr/bin/', ''), build),
                 (source, build.replace('    /usr/bin/rancher-catalog-service\n', '')),
                 (source, build.replace('launcher_wrapper_sha256=$(sha256sum server/patches/websocket-proxy-wrapper.sh', 'launcher_wrapper_sha256=old_base_hash #'))]
        for recipe, consumer in cases:
            with self.subTest(recipe=recipe == source, consumer=consumer == build):
                self.assertFalse(current_launcher_flow(recipe, consumer))


if __name__ == '__main__':
    unittest.main()

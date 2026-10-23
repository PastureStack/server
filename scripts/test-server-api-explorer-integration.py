#!/usr/bin/env python3
"""Exercise the current product installer and reject stale or unsafe archives.

No product rebuild, browser test, container or registry operation is performed.
"""
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
PREPARE = ROOT / 'server/artifacts/prepare-api-explorer.sh'
COMMIT = 'dda3fe8a806d9736de771d325e3ca98ab4067cd2'
COPY = 'COPY --from=release_artifacts /out/api-explorer/ /tmp/pasturestack-api-ui/'
SPEC = importlib.util.spec_from_file_location('packaging', ROOT / 'scripts/test-current-server-packaging-contract.py')
PACKAGING = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PACKAGING)


def product():
    files = {
        'version.json': json.dumps({'version': '1.1.19', 'commit': COMMIT[:7]}).encode(),
        'ui.js': b'handlebars v4.7.10 PastureStackUi pasturestack:modal:shown pasturestack:modal:hidden data-pasturestack-toggle',
        'ui.min.js': b'fixture-minified-runtime',
        'ui.css': b'Bootstrap v5.3.8 url("./fonts/bootstrap-icons.woff2")',
        'ui.min.css': b'fixture-minified-css',
        'fonts/bootstrap-icons.woff': b'fixture-font',
        'fonts/bootstrap-icons.woff2': b'fixture-font2',
    }
    for legal in ('LICENSE.txt', 'ORIGIN.md', 'THIRD-PARTY-NOTICES.md',
                  'bootstrap-5.3.8/LICENSE', 'bootstrap-icons-1.13.1/LICENSE',
                  'handlebars-4.7.10/LICENSE', 'jquery-4.0.0/LICENSE.txt',
                  'inherited-vendor/LICENSE-async-0.9.0',
                  'inherited-vendor/LICENSE-jquery-scrollintoview-1.8',
                  'inherited-vendor/LICENSE-jsonformatter-2009',
                  'inherited-vendor/LICENSE-polyfill-compat', 'inherited-vendor/NOTICE-json2'):
        files['licenses/' + legal] = b'fixture license text'
    return files


def archive(destination, files, mutate=None):
    entries = []
    directories = {''}
    for name in files:
        directories.update(str(parent).replace('\\', '/') for parent in Path(name).parents if str(parent) != '.')
    for name in sorted(directories):
        item = tarfile.TarInfo('./' + (name + '/' if name else ''))
        item.type = tarfile.DIRTYPE
        item.mode = 0o755
        entries.append((item, b''))
    for name, data in files.items():
        item = tarfile.TarInfo('./' + name)
        item.mode = 0o644
        item.size = len(data)
        entries.append((item, data))
    if mutate:
        mutate(entries)
    with tarfile.open(destination, 'w:gz', format=tarfile.GNU_FORMAT) as stream:
        for item, data in entries:
            stream.addfile(item, io.BytesIO(data))


class ExplorerIntegration(unittest.TestCase):
    def run_product(self, files=None, mutate=None, existing=False):
        with tempfile.TemporaryDirectory(prefix='server-api-install-') as temporary:
            directory = Path(temporary)
            artifact = directory / 'api.tar.gz'
            archive(artifact, product() if files is None else files, mutate)
            if existing:
                (directory / 'out').mkdir()
                (directory / 'out/preserve').write_text('existing-output')
            result = subprocess.run(['bash', str(PREPARE), str(artifact), '1.1.19', COMMIT, str(directory / 'out')],
                                    text=True, capture_output=True)
            self.assertFalse((directory.parent / 'escaped-api-member').exists())
            if existing:
                self.assertEqual('existing-output', (directory / 'out/preserve').read_text())
            return result

    def test_valid_product_and_all_licenses_install(self):
        result = self.run_product()
        self.assertEqual(0, result.returncode, result.stdout + result.stderr)
        self.assertIn('SERVER_API_EXPLORER_PRODUCT_OK version=1.1.19', result.stdout)

    def test_existing_output_is_never_overwritten(self):
        self.assertNotEqual(0, self.run_product(existing=True).returncode)

    def test_stale_version_commit_runtime_and_missing_legal_rejected(self):
        mutations = (
            ('old-version', 'version.json', b'{"version":"1.1.18","commit":"dda3fe8"}'),
            ('old-commit', 'version.json', b'{"version":"1.1.19","commit":"3b1c39e"}'),
            ('old-runtime', 'ui.js', product()['ui.js'].replace(b'4.7.10', b'4.7.9')),
            ('missing-license', 'licenses/handlebars-4.7.10/LICENSE', None),
            ('empty-license', 'licenses/LICENSE.txt', b''),
        )
        for label, name, value in mutations:
            with self.subTest(case=label):
                files = product()
                if value is None:
                    del files[name]
                else:
                    files[name] = value
                self.assertNotEqual(0, self.run_product(files).returncode)

    def test_links_devices_aliases_duplicates_and_traversal_rejected_before_extract(self):
        def change(entries, kind):
            item, data = next(entry for entry in entries if entry[0].name == './ui.js')
            if kind in ('symbolic-link', 'hard-link', 'fifo', 'device'):
                item.type = {'symbolic-link': tarfile.SYMTYPE, 'hard-link': tarfile.LNKTYPE,
                             'fifo': tarfile.FIFOTYPE, 'device': tarfile.CHRTYPE}[kind]
                item.linkname = '../escaped-api-member'
                item.size = 0
            elif kind == 'duplicate':
                entries.append((item, data))
            else:
                item.name = {'alias': './fonts/../ui.js', 'absolute': '/ui.js',
                             'traversal': '../escaped-api-member'}[kind]
        for kind in ('symbolic-link', 'hard-link', 'fifo', 'device', 'duplicate', 'alias', 'absolute', 'traversal'):
            with self.subTest(case=kind):
                self.assertNotEqual(0, self.run_product(mutate=lambda entries: change(entries, kind)).returncode)

    def test_current_recipe_cannot_omit_copy_or_accept_old_artifact(self):
        PACKAGING.verify_incremental_contract(PACKAGING.FILES)
        for replacement in ('', '# ' + COPY):
            files = dict(PACKAGING.FILES)
            files[PACKAGING.DOCKER] = files[PACKAGING.DOCKER].replace(COPY, replacement)
            with self.assertRaises(AssertionError):
                PACKAGING.verify_incremental_contract(files)
        for old, new in (
            ('api-explorer-1.1.20.tar.gz', 'api-explorer-1.1.19.tar.gz'),
            ('c989ee12a518f6d9d2b23b1f17f48d781aacf6ec31fb65291dd7de9b1661badb', 'd1602ab6033512f0b86dc8ceafee2061364ce2fc5da2a9b7119f900d9e0f3c25'),
        ):
            files = dict(PACKAGING.FILES)
            self.assertIn(old, files[PACKAGING.DOCKER], 'mutation must change the current recipe')
            files[PACKAGING.DOCKER] = files[PACKAGING.DOCKER].replace(old, new)
            with self.assertRaises(AssertionError):
                PACKAGING.verify_incremental_contract(files)


if __name__ == '__main__':
    unittest.main(verbosity=2)

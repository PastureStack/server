#!/usr/bin/env python3
"""Offline tests for the tracked Catalog package and its packaging helper."""

import copy
from contextlib import redirect_stderr, redirect_stdout
import hashlib
import importlib.util
import json
import io
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


sys.dont_write_bytecode = True
REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / 'scripts' / 'package-catalog-source.py'
SPEC = importlib.util.spec_from_file_location('catalog_source_package', SCRIPT)
PACKAGE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PACKAGE)


def run_git(repo, *args, input_data=None, check=True):
    environment = {
        key: value for key, value in os.environ.items()
        if not key.upper().startswith('GIT_')
    }
    environment.update({
        'GIT_CONFIG_GLOBAL': os.devnull, 'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_TERMINAL_PROMPT': '0',
    })
    command = ['git', '-c', 'core.autocrlf=false', '-c', 'core.hooksPath=' + os.devnull,
               '-c', 'user.name=Catalog fixture', '-c', 'user.email=catalog@example.invalid']
    if repo is not None:
        command += ['-C', str(repo)]
    return subprocess.run(command + list(args), input=input_data, env=environment,
                          capture_output=True, check=check, timeout=60,
                          cwd=tempfile.gettempdir())


def fixture_repository(root, missing=None):
    working = root / 'working'
    run_git(None, 'init', str(working))
    files = {PACKAGE.LICENSE_PATH: b'MIT fixture license\n'}
    for template in PACKAGE.REQUIRED_TEMPLATES:
        folder = 'infra-templates/' + template['name']
        version = folder + '/' + str(template['revision'])
        files[folder + '/config.yml'] = ('name: ' + template['name'] + '\n').encode()
        files[version + '/rancher-compose.yml'] = b'catalog:\n  version: fixture\n'
        files[version + '/docker-compose.yml'] = b'services:\n  fixture:\n    image: example.invalid/fixture\n'
    for name, data in files.items():
        if name != missing:
            target = working / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
    run_git(working, 'add', '--all')
    run_git(working, 'commit', '-m', 'Complete local Catalog fixture')
    pin = run_git(working, 'rev-parse', 'HEAD').stdout.decode().strip()
    bare = root / 'source.git'
    run_git(None, 'clone', '--bare', '--no-local', str(working), str(bare))
    run_git(bare, 'update-ref', PACKAGE.BUNDLE_REF, pin)
    # A disconnected commit proves packaging excludes unrelated old history,
    # rather than merely hiding the old branch from bundle list-heads.
    tree = run_git(bare, 'mktree', input_data=b'').stdout.decode().strip()
    unrelated = run_git(bare, 'commit-tree', tree, input_data=b'Unrelated old history\n').stdout.decode().strip()
    run_git(bare, 'update-ref', 'refs/heads/unrelated-old', unrelated)
    return bare, pin, unrelated


def unchecked_assets(root, bare, pin, exclude=None):
    """Make well-hashed but semantically incomplete input for verifier tests."""
    root.mkdir()
    bundle = root / PACKAGE.BUNDLE_NAME
    args = ['bundle', 'create', str(bundle), PACKAGE.BUNDLE_REF]
    if exclude:
        args.append('^' + exclude)
    run_git(bare, *args)
    source = {
        'url': PACKAGE.SOURCE_URL, 'branch': PACKAGE.SOURCE_BRANCH,
        'pinnedCommit': pin, 'bundle': PACKAGE.BUNDLE_NAME,
        'sha256': hashlib.sha256(bundle.read_bytes()).hexdigest(),
        'requiredTemplates': copy.deepcopy(PACKAGE.REQUIRED_TEMPLATES),
    }
    (root / 'manifest.json').write_text(json.dumps({'version': 1, 'sources': [source]}), encoding='utf-8')
    (root / 'SOURCES.txt').write_text(PACKAGE.sources_text(source), encoding='utf-8')
    license_file = root / PACKAGE.LICENSE_PATH
    license_file.parent.mkdir()
    license_file.write_bytes(b'MIT fixture license\n')


class CatalogSourceDefaultsTests(unittest.TestCase):
    def setUp(self):
        self.source = PACKAGE.load_source(PACKAGE.DEFAULT_OUTPUT, PACKAGE.SOURCE_PIN)

    def test_verify_cli_binds_canonical_defaults_and_preserves_custom_output(self):
        with patch.object(PACKAGE, 'verify_package', return_value=self.source) as verify, redirect_stdout(io.StringIO()):
            self.assertEqual(PACKAGE.main(['--verify']), 0)
            verify.assert_called_once_with(PACKAGE.DEFAULT_OUTPUT, PACKAGE.SOURCE_PIN)
        with tempfile.TemporaryDirectory(prefix='catalog-custom-output-') as temporary:
            output = Path(temporary)
            with (patch.object(PACKAGE, 'verify_package', return_value=self.source) as verify,
                  patch.object(PACKAGE, 'verify_docker_source', side_effect=AssertionError('Custom output is independent')),
                  redirect_stdout(io.StringIO())):
                self.assertEqual(PACKAGE.main(['--verify', '--output-dir', str(output)]), 0)
                verify.assert_called_once_with(output, PACKAGE.SOURCE_PIN)

    def test_verify_cli_rejects_default_pin_branch_or_url_drift_before_bundle_import(self):
        original = PACKAGE.RELEASE_DOCKERFILE.read_text(encoding='utf-8')
        variants = [('PASTURESTACK_CATALOG_COMMIT', 'pin', original.replace(
            'ENV PASTURESTACK_CATALOG_COMMIT=' + self.source['pinnedCommit'],
            'ENV PASTURESTACK_CATALOG_COMMIT=' + '0' * 40))]
        for name in ('CATTLE_CATALOG_URL', 'DEFAULT_CATTLE_CATALOG_URL'):
            current_line = next(line for line in original.splitlines() if line.startswith('ENV ' + name + '='))
            for field, value in (('pinnedCommit', '0' * 40), ('branch', 'next'),
                                 ('url', 'https://github.com/PastureStack/another-catalog.git')):
                configured = {key: self.source[key] for key in ('url', 'branch', 'pinnedCommit')}
                configured[field] = value
                replacement = 'ENV ' + name + "='" + json.dumps({'catalogs': {'pasturestack': configured}}) + "'"
                variants.append((name, field, original.replace(current_line, replacement)))
        variants.append(('all defaults', 'pin', original.replace(self.source['pinnedCommit'], '0' * 40)))
        variants.append(('final stage', 'missing defaults', original + '\nFROM scratch AS unexpected_final\n'))
        with tempfile.TemporaryDirectory(prefix='catalog-default-drift-') as temporary:
            dockerfile = Path(temporary) / 'Dockerfile'
            for name, field, text in variants:
                with self.subTest(name=name, field=field):
                    dockerfile.write_text(text, encoding='utf-8')
                    errors = io.StringIO()
                    with (patch.object(PACKAGE, 'RELEASE_DOCKERFILE', dockerfile),
                          patch.object(PACKAGE, 'verify_package') as verify,
                          redirect_stderr(errors), redirect_stdout(io.StringIO())):
                        self.assertEqual(PACKAGE.main(['--verify']), 1)
                        verify.assert_not_called()
                    self.assertIn('Release Dockerfile', errors.getvalue())


class BundledCatalogSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix='catalog-source-tests-')
        cls.root = Path(cls.temporary.name)
        cls.bare, cls.pin, cls.unrelated = fixture_repository(cls.root)
        cls.valid = cls.root / 'valid-assets'
        PACKAGE.package_source(cls.bare, cls.valid, cls.pin)

    @classmethod
    def tearDownClass(cls):
        cls.temporary.cleanup()

    def setUp(self):
        self.case = tempfile.TemporaryDirectory(prefix='catalog-source-case-')
        self.addCleanup(self.case.cleanup)
        self.directory = Path(self.case.name)
        self.assets = self.directory / 'assets'
        shutil.copytree(self.valid, self.assets)

    def update_manifest(self, change):
        path = self.assets / 'manifest.json'
        manifest = json.loads(path.read_text(encoding='utf-8'))
        change(manifest['sources'][0])
        path.write_text(json.dumps(manifest), encoding='utf-8')

    def test_tracked_release_assets_are_self_contained_and_exact(self):
        source = PACKAGE.verify_package(REPO / 'server' / 'catalog-sources')
        self.assertEqual(source['pinnedCommit'], '6e7b935b6f08e711e1884ef8369cd9dcd110901f')
        self.assertEqual(source['requiredTemplates'], [
            {'base': 'infra', 'name': 'healthcheck', 'revision': 7},
            {'base': 'infra', 'name': 'ipsec-overlay', 'revision': 17},
            {'base': 'infra', 'name': 'network-services', 'revision': 16},
            {'base': 'infra', 'name': 'resource-scheduler', 'revision': 10},
        ])

    def test_verify_cli_works_from_unrelated_directory_and_leaves_assets_unchanged(self):
        before = {str(path.relative_to(self.assets)): path.read_bytes()
                  for path in self.assets.rglob('*') if path.is_file()}
        result = subprocess.run(
            [sys.executable, str(SCRIPT), '--verify', '--output-dir', str(self.assets), '--pin', self.pin],
            cwd=self.directory, capture_output=True, text=True, timeout=60,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('CATALOG_SOURCE_BUNDLE_OK', result.stdout)
        after = {str(path.relative_to(self.assets)): path.read_bytes()
                 for path in self.assets.rglob('*') if path.is_file()}
        self.assertEqual(after, before)

    def test_packaging_excludes_unrelated_refs_and_history(self):
        bare = self.directory / 'imported.git'
        run_git(None, 'init', '--bare', str(bare))
        run_git(bare, 'fetch', str(self.assets / PACKAGE.BUNDLE_NAME),
                PACKAGE.BUNDLE_REF + ':' + PACKAGE.BUNDLE_REF)
        result = run_git(bare, 'cat-file', '-e', self.unrelated, check=False)
        self.assertNotEqual(result.returncode, 0)
        heads = run_git(None, 'bundle', 'list-heads', str(self.assets / PACKAGE.BUNDLE_NAME)).stdout.decode().splitlines()
        self.assertEqual(heads, [self.pin + ' ' + PACKAGE.BUNDLE_REF])

    def test_rejects_changed_bundle_hash(self):
        with (self.assets / PACKAGE.BUNDLE_NAME).open('ab') as stream:
            stream.write(b'corruption')
        with self.assertRaisesRegex(PACKAGE.PackageError, 'SHA-256 does not match'):
            PACKAGE.verify_package(self.assets, self.pin)

    def test_rejects_bad_hash_syntax(self):
        self.update_manifest(lambda source: source.update(sha256='not-a-hash'))
        with self.assertRaisesRegex(PACKAGE.PackageError, 'SHA-256 is invalid'):
            PACKAGE.verify_package(self.assets, self.pin)

    def test_rejects_wrong_release_pin(self):
        self.update_manifest(lambda source: source.update(pinnedCommit='0' * 40))
        with self.assertRaisesRegex(PACKAGE.PackageError, 'expected release commit'):
            PACKAGE.verify_package(self.assets, self.pin)

    def test_rejects_bundle_whose_ref_does_not_match_manifest_pin(self):
        self.update_manifest(lambda source: source.update(pinnedCommit='0' * 40))
        with self.assertRaisesRegex(PACKAGE.PackageError, 'exact pinned Catalog ref'):
            PACKAGE.verify_package(self.assets, '0' * 40)

    def test_rejects_unsafe_bundle_paths(self):
        for path in ('../catalog-templates.bundle', '/tmp/catalog.bundle',
                     'C:/catalog.bundle', 'folder\\catalog.bundle', 'folder//catalog.bundle'):
            with self.subTest(path=path):
                self.update_manifest(lambda source: source.update(bundle=path))
                with self.assertRaisesRegex(PACKAGE.PackageError, 'safe relative path'):
                    PACKAGE.verify_package(self.assets, self.pin)

    def test_rejects_bundle_symlink(self):
        link = self.assets / 'linked.bundle'
        try:
            link.symlink_to(self.assets / PACKAGE.BUNDLE_NAME)
        except OSError:
            self.skipTest('Host does not grant file-symlink privileges')
        self.update_manifest(lambda source: source.update(bundle=link.name))
        with self.assertRaisesRegex(PACKAGE.PackageError, 'symlink'):
            PACKAGE.verify_package(self.assets, self.pin)

    def test_rejects_wrong_source_tuple_and_weakened_requirements(self):
        for change, message in (
            ({'url': 'https://example.invalid/catalog.git'}, 'source URL or branch'),
            ({'branch': 'custom'}, 'source URL or branch'),
            ({'requiredTemplates': []}, 'requiredTemplates'),
        ):
            with self.subTest(change=change):
                original = (self.valid / 'manifest.json').read_bytes()
                (self.assets / 'manifest.json').write_bytes(original)
                self.update_manifest(lambda source: source.update(change))
                with self.assertRaisesRegex(PACKAGE.PackageError, message):
                    PACKAGE.verify_package(self.assets, self.pin)

    def test_rejects_missing_required_source_files_despite_valid_hash_and_pin(self):
        for missing in ('infra-templates/healthcheck/config.yml',
                        'infra-templates/healthcheck/7/rancher-compose.yml',
                        'infra-templates/healthcheck/7/docker-compose.yml', PACKAGE.LICENSE_PATH):
            with self.subTest(missing=missing), tempfile.TemporaryDirectory(prefix='catalog-incomplete-') as temporary:
                root = Path(temporary)
                bare, pin, _ = fixture_repository(root, missing=missing)
                assets = root / 'assets'
                unchecked_assets(assets, bare, pin)
                with self.assertRaisesRegex(PACKAGE.PackageError, 'missing or invalid'):
                    PACKAGE.verify_package(assets, pin)

    def test_rejects_incremental_bundle_requiring_unavailable_history(self):
        root = self.directory / 'incremental'
        root.mkdir()
        bare, first, _ = fixture_repository(root)
        working = root / 'working'
        (working / 'new-file.txt').write_text('new version\n', encoding='utf-8')
        run_git(working, 'add', '--all')
        run_git(working, 'commit', '-m', 'Next fixture version')
        pin = run_git(working, 'rev-parse', 'HEAD').stdout.decode().strip()
        run_git(bare, 'fetch', str(working), pin + ':' + PACKAGE.BUNDLE_REF)
        assets = root / 'assets'
        unchecked_assets(assets, bare, pin, exclude=first)
        with self.assertRaisesRegex(PACKAGE.PackageError, 'bundle failed'):
            PACKAGE.verify_package(assets, pin)

    def test_rejects_license_or_attribution_drift(self):
        for name, message in ((PACKAGE.LICENSE_PATH, 'Packaged license'), ('SOURCES.txt', 'SOURCES.txt')):
            with self.subTest(name=name):
                target = self.assets / name
                original = target.read_bytes()
                target.write_bytes(b'changed\n')
                with self.assertRaisesRegex(PACKAGE.PackageError, message):
                    PACKAGE.verify_package(self.assets, self.pin)
                target.write_bytes(original)

    def test_invalid_source_does_not_publish_partial_assets(self):
        root = self.directory / 'missing-source'
        root.mkdir()
        bare, pin, _ = fixture_repository(root, missing='infra-templates/healthcheck/config.yml')
        output = root / 'output'
        with self.assertRaisesRegex(PACKAGE.PackageError, 'missing or invalid'):
            PACKAGE.package_source(bare, output, pin)
        self.assertFalse(output.exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)

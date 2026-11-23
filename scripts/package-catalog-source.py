#!/usr/bin/env python3
"""Package or verify the Server's self-contained, pinned Catalog Git source.

Only Python's standard library and Git are required. Packaging reads an existing
local bare repository; verification never reads that repository or the network.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile


SOURCE_URL = 'https://github.com/PastureStack/catalog-templates.git'
SOURCE_BRANCH = 'main'
SOURCE_PIN = '6e7b935b6f08e711e1884ef8369cd9dcd110901f'
BUNDLE_NAME = 'catalog-templates.bundle'
BUNDLE_REF = 'refs/heads/pasturestack-catalog'
LICENSE_PATH = 'LICENSES/MIT.txt'
REQUIRED_TEMPLATES = [
    {'base': 'infra', 'name': 'healthcheck', 'revision': 7},
    {'base': 'infra', 'name': 'ipsec-overlay', 'revision': 17},
    {'base': 'infra', 'name': 'network-services', 'revision': 16},
    {'base': 'infra', 'name': 'resource-scheduler', 'revision': 10},
]
DEFAULT_OUTPUT = Path(__file__).resolve().parents[1] / 'server' / 'catalog-sources'
RELEASE_DOCKERFILE = DEFAULT_OUTPUT.parent / 'Dockerfile.web-compose-release'
FULL_SHA = re.compile(r'[0-9a-f]{40}\Z')
SHA256 = re.compile(r'[0-9a-f]{64}\Z')
PATH_PART = re.compile(r'[A-Za-z0-9._-]+\Z')


class PackageError(Exception):
    """A package does not satisfy the pinned source contract."""


def git(repo, *args):
    environment = {
        key: value for key, value in os.environ.items()
        if not key.upper().startswith('GIT_') and key.upper() != 'SSH_ASKPASS'
    }
    environment.update({
        'GIT_CONFIG_GLOBAL': os.devnull,
        'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_TERMINAL_PROMPT': '0',
        'GIT_ASKPASS': '',
        'SSH_ASKPASS': '',
    })
    command = [
        'git', '-c', 'protocol.allow=never', '-c', 'protocol.file.allow=always',
        '-c', 'credential.helper=', '-c', 'core.hooksPath=' + os.devnull,
    ]
    if repo is not None:
        command += ['-C', str(repo)]
    try:
        result = subprocess.run(
            command + list(args), env=environment, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, check=False, timeout=60,
            cwd=tempfile.gettempdir(),
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise PackageError('Git could not complete: ' + str(error)) from error
    if result.returncode:
        detail = result.stderr.decode('utf-8', errors='replace').strip()
        raise PackageError('Git ' + args[0] + ' failed: ' + detail)
    return result.stdout


def safe_asset(root, relative):
    if not isinstance(relative, str) or not relative:
        raise PackageError('Asset path must be a non-empty relative path')
    parts = relative.split('/')
    if any(part in ('', '.', '..') or not PATH_PART.fullmatch(part) for part in parts):
        raise PackageError('Asset path is not a safe relative path: ' + relative)
    if PurePosixPath(relative).is_absolute():
        raise PackageError('Asset path must be relative: ' + relative)
    candidate = root
    for part in parts:
        candidate = candidate / part
        if candidate.is_symlink():
            raise PackageError('Asset path must not contain a symlink: ' + relative)
    try:
        candidate.resolve(strict=True).relative_to(root.resolve(strict=True))
        mode = candidate.stat().st_mode
    except (OSError, ValueError) as error:
        raise PackageError('Asset path is missing or escapes the package: ' + relative) from error
    if not stat.S_ISREG(mode):
        raise PackageError('Asset must be a regular file: ' + relative)
    return candidate


def sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def load_source(root, expected_pin):
    manifest_path = safe_asset(root, 'manifest.json')
    try:
        manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    except (OSError, UnicodeError, ValueError) as error:
        raise PackageError('Manifest is not valid UTF-8 JSON') from error
    if not isinstance(manifest, dict) or type(manifest.get('version')) is not int or manifest['version'] != 1:
        raise PackageError('Manifest version must be 1')
    sources = manifest.get('sources')
    if not isinstance(sources, list) or len(sources) != 1 or not isinstance(sources[0], dict):
        raise PackageError('Manifest must describe exactly one bundled Catalog source')
    source = sources[0]
    if source.get('url') != SOURCE_URL or source.get('branch') != SOURCE_BRANCH:
        raise PackageError('Manifest source URL or branch does not match the managed Catalog')
    if not isinstance(source.get('pinnedCommit'), str) or not FULL_SHA.fullmatch(source['pinnedCommit']):
        raise PackageError('Manifest pin must be a full lowercase Git commit SHA')
    if source['pinnedCommit'] != expected_pin:
        raise PackageError('Manifest pin does not match the expected release commit')
    if not isinstance(source.get('sha256'), str) or not SHA256.fullmatch(source['sha256']):
        raise PackageError('Manifest bundle SHA-256 is invalid')
    # Keep the release's required revisions explicit; an edited manifest cannot
    # weaken source completeness by silently removing a required template.
    if source.get('requiredTemplates') != REQUIRED_TEMPLATES:
        raise PackageError('Manifest requiredTemplates do not match the release requirements')
    safe_asset(root, source.get('bundle'))
    return source


def verify_docker_source(source, dockerfile=None):
    """Bind the managed source to defaults in the production final stage."""
    text = Path(dockerfile or RELEASE_DOCKERFILE).read_text(encoding='utf-8')
    stages = list(re.finditer(r'(?im)^FROM[ \t]+[^\r\n]+', text))
    if not stages:
        raise PackageError('Release Dockerfile has no final stage')
    final = re.sub(r'\\\r?\n', ' ', text[stages[-1].end():])
    defaults = {name: [] for name in (
        'CATTLE_CATALOG_URL', 'DEFAULT_CATTLE_CATALOG_URL', 'PASTURESTACK_CATALOG_COMMIT',
    )}
    for match in re.finditer(r'(?im)^ENV[ \t]+([^\r\n]+)', final):
        for assignment in shlex.split(match[1]):
            name, separator, value = assignment.partition('=')
            if separator and name in defaults:
                defaults[name].append(value)
    for name, values in defaults.items():
        if len(values) != 1:
            raise PackageError('Release Dockerfile must declare ' + name + ' exactly once in the final stage')
    if defaults['PASTURESTACK_CATALOG_COMMIT'][0] != source['pinnedCommit']:
        raise PackageError('Release Dockerfile PASTURESTACK_CATALOG_COMMIT differs from the bundled source')
    expected = {key: source[key] for key in ('url', 'branch', 'pinnedCommit')}
    for name in ('CATTLE_CATALOG_URL', 'DEFAULT_CATTLE_CATALOG_URL'):
        try:
            configured = json.loads(defaults[name][0])['catalogs']['pasturestack']
            actual = {key: configured[key] for key in expected}
        except (ValueError, TypeError, KeyError) as error:
            raise PackageError('Release Dockerfile ' + name + ' is not an explicit managed Catalog source') from error
        if actual != expected:
            raise PackageError('Release Dockerfile ' + name + ' URL, branch or pin differs from the bundled source')


def source_tree(repo, pin):
    entries = {}
    for record in git(repo, 'ls-tree', '-r', '-z', '--full-tree', pin).split(b'\0'):
        if not record:
            continue
        metadata, name = record.split(b'\t', 1)
        mode, kind, object_id = metadata.decode('ascii').split(' ')
        entries[name.decode('utf-8')] = (mode, kind, object_id)
    return entries


def verify_source_files(repo, pin):
    entries = source_tree(repo, pin)

    def regular_blob(path):
        entry = entries.get(path)
        return (entry is not None and entry[0] in ('100644', '100755') and
                entry[1] == 'blob' and int(git(repo, 'cat-file', '-s', entry[2])) > 0)

    for template in REQUIRED_TEMPLATES:
        folder = 'infra-templates/' + template['name']
        version = folder + '/' + str(template['revision'])
        for path in (folder + '/config.yml', version + '/rancher-compose.yml'):
            if not regular_blob(path):
                raise PackageError('Required Catalog source file is missing or invalid: ' + path)
        if not any(regular_blob(version + '/' + name) for name in ('docker-compose.yml', 'docker-compose.yml.tpl')):
            raise PackageError('Required Catalog compose source is missing or invalid: ' + version)
    if not regular_blob(LICENSE_PATH):
        raise PackageError('Required Catalog license source is missing or invalid: ' + LICENSE_PATH)
    return git(repo, 'show', pin + ':' + LICENSE_PATH)


def sources_text(source):
    return (
        'Bundled PastureStack Catalog source\n'
        'Source URL: ' + source['url'] + '\n'
        'Source branch: ' + source['branch'] + '\n'
        'Source commit: ' + source['pinnedCommit'] + '\n'
        'Bundle: ' + source['bundle'] + '\n'
        'Bundle SHA-256: ' + source['sha256'] + '\n'
        'Bundle ref: ' + BUNDLE_REF + '\n'
        'License: MIT\n'
        'License source: https://github.com/PastureStack/catalog-templates/blob/' +
        source['pinnedCommit'] + '/' + LICENSE_PATH + '\n'
        'License file: ' + LICENSE_PATH + '\n'
        '\nThe bundle contains only this ref and its complete reachable Git history.\n'
        'It has no prerequisites, local object alternates, or network dependency.\n'
        '\nRegenerate from a trusted local bare repository using Python and Git:\n'
        '  python3 scripts/package-catalog-source.py --source-repo LOCAL_BARE_REPOSITORY\n'
        'The helper imports only the release commit into an independent bare\n'
        'repository, checks the complete object graph and required source files,\n'
        'and verifies the finished bundle before replacing these assets.\n'
        '\nVerify the tracked package offline, without the original repository:\n'
        '  python3 scripts/package-catalog-source.py --verify\n'
        'Run the focused package regression tests:\n'
        '  python3 scripts/test-bundled-catalog-source.py\n'
    )


def verify_package(root, expected_pin=SOURCE_PIN):
    root = Path(root)
    source = load_source(root, expected_pin)
    bundle = safe_asset(root, source['bundle'])
    if sha256(bundle) != source['sha256']:
        raise PackageError('Bundle SHA-256 does not match the manifest')
    heads = git(None, 'bundle', 'list-heads', str(bundle.resolve())).decode('ascii').splitlines()
    if heads != [expected_pin + ' ' + BUNDLE_REF]:
        raise PackageError('Bundle must contain only the exact pinned Catalog ref')
    with tempfile.TemporaryDirectory(prefix='pasturestack-catalog-verify-') as temporary:
        repo = Path(temporary) / 'catalog.git'
        git(None, 'init', '--bare', str(repo))
        # An empty repository cannot satisfy external prerequisites. This check
        # therefore rejects incremental bundles that would fail a clean install.
        git(repo, 'bundle', 'verify', str(bundle.resolve()))
        git(repo, 'fetch', '--no-tags', '--no-write-fetch-head', '--', str(bundle.resolve()), BUNDLE_REF + ':' + BUNDLE_REF)
        git(repo, 'symbolic-ref', 'HEAD', BUNDLE_REF)
        git(repo, 'fsck', '--full', '--strict', '--no-reflogs')
        if git(repo, 'rev-parse', BUNDLE_REF + '^{commit}').decode('ascii').strip() != expected_pin:
            raise PackageError('Imported Catalog commit does not match the release pin')
        license_data = verify_source_files(repo, expected_pin)
    if safe_asset(root, LICENSE_PATH).read_bytes() != license_data:
        raise PackageError('Packaged license differs from the exact pinned source')
    if safe_asset(root, 'SOURCES.txt').read_text(encoding='utf-8') != sources_text(source):
        raise PackageError('SOURCES.txt does not describe the exact bundled source')
    return source


def package_source(source_repo, output_dir, pin=SOURCE_PIN):
    if not FULL_SHA.fullmatch(pin):
        raise PackageError('Release pin must be a full lowercase Git commit SHA')
    source_repo = Path(source_repo).resolve(strict=True)
    if not source_repo.is_dir() or git(source_repo, 'rev-parse', '--is-bare-repository').strip() != b'true':
        raise PackageError('Source must be an existing local bare Git repository')
    with tempfile.TemporaryDirectory(prefix='pasturestack-catalog-package-') as temporary:
        staging = Path(temporary)
        repo = staging / 'catalog.git'
        assets = staging / 'assets'
        (assets / 'LICENSES').mkdir(parents=True)
        git(None, 'init', '--bare', str(repo))
        # Fetch one explicit commit into an independent repository. Never use
        # --all, alternates or shared clones, which can retain unrelated refs or
        # make the published bundle depend on a developer's repository.
        git(repo, 'fetch', '--no-tags', '--no-write-fetch-head', '--', str(source_repo), pin + ':' + BUNDLE_REF)
        git(repo, 'symbolic-ref', 'HEAD', BUNDLE_REF)
        git(repo, 'fsck', '--full', '--strict', '--no-reflogs')
        license_data = verify_source_files(repo, pin)
        git(repo, 'bundle', 'create', str(assets / BUNDLE_NAME), BUNDLE_REF)
        source = {
            'url': SOURCE_URL, 'branch': SOURCE_BRANCH, 'pinnedCommit': pin,
            'bundle': BUNDLE_NAME, 'sha256': sha256(assets / BUNDLE_NAME),
            'requiredTemplates': REQUIRED_TEMPLATES,
        }
        (assets / 'manifest.json').write_text(
            json.dumps({'version': 1, 'sources': [source]}, indent=2) + '\n', encoding='utf-8', newline='\n',
        )
        (assets / LICENSE_PATH).write_bytes(license_data)
        (assets / 'SOURCES.txt').write_text(sources_text(source), encoding='utf-8', newline='\n')
        verify_package(assets, pin)
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        # Publish only verified assets, with the manifest last. Each destination
        # is replaced rather than followed if an old file is a symlink.
        for name in (BUNDLE_NAME, LICENSE_PATH, 'SOURCES.txt', 'manifest.json'):
            destination = output_dir / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            if destination.parent.is_symlink():
                raise PackageError('Output asset directory must not be a symlink')
            with tempfile.NamedTemporaryFile(dir=destination.parent, prefix='.catalog-', delete=False) as pending:
                pending_path = Path(pending.name)
                try:
                    with (assets / name).open('rb') as stream:
                        shutil.copyfileobj(stream, pending)
                except BaseException:
                    pending_path.unlink(missing_ok=True)
                    raise
            try:
                os.replace(pending_path, destination)
            finally:
                pending_path.unlink(missing_ok=True)
    return source


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--verify', action='store_true', help='Verify the tracked assets without the original repository or network')
    mode.add_argument('--source-repo', type=Path, help='Existing local bare repository used to regenerate the assets')
    parser.add_argument('--output-dir', type=Path, default=DEFAULT_OUTPUT, help='Catalog asset directory (default: server/catalog-sources)')
    parser.add_argument('--pin', default=SOURCE_PIN, help='Expected full source commit (defaults to the reviewed release pin)')
    arguments = parser.parse_args(argv)
    try:
        if not FULL_SHA.fullmatch(arguments.pin):
            raise PackageError('Release pin must be a full lowercase Git commit SHA')
        if arguments.verify:
            if arguments.output_dir.resolve() == DEFAULT_OUTPUT.resolve():
                # Fail before bundle import or a full image build if a future
                # release changes the Docker defaults without updating assets.
                verify_docker_source(load_source(arguments.output_dir, arguments.pin))
            source = verify_package(arguments.output_dir, arguments.pin)
        else:
            source = package_source(arguments.source_repo, arguments.output_dir, arguments.pin)
    except (PackageError, OSError, UnicodeError, ValueError) as error:
        print('CATALOG_SOURCE_BUNDLE_INVALID: ' + str(error), file=sys.stderr)
        return 1
    print('CATALOG_SOURCE_BUNDLE_OK commit=' + source['pinnedCommit'] + ' sha256=' + source['sha256'])
    return 0


if __name__ == '__main__':
    sys.exit(main())

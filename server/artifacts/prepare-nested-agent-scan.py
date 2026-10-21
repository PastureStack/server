#!/usr/bin/env python3
"""Qualify active agent bytes from the final rootfs, without executing them."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tarfile
import zipfile


def need(ok, code):
    if not ok:
        raise ValueError(code)


def defaults(recipe):
    values = {}
    for name, value in re.findall(r'^ARG ([A-Z0-9_]+)=(.*)$', recipe, re.M):
        need(name not in values or values[name] == value, 'CONFLICTING_RECIPE_DEFAULT')
        values[name] = value
    return values


def digest(data):
    return hashlib.sha256(data).hexdigest()


def member_bytes(archive, name, windows):
    if windows:
        with zipfile.ZipFile(archive) as stream:
            need(set(stream.namelist()) == {'pasturestack/', 'pasturestack/node-agent.exe',
                 'pasturestack/startup_node-agent.ps1'} and len(stream.namelist()) == 3,
                 'EXACT_WINDOWS_PACKAGE_LAYOUT_REQUIRED')
            need(stream.namelist().count(name) == 1, 'UNIQUE_BINARY_MEMBER_REQUIRED')
            item = stream.getinfo(name)
            need(not item.is_dir() and item.file_size <= 32 * 1024 * 1024, 'BOUNDED_BINARY_REQUIRED')
            return stream.read(item)
    with tarfile.open(archive, 'r:gz') as stream:
        items = [item for item in stream if item.name == name]
        need(len(items) == 1 and items[0].isfile() and items[0].size <= 32 * 1024 * 1024,
             'UNIQUE_REGULAR_BINARY_MEMBER_REQUIRED')
        return stream.extractfile(items[0]).read()


def metadata(path, source, windows):
    # go version -m reads executable metadata; it does not run the payload.
    text = subprocess.check_output(['go', 'version', '-m', str(path)], text=True)
    need(text.splitlines()[0].split()[-1] == 'go1.27.3', 'FIXED_GO_COMPILER_REQUIRED')
    fields = {line.strip().split('\t', 1)[1] for line in text.splitlines()
              if line.strip().startswith('build\t')}
    for field in ('CGO_ENABLED=0', 'GOARCH=amd64', 'vcs.modified=false',
                  'vcs.revision=' + source, 'GOOS=' + ('windows' if windows else 'linux')):
        need(field in fields, 'EXACT_BINARY_PRODUCER_METADATA_REQUIRED')


def prepare(rootfs, recipe, output):
    rootfs = rootfs.resolve(strict=True)
    pins = defaults(recipe)
    expected_archives = {'host-api-' + pins['HOST_API_VERSION'] + '.tar.gz',
                         'node-agent-' + pins['NODE_AGENT_VERSION'] + '.tar.gz',
                         'node-agent-' + pins['NODE_AGENT_VERSION'] + '-windows-amd64.zip'}
    actual_archives = {path.name for path in (rootfs / 'usr/share/cattle/artifacts').iterdir()
                       if re.fullmatch(r'(host-api|node-agent)-[0-9]+\.[0-9]+\.[0-9]+(\.tar\.gz|-windows-amd64\.zip)', path.name)}
    need(actual_archives == expected_archives, 'ONLY_ACTIVE_AGENT_BUNDLES_REQUIRED')
    need(not output.exists(), 'NEW_PRIVATE_OUTPUT_REQUIRED')
    output.mkdir(mode=0o700)
    records = []
    for component, prefix, windows in (('host-api', 'HOST_API', False),
                                       ('node-agent', 'NODE_AGENT', False),
                                       ('node-agent', 'NODE_AGENT', True)):
        version = pins[prefix + '_VERSION']
        source = pins[prefix + '_COMMIT']
        need(re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', version) and
             re.fullmatch(r'[0-9a-f]{40}', source), 'EXACT_NUMERIC_VERSION_AND_SOURCE_REQUIRED')
        suffix = '-windows-amd64.zip' if windows else '.tar.gz'
        archive = rootfs / 'usr/share/cattle/artifacts' / (component + '-' + version + suffix)
        need(archive.is_file() and not archive.is_symlink() and archive.resolve().is_relative_to(rootfs),
             'REGULAR_ROOTFS_ARCHIVE_REQUIRED')
        need(archive.stat().st_size <= 64 * 1024 * 1024, 'BOUNDED_ARCHIVE_REQUIRED')
        key = prefix + ('_WINDOWS' if windows else '')
        archive_sha = digest(archive.read_bytes())
        need(archive_sha == pins[key + '_ARCHIVE_SHA256'], 'ARCHIVE_SHA256_MISMATCH')
        member = 'pasturestack/node-agent.exe' if windows else pins[prefix + '_PACKAGE_ID'] + '/bin/' + component
        binary = member_bytes(archive, member, windows)
        binary_sha = digest(binary)
        need(binary_sha == pins[key + '_BINARY_SHA256'], 'BINARY_SHA256_MISMATCH')
        startup = 'pasturestack/startup_node-agent.ps1' if windows else pins[prefix + '_PACKAGE_ID'] + '/apply.sh'
        need(digest(member_bytes(archive, startup, windows)) ==
             pins[key + ('_STARTUP_SHA256' if windows else '_APPLY_SHA256')], 'INSTALLER_SHA256_MISMATCH')
        target = output / (component + ('-windows-amd64.exe' if windows else '-linux-amd64'))
        with target.open('xb') as stream:
            stream.write(binary)
        # Trivy's Go analyzer requires executable mode even though neither this
        # qualifier nor the scanner executes the payload. Keep it owner-only.
        target.chmod(0o700)
        metadata(target, source, windows)
        records.append({'component': component, 'platform': 'windows/amd64' if windows else 'linux/amd64',
                        'version': version, 'source': source, 'compiler': 'go1.27.3',
                        'archive': archive.name, 'archiveSha256': archive_sha,
                        'binary': target.name, 'binarySha256': binary_sha, 'bytes': len(binary),
                        'payloadExecuted': False})
    return {'schemaVersion': 1, 'status': 'PASS_EXACT_FINAL_ROOTFS_PAYLOADS',
            'records': records, 'payloadCount': 3, 'runtimeWrites': 0}


if __name__ == '__main__':
    need(len(sys.argv) == 4, 'USAGE_ROOTFS_RECIPE_NEW_OUTPUT')
    result = prepare(Path(sys.argv[1]), Path(sys.argv[2]).read_text(encoding='utf-8'), Path(sys.argv[3]))
    print(json.dumps(result, sort_keys=True, indent=2))

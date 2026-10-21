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


def member_bytes(archive, name, windows, cni=False):
    if windows:
        with zipfile.ZipFile(archive) as stream:
            layout = ({'rancher/', 'rancher/per-host-subnet.exe', 'rancher/startup_per-host-subnet.ps1'}
                      if cni else {'pasturestack/', 'pasturestack/node-agent.exe',
                                   'pasturestack/startup_node-agent.ps1'})
            need(set(stream.namelist()) == layout and len(stream.namelist()) == 3,
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


def cni_metadata(path):
    """Only the producer's explicit buildvcs=false CNI contract; never a general fallback."""
    text = subprocess.check_output(['go', 'version', '-m', str(path)], text=True)
    need(text.splitlines()[0].split()[-1] == 'go1.27.3', 'FIXED_GO_COMPILER_REQUIRED')
    fields = {line.strip().split('\t', 1)[1] for line in text.splitlines()
              if line.strip().startswith('build\t')}
    for field in ('CGO_ENABLED=0', 'GOARCH=amd64', 'GOOS=windows', 'GOAMD64=v1'):
        need(field in fields, 'EXACT_CNI_METADATA_REQUIRED')
    need(not any(field.startswith(('vcs=', 'vcs.')) for field in fields),
         'CNI_PRODUCER_NO_VCS_CONTRACT_REQUIRED')


def cni_payload(rootfs, pins, output):
    version = pins['PER_HOST_SUBNET_VERSION']
    producer = pins['PER_HOST_SUBNET_PRODUCER_COMMIT']
    provenance = pins['PER_HOST_SUBNET_PROVENANCE_SHA256']
    need(version == '0.2.5' and re.fullmatch(r'[0-9a-f]{40}', producer) and
         re.fullmatch(r'[0-9a-f]{64}', provenance), 'FORMAL_CNI_PROVENANCE_PINS_REQUIRED')
    archive = rootfs / 'usr/share/cattle/artifacts' / ('per-host-subnet-' + version + '-windows-amd64.zip')
    need(archive.is_file() and not archive.is_symlink() and archive.resolve().is_relative_to(rootfs),
         'REGULAR_ROOTFS_ARCHIVE_REQUIRED')
    need(archive.stat().st_size <= 64 * 1024 * 1024, 'BOUNDED_ARCHIVE_REQUIRED')
    archive_sha = digest(archive.read_bytes())
    need(archive_sha == pins['PER_HOST_SUBNET_ARCHIVE_SHA256'], 'ARCHIVE_SHA256_MISMATCH')
    binary = member_bytes(archive, 'rancher/per-host-subnet.exe', True, cni=True)
    binary_sha = digest(binary)
    need(binary_sha == pins['PER_HOST_SUBNET_BINARY_SHA256'], 'BINARY_SHA256_MISMATCH')
    startup = member_bytes(archive, 'rancher/startup_per-host-subnet.ps1', True, cni=True)
    need(digest(startup) == pins['PER_HOST_SUBNET_STARTUP_SHA256'], 'INSTALLER_SHA256_MISMATCH')
    pe = int.from_bytes(binary[60:64], 'little')
    need(binary[:2] == b'MZ' and len(binary) >= 64 and pe + 26 <= len(binary) and
         binary[pe:pe+6] == b'PE\0\0\x64\x86' and binary[pe+24:pe+26] == b'\x0b\x02',
         'CNI_PE32_PLUS_AMD64_REQUIRED')
    target = output / 'per-host-subnet-windows-amd64.exe'
    with target.open('xb') as stream:
        stream.write(binary)
    target.chmod(0o700)
    cni_metadata(target)
    # Provenance is the reviewed official CI/readback receipt, not embedded VCS.
    # The formal original-CI receipt binds these pins; this is not a source field.
    return {'component': 'per-host-subnet', 'platform': 'windows/amd64', 'version': version,
            'producerSource': producer, 'provenanceReceiptSha256': provenance,
            'vcsMetadata': 'ABSENT_BY_PRODUCER_BUILDVCS_FALSE_CONTRACT',
            'compiler': 'go1.27.3', 'archive': archive.name, 'archiveSha256': archive_sha,
            'binary': target.name, 'binarySha256': binary_sha, 'bytes': len(binary),
            'payloadExecuted': False}


def prepare(rootfs, recipe, output):
    rootfs = rootfs.resolve(strict=True)
    pins = defaults(recipe)
    expected_archives = {'host-api-' + pins['HOST_API_VERSION'] + '.tar.gz',
                         'node-agent-' + pins['NODE_AGENT_VERSION'] + '.tar.gz',
                         'node-agent-' + pins['NODE_AGENT_VERSION'] + '-windows-amd64.zip',
                         'per-host-subnet-' + pins['PER_HOST_SUBNET_VERSION'] + '-windows-amd64.zip'}
    actual_archives = {path.name for path in (rootfs / 'usr/share/cattle/artifacts').iterdir()
                       if re.fullmatch(r'(?:(host-api|node-agent)-[0-9]+\.[0-9]+\.[0-9]+(\.tar\.gz|-windows-amd64\.zip)|per-host-subnet-[0-9]+\.[0-9]+\.[0-9]+-windows-amd64\.zip)', path.name)}
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
    records.append(cni_payload(rootfs, pins, output))
    return {'schemaVersion': 1, 'status': 'PASS_EXACT_FINAL_ROOTFS_PAYLOADS',
            'records': records, 'payloadCount': 4, 'runtimeWrites': 0}


if __name__ == '__main__':
    # This is a fixed CI stage, not a general-purpose filesystem utility.
    # The workflow selects its owned working directory; callers cannot choose
    # arbitrary read/write destinations through command-line paths.
    need(len(sys.argv) == 1, 'NO_PATH_ARGUMENTS_ACCEPTED')
    recipe = Path(__file__).resolve().parents[1] / 'Dockerfile.web-compose-release'
    workspace = Path.cwd()
    result = prepare(workspace / 'server-rootfs', recipe.read_text(encoding='utf-8'),
                     workspace / 'server-nested-payloads')
    print(json.dumps(result, sort_keys=True, indent=2))

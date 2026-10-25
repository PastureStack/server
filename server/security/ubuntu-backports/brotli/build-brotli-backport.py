#!/usr/bin/env python3
"""Exact official Brotli decoder fix with original Ubuntu package semantics."""
import argparse
import importlib.util
import json
from pathlib import Path
import re
import shlex
import subprocess
import sys
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
sys.dont_write_bytecode = True
SPEC = importlib.util.spec_from_file_location('brotli_source_helpers', HERE.parent / 'source_helpers.py')
H = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(H)
COMMIT = 'b418fa81c48262a86a95332b0bc6d62c30aa78b6'
VERSION = '1.2.0-3build1'
SONAMES = ['libbrotlicommon.so.1', 'libbrotlidec.so.1', 'libbrotlienc.so.1']
BOUNDARY = {'c/dec/decode.c', 'c/include/brotli/decode.h'}


def load_lock(file):
    lock = json.loads(file.read_text(encoding='utf-8'))
    H.require(all(lock.get(k) == v for k, v in {
        'schemaVersion': 1, 'sourcePackage': 'brotli', 'ubuntuSourceVersion': VERSION,
        'customVersion': VERSION + '+pasturestack.1', 'distribution': 'resolute',
        'osVersion': '26.04', 'architecture': 'amd64', 'runtimePackages': ['libbrotli1']}.items()),
        'Unexpected Brotli package/platform boundary')
    H.require(type(lock['sourceDateEpoch']) is int and lock['sourceDateEpoch'] > 0, 'Invalid source date')
    H.require({p['name'] for p in lock['sourceFiles']} == {
        'brotli_1.2.0-3build1.dsc', 'brotli_1.2.0.orig.tar.gz', 'brotli_1.2.0-3build1.debian.tar.xz'}
        and len(lock['sourceFiles']) == 3, 'Wrong Ubuntu source set')
    H.require(len(lock['patches']) == 1 and lock['patches'][0]['commit'] == COMMIT
              and lock['patches'][0]['fixedCves'] == ['CVE-2026-111497'], 'Wrong official security patch')
    H.require(lock['baselineBinary']['name'] == 'libbrotli1_' + VERSION + '_amd64.deb'
              and lock['baselineBinary']['version'] == VERSION, 'Wrong original Ubuntu binary')
    for item in H.inputs(lock):
        H.require(re.fullmatch(r'[A-Za-z0-9._~+-]+', item['name'])
                  and re.fullmatch('[0-9a-f]{64}', item['sha256'])
                  and type(item['size']) is int and 0 < item['size'] < 8 * 1024 * 1024, 'Unsafe/unpinned input')
        url = ('https://github.com/google/brotli/commit/' + COMMIT + '.patch' if item in lock['patches']
               else 'https://archive.ubuntu.com/ubuntu/pool/main/b/brotli/' + item['name'])
        H.require(item['url'] == url, 'Unexpected official source URL')
    H.require(set(lock['baselineSha256']) == set(lock['patchedSha256']) == BOUNDARY,
              'Security patch source boundary changed')
    for group in ['baselineSha256', 'patchedSha256', 'ubuntuPackagingSha256']:
        for name, sha in lock[group].items():
            H.require(not Path(name).is_absolute() and '..' not in Path(name).parts
                      and '\\' not in name and re.fullmatch('[0-9a-f]{64}', sha), 'Unsafe/unpinned source path')
    H.require(lock['buildContract']['requiredSonames'] == SONAMES, 'Wrong ABI contract')
    return lock


def abi(dynamic, symbols, original_dynamic, original_symbols, soname):
    sonames = lambda text: re.findall(r'SONAME.*\[(.+?)\]', text)
    needed = lambda text: sorted(re.findall(r'NEEDED.*\[(.+?)\]', text))
    exports = lambda text: {line.split()[-1] for line in text.splitlines() if line.split()}
    H.require(sonames(dynamic) == sonames(original_dynamic) == [soname], 'Brotli SONAME changed')
    H.require(needed(dynamic) == needed(original_dynamic), 'Brotli runtime dependencies changed')
    H.require(exports(symbols) == exports(original_symbols) and exports(symbols), 'Brotli exported ABI changed')
    return {'soname': soname, 'needed': needed(dynamic), 'exports': len(exports(symbols)), 'status': 'PASS'}


def owning_results(xml, python_log):
    root = ET.fromstring(xml)
    cases = root.findall('.//testcase')
    H.require(len(cases) >= 12 and not root.findall('.//failure') and not root.findall('.//error')
              and not root.findall('.//skipped')
              and all(c.get('status') in (None, 'run') for c in cases), 'Brotli CMake suite failed/skipped/empty')
    counts = re.findall(r'^Ran ([0-9]+) tests? in ', python_log, re.M)
    H.require(len(counts) == 1 and int(counts[0]) > 0 and re.search(r'^OK\s*$', python_log, re.M)
              and not re.search(r'\b(?:skipped|FAILED|ERROR|FAIL)\b', python_log), 'Brotli Python suite failed/skipped/empty')
    return {'status': 'PASS', 'cmakeCases': len(cases), 'pythonCases': int(counts[0]), 'addedSkips': 0}


def verify(lock, source, extracted, work, env, log):
    caches = list(source.glob('obj-*/CMakeCache.txt'))
    H.require(len(caches) == 1, 'Missing/ambiguous original package CMake build')
    build = caches[0].parent
    cmake_log, junit, python_log = work / 'cmake-tests.log', work / 'cmake-tests.xml', work / 'python-tests.log'
    H.run(['ctest', '--test-dir', str(build), '--output-on-failure', '--no-tests=error',
           '--output-junit', str(junit)], source, env, cmake_log)
    modules = list(source.glob('.pybuild/*/build/brotli.py'))
    H.require(len(modules) == 1, 'Missing/ambiguous original Python module build')
    child = dict(env, PYTHONPATH=str(modules[0].parent))
    H.run(['python3', '-m', 'unittest', 'discover', '-s', 'python', '-p', '*_test.py', '-v'], source, child, python_log)
    suites = owning_results(junit.read_text(), python_log.read_text())
    original = work / 'original-package'
    H.run(['dpkg-deb', '--extract', str(work / 'inputs' / lock['baselineBinary']['name']), str(original)], work, env, log)
    controls = []
    library_dir = Path('usr/lib/x86_64-linux-gnu')
    for soname in SONAMES:
        new, old = extracted / library_dir / soname, original / library_dir / soname
        dynamic = H.capture(['readelf', '--dynamic', str(new)], work, env)
        old_dynamic = H.capture(['readelf', '--dynamic', str(old)], work, env)
        nm = ['nm', '--dynamic', '--defined-only', '--extern-only']
        controls.append(abi(dynamic, H.capture(nm + [str(new)], work, env), old_dynamic,
                            H.capture(nm + [str(old)], work, env), soname))
        H.require('GNU_RELRO' in H.capture(['readelf', '--program-headers', str(new)], work, env), 'RELRO regressed')
        now = lambda text: 'BIND_NOW' in text or bool(re.search(r'FLAGS_1.*NOW', text))
        H.require(not now(old_dynamic) or now(dynamic), 'Original BIND_NOW hardening regressed')
    probe = work / 'brotli-roundtrip'
    cc = ['cc', '-std=c11', '-Wall', '-Wextra', '-Werror']
    for name in ['CPPFLAGS', 'CFLAGS', 'LDFLAGS']:
        cc += shlex.split(H.capture(['dpkg-buildflags', '--get', name], work, env))
    libs = extracted / library_dir
    H.run(cc + ['-I' + str(source / 'c/include'), str(HERE / 'roundtrip.c'), '-L' + str(libs),
                '-Wl,-rpath,' + str(libs), '-l:libbrotlienc.so.1', '-l:libbrotlidec.so.1',
                '-l:libbrotlicommon.so.1', '-o', str(probe)], work, env, log)
    result = H.capture([str(probe)], work, dict(env, LD_LIBRARY_PATH=str(libs)))
    H.require(result == 'PASS: 15 valid roundtrips, 45 streaming roundtrips, three linked SONAMEs', 'Packaged valid-input API control failed')
    report = {'status': 'PASS', 'owningSuites': suites, 'abi': controls, 'packageApi': result,
              'runtimeInstalled': False, 'exploitExecuted': False,
              'remediationEvidence': 'Exact official two-file source patch and post-patch hashes; no malformed-stream trigger executed.'}
    receipt = work / 'brotli-tests.json'
    receipt.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    return report, [(p, p.name) for p in [cmake_log, junit, python_log, receipt]]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--validate-lock', action='store_true')
    parser.add_argument('--output-dir', type=Path)
    parser.add_argument('--work-dir', type=Path)
    parser.add_argument('--cache-dir', type=Path)
    parser.add_argument('--jobs', type=int, choices=(2, 4), default=2)
    args = parser.parse_args()
    lock = load_lock(HERE / 'brotli.lock.json')
    if args.validate_lock:
        print('OFFICIAL_SOURCE_LOCK_OK brotli')
        return
    H.require(args.output_dir is not None, '--output-dir is required')
    H.build(args, lock, HERE, verify, ['cc', 'ctest', 'dpkg-buildflags'])


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print('BROTLI_BACKPORT_FAILED: ' + str(error), file=sys.stderr)
        sys.exit(1)

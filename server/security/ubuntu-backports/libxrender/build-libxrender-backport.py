#!/usr/bin/env python3
"""Exact libXrender security backport; preserve Ubuntu packaging and public ABI."""
import importlib.util
import json
from pathlib import Path
import re
import shlex
import subprocess
import sys

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('source_helpers', HERE.parent / 'source_helpers.py')
H = importlib.util.module_from_spec(SPEC)
sys.dont_write_bytecode = True
SPEC.loader.exec_module(H)
COMMITS = ['0564bce5446550c1b1681f3d8a933c20ea1455f7']


def exports(file, work, env):
    return {line.split()[-1].split('@')[0] for line in
            H.capture(['nm', '--dynamic', '--defined-only', str(file)], work, env).splitlines()
            if line.split()}


def check_result(code, output, negative):
    if negative:
        H.require(code == 2 and 'malformed header reached allocation:' in output,
                  'Original-source negative control did not detect the specific vulnerable path')
    else:
        H.require(code == 0 and 'PASS' in output, 'Patched/packaged reply-boundary fixture failed')


def regression(source, extracted, work, env, log):
    archive = source / 'build/src/.libs/libXrender.a'
    H.require(archive.is_file(), 'Original configured static test archive missing')
    cc = ['cc']
    for name in ['CPPFLAGS', 'CFLAGS']:
        cc += shlex.split(H.capture(['dpkg-buildflags', '--get', name], work, env))
    includes = ['-I' + str(source / x) for x in ['build', 'src', 'include', 'include/X11/extensions']]
    links = ['-lX11', '-Wl,--wrap=_XReply', '-Wl,--wrap=calloc']
    fixture = str(HERE / 'reply-boundary.c')
    old_object = work / 'original-Xrender.o'
    H.run(cc + includes + ['-DHAVE_CONFIG_H', '-c', str(work / 'original-Xrender.c'),
                           '-o', str(old_object)], work, env, log)
    executables = []
    for name, objects in [('patched', [str(archive)]), ('original', [str(old_object), str(archive)]),
                          ('packaged', [str(extracted / 'usr/lib/x86_64-linux-gnu/libXrender.so.1')])]:
        file = work / ('reply-' + name)
        H.run(cc + includes + [fixture] + objects + links + ['-o', str(file)], work, env, log)
        executables.append((name, file))
    child = dict(env, LD_LIBRARY_PATH=str(extracted / 'usr/lib/x86_64-linux-gnu'))
    results = []
    for name, file in executables:
        command = ['xvfb-run', '--auto-servernum', '--server-args=-nolisten tcp -screen 0 640x480x24',
                   str(file)] + (['--valid-only'] if name == 'packaged' else [])
        result = subprocess.run(command, cwd=work, env=child, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True, timeout=30)
        check_result(result.returncode, result.stdout, name == 'original')
        results.append({'test': name, 'exitCode': result.returncode, 'output': result.stdout,
                        'status': 'EXPECTED_FAILURE' if name == 'original' else 'PASS'})
    report = work / 'reply-boundary.json'
    report.write_text(json.dumps(results, indent=2) + '\n', encoding='utf-8')
    return results, [(report, report.name)]


def verify(lock, source, extracted, work, env, log):
    # This upstream has no tests: preserve its normal check target, then require
    # the additional native negative/positive boundary fixtures instead of claiming
    # zero upstream cases proved the vulnerability fixed.
    check_log = work / 'owning-check.log'
    H.run(['make', '-C', 'build', 'check'], source, env, check_log)
    H.require(not list(source.rglob('*.trs')), 'Unexpected upstream test manifest; reassess full suite')
    baseline_dir = work / 'original-package'
    baseline = work / 'inputs' / lock['baselineBinary']['name']
    for field, expected in [('Package', 'libxrender1'), ('Version', '1:0.9.12-1build1'),
                            ('Architecture', 'amd64')]:
        H.require(H.capture(['dpkg-deb', '--field', str(baseline), field], work, env) == expected,
                  'Original Ubuntu ABI baseline identity mismatch')
    H.run(['dpkg-deb', '--extract', str(baseline), str(baseline_dir)], work, env, log)
    library = extracted / 'usr/lib/x86_64-linux-gnu/libXrender.so.1'
    old = baseline_dir / 'usr/lib/x86_64-linux-gnu/libXrender.so.1'
    H.require(exports(library, work, env) == exports(old, work, env),
              'Original Ubuntu exported ABI changed')
    dynamic = H.capture(['readelf', '--dynamic', str(library)], work, env)
    old_dynamic = H.capture(['readelf', '--dynamic', str(old)], work, env)
    needed = lambda text: set(re.findall(r'NEEDED.*\[(.+?)\]', text))
    H.require('[libXrender.so.1]' in dynamic and needed(dynamic) == needed(old_dynamic),
              'SONAME/original runtime dependencies changed')
    # The original source has no Debian symbols file; compare the exact original
    # Ubuntu binary exports and NEEDED entries instead.
    headers = H.capture(['readelf', '--program-headers', str(library)], work, env)
    H.require('GNU_RELRO' in headers and ('BIND_NOW' in dynamic or re.search(r'FLAGS_1.*NOW', dynamic)),
              'Original Ubuntu hardening is missing')
    cases, evidence = regression(source, extracted, work, env, log)
    return {'owningCheck': 'PASS', 'upstreamDefinedTestCases': 0,
            'originalUbuntuAbiAndNeeded': 'PASS', 'originalBinarySha256': lock['baselineBinary']['sha256'],
            'replyBoundaryCases': cases, 'runtimeInstalled': False}, \
           [(check_log, check_log.name)] + evidence


if __name__ == '__main__':
    try:
        H.entry(HERE, 'libxrender', '1:0.9.12-1build1', COMMITS, verify,
                ['cc', 'dpkg-buildflags', 'xvfb-run', 'Xvfb', 'xauth'])
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print('LIBXRENDER_BACKPORT_FAILED: ' + str(error), file=sys.stderr)
        sys.exit(1)

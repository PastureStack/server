#!/usr/bin/env python3
"""Exact p11-kit RPC security backports, with unchanged Ubuntu owning tests."""
from collections import Counter
import ctypes
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sys

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('source_helpers', HERE.parent / 'source_helpers.py')
H = importlib.util.module_from_spec(SPEC)
sys.dont_write_bytecode = True
SPEC.loader.exec_module(H)
COMMITS = ['0eedd4ddd7c924f9cbb4ac496b3fda699435c3cf', '3e64244e538550c6a7fcf826fa8c50a4604416dc']
EXTRA_TOOLS = ['p11tool']


def require_tap_ok(text, case):
    pattern = (r'^(not ok|ok)[ \t]+[0-9]+[ \t]+(?:-[ \t]+)?' + re.escape(case) +
               r'((?:[ \t]+.*)?)$')
    results = [(state, suffix.strip()) for state, suffix in re.findall(pattern, text, re.M)]
    H.require(results == [('ok', '')],
              'Official regression case lacks a single unqualified TAP ok: ' + case)


def configured_test_logs(source, env):
    # Query the original generated Makefile without running a test target.
    # TEST_LOGS intentionally retains any duplicate entries used by Automake's
    # summary; p11-kit 0.26.2 lists test-oid through two source fragments.
    return H.capture(['make', '--no-print-directory', '--eval',
                      "pasturestack-print-test-logs:;@printf '%s\\n' $(TEST_LOGS)",
                      'pasturestack-print-test-logs'], source, env).splitlines()


def full_suite(source, test_logs):
    logs = list(source.rglob('test-suite.log'))
    H.require(len(logs) == 1, 'Missing/ambiguous full owning test-suite log')
    summary = logs[0].read_text(encoding='utf-8', errors='replace')
    states = ['PASS', 'SKIP', 'XFAIL', 'FAIL', 'XPASS', 'ERROR']
    pairs = re.findall(r'^# (TOTAL|PASS|SKIP|XFAIL|FAIL|XPASS|ERROR):[ \t]*([0-9]+)[ \t]*$',
                       summary, re.M)
    H.require(len(pairs) == 7 and {key for key, _ in pairs} == {'TOTAL', *states},
              'Missing or ambiguous owning-suite summary counts')
    counts = {key: int(value) for key, value in pairs}
    H.require(test_logs and all(not Path(name).is_absolute() and '..' not in Path(name).parts
                              and Path(name).suffix == '.log' for name in test_logs),
              'Missing or unsafe configured TEST_LOGS manifest')
    occurrences = Counter(source / Path(name).with_suffix('.trs') for name in test_logs)
    reports = list(occurrences)
    H.require(set(reports) == set(source.rglob('*.trs')),
              'Configured TEST_LOGS and native TRS files differ')
    H.require(reports and counts['TOTAL'] > 0, 'Complete owning suite has no testcase results')
    receipts, evidence = [], [(logs[0], 'test-suite.log')]
    names, observed, unique = set(), Counter(), Counter()
    for report in reports:
        text = report.read_text(encoding='utf-8')
        # tap-driver writes one result per TAP testcase, not one per .trs file.
        result_lines = [line for line in text.splitlines() if line.startswith(':test-result:')]
        matches = [re.fullmatch(r':test-result: (PASS|SKIP|XFAIL|FAIL|XPASS|ERROR)', line)
                   for line in result_lines]
        H.require(matches and all(matches), 'Missing or invalid TRS testcase result: ' + str(report))
        H.require(re.findall(r'^:global-test-result: (\S+)$', text, re.M) == ['PASS'],
                  'Owning TRS global result did not PASS: ' + str(report))
        case_counts = Counter(match[1] for match in matches)
        unique.update(case_counts)
        observed.update({state: count * occurrences[report] for state, count in case_counts.items()})
        relative = report.relative_to(source).as_posix()
        names.add(report.stem)
        receipts.append({'path': relative, 'status': 'PASS', 'sha256': H.digest(report),
                         'caseCounts': {state: case_counts[state] for state in states},
                         'summaryOccurrences': occurrences[report]})
        for suffix in ['.trs', '.log']:
            file = report.with_suffix(suffix)
            H.require(file.is_file(), 'Owning test output missing')
            evidence.append((file, file.relative_to(source).as_posix().replace('/', '__')))
    H.require(sum(observed.values()) == counts['TOTAL']
              and all(observed[state] == counts[state] for state in states),
              'TRS testcase totals/states do not match owning-suite summary')
    H.require(counts['PASS'] == counts['TOTAL'] and all(counts[state] == 0 for state in states[1:]),
              'Complete owning suite must PASS without skips')
    H.require({'test-rpc', 'test-rpc-message'} <= names, 'RPC owning regression suites missing')
    # Verify the new upstream cases actually ran, rather than only trusting a suite name.
    rpc = next(p for p in reports if p.stem == 'test-rpc').with_suffix('.log').read_text(encoding='utf-8')
    message = next(p for p in reports if p.stem == 'test-rpc-message').with_suffix('.log').read_text(encoding='utf-8')
    require_tap_ok(rpc, '/rpc3/recursion-limit')
    require_tap_ok(message, '/rpc-message/attribute-recursion-limit')
    return {'status': 'PASS', 'counts': counts, 'receipts': receipts,
            'configuredTestLogs': test_logs, 'uniqueCaseTotal': sum(unique.values()),
            'uniqueCaseCounts': {state: unique[state] for state in states},
            'officialRpcRecursionCases': 'PASS', 'addedSkips': 0}, evidence


def verify(lock, source, extracted, work, env, log):
    tests, evidence = full_suite(source, configured_test_logs(source, env))
    library = extracted / 'usr/lib/x86_64-linux-gnu/libp11-kit.so.0'
    abi = H.verify_abi(library, 'libp11-kit.so.0', source / 'debian/libp11-kit0.symbols', work, env)
    for name in ['usr/bin/p11-kit', 'usr/libexec/p11-kit/p11-kit-remote',
                 'usr/libexec/p11-kit/p11-kit-server',
                 'usr/lib/x86_64-linux-gnu/pkcs11/p11-kit-trust.so']:
        H.require((extracted / name).is_file(), 'Original runtime entry point missing: ' + name)
    child = dict(env, LD_LIBRARY_PATH=str(library.parent))
    help_text = H.capture([str(extracted / 'usr/bin/p11-kit'), '--help'], work, child)
    H.require('list-modules' in help_text, 'Packaged CLI help contract failed')
    api = ctypes.CDLL(str(library))
    count, table = ctypes.c_ulong(0), ctypes.c_void_p()
    api.C_GetInterfaceList.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_ulong)]
    api.C_GetInterfaceList.restype = ctypes.c_ulong
    api.C_GetFunctionList.argtypes = [ctypes.POINTER(ctypes.c_void_p)]
    api.C_GetFunctionList.restype = ctypes.c_ulong
    H.require(api.C_GetInterfaceList(None, ctypes.byref(count)) == 0 and count.value > 0
              and api.C_GetFunctionList(ctypes.byref(table)) == 0 and table.value,
              'Packaged PKCS11 public interface smoke failed')
    return {'fullOwningSuite': tests, 'abi': abi, 'packagedCliAndPkcs11': 'PASS',
            'cve18938ArchitectureCaveat': 'Officially32-bit only; nativeamd64 suite does not claim32-bit trigger coverage.'}, evidence


if __name__ == '__main__':
    try:
        H.entry(HERE, 'p11-kit', '0.26.2-2', COMMITS, verify, EXTRA_TOOLS)
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print('P11_KIT_BACKPORT_FAILED: ' + str(error), file=sys.stderr)
        sys.exit(1)

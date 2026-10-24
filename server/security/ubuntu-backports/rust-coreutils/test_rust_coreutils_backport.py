"""Network-free guards for source identity, unsuppressed tests and GID QA."""
import copy
import importlib.util
import json
import os
import shlex
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('rust_backport', HERE / 'build-rust-coreutils-backport.py')
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)


class RustBackport(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='rust-backport-contract-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.lock = M.load_lock(HERE / 'rust-coreutils.lock.json')

    def test_lock_rejects_widened_scope_unpinned_sources_and_wrong_identity(self):
        for field, bad in [('architecture', 'arm64'), ('ubuntuSourceVersion', '0.12.0'),
                           ('runtimePackages', ['coreutils']), ('sourceDateEpoch', True)]:
            with self.subTest(field=field):
                altered = copy.deepcopy(self.lock)
                altered[field] = bad
                file = self.root / 'bad.json'
                file.write_text(json.dumps(altered), encoding='utf-8')
                with self.assertRaises(ValueError): M.load_lock(file)
        for bad in ['../outside.patch', 'http://example.invalid/patch', 'bad-hash']:
            altered = copy.deepcopy(self.lock)
            key = 'name' if bad.startswith('..') else ('url' if bad.startswith('http') else 'sha256')
            altered['patches'][0][key] = bad
            file.write_text(json.dumps(altered), encoding='utf-8')
            with self.assertRaises(ValueError): M.load_lock(file)

    def test_poisoned_cache_is_not_silently_refetched(self):
        cache, inputs = self.root / 'cache', self.root / 'inputs'
        cache.mkdir(); inputs.mkdir()
        item = self.lock['patches'][0]
        (cache / item['name']).write_bytes(b'poison')
        with mock.patch.object(M.urllib.request, 'build_opener') as opener:
            with self.assertRaises(ValueError): M.download(item, inputs, cache)
            opener.assert_not_called()

    def test_source_control_manifest_must_match_all_three_pinned_archives(self):
        entries = [x for x in self.lock['sourceFiles'] if not x['name'].endswith('.dsc')]
        text = ('Format: 3.0 (quilt)\nSource: rust-coreutils\nVersion: ' + M.VERSION +
                '\nChecksums-Sha256:\n' + ''.join(' ' + x['sha256'] + ' ' + str(x['size']) +
                ' ' + x['name'] + '\n' for x in entries))
        file = self.root / ('rust-coreutils_' + M.VERSION + '.dsc')
        file.write_text(text, encoding='utf-8')
        M.verify_source_control(self.lock, self.root)
        file.write_text(text.replace(entries[0]['sha256'], '0' * 64), encoding='utf-8')
        with self.assertRaises(ValueError): M.verify_source_control(self.lock, self.root)

    def test_patch_cannot_modify_packaging_or_other_utilities(self):
        file = self.root / 'patch'
        text = 'From ' + M.COMMIT + ' Mon Sep 17 00:00:00 2001\n' + ''.join(
            'diff --git a/' + p + ' b/' + p + '\n' for p in M.PATHS)
        file.write_text(text, encoding='utf-8')
        M.verify_patch(self.lock['patches'][0], file)
        file.write_text(text + 'diff --git a/debian/rules b/debian/rules\n', encoding='utf-8')
        with self.assertRaises(ValueError): M.verify_patch(self.lock['patches'][0], file)

    def test_build_environment_discards_test_and_compiler_overrides(self):
        with mock.patch.dict(os.environ, {'DEB_BUILD_OPTIONS': 'nocheck', 'CARGOFLAGS': '--test id',
                                         'RUSTFLAGS': '-C opt-level=0', 'TESTS': 'id', 'CI': 'true',
                                         'TEST_NO_FAIL_FAST': 'stdout', '_PS_TEST_ARGS': '--ignored'}):
            env = M.build_environment(self.lock, 2, self.root)
        self.assertEqual('parallel=2', env['DEB_BUILD_OPTIONS'])
        self.assertEqual('', env['DEB_BUILD_MAINT_OPTIONS'])
        self.assertEqual('true', env['CARGO_NET_OFFLINE'])
        self.assertEqual('true', env['CI'])
        self.assertTrue(all(x not in env for x in ['CARGOFLAGS', 'RUSTFLAGS', 'TESTS', 'SKIP_UTILS',
                                                   'TEST_NO_FAIL_FAST', '_PS_TEST_ARGS']))
        for marker in ['', 'false', '1']:
            with mock.patch.dict(os.environ, {'CI': marker}):
                self.assertNotIn('CI', M.build_environment(self.lock, 2, self.root))

    def test_root_cannot_accidentally_run_the_build_or_full_suite(self):
        with mock.patch.object(Path, 'read_text', return_value='ID=ubuntu\nVERSION_ID="26.04"\n'), \
                mock.patch.object(M.os, 'geteuid', create=True, return_value=0):
            with self.assertRaisesRegex(ValueError, 'must run as non-root'):
                M.build(None, self.lock)

    def contract_fixture(self):
        patterns = list(M.UBUNTU_EXCLUSIONS)
        patterns[11] += ' stdout'
        args = '-- --skip ' + ' \\\n--skip '.join(patterns)
        return 'override_dh_auto_test:\n TEST_NO_FAIL_FAST="' + args + '"\n test||true\n' + \
               'override_dh_auto_install:\n'

    def contract(self):
        rules = self.root / 'rules'
        rules.write_text(self.contract_fixture(), encoding='utf-8')
        with mock.patch.object(M, 'digest', return_value=M.RULES_SHA256):
            return M.ubuntu_test_contract(rules)

    def test_original_contract_requires_pinned_rules_and_exact17_patterns(self):
        rules = self.root / 'rules'
        rules.write_text(self.contract_fixture(), encoding='utf-8')
        with self.assertRaises(ValueError): M.ubuntu_test_contract(rules)
        contract = self.contract()
        self.assertEqual(17, len(contract['excludedPatterns']))
        self.assertEqual(['stdout'], contract['removedLegacyPositionalFilters'])
        self.assertTrue(contract['removedFailureSwallowing'])
        self.assertFalse(any(pattern in name for pattern in contract['excludedPatterns']
                             for name in M.ID_TESTS))

    def test_contract_rejects_new_missing_reordered_id_or_extra_filters(self):
        original = self.contract_fixture()
        first, second = M.UBUNTU_EXCLUSIONS[:2]
        for bad in [original.replace(first, 'test_id::'), original.replace('--skip ' + first, ''),
                    original.replace(first, 'marker').replace(second, first).replace('marker', second),
                    original.replace(' stdout', ''), original.replace(' stdout', ' stdout --ignored'),
                    original.replace('test||true', 'test')]:
            rules = self.root / 'rules'
            rules.write_text(bad, encoding='utf-8')
            with mock.patch.object(M, 'digest', return_value=M.RULES_SHA256):
                with self.assertRaises(ValueError): M.ubuntu_test_contract(rules)

    def test_command_contains_only_owner_exclusions_without_positional_filter_or_swallow(self):
        contract = self.contract()
        tokens = shlex.split(M.ubuntu_test_arguments(contract))
        self.assertEqual(['--no-fail-fast', '--'], tokens[:2])
        self.assertEqual(17, tokens.count('--skip'))
        self.assertEqual(M.UBUNTU_EXCLUSIONS, tokens[3::2])
        self.assertNotIn('stdout', tokens)
        self.assertNotIn('||true', tokens)
        altered = copy.deepcopy(contract)
        altered['excludedPatterns'].append('test_id')
        with self.assertRaises(ValueError): M.ubuntu_test_arguments(altered)

    def owner_log(self, main_ignored=83):
        targets = ['Running unittests src/lib.rs', 'Running unittests src/bin/coreutils.rs',
                   'Running tests/test_localization_and_colors.rs', 'Running tests/test_util_name.rs',
                   'Running tests/test_uudoc.rs', 'Running tests/tests.rs', 'Doc-tests coreutils']
        ignored = [0, 0, 0, 2, 0, main_ignored, 0]
        lines = [line for target, count in zip(targets, ignored) for line in
                 [target, f'test result: ok. 30 passed; 0 failed; {count} ignored; 0 measured; 0 filtered out;']]
        lines += ['test ' + name + ' ... ok' for name in M.ID_TESTS]
        lines += ['test test_logname::test_normal ... ok', 'test test_logname::test_output_format ... ok']
        return '\n'.join(lines) + '\n'

    def test_strict_receipt_requires_all_targets_and_all19_id_cases(self):
        file = self.root / 'strict.log'
        contract = self.contract()
        good = self.owner_log()
        file.write_text(good, encoding='utf-8')
        self.assertEqual('PASS', M.strict_test_receipt(file, contract, 'true')['status'])
        for bad in [good.replace('groups_ordering', 'unrelated'),
                    good.replace('test_id::test_id_real ... ok', 'test_id::test_id_real ... ignored'),
                    good.replace('Running tests/test_util_name.rs', 'unrelated target'),
                    good.replace('0 failed', '1 failed'), good + 'test result: FAILED\n', '']:
            file.write_text(bad, encoding='utf-8')
            with self.assertRaises(ValueError): M.strict_test_receipt(file, contract, 'true')

    def test_metadata_preserves_old_fail_85ignored_and_owner_ci_coverage_limits(self):
        file = self.root / 'strict.log'
        file.write_text(self.owner_log(main_ignored=80), encoding='utf-8')
        receipt = M.strict_test_receipt(file, self.contract(), 'true')
        self.assertEqual(17, len(receipt['owningTestContract']['excludedPatterns']))
        self.assertEqual(82, receipt['observedTotals']['upstreamIgnored'])
        self.assertEqual(85, receipt['historicalUnfilteredAttempt']['upstreamIgnoredActual'])
        self.assertEqual('FAIL', receipt['historicalUnfilteredAttempt']['status'])
        self.assertEqual(5, receipt['historicalUnfilteredAttempt']['failed'])
        self.assertEqual(19, len(receipt['idCasesReportedOk']))
        self.assertTrue(receipt['lognameCoverage']['ciMarkerForwarded'])
        self.assertFalse(receipt['lognameCoverage']['genuineLoginFixtureValidated'])

    def test_native_command_failure_cannot_be_swallowed(self):
        with self.assertRaises(ValueError):
            M.run([sys.executable, '-c', 'raise SystemExit(3)'], self.root, dict(os.environ),
                  self.root / 'failed.log')

    def test_distinct_gid_fixture_detects_original_effective_first_bug(self):
        binary = self.root / 'id'
        binary.write_bytes(b'fixture')
        def output(command, *_):
            real = int(next(x.split('=')[1] for x in command if x.startswith('--rgid=')))
            effective = int(next(x.split('=')[1] for x in command if x.startswith('--egid=')))
            extra = sorted(map(int, next(x.split('=')[1] for x in command if x.startswith('--groups=')).split(',')))
            args = command[command.index(str(binary)) + 1:]
            if '-G' in args: return ' '.join(map(str, dict.fromkeys([real, effective] + extra)))
            if '-g' in args: return str(real if '-r' in args else effective)
            return 'uid=65534(nobody) gid=' + str(real) + ' groups=' + ','.join(
                str(x) + '(group)' for x in dict.fromkeys([effective] + extra))
        with mock.patch.object(M, 'capture', side_effect=output):
            self.assertEqual(3, len(M.verify_id(binary, [], {}, self.root)))
        with mock.patch.object(M, 'capture', return_value='1 2'):
            with self.assertRaises(ValueError): M.verify_id(binary, [], {}, self.root)


if __name__ == '__main__':
    unittest.main()

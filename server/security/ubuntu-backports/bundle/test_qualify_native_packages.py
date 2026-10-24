#!/usr/bin/env python3
"""Small negative/positive checks for the bundle trust boundaries; no builds."""
import copy
import importlib.util
import io
import json
from pathlib import Path
import stat
import struct
import tarfile
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import urllib.error
import zipfile

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('qualifier', HERE / 'qualify-native-packages.py')
Q = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(Q)


def fixture_api(item, family='jq'):
    return {'run': {'id': item['runId'], 'status': 'completed', 'head_sha': item['sourceCommit'],
                    'conclusion': item['runConclusion'], 'path': '.github/workflows/ubuntu-backport-native.yml'},
            'job': {'id': item['jobId'], 'run_id': item['runId'], 'head_sha': item['sourceCommit'],
                    'name': 'Native (' + family + ')', 'status': 'completed', 'conclusion': 'success'},
            'artifact': {'id': item['artifactId'], 'expired': False, 'name': item['artifactName'],
                         'digest': 'sha256:' + item['zipSha256'],
                         'workflow_run': {'id': item['runId'], 'head_sha': item['sourceCommit']}}}


def pcre2_api(stage):
    return {'run': {'id': stage['runId'], 'head_sha': stage['publisherCommit'], 'status': 'completed',
                    'conclusion': 'failure', 'event': 'workflow_dispatch',
                    'path': '.github/workflows/publish-ubuntu-security-backports.yml'},
            'job': {'id': stage['jobId'], 'run_id': stage['runId'], 'name': 'publish', 'head_sha': stage['publisherCommit'],
                    'status': 'completed', 'conclusion': 'failure',
                    'steps': [dict(row, status='completed') for row in Q.PCRE2_STAGE_STEPS]},
            'artifact': {'id': stage['artifactId'], 'name': stage['artifactName'], 'expired': False,
                         'digest': 'sha256:' + stage['zipSha256'],
                         'workflow_run': {'id': stage['runId'], 'head_sha': stage['publisherCommit']}}}


class Boundaries(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='bundle-unit-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.lock = Q.load_lock()

    def make_zip(self, names):
        archive = self.root / 'native.zip'
        with zipfile.ZipFile(archive, 'w') as target:
            for name, content in names:
                if isinstance(name, str):
                    info = zipfile.ZipInfo('entry'); info.filename = info.orig_filename = name
                    target.writestr(info, content)
                else: target.writestr(name, content)
        return archive

    def test_pending_glibc_is_not_publishable(self):
        lock = copy.deepcopy(self.lock)
        lock['nativeInputs']['glibc'].update(status='pending', artifactId=None, zipSha256=None)
        file = self.root / 'lock.json'; file.write_text(json.dumps(lock))
        with patch.object(Q, 'LOCK_FILE', file):
            self.assertEqual(Q.load_lock()['nativeInputs']['glibc']['status'], 'pending')
            with self.assertRaisesRegex(ValueError, 'pending'):
                Q.load_lock(ready=True)

    def test_missing_native_producer_is_fetched_by_exact_sha_without_changing_head(self):
        commits = sorted({item['sourceCommit'] for item in self.lock['nativeInputs'].values()} |
                         {self.lock['pcre2']['stageInput']['publisherCommit']})
        with patch.object(Q.subprocess, 'run', return_value=SimpleNamespace(returncode=0)) as run:
            Q.ensure_native_sources(self.lock)
            self.assertEqual(len(run.call_args_list), len(commits))
            self.assertTrue(all(call.args[0][:3] == ['git', 'cat-file', '-e'] for call in run.call_args_list))
        replies = [SimpleNamespace(returncode=1), SimpleNamespace(returncode=0), SimpleNamespace(returncode=0)]
        replies += [SimpleNamespace(returncode=0) for _ in commits[1:]]
        with patch.object(Q.subprocess, 'run', side_effect=replies) as run:
            Q.ensure_native_sources(self.lock)
            fetches = [call.args[0] for call in run.call_args_list if call.args[0][1] != 'cat-file']
            self.assertEqual(fetches, [['git', 'fetch', '--no-tags', 'origin', commits[0]]])

    def test_pcre2_input_keeps_failed_job_and_requires_exact_completed_stage_outcomes(self):
        stage = self.lock['pcre2']['stageInput']; api = pcre2_api(stage)
        Q.verify_pcre2_api(stage, **api)
        for mutate in [lambda a: a['run'].update(conclusion='success'),
                       lambda a: a['job'].update(conclusion='success'),
                       lambda a: a['job']['steps'][0].update(conclusion='failure'),
                       lambda a: a['job']['steps'][1].update(conclusion='failure'),
                       lambda a: a['job']['steps'][2].update(conclusion='success'),
                       lambda a: a['job']['steps'][3].update(conclusion='success'),
                       lambda a: a['job']['steps'].pop(),
                       lambda a: a['artifact']['workflow_run'].update(head_sha='0' * 40)]:
            altered = copy.deepcopy(api); mutate(altered)
            with self.assertRaises(ValueError): Q.verify_pcre2_api(stage, **altered)

    def test_pcre2_input_has_no_fresh_build_fallback_or_recipe_waiver(self):
        for mutate in [lambda x: x['pcre2'].update(kind='fresh-production-target'),
                       lambda x: x['pcre2']['stageInput']['sourceFiles'].pop('.github/workflows/publish-ubuntu-security-backports.yml'),
                       lambda x: x['pcre2']['stageInput']['stepOutcomes'][1].update(conclusion='failure')]:
            lock = copy.deepcopy(self.lock); mutate(lock)
            file = self.root / 'lock.json'; Q.write_json(file, lock)
            with patch.object(Q, 'LOCK_FILE', file), self.assertRaises(ValueError): Q.load_lock()
        workflow = (Q.ROOT / '.github/workflows/publish-ubuntu-security-backports.yml').read_text(encoding='utf-8')
        self.assertNotIn('pcre2_bundle_inputs', workflow)
        self.assertNotIn('pcre2-build.log', workflow)
        self.assertIn('--check-pcre2-source', workflow)
        self.assertIn('--target installer_export', workflow)
        self.assertIn('go test -mod=readonly ./...', (HERE / 'Dockerfile.bundle').read_text(encoding='utf-8'))

    def test_no_extra_runtime_family_or_deb(self):
        for mutate in [lambda x: x['nativeInputs'].update(tar={}),
                       lambda x: x['nativeInputs']['jq']['runtimePackages'].append('libjq-dev')]:
            lock = copy.deepcopy(self.lock); mutate(lock)
            file = self.root / 'lock.json'; file.write_text(json.dumps(lock))
            with patch.object(Q, 'LOCK_FILE', file), self.assertRaises(ValueError): Q.load_lock()

    def test_zip_requires_external_pin(self):
        archive = self.make_zip([('export/result.json', b'{}')])
        with self.assertRaisesRegex(ValueError, 'reviewed artifact pin'): Q.read_zip(archive, '0' * 64)
        self.assertEqual(Q.read_zip(archive, Q.file_sha(archive)), {'export/result.json': b'{}'})

    def test_zip_rejects_escaping_alias_and_diagnostic_paths(self):
        for name in ['../escape', '/absolute', 'C:/escape', 'a\\b', 'a/./b', 'a//b', '.', 'line\nbreak',
                     'export/diagnostics/unqualified-packages/libc6.deb']:
            with self.subTest(name=name):
                archive = self.make_zip([(name, b'x')])
                with self.assertRaises(ValueError): Q.read_zip(archive, Q.file_sha(archive))

    def test_zip_rejects_duplicate_case_and_links(self):
        archive = self.make_zip([('A', b'x'), ('a', b'y')])
        with self.assertRaises(ValueError): Q.read_zip(archive, Q.file_sha(archive))
        link = zipfile.ZipInfo('link'); link.create_system = 3
        link.external_attr = (stat.S_IFLNK | 0o777) << 16
        archive = self.make_zip([(link, b'/etc/passwd')])
        with self.assertRaises(ValueError): Q.read_zip(archive, Q.file_sha(archive))

    def test_selected_job_success_preserves_actual_matrix_failure(self):
        item = self.lock['nativeInputs']['jq']; api = fixture_api(item)
        self.assertEqual(api['run']['conclusion'], 'failure')
        Q.verify_api('jq', item, **api)
        for section, key, value in [('job', 'conclusion', 'failure'), ('job', 'run_id', 1),
                                    ('artifact', 'expired', True), ('run', 'head_sha', 'a' * 40),
                                    ('run', 'conclusion', 'success')]:
            changed = copy.deepcopy(api); changed[section][key] = value
            with self.subTest(section=section, key=key), self.assertRaises(ValueError):
                Q.verify_api('jq', item, **changed)

    def test_artifact_api_cannot_rebind_same_named_bytes(self):
        item = self.lock['nativeInputs']['jq']; api = fixture_api(item)
        api['artifact']['workflow_run']['id'] += 1
        with self.assertRaises(ValueError): Q.verify_api('jq', item, **api)

    def test_native_result_requires_all_three_numeric_zero_exits(self):
        original = self.lock['nativeInputs']['jq']
        for key, value in [('exitCode', 1), ('helperExitCode', True), ('logExitCode', 1)]:
            result = {'module': 'jq', 'sourceSha': original['sourceCommit'], 'status': 'passed',
                      'exitCode': 0, 'helperExitCode': 0, 'logExitCode': 0,
                      'sourceLockSha256': original['lockSha256']}; result[key] = value
            archive = self.make_zip([('source-sha.txt', original['sourceCommit']),
                                     ('export/result.json', json.dumps(result))])
            item = copy.deepcopy(original); item['zipSha256'] = Q.file_sha(archive); item['sourceFiles'] = {}
            with self.subTest(key=key), self.assertRaisesRegex(ValueError, 'exit/lock'):
                Q.validate_native('jq', item, archive, fixture_api(item), self.root, self.root / 'tests')

    def test_pcre_requires_each_actual_suite_and_global_pass(self):
        names = ['pcre2_jit_test', 'RunTest', 'RunGrepTest']
        good = b':test-result: PASS\n:global-test-result: PASS\n'
        files = {name + '.trs': good for name in names}
        files.update({name + '.log': b'actual native output' for name in names})
        provenance = {'tests': [{'test': n, 'sha256': Q.sha(good), 'status': 'PASS'} for n in names]}
        Q.check_owning_tests('pcre2', files, provenance, self.root / 'good')
        for number, wrong in enumerate([b':test-result: PASS\n:global-test-result: FAIL\n',
                                        good + b':test-result: FAIL\n', b':test-result: SKIP\n']):
            files[names[0] + '.trs'] = wrong; provenance['tests'][0]['sha256'] = Q.sha(wrong)
            with self.assertRaises(ValueError):
                Q.check_owning_tests('pcre2', files, provenance, self.root / ('bad' + str(number)))

    def tar_payload(self, entries):
        stream = io.BytesIO()
        with tarfile.open(fileobj=stream, mode='w') as archive:
            for name, kind, content in entries:
                member = tarfile.TarInfo(name); member.mode = 0o755; member.uid = member.gid = 0
                member.type = kind
                if kind == tarfile.REGTYPE:
                    member.size = len(content); archive.addfile(member, io.BytesIO(content))
                else:
                    member.linkname = content; archive.addfile(member)
        return stream.getvalue()

    def payload(self, entries, source='rust-coreutils'):
        data = self.tar_payload(entries)
        fields = {'Package': b'rust-coreutils', 'Source': source.encode(), 'Version': b'1.0', 'Architecture': b'amd64'}
        def command(args):
            if args[1] == '--field': return fields[args[-1]]
            if args[1] == '--fsys-tarfile': return data
            raise AssertionError(args)
        with patch.object(Q, 'command', command):
            return Q.package_payload(self.root / 'native.deb',
                {'name': 'rust-coreutils', 'source': 'rust-coreutils', 'version': '1.0'}, self.root)

    def test_deb_payload_resolves_hardlinks_without_extracting(self):
        payload = self.payload([('./usr/bin/coreutils', tarfile.REGTYPE, b'payload'),
                                ('./usr/bin/id', tarfile.LNKTYPE, './usr/bin/coreutils'),
                                ('./usr/bin/realpath', tarfile.SYMTYPE, '/usr/bin/coreutils')])
        files = {p['path']: p for p in payload['files']}
        self.assertEqual(files['usr/bin/id']['sha256'], Q.sha(b'payload'))
        self.assertEqual(files['usr/bin/realpath']['target'], '/usr/bin/coreutils')
        self.assertFalse((self.root / 'usr').exists())

    def test_deb_rejects_traversal_special_cycle_and_symlink_parent(self):
        for entries in [[('../escape', tarfile.REGTYPE, b'x')],
                        [('device', tarfile.FIFOTYPE, '')],
                        [('id', tarfile.LNKTYPE, 'other'), ('other', tarfile.LNKTYPE, 'id')],
                        [('usr', tarfile.SYMTYPE, '/etc'), ('usr/passwd', tarfile.REGTYPE, b'x')]]:
            with self.subTest(entries=entries), self.assertRaises(ValueError): self.payload(entries)

    def test_deb_rejects_wrong_source(self):
        with self.assertRaisesRegex(ValueError, 'control identity'):
            self.payload([('file', tarfile.REGTYPE, b'x')], source='other')

    def test_elf_metadata_uses_dynamic_external_symbols_and_versions(self):
        elf = bytearray(64); elf[:6] = b'\x7fELF\x02\x01'; struct.pack_into('<H', elf, 18, 62)
        data = self.tar_payload([('usr/lib/libfixture.so.1', tarfile.REGTYPE, bytes(elf))])
        def command(args):
            if args[:2] == ['dpkg-deb', '--field']:
                return {'Package': b'fixture', 'Source': b'', 'Version': b'1', 'Architecture': b'amd64'}[args[-1]]
            if args[:2] == ['dpkg-deb', '--fsys-tarfile']: return data
            if args[0] == 'readelf': return b'(SONAME) Library soname: [libfixture.so.1]\n(NEEDED) Shared library: [libc.so.6]\n'
            self.assertIn('--extern-only', args)
            return b'00000000 T function@@VERSION_1\n00000001 W weak_function\n'
        with patch.object(Q, 'command', command):
            payload = Q.package_payload(self.root / 'fixture.deb',
                {'name': 'fixture', 'source': 'fixture', 'version': '1'}, self.root)
        self.assertEqual(payload['elf'][0]['definedSymbols'], ['function', 'weak_function'])
        self.assertEqual(payload['elf'][0]['needed'], ['libc.so.6'])
        self.assertEqual(payload['elf'][0]['soname'], 'libfixture.so.1')

    def test_readback_is_bound_to_producer_not_a_rewritten_self_manifest(self):
        expected = self.root / 'context/out'; actual = self.root / 'readback/out'
        expected.mkdir(parents=True); actual.mkdir(parents=True)
        for directory in [expected, actual]:
            (directory / 'package.deb').write_bytes(b'original producer bytes')
            (directory / 'install-existing-backports').write_bytes(b'static installer')
        (actual.parent / 'bundle-installer').write_bytes(b'static installer')
        with patch.object(Q, 'WORK', self.root), patch('sys.stdout', io.StringIO()):
            Q.verify_readback()
            (actual / 'package.deb').write_bytes(b'empty replacement')
            (actual / 'SHA256SUMS').write_text(Q.file_sha(actual / 'package.deb') + '  package.deb\n')
            with self.assertRaisesRegex(ValueError, 'producer bytes'): Q.verify_readback()

    def test_registry_collision_and_ambiguous_absence_fail_closed(self):
        token = io.BytesIO(b'{"token":"test"}')
        def error(code, body):
            return urllib.error.HTTPError('https://ghcr.io/', code, 'fixture', {}, io.BytesIO(body))
        env = {'GITHUB_ACTOR': 'fixture', 'REGISTRY_TOKEN': 'fixture'}
        for response, passes in [(io.BytesIO(b'present'), False),
                                  (error(401, b'{"errors":[{"code":"UNAUTHORIZED"}]}'), False),
                                  (error(404, b'{"errors":[{"code":"MANIFEST_UNKNOWN"}]}'), True),
                                  (error(404, b'{"errors":[]}'), False)]:
            token.seek(0)
            with patch('sys.stdout', io.StringIO()), patch.dict(Q.os.environ, env), patch.object(Q.urllib.request, 'urlopen',
                    side_effect=[io.BytesIO(token.getvalue()), response]):
                if passes: Q.registry_manifest('absent')
                else:
                    with self.assertRaises(ValueError): Q.registry_manifest('absent')

    def test_rust_original18_require_bound_per_cve_source_audit(self):
        item = self.lock['nativeInputs']['rust-coreutils']; public = Q.load_rust_source_audit(item)
        audit = public['audit']
        self.assertEqual(set(item['fixedVulnerabilities']),
                         {r['id'] for r in audit['results']} | {'CVE-2026-35370', 'CVE-2026-35371'})
        self.assertEqual(len(audit['results']), 18)
        self.assertTrue(all(row['sourceEvidence'] and row['sourceFixPresent']
                            and not row['effectiveRevertFound'] for row in audit['results']))
        self.assertEqual(audit['identity']['lockSha256'], item['lockSha256'])
        self.assertEqual(audit['identity']['provenanceSha256'], item['evidence']['provenance.json'])
        self.assertEqual(audit['identity']['packageSha256'], item['packages'][0]['sha256'])
        totals = audit['nativeEvidenceReused']['strictOwningSuite']['observedTotals']
        self.assertEqual((totals['upstreamIgnored'], totals['filteredOut']), (84, 17))
        self.assertTrue(all(not row['existingNativeLog']['completeCveSpecificDynamicCoverageClaimed']
                            for row in audit['results']))
        tracked = self.lock['trackedScopes']['statements'][0]
        self.assertEqual(len(tracked['vulnerabilities']), 18)
        self.assertEqual(tracked['status'], 'qualified_component_source_closed')

    def test_exported_guard_is_exact_source_bytes_and_sha(self):
        proof = Q.export_metadata_guard(self.root)
        original = (HERE / 'verify-consumer-evidence.py').read_bytes()
        self.assertEqual((self.root / proof['path']).read_bytes(), original)
        self.assertEqual(proof['sha256'], Q.sha(original))

    def test_rust_extended_fixed_set_without_audit_or_native_identity_is_rejected(self):
        for key in ['sourceAudit', 'lockSha256']:
            item = copy.deepcopy(self.lock['nativeInputs']['rust-coreutils'])
            if key == 'sourceAudit': item.pop(key)
            else: item[key] = '0' * 64
            with self.subTest(key=key), self.assertRaises(ValueError): Q.load_rust_source_audit(item)

    def test_rust_self_rehashed_audit_still_requires_source_details_and_native_binding(self):
        original = json.loads(Q.RUST_AUDIT_FILE.read_text(encoding='utf-8'))
        for number, mutate in enumerate([
                lambda a: a['audit']['results'].pop(),
                lambda a: a['audit']['results'][0].update(sourceEvidence=[]),
                lambda a: a['audit']['results'][0]['sourceEvidence'][0].update(sha256='0' * 64),
                lambda a: a['audit']['identity'].update(packageSha256='0' * 64),
                lambda a: a['audit']['identity'].update(provenanceSha256='0' * 64),
                lambda a: a['audit']['results'][0].update(effectiveRevertFound=True)]):
            public = copy.deepcopy(original); mutate(public)
            file = self.root / Q.RUST_AUDIT_FILE.name; Q.write_json(file, public)
            item = copy.deepcopy(self.lock['nativeInputs']['rust-coreutils']); item['sourceAudit']['sha256'] = Q.file_sha(file)
            with self.subTest(number=number), patch.object(Q, 'RUST_AUDIT_FILE', file), self.assertRaises(ValueError):
                Q.load_rust_source_audit(item)

    def test_debian_purl_separates_epoch_and_preserves_exact_package_version(self):
        package = self.lock['nativeInputs']['libxrender']['packages'][0]
        self.assertEqual(Q.purl(package), 'pkg:deb/ubuntu/libxrender1@0.9.12-1build1%2Bpasturestack.1'
                         '?arch=amd64&distro=ubuntu-26.04&epoch=1')
        self.assertEqual(package['version'], '1:0.9.12-1build1+pasturestack.1')
        self.assertEqual(Q.purl({'name': 'jq', 'version': '1.8.2-0pasturestack1~26.04.1'}),
                         'pkg:deb/ubuntu/jq@1.8.2-0pasturestack1~26.04.1?arch=amd64&distro=ubuntu-26.04')

    def consumer_fixture(self, work, wrong=None):
        output = work / 'context/out'; output.mkdir(parents=True)
        Q.write_json(output / 'qualification.json', {'status': 'qualified'})
        Q.write_json(output / 'manifest.json', {'qualification': {'sha256': Q.file_sha(output / 'qualification.json')}})
        digest = Q.file_sha(output / 'manifest.json')
        for provider in ['gnu', 'uutils']:
            selected = sorted(n for names in Q.FAMILIES.values() for n in names
                              if provider == 'uutils' or n != 'rust-coreutils')
            result = {'schemaVersion': 1, 'provider': provider, 'status': 'PASS', 'inputManifestSha256': digest,
                      'selectedPackages': selected, 'checks': ['batch-install', 'verify-installed', 'package-set',
                        'provider', 'docs-restored', 'glibc-loader', 'jq', 'libjq-RTLD_NOW-TLS-threads',
                        'id', 'p11-kit', 'grep', 'getent']}
            if wrong and provider == 'gnu': wrong(result)
            source = work / ('consumer-' + provider); source.mkdir()
            Q.write_json(source / 'result.json', result)
            for name in ['install.json', 'verify.json', 'console.log']: (source / name).write_text('fixture')

    def test_two_consumer_receipts_are_bound_to_actual_input_manifest(self):
        self.consumer_fixture(self.root)
        with patch.object(Q, 'WORK', self.root), patch('sys.stdout', io.StringIO()):
            Q.record_consumer_tests()
            with self.assertRaisesRegex(ValueError, 'overwritten'): Q.record_consumer_tests()
        output = self.root / 'context/out'
        qualification = json.loads((output / 'qualification.json').read_text())
        manifest = json.loads((output / 'manifest.json').read_text())
        self.assertEqual(len(qualification['consumerFixtures']), 2)
        self.assertEqual(manifest['qualification']['sha256'], Q.file_sha(output / 'qualification.json'))
        self.assertTrue((output / 'provenance/consumer/gnu/install.json').is_file())

    def test_consumer_wrong_manifest_new_rust_or_skipped_check_is_rejected(self):
        for number, mutation in enumerate([lambda r: r.update(inputManifestSha256='0' * 64),
                                           lambda r: r['selectedPackages'].append('rust-coreutils'),
                                           lambda r: r['checks'].remove('docs-restored')]):
            work = self.root / str(number); self.consumer_fixture(work, mutation)
            with patch.object(Q, 'WORK', work), self.assertRaisesRegex(ValueError, 'receipt failed'):
                Q.record_consumer_tests()


if __name__ == '__main__':
    unittest.main(verbosity=2)

"""Focused pure guard/integration checks; no Server or old smoke execution."""
import contextlib
import importlib.util
import io
from pathlib import Path
import unittest
from unittest.mock import Mock, patch

SCRIPT = Path(__file__).with_name('test-registration-basic-api.py')
spec = importlib.util.spec_from_file_location('registration_tested', SCRIPT)
r = importlib.util.module_from_spec(spec); spec.loader.exec_module(r)


class RegistrationSmokeTests(unittest.TestCase):
    def test_creatable_string_kind_without_options_is_native_legal(self):
        self.assertTrue(r.ordinary_kind_creatable({'create': True, 'type': 'string'}))
        self.assertFalse(r.ordinary_kind_creatable({'create': False, 'type': 'string'}))
        self.assertFalse(r.ordinary_kind_creatable({'create': True, 'type': 'unknown'}))

    def test_enum_or_explicit_options_must_allow_user(self):
        for field in ({'create': True, 'type': 'enum'},
                      {'create': True, 'type': 'enum', 'options': []},
                      {'create': True, 'type': 'enum', 'options': ['admin', 'service']},
                      {'create': True, 'type': 'string', 'options': ['admin']},
                      {'create': True, 'type': 'string', 'options': 'user'}):
            with self.subTest(field=field):
                self.assertFalse(r.ordinary_kind_creatable(field))
        for kind in ('string', 'enum'):
            self.assertTrue(r.ordinary_kind_creatable({'create': True, 'type': kind, 'options': ['user', 'admin']}))

    def test_schema_link_is_native_and_transport_cannot_target_external_or_existing_port(self):
        path = '/v2-beta/projects/1a8/registrationtokens'
        schema = {'id': 'registrationToken', 'collectionMethods': ['GET', 'POST'],
                  'links': {'collection': r.ORIGIN + path}}
        self.assertEqual(r.collection(schema, 'registrationToken', path), path)
        self.assertNotIn('_collection', schema)
        for link in ('https://company.example' + path, r.ORIGIN + path + '?secret=x'):
            with self.assertRaises(r.SmokeFailure): r.native_path(link, path)
        for port in (8080, 18193, 18194):
            with patch.object(r.http.client, 'HTTPConnection', side_effect=AssertionError('network')):
                with self.assertRaisesRegex(r.SmokeFailure, 'LOOPBACK_PORT'): r.Client(port)
        client = r.Client(r.PORT)
        client.request = Mock(side_effect=[(404, b'{"code":"Not Found"}', (None, None)),
            (200, b'{"id":"1a8","state":"active"}', ('1a7', '1a7'))])
        with patch.object(r.time, 'sleep'):
            self.assertEqual(client.active('/v2-beta/projects/1a8', 'Basic RAM', project=True)['id'], '1a8')
        client.request = Mock(return_value=(403, b'{"code":"Forbidden"}', (None, None)))
        with self.assertRaisesRegex(r.SmokeFailure, 'ACTIVE_HTTP_STATUS'):
            client.active('/v2-beta/projects/1a8', 'Basic RAM', project=True)

    def test_native_post_is_once_even_if_first_response_fails(self):
        client = r.Client(r.PORT)
        client.request = Mock(return_value=(503, b'{}', (None, None)))
        for _ in range(2):
            with self.assertRaises(r.SmokeFailure):
                client.post('/v2-beta/accounts', {'kind': 'user', 'name': 'fresh'}, 'Bearer RAM')
        self.assertEqual(client.request.call_count, 1)

    def test_failed_http_status_is_diagnostic_without_response_or_credentials(self):
        client = r.Client(r.PORT)
        client.request = Mock(return_value=(500, b'{"secret":"never print"}', (None, None)))
        with self.assertRaisesRegex(r.SmokeFailure, 'HTTP_STATUS_500_EXPECTED_201') as failure:
            client.post('/v2-beta/projects', {'name': 'fresh'}, 'Basic RAM')
        self.assertNotIn('never print', str(failure.exception))
        self.assertNotIn('Basic RAM', str(failure.exception))

    def test_failure_cannot_echo_secret_and_workflow_reuses_existing_bootstrap(self):
        secret = 'RAM-secret-marker-1234567890'
        output = io.StringIO()
        with patch.object(r.Client, 'request', side_effect=RuntimeError(secret)), contextlib.redirect_stdout(output):
            with self.assertRaises(r.SmokeFailure) as failure:
                r.run(port=r.PORT, administrator_jwt=secret, administrator_account_id='1a1', disposable=True)
        self.assertNotIn(secret, str(failure.exception)); self.assertNotIn(secret, output.getvalue())
        mfa = SCRIPT.with_name('test-mfa-policy-api.py').read_text()
        self.assertLess(mfa.index("check('authenticated-administrator'"), mfa.index('registration.run('))
        self.assertLess(mfa.index('registration.run('), mfa.index('recovery_codes = enroll()'))
        self.assertNotIn('/localauthconfigs', SCRIPT.read_text())
        workflow = SCRIPT.parents[1].joinpath('.github/workflows/publish-current-server.yml').read_text()
        self.assertIn('--port 18082 --disposable --registration-basic', workflow)
        self.assertEqual(workflow.count('python3 source/scripts/test-mfa-policy-api.py'), 1)
        self.assertEqual(workflow.count('registration-basic-api-smoke.txt'), 3)


if __name__ == '__main__':
    unittest.main()

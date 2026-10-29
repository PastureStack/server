"""Only guard regressions; actual protocol acceptance requires a real JVM."""
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('ai_smoke', Path(__file__).with_name('test-ai-resource-api.py'))
smoke = importlib.util.module_from_spec(spec)
spec.loader.exec_module(smoke)


class DisposableGuard(unittest.TestCase):
    def test_missing_disposable_or_production_ports_fail_before_any_connection(self):
        with patch.object(smoke.http.client, 'HTTPConnection', side_effect=AssertionError('Unexpected network request')) as connection:
            for port, disposable in [(18082, False), (80, True), (443, True), (8080, True), (0, True), (65536, True)]:
                with self.subTest(port=port, disposable=disposable), self.assertRaises(AssertionError):
                    smoke.run(port=port, administrator_jwt='guard-fixture', administrator_account_id='1a1', disposable=disposable)
            connection.assert_not_called()

    def test_absent_administrator_session_fails_before_any_connection(self):
        with patch.object(smoke.http.client, 'HTTPConnection', side_effect=AssertionError('Unexpected network request')) as connection:
            for token, account in [(None, '1a1'), ('', '1a1'), ('guard-fixture', None)]:
                with self.subTest(account=account), self.assertRaises(AssertionError):
                    smoke.run(port=18082, administrator_jwt=token, administrator_account_id=account, disposable=True)
            connection.assert_not_called()


if __name__ == '__main__':
    unittest.main()

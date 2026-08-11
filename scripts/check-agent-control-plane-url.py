#!/usr/bin/env python3
import contextlib
import io
import json
import os
import pathlib
import stat
import sys
import unittest


REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "agent"))

import register as agent_register
from control_plane_url import ControlPlaneURLPolicy


class ControlPlaneURLPolicyTest(unittest.TestCase):
    def setUp(self):
        self.policy = ControlPlaneURLPolicy("https://control.example/v1")

    def test_accepts_only_same_origin_http_paths(self):
        self.assertEqual(
            self.policy.validate("/v1/schemas"),
            "https://control.example/v1/schemas",
        )
        self.assertEqual(
            self.policy.validate("https://control.example:443/v1/projects"),
            "https://control.example:443/v1/projects",
        )

    def test_rejects_cross_origin_redirect_targets(self):
        rejected = (
            "https://other.example/v1",
            "http://control.example/v1",
            "https://control.example:444/v1",
            "https://user:secret@control.example/v1",
            "file:///etc/passwd",
            "https://control.example/v1#fragment",
        )
        for candidate in rejected:
            with self.subTest(candidate=candidate):
                with self.assertRaises(ValueError):
                    self.policy.validate(candidate)

        redirect_handler = self.policy._redirect_handler()()
        with self.assertRaises(ValueError):
            redirect_handler.redirect_request(
                None,
                None,
                302,
                "Found",
                {},
                "https://other.example/v1/credentials",
            )

    def test_private_control_plane_addresses_remain_supported(self):
        policy = ControlPlaneURLPolicy("http://10.0.0.125:8080/v1")
        self.assertEqual(
            policy.validate("/v1/schemas"),
            "http://10.0.0.125:8080/v1/schemas",
        )

    def test_credentials_are_file_backed_and_not_logged(self):
        captured = io.StringIO()
        with contextlib.redirect_stdout(captured):
            output_path = pathlib.Path(
                agent_register.write_credentials("access value", "secret value")
            )
        self.assertEqual(captured.getvalue(), "")
        try:
            self.assertEqual(
                json.loads(output_path.read_text(encoding="utf-8")),
                {"accessKey": "access value", "secretKey": "secret value"},
            )
            self.assertTrue(
                output_path.name.startswith("pasturestack-agent-registration.")
            )
            if os.name != "nt":
                self.assertEqual(stat.S_IMODE(output_path.stat().st_mode), 0o600)
        finally:
            output_path.unlink(missing_ok=True)

    def test_credentials_use_unique_secure_files(self):
        first = pathlib.Path(agent_register.write_credentials("a", "b"))
        second = pathlib.Path(agent_register.write_credentials("a", "b"))
        try:
            self.assertNotEqual(first, second)
            self.assertTrue(first.is_file())
            self.assertTrue(second.is_file())
        finally:
            first.unlink(missing_ok=True)
            second.unlink(missing_ok=True)


if __name__ == "__main__":
    unittest.main(verbosity=2)

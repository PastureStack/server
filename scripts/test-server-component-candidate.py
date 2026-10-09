#!/usr/bin/env python3
"""Recipe/asset boundary tests. Fixtures are not release component identities."""
import hashlib
import contextlib
import importlib.util
import io
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
ENTRY = ROOT / "server/build-component-candidate.sh"
BUILD = ROOT / "server/build-api-explorer-patch-image.sh"
VERIFY = ROOT / "server/artifacts/verify-host-api-package.sh"
COMMITS = ("ORCHESTRATION_ENGINE_COMMIT", "WEB_CONSOLE_COMMIT", "WEBSOCKET_PROXY_COMMIT", "HOST_API_COMMIT", "NODE_AGENT_COMMIT")
HASHES = ("ORCHESTRATION_ENGINE_ARTIFACT_SHA256", "ENGINE_READONLY_SCHEMA_SHA256", "ENGINE_RESTRICTED_SCHEMA_SHA256",
          "WEB_CONSOLE_ARTIFACT_SHA256", "WEBSOCKET_PROXY_ARCHIVE_SHA256", "WEBSOCKET_PROXY_BINARY_SHA256",
          "HOST_API_ARCHIVE_SHA256", "HOST_API_BINARY_SHA256", "HOST_API_APPLY_SHA256",
          "NODE_AGENT_ARCHIVE_SHA256", "NODE_AGENT_BINARY_SHA256", "NODE_AGENT_APPLY_SHA256")


def fixture_environment():
    environment = {"PATH": os.environ["PATH"], "SOURCE_DATE_EPOCH": "1"}
    for name in COMMITS:
        environment[name] = hashlib.sha1(("unit-fixture-" + name).encode()).hexdigest()
    for name in HASHES:
        environment[name] = hashlib.sha256(("unit-fixture-" + name).encode()).hexdigest()
    return environment


class ComponentRecipeTest(unittest.TestCase):
    def run_entry(self, environment, *arguments):
        return subprocess.run(["bash", str(ENTRY), *arguments], env=environment, text=True, capture_output=True)

    def test_missing_or_invalid_identity_fails_before_any_build(self):
        environment = fixture_environment()
        del environment["HOST_API_ARCHIVE_SHA256"]
        result = self.run_entry(environment, "--check-inputs")
        self.assertEqual(2, result.returncode)
        self.assertIn("Missing required component identity: HOST_API_ARCHIVE_SHA256", result.stderr)
        environment = fixture_environment()
        environment["WEB_CONSOLE_COMMIT"] = "unverified"
        self.assertNotEqual(0, self.run_entry(environment, "--check-inputs").returncode)

    def test_input_check_uses_new_coordinates_and_new_package_id_without_build(self):
        environment = fixture_environment()
        result = self.run_entry(environment, "--check-inputs")
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("server=v1.6.519 engine=v0.183.334 web=1.6.181 proxy=0.23.15 host=0.38.5 node=0.13.28", result.stdout)
        self.assertIn(environment["HOST_API_COMMIT"][:32], result.stdout)
        environment["HOST_API_PACKAGE_ID"] = "301025de31c07073cc03efa17e1ab8ef"
        self.assertNotEqual(0, self.run_entry(environment, "--check-inputs").returncode)

    def local_fixture(self, path):
        environment = fixture_environment()
        assets = path / "assets"
        assets.mkdir()
        for name, variable in (("cattle.jar", "ORCHESTRATION_ENGINE_ARTIFACT_SHA256"),
                               ("web-console-1.6.181.tar.gz", "WEB_CONSOLE_ARTIFACT_SHA256"),
                               ("websocket-proxy-0.23.15-linux-amd64.tar.xz", "WEBSOCKET_PROXY_ARCHIVE_SHA256"),
                               ("host-api-0.38.5.tar.gz", "HOST_API_ARCHIVE_SHA256"),
                               ("node-agent-0.13.28.tar.gz", "NODE_AGENT_ARCHIVE_SHA256")):
            content = ("unit-fixture:" + name).encode()
            (assets / name).write_bytes(content)
            environment[variable] = hashlib.sha256(content).hexdigest()
        commands = path / "commands"
        commands.mkdir()
        git = commands / "git"
        git.write_text("#!/bin/sh\nexit 0\n")
        git.chmod(0o755)
        docker = commands / "docker"
        docker.write_text('#!/bin/sh\nprintf "%s\\n" "$@" >"$FIXTURE_TRACE"\nexit 88\n')
        docker.chmod(0o755)
        environment.update(PATH=str(commands) + os.pathsep + environment["PATH"],
                           PASTURESTACK_COMPONENT_ARTIFACT_DIR=str(assets),
                           PASTURESTACK_SERVER_REVISION=hashlib.sha1(b"unit-fixture-server").hexdigest(),
                           FIXTURE_TRACE=str(path / "docker-arguments"))
        return environment, assets

    def test_five_local_assets_are_hashed_and_named_context_reaches_formal_recipe(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary)
            environment, assets = self.local_fixture(path)
            result = self.run_entry(environment)
            self.assertEqual(88, result.returncode, result.stderr)
            arguments = (path / "docker-arguments").read_text()
            self.assertIn("component_input=" + str(assets), arguments)
            self.assertIn("COMPONENT_ARTIFACT_MODE=local", arguments)
            self.assertIn("HOST_API_PACKAGE_MODE=producer", arguments)
            self.assertIn("SERVER_RELEASE_TAG=v1.6.519", arguments)
            self.assertIn("server/Dockerfile.web-compose-release", arguments)
            for variable in HASHES:
                self.assertIn(environment[variable], arguments)
            for variable in COMMITS:
                self.assertIn(environment[variable], arguments)

    def test_ancillary_url_defaults_keep_https_and_sha_pins_with_explicit_loopback_only(self):
        defaults = {
            'COMPOSE_EXECUTOR_RELEASE_BASE_URL': 'https://github.com/PastureStack/compose-cli/releases/download',
            'VSPHERE_CLI_BUNDLE_RELEASE_BASE_URL': 'https://github.com/PastureStack/vsphere-cli-bundle/releases/download',
        }
        dockerfile = (ROOT / 'server/Dockerfile.web-compose-release').read_text()
        for variable, url in defaults.items():
            self.assertIn('ARG ' + variable + '=' + url, dockerfile)
            self.assertNotIn('ENV ' + variable, dockerfile)
        self.assertIn('echo "${COMPOSE_EXECUTOR_ARCHIVE_SHA256}  ${compose_archive}" | sha256sum -c -', dockerfile)
        self.assertIn('echo "${VSPHERE_CLI_BUNDLE_ARCHIVE_SHA256}  ${vsphere_archive}" | sha256sum -c -', dockerfile)
        self.assertIn('test "${PASTURESTACK_ALLOW_LOOPBACK_ARTIFACTS}" = 1', dockerfile)
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary)
            environment, _ = self.local_fixture(path)
            result = self.run_entry(environment)
            self.assertEqual(88, result.returncode, result.stderr)
            arguments = (path / 'docker-arguments').read_text()
            for variable, url in defaults.items():
                self.assertIn(variable + '=' + url, arguments)
        for variable in defaults:
            for url, allowed, reaches_docker in (
                    ('http://127.0.0.1:18795/cache', False, False),
                    ('http://127.0.0.1:18795/cache', True, True),
                    ('http://10.0.0.144:18795/cache', True, False)):
                with self.subTest(variable=variable, url=url, allowed=allowed):
                    with tempfile.TemporaryDirectory() as temporary:
                        path = Path(temporary)
                        environment, _ = self.local_fixture(path)
                        environment[variable] = url
                        if allowed:
                            environment['PASTURESTACK_ALLOW_LOOPBACK_ARTIFACTS'] = '1'
                        result = self.run_entry(environment)
                        self.assertEqual(reaches_docker, (path / 'docker-arguments').exists())
                        if reaches_docker:
                            self.assertEqual(88, result.returncode, result.stderr)
                            self.assertIn(variable + '=' + url, (path / 'docker-arguments').read_text())
                        else:
                            self.assertNotEqual(0, result.returncode)

    def test_extra_file_or_corrupted_asset_cannot_reach_build(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary)
            environment, assets = self.local_fixture(path)
            (assets / "unexpected").write_text("not a component")
            self.assertNotEqual(0, self.run_entry(environment).returncode)
            self.assertFalse((path / "docker-arguments").exists())
            (assets / "unexpected").unlink()
            (assets / "cattle.jar").write_bytes(b"changed after hash")
            self.assertNotEqual(0, self.run_entry(environment).returncode)
            self.assertFalse((path / "docker-arguments").exists())

    def test_local_symlink_is_rejected_without_build(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary)
            environment, assets = self.local_fixture(path)
            original = assets / "cattle.jar"
            original.rename(path / "outside.jar")
            original.symlink_to(path / "outside.jar")
            self.assertNotEqual(0, self.run_entry(environment).returncode)
            self.assertFalse((path / "docker-arguments").exists())

    def producer_archive(self, directory, corrupt=False, component="host-api"):
        package_id = hashlib.sha1(b"unit-fixture-host-package").hexdigest()[:32]
        content = {package_id + "/bin/" + component: b"unit fixture binary", package_id + "/apply.sh": b"unit fixture apply",
                   package_id + "/licenses/LICENSE test.txt": b"unit fixture license"}
        binary_hash = hashlib.sha256(content[package_id + "/bin/" + component]).hexdigest()
        apply_hash = hashlib.sha256(content[package_id + "/apply.sh"]).hexdigest()
        for algorithm, manifest, checksum in ((hashlib.sha1, "SHA1SUMS", "SHA1SUMSSUM"),
                                               (hashlib.sha256, "SHA256SUMS", "SHA256SUMSSUM")):
            values = sorted((name, value) for name, value in content.items() if "/SHA" not in name)
            body = "".join(algorithm(value).hexdigest() + " *" + name + "\n" for name, value in values).encode()
            content[package_id + "/" + manifest] = body
            content[package_id + "/" + checksum] = (algorithm(body).hexdigest() + "  " + package_id + "/" + manifest + "\n").encode()
        if corrupt:
            content[package_id + "/bin/" + component] = b"modified without updating manifests"
        archive = directory / (component + ".tar.gz")
        with tarfile.open(archive, "w:gz") as output:
            for name, value in content.items():
                member = tarfile.TarInfo(name); member.size = len(value)
                output.addfile(member, io.BytesIO(value))
        return archive, package_id, binary_hash, apply_hash

    def test_producer_checksums_and_license_files_are_accepted_without_legacy_repair(self):
        with tempfile.TemporaryDirectory() as temporary:
            values = self.producer_archive(Path(temporary))
            result = subprocess.run(["bash", str(VERIFY), *map(str, values)], text=True, capture_output=True)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertIn("HOST_API_PRODUCER_PACKAGE_OK", result.stdout)

    def test_producer_corruption_and_wrong_root_are_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            values = self.producer_archive(Path(temporary), corrupt=True)
            self.assertNotEqual(0, subprocess.run(["bash", str(VERIFY), *map(str, values)], capture_output=True).returncode)
            wrong_root = (values[0], "301025de31c07073cc03efa17e1ab8ef", *values[2:])
            self.assertNotEqual(0, subprocess.run(["bash", str(VERIFY), *map(str, wrong_root)], capture_output=True).returncode)

    def test_node_producer_uses_same_manifest_verifier_and_only_known_component_names(self):
        verifier = ROOT / "server/artifacts/verify-agent-package.sh"
        with tempfile.TemporaryDirectory() as temporary:
            values = self.producer_archive(Path(temporary), component="node-agent")
            result = subprocess.run(["bash", str(verifier), "node-agent", *map(str, values)], text=True, capture_output=True)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertIn("AGENT_PRODUCER_PACKAGE_OK component=node-agent", result.stdout)
            self.assertNotEqual(0, subprocess.run(["bash", str(verifier), "unknown", *map(str, values)], capture_output=True).returncode)

    def test_agent_archive_verbose_failure_cannot_bypass_link_rejection(self):
        # Deterministically reproduce an early grep match followed by tar's
        # SIGPIPE status, without timing or constructing a malicious payload.
        verifier = ROOT / "server/artifacts/verify-agent-package.sh"
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            values = self.producer_archive(directory, component="node-agent")
            commands = directory / "commands"
            commands.mkdir()
            real_tar = shutil.which("tar")
            self.assertIsNotNone(real_tar)
            wrapper = commands / "tar"
            wrapper.write_text("#!/usr/bin/env bash\n"
                               "if [[ ${1:-} == -tvzf ]]; then\n"
                               "  printf '%s\\n' 'lrwxrwxrwx link -> outside'\n"
                               "  exit 141\n"
                               "fi\nexec " + shlex.quote(real_tar) + " \"$@\"\n",
                               encoding="utf-8")
            wrapper.chmod(0o755)
            environment = dict(os.environ, PATH=str(commands) + os.pathsep + os.environ["PATH"])
            result = subprocess.run(["bash", str(verifier), "node-agent", *map(str, values)],
                                    env=environment, text=True, capture_output=True)
            self.assertNotEqual(0, result.returncode)
            self.assertNotIn("AGENT_PRODUCER_PACKAGE_OK", result.stdout)

    def test_security_pins_and_overlay_path_are_retained(self):
        text = (ROOT / "server/Dockerfile.web-compose-release").read_text()
        for marker in ("ghcr.io/pasturestack/server:v1.6.460@sha256:c855af8aea232dacc5bb6df68e2271d482c68b53c43ab0c108ec19118f5ab403",
                       "OPENSSL_PACKAGE_VERSION=3.5.5-1ubuntu3.7", "CURL_PACKAGE_VERSION=8.18.0-1ubuntu2.7",
                       "FREETYPE_PACKAGE_VERSION=2.14.2+dfsg-1ubuntu0.2", "UBUNTU_RUNTIME_SECURITY_SNAPSHOT=20261002T000000Z",
                       "PatchV1GlobalSubscribe verify-hardware", "schema/service/service-auth.json", "db/core-124.xml"):
            self.assertIn(marker, text)

    def test_formal_workflow_reads_recipe_defaults_and_does_not_pin_old_host_assets(self):
        workflow = (ROOT / ".github/workflows/publish-current-server.yml").read_text()
        self.assertIn("s/^ARG SERVER_RELEASE_TAG=//p", workflow)
        self.assertIn("s/^ARG HOST_API_VERSION=//p", workflow)
        self.assertNotIn("host-api-0.38.4.tar.gz", workflow)
        self.assertIn("verify-host-api-package.sh", workflow)
        # Parse each YAML literal run block without executing any workflow,
        # release, registry, Docker or shell command from it.
        lines = workflow.splitlines()
        blocks = []
        for index, line in enumerate(lines):
            if not re.match(r"^\s+run: \|$", line):
                continue
            indentation = len(line) - len(line.lstrip())
            block = []
            for following in lines[index + 1:]:
                if following.strip() and len(following) - len(following.lstrip()) <= indentation:
                    break
                block.append(following[indentation + 2:] if following.strip() else "")
            blocks.append("\n".join(block) + "\n")
        self.assertGreater(len(blocks), 5)
        for block in blocks:
            result = subprocess.run(["bash", "-n"], input=block, text=True, capture_output=True)
            self.assertEqual(0, result.returncode, result.stderr)

    def test_schema_proof_rejects_writable_audit_and_client_derived_preview_fields(self):
        specification = importlib.util.spec_from_file_location("key_schema_proof", ROOT / "scripts/test-api-key-schema.py")
        proof = importlib.util.module_from_spec(specification)
        specification.loader.exec_module(proof)
        audit = {'resourceFields': {field: {'create': False, 'update': False} for field in proof.AUDIT_FIELDS}}
        proof.validate_schema('auditlog', audit)
        audit['resourceFields']['keyId']['update'] = True
        with self.assertRaises(AssertionError):
            proof.validate_schema('auditlog', audit)
        preview = {'collectionMethods': ['POST'], 'resourceMethods': [], 'resourceFields': {
            field: {} for field in ('apiKeyId', 'apiKeyPolicy', 'apiKeyPolicyRevision',
                                   'purpose', 'requestDigest', 'confirmationRequired')}}
        proof.validate_schema('apikeypolicypreview', preview)
        preview['resourceFields']['purpose']['create'] = True
        with self.assertRaises(AssertionError):
            proof.validate_schema('apikeypolicypreview', preview)

    def test_schema_failure_diagnostics_keep_only_safe_metadata(self):
        specification = importlib.util.spec_from_file_location('key_schema_failure_proof', ROOT / 'scripts/test-api-key-schema.py')
        proof = importlib.util.module_from_spec(specification)
        specification.loader.exec_module(proof)
        secret = 'fixture-secret-that-must-not-be-printed'
        valid = {'resourceFields': {
            'apiKeyPolicy': {'type': 'map[json]', 'create': True, 'update': True},
            'apiKeyPolicyRevision': {'update': True},
            'securityConfirmation': {'type': 'password'},
        }, 'token': secret}
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            proof.validate_schema('apikey', valid)
        self.assertEqual('', output.getvalue())
        cases = (
            ({'resourceFields': {'apiKeyPolicy': {'type': secret}}, 'token': secret}, AssertionError, 'apikey-policy-type'),
            ({'resourceFields': {}, 'token': secret}, KeyError, 'MISSING_FIELD_METADATA'),
            ({'resourceFields': None, 'token': secret}, TypeError, 'INVALID_FIELD_METADATA'),
        )
        for schema, exception, code in cases:
            output = io.StringIO()
            with contextlib.redirect_stdout(output), self.assertRaises(exception):
                proof.validate_schema('apikey', schema)
            self.assertIn(code, output.getvalue())
            self.assertNotIn(secret, output.getvalue())
            self.assertNotIn('"token"', output.getvalue())


if __name__ == "__main__":
    unittest.main()

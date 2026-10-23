#!/usr/bin/env python3
"""Exercise the installed agent Python, TLS trust, and registration URL policy."""

import contextlib
import ensurepip
import importlib.util
import io
import json
from pathlib import Path
import ssl
import subprocess
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib import error, request

import pip
import pip._vendor.certifi as bundled_certifi


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "agent"))
from control_plane_url import ControlPlaneURLPolicy
from register import RegistrationClient


class FixtureHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/redirect-away":
            self.send_response(302)
            self.send_header("Location", self.server.redirect_target)
            self.end_headers()
            return
        self.server.requests_seen += 1
        payload = b'{"data":[],"fixture":"agent-runtime"}'
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, *_):
        pass


@contextlib.contextmanager
def fixture_server(tls=None):
    server = ThreadingHTTPServer(("127.0.0.1", 0), FixtureHandler)
    server.requests_seen = 0
    if tls is not None:
        server.socket = tls.wrap_socket(server.socket, server_side=True)
    worker = threading.Thread(target=server.serve_forever, daemon=True)
    worker.start()
    try:
        yield server
    finally:
        server.shutdown()
        server.server_close()
        worker.join(timeout=5)


def rejected_tls(url, context):
    try:
        request.urlopen(url, context=context, timeout=5)
    except error.URLError as exc:
        assert isinstance(exc.reason, ssl.SSLCertVerificationError), type(exc.reason)
    else:
        raise AssertionError("untrusted or wrong-host TLS certificate was accepted")


assert sys.version_info[:3] == (3, 14, 9), sys.version
assert ensurepip.version() == "26.2.2", ensurepip.version()
assert pip.__version__ == "26.2.2", pip.__version__
assert bundled_certifi.__version__ == "2026.10.19", bundled_certifi.__version__
system_trust = ssl.create_default_context()
bundled_trust = ssl.create_default_context(cafile=bundled_certifi.where())
for trust in (system_trust, bundled_trust):
    common_names = [value for cert in trust.get_ca_certs()
                    for rdn in cert["subject"] for name, value in rdn
                    if name == "commonName"]
    assert "emSign ECC Root CA - G3" not in common_names
    assert len(common_names) > 50

with tempfile.TemporaryDirectory(prefix="agent-tls-") as name:
    directory = Path(name)
    key, cert = directory / "key.pem", directory / "cert.pem"
    subprocess.run([
        "openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "1",
        "-subj", "/CN=localhost", "-addext", "subjectAltName=DNS:localhost",
        "-keyout", str(key), "-out", str(cert),
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    server_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    server_context.load_cert_chain(cert, key)
    with fixture_server(server_context) as server:
        port = server.server_address[1]
        for version in (ssl.TLSVersion.TLSv1_2, ssl.TLSVersion.TLSv1_3):
            trust = ssl.create_default_context(cafile=str(cert))
            trust.minimum_version = trust.maximum_version = version
            with request.urlopen(f"https://localhost:{port}/", context=trust, timeout=5) as response:
                assert response.status == 200
        rejected_tls(f"https://localhost:{port}/", system_trust)
        rejected_tls(f"https://127.0.0.1:{port}/", ssl.create_default_context(cafile=str(cert)))

with fixture_server() as expected, fixture_server() as other:
    expected.redirect_target = f"http://127.0.0.1:{other.server_address[1]}/credentials"
    base = f"http://127.0.0.1:{expected.server_address[1]}/v1"
    client = RegistrationClient(base, "fixture-access", "fixture-secret")
    assert client.http_json("GET", client.api_url("register?key=fixture"))["fixture"] == "agent-runtime"
    with contextlib.redirect_stderr(io.StringIO()):
        try:
            client.http_json("GET", f"http://127.0.0.1:{expected.server_address[1]}/redirect-away")
        except SystemExit as exc:
            assert exc.code == 1
        else:
            raise AssertionError("cross-origin registration redirect was accepted")
    assert other.requests_seen == 0
    assert ControlPlaneURLPolicy("http://10.0.0.1:8080/v1").validate("/v1/schemas") == "http://10.0.0.1:8080/v1/schemas"

external = None
if importlib.util.find_spec("certifi") is not None:
    import certifi
    external = certifi.__version__
    assert external == "2026.10.19"
print(json.dumps({
    "python": sys.version.split()[0], "openssl": ssl.OPENSSL_VERSION,
    "ensurepip": ensurepip.version(), "pip": pip.__version__,
    "pip_certifi": bundled_certifi.__version__, "external_certifi": external,
    "removed_ca_absent": True, "tls12": "accepted", "tls13": "accepted",
    "untrusted_chain": "rejected", "wrong_hostname": "rejected",
    "registration_same_origin": "accepted", "registration_cross_origin": "rejected",
    "registration_external_requests": 0,
}, sort_keys=True))

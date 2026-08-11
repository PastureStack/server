#!/usr/bin/env python3
import base64
import json
import os
import stat
import sys
import tempfile
import time
from urllib import parse, request

from control_plane_url import ControlPlaneURLPolicy


def fail(message):
    print(message, file=sys.stderr)
    raise SystemExit(1)


class RegistrationClient:
    def __init__(self, base_url, access, secret):
        self.policy = ControlPlaneURLPolicy(base_url)
        token = "{}:{}".format(access, secret).encode("utf-8")
        self.authorization = "Basic {}".format(
            base64.b64encode(token).decode("ascii")
        )

    def api_url(self, path):
        base = self.policy.base_url.rstrip("/")
        return self.policy.validate("{}/{}".format(base, path.lstrip("/")))

    def http_json(self, method, url, body=None):
        checked_url = self.policy.validate(url)
        data = None
        headers = {
            "Authorization": self.authorization,
            "Accept": "application/json",
        }
        if body is not None:
            data = json.dumps(body).encode("utf-8")
            headers["Content-Type"] = "application/json"

        req = request.Request(
            checked_url, data=data, headers=headers, method=method
        )
        try:
            with self.policy.open(req, timeout=60) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except Exception as exc:
            fail("PastureStack registration API request failed: {}".format(exc))


def collection_data(resource):
    data = resource.get("data", [])
    return data if isinstance(data, list) else []


def wait_success(client, resource, timeout=300):
    deadline = time.time() + timeout
    current = resource
    while time.time() < deadline:
        state = current.get("state")
        transitioning = current.get("transitioning")
        if state == "active" and transitioning in (None, "no"):
            return current
        if transitioning == "error":
            fail(
                "Registration failed: {}".format(
                    current.get("transitioningMessage", "unknown error")
                )
            )
        self_url = current.get("links", {}).get("self")
        if not self_url:
            return current
        time.sleep(2)
        current = client.http_json("GET", self_url)
    fail("Timed out waiting for PastureStack registration")


def write_credentials(access_key, secret_key):
    fd, path = tempfile.mkstemp(prefix="pasturestack-agent-registration.", text=True)
    try:
        file_stat = os.fstat(fd)
        if not stat.S_ISREG(file_stat.st_mode) or file_stat.st_nlink != 1:
            raise ValueError("credential output must be a single regular file")
        if hasattr(os, "geteuid") and file_stat.st_uid != os.geteuid():
            raise ValueError("credential output must be owned by the current user")
        if hasattr(os, "fchmod"):
            os.fchmod(fd, 0o600)
        output = os.fdopen(fd, "w", encoding="utf-8")
        fd = None
        with output:
            json.dump(
                {"accessKey": access_key, "secretKey": secret_key},
                output,
                separators=(",", ":"),
            )
            output.write("\n")
            output.flush()
            os.fsync(output.fileno())
        return path
    except BaseException:
        if fd is not None:
            os.close(fd)
        try:
            os.unlink(path)
        except FileNotFoundError:
            pass
        raise


def register(client, key):
    query = parse.urlencode({"key": key})
    lookup_url = client.api_url("/register?{}".format(query))
    resources = collection_data(client.http_json("GET", lookup_url))

    if resources:
        wait_success(client, resources[0])
    else:
        resource = client.http_json("POST", client.api_url("/register"), {"key": key})
        wait_success(client, resource)

    resources = collection_data(client.http_json("GET", lookup_url))
    if not resources:
        fail("PastureStack registration response did not include the registered agent")
    resource = resources[0]

    fields = resource.get("data", {}).get("fields", {})
    access_key = resource.get("accessKey") or fields.get("accessKey")
    secret_key = resource.get("secretKey") or fields.get("secretKey")
    if not isinstance(access_key, str) or not isinstance(secret_key, str):
        fail("PastureStack registration response did not include agent credentials")
    if not access_key or not secret_key:
        fail("PastureStack registration response did not include agent credentials")
    return access_key, secret_key


def main(argv):
    if len(argv) != 2:
        fail("Usage: register.py REGISTRATION_KEY")
    key = argv[1]
    if not key or len(key) > 16 * 1024:
        fail("Invalid PastureStack registration key")

    base_url = os.environ.get("CATTLE_URL", "").rstrip("/")
    access = os.environ.get("CATTLE_REGISTRATION_ACCESS_KEY")
    secret = os.environ.get("CATTLE_REGISTRATION_SECRET_KEY")
    if not base_url:
        fail("Missing CATTLE_URL")
    if not access or not secret:
        fail("Missing CATTLE_REGISTRATION_ACCESS_KEY or CATTLE_REGISTRATION_SECRET_KEY")

    try:
        client = RegistrationClient(base_url, access, secret)
        access_key, secret_key = register(client, key)
        credential_path = write_credentials(access_key, secret_key)
        print(credential_path)
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        fail("PastureStack registration failed: {}".format(exc))


if __name__ == "__main__":
    main(sys.argv)
